-- scripts/test_direktori_komunitas.sql - the F7 proof.
--
-- Run:  docker exec -i supabase_db_dekapautis \
--         psql -U postgres -d postgres -v ON_ERROR_STOP=1 -f - \
--         < scripts/test_direktori_komunitas.sql
--
-- The claim under test is a specific one: an anonymous author's identity is
-- hidden **server-side**, not sent to the client and hidden in the UI. That is
-- not something a screenshot can demonstrate, so checks 1 to 3 below assert it
-- structurally - the identity columns must not exist in the view at all - and
-- check 5 asserts the full name appears in none of the returned values.
--
-- Same simulation as test_rls.sql: set the JWT claim and switch to the
-- `authenticated` role. Doing it as postgres would prove nothing, because the
-- owner bypasses RLS.

\set ON_ERROR_STOP on
\pset pager off

drop schema if exists uji_f7 cascade;
create schema uji_f7;

create table uji_f7.hasil (
  urutan      int generated always as identity,
  pemeriksaan text not null,
  wajib       boolean not null default true,
  lulus       boolean not null,
  catatan     text
);

create function uji_f7.catat(p_nama text, p_lulus boolean, p_catatan text default null,
                             p_wajib boolean default true)
returns void language sql security definer
set search_path = uji_f7, pg_temp
as $$ insert into uji_f7.hasil (pemeriksaan, wajib, lulus, catatan)
     values (p_nama, p_wajib, p_lulus, p_catatan) $$;

grant usage on schema uji_f7 to authenticated;
grant execute on function uji_f7.catat(text, boolean, text, boolean) to authenticated;

create function uji_f7.jadi(p_uid uuid) returns void language plpgsql
as $$ begin
  perform set_config('request.jwt.claims',
    json_build_object('sub', p_uid, 'role', 'authenticated')::text, false);
end $$;

-- ================================================================ fixtures ==

\set P1 '''f7000001-0000-4000-8000-000000000001'''
\set P2 '''f7000002-0000-4000-8000-000000000002'''
\set PR '''f7000003-0000-4000-8000-000000000003'''
\set PR2 '''f7000004-0000-4000-8000-000000000004'''
\set AD '''f7000005-0000-4000-8000-000000000005'''

delete from auth.users where id in (:P1::uuid, :P2::uuid, :PR::uuid, :PR2::uuid, :AD::uuid);

-- Distinctive full names: check 5 searches the returned rows for them.
insert into auth.users (id, email, raw_user_meta_data) values
  (:P1::uuid,  'f7.p1@dekapautis.test',  '{"peran":"pengasuh","nama":"Ratna Kusumawardani"}'),
  (:P2::uuid,  'f7.p2@dekapautis.test',  '{"peran":"pengasuh","nama":"Bagus Setiawan"}'),
  (:PR::uuid,  'f7.pr@dekapautis.test',  '{"peran":"profesional","nama":"Sri Handayani"}'),
  (:PR2::uuid, 'f7.pr2@dekapautis.test', '{"peran":"profesional","nama":"Tono Wibowo"}'),
  (:AD::uuid,  'f7.ad@dekapautis.test',  '{"peran":"admin","nama":"Admin F7"}');

insert into profesional (id, pengguna_id, nama_lengkap, spesialisasi, kota,
                         lokasi_lat, lokasi_lng, terverifikasi)
values ('f7000003-1111-4000-8000-000000000003', :PR::uuid,
        'Sri Handayani', 'Terapi wicara', 'Surabaya', -7.2819, 112.7951, true),
       ('f7000004-1111-4000-8000-000000000004', :PR2::uuid,
        'Tono Wibowo', 'Psikolog anak', 'Surabaya', -7.2456, 112.7378, true);

insert into profil_anak (id, pengguna_id, nama_panggilan, usia, kemampuan_komunikasi)
values ('f7000001-1111-4000-8000-000000000001', :P1::uuid, 'Bima', 6, 'beberapa_kata');

-- One anonymous post, one signed.
insert into postingan_komunitas (id, pengguna_id, topik, judul, isi, anonim) values
  ('f7000001-2222-4000-8000-000000000001', :P1::uuid, 'rutinitas',
   'Rutinitas pagi yang bisa diprediksi', 'Ini yang kami coba di rumah.', true),
  ('f7000002-2222-4000-8000-000000000002', :P2::uuid, 'sensorik',
   'Anak menutup telinga di mal', 'Ada yang punya pengalaman serupa?', false);

