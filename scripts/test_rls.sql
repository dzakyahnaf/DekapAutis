-- scripts/test_rls.sql - the privacy proof.
--
-- Five checks are mandatory (docs/03 §4). If one fails, that is a blocker and
-- work does not move on to the next phase. Several extra checks follow them,
-- covering promises the product makes on screen.
--
-- Run:  docker exec -i supabase_db_dekapautis \
--         psql -U postgres -d postgres -v ON_ERROR_STOP=1 -f - < scripts/test_rls.sql
--
-- How the simulation works
-- -----------------------
-- Policies key off auth.uid(), which reads request.jwt.claims. Setting that and
-- switching to the `authenticated` role reproduces exactly what a signed-in
-- client sees. It has to be the role too, not just the claim: postgres owns
-- these tables and owners bypass RLS, so running the checks as postgres would
-- pass no matter how broken the policies were.

\set ON_ERROR_STOP on
\pset pager off

-- ============================================================ scaffolding ==

drop schema if exists uji_rls cascade;
create schema uji_rls;

create table uji_rls.hasil (
  urutan     int generated always as identity,
  pemeriksaan text not null,
  wajib      boolean not null default true,
  lulus      boolean not null,
  catatan    text
);

-- SECURITY DEFINER so a check can record its own result while still acting as
-- the authenticated role it is testing.
create function uji_rls.catat(p_nama text, p_lulus boolean, p_catatan text default null,
                              p_wajib boolean default true)
returns void language sql security definer
set search_path = uji_rls, pg_temp
as $$ insert into uji_rls.hasil (pemeriksaan, wajib, lulus, catatan)
     values (p_nama, p_wajib, p_lulus, p_catatan) $$;

grant usage on schema uji_rls to authenticated;
grant execute on function uji_rls.catat(text, boolean, text, boolean) to authenticated;

create function uji_rls.jadi(p_uid uuid) returns void language plpgsql
as $$ begin
  perform set_config('request.jwt.claims',
    json_build_object('sub', p_uid, 'role', 'authenticated')::text, false);
end $$;

-- ================================================================ fixtures ==

-- Deterministic ids so a failure is readable in the output.
\set A   '''aaaaaaaa-0000-4000-8000-000000000001'''
\set B   '''bbbbbbbb-0000-4000-8000-000000000002'''
\set C   '''cccccccc-0000-4000-8000-000000000003'''

delete from auth.users where id in (:A::uuid, :B::uuid, :C::uuid);

-- The trigger from migration 001 creates the matching pengguna row and assigns
-- the role, so this also exercises sign-up.
insert into auth.users (id, email, raw_user_meta_data) values
  (:A::uuid, 'rls.a@dekapautis.test', '{"peran":"pengasuh","nama":"Pengasuh A"}'),
  (:B::uuid, 'rls.b@dekapautis.test', '{"peran":"pengasuh","nama":"Pengasuh B"}'),
  (:C::uuid, 'rls.c@dekapautis.test', '{"peran":"profesional","nama":"Profesional C"}');

insert into profesional (id, pengguna_id, nama_lengkap, spesialisasi, kota)
values ('cccccccc-1111-4000-8000-000000000003', :C::uuid,
        'Profesional C', 'Terapi wicara', 'Surabaya');

insert into profil_anak (id, pengguna_id, nama_panggilan, usia, kemampuan_komunikasi)
values ('aaaaaaaa-1111-4000-8000-000000000001', :A::uuid, 'Anak A', 6, 'beberapa_kata'),
       ('bbbbbbbb-1111-4000-8000-000000000002', :B::uuid, 'Anak B', 7, 'kalimat_pendek');

insert into laporan (id, profil_anak_id, periode_mulai, periode_selesai,
                     metrik, per_kategori, ringkasan)
values ('aaaaaaaa-2222-4000-8000-000000000001',
        'aaaaaaaa-1111-4000-8000-000000000001',
        current_date - 28, current_date,
        '{"aktivitas_selesai":0}', '[]', 'Ringkasan uji.');

insert into dokumen_pengetahuan (id, judul, penerbit, tahun, url)
values ('dddddddd-0000-4000-8000-000000000001', 'Dokumen uji', 'Uji', 2026,
        'https://contoh.test/dokumen');

-- ================================================ 1. caregiver isolation ==

set role authenticated;
select uji_rls.jadi(:A::uuid);

select uji_rls.catat(
  '1. Pengasuh A membaca profil_anak milik B',
  (select count(*) from profil_anak where pengguna_id = :B::uuid) = 0,
  'baris terbaca: ' || (select count(*) from profil_anak where pengguna_id = :B::uuid)
);

