-- F9 - the professional and administrator roles, and closing the loop.
--
-- Gambar 7.1 draws a circle: a report leaves the caregiver, a professional
-- answers it, and the answer comes back and changes the plan. Until now the
-- circle stopped at `tanggapan_profesional.isi` - a paragraph of prose that a
-- human could read and nothing could act on.
--
-- This migration adds the part that can be acted on, and it is deliberately
-- small: a set of categories to emphasise and an optional session length. The
-- prose stays prose and is never parsed. Two reasons for splitting it that way:
--
--   1. A plan change has to be deterministic and explainable. `adaptasi_log`
--      must be able to say which real numbers moved, and it cannot do that
--      from a sentence.
--   2. Nothing a professional writes should silently rewrite a child's plan.
--      The structured part is a *proposal*; the caregiver applies it, and
--      `status` records whether they did.

-- ------------------------------------------------------ structured response --

alter table public.tanggapan_profesional
  add column if not exists saran_kategori text[] not null default '{}',
  add column if not exists saran_durasi_menit int,
  add column if not exists status text not null default 'baru',
  add column if not exists ditindaklanjuti_pada timestamptz,
  add column if not exists klien_id uuid;

do $$
begin
  if not exists (select 1 from pg_constraint
                  where conname = 'tanggapan_status_sah') then
    alter table public.tanggapan_profesional
      add constraint tanggapan_status_sah
      check (status in ('baru', 'dibaca', 'diterapkan', 'ditolak'));
  end if;

  -- A duration a professional suggests still has to be a duration the plan can
  -- hold. The engine's floor is 5 minutes; an hour is already long for a child
  -- who finds sessions hard.
  if not exists (select 1 from pg_constraint
                  where conname = 'tanggapan_durasi_masuk_akal') then
    alter table public.tanggapan_profesional
      add constraint tanggapan_durasi_masuk_akal
      check (saran_durasi_menit is null
             or saran_durasi_menit between 5 and 60);
  end if;

  if not exists (select 1 from pg_constraint
                  where conname = 'tanggapan_kategori_sah') then
    alter table public.tanggapan_profesional
      add constraint tanggapan_kategori_sah
      check (saran_kategori <@ array['komunikasi', 'motorik', 'sensorik',
                                     'kemandirian', 'sosial']::text[]);
  end if;

  if not exists (select 1 from pg_constraint
                  where conname = 'tanggapan_klien_id_unik') then
    alter table public.tanggapan_profesional
      add constraint tanggapan_klien_id_unik unique (klien_id);
  end if;
end $$;

-- The caregiver marks a response read, applied, or declined. They may not
-- touch the text or the suggestion - only what they did about it.
drop policy if exists "pengasuh_tindak_lanjuti_tanggapan"
  on public.tanggapan_profesional;
create policy "pengasuh_tindak_lanjuti_tanggapan"
  on public.tanggapan_profesional
  for update to authenticated
  using (
    (select public.pemilik_laporan(tanggapan_profesional.laporan_id))
      = (select auth.uid())
  )
  with check (
    (select public.pemilik_laporan(tanggapan_profesional.laporan_id))
      = (select auth.uid())
  );

-- A response reaches the caregiver as a notification, raised by the server so
-- it cannot be forgotten by whichever client wrote the row.
create or replace function public.beritahu_tanggapan_profesional()
returns trigger language plpgsql security definer
set search_path = public, pg_temp
as $$
declare
  v_pengasuh uuid;
begin
  select pa.pengguna_id into v_pengasuh
    from laporan l
    join profil_anak pa on pa.id = l.profil_anak_id
   where l.id = new.laporan_id;

  if v_pengasuh is not null then
    insert into notifikasi (pengguna_id, jenis, judul, tautan)
    values (v_pengasuh, 'penyesuaian',
            'Tanggapan baru dari tenaga profesional',
            '/profil/laporan');
  end if;

  return new;
end $$;

drop trigger if exists trg_beritahu_tanggapan on public.tanggapan_profesional;
create trigger trg_beritahu_tanggapan
  after insert on public.tanggapan_profesional
  for each row execute function public.beritahu_tanggapan_profesional();

-- `adaptasi_log` accepted only the five automatic rules of F4. A plan change a
-- professional asked for and a caregiver approved is a sixth kind, and it has
-- to be recordable in the same place - a plan that moved without a row in this
-- table is exactly the black box the log exists to prevent.
alter table public.adaptasi_log
  drop constraint if exists adaptasi_log_aturan_id_check;
alter table public.adaptasi_log
  add constraint adaptasi_log_aturan_id_check
  check (aturan_id in ('A_naik', 'B_turun', 'C_porsi', 'D_tandai', 'E_jadwal',
                       'F_profesional'));

