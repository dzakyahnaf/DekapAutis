-- scripts/test_seed_demo.sql - bukti bahwa data demo tidak pernah basi.
--
-- Jalankan:
--   docker exec -i supabase_db_dekapautis \
--     psql -U postgres -d postgres -v ON_ERROR_STOP=1 -f - \
--     < scripts/test_seed_demo.sql
--
-- Pemeriksaan terpenting adalah nomor 1 dan 2: riwayat harus selalu berakhir
-- hari ini. Seed dengan tanggal absolut lolos pada hari ia ditulis dan gagal
-- diam-diam setiap hari sesudahnya - persis jenis kegagalan yang tidak terlihat
-- sampai juri membukanya.

\set ON_ERROR_STOP on
\pset pager off

drop schema if exists uji_seed cascade;
create schema uji_seed;

create table uji_seed.hasil (
  urutan      int generated always as identity,
  pemeriksaan text not null,
  lulus       boolean not null,
  catatan     text
);

create function uji_seed.catat(n text, l boolean, c text default null)
returns void language sql
as $$ insert into uji_seed.hasil (pemeriksaan, lulus, catatan)
     values (n, l, c) $$;

create function uji_seed.capaian(p_kategori text, p_mundur int)
returns int language sql stable as $$
  select round(
           100.0 * count(*) filter (where cr.nilai = 'mudah')
           / nullif(count(*), 0)
         )::int
  from catatan_respons cr
  join jadwal_aktivitas ja on ja.id = cr.jadwal_aktivitas_id
  join aktivitas a on a.id = ja.aktivitas_id
  join rencana r on r.id = ja.rencana_id
  where r.profil_anak_id = 'd0000001-1111-4000-8000-000000000001'
    and a.kategori = p_kategori
    and r.periode_mulai = current_date - p_mundur
$$;

-- ================================================= tanggal relatif ==

do $$
declare v_akhir date; v_awal date;
begin
  select max(periode_selesai), min(periode_mulai) into v_akhir, v_awal
    from rencana
   where profil_anak_id = 'd0000001-1111-4000-8000-000000000001';

  perform uji_seed.catat('1. riwayat berakhir hari ini, bukan tanggal mati',
    v_akhir = current_date,
    format('berakhir %s, hari ini %s', v_akhir, current_date));

  perform uji_seed.catat('2. riwayat membentang tepat empat minggu',
    v_akhir - v_awal = 27, format('%s hari', v_akhir - v_awal));
end $$;

-- ========================================================== volume ==

do $$
declare v_jadwal int; v_catatan int; v_persen int;
begin
  select count(*) into v_jadwal
    from jadwal_aktivitas ja
    join rencana r on r.id = ja.rencana_id
   where r.profil_anak_id = 'd0000001-1111-4000-8000-000000000001';

  select count(*) into v_catatan
    from catatan_respons cr
    join jadwal_aktivitas ja on ja.id = cr.jadwal_aktivitas_id
    join rencana r on r.id = ja.rencana_id
   where r.profil_anak_id = 'd0000001-1111-4000-8000-000000000001';

  v_persen := round(100.0 * v_catatan / nullif(v_jadwal, 0));

  perform uji_seed.catat(
    '3. volume sesuai docs/07: 140 jadwal, 120 catatan, 86%',
    v_jadwal = 140 and v_catatan = 120 and v_persen = 86,
    format('%s jadwal, %s catatan, %s%%', v_jadwal, v_catatan, v_persen));
end $$;

-- ===================================================== bentuk tren ==
--
-- Yang diperiksa adalah arahnya, karena itulah yang docs/07 jelaskan alasannya
-- kolom demi kolom. Angka persisnya tidak dapat dicapai dengan enam sampel per
-- minggu, dan alasannya ditulis di kepala supabase/seed/demo.sql.

do $$
declare k1 int; k4 int;
begin
  k1 := uji_seed.capaian('komunikasi', 27);
  k4 := uji_seed.capaian('komunikasi', 6);
  perform uji_seed.catat('4. komunikasi naik konsisten',
    k4 > k1, format('minggu 1 %s%% -> minggu 4 %s%%', k1, k4));
end $$;

do $$
declare m1 int; m4 int;
begin
  m1 := uji_seed.capaian('motorik', 27);
  m4 := uji_seed.capaian('motorik', 6);
  perform uji_seed.catat('5. motorik datar',
    m1 = m4, format('minggu 1 %s%% -> minggu 4 %s%%', m1, m4));
