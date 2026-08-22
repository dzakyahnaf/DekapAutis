-- scripts/test_lingkaran_penuh.sql - Gambar 7.1, ujung ke ujung.
--
-- Run:  docker exec -i supabase_db_dekapautis \
--         psql -U postgres -d postgres -v ON_ERROR_STOP=1 -f - \
--         < scripts/test_lingkaran_penuh.sql
--
-- The loop the proposal draws: a report leaves the caregiver, a professional
-- reads it, answers, and the answer comes back and changes the plan.
--
-- It is proved here rather than only in a widget test because every step of it
-- crosses a role boundary, and role boundaries are enforced by RLS. A test that
-- stubs the backend proves the buttons are wired; this proves the caregiver's
-- data actually reaches the one professional they chose and nobody else.
--
-- Same simulation as the other scripts: set the JWT claim, switch to the
-- `authenticated` role. Running as postgres would prove nothing - owners bypass
-- RLS.

\set ON_ERROR_STOP on
\pset pager off

drop schema if exists uji_lingkar cascade;
create schema uji_lingkar;

create table uji_lingkar.hasil (
  urutan      int generated always as identity,
  pemeriksaan text not null,
  lulus       boolean not null,
  catatan     text
);

create function uji_lingkar.catat(p_nama text, p_lulus boolean,
                                  p_catatan text default null)
returns void language sql security definer
set search_path = uji_lingkar, pg_temp
as $$ insert into uji_lingkar.hasil (pemeriksaan, lulus, catatan)
     values (p_nama, p_lulus, p_catatan) $$;

grant usage on schema uji_lingkar to authenticated;
grant execute on function uji_lingkar.catat(text, boolean, text) to authenticated;

create function uji_lingkar.jadi(p_uid uuid) returns void language plpgsql
as $$ begin
  perform set_config('request.jwt.claims',
    json_build_object('sub', p_uid, 'role', 'authenticated')::text, false);
end $$;

-- ================================================================ fixtures ==

\set PENGASUH '''f9000001-0000-4000-8000-000000000001'''
\set PRO      '''f9000002-0000-4000-8000-000000000002'''
\set PRO_LAIN '''f9000003-0000-4000-8000-000000000003'''
\set ADMIN    '''f9000004-0000-4000-8000-000000000004'''

\set ANAK     '''f9000001-1111-4000-8000-000000000001'''
\set LAPORAN  '''f9000001-2222-4000-8000-000000000001'''
\set PROFIL   '''f9000002-1111-4000-8000-000000000002'''
\set PROFIL2  '''f9000003-1111-4000-8000-000000000003'''

delete from auth.users
 where id in (:PENGASUH::uuid, :PRO::uuid, :PRO_LAIN::uuid, :ADMIN::uuid);

insert into auth.users (id, email, raw_user_meta_data) values
  (:PENGASUH::uuid, 'f9.pengasuh@dekapautis.test',
   '{"peran":"pengasuh","nama":"Rina Kusuma"}'),
  (:PRO::uuid, 'f9.pro@dekapautis.test',
   '{"peran":"profesional","nama":"Sri Handayani"}'),
  (:PRO_LAIN::uuid, 'f9.pro2@dekapautis.test',
   '{"peran":"profesional","nama":"Tono Wibowo"}'),
  (:ADMIN::uuid, 'f9.admin@dekapautis.test',
   '{"peran":"admin","nama":"Admin F9"}');

insert into profesional (id, pengguna_id, nama_lengkap, spesialisasi, kota,
                         status_verifikasi)
values (:PROFIL::uuid, :PRO::uuid, 'Sri Handayani', 'Terapis wicara',
        'Surabaya', 'disetujui'),
       (:PROFIL2::uuid, :PRO_LAIN::uuid, 'Tono Wibowo', 'Psikolog anak',
        'Surabaya', 'menunggu');

insert into profil_anak (id, pengguna_id, nama_panggilan, usia,
                         kemampuan_komunikasi)
values (:ANAK::uuid, :PENGASUH::uuid, 'Bima', 6, 'beberapa_kata');

-- =============================================== 1. laporan dibuat pengasuh ==

set role authenticated;
select uji_lingkar.jadi(:PENGASUH::uuid);

insert into laporan (id, profil_anak_id, periode_mulai, periode_selesai,
                     metrik, per_kategori, ringkasan, penanda_perhatian)
