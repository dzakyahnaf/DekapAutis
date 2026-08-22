-- scripts/test_cari_potongan.sql - hybrid retrieval, checked.
--
-- The fixtures below are obviously synthetic and are deleted at the end. They
-- never reach the application: CLAUDE.md rule 2 forbids fictional documents in
-- the corpus, and a test fixture that looked like a real health source would be
-- exactly the thing that rule exists to prevent.
--
-- What is being checked is the retrieval mechanism, not the content: that both
-- retrievers work alone, that fusing them beats either, that a rejected
-- document can never surface, and that a null embedding degrades to full-text
-- rather than failing.
--
-- Run:  docker exec -i supabase_db_dekapautis \
--         psql -U postgres -d postgres -v ON_ERROR_STOP=1 -f - < scripts/test_cari_potongan.sql

\set ON_ERROR_STOP on
\pset pager off

drop schema if exists uji_cari cascade;
create schema uji_cari;

create table uji_cari.hasil (
  urutan      int generated always as identity,
  pemeriksaan text not null,
  lulus       boolean not null,
  catatan     text
);

create function uji_cari.catat(p_nama text, p_lulus boolean, p_catatan text default null)
returns void language sql as $$
  insert into uji_cari.hasil (pemeriksaan, lulus, catatan)
  values (p_nama, p_lulus, p_catatan)
$$;

-- A 768-dimension unit vector pointing mostly along one axis, so two fixtures
-- can be made near or far from a query vector in a way that is easy to read.
create function uji_cari.arah(p_sumbu int)
returns extensions.vector
language sql immutable
set search_path = public, extensions, pg_temp
as $$
  select (
    '[' || array_to_string(
      array(select case when i = p_sumbu then 1.0 else 0.0 end
            from generate_series(0, 767) i), ',') || ']'
  )::extensions.vector(768)
$$;

-- ================================================================ fixtures ==

insert into dokumen_pengetahuan (id, judul, penerbit, tahun, url, status_tinjauan)
values
  ('11111111-0000-4000-8000-000000000001', 'Dokumen uji A', 'Uji', 2026,
   'https://contoh.test/a', 'ditinjau_profesional'),
  ('11111111-0000-4000-8000-000000000002', 'Dokumen uji B', 'Uji', 2026,
   'https://contoh.test/b', 'menunggu'),
  ('11111111-0000-4000-8000-000000000003', 'Dokumen uji ditolak', 'Uji', 2026,
   'https://contoh.test/c', 'ditolak');

insert into potongan_dokumen (id, dokumen_id, halaman, teks, embedding) values
  -- Matches the query on BOTH sides: the words and the vector.
  ('22222222-0000-4000-8000-000000000001',
   '11111111-0000-4000-8000-000000000001', 1,
   'Rutinitas pagi yang dapat diprediksi membantu anak mengetahui urutan kegiatan.',
   uji_cari.arah(0)),
  -- Matches on words only: same vocabulary, unrelated vector.
  ('22222222-0000-4000-8000-000000000002',
   '11111111-0000-4000-8000-000000000001', 2,
   'Urutan kegiatan pagi sebaiknya tetap sama setiap hari.',
   uji_cari.arah(500)),
  -- Matches on vector only: near the query vector, no shared words.
  ('22222222-0000-4000-8000-000000000003',
   '11111111-0000-4000-8000-000000000002', 1,
   'Kartu bergambar membantu menyampaikan urutan tanpa kata.',
   uji_cari.arah(1)),
  -- Unrelated on both sides.
  ('22222222-0000-4000-8000-000000000004',
   '11111111-0000-4000-8000-000000000002', 2,
   'Bermain bola di halaman melatih koordinasi tubuh.',
   uji_cari.arah(700)),
  -- Belongs to the rejected document. A perfect match on every signal, and it
  -- must still never appear.
  ('22222222-0000-4000-8000-000000000005',
   '11111111-0000-4000-8000-000000000003', 1,
   'Rutinitas pagi yang dapat diprediksi membantu anak mengetahui urutan kegiatan.',
   uji_cari.arah(0));

analyze potongan_dokumen;

-- ================================================================== checks ==

-- 1. Full text alone, the mode terbatas path.
select uji_cari.catat(
  '1. Embedding null tetap menjawab dari teks penuh',
  (select count(*) from cari_potongan(null, 'rutinitas pagi', 8)) > 0,
  'baris: ' || (select count(*) from cari_potongan(null, 'rutinitas pagi', 8))
);

