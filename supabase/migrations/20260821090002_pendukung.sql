-- 002 - Supporting tables.
--
-- versi_basis_pengetahuan is not here: migration 001 needs it in place before
-- dokumen_pengetahuan can reference it. See the note at the top of 001.

-- Why the plan changed, in the caregiver's own language.
--
-- This table is what separates the adaptation engine from a black box. Every
-- rule application writes one row, and `alasan` must be a sentence citing real
-- numbers - never "the system adjusted your plan".
create table adaptasi_log (
  id               uuid primary key default gen_random_uuid(),
  rencana_id       uuid not null references rencana on delete cascade,
  aturan_id        text not null check (aturan_id in
                     ('A_naik', 'B_turun', 'C_porsi', 'D_tandai', 'E_jadwal')),
  kategori         text check (kategori in
                     ('komunikasi', 'motorik', 'sensorik', 'kemandirian', 'sosial')),
  nilai_sebelum    jsonb,
  nilai_sesudah    jsonb,
  alasan           text not null,
  -- A manual correction wins: the rules do not overwrite it in the same period.
  dikoreksi_manual boolean not null default false,
  dibuat_pada      timestamptz not null default now()
);

-- Every time a medical boundary fires, at whichever layer.
--
-- A spike in lapisan_pemicu='verifikasi_keluaran' means the model started
-- saying something it was instructed not to. We need to know that before a
-- judge finds it, which is why this is a table and not a log line.
create table log_batas_aman (
  id              uuid primary key default gen_random_uuid(),
  pengguna_id     uuid references pengguna on delete set null,
  pertanyaan      text not null,
  lapisan_pemicu  text not null check (lapisan_pemicu in
                    ('leksikon', 'klasifikasi', 'verifikasi_keluaran')),
  kategori        text not null check (kategori in
                    ('diagnosis', 'tingkat_spektrum', 'obat', 'dosis',
                     'klaim_sembuh', 'terapi_medis')),
  dibuat_pada     timestamptz not null default now()
);

-- Closes the loop of the business flow in Gambar 7.1: a caregiver shares a
-- report, a professional responds, and the response comes back to the caregiver.
create table tanggapan_profesional (
  id             uuid primary key default gen_random_uuid(),
  laporan_id     uuid not null references laporan on delete cascade,
  profesional_id uuid not null references profesional on delete cascade,
  isi            text not null,
  dibuat_pada    timestamptz not null default now()
);

create table postingan_komunitas (
  id          uuid primary key default gen_random_uuid(),
  pengguna_id uuid not null references pengguna on delete cascade,
  topik       text not null,
  judul       text not null,
  isi         text not null,
  -- When true the author's identity must never reach the client. That is
  -- enforced server-side by a view in migration 003, not by the client.
  anonim      boolean not null default false,
  status      text not null default 'terbit'
                check (status in ('terbit', 'ditinjau', 'dihapus')),
  dibuat_pada timestamptz not null default now()
);

create table balasan_komunitas (
  id           uuid primary key default gen_random_uuid(),
  postingan_id uuid not null references postingan_komunitas on delete cascade,
  pengguna_id  uuid not null references pengguna on delete cascade,
  isi          text not null,
  anonim       boolean not null default false,
  dibuat_pada  timestamptz not null default now()
);

create table notifikasi (
  id          uuid primary key default gen_random_uuid(),
  pengguna_id uuid not null references pengguna on delete cascade,
  jenis       text not null check (jenis in
                ('penyesuaian', 'belum_dicatat', 'balasan', 'artikel', 'jadwal')),
  judul       text not null,
  dibaca      boolean not null default false,
  dibuat_pada timestamptz not null default now()
);
