-- 001 - Core entities.
--
-- The twelve entities of Gambar 6.4, in dependency order. The design keeps
-- identity, child profile, activity execution and knowledge apart so access
-- policy can differ per group and a full account deletion stays simple.
--
-- Deviation from docs/03 §1, recorded in docs/DEVIATIONS.md: the doc declares
-- dokumen_pengetahuan.versi_id as a reference to versi_basis_pengetahuan while
-- creating that table in migration 002. A forward reference to a table that
-- does not exist yet fails on the very first migration, so it is created here.

create extension if not exists vector with schema extensions;

-- ---------------------------------------------------------------- identity --

create table pengguna (
  id            uuid primary key references auth.users on delete cascade,
  peran         text not null check (peran in ('pengasuh', 'profesional', 'admin')),
  nama          text not null,
  email         text not null,
  mode_tenang   boolean not null default false,
  skala_teks    text not null default 'standar'
                  check (skala_teks in ('standar', 'besar', 'sangat_besar')),
  kurangi_gerak boolean not null default false,
  -- Demo rows are synthetic and the app says so on screen. They are never
  -- disguised as a real user.
  adalah_demo   boolean not null default false,
  dibuat_pada   timestamptz not null default now()
);

comment on column pengguna.adalah_demo is
  'Marks a seeded demo account. The UI shows an "Akun demo" chip for these.';