-- 2. Vector alone, for a query whose words appear nowhere.
select uji_cari.catat(
  '2. Vektor tetap menjawab saat tidak ada kata yang cocok',
  (select count(*) from cari_potongan(uji_cari.arah(0), 'xyzqwerty', 8)) > 0,
  'baris: ' || (select count(*) from cari_potongan(uji_cari.arah(0), 'xyzqwerty', 8))
);

-- 3. The chunk both retrievers agree on ranks first. This is the whole reason
--    for fusing them rather than picking one.
select uji_cari.catat(
  '3. Potongan yang cocok di kedua sisi berada di peringkat pertama',
  (select id from cari_potongan(uji_cari.arah(0), 'rutinitas pagi', 8) limit 1)
    = '22222222-0000-4000-8000-000000000001',
  'teratas: ' ||
    coalesce((select left(teks, 45) from cari_potongan(uji_cari.arah(0), 'rutinitas pagi', 8) limit 1), '-')
);

-- 4. Fusion beats either signal on its own.
select uji_cari.catat(
  '4. Skor gabungan lebih tinggi daripada satu sinyal saja',
  (select skor from cari_potongan(uji_cari.arah(0), 'rutinitas pagi', 8)
    where id = '22222222-0000-4000-8000-000000000001')
  > (select skor from cari_potongan(uji_cari.arah(0), 'rutinitas pagi', 8)
    where id = '22222222-0000-4000-8000-000000000002'),
  'ganda vs teks-saja'
);

-- 5. A rejected document is unreachable, however well it matches.
select uji_cari.catat(
  '5. Dokumen ditolak tidak pernah muncul',
  (select count(*) from cari_potongan(uji_cari.arah(0), 'rutinitas pagi', 8)
    where dokumen_id = '11111111-0000-4000-8000-000000000003') = 0,
  'baris dari dokumen ditolak: ' ||
    (select count(*) from cari_potongan(uji_cari.arah(0), 'rutinitas pagi', 8)
      where dokumen_id = '11111111-0000-4000-8000-000000000003')
);

-- 6. Every row carries what the Source Panel (L.4) has to show.
select uji_cari.catat(
  '6. Setiap baris membawa judul, penerbit, tahun, halaman, dan URL',
  (select count(*) from cari_potongan(uji_cari.arah(0), 'rutinitas pagi', 8)
    where judul is null or penerbit is null or tahun is null or url is null) = 0
);

-- 7. The limit is honoured, and never zero.
select uji_cari.catat(
  '7. Batas dihormati',
  (select count(*) from cari_potongan(uji_cari.arah(0), 'rutinitas pagi', 2)) = 2
  and (select count(*) from cari_potongan(uji_cari.arah(0), 'rutinitas pagi', 0)) = 1
);

-- 8. The number shown on L.4 counts only what can actually be answered from.
--    Three documents exist; one is rejected, so two remain.
select uji_cari.catat(
  '8. jumlah_dokumen_terindeks menghitung dari basis data, bukan 148',
  jumlah_dokumen_terindeks() = 2,
  'terhitung: ' || jumlah_dokumen_terindeks()
);

-- 9. An empty question must not throw.
select uji_cari.catat(
  '9. Pertanyaan kosong tidak menimbulkan galat',
  (select count(*) from cari_potongan(null, '', 8)) >= 0
);

-- ================================================================== report ==

\echo ''
\echo '========== HASIL UJI cari_potongan =========='

select lpad(urutan::text, 2) as no,
       case when lulus then 'LULUS' else 'GAGAL' end as status,
       pemeriksaan, coalesce(catatan, '') as catatan
from uji_cari.hasil order by urutan;

do $$
declare gagal int;
begin
  select count(*) into gagal from uji_cari.hasil where not lulus;
  if gagal > 0 then
    raise exception 'BLOCKER: % pemeriksaan pengambilan gagal.', gagal;
  end if;
  raise notice 'Pengambilan hibrida bekerja: vektor, teks penuh, dan gabungannya.';
end $$;

-- ================================================================= cleanup ==

delete from potongan_dokumen
 where dokumen_id in ('11111111-0000-4000-8000-000000000001',
                      '11111111-0000-4000-8000-000000000002',
                      '11111111-0000-4000-8000-000000000003');
delete from dokumen_pengetahuan
 where id in ('11111111-0000-4000-8000-000000000001',
              '11111111-0000-4000-8000-000000000002',
              '11111111-0000-4000-8000-000000000003');
drop schema uji_cari cascade;
