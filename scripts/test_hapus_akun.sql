-- scripts/test_hapus_akun.sql - proof that deleting an account deletes the data.
--
-- Bab 4.3 promises the user can delete their account together with all related
-- data. This checks that with direct queries after the delete, because a
-- cascade is easy to believe in and easy to get wrong: one missing ON DELETE
-- CASCADE anywhere and a child's records outlive the account silently.
--
-- Run:  docker exec -i supabase_db_dekapautis \
--         psql -U postgres -d postgres -v ON_ERROR_STOP=1 -f - < scripts/test_hapus_akun.sql
--
-- A note on "12 tabel"
-- --------------------
-- PLAN.md F2 asks for zero rows in twelve tables. Three of those twelve -
-- aktivitas, dokumen_pengetahuan and potongan_dokumen - are the shared activity
-- catalogue and the shared knowledge corpus. They are not one person's data,
-- and emptying them when a single account leaves would wipe the product for
-- everyone. So this script proves two things instead of one:
--
--   * every table that holds this user's data reaches zero, all sixteen of them
--   * the three shared tables are untouched
--
-- The deviation is recorded in docs/DEVIATIONS.md.

\set ON_ERROR_STOP on
\pset pager off

drop schema if exists uji_hapus cascade;
create schema uji_hapus;

create table uji_hapus.hasil (
  urutan      int generated always as identity,
  tabel       text not null,
  jenis       text not null,   -- 'milik pengguna' | 'bersama'
  sebelum     bigint not null,
  sesudah     bigint not null,
  lulus       boolean not null
);

\set U '''12345678-dead-4000-8000-00000000beef'''

delete from auth.users where id = :U::uuid;

-- ============================================================== fixtures ==
-- One row in every table an account can own, so nothing is proved by absence.

insert into auth.users (id, email, raw_user_meta_data)
values (:U::uuid, 'hapus@dekapautis.test',
        '{"peran":"profesional","nama":"Akun Uji Hapus"}');

insert into profesional (id, pengguna_id, nama_lengkap, spesialisasi, kota)
values ('12345678-0001-4000-8000-00000000beef', :U::uuid,
        'Akun Uji Hapus', 'Terapi okupasi', 'Surabaya');

insert into profil_anak (id, pengguna_id, nama_panggilan, usia, kemampuan_komunikasi,
                         sensitivitas_sensorik, fokus_perkembangan)
values ('12345678-0002-4000-8000-00000000beef', :U::uuid, 'Anak Uji', 6,
        'beberapa_kata', '{suara_keras}', '{komunikasi_ekspresif}');

insert into rencana (id, profil_anak_id, periode_mulai, periode_selesai)
values ('12345678-0003-4000-8000-00000000beef',
        '12345678-0002-4000-8000-00000000beef', current_date, current_date + 6);

insert into aktivitas (id, kategori, tingkat, judul, tujuan, durasi_menit, langkah)
values ('12345678-0004-4000-8000-00000000beef', 'komunikasi', 2,
        'Aktivitas bersama', 'Tujuan uji', 10,
        '[{"urutan":1,"teks":"a"},{"urutan":2,"teks":"b"},{"urutan":3,"teks":"c"}]');

insert into jadwal_aktivitas (id, rencana_id, aktivitas_id, tanggal, waktu, urutan,
                              durasi_menit, tingkat_disesuaikan)
values ('12345678-0005-4000-8000-00000000beef',
        '12345678-0003-4000-8000-00000000beef',
        '12345678-0004-4000-8000-00000000beef', current_date, '08:00', 1, 10, 2);

insert into catatan_respons (jadwal_aktivitas_id, nilai, catatan, klien_id)
values ('12345678-0005-4000-8000-00000000beef', 'mudah', 'Catatan uji', 'klien-uji-1');

insert into catatan_pengasuh (pengguna_id, tanggal, kondisi)
values (:U::uuid, current_date, 3);

