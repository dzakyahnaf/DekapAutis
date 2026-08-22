-- F7 - directory, schedule requests, community moderation, notifications.
--
-- Three things this migration is responsible for:
--
--   1. Author identity stops leaving the database. The community views used to
--      emit `nama_penulis` - the author's full name - for any post not marked
--      anonymous, and relied on the client to render initials. That is the
--      wrong side of the wire. docs/05 L.11 says a community card shows an
--      initial or an "Anonim" chip, never a name, so the view now emits an
--      initial and the name never crosses the boundary at all.
--
--   2. A schedule request records a request and notifies. Nothing more.
--      Bab 4.1 rules out payment and in-app consultation sessions, so there is
--      deliberately no amount, no currency, no invoice, no room id, and no
--      session state anywhere in `pengajuan_jadwal`. If a future change wants
--      one of those, it should have to add the column and explain why.
--
--   3. The word filter in the client is layer one. `laporan_penyalahgunaan` is
--      layer two: what a human reports and an administrator works through.

-- ------------------------------------------------------------------ initials --

-- Two letters at most, from the first two words of a name.
--
-- Kept in SQL rather than in Dart on purpose: it runs inside the view, so the
-- client is never sent the name it was derived from. Doing it client-side would
-- mean shipping the name and trimming it on arrival, which is the exact thing
-- this migration exists to stop.
create or replace function public.inisial_dari(p_nama text)
returns text language sql immutable
set search_path = pg_temp
as $$
  -- Whitespace is collapsed first. split_part counts empty fields, so a name
  -- typed with two spaces between the words would otherwise yield one initial
  -- instead of two - which is exactly the kind of thing nobody notices until a
  -- real user types it.
  select coalesce(
    nullif(
      upper(substr(split_part(bersih, ' ', 1), 1, 1)) ||
      upper(substr(split_part(bersih, ' ', 2), 1, 1)),
      ''
    ),
    '?'
  )
  from (
    select regexp_replace(btrim(coalesce(p_nama, '')), '\s+', ' ', 'g') as bersih
  ) t
$$;

grant execute on function public.inisial_dari to authenticated;

-- --------------------------------------------------------- community views --

drop view if exists public.balasan_publik;
drop view if exists public.postingan_publik;

-- `security_invoker = off` so the view reads the base table as its owner and
-- can therefore show every published post, while the base table's own RLS
-- still limits direct access to the author's own rows.
--
-- Note what is absent: `pengguna_id` and `nama`. Neither appears in the select
-- list, so no amount of client-side carelessness can display them. `milik_saya`
-- is how the client decides whether to offer edit and delete without ever
-- learning who anyone else is.
create view public.postingan_publik with (security_invoker = off) as
  select p.id,
         p.topik,
         p.judul,
         p.isi,
         p.anonim,
         p.dibuat_pada,
         case when p.anonim then null else public.inisial_dari(u.nama) end
           as inisial,
         (p.pengguna_id = auth.uid()) as milik_saya,
         (select count(*)
            from balasan_komunitas b
           where b.postingan_id = p.id) as jumlah_balasan
  from postingan_komunitas p
  join pengguna u on u.id = p.pengguna_id
  where p.status = 'terbit';

create view public.balasan_publik with (security_invoker = off) as
  select b.id,
         b.postingan_id,
         b.isi,
         b.anonim,
         b.dibuat_pada,
         case when b.anonim then null else public.inisial_dari(u.nama) end
           as inisial,
         (b.pengguna_id = auth.uid()) as milik_saya
  from balasan_komunitas b
  join pengguna u on u.id = b.pengguna_id
  join postingan_komunitas p on p.id = b.postingan_id
  where p.status = 'terbit';

grant select on public.postingan_publik, public.balasan_publik to authenticated;

-- ---------------------------------------------------------- schedule requests --