-- ------------------------------------------------- professional onboarding --

alter table public.profesional
  add column if not exists bukti_kredensial text,
  add column if not exists status_verifikasi text not null default 'menunggu',
  add column if not exists alasan_penolakan text,
  add column if not exists diajukan_pada timestamptz not null default now(),
  add column if not exists ditinjau_oleh uuid references pengguna on delete set null;

do $$
begin
  if not exists (select 1 from pg_constraint
                  where conname = 'verifikasi_status_sah') then
    alter table public.profesional
      add constraint verifikasi_status_sah
      check (status_verifikasi in ('menunggu', 'disetujui', 'ditolak'));
  end if;

  -- A rejection without a reason is not a decision anybody can act on. The
  -- practice has to be told what to fix.
  if not exists (select 1 from pg_constraint
                  where conname = 'penolakan_punya_alasan') then
    alter table public.profesional
      add constraint penolakan_punya_alasan
      check (status_verifikasi <> 'ditolak'
             or (alasan_penolakan is not null and btrim(alasan_penolakan) <> ''));
  end if;
end $$;

-- `terverifikasi` is what the directory filters on and what the badge reads.
-- Keeping it in step with `status_verifikasi` here rather than asking every
-- caller to set both means the badge cannot disagree with the decision.
create or replace function public.selaraskan_verifikasi()
returns trigger language plpgsql
set search_path = public, pg_temp
as $$
begin
  new.terverifikasi := (new.status_verifikasi = 'disetujui');
  new.diverifikasi_pada := case
    when new.status_verifikasi = 'disetujui'
      then coalesce(new.diverifikasi_pada, now())
    else null
  end;
  return new;
end $$;

drop trigger if exists trg_selaraskan_verifikasi on public.profesional;
create trigger trg_selaraskan_verifikasi
  before insert or update on public.profesional
  for each row execute function public.selaraskan_verifikasi();

-- Admins decide verification. The existing "admin_kelola_profesional" policy
-- already grants the write; this only records who decided.

-- ------------------------------------------------------- knowledge base ops --

alter table public.dokumen_pengetahuan
  add column if not exists perlu_indeks_ulang boolean not null default false,
  add column if not exists diindeks_pada timestamptz,
  add column if not exists diminta_indeks_pada timestamptz;

-- Reindexing is requested, not performed.
--
-- The embedding call needs an API key, and CLAUDE.md rule 4 keeps those out of
-- the client entirely. So the admin screen flags the document and
-- `scripts/index_corpus.py` picks it up. The screen says "menunggu indexing
-- ulang" rather than showing a spinner over work that is not happening, which
-- is the honest version of this button.
create or replace function public.minta_indeks_ulang(p_dokumen_id uuid)
returns void language plpgsql security definer
set search_path = public, pg_temp
as $$
begin
  if not public.adalah_admin() then
    raise exception 'Hanya administrator yang dapat meminta indexing ulang.';
  end if;

  update dokumen_pengetahuan
     set perlu_indeks_ulang = true,
         diminta_indeks_pada = now()
   where id = p_dokumen_id;
end $$;

revoke execute on function public.minta_indeks_ulang from public, anon;
grant execute on function public.minta_indeks_ulang to authenticated;

-- What the indexer asks for on its next run.
create or replace view public.antrean_indeks with (security_invoker = on) as
  select id, judul, penerbit, url, status_tinjauan, diminta_indeks_pada
  from dokumen_pengetahuan
  where perlu_indeks_ulang
  order by diminta_indeks_pada;

grant select on public.antrean_indeks to authenticated;

-- ------------------------------------------------------------------ indexes --

create index if not exists tanggapan_per_laporan
  on public.tanggapan_profesional (laporan_id, dibuat_pada desc);
create index if not exists tanggapan_per_profesional
  on public.tanggapan_profesional (profesional_id, dibuat_pada desc);
create index if not exists tanggapan_belum_ditindak
  on public.tanggapan_profesional (status) where status = 'baru';

create index if not exists profesional_antrean_verifikasi
  on public.profesional (status_verifikasi, diajukan_pada)
  where status_verifikasi = 'menunggu';
create index if not exists profesional_peninjau
  on public.profesional (ditinjau_oleh);

create index if not exists dokumen_perlu_indeks
  on public.dokumen_pengetahuan (diminta_indeks_pada)
  where perlu_indeks_ulang;

-- Existing rows predate `status_verifikasi`; bring them in line with the badge
-- they already carry so the queue does not suddenly list every seeded practice.
update public.profesional
   set status_verifikasi = case when terverifikasi then 'disetujui' else 'menunggu' end
 where status_verifikasi = 'menunggu' and terverifikasi;
