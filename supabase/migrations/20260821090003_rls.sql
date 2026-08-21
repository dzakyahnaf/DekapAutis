-- 003 - Row Level Security. Enabled on every table, default deny.
--
-- This is not paperwork. It is the privacy proof shown in the video, it is what
-- satisfies KNF-03 and KNF-04, and scripts/test_rls.sql fails the build if any
-- of it stops holding.
--
-- Why the helper functions exist
-- ------------------------------
-- A subquery inside a policy expression is still subject to the referenced
-- table's own RLS. The policy in docs/03 §4 lets a professional read a report
-- by looking into izin_berbagi and profesional - but a professional cannot see
-- those rows under their own policies, so the subquery returns nothing and the
-- professional can never read a shared report. The whole F6 sharing flow would
-- look broken for a reason invisible in the policy text.
--
-- Every helper below is SECURITY DEFINER with a pinned search_path, so it reads
-- the underlying tables as the owner and answers one narrow question.

-- ------------------------------------------------------------- role & self --

create or replace function public.uid_saya()
returns uuid language sql stable
set search_path = public, pg_temp
as $$ select auth.uid() $$;

create or replace function public.peran_saya()
returns text language sql stable security definer
set search_path = public, pg_temp
as $$ select peran from pengguna where id = auth.uid() $$;

create or replace function public.adalah_admin()
returns boolean language sql stable security definer
set search_path = public, pg_temp
as $$ select coalesce((select peran from pengguna where id = auth.uid()) = 'admin', false) $$;

-- The profesional row belonging to the caller, if any.
create or replace function public.profesional_saya()
returns uuid language sql stable security definer
set search_path = public, pg_temp
as $$ select id from profesional where pengguna_id = auth.uid() $$;

-- --------------------------------------------------------------- ownership --

create or replace function public.pemilik_profil_anak(p_id uuid)
returns uuid language sql stable security definer
set search_path = public, pg_temp
as $$ select pengguna_id from profil_anak where id = p_id $$;

create or replace function public.pemilik_rencana(p_id uuid)
returns uuid language sql stable security definer
set search_path = public, pg_temp
as $$
  select a.pengguna_id
  from rencana r join profil_anak a on a.id = r.profil_anak_id
  where r.id = p_id
$$;

-- catatan_respons carries no pengguna_id of its own, so ownership is three
-- joins away. Resolving it here keeps the policy readable and lets the planner
-- cache the result instead of re-deriving it per row.
create or replace function public.pemilik_jadwal(p_id uuid)
returns uuid language sql stable security definer
set search_path = public, pg_temp
as $$
  select a.pengguna_id
  from jadwal_aktivitas j
  join rencana r on r.id = j.rencana_id
  join profil_anak a on a.id = r.profil_anak_id
  where j.id = p_id
$$;

create or replace function public.pemilik_laporan(p_id uuid)
returns uuid language sql stable security definer
set search_path = public, pg_temp
as $$
  select a.pengguna_id
  from laporan l join profil_anak a on a.id = l.profil_anak_id
  where l.id = p_id
$$;

-- ------------------------------------------------------------- consent --

-- True only while an unrevoked izin_berbagi names the calling professional.
-- Revoking a consent must cut access off immediately, which is check 4 of
-- scripts/test_rls.sql.
create or replace function public.profesional_berizin(p_laporan_id uuid)
returns boolean language sql stable security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1
    from izin_berbagi i
    join profesional pr on pr.id = i.profesional_id
    where i.laporan_id = p_laporan_id
      and i.status = 'aktif'
      and pr.pengguna_id = auth.uid()
  )
$$;

-- A professional may read the child's nickname only for a child whose report
-- is currently shared with them - never the whole profile table.
create or replace function public.profesional_berizin_atas_anak(p_profil_anak_id uuid)
returns boolean language sql stable security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1
    from laporan l
    join izin_berbagi i on i.laporan_id = l.id
    join profesional pr on pr.id = i.profesional_id
    where l.profil_anak_id = p_profil_anak_id
      and i.status = 'aktif'
      and pr.pengguna_id = auth.uid()
  )
$$;

