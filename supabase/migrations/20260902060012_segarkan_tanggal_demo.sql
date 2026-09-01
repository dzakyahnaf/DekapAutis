-- Keeps the demo account's window ending today, every day, for the whole
-- judging period.
--
-- The seed anchors every date to `current_date` at the moment it runs. That is
-- right once and wrong from the next morning on: the calendar advances, the
-- data does not, and the home screen loses a day each time. Judging runs to
-- 11 September, so without this a judge opening the app in the second week
-- finds "Rencana hari ini" empty.
--
-- Shifting rather than re-seeding is deliberate. Re-seeding would restore the
-- dates but throw away anything a judge recorded, and it would churn every id.
-- A shift preserves rows, ids, and every invariant scripts/test_seed_demo.sql
-- asserts: the four weekly trend shapes, the 86% recorded ratio, and Sosial
-- declining across the last three periods so rule D_tandai still fires.
--
-- The target is today in Asia/Jakarta, not `current_date`. The database runs in
-- UTC, so from 00:00 to 07:00 WIB `current_date` still reads yesterday while
-- the phone has already rolled over - seven hours a day in which the app asks
-- for a date the data does not reach. WIB is the clock the users are on.

create or replace function public.segarkan_tanggal_demo()
returns table (
  hari_ini_wib       date,
  digeser_hari       int,
  data_berakhir      date,
  aktivitas_hari_ini bigint,
  rencana_aktif      bigint
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_hari_ini date := (now() at time zone 'Asia/Jakarta')::date;
  v_terakhir date;
  v_geser    int := 0;
  v_anak     uuid[];
  v_rencana  uuid[];
begin
  -- Only demo rows move. An account a judge created keeps its own dates.
  select array_agg(pa.id) into v_anak
    from profil_anak pa
    join pengguna p on p.id = pa.pengguna_id
   where p.adalah_demo;

  if v_anak is null then
    return query select v_hari_ini, 0, null::date, 0::bigint, 0::bigint;
    return;
  end if;

  select array_agg(id) into v_rencana
    from rencana where profil_anak_id = any(v_anak);

  select max(tanggal) into v_terakhir
    from jadwal_aktivitas where rencana_id = any(v_rencana);

  v_geser := coalesce(v_hari_ini - v_terakhir, 0);

  if v_geser <> 0 then
    update rencana set
      periode_mulai   = periode_mulai   + v_geser,
      periode_selesai = periode_selesai + v_geser
     where id = any(v_rencana);

    update jadwal_aktivitas set tanggal = tanggal + v_geser
     where rencana_id = any(v_rencana);

    update catatan_respons set
      dicatat_pada = dicatat_pada + make_interval(days => v_geser)
     where jadwal_aktivitas_id in (
       select id from jadwal_aktivitas where rencana_id = any(v_rencana)
     );

    update catatan_pengasuh set tanggal = tanggal + v_geser
     where pengguna_id in (select id from pengguna where adalah_demo);

    update laporan set
      periode_mulai   = periode_mulai   + v_geser,
      periode_selesai = periode_selesai + v_geser,
      dibuat_pada     = dibuat_pada     + make_interval(days => v_geser)
     where profil_anak_id = any(v_anak);

    update adaptasi_log set
      dibuat_pada = dibuat_pada + make_interval(days => v_geser)
     where rencana_id = any(v_rencana);

    update notifikasi set
      dibuat_pada = dibuat_pada + make_interval(days => v_geser)
     where pengguna_id in (select id from pengguna where adalah_demo);
  end if;

  -- Exactly one active plan. generate-plan used to scope its supersede by
  -- periode_mulai, which left a second active plan behind whenever the new
  -- week started on a different weekday - and ambilJadwal filters on
  -- rencana.status alone, so the plan screen then showed overlapping days
  -- twice. Collapsing to the newest is cheap insurance either way.
  update rencana set status = 'digantikan'
   where status = 'aktif'
     and profil_anak_id = any(v_anak)
     and id <> (
       select id from rencana
        where profil_anak_id = any(v_anak) and status = 'aktif'
        order by periode_mulai desc, id
        limit 1
     );

  return query
    select
      v_hari_ini,
      v_geser,
      max(ja.tanggal),
      count(*) filter (where ja.tanggal = v_hari_ini),
      (select count(*) from rencana
        where profil_anak_id = any(v_anak) and status = 'aktif')
    from jadwal_aktivitas ja
   where ja.rencana_id = any(v_rencana);
end $$;

-- Service role only. This rewrites demo history; no signed-in user needs it,
-- and the keep-alive function already holds that key.
revoke all on function public.segarkan_tanggal_demo() from public, anon, authenticated;
grant execute on function public.segarkan_tanggal_demo() to service_role;