values (:LAPORAN::uuid, :ANAK::uuid, current_date - 28, current_date,
        '{"aktivitas_selesai": 18, "catatan_tercatat": 22, "rata_sesi_harian": 1.4}',
        '[{"kategori":"komunikasi","persen":48,"tren":"turun"}]',
        'Disusun dari catatan pengasuh selama empat minggu.',
        array['komunikasi']);

do $$
declare n int;
begin
  select count(*) into n from laporan
   where id = 'f9000001-2222-4000-8000-000000000001';
  perform uji_lingkar.catat('1. pengasuh membuat laporan atas anaknya',
    n = 1, format('%s laporan terbaca oleh pemiliknya', n));
end $$;

-- ============================================ 2. sebelum izin: tidak terlihat ==

select uji_lingkar.jadi(:PRO::uuid);
do $$
declare n int;
begin
  select count(*) into n from laporan;
  perform uji_lingkar.catat(
    '2. sebelum izin diberikan, profesional tidak melihat laporan apa pun',
    n = 0, format('%s laporan terbaca', n));
end $$;

-- Writing a response without permission must fail, not merely be invisible.
do $$
declare ditolak boolean := false;
begin
  begin
    insert into tanggapan_profesional (laporan_id, profesional_id, isi)
    values ('f9000001-2222-4000-8000-000000000001',
            'f9000002-1111-4000-8000-000000000002', 'Tanpa izin.');
  exception when insufficient_privilege or check_violation then ditolak := true;
  end;
  perform uji_lingkar.catat(
    '3. tanpa izin, profesional tidak bisa menulis tanggapan',
    ditolak, format('ditolak=%s', ditolak));
end $$;

-- ===================================================== 4. pengasuh beri izin ==

select uji_lingkar.jadi(:PENGASUH::uuid);
insert into izin_berbagi (laporan_id, profesional_id)
values (:LAPORAN::uuid, :PROFIL::uuid);

select uji_lingkar.jadi(:PRO::uuid);
do $$
declare n int; penanda text[];
begin
  select count(*), max(penanda_perhatian) into n, penanda from laporan;
  perform uji_lingkar.catat(
    '4. setelah izin, laporan muncul di kotak masuk profesional',
    n = 1 and penanda @> array['komunikasi'],
    format('%s laporan, penanda=%s', n, penanda));
end $$;

-- 5. The other professional still sees nothing.
select uji_lingkar.jadi(:PRO_LAIN::uuid);
do $$
declare n int;
begin
  select count(*) into n from laporan;
  perform uji_lingkar.catat(
    '5. profesional lain tetap tidak melihat laporan itu',
    n = 0, format('%s laporan terbaca', n));
end $$;

-- ================================================== 6. tanggapan + saran ==

select uji_lingkar.jadi(:PRO::uuid);
insert into tanggapan_profesional
  (laporan_id, profesional_id, isi, saran_kategori, saran_durasi_menit)
values (:LAPORAN::uuid, :PROFIL::uuid,
        'Pola menutup telinga di sore hari sebaiknya diamati bersama guru '
        'pendamping. Latihan komunikasi bisa ditambah porsinya.',
        array['komunikasi'], 20);
reset role;

do $$
declare n int; kat text[]; dur int;
begin
  select count(*), max(saran_kategori), max(saran_durasi_menit)
    into n, kat, dur
  from tanggapan_profesional
   where laporan_id = 'f9000001-2222-4000-8000-000000000001';

  perform uji_lingkar.catat(
    '6. tanggapan tersimpan dengan bagian terstruktur yang bisa ditindak',
    n = 1 and kat = array['komunikasi'] and dur = 20,
    format('%s tanggapan, saran=%s durasi=%s', n, kat, dur));
end $$;

-- 7. The caregiver is told, by the server.
do $$
declare n int; judul text;
begin
  select count(*), max(nt.judul) into n, judul from notifikasi nt
   where nt.pengguna_id = 'f9000001-0000-4000-8000-000000000001'
     and nt.jenis = 'penyesuaian';
  perform uji_lingkar.catat(
    '7. pengasuh diberi tahu ada tanggapan baru',
    n = 1, format('%s notifikasi, judul=%s', n, coalesce(judul, 'null')));
end $$;

-- ============================================ 8. tanggapan kembali ke pengasuh ==

set role authenticated;
select uji_lingkar.jadi(:PENGASUH::uuid);
do $$
declare isi_terbaca text;
begin
  select isi into isi_terbaca from tanggapan_profesional
   where laporan_id = 'f9000001-2222-4000-8000-000000000001';
  perform uji_lingkar.catat(
    '8. pengasuh dapat membaca tanggapan atas laporannya',
    isi_terbaca is not null and isi_terbaca like '%guru pendamping%',
    coalesce(left(isi_terbaca, 40), 'null'));