revoke execute on function
  public.peran_saya, public.adalah_admin, public.profesional_saya,
  public.pemilik_profil_anak, public.pemilik_rencana, public.pemilik_jadwal,
  public.pemilik_laporan, public.profesional_berizin,
  public.profesional_berizin_atas_anak
from public, anon;

grant execute on function
  public.uid_saya, public.peran_saya, public.adalah_admin, public.profesional_saya,
  public.pemilik_profil_anak, public.pemilik_rencana, public.pemilik_jadwal,
  public.pemilik_laporan, public.profesional_berizin,
  public.profesional_berizin_atas_anak
to authenticated;

-- ============================================================================
-- Default deny on everything.
-- ============================================================================

alter table pengguna                enable row level security;
alter table profil_anak             enable row level security;
alter table aktivitas               enable row level security;
alter table rencana                 enable row level security;
alter table jadwal_aktivitas        enable row level security;
alter table catatan_respons         enable row level security;
alter table catatan_pengasuh        enable row level security;
alter table laporan                 enable row level security;
alter table versi_basis_pengetahuan enable row level security;
alter table dokumen_pengetahuan     enable row level security;
alter table potongan_dokumen        enable row level security;
alter table profesional             enable row level security;
alter table izin_berbagi            enable row level security;
alter table adaptasi_log            enable row level security;
alter table log_batas_aman          enable row level security;
alter table tanggapan_profesional   enable row level security;
alter table postingan_komunitas     enable row level security;
alter table balasan_komunitas       enable row level security;
alter table notifikasi              enable row level security;

-- ---------------------------------------------------------------- identity --

create policy "pengguna_baca_diri" on pengguna
  for select to authenticated
  using (id = (select auth.uid()) or (select public.adalah_admin()));

create policy "pengguna_daftar_diri" on pengguna
  for insert to authenticated
  with check (id = (select auth.uid()));

create policy "pengguna_ubah_diri" on pengguna
  for update to authenticated
  using (id = (select auth.uid()))
  with check (id = (select auth.uid()));

create policy "pengguna_hapus_diri" on pengguna
  for delete to authenticated
  using (id = (select auth.uid()));

-- ---------------------------------------------------------- child profile --

create policy "pengasuh_kelola_anak_sendiri" on profil_anak
  for all to authenticated
  using (pengguna_id = (select auth.uid()))
  with check (pengguna_id = (select auth.uid()));

create policy "profesional_baca_anak_berizin" on profil_anak
  for select to authenticated
  using ((select public.profesional_berizin_atas_anak(profil_anak.id)));

-- ------------------------------------------------------- activity catalogue --

create policy "semua_baca_aktivitas" on aktivitas
  for select to authenticated using (true);

create policy "admin_kelola_aktivitas" on aktivitas
  for all to authenticated
  using ((select public.adalah_admin()))
  with check ((select public.adalah_admin()));

-- -------------------------------------------------------------------- plan --

create policy "pengasuh_kelola_rencana" on rencana
  for all to authenticated
  using ((select public.pemilik_profil_anak(rencana.profil_anak_id)) = (select auth.uid()))
  with check ((select public.pemilik_profil_anak(rencana.profil_anak_id)) = (select auth.uid()));

create policy "pengasuh_kelola_jadwal" on jadwal_aktivitas
  for all to authenticated
  using ((select public.pemilik_rencana(jadwal_aktivitas.rencana_id)) = (select auth.uid()))
  with check ((select public.pemilik_rencana(jadwal_aktivitas.rencana_id)) = (select auth.uid()));

create policy "pengasuh_kelola_adaptasi_log" on adaptasi_log
  for all to authenticated
  using ((select public.pemilik_rencana(adaptasi_log.rencana_id)) = (select auth.uid()))
  with check ((select public.pemilik_rencana(adaptasi_log.rencana_id)) = (select auth.uid()));

-- --------------------------------------------------------------- execution --

create policy "pengasuh_kelola_respons" on catatan_respons
  for all to authenticated
  using ((select public.pemilik_jadwal(catatan_respons.jadwal_aktivitas_id)) = (select auth.uid()))
  with check ((select public.pemilik_jadwal(catatan_respons.jadwal_aktivitas_id)) = (select auth.uid()));

