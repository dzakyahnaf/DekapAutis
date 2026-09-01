-- Anchors the shift on the seeded plans alone.
--
-- The first version took max(tanggal) across every plan belonging to the demo
-- child. That is wrong the moment anyone presses "Susun rencana": generate-plan
-- writes a plan for the current Monday-to-Sunday week, which reaches past
-- today, so the anchor jumps forward and the next run drags the whole seeded
-- history *backwards* to compensate. It happened on the first real run - a
-- generated plan ending 6 September pulled four weeks of history back four
-- days.
--
-- The seed writes deterministic ids (d0000001-2000-4000-8000-00000000000N), so
-- those four plans are the stable reference. Anything else on the demo child
-- was made by a judge, and is archived rather than deleted: it stops competing
-- for "aktif" without throwing away what they did.

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
  v_seed     uuid[];
  v_aktif    uuid;
begin
  select array_agg(pa.id) into v_anak
    from profil_anak pa
    join pengguna p on p.id = pa.pengguna_id
   where p.adalah_demo;

  if v_anak is null then
    return query select v_hari_ini, 0, null::date, 0::bigint, 0::bigint;
    return;
  end if;

  -- The four plans the seed writes, and nothing else.
  select array_agg(id order by periode_mulai) into v_seed
    from rencana
   where profil_anak_id = any(v_anak)
     and id::text like 'd0000001-2000-4000-8000-%';

  if v_seed is null then
    return query select v_hari_ini, 0, null::date, 0::bigint, 0::bigint;
    return;
  end if;

  select max(tanggal) into v_terakhir
    from jadwal_aktivitas where rencana_id = any(v_seed);

  v_geser := coalesce(v_hari_ini - v_terakhir, 0);

  if v_geser <> 0 then
    update rencana set
      periode_mulai   = periode_mulai   + v_geser,
      periode_selesai = periode_selesai + v_geser
     where id = any(v_seed);

    update jadwal_aktivitas set tanggal = tanggal + v_geser
     where rencana_id = any(v_seed);

    update catatan_respons set
      dicatat_pada = dicatat_pada + make_interval(days => v_geser)
     where jadwal_aktivitas_id in (
       select id from jadwal_aktivitas where rencana_id = any(v_seed)
     );

    -- Out through an offset and back: catatan_pengasuh carries
    -- UNIQUE (pengguna_id, tanggal), and Postgres checks that per row during
    -- UPDATE, so a one-day shift lands on the date the next row still holds.
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
     where rencana_id = any(v_seed);

    update notifikasi set
      dibuat_pada = dibuat_pada + make_interval(days => v_geser)
     where pengguna_id in (select id from pengguna where adalah_demo);
  end if;

  -- The seeded fourth week is the plan the demo is meant to present. Anything
  -- a judge generated is archived so it cannot take "aktif" from it.
  v_aktif := v_seed[array_length(v_seed, 1)];

  update rencana set status = 'digantikan'
   where profil_anak_id = any(v_anak)
     and status = 'aktif'
     and id <> v_aktif;

  update rencana set status = 'aktif'
   where id = v_aktif and status <> 'aktif';

  return query
    select
      v_hari_ini,
      v_geser,
      max(ja.tanggal),
      count(*) filter (where ja.tanggal = v_hari_ini),
      (select count(*) from rencana
        where profil_anak_id = any(v_anak) and status = 'aktif')
    from jadwal_aktivitas ja
   where ja.rencana_id = any(v_seed);
end $$;

revoke all on function public.segarkan_tanggal_demo() from public, anon, authenticated;
grant execute on function public.segarkan_tanggal_demo() to service_role;
