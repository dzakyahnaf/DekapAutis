-- scripts/test_katalog.sql - content limits for the activity catalogue.
--
-- docs/07 §5 sets limits that no amount of care remembers on its own once
-- someone is adding the sixty-first activity in a hurry. They are checked here
-- instead.
--
-- Run:  docker exec -i supabase_db_dekapautis \
--         psql -U postgres -d postgres -v ON_ERROR_STOP=1 -f - < scripts/test_katalog.sql

\set ON_ERROR_STOP on
\pset pager off

drop schema if exists uji_katalog cascade;
create schema uji_katalog;

create table uji_katalog.hasil (
  urutan      int generated always as identity,
  pemeriksaan text not null,
  pelanggar   int not null,
  contoh      text,
  lulus       boolean not null
);

-- Everything an activity says, in one string, so a rule only has to be written
-- once rather than per column.
create view uji_katalog.teks as
select id, kategori, tingkat, judul,
       lower(
         judul || ' ' || tujuan || ' ' || coalesce(saran_lingkungan, '') || ' ' ||
         array_to_string(alat, ' ') || ' ' ||
         (select string_agg(l ->> 'teks', ' ') from jsonb_array_elements(langkah) l)
       ) as isi
from aktivitas;

create function uji_katalog.periksa(p_nama text, p_pola text) returns void
language plpgsql as $$
declare n int; c text;
begin
  select count(*), min(judul) into n, c
  from uji_katalog.teks where isi ~ p_pola;
  insert into uji_katalog.hasil (pemeriksaan, pelanggar, contoh, lulus)
  values (p_nama, n, c, n = 0);
end $$;

-- Shape --------------------------------------------------------------------

insert into uji_katalog.hasil (pemeriksaan, pelanggar, contoh, lulus)
select 'Tepat 60 aktivitas', abs(count(*) - 60)::int, count(*)::text, count(*) = 60
from aktivitas;

insert into uji_katalog.hasil (pemeriksaan, pelanggar, contoh, lulus)
select 'Tiap kategori x tingkat berisi 3 varian', count(*)::int,
       min(kategori || ' L' || tingkat), count(*) = 0
from (select kategori, tingkat from aktivitas group by 1, 2 having count(*) <> 3) s;

insert into uji_katalog.hasil (pemeriksaan, pelanggar, contoh, lulus)
select 'Durasi 5-20 menit', count(*)::int, min(judul), count(*) = 0
from aktivitas where durasi_menit not between 5 and 20;

insert into uji_katalog.hasil (pemeriksaan, pelanggar, contoh, lulus)
select 'Langkah 3-6 buah', count(*)::int, min(judul), count(*) = 0
from aktivitas where jsonb_array_length(langkah) not between 3 and 6;

insert into uji_katalog.hasil (pemeriksaan, pelanggar, contoh, lulus)
select 'Durasi rata-rata naik tiap tingkat', count(*)::int,
       min('tingkat ' || tingkat), count(*) = 0
from (
  select tingkat, avg(durasi_menit) a,
         lag(avg(durasi_menit)) over (order by tingkat) sebelumnya
  from aktivitas group by tingkat
) s where sebelumnya is not null and a <= sebelumnya;

insert into uji_katalog.hasil (pemeriksaan, pelanggar, contoh, lulus)
select 'Punya saran_lingkungan untuk aturan B_turun', count(*)::int, min(judul),
       count(*) = 0
from aktivitas where coalesce(saran_lingkungan, '') = '';

-- Content limits -----------------------------------------------------------

-- Naming a licensed method implies the app delivers it. It does not, and
-- claiming so would be the clearest possible breach of Bab 4.2.
select uji_katalog.periksa(
  'Tidak menamai metode terapi berlisensi',
  -- The bare acronym ABA is deliberately not matched on its own: "aba-aba" is
  -- ordinary Indonesian for a cue, and matching it flagged a ball game. The
  -- spelled-out names and the "metode/terapi X" shape catch the real case.
  '\m(applied behavior|analisis perilaku terapan|teacch|pecs|floortime|son-?rise|snoezelen|makaton|integrasi sensori|(metode|terapi) (aba|dir|rdi|abm)\M)'
);

-- The app does not diagnose, grade, or treat.
select uji_katalog.periksa(
  'Tidak memakai bahasa klinis atau diagnosis',
  '\m(diagnosis|didiagnosis|terapi wicara|sesi terapi|protokol|asesmen|skrining|derajat|tingkat keparahan|gejala|kelainan|gangguan)'
);

-- Bab II is about the cost of therapy. An activity that requires buying
-- something argues against the product it belongs to.
select uji_katalog.periksa(
  'Tidak mensyaratkan alat yang harus dibeli',
  -- \M closes the word: without it, "toko" matched "tokoh" in "tiga tokoh".
  '\m(beli\M|membeli\M|harga\M|toko\M|pesan online|alat terapi|khusus terapi|sensory kit)'
);

-- No promise that anything is reached in any timeframe.
select uji_katalog.periksa(
  'Tidak menjanjikan hasil dalam jangka waktu',
  '(dalam (satu|dua|tiga|empat|[0-9]+) (hari|minggu|bulan)|akan bisa|pasti bisa|dijamin|terbukti meningkat|sembuh|kesembuhan|menyembuhkan|normal kembali)'
);

-- Nothing that restrains a child or withholds a response as leverage.
select uji_katalog.periksa(
  'Tidak memuat pengekangan, penghukuman, atau penahanan respons',
  '\m(tahan tangan|pegang erat|kekang|paksa|memaksa|hukum|hukuman|abaikan sampai|diamkan sampai|jangan diberi|tolak sampai|larang)'
);

-- Steps address the child by name.
select uji_katalog.periksa(
  'Tidak menyebut anak sebagai penderita, pasien, atau si anak',
  '\m(penderita|penyandang|pasien|si anak|anak tersebut|subjek)'
);

-- The catalogue is shared, so it must never contain a real child's name.
insert into uji_katalog.hasil (pemeriksaan, pelanggar, contoh, lulus)
select 'Memakai placeholder {nama}, bukan nama sungguhan', count(*)::int,
       min(judul), count(*) = 0
from aktivitas
where (tujuan || (select string_agg(l ->> 'teks', ' ')
                  from jsonb_array_elements(langkah) l)) !~ '\{nama\}';

insert into uji_katalog.hasil (pemeriksaan, pelanggar, contoh, lulus)
select 'Tidak ada nama demo yang bocor ke katalog bersama', count(*)::int,
       min(judul), count(*) = 0
from uji_katalog.teks where isi ~ '\m(bima|rina)\M';

-- Report -------------------------------------------------------------------

\echo ''
\echo '============ HASIL UJI KATALOG AKTIVITAS ============'

select lpad(urutan::text, 2) as no,
       case when lulus then 'LULUS' else 'GAGAL' end as status,
       pemeriksaan,
       case when lulus then '' else pelanggar || ' pelanggar, mis. ' || coalesce(contoh, '-') end
         as catatan
from uji_katalog.hasil order by urutan;

do $$
declare gagal int;
begin
  select count(*) into gagal from uji_katalog.hasil where not lulus;
  if gagal > 0 then
    raise exception 'BLOCKER: % aturan isi katalog dilanggar.', gagal;
  end if;
  raise notice 'Katalog memenuhi seluruh batas isi docs/07 bagian 5.';
end $$;

drop schema uji_katalog cascade;