-- "Hanya untuk Anda, tidak dibagikan" on L.2 is a promise the database keeps:
-- there is no policy that lets anyone else read this table, professionals and
-- administrators included.
create policy "pengasuh_kelola_check_in" on catatan_pengasuh
  for all to authenticated
  using (pengguna_id = (select auth.uid()))
  with check (pengguna_id = (select auth.uid()));

create policy "pengguna_kelola_notifikasi" on notifikasi
  for all to authenticated
  using (pengguna_id = (select auth.uid()))
  with check (pengguna_id = (select auth.uid()));

-- ------------------------------------------------------------------ report --

create policy "pemilik_kelola_laporan" on laporan
  for all to authenticated
  using ((select public.pemilik_profil_anak(laporan.profil_anak_id)) = (select auth.uid()))
  with check ((select public.pemilik_profil_anak(laporan.profil_anak_id)) = (select auth.uid()));

create policy "profesional_baca_laporan_berizin" on laporan
  for select to authenticated
  using ((select public.profesional_berizin(laporan.id)));

-- Consent is granted and withdrawn by the caregiver who owns the report.
create policy "pengasuh_kelola_izin" on izin_berbagi
  for all to authenticated
  using ((select public.pemilik_laporan(izin_berbagi.laporan_id)) = (select auth.uid()))
  with check ((select public.pemilik_laporan(izin_berbagi.laporan_id)) = (select auth.uid()));

create policy "profesional_baca_izin_sendiri" on izin_berbagi
  for select to authenticated
  using (profesional_id = (select public.profesional_saya()));

create policy "profesional_tulis_tanggapan" on tanggapan_profesional
  for insert to authenticated
  with check (
    profesional_id = (select public.profesional_saya())
    and (select public.profesional_berizin(tanggapan_profesional.laporan_id))
  );

create policy "baca_tanggapan_terkait" on tanggapan_profesional
  for select to authenticated
  using (
    (select public.pemilik_laporan(tanggapan_profesional.laporan_id)) = (select auth.uid())
    or profesional_id = (select public.profesional_saya())
  );

-- --------------------------------------------------------------- knowledge --

create policy "semua_baca_versi" on versi_basis_pengetahuan
  for select to authenticated using (true);
create policy "admin_kelola_versi" on versi_basis_pengetahuan
  for all to authenticated
  using ((select public.adalah_admin())) with check ((select public.adalah_admin()));

create policy "semua_baca_dokumen" on dokumen_pengetahuan
  for select to authenticated using (true);
create policy "admin_kelola_dokumen" on dokumen_pengetahuan
  for all to authenticated
  using ((select public.adalah_admin())) with check ((select public.adalah_admin()));

create policy "semua_baca_potongan" on potongan_dokumen
  for select to authenticated using (true);
create policy "admin_kelola_potongan" on potongan_dokumen
  for all to authenticated
  using ((select public.adalah_admin())) with check ((select public.adalah_admin()));

-- --------------------------------------------------------- professionals --

-- The directory is meant to be browsed, so any signed-in user may read it.
create policy "semua_baca_profesional" on profesional
  for select to authenticated using (true);

create policy "profesional_kelola_profil_sendiri" on profesional
  for all to authenticated
  using (pengguna_id = (select auth.uid()))
  with check (pengguna_id = (select auth.uid()));

create policy "admin_kelola_profesional" on profesional
  for all to authenticated
  using ((select public.adalah_admin())) with check ((select public.adalah_admin()));

-- A professional owns their own row, so without this guard they could simply
-- set terverifikasi = true on themselves. Verification is an administrator's
-- decision, and a self-awarded badge on a health directory is exactly the kind
-- of fabricated credential this product must not display.
create or replace function public.jaga_verifikasi_profesional()
returns trigger language plpgsql security definer
set search_path = public, pg_temp
as $$
begin
  if (new.terverifikasi is distinct from old.terverifikasi
      or new.diverifikasi_pada is distinct from old.diverifikasi_pada)
     and not public.adalah_admin() then
    raise exception 'Status verifikasi hanya dapat diubah oleh administrator';
  end if;
  return new;
end;
$$;

create trigger jaga_verifikasi
  before update on profesional
  for each row execute function public.jaga_verifikasi_profesional();

-- --------------------------------------------------------------- community --