insert into laporan (id, profil_anak_id, periode_mulai, periode_selesai,
                     metrik, per_kategori, ringkasan)
values ('12345678-0006-4000-8000-00000000beef',
        '12345678-0002-4000-8000-00000000beef',
        current_date - 28, current_date, '{"a":1}', '[]', 'Ringkasan uji.');

insert into adaptasi_log (rencana_id, aturan_id, kategori, alasan)
values ('12345678-0003-4000-8000-00000000beef', 'A_naik', 'komunikasi',
        'Tingkat dinaikkan karena 2 dari 3 catatan terakhir menandai Mudah.');

insert into izin_berbagi (id, laporan_id, profesional_id)
values ('12345678-0007-4000-8000-00000000beef',
        '12345678-0006-4000-8000-00000000beef',
        '12345678-0001-4000-8000-00000000beef');

insert into tanggapan_profesional (laporan_id, profesional_id, isi)
values ('12345678-0006-4000-8000-00000000beef',
        '12345678-0001-4000-8000-00000000beef', 'Tanggapan uji.');

insert into postingan_komunitas (id, pengguna_id, topik, judul, isi)
values ('12345678-0008-4000-8000-00000000beef', :U::uuid, 'rutinitas',
        'Judul uji', 'Isi uji');

insert into balasan_komunitas (postingan_id, pengguna_id, isi)
values ('12345678-0008-4000-8000-00000000beef', :U::uuid, 'Balasan uji.');

insert into notifikasi (pengguna_id, jenis, judul)
values (:U::uuid, 'penyesuaian', 'Rencana Anda disesuaikan.');

-- The most identifying text in the system: a question that tripped the medical
-- boundary names the child almost every time.
insert into log_batas_aman (pengguna_id, pertanyaan, lapisan_pemicu, kategori)
values (:U::uuid, 'Apakah Anak Uji termasuk autis berat?', 'leksikon',
        'tingkat_spektrum');

-- Knowledge corpus: shared, and must survive.
insert into dokumen_pengetahuan (id, judul, penerbit, tahun, url)
values ('12345678-0009-4000-8000-00000000beef', 'Dokumen bersama', 'Uji', 2026,
        'https://contoh.test/bersama');
insert into potongan_dokumen (id, dokumen_id, halaman, teks)
values ('12345678-000a-4000-8000-00000000beef',
        '12345678-0009-4000-8000-00000000beef', 1, 'Potongan bersama.');

-- ============================================================ count before ==

create function uji_hapus.hitung(p_sql text) returns bigint
language plpgsql as $$
declare n bigint;
begin execute p_sql into n; return n; end $$;

create table uji_hapus.sebelum as
select 'pengguna' as tabel, 'milik pengguna' as jenis,
       uji_hapus.hitung(format('select count(*) from pengguna where id = %L', :U)) as n
union all select 'profil_anak', 'milik pengguna',
       uji_hapus.hitung(format('select count(*) from profil_anak where pengguna_id = %L', :U))
union all select 'rencana', 'milik pengguna',
       uji_hapus.hitung('select count(*) from rencana where id = ''12345678-0003-4000-8000-00000000beef''')
union all select 'jadwal_aktivitas', 'milik pengguna',
       uji_hapus.hitung('select count(*) from jadwal_aktivitas where id = ''12345678-0005-4000-8000-00000000beef''')
union all select 'catatan_respons', 'milik pengguna',
       uji_hapus.hitung('select count(*) from catatan_respons where klien_id = ''klien-uji-1''')
union all select 'catatan_pengasuh', 'milik pengguna',
       uji_hapus.hitung(format('select count(*) from catatan_pengasuh where pengguna_id = %L', :U))
union all select 'laporan', 'milik pengguna',
       uji_hapus.hitung('select count(*) from laporan where id = ''12345678-0006-4000-8000-00000000beef''')