-- A positive control. Without it, a missing GRANT would return zero rows
-- everywhere and every check above would "pass" for the wrong reason.
select uji_rls.catat(
  '1b. Kontrol positif - A tetap melihat anaknya sendiri',
  (select count(*) from profil_anak) = 1,
  'baris terbaca: ' || (select count(*) from profil_anak),
  false
);

reset role;

-- =========================================== 2. professional, no consent ==

set role authenticated;
select uji_rls.jadi(:C::uuid);

select uji_rls.catat(
  '2. Profesional tanpa izin membaca laporan A',
  (select count(*) from laporan) = 0,
  'baris terbaca: ' || (select count(*) from laporan)
);

reset role;

-- ============================================= 3. professional, consented ==

insert into izin_berbagi (id, laporan_id, profesional_id)
values ('eeeeeeee-0000-4000-8000-000000000001',
        'aaaaaaaa-2222-4000-8000-000000000001',
        'cccccccc-1111-4000-8000-000000000003');

set role authenticated;
select uji_rls.jadi(:C::uuid);

select uji_rls.catat(
  '3. Profesional dengan izin aktif membaca laporan A',
  (select count(*) from laporan) = 1,
  'baris terbaca: ' || (select count(*) from laporan)
);

reset role;

-- ================================================ 4. consent is withdrawn ==

update izin_berbagi
   set status = 'dicabut', dicabut_pada = now()
 where id = 'eeeeeeee-0000-4000-8000-000000000001';

set role authenticated;
select uji_rls.jadi(:C::uuid);

select uji_rls.catat(
  '4. Setelah izin dicabut, profesional yang sama',
  (select count(*) from laporan) = 0,
  'baris terbaca: ' || (select count(*) from laporan)
);

reset role;

-- ====================================== 5. caregiver cannot write knowledge ==

set role authenticated;
select uji_rls.jadi(:A::uuid);

do $$
begin
  insert into dokumen_pengetahuan (judul, penerbit, tahun, url)
  values ('Dokumen selundupan', 'Pengasuh A', 2026, 'https://contoh.test/palsu');
  perform uji_rls.catat('5. Pengasuh menulis dokumen_pengetahuan', false,
                        'BERHASIL MENULIS - seharusnya ditolak');
exception
  when insufficient_privilege then
    perform uji_rls.catat('5. Pengasuh menulis dokumen_pengetahuan', true,
                          'ditolak oleh RLS');
end $$;

reset role;

-- ============================================ extra checks beyond the five ==

-- The check-in card on L.2 says "Hanya untuk Anda, tidak dibagikan". That has
-- to be true of the database, not just of the label.
insert into catatan_pengasuh (pengguna_id, tanggal, kondisi)
values (:A::uuid, current_date, 2);

set role authenticated;
select uji_rls.jadi(:C::uuid);
select uji_rls.catat(
  '6. Check-in kondisi pengasuh tidak terbaca profesional',
  (select count(*) from catatan_pengasuh) = 0,
  'baris terbaca: ' || (select count(*) from catatan_pengasuh),
  false
);
reset role;

-- A professional owns their own directory row, so without the guard trigger
-- they could award themselves the verified badge.
set role authenticated;
select uji_rls.jadi(:C::uuid);
do $$
begin
  update profesional set terverifikasi = true where pengguna_id = auth.uid();
  perform uji_rls.catat('7. Profesional memverifikasi dirinya sendiri', false,
                        'BERHASIL - seharusnya ditolak', false);
exception
  when others then
    perform uji_rls.catat('7. Profesional memverifikasi dirinya sendiri', true,
                          'ditolak: ' || sqlerrm, false);
end $$;
reset role;

-- Anonymity is a server-side guarantee: the identity column must not travel to
-- the client at all, rather than being hidden by it.
insert into postingan_komunitas (id, pengguna_id, topik, judul, isi, anonim)
values ('ffffffff-0000-4000-8000-000000000001', :A::uuid, 'rutinitas',
        'Judul uji', 'Isi uji', true);

set role authenticated;
select uji_rls.jadi(:B::uuid);
-- Migration 008 removed `nama_penulis` outright: the view now emits an
-- initial, and an anonymous post does not even get that. The stronger
-- structural form of this check lives in test_direktori_komunitas.sql.
select uji_rls.catat(
  '8. Postingan anonim tidak membocorkan identitas',
  (select count(*) from postingan_publik
    where id = 'ffffffff-0000-4000-8000-000000000001' and inisial is null) = 1
  and (select count(*) from postingan_komunitas
        where id = 'ffffffff-0000-4000-8000-000000000001') = 0,
  'view menyembunyikan penulis, tabel dasar tidak terbaca pengguna lain',
  false
);
reset role;