-- Role assignment at sign-up (KF-01).
--
-- Every policy in migration 003 reads pengguna.peran, so an auth user without a
-- matching pengguna row would be locked out of everything with no obvious
-- cause. This trigger makes "every auth user has exactly one pengguna row" an
-- invariant of the database rather than something the client must remember,
-- which also covers the Google OAuth path where no form is submitted.
create or replace function public.tangani_pengguna_baru()
returns trigger language plpgsql security definer
set search_path = public, pg_temp
as $$
begin
  insert into public.pengguna (id, peran, nama, email)
  values (
    new.id,
    -- Anything other than the three known roles falls back to pengasuh, so a
    -- malformed sign-up cannot mint an administrator.
    case new.raw_user_meta_data ->> 'peran'
      when 'profesional' then 'profesional'
      when 'admin' then 'admin'
      else 'pengasuh'
    end,
    coalesce(
      nullif(new.raw_user_meta_data ->> 'nama', ''),
      nullif(new.raw_user_meta_data ->> 'full_name', ''),
      split_part(coalesce(new.email, ''), '@', 1),
      'Pengguna'
    ),
    coalesce(new.email, '')
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

create trigger pada_pengguna_baru
  after insert on auth.users
  for each row execute function public.tangani_pengguna_baru();

-- ----------------------------------------------------------- child profile --

create table profil_anak (
  id                    uuid primary key default gen_random_uuid(),
  pengguna_id           uuid not null references pengguna on delete cascade,
  nama_panggilan        text not null,
  usia                  int not null check (usia between 1 and 18),
  kemampuan_komunikasi  text not null check (kemampuan_komunikasi in
                          ('belum_verbal', 'beberapa_kata', 'kalimat_pendek', 'lancar')),
  sensitivitas_sensorik text[] not null default '{}',
  fokus_perkembangan    text[] not null default '{}',
  dibuat_pada           timestamptz not null default now()
);

-- ------------------------------------------------------- activity catalogue --

-- System-owned and readable by everyone. Deliberately NOT per-user data: a
-- caregiver deleting their account must not empty the catalogue for everyone.
create table aktivitas (
  id                     uuid primary key default gen_random_uuid(),
  kategori               text not null check (kategori in
                           ('komunikasi', 'motorik', 'sensorik', 'kemandirian', 'sosial')),
  tingkat                int not null check (tingkat between 1 and 4),
  judul                  text not null,
  tujuan                 text not null,
  -- docs/07 §5 sets the catalogue at 5-20 minutes. The constraint matches that
  -- rather than the looser 5-45 in docs/03, so it can actually catch a bad seed.
  durasi_menit           int not null check (durasi_menit between 5 and 20),
  alat                   text[] not null default '{}',
  langkah                jsonb not null,          -- [{urutan, teks}]
  -- Attached by the adaptation engine when rule B_turun lowers a level.
  saran_lingkungan       text,
  cocok_untuk_komunikasi text[] not null default '{}',
  constraint langkah_adalah_larik check (jsonb_typeof(langkah) = 'array'),
  constraint langkah_3_sampai_6 check (jsonb_array_length(langkah) between 3 and 6)
);

-- -------------------------------------------------------------------- plan --

create table rencana (
  id             uuid primary key default gen_random_uuid(),
  profil_anak_id uuid not null references profil_anak on delete cascade,
  periode_mulai  date not null,
  periode_selesai date not null,
  status         text not null default 'aktif'
                   check (status in ('aktif', 'selesai', 'digantikan')),
  dibuat_pada    timestamptz not null default now(),
  constraint periode_masuk_akal check (periode_selesai >= periode_mulai)
);

create table jadwal_aktivitas (
  id                  uuid primary key default gen_random_uuid(),
  rencana_id          uuid not null references rencana on delete cascade,
  aktivitas_id        uuid not null references aktivitas,
  tanggal             date not null,
  waktu               time not null,
  urutan              int not null,
  durasi_menit        int not null check (durasi_menit >= 5),
  tingkat_disesuaikan int not null check (tingkat_disesuaikan between 1 and 4)
);

-- --------------------------------------------------------------- execution --

create table catatan_respons (
  id                  uuid primary key default gen_random_uuid(),
  jadwal_aktivitas_id uuid not null references jadwal_aktivitas on delete cascade,
  nilai               text not null check (nilai in ('mudah', 'pas', 'sulit')),
  catatan             text,
  dicatat_pada        timestamptz not null default now(),
  -- Idempotency for offline sync: the device mints this UUID, so replaying a
  -- queued write cannot produce a duplicate row.
  klien_id            text unique,
  -- docs/03 §5 resolves conflicts as last-write-wins on the grounds that one
  -- activity has exactly one response. Without this constraint that claim is
  -- not enforceable and two queued writes would produce two rows instead.
  constraint satu_respons_per_jadwal unique (jadwal_aktivitas_id)
);

create table catatan_pengasuh (
  id          uuid primary key default gen_random_uuid(),
  pengguna_id uuid not null references pengguna on delete cascade,
  tanggal     date not null,
  -- 1 berat .. 5 baik. This is the caregiver rating their own day, never the
  -- child: the product must not produce a single score of a child's ability.
  kondisi     int not null check (kondisi between 1 and 5),
  unique (pengguna_id, tanggal)
);

-- ------------------------------------------------------------------ report --

create table laporan (
  id                uuid primary key default gen_random_uuid(),
  profil_anak_id    uuid not null references profil_anak on delete cascade,
  periode_mulai     date not null,
  periode_selesai   date not null,
  metrik            jsonb not null,   -- {aktivitas_selesai, catatan_tercatat, rata_sesi_harian}
  per_kategori      jsonb not null,   -- [{kategori, persen, tren}]
  ringkasan         text not null,    -- narrative produced by summarize-report
  penanda_perhatian text[] not null default '{}',
  dibuat_pada       timestamptz not null default now(),
  constraint periode_laporan_masuk_akal check (periode_selesai >= periode_mulai)
);

-- --------------------------------------------------------------- knowledge --

create table versi_basis_pengetahuan (
  id                uuid primary key default gen_random_uuid(),
  label             text not null,
  catatan           text,
  diterbitkan_pada  timestamptz not null default now()
);

create table dokumen_pengetahuan (
  id              uuid primary key default gen_random_uuid(),
  judul           text not null,
  penerbit        text not null,
  tahun           int not null,
  -- Every document must have a real, openable source. There are no fictional
  -- documents in this corpus: one dead link and the whole RAG pillar loses
  -- its credibility, which costs far more than a small corpus does.
  url             text not null,
  status_tinjauan text not null default 'menunggu'
                    check (status_tinjauan in ('menunggu', 'ditinjau_profesional', 'ditolak')),
  versi_id        uuid references versi_basis_pengetahuan,
  dibuat_pada     timestamptz not null default now()
);

create table potongan_dokumen (
  id          uuid primary key default gen_random_uuid(),
  dokumen_id  uuid not null references dokumen_pengetahuan on delete cascade,
  halaman     int,
  teks        text not null,
  -- 768 dimensions, locked. Changing this means re-embedding the whole corpus.
  -- Schema-qualified because the authenticated role does not carry `extensions`
  -- in its search_path - only postgres does.
  embedding   extensions.vector(768),
  tsv         tsvector generated always as (to_tsvector('indonesian', teks)) stored
);

-- ------------------------------------------------- professionals & consent --

create table profesional (
  id                uuid primary key default gen_random_uuid(),
  pengguna_id       uuid not null references pengguna on delete cascade,
  nama_lengkap      text not null,
  gelar             text,
  spesialisasi      text not null,
  tentang           text,
  layanan           text[] not null default '{}',
  jadwal_praktik    jsonb not null default '[]',
  lokasi_lat        double precision check (lokasi_lat between -90 and 90),
  lokasi_lng        double precision check (lokasi_lng between -180 and 180),
  kota              text,
  terverifikasi     boolean not null default false,
  diverifikasi_pada timestamptz
);

-- Sharing is per report and per action, and it can be withdrawn. Revoking must
-- actually cut access off, which is the second RLS proof in scripts/test_rls.sql.
create table izin_berbagi (
  id             uuid primary key default gen_random_uuid(),
  laporan_id     uuid not null references laporan on delete cascade,
  profesional_id uuid not null references profesional on delete cascade,
  ruang_lingkup  text not null default 'laporan',
  status         text not null default 'aktif' check (status in ('aktif', 'dicabut')),
  diberikan_pada timestamptz not null default now(),
  dicabut_pada   timestamptz,
  constraint dicabut_punya_waktu check (
    (status = 'dicabut' and dicabut_pada is not null) or
    (status = 'aktif' and dicabut_pada is null)
  )
);
