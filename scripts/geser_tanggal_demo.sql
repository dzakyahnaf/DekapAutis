-- Rolls the demo account's four-week window forward so it always ends today.
--
-- WHY THIS EXISTS
-- ---------------
-- `supabase/seed/demo.sql` anchors every date to `current_date` *at the moment
-- the seed runs*. That is correct at seed time and wrong every day after: the
-- window stays frozen while the calendar moves, so the home screen empties out
-- one day at a time. Judging runs to 11 September, so by the last day a judge
-- would open the app to an empty "Rencana hari ini".
--
-- Re-running the seed would fix the dates but also discard anything a judge
-- recorded. Shifting instead preserves every row, every id, and every
-- invariant `scripts/test_seed_demo.sql` checks - the trend shapes, the 86%
-- recorded ratio, and Sosial declining across the last three periods.
--
-- TIMEZONE
-- --------
-- The target is today in Asia/Jakarta, not `current_date`. The database runs
-- in UTC, so between 00:00 and 07:00 WIB `current_date` is still yesterday
-- while the phone has already rolled over - a seven-hour window every day in
-- which the app asks for a date the data does not reach. Anchoring on WIB
-- removes it, because that is the clock the users are actually on.
--
-- Idempotent: shifting by zero is a no-op, so running it twice in one day
-- changes nothing. Safe to run daily from cron.

do $$
declare
  v_hari_ini date := (now() at time zone 'Asia/Jakarta')::date;
  v_terakhir date;
  v_geser    int;
begin
  select max(ja.tanggal) into v_terakhir
    from jadwal_aktivitas ja
    join rencana r on r.id = ja.rencana_id
    join profil_anak pa on pa.id = r.profil_anak_id
    join pengguna p on p.id = pa.pengguna_id
   where p.adalah_demo;

  if v_terakhir is null then
    raise notice 'Tidak ada data demo untuk digeser.';
    return;
  end if;

  v_geser := v_hari_ini - v_terakhir;
  if v_geser = 0 then
    raise notice 'Data demo sudah berakhir hari ini (%). Tidak ada yang digeser.', v_hari_ini;
    return;
  end if;

  raise notice 'Menggeser data demo % hari, dari % ke %.', v_geser, v_terakhir, v_hari_ini;

  -- Only the demo caregiver's rows move. A real account that a judge created
  -- keeps its own dates.
  with anak_demo as (
    select pa.id
      from profil_anak pa
      join pengguna p on p.id = pa.pengguna_id
     where p.adalah_demo
  )
  update rencana set
    periode_mulai   = periode_mulai   + v_geser,
    periode_selesai = periode_selesai + v_geser
  where profil_anak_id in (select id from anak_demo);

  update jadwal_aktivitas ja set tanggal = ja.tanggal + v_geser
   where ja.rencana_id in (
     select r.id from rencana r
      join profil_anak pa on pa.id = r.profil_anak_id
      join pengguna p on p.id = pa.pengguna_id
     where p.adalah_demo
   );

  update catatan_respons cr
     set dicatat_pada = cr.dicatat_pada + make_interval(days => v_geser)
   where cr.jadwal_aktivitas_id in (
     select ja.id from jadwal_aktivitas ja
      join rencana r on r.id = ja.rencana_id
      join profil_anak pa on pa.id = r.profil_anak_id
      join pengguna p on p.id = pa.pengguna_id
     where p.adalah_demo
   );

  update catatan_pengasuh cp set tanggal = cp.tanggal + v_geser
   where cp.pengguna_id in (select id from pengguna where adalah_demo);

  update laporan l set
    periode_mulai   = l.periode_mulai   + v_geser,
    periode_selesai = l.periode_selesai + v_geser,
    dibuat_pada     = l.dibuat_pada     + make_interval(days => v_geser)
   where l.profil_anak_id in (
     select pa.id from profil_anak pa
      join pengguna p on p.id = pa.pengguna_id
     where p.adalah_demo
   );

  update adaptasi_log al
     set dibuat_pada = al.dibuat_pada + make_interval(days => v_geser)
   where al.rencana_id in (
     select r.id from rencana r
      join profil_anak pa on pa.id = r.profil_anak_id
      join pengguna p on p.id = pa.pengguna_id
     where p.adalah_demo
   );

  update notifikasi n
     set dibuat_pada = n.dibuat_pada + make_interval(days => v_geser)
   where n.pengguna_id in (select id from pengguna where adalah_demo);

  -- Exactly one active plan. generate-plan used to leave a second one behind,
  -- and two active plans make the sync pull the overlapping days twice.
  update rencana set status = 'digantikan'
   where status = 'aktif'
     and profil_anak_id in (
       select pa.id from profil_anak pa
        join pengguna p on p.id = pa.pengguna_id
       where p.adalah_demo
     )
     and id <> (
       select r.id from rencana r
        join profil_anak pa on pa.id = r.profil_anak_id
        join pengguna p on p.id = pa.pengguna_id
       where p.adalah_demo and r.status = 'aktif'
       order by r.periode_mulai desc
       limit 1
     );
end $$;

-- Proof, printed so a run can be checked at a glance.
select
  (now() at time zone 'Asia/Jakarta')::date               as hari_ini_wib,
  max(ja.tanggal)                                         as data_berakhir,
  count(*) filter (where ja.tanggal = (now() at time zone 'Asia/Jakarta')::date)
                                                          as aktivitas_hari_ini,
  (select count(*) from rencana r
     join profil_anak pa on pa.id = r.profil_anak_id
     join pengguna p on p.id = pa.pengguna_id
    where p.adalah_demo and r.status = 'aktif')           as rencana_aktif
from jadwal_aktivitas ja
join rencana r on r.id = ja.rencana_id
join profil_anak pa on pa.id = r.profil_anak_id
join pengguna p on p.id = pa.pengguna_id
where p.adalah_demo;
