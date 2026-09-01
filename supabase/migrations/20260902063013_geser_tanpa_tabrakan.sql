-- Fixes segarkan_tanggal_demo(), which aborted on its first real run.
--
-- catatan_pengasuh has UNIQUE (pengguna_id, tanggal). Shifting the window one
-- day forward moved a row onto a date the next row still held, and Postgres
-- checks unique constraints per row during UPDATE rather than at statement
-- end, so the whole function rolled back with:
--
--   duplicate key value violates unique constraint
--   "catatan_pengasuh_pengguna_id_tanggal_key"
--
-- It is the only shifted table with a unique constraint over a date column,
-- confirmed against the live schema. The shift now goes out through an offset
-- far beyond the data and back, which cannot collide in either direction.

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

    -- Two steps, via an offset far outside the data, because
    -- catatan_pengasuh carries UNIQUE (pengguna_id, tanggal) and it is the
    -- only shifted table that does. Postgres checks a unique constraint per
    -- row during UPDATE, not at statement end, so shifting a day forward
    -- collides with the row that already occupies the target date. Moving
    -- everything out of range first and back afterwards cannot collide,
    -- whichever direction the shift runs in.
    update catatan_pengasuh set tanggal = tanggal + 100000
     where pengguna_id in (select id from pengguna where adalah_demo);
    update catatan_pengasuh set tanggal = tanggal - 100000 + v_geser
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

