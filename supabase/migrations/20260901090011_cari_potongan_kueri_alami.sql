-- Pengambilan teks penuh gagal untuk pertanyaan yang ditulis manusia.
--
-- `websearch_to_tsquery('indonesian', ...)` menggabungkan SELURUH kata dengan
-- AND, termasuk kata umum yang kamus `indonesian` ternyata tidak buang:
--
--   'Bagaimana cara membangun rutinitas pagi yang bisa diprediksi?'
--     -> 'bagaimana' & 'cara' & 'bangun' & 'rutinitas' & 'pagi' & 'yang'
--        & 'bisa' & 'prediksi'
--
-- Tidak ada satu pun potongan yang memuat kedelapan kata itu sekaligus, jadi
-- hasilnya nol. Kata tunggal seperti 'autisme' mengembalikan delapan potongan,
-- sementara pertanyaan utuh mengembalikan nol - dan pertanyaan utuh persis
-- itulah yang diketik pengasuh.
--
-- Ditemukan oleh `scripts/eval_groundedness.py`: 0 dari 20 pertanyaan aman
-- mengambil apa pun, padahal korpusnya berisi 31 dokumen dan 190 potongan.
--
-- Perbaikannya dua tahap, bukan sekadar mengganti AND menjadi OR. AND lebih
-- dulu, karena kalau frasa lengkapnya memang ada di korpus, itulah jawaban
-- terbaik. Bila AND tidak menghasilkan apa-apa, barulah OR - dan `ts_rank`
-- yang menentukan urutannya. Mengganti langsung ke OR akan membuang presisi
-- yang sebenarnya bisa didapat gratis.

create or replace function public.cari_potongan(
  p_embedding extensions.vector(768),
  p_kueri text,
  p_batas int default 8
)
returns table (
  id uuid,
  dokumen_id uuid,
  halaman int,
  teks text,
  judul text,
  penerbit text,
  tahun int,
  url text,
  skor double precision
)
language sql
stable
set search_path = public, extensions, pg_temp
as $$
  with kueri as (
    select
      websearch_to_tsquery('indonesian', coalesce(p_kueri, '')) as q_ketat,
      -- Versi longgar: lekseme yang sama, digabung OR. Dibentuk dari hasil
      -- websearch_to_tsquery supaya stemming Bahasa Indonesia dan pembuangan
      -- tanda baca tetap berlaku - bukan dipecah sendiri dari teks mentah.
      nullif(
        replace(
          websearch_to_tsquery('indonesian', coalesce(p_kueri, ''))::text,
          ' & ', ' | '
        ), ''
      )::tsquery as q_longgar
  ),
  vektor as (
    select s.id, row_number() over () as urutan
    from (
      select p.id
      from potongan_dokumen p
      where p_embedding is not null
        and p.embedding is not null
      order by p.embedding <=> p_embedding
      limit 30
    ) s
  ),
  teks_ketat as (
    select p.id, ts_rank(p.tsv, k.q_ketat) as peringkat
    from potongan_dokumen p, kueri k
    where k.q_ketat is not null and p.tsv @@ k.q_ketat
    order by peringkat desc
    limit 30
  ),
  teks as (
    select s.id, row_number() over () as urutan
    from (
      select p.id
      from potongan_dokumen p, kueri k
      where
        case
          when exists (select 1 from teks_ketat) then p.tsv @@ k.q_ketat
          else k.q_longgar is not null and p.tsv @@ k.q_longgar
        end
      order by ts_rank(
        p.tsv,
        case when exists (select 1 from teks_ketat)
             then k.q_ketat else k.q_longgar end
      ) desc
      limit 30
    ) s
  ),
  gabung as (
    -- Reciprocal Rank Fusion, k = 60 seperti di makalah aslinya dan di docs/04.
    select
      coalesce(v.id, t.id) as id,
      coalesce(1.0 / (60 + v.urutan), 0) + coalesce(1.0 / (60 + t.urutan), 0)
        as skor
    from vektor v
    full outer join teks t on t.id = v.id
  )
  select
    p.id,
    p.dokumen_id,
    p.halaman,
    p.teks,
    d.judul,
    d.penerbit,
    d.tahun,
    d.url,
    g.skor
  from gabung g
  join potongan_dokumen p on p.id = g.id
  join dokumen_pengetahuan d on d.id = p.dokumen_id
  -- Dokumen yang ditolak administrator tidak boleh menjadi sumber jawaban
  -- kesehatan, berapa pun tinggi skor kemiripannya.
  where d.status_tinjauan <> 'ditolak'
  order by g.skor desc
  -- greatest(...,1): pemanggil yang mengirim 0 tetap mendapat satu baris, bukan
  -- jawaban kosong. Klausa ini ada di versi pertama fungsi dan sempat hilang
  -- dalam penulisan ulang ini - ditangkap oleh pemeriksaan 7 di
  -- scripts/test_cari_potongan.sql, bukan oleh membaca ulang.
  limit greatest(p_batas, 1)
$$;