end $$;

-- 9. The caregiver applies it. They may change what they did about the
--    response, and nothing else.
update tanggapan_profesional
   set status = 'diterapkan', ditindaklanjuti_pada = now()
 where laporan_id = :LAPORAN::uuid;

do $$
declare st text;
begin
  select status into st from tanggapan_profesional
   where laporan_id = 'f9000001-2222-4000-8000-000000000001';
  perform uji_lingkar.catat('9. pengasuh menandai tanggapan sebagai diterapkan',
    st = 'diterapkan', format('status=%s', st));
end $$;

-- 10. The plan moves, and the row that moved it explains itself.
--     The arithmetic lives in Dart (saran_profesional.dart); what is proved
--     here is that the caregiver may write the log row for their own child.
insert into rencana (id, profil_anak_id, periode_mulai, periode_selesai)
values ('f9000001-3333-4000-8000-000000000001', :ANAK::uuid,
        current_date, current_date + 6);

insert into adaptasi_log (rencana_id, aturan_id, kategori, nilai_sebelum,
                          nilai_sesudah, alasan)
values ('f9000001-3333-4000-8000-000000000001', 'F_profesional', 'komunikasi',
        '{"porsi": 3}', '{"porsi": 4}',
        'Tenaga profesional yang membaca laporan Anda menyarankan lebih banyak '
        'latihan komunikasi. Sesi komunikasi minggu ini naik dari 3 menjadi 4. '
        'Anda yang menyetujui penerapannya.');

do $$
declare alasan_baris text;
begin
  select alasan into alasan_baris from adaptasi_log
   where aturan_id = 'F_profesional';

  perform uji_lingkar.catat(
    '10. lingkaran tertutup: rencana berubah dan alasannya menyebut angka nyata',
    alasan_baris like '%3%' and alasan_baris like '%4%'
      and alasan_baris like '%profesional%',
    coalesce(left(alasan_baris, 60), 'null'));
end $$;

-- 11. Revoking permission cuts the professional off from here on.
update izin_berbagi set status = 'dicabut', dicabut_pada = now()
 where laporan_id = :LAPORAN::uuid;

select uji_lingkar.jadi(:PRO::uuid);
do $$
declare n int; bisa_tulis boolean := true;
begin
  select count(*) into n from laporan;

  begin
    insert into tanggapan_profesional (laporan_id, profesional_id, isi)
    values ('f9000001-2222-4000-8000-000000000001',
            'f9000002-1111-4000-8000-000000000002', 'Setelah dicabut.');
  exception when insufficient_privilege or check_violation then
    bisa_tulis := false;
  end;

  perform uji_lingkar.catat(
    '11. pencabutan izin benar-benar memutus akses',
    n = 0 and not bisa_tulis,
    format('%s laporan terbaca, bisa_tulis=%s', n, bisa_tulis));
end $$;
reset role;

-- ==================================================== 12-15. administrator ==

set role authenticated;
select uji_lingkar.jadi(:ADMIN::uuid);

do $$
declare n int;
begin
  select count(*) into n from profesional where status_verifikasi = 'menunggu';
  perform uji_lingkar.catat('12. admin melihat antrean verifikasi',
    n >= 1, format('%s praktik menunggu', n));
end $$;

-- A rejection has to say why. An unexplained refusal is not a decision the
-- practice can act on.
do $$
declare ditolak boolean := false;
begin
  begin
    update profesional set status_verifikasi = 'ditolak'
     where id = 'f9000003-1111-4000-8000-000000000003';
  exception when check_violation then ditolak := true;
  end;
  perform uji_lingkar.catat('13. penolakan tanpa alasan ditolak basis data',
    ditolak, format('ditolak=%s', ditolak));
end $$;

do $$
declare v_terverifikasi boolean; v_pada timestamptz;
begin
  update profesional
     set status_verifikasi = 'disetujui', ditinjau_oleh = auth.uid()
   where id = 'f9000003-1111-4000-8000-000000000003';

  select terverifikasi, diverifikasi_pada into v_terverifikasi, v_pada
    from profesional where id = 'f9000003-1111-4000-8000-000000000003';

  perform uji_lingkar.catat(
    '14. persetujuan menyalakan lencana dan mencatat waktunya',
    v_terverifikasi and v_pada is not null,
    format('terverifikasi=%s pada=%s', v_terverifikasi, v_pada is not null));