-- Anonymity is enforced on the server. The base table only ever returns the
-- caller's own rows, so an author's identity is not something the client is
-- trusted to hide - it never reaches the client at all.
create policy "penulis_kelola_postingan" on postingan_komunitas
  for all to authenticated
  using (pengguna_id = (select auth.uid()) or (select public.adalah_admin()))
  with check (pengguna_id = (select auth.uid()) or (select public.adalah_admin()));

create policy "penulis_kelola_balasan" on balasan_komunitas
  for all to authenticated
  using (pengguna_id = (select auth.uid()) or (select public.adalah_admin()))
  with check (pengguna_id = (select auth.uid()) or (select public.adalah_admin()));

-- Everyone reads the community through these views instead. They run with the
-- owner's rights, filter to published rows, and drop the author's name whenever
-- anonim is set.
create view postingan_publik with (security_invoker = off) as
  select p.id,
         p.topik,
         p.judul,
         p.isi,
         p.anonim,
         p.dibuat_pada,
         case when p.anonim then null else u.nama end as nama_penulis,
         (select count(*) from balasan_komunitas b where b.postingan_id = p.id)
           as jumlah_balasan
  from postingan_komunitas p
  join pengguna u on u.id = p.pengguna_id
  where p.status = 'terbit';

create view balasan_publik with (security_invoker = off) as
  select b.id,
         b.postingan_id,
         b.isi,
         b.anonim,
         b.dibuat_pada,
         case when b.anonim then null else u.nama end as nama_penulis
  from balasan_komunitas b
  join pengguna u on u.id = b.pengguna_id
  join postingan_komunitas p on p.id = b.postingan_id
  where p.status = 'terbit';

grant select on postingan_publik, balasan_publik to authenticated;

-- ------------------------------------------------------ safety boundary log --

-- Written by the ask Edge Function under the service role. No client policy
-- grants read access: the questions recorded here are the most sensitive text
-- in the system, because a caregiver only trips the boundary by asking
-- something about their own child.
create policy "admin_baca_log_batas_aman" on log_batas_aman
  for select to authenticated
  using ((select public.adalah_admin()));

-- ============================================================================
-- Table privileges.
--
-- RLS decides which rows a role may touch. GRANT decides whether it may touch
-- the table at all, and the two are independent - which cuts both ways here.
--
-- docs/03 §4 warns that newer Supabase projects need explicit grants for
-- PostgREST. Measured on this database, the default privileges for tables
-- created by `postgres` in `public` hand anon and authenticated exactly
-- `Dxtm`: TRUNCATE, REFERENCES, TRIGGER, MAINTAIN - and none of SELECT,
-- INSERT, UPDATE or DELETE. So two things were wrong at once:
--
--   1. Nothing worked. Every client call failed on permission before RLS was
--      ever consulted.
--   2. TRUNCATE was granted, and TRUNCATE ignores RLS completely. Any signed-in
--      account could have run `truncate aktivitas cascade` and taken the
--      activity catalogue, every schedule and every response record with it,
--      for every user. With demo credentials published in the submission and
--      judging running unattended for ten days, that is not a theoretical risk.
--
-- So: revoke everything first, then grant back only what is actually used.
-- ============================================================================

revoke all on all tables in schema public from public, anon, authenticated;
revoke all on all sequences in schema public from public, anon, authenticated;

-- Row access is decided by the policies above; without a matching policy these
-- grants still yield nothing, because RLS is default deny.
grant select, insert, update, delete on all tables in schema public to authenticated;
grant usage, select on all sequences in schema public to authenticated;

-- Edge Functions run as service_role and bypass RLS by design. They are the
-- only path allowed to write log_batas_aman and to read potongan_dokumen for
-- retrieval.
grant all on all tables in schema public to service_role;
grant all on all sequences in schema public to service_role;

-- anon keeps schema usage so PostgREST can answer, and nothing else: every
-- screen in this product requires a signed-in account.

-- Future tables inherit the same shape, so a later migration cannot quietly
-- reintroduce the TRUNCATE grant.
alter default privileges in schema public
  revoke all on tables from public, anon, authenticated;
alter default privileges in schema public
  grant select, insert, update, delete on tables to authenticated;
alter default privileges in schema public
  grant all on tables to service_role;

-- The community views are read through, never written.
grant select on postingan_publik, balasan_publik to authenticated;