insert into balasan_komunitas (id, postingan_id, pengguna_id, isi, anonim) values
  ('f7000001-3333-4000-8000-000000000001', 'f7000002-2222-4000-8000-000000000002',
   :P1::uuid, 'Kami juga mengalaminya.', true),
  ('f7000002-3333-4000-8000-000000000002', 'f7000002-2222-4000-8000-000000000002',
   :P2::uuid, 'Terima kasih sudah berbagi.', false);

-- ================================================================== checks ==

-- 1. The view does not have a column that could carry a name or a user id.
--    Structural, because "the client hides it" is exactly what this forbids.
do $$
declare bocor text;
begin
  select string_agg(table_name || '.' || column_name, ', ')
    into bocor
  from information_schema.columns
  where table_schema = 'public'
    and table_name in ('postingan_publik', 'balasan_publik')
    and (column_name ilike '%nama%'
      or column_name ilike '%pengguna%'
      or column_name ilike '%penulis%'
      or column_name ilike '%email%');

  perform uji_f7.catat(
    '1. view komunitas tidak punya kolom identitas',
    bocor is null,
    coalesce('kolom identitas masih ada: ' || bocor, 'tidak ada kolom identitas'));
end $$;

-- 2. An anonymous post has no initial either. An initial is still an identifier
--    in a small community: "R.K. from Surabaya" is not anonymous.
set role authenticated;
select uji_f7.jadi(:P2::uuid);
do $$
declare v_inisial text; v_ada boolean;
begin
  select inisial into v_inisial from postingan_publik
   where id = 'f7000001-2222-4000-8000-000000000001';
  select exists(select 1 from postingan_publik
                 where id = 'f7000001-2222-4000-8000-000000000001') into v_ada;

  perform uji_f7.catat('2. postingan anonim: inisial null, baris tetap terlihat',
    v_ada and v_inisial is null,
    format('terlihat=%s inisial=%s', v_ada, coalesce(v_inisial, 'null')));
end $$;

-- 3. A signed post shows an initial, never the name.
do $$
declare v_inisial text;
begin
  select inisial into v_inisial from postingan_publik
   where id = 'f7000002-2222-4000-8000-000000000002';

  perform uji_f7.catat('3. postingan bernama: hanya inisial yang keluar',
    v_inisial = 'BS',
    format('inisial=%s (diharapkan BS dari "Bagus Setiawan")', coalesce(v_inisial, 'null')));
end $$;

-- 4. Replies obey the same rule.
do $$
declare v_anon text; v_bernama text;
begin
  select inisial into v_anon from balasan_publik
   where id = 'f7000001-3333-4000-8000-000000000001';
  select inisial into v_bernama from balasan_publik
   where id = 'f7000002-3333-4000-8000-000000000002';

  perform uji_f7.catat('4. balasan mengikuti aturan yang sama',
    v_anon is null and v_bernama = 'BS',
    format('anonim=%s bernama=%s', coalesce(v_anon, 'null'), coalesce(v_bernama, 'null')));
end $$;

-- 5. No full name appears anywhere in what the view returns, in any column.
--    Catches a name smuggled inside a body or a title as well as in a column.
do $$
declare bocor int;
begin
  select count(*) into bocor
  from postingan_publik p
  where p::text ilike '%Ratna%' or p::text ilike '%Kusumawardani%'
     or p::text ilike '%Bagus Setiawan%';

  perform uji_f7.catat('5. tidak ada nama lengkap di baris manapun',
    bocor = 0, format('%s baris memuat nama lengkap', bocor));
end $$;

-- 6. The base table still refuses to hand over someone else's post directly.
--    The view is the only way in, which is what makes check 1 meaningful.
do $$
declare terlihat int;
begin
  select count(*) into terlihat from postingan_komunitas
   where pengguna_id = 'f7000001-0000-4000-8000-000000000001';

  perform uji_f7.catat('6. tabel dasar tidak bisa dibaca langsung oleh pengguna lain',
    terlihat = 0, format('%s baris milik orang lain terbaca', terlihat));
end $$;

reset role;

