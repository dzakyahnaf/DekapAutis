-- 004 - Indexes.
--
-- Two groups. The retrieval indexes make hybrid search viable, and the rest
-- back the columns every RLS policy filters on: a policy that triggers a
-- sequential scan per row turns privacy into a performance problem, which is
-- how people end up weakening policies instead of indexing them.

-- ------------------------------------------------------- hybrid retrieval --

-- HNSW rather than the ivfflat in docs/03 §3, recorded in docs/DEVIATIONS.md.
-- With a corpus of roughly 1,000-2,000 chunks, ivfflat with lists=100 and the
-- default probes=1 searches about one percent of the data and recall collapses.
-- HNSW also needs no re-tuning when an administrator adds documents, which
-- KNF-08 says must be possible without shipping a new build.
--
-- Operator class is schema-qualified: the authenticated role does not carry
-- `extensions` in its search_path.
create index potongan_dokumen_embedding_hnsw
  on potongan_dokumen using hnsw (embedding extensions.vector_cosine_ops);

-- Full-text half of the hybrid. Vector search alone is poor on specific terms -
-- drug names, abbreviations, institution names - and full text alone is poor on
-- paraphrase. It is also the fallback path when the embedding API is down.
create index potongan_dokumen_tsv_gin
  on potongan_dokumen using gin (tsv);

create index potongan_dokumen_dokumen_id on potongan_dokumen (dokumen_id);
create index dokumen_pengetahuan_status on dokumen_pengetahuan (status_tinjauan);

-- ------------------------------------------------------------ plan & diary --

create index jadwal_aktivitas_rencana_tanggal on jadwal_aktivitas (rencana_id, tanggal);
create index jadwal_aktivitas_aktivitas_id on jadwal_aktivitas (aktivitas_id);
create index rencana_profil_anak_id on rencana (profil_anak_id, status);
create index profil_anak_pengguna_id on profil_anak (pengguna_id);
create index adaptasi_log_rencana_id on adaptasi_log (rencana_id, dibuat_pada desc);

-- The adaptation engine reads the last six responses in a category, so the
-- ordering column belongs in the index.
create index catatan_respons_dicatat_pada on catatan_respons (dicatat_pada desc);

-- Plan generation picks by category and level.
create index aktivitas_kategori_tingkat on aktivitas (kategori, tingkat);

-- ----------------------------------------------------- reports & consent --

create index laporan_profil_anak_id on laporan (profil_anak_id, periode_selesai desc);
create index izin_berbagi_profesional_status on izin_berbagi (profesional_id, status);
create index izin_berbagi_laporan_id on izin_berbagi (laporan_id, status);
create index tanggapan_profesional_laporan_id on tanggapan_profesional (laporan_id);
create index tanggapan_profesional_profesional_id on tanggapan_profesional (profesional_id);

-- --------------------------------------------------- directory & community --

create index profesional_pengguna_id on profesional (pengguna_id);
-- L.9 filters by city and verification before distance is computed client-side.
create index profesional_kota_terverifikasi on profesional (kota, terverifikasi);
create index postingan_komunitas_pengguna_id on postingan_komunitas (pengguna_id);
create index postingan_komunitas_terbit on postingan_komunitas (status, dibuat_pada desc);
create index balasan_komunitas_postingan_id on balasan_komunitas (postingan_id);
create index balasan_komunitas_pengguna_id on balasan_komunitas (pengguna_id);

-- --------------------------------------------------------- notifications --

create index notifikasi_pengguna_belum_dibaca on notifikasi (pengguna_id, dibaca, dibuat_pada desc);
create index catatan_pengasuh_pengguna_tanggal on catatan_pengasuh (pengguna_id, tanggal desc);

-- --------------------------------------------------------------- boundary --

create index log_batas_aman_kategori on log_batas_aman (kategori, dibuat_pada desc);
create index log_batas_aman_lapisan on log_batas_aman (lapisan_pemicu, dibuat_pada desc);
