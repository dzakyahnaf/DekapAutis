-- Returns the demo child to the plan set the seed designed.
--
-- Archiving a judge-generated plan is not enough. The report query joins
-- jadwal_aktivitas to rencana on profil_anak_id alone - it never filters on
-- status, because a finished week must still count towards the four-week
-- figures. So an extra plan's rows keep landing in the metrics however the
-- plan is marked.
--
-- Measured on the live database: one generated week added 11 scheduled rows
-- with no responses and pulled the recorded ratio from 86% to 79%. The first
-- judge to press "Susun rencana" would degrade the report for every judge
-- after them, and the trend shapes docs/07 §3 specifies would stop holding.
--
-- Only the demo child is touched, and only plans the seed did not write. The
-- account is labelled synthetic in the interface, and presenting its designed
-- state is the whole point of it. Real accounts keep everything.

-- Dropped rather than replaced: the return gains a rencana_dihapus column, and
-- CREATE OR REPLACE cannot change a function's output row type.
drop function if exists public.segarkan_tanggal_demo();

create function public.segarkan_tanggal_demo()
returns table (
  hari_ini_wib       date,
  digeser_hari       int,
  data_berakhir      date,
  aktivitas_hari_ini bigint,
  rencana_aktif      bigint,
  rencana_dihapus    int
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_hari_ini date := (now() at time zone 'Asia/Jakarta')::date;
  v_terakhir date;
  v_geser    int := 0;
  v_hapus    int := 0;
  v_anak     uuid[];
  v_seed     uuid[];
  v_aktif    uuid;
begin
  select array_agg(pa.id) into v_anak
    from profil_anak pa
    join pengguna p on p.id = pa.pengguna_id
   where p.adalah_demo;

  if v_anak is null then
    return query select v_hari_ini, 0, null::date, 0::bigint, 0::bigint, 0;
    return;
  end if;

  select array_agg(id order by periode_mulai) into v_seed
    from rencana
   where profil_anak_id = any(v_anak)
     and id::text like 'd0000001-2000-4000-8000-%';

  if v_seed is null then
    return query select v_hari_ini, 0, null::date, 0::bigint, 0::bigint, 0;
    return;
  end if;

  -- Cascades to jadwal_aktivitas and catatan_respons.
  with dibuang as (
    delete from rencana
     where profil_anak_id = any(v_anak)
       and not (id = any(v_seed))
    returning 1
  )
  select count(*)::int into v_hapus from dibuang;

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
    -- UNIQUE (pengguna_id, tanggal), checked per row during UPDATE.
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

  v_aktif := v_seed[array_length(v_seed, 1)];
  update rencana set status = 'digantikan'
   where profil_anak_id = any(v_anak) and status = 'aktif' and id <> v_aktif;
  update rencana set status = 'aktif'
   where id = v_aktif and status <> 'aktif';

  return query
    select
      v_hari_ini,
      v_geser,
      max(ja.tanggal),
      count(*) filter (where ja.tanggal = v_hari_ini),
      (select count(*) from rencana
        where profil_anak_id = any(v_anak) and status = 'aktif'),
      v_hapus
    from jadwal_aktivitas ja
   where ja.rencana_id = any(v_seed);
end $$;

revoke all on function public.segarkan_tanggal_demo() from public, anon, authenticated;
grant execute on function public.segarkan_tanggal_demo() to service_role;