create table if not exists public.pengajuan_jadwal (
  id              uuid primary key default gen_random_uuid(),
  pengasuh_id     uuid not null references pengguna on delete cascade,
  profesional_id  uuid not null references profesional on delete cascade,
  -- Which child the appointment concerns. Set null rather than cascade so
  -- removing a child profile does not silently erase the professional's
  -- record of a request they already answered.
  anak_id         uuid references profil_anak on delete set null,
  hari            text not null,
  jam             text not null,
  catatan         text,
  status          text not null default 'menunggu'
                    check (status in ('menunggu', 'disetujui', 'ditolak', 'dibatalkan')),
  -- Why a request was declined, in the professional's own words.
  alasan          text,
  -- Idempotency for the offline write queue, same contract as the other
  -- queued writes: replaying a request never creates a second one.
  klien_id        uuid unique,
  dibuat_pada     timestamptz not null default now(),
  ditanggapi_pada timestamptz,
  constraint ditanggapi_punya_waktu check (
    (status in ('disetujui', 'ditolak') and ditanggapi_pada is not null) or
    (status in ('menunggu', 'dibatalkan'))
  )
);

comment on table public.pengajuan_jadwal is
  'Records a request for an appointment and notifies the professional. '
  'No payment and no in-app session: Bab 4.1 rules both out.';

-- ------------------------------------------------------------- abuse reports --

create table if not exists public.laporan_penyalahgunaan (
  id             uuid primary key default gen_random_uuid(),
  -- Set null on delete: an account closing must not erase the report an
  -- administrator is still working through.
  pelapor_id     uuid references pengguna on delete set null,
  postingan_id   uuid references postingan_komunitas on delete cascade,
  balasan_id     uuid references balasan_komunitas on delete cascade,
  kategori       text not null
                   check (kategori in ('batas_medis', 'kasar', 'spam', 'lainnya')),
  -- What the client-side filter matched, when it was the filter that raised
  -- this. Kept so a false positive can be traced back to its phrase rather
  -- than argued about.
  frasa          text,
  catatan        text,
  status         text not null default 'menunggu'
                   check (status in ('menunggu', 'ditindak', 'ditolak')),
  ditangani_oleh uuid references pengguna on delete set null,
  dibuat_pada    timestamptz not null default now(),
  ditangani_pada timestamptz,
  constraint sasaran_tepat_satu
    check (num_nonnulls(postingan_id, balasan_id) = 1)
);

-- --------------------------------------------------------------- notifications --

-- Where the row takes you when tapped. Without it L.17 is a list you can read
-- and not act on, which is most of the point of a notification.
alter table public.notifikasi
  add column if not exists tautan text;

-- Raised by the server, not by the client.
--
-- A notification that only fires when the client remembers to insert it is a
-- notification that stops firing the first time a write is retried from the
-- offline queue. This fires from the row itself.
create or replace function public.beritahu_pengajuan_jadwal()
returns trigger language plpgsql security definer
set search_path = public, pg_temp
as $$
declare
  v_akun_profesional uuid;
begin
  if tg_op = 'INSERT' then
    select pengguna_id into v_akun_profesional
      from profesional where id = new.profesional_id;

    if v_akun_profesional is not null then
      insert into notifikasi (pengguna_id, jenis, judul, tautan)
      values (v_akun_profesional, 'jadwal',
              'Permintaan jadwal baru', '/profesional/masuk-kotak');
    end if;

  elsif tg_op = 'UPDATE'
        and new.status is distinct from old.status
        and new.status in ('disetujui', 'ditolak') then
    insert into notifikasi (pengguna_id, jenis, judul, tautan)
    values (new.pengasuh_id, 'jadwal',
            case when new.status = 'disetujui'
                 then 'Pengajuan jadwal disetujui'
                 -- Not "ditolak": the caregiver did nothing wrong, and a
                 -- practice being full is not a rejection of them.
                 else 'Pengajuan jadwal belum dapat dipenuhi' end,
            '/direktori/' || new.profesional_id);
  end if;

  return new;
end $$;

drop trigger if exists trg_beritahu_pengajuan_jadwal on public.pengajuan_jadwal;
create trigger trg_beritahu_pengajuan_jadwal
  after insert or update on public.pengajuan_jadwal
  for each row execute function public.beritahu_pengajuan_jadwal();

-- ----------------------------------------------------------------------- RLS --

alter table public.pengajuan_jadwal        enable row level security;
alter table public.laporan_penyalahgunaan  enable row level security;
alter table public.pengajuan_jadwal        force row level security;
alter table public.laporan_penyalahgunaan  force row level security;

drop policy if exists "pengasuh_kelola_pengajuan" on public.pengajuan_jadwal;
create policy "pengasuh_kelola_pengajuan" on public.pengajuan_jadwal
  for all to authenticated
  using (pengasuh_id = public.uid_saya())
  with check (pengasuh_id = public.uid_saya());