-- 7. A schedule request records a request and nothing that resembles payment
--    or an in-app session. Structural: absence is the whole point.
do $$
declare terlarang text;
begin
  select string_agg(column_name, ', ') into terlarang
  from information_schema.columns
  where table_schema = 'public' and table_name = 'pengajuan_jadwal'
    and (column_name ~* 'bayar|harga|tarif|biaya|invoice|payment|amount|
                         sesi|session|room|ruang|video|panggilan|call');

  perform uji_f7.catat('7. pengajuan jadwal tidak punya kolom pembayaran/sesi',
    terlarang is null,
    coalesce('kolom terlarang: ' || terlarang, 'tidak ada kolom pembayaran atau sesi'));
end $$;

-- 8. Creating a request notifies the professional, from the server.
set role authenticated;
select uji_f7.jadi(:P1::uuid);
insert into pengajuan_jadwal (id, pengasuh_id, profesional_id, anak_id, hari, jam, catatan)
values ('f7000001-4444-4000-8000-000000000001', :P1::uuid,
        'f7000003-1111-4000-8000-000000000003',
        'f7000001-1111-4000-8000-000000000001', 'Selasa', '15.00',
        'Bima lebih tenang di sore hari.');
reset role;

do $$
declare n int;
begin
  select count(*) into n from notifikasi
   where pengguna_id = 'f7000003-0000-4000-8000-000000000003'
     and jenis = 'jadwal';

  perform uji_f7.catat('8. profesional diberi tahu saat ada pengajuan',
    n = 1, format('%s notifikasi untuk profesional', n));
end $$;

-- 9. A caregiver cannot see another caregiver's requests.
set role authenticated;
select uji_f7.jadi(:P2::uuid);
do $$
declare terlihat int;
begin
  select count(*) into terlihat from pengajuan_jadwal;
  perform uji_f7.catat('9. pengasuh lain tidak melihat pengajuan siapa pun',
    terlihat = 0, format('%s pengajuan terbaca', terlihat));
end $$;

-- 10. The professional the request was addressed to does see it.
select uji_f7.jadi(:PR::uuid);
do $$
declare terlihat int;
begin
  select count(*) into terlihat from pengajuan_jadwal;
  perform uji_f7.catat('10. profesional yang dituju melihat pengajuannya',
    terlihat = 1, format('%s pengajuan terbaca', terlihat));
end $$;

-- 11. A different professional does not.
select uji_f7.jadi(:PR2::uuid);
do $$
declare terlihat int;
begin
  select count(*) into terlihat from pengajuan_jadwal;
  perform uji_f7.catat('11. profesional lain tidak melihat pengajuan itu',
    terlihat = 0, format('%s pengajuan terbaca', terlihat));
end $$;

-- 12. Answering notifies the caregiver, and the wording never blames them.
select uji_f7.jadi(:PR::uuid);
update pengajuan_jadwal
   set status = 'disetujui', ditanggapi_pada = now()
 where id = 'f7000001-4444-4000-8000-000000000001';
reset role;

do $$
declare n int; v_judul text;
begin
  select count(*), max(n2.judul) into n, v_judul from notifikasi n2
   where pengguna_id = 'f7000001-0000-4000-8000-000000000001' and jenis = 'jadwal';

  perform uji_f7.catat('12. pengasuh diberi tahu saat pengajuan dijawab',
    n = 1 and v_judul = 'Pengajuan jadwal disetujui',
    format('%s notifikasi, judul=%s', n, coalesce(v_judul, 'null')));
end $$;

-- 13. Replaying a queued request does not create a second appointment.
-- The first write lands outside the exception block on purpose: PL/pgSQL
-- rolls the whole block back when it catches, so an insert inside it would be
-- undone along with the duplicate and the count would read zero.
insert into pengajuan_jadwal (pengasuh_id, profesional_id, hari, jam, klien_id)
values ('f7000001-0000-4000-8000-000000000001',
        'f7000003-1111-4000-8000-000000000003', 'Rabu', '09.00',
        'f7000001-9999-4000-8000-000000000001');

do $$
declare n int; gagal boolean := false;
begin
  begin
    insert into pengajuan_jadwal (pengasuh_id, profesional_id, hari, jam, klien_id)
    values ('f7000001-0000-4000-8000-000000000001',
            'f7000003-1111-4000-8000-000000000003', 'Rabu', '09.00',
            'f7000001-9999-4000-8000-000000000001');
  exception when unique_violation then gagal := true;
  end;

  select count(*) into n from pengajuan_jadwal
   where klien_id = 'f7000001-9999-4000-8000-000000000001';

  perform uji_f7.catat('13. klien_id idempoten: pengulangan tidak menggandakan',
    gagal and n = 1, format('unique_violation=%s baris=%s', gagal, n));
end $$;

-- 14. An abuse report names exactly one target, never both and never neither.
do $$
declare ditolak int := 0;
begin
  begin
    insert into laporan_penyalahgunaan (pelapor_id, kategori) values
      ('f7000001-0000-4000-8000-000000000001', 'kasar');
  exception when check_violation then ditolak := ditolak + 1; end;

  begin
    insert into laporan_penyalahgunaan (pelapor_id, kategori, postingan_id, balasan_id)
    values ('f7000001-0000-4000-8000-000000000001', 'kasar',
            'f7000002-2222-4000-8000-000000000002',
            'f7000002-3333-4000-8000-000000000002');
  exception when check_violation then ditolak := ditolak + 1; end;

  perform uji_f7.catat('14. laporan penyalahgunaan menunjuk tepat satu sasaran',
    ditolak = 2, format('%s dari 2 penyisipan salah ditolak', ditolak));
end $$;

-- 15. A report is not readable by the person it is about.
insert into laporan_penyalahgunaan (id, pelapor_id, postingan_id, kategori, frasa)
values ('f7000001-5555-4000-8000-000000000001',
        'f7000001-0000-4000-8000-000000000001',
        'f7000002-2222-4000-8000-000000000002', 'batas_medis', 'dosisnya');

set role authenticated;
select uji_f7.jadi(:P2::uuid);
do $$
declare terlihat int;
begin
  select count(*) into terlihat from laporan_penyalahgunaan;
  perform uji_f7.catat('15. yang dilaporkan tidak bisa membaca laporannya',
    terlihat = 0, format('%s laporan terbaca', terlihat));
end $$;

-- 16. The administrator working the queue can.
select uji_f7.jadi(:AD::uuid);
do $$
declare terlihat int;
begin
  select count(*) into terlihat from laporan_penyalahgunaan;
  perform uji_f7.catat('16. admin melihat antrean moderasi',
    terlihat >= 1, format('%s laporan terbaca', terlihat));
end $$;

-- 17. And can reach the post itself, whatever status the author left it in.
update postingan_komunitas set status = 'ditinjau'
 where id = 'f7000002-2222-4000-8000-000000000002';
do $$
declare terlihat int;
begin
  select count(*) into terlihat from postingan_komunitas
   where id = 'f7000002-2222-4000-8000-000000000002';
  perform uji_f7.catat('17. admin bisa membuka postingan yang ditinjau',
    terlihat = 1, format('%s postingan terbaca', terlihat));
end $$;

-- 18. A post under review leaves the public list.
select uji_f7.jadi(:P1::uuid);
do $$
declare terlihat int;
begin
  select count(*) into terlihat from postingan_publik
   where id = 'f7000002-2222-4000-8000-000000000002';
  perform uji_f7.catat('18. postingan yang ditinjau hilang dari daftar publik',
    terlihat = 0, format('%s baris masih tampil', terlihat));
end $$;

reset role;
update postingan_komunitas set status = 'terbit'
 where id = 'f7000002-2222-4000-8000-000000000002';

-- 19. Initials, including the awkward inputs.
do $$
declare salah text;
begin
  select string_agg(format('%s -> %s (diharapkan %s)', masuk,
                           public.inisial_dari(masuk), keluar), '; ')
    into salah
  from (values ('Bagus Setiawan', 'BS'),
               ('Ratna', 'R'),
               ('  Sri   Handayani  ', 'SH'),
               ('siti nurhaliza binti ahmad', 'SN'),
               ('', '?'),
               (null, '?')) as t(masuk, keluar)
  where public.inisial_dari(masuk) is distinct from keluar;

  perform uji_f7.catat('19. inisial_dari menangani masukan aneh',
    salah is null, coalesce(salah, 'semua benar'));
end $$;

-- 20. The directory is readable by a caregiver - L.9 needs it.
set role authenticated;
select uji_f7.jadi(:P1::uuid);
do $$
declare terlihat int; ada_koordinat int;
begin
  select count(*), count(*) filter (where lokasi_lat is not null)
    into terlihat, ada_koordinat
  from profesional where kota = 'Surabaya';

  perform uji_f7.catat('20. pengasuh bisa membaca direktori beserta koordinat',
    terlihat >= 2 and ada_koordinat >= 2,
    format('%s profesional, %s berkoordinat', terlihat, ada_koordinat));
end $$;
reset role;

-- ================================================================= report ==

select urutan,
       case when lulus then 'LULUS' else 'GAGAL' end as hasil,
       case when wajib then 'wajib' else 'tambahan' end as sifat,
       pemeriksaan, catatan
from uji_f7.hasil order by urutan;

do $$
declare gagal int;
begin
  select count(*) filter (where not lulus) into gagal from uji_f7.hasil;
  if gagal > 0 then
    raise exception 'BLOCKER: % pemeriksaan F7 gagal.', gagal;
  end if;
  raise notice 'Seluruh pemeriksaan F7 lulus.';
end $$;

-- ================================================================ cleanup ==

delete from auth.users where id in (:P1::uuid, :P2::uuid, :PR::uuid, :PR2::uuid, :AD::uuid);
drop schema uji_f7 cascade;
