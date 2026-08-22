-- 007 - Hybrid retrieval as one RPC.
--
-- pgvector cosine similarity fused with Indonesian full-text search using
-- Reciprocal Rank Fusion. Not a luxury: vector search alone is poor on specific
-- terms - drug names, abbreviations, institution names - and full text alone is
-- poor on paraphrase. Fusing them also hands us a free fallback for when the
-- embedding API is down, which during judging week is the difference between a
-- degraded answer and no answer.
--
-- Two corrections to the query in docs/04
-- ---------------------------------------
-- 1. The published version computes row_number() OVER (ORDER BY embedding <=> $1)
--    directly on potongan_dokumen. Window functions are evaluated before ORDER
--    BY and LIMIT, so Postgres sorts the entire table and the vector index is
--    never used at all. The ranking is correct and the performance is not. Here
--    each side takes its top-N in a subquery first, and the numbering happens
--    over those rows.
-- 2. It LEFT JOINs from the full table and then filters, which scans everything.
--    A FULL OUTER JOIN of the two candidate sets says what was meant.
--
-- A null embedding is a supported input, not an error: it is the "mode terbatas"
-- path, where the answer comes from full-text search alone.

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
-- SECURITY INVOKER on purpose: RLS already lets any signed-in account read the
-- curated corpus, so this needs no elevated rights. The pinned search_path is
-- what matters - the authenticated role does not carry `extensions`, and
-- without it the <=> operator would not resolve.
set search_path = public, extensions, pg_temp
as $$
  with kueri as (
    select websearch_to_tsquery('indonesian', coalesce(p_kueri, '')) as q
  ),
  vektor as (
    -- Top-N by cosine distance. Taken in a subquery so the HNSW index is
    -- actually used, then numbered.
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
  teks as (
    select s.id, row_number() over () as urutan
    from (
      select p.id
      from potongan_dokumen p, kueri k
      where k.q is not null
        and p.tsv @@ k.q
      order by ts_rank(p.tsv, k.q) desc
      limit 30
    ) s
  ),
  gabung as (
    -- Reciprocal Rank Fusion. 60 is the constant the original paper uses and
    -- the one docs/04 specifies; it flattens the difference between ranks 1 and
    -- 2 enough that neither retriever dominates the other.
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
  -- A rejected document is one an administrator looked at and turned down. It
  -- must never end up as the source of a health answer. Filtering here rather
  -- than inside the two candidate sets keeps the index paths clean.
  where d.status_tinjauan <> 'ditolak'
  order by g.skor desc, p.id
  limit greatest(p_batas, 1);
$$;

comment on function public.cari_potongan is
  'Hybrid retrieval: pgvector cosine fused with Indonesian full-text via RRF. '
  'A null embedding falls back to full-text alone (mode terbatas).';

-- How many documents the assistant can actually answer from.
--
-- The L.4 footer states this number, and CLAUDE.md rule 2 requires it to come
-- from the database rather than from the mockup, which said 148. A document
-- only counts if it survived review and has at least one indexed chunk: one
-- that was uploaded but never indexed is not something we can answer from, and
-- saying otherwise would be the same kind of unearned claim.
create or replace function public.jumlah_dokumen_terindeks()
returns int
language sql
stable
set search_path = public, pg_temp
as $$
  select count(distinct d.id)::int
  from dokumen_pengetahuan d
  join potongan_dokumen p on p.dokumen_id = d.id
  where d.status_tinjauan <> 'ditolak';
$$;

revoke execute on function public.cari_potongan(extensions.vector, text, int)
  from public, anon;
revoke execute on function public.jumlah_dokumen_terindeks() from public, anon;

grant execute on function public.cari_potongan(extensions.vector, text, int)
  to authenticated, service_role;
grant execute on function public.jumlah_dokumen_terindeks()
  to authenticated, service_role;

-- URL is the natural key of a document: two rows pointing at the same page are
-- the same source, however the title was typed. scripts/index_corpus.py relies
-- on this to be idempotent, and docs/07 §6 requires that a re-run cannot double
-- the corpus - a quietly doubled corpus makes every retrieval score meaningless.
alter table dokumen_pengetahuan
  add constraint dokumen_pengetahuan_url_unik unique (url);