-- The professional sees requests addressed to them and answers them. They
-- cannot create one on a caregiver's behalf: the `with check` keeps an update
-- from moving a request onto a different practice.
drop policy if exists "profesional_tanggapi_pengajuan" on public.pengajuan_jadwal;
create policy "profesional_tanggapi_pengajuan" on public.pengajuan_jadwal
  for select to authenticated
  using (profesional_id = public.profesional_saya());

drop policy if exists "profesional_ubah_pengajuan" on public.pengajuan_jadwal;
create policy "profesional_ubah_pengajuan" on public.pengajuan_jadwal
  for update to authenticated
  using (profesional_id = public.profesional_saya())
  with check (profesional_id = public.profesional_saya());

-- Anyone signed in may report, and may see what they reported. Nobody but an
-- administrator sees anyone else's reports: a queue that the reported person
-- can read is a queue that gets used to retaliate.
drop policy if exists "pelapor_kelola_laporan" on public.laporan_penyalahgunaan;
create policy "pelapor_kelola_laporan" on public.laporan_penyalahgunaan
  for insert to authenticated
  with check (pelapor_id = public.uid_saya());

drop policy if exists "pelapor_baca_laporan_sendiri" on public.laporan_penyalahgunaan;
create policy "pelapor_baca_laporan_sendiri" on public.laporan_penyalahgunaan
  for select to authenticated
  using (pelapor_id = public.uid_saya());

drop policy if exists "admin_kelola_penyalahgunaan" on public.laporan_penyalahgunaan;
create policy "admin_kelola_penyalahgunaan" on public.laporan_penyalahgunaan
  for all to authenticated
  using (public.adalah_admin())
  with check (public.adalah_admin());

-- An administrator moderating the community needs to reach a post whose status
-- the author has not set to 'terbit'. Without this the moderation queue can
-- name a post nobody with the power to act on it can open.
drop policy if exists "admin_kelola_postingan" on public.postingan_komunitas;
create policy "admin_kelola_postingan" on public.postingan_komunitas
  for all to authenticated
  using (public.adalah_admin())
  with check (public.adalah_admin());

drop policy if exists "admin_kelola_balasan" on public.balasan_komunitas;
create policy "admin_kelola_balasan" on public.balasan_komunitas
  for all to authenticated
  using (public.adalah_admin())
  with check (public.adalah_admin());

-- ------------------------------------------------------------------- indexes --

create index if not exists pengajuan_untuk_profesional
  on public.pengajuan_jadwal (profesional_id, status, dibuat_pada desc);
create index if not exists pengajuan_milik_pengasuh
  on public.pengajuan_jadwal (pengasuh_id, dibuat_pada desc);
create index if not exists pengajuan_anak
  on public.pengajuan_jadwal (anak_id);

create index if not exists penyalahgunaan_antrean
  on public.laporan_penyalahgunaan (status, dibuat_pada);
create index if not exists penyalahgunaan_postingan
  on public.laporan_penyalahgunaan (postingan_id);
create index if not exists penyalahgunaan_balasan
  on public.laporan_penyalahgunaan (balasan_id);
create index if not exists penyalahgunaan_pelapor
  on public.laporan_penyalahgunaan (pelapor_id);
create index if not exists penyalahgunaan_penangan
  on public.laporan_penyalahgunaan (ditangani_oleh);

-- L.11 lists published posts newest first; L.9 filters professionals by city.
create index if not exists postingan_terbit
  on public.postingan_komunitas (status, dibuat_pada desc);
create index if not exists balasan_per_postingan
  on public.balasan_komunitas (postingan_id, dibuat_pada);
create index if not exists profesional_kota
  on public.profesional (kota) where terverifikasi;
create index if not exists notifikasi_milik_pengguna
  on public.notifikasi (pengguna_id, dibuat_pada desc);

-- ------------------------------------------------------------------- grants --

-- The blanket grant in migration 003 covered the tables that existed then.
-- These two arrived later, so they need their own - and RLS above is what
-- actually decides who sees which rows.
grant select, insert, update, delete
  on public.pengajuan_jadwal, public.laporan_penyalahgunaan
  to authenticated;