end $$;

do $$
declare s1 int; s4 int;
begin
  s1 := uji_seed.capaian('sensorik', 27);
  s4 := uji_seed.capaian('sensorik', 6);
  perform uji_seed.catat('6. sensorik menurun',
    s4 < s1, format('minggu 1 %s%% -> minggu 4 %s%%', s1, s4));
end $$;

-- Yang paling penting di seluruh berkas ini. `D_tandai` menuntut tiga periode
-- terakhir menurun KETAT. Tanpa ini penanda perhatian tidak pernah tampil, dan
-- mesin adaptasi terlihat hanya bisa memuji.
do $$
declare p1 int; p2 int; p3 int;
begin
  p1 := uji_seed.capaian('sosial', 20);
  p2 := uji_seed.capaian('sosial', 13);
  p3 := uji_seed.capaian('sosial', 6);
  perform uji_seed.catat(
    '7. sosial menurun ketat tiga periode sehingga D_tandai menyala',
    p1 > p2 and p2 > p3, format('%s%% > %s%% > %s%%', p1, p2, p3));
end $$;

-- Empat kategori lain tidak boleh memenuhi syarat yang sama, supaya penandanya
-- berarti sesuatu.
do $$
declare k text; ikut text := '';
begin
  foreach k in array array['komunikasi', 'motorik', 'sensorik', 'kemandirian']
  loop
    if uji_seed.capaian(k, 20) > uji_seed.capaian(k, 13)
       and uji_seed.capaian(k, 13) > uji_seed.capaian(k, 6) then
      ikut := ikut || k || ' ';
    end if;
  end loop;

  perform uji_seed.catat('8. hanya sosial yang memicu penanda perhatian',
    ikut = '', case when ikut = '' then 'tidak ada kategori lain'
                    else 'ikut tertandai: ' || ikut end);
end $$;

-- ==================================================== isi lainnya ==

do $$
declare v int;
begin
  select count(*) into v from catatan_pengasuh where kondisi = 2;
  perform uji_seed.catat(
    '9. pola kelelahan pengasuh terlihat (ada hari bernilai 2)',
    v >= 3, format('%s hari bernilai 2', v));

  select count(distinct aturan_id) into v from adaptasi_log;
  perform uji_seed.catat('10. adaptasi_log mencakup lima aturan',
    v >= 5, format('%s aturan berbeda', v));

  select count(*) into v from adaptasi_log where alasan !~ '[0-9]';
  perform uji_seed.catat('11. setiap alasan adaptasi menyebut angka nyata',
    v = 0, format('%s baris tanpa angka', v));

  select count(*) into v
    from laporan where penanda_perhatian @> array['sosial'];
  perform uji_seed.catat('12. laporan membawa penanda perhatian sosial',
    v >= 1, format('%s laporan', v));

  select count(*) into v from izin_berbagi where status = 'aktif';
  perform uji_seed.catat('13. satu laporan sudah dibagikan ke profesional',
    v = 1, format('%s izin aktif', v));

  select count(*) into v from profesional where status_verifikasi = 'menunggu';
  perform uji_seed.catat('14. antrean verifikasi admin tidak kosong',
    v >= 2, format('%s pengajuan', v));

  select count(distinct jenis) into v from notifikasi;
  perform uji_seed.catat('15. notifikasi mencakup kelima jenis',
    v = 5, format('%s jenis', v));

  select count(*) into v from postingan_komunitas where anonim;
  perform uji_seed.catat('16. ada postingan anonim di komunitas',
    v = 2, format('%s postingan anonim', v));

  select count(*) into v from pengguna where adalah_demo;
  perform uji_seed.catat('17. akun demo ditandai sebagai demo',
    v >= 3, format('%s akun bertanda demo', v));

  select count(*) into v from profesional where terverifikasi;
  perform uji_seed.catat('18. direktori terisi untuk L.9',
    v >= 15, format('%s profesional terverifikasi', v));
end $$;

-- =========================================================== hasil ==

select urutan,
       case when lulus then 'LULUS' else 'GAGAL' end as hasil,
       pemeriksaan, catatan
from uji_seed.hasil order by urutan;

do $$
declare g int;
begin
  select count(*) filter (where not lulus) into g from uji_seed.hasil;
  if g > 0 then
    raise exception 'BLOCKER: % pemeriksaan seed gagal.', g;
  end if;
  raise notice 'Data demo sehat dan tidak basi.';
end $$;

drop schema uji_seed cascade;