union all select 'adaptasi_log', 'milik pengguna',
       uji_hapus.hitung('select count(*) from adaptasi_log where rencana_id = ''12345678-0003-4000-8000-00000000beef''')
union all select 'profesional', 'milik pengguna',
       uji_hapus.hitung(format('select count(*) from profesional where pengguna_id = %L', :U))
union all select 'izin_berbagi', 'milik pengguna',
       uji_hapus.hitung('select count(*) from izin_berbagi where id = ''12345678-0007-4000-8000-00000000beef''')
union all select 'tanggapan_profesional', 'milik pengguna',
       uji_hapus.hitung('select count(*) from tanggapan_profesional where profesional_id = ''12345678-0001-4000-8000-00000000beef''')
union all select 'postingan_komunitas', 'milik pengguna',
       uji_hapus.hitung(format('select count(*) from postingan_komunitas where pengguna_id = %L', :U))
union all select 'balasan_komunitas', 'milik pengguna',
       uji_hapus.hitung(format('select count(*) from balasan_komunitas where pengguna_id = %L', :U))
union all select 'notifikasi', 'milik pengguna',
       uji_hapus.hitung(format('select count(*) from notifikasi where pengguna_id = %L', :U))
union all select 'log_batas_aman', 'milik pengguna',
       uji_hapus.hitung(format('select count(*) from log_batas_aman where pengguna_id = %L', :U))
union all select 'auth.users', 'milik pengguna',
       uji_hapus.hitung(format('select count(*) from auth.users where id = %L', :U))
union all select 'aktivitas', 'bersama',
       uji_hapus.hitung('select count(*) from aktivitas where id = ''12345678-0004-4000-8000-00000000beef''')
union all select 'dokumen_pengetahuan', 'bersama',
       uji_hapus.hitung('select count(*) from dokumen_pengetahuan where id = ''12345678-0009-4000-8000-00000000beef''')
union all select 'potongan_dokumen', 'bersama',
       uji_hapus.hitung('select count(*) from potongan_dokumen where id = ''12345678-000a-4000-8000-00000000beef''');

-- Nothing is proved by counting zero before and zero after.
do $$
declare kosong text;
begin
  select string_agg(tabel, ', ') into kosong from uji_hapus.sebelum where n = 0;
  if kosong is not null then
    raise exception 'Fixture tidak lengkap, tabel ini kosong sebelum penghapusan: %', kosong;
  end if;
end $$;

-- ================================================================= delete ==
-- Exactly what the hapus-akun Edge Function does: one delete on auth.users.
-- Everything else has to fall out of the cascade, or the promise is not kept.

delete from auth.users where id = :U::uuid;

-- ============================================================= count after ==

insert into uji_hapus.hasil (tabel, jenis, sebelum, sesudah, lulus)
select s.tabel, s.jenis, s.n,
       a.n,
       case when s.jenis = 'milik pengguna' then a.n = 0 else a.n = s.n end