end $$;

do $$
declare v_terverifikasi boolean;
begin
  update profesional
     set status_verifikasi = 'ditolak',
         alasan_penolakan = 'Bukti kredensial belum terbaca jelas.'
   where id = 'f9000003-1111-4000-8000-000000000003';

  select terverifikasi into v_terverifikasi
    from profesional where id = 'f9000003-1111-4000-8000-000000000003';

  perform uji_lingkar.catat(
    '15. penolakan mematikan lencana, tidak menyisakan status lama',
    not v_terverifikasi, format('terverifikasi=%s', v_terverifikasi));
end $$;

-- ==================================================== 16-18. basis pengetahuan ==

reset role;
insert into dokumen_pengetahuan (id, judul, penerbit, tahun, url)
values ('f9000009-0000-4000-8000-000000000009', 'Dokumen uji F9', 'Uji', 2026,
        'https://contoh.test/f9');

set role authenticated;
select uji_lingkar.jadi(:ADMIN::uuid);
select public.minta_indeks_ulang('f9000009-0000-4000-8000-000000000009'::uuid);

do $$
declare n int;
begin
  select count(*) into n from antrean_indeks
   where id = 'f9000009-0000-4000-8000-000000000009';
  perform uji_lingkar.catat(
    '16. admin memicu indexing ulang dan dokumen masuk antrean',
    n = 1, format('%s dokumen di antrean', n));
end $$;

select uji_lingkar.jadi(:PENGASUH::uuid);
do $$
declare ditolak boolean := false;
begin
  begin
    perform public.minta_indeks_ulang(
      'f9000009-0000-4000-8000-000000000009'::uuid);
  exception when others then ditolak := true;
  end;
  perform uji_lingkar.catat('17. pengasuh tidak bisa memicu indexing ulang',
    ditolak, format('ditolak=%s', ditolak));
end $$;

-- A post to act on. Written by the caregiver, reported, then taken down by the
-- administrator - the moderation queue end to end rather than an empty update
-- that would pass with nothing in the table.
select uji_lingkar.jadi(:PENGASUH::uuid);
insert into postingan_komunitas (id, pengguna_id, topik, judul, isi)
values ('f9000001-4444-4000-8000-000000000001', :PENGASUH::uuid, 'rutinitas',
        'Postingan uji moderasi', 'Isi yang akan dilaporkan.');
insert into laporan_penyalahgunaan (pelapor_id, postingan_id, kategori)
values (:PENGASUH::uuid, 'f9000001-4444-4000-8000-000000000001', 'spam');

select uji_lingkar.jadi(:ADMIN::uuid);
do $$
declare n int; terlihat int; antre int;
begin
  select count(*) into antre from laporan_penyalahgunaan where status = 'menunggu';

  update postingan_komunitas set status = 'dihapus'
   where id = 'f9000001-4444-4000-8000-000000000001';
  get diagnostics n = row_count;

  update laporan_penyalahgunaan
     set status = 'ditindak', ditangani_oleh = auth.uid(), ditangani_pada = now()
   where postingan_id = 'f9000001-4444-4000-8000-000000000001';

  -- And the post really leaves the public list.
  select count(*) into terlihat from postingan_publik
   where id = 'f9000001-4444-4000-8000-000000000001';

  perform uji_lingkar.catat('18. admin menindak antrean moderasi dan postingan hilang',
    antre >= 1 and n = 1 and terlihat = 0,
    format('%s laporan antre, %s postingan ditindak, %s masih tampil',
           antre, n, terlihat));
end $$;
reset role;
delete from postingan_komunitas where id = 'f9000001-4444-4000-8000-000000000001';

-- ================================================================= report ==

select urutan,
       case when lulus then 'LULUS' else 'GAGAL' end as hasil,
       pemeriksaan, catatan
from uji_lingkar.hasil order by urutan;

do $$
declare gagal int;
begin
  select count(*) filter (where not lulus) into gagal from uji_lingkar.hasil;
  if gagal > 0 then
    raise exception 'BLOCKER: % langkah lingkaran F9 gagal.', gagal;
  end if;
  raise notice 'Lingkaran Gambar 7.1 tertutup penuh.';
end $$;

-- ================================================================ cleanup ==

delete from auth.users
 where id in (:PENGASUH::uuid, :PRO::uuid, :PRO_LAIN::uuid, :ADMIN::uuid);
delete from dokumen_pengetahuan
 where id = 'f9000009-0000-4000-8000-000000000009';
drop schema uji_lingkar cascade;