-- A caregiver must not be able to read another caregiver's responses, which sit
-- three joins away from any pengguna_id.
insert into rencana (id, profil_anak_id, periode_mulai, periode_selesai)
values ('aaaaaaaa-3333-4000-8000-000000000001',
        'aaaaaaaa-1111-4000-8000-000000000001', current_date, current_date + 6);
insert into aktivitas (id, kategori, tingkat, judul, tujuan, durasi_menit, langkah)
values ('aaaaaaaa-4444-4000-8000-000000000001', 'komunikasi', 2, 'Aktivitas uji',
        'Tujuan uji', 10,
        '[{"urutan":1,"teks":"a"},{"urutan":2,"teks":"b"},{"urutan":3,"teks":"c"}]');
insert into jadwal_aktivitas (id, rencana_id, aktivitas_id, tanggal, waktu, urutan,
                              durasi_menit, tingkat_disesuaikan)
values ('aaaaaaaa-5555-4000-8000-000000000001',
        'aaaaaaaa-3333-4000-8000-000000000001',
        'aaaaaaaa-4444-4000-8000-000000000001', current_date, '08:00', 1, 10, 2);
insert into catatan_respons (jadwal_aktivitas_id, nilai)
values ('aaaaaaaa-5555-4000-8000-000000000001', 'mudah');

set role authenticated;
select uji_rls.jadi(:B::uuid);
select uji_rls.catat(
  '9. Pengasuh B membaca catatan_respons milik A',
  (select count(*) from catatan_respons) = 0,
  'baris terbaca: ' || (select count(*) from catatan_respons),
  false
);
reset role;

set role authenticated;
select uji_rls.jadi(:A::uuid);
select uji_rls.catat(
  '9b. Kontrol positif - A membaca catatannya sendiri',
  (select count(*) from catatan_respons) = 1,
  'baris terbaca: ' || (select count(*) from catatan_respons),
  false
);
reset role;

-- TRUNCATE ignores RLS entirely, and Supabase's default privileges granted it
-- to authenticated. One request could have emptied the activity catalogue and,
-- through the cascade, every schedule and response row in the system. This
-- check exists so that can never come back unnoticed.
set role authenticated;
select uji_rls.jadi(:B::uuid);
do $$
begin
  truncate aktivitas cascade;
  perform uji_rls.catat('10. Pengguna biasa meng-TRUNCATE tabel', false,
                        'BERHASIL - RLS tidak melindungi TRUNCATE');
exception
  when insufficient_privilege then
    perform uji_rls.catat('10. Pengguna biasa meng-TRUNCATE tabel', true,
                          'ditolak: hak TRUNCATE sudah dicabut');
end $$;
reset role;

select uji_rls.catat(
  '10b. Katalog aktivitas masih utuh setelah percobaan',
  (select count(*) from aktivitas) > 0,
  'baris tersisa: ' || (select count(*) from aktivitas)
);

-- ================================================================= report ==

\echo ''
\echo '================= HASIL UJI RLS ================='

select lpad(urutan::text, 2) as no,
       case when lulus then 'LULUS' else 'GAGAL' end as status,
       case when wajib then 'wajib' else 'tambahan' end as jenis,
       pemeriksaan,
       catatan
from uji_rls.hasil
order by urutan;

select count(*) filter (where lulus and wajib)     as wajib_lulus,
       count(*) filter (where wajib)               as wajib_total,
       count(*) filter (where lulus and not wajib) as tambahan_lulus,
       count(*) filter (where not wajib)           as tambahan_total
from uji_rls.hasil;

do $$
declare
  gagal_wajib int;
  gagal_lain  int;
begin
  select count(*) filter (where not lulus and wajib),
         count(*) filter (where not lulus and not wajib)
    into gagal_wajib, gagal_lain
  from uji_rls.hasil;

  if gagal_wajib > 0 then
    raise exception 'BLOCKER: % pemeriksaan RLS wajib gagal. Jangan lanjut ke fase berikutnya.', gagal_wajib;
  end if;
  if gagal_lain > 0 then
    raise warning '% pemeriksaan tambahan gagal.', gagal_lain;
  end if;
  raise notice 'Seluruh pemeriksaan RLS wajib lulus.';
end $$;

-- ================================================================ cleanup ==

delete from auth.users where id in (:A::uuid, :B::uuid, :C::uuid);
delete from aktivitas where id = 'aaaaaaaa-4444-4000-8000-000000000001';
delete from dokumen_pengetahuan where id = 'dddddddd-0000-4000-8000-000000000001';
drop schema uji_rls cascade;