from uji_hapus.sebelum s
join lateral (
  select case s.tabel
    when 'pengguna'              then uji_hapus.hitung(format('select count(*) from pengguna where id = %L', :U))
    when 'profil_anak'           then uji_hapus.hitung(format('select count(*) from profil_anak where pengguna_id = %L', :U))
    when 'rencana'               then uji_hapus.hitung('select count(*) from rencana where id = ''12345678-0003-4000-8000-00000000beef''')
    when 'jadwal_aktivitas'      then uji_hapus.hitung('select count(*) from jadwal_aktivitas where id = ''12345678-0005-4000-8000-00000000beef''')
    when 'catatan_respons'       then uji_hapus.hitung('select count(*) from catatan_respons where klien_id = ''klien-uji-1''')
    when 'catatan_pengasuh'      then uji_hapus.hitung(format('select count(*) from catatan_pengasuh where pengguna_id = %L', :U))
    when 'laporan'               then uji_hapus.hitung('select count(*) from laporan where id = ''12345678-0006-4000-8000-00000000beef''')
    when 'adaptasi_log'          then uji_hapus.hitung('select count(*) from adaptasi_log where rencana_id = ''12345678-0003-4000-8000-00000000beef''')
    when 'profesional'           then uji_hapus.hitung(format('select count(*) from profesional where pengguna_id = %L', :U))
    when 'izin_berbagi'          then uji_hapus.hitung('select count(*) from izin_berbagi where id = ''12345678-0007-4000-8000-00000000beef''')
    when 'tanggapan_profesional' then uji_hapus.hitung('select count(*) from tanggapan_profesional where profesional_id = ''12345678-0001-4000-8000-00000000beef''')
    when 'postingan_komunitas'   then uji_hapus.hitung(format('select count(*) from postingan_komunitas where pengguna_id = %L', :U))
    when 'balasan_komunitas'     then uji_hapus.hitung(format('select count(*) from balasan_komunitas where pengguna_id = %L', :U))
    when 'notifikasi'            then uji_hapus.hitung(format('select count(*) from notifikasi where pengguna_id = %L', :U))
    when 'log_batas_aman'        then uji_hapus.hitung(format('select count(*) from log_batas_aman where pengguna_id = %L', :U))
    when 'auth.users'            then uji_hapus.hitung(format('select count(*) from auth.users where id = %L', :U))
    when 'aktivitas'             then uji_hapus.hitung('select count(*) from aktivitas where id = ''12345678-0004-4000-8000-00000000beef''')
    when 'dokumen_pengetahuan'   then uji_hapus.hitung('select count(*) from dokumen_pengetahuan where id = ''12345678-0009-4000-8000-00000000beef''')
    when 'potongan_dokumen'      then uji_hapus.hitung('select count(*) from potongan_dokumen where id = ''12345678-000a-4000-8000-00000000beef''')
  end as n
) a on true;

-- A leftover row that merely lost its owner still contains the text. Deleting
-- an account must not leave an anonymous copy of the question behind.
insert into uji_hapus.hasil (tabel, jenis, sebelum, sesudah, lulus)
select 'log_batas_aman (yatim)', 'milik pengguna', 1,
       count(*),
       count(*) = 0
from log_batas_aman
where pertanyaan like '%Anak Uji%';

-- ================================================================= report ==

\echo ''
\echo '============ HASIL UJI PENGHAPUSAN AKUN ============'

select lpad(urutan::text, 2) as no,
       case when lulus then 'LULUS' else 'GAGAL' end as status,
       jenis,
       tabel,
       sebelum,
       sesudah
from uji_hapus.hasil
order by jenis desc, urutan;

select count(*) filter (where jenis = 'milik pengguna' and lulus) || ' dari ' ||
       count(*) filter (where jenis = 'milik pengguna') ||
       ' tabel milik pengguna kosong'                            as milik_pengguna,
       count(*) filter (where jenis = 'bersama' and lulus) || ' dari ' ||
       count(*) filter (where jenis = 'bersama') ||
       ' tabel bersama utuh'                                     as bersama
from uji_hapus.hasil;

do $$
declare gagal int;
begin
  select count(*) into gagal from uji_hapus.hasil where not lulus;
  if gagal > 0 then
    raise exception 'BLOCKER: % pemeriksaan penghapusan gagal. Data pengguna tertinggal setelah akun dihapus.', gagal;
  end if;
  raise notice 'Penghapusan akun tuntas: nol baris tersisa di seluruh tabel milik pengguna, tabel bersama utuh.';
end $$;

-- ================================================================ cleanup ==

delete from potongan_dokumen where id = '12345678-000a-4000-8000-00000000beef';
delete from dokumen_pengetahuan where id = '12345678-0009-4000-8000-00000000beef';
delete from aktivitas where id = '12345678-0004-4000-8000-00000000beef';
drop schema uji_hapus cascade;
