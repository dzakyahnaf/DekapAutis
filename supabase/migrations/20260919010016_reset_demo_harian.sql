-- Returns the demo account to exactly the state the seed designed, every day.
--
-- WHY A FULL RESET, NOT A SHIFT
-- -----------------------------
-- The previous version only moved dates forward and removed extra plans. That
-- kept the window current but let every other trace of use accumulate. Measured
-- on production on 19 September, after the judging period:
--
--   * one of today's five activities already recorded - the seed leaves the
--     last day open on purpose, and someone recorded it
--   * a sixth adaptation row, G_manual, from a "Saya koreksi sendiri" tap; the
--     explanation card changed and rule C will now never touch that category
--   * two schedule requests the seed never made
--
-- The team rehearses for the final on this same account. Each rehearsal would
-- leave more of the same, and the final demo would open on a home screen that
-- is already half done. So every run now deletes all activity under the demo
-- child and plants it again from the seed's own logic.
--
-- WHAT IS KEPT
-- ------------
-- Accounts are left alone. Deleting auth users would revoke every session, and
-- a phone signed in during rehearsal would wake up to a dead token mid-demo.
-- Community posts are left alone too: judges may have replied to them, and
-- those replies are not ours to delete.
--
-- STABLE IDS
-- ----------
-- The seed mints schedule ids with gen_random_uuid(). Re-seeding with fresh ids
-- every night would break the phone's cache: it upserts rows by id and never
-- deletes, so yesterday's ids would linger beside today's and the plan screen
-- would show each day twice. Ids here are derived from (week, category, day),
-- so the same row keeps the same id and only its date moves.
--
-- NAME AND SIGNATURE
-- ------------------
-- Kept as segarkan_tanggal_demo() with the same output row, so the keep-alive
-- function already deployed picks this up without a redeploy.
--
-- TIMEZONE
-- --------
-- `set timezone` on the function makes current_date the date in WIB for the
-- duration of the call. The database runs in UTC, and the phone does not.

create or replace function public.segarkan_tanggal_demo()
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
set timezone = 'Asia/Jakarta'
as $$
declare
  v_pengasuh  uuid := 'd0000001-0000-4000-8000-000000000001';
  v_anak      uuid := 'd0000001-1111-4000-8000-000000000001';
  v_hari_ini  date := current_date;
  v_terakhir  date;
  v_geser     int := 0;
  v_hapus     int := 0;

  v_rencana   uuid;
  v_kategori  text;
  v_minggu    int;
  v_hari      int;
  v_urut      int;
  v_aktivitas uuid;
  v_jadwal    uuid;
  v_tanggal   date;
  v_jam       time;
  v_mudah     int;
  v_terpakai  int;
  v_nilai     text;
  -- Identical to supabase/seed/demo.sql. Rows are weeks 1..4; Sosial (column
  -- 5) falls strictly across the last three periods so D_tandai fires.
  v_pola      int[][] := array[
    [3, 4, 3, 4, 3],
    [4, 4, 3, 4, 4],
    [4, 4, 3, 5, 3],
    [5, 4, 2, 5, 2]
  ];
  v_kategori_urut text[] := array['komunikasi', 'motorik', 'sensorik',
                                  'kemandirian', 'sosial'];
begin
  if not exists (select 1 from profil_anak where id = v_anak) then
    return query select v_hari_ini, 0, null::date, 0::bigint, 0::bigint, 0;
    return;
  end if;

  -- Reported, not needed: how far the window had drifted, and how many plans
  -- someone generated since the last run.
  select max(j.tanggal) into v_terakhir
    from jadwal_aktivitas j
    join rencana r on r.id = j.rencana_id
   where r.profil_anak_id = v_anak
     and r.id::text like 'd0000001-2000-4000-8000-%';
  v_geser := coalesce(v_hari_ini - v_terakhir, 0);

  select count(*)::int into v_hapus
    from rencana
   where profil_anak_id = v_anak
     and id::text not like 'd0000001-2000-4000-8000-%';

  -- ------------------------------------------------------------- clear --

  -- The child's profile, in case a rehearsal edited it.
  update profil_anak set
    nama_panggilan        = 'Bima',
    usia                  = 6,
    kemampuan_komunikasi  = 'beberapa_kata',
    sensitivitas_sensorik = array['suara_keras', 'cahaya_terang'],
    fokus_perkembangan    = array['komunikasi', 'kemandirian']
  where id = v_anak;

  -- Cascades to jadwal_aktivitas, catatan_respons and adaptasi_log.
  delete from rencana where profil_anak_id = v_anak;
  -- Cascades to izin_berbagi and tanggapan_profesional.
  delete from laporan where profil_anak_id = v_anak;

  delete from catatan_pengasuh where pengguna_id = v_pengasuh;
  delete from pengajuan_jadwal where pengasuh_id = v_pengasuh;
  -- Every demo account, not only the caregiver: a schedule request made during
  -- rehearsal notifies the demo professional as well.
  delete from notifikasi
   where pengguna_id in (select id from pengguna where adalah_demo);

  -- ------------------------------------------------------------- plant --

  for v_minggu in 1..4 loop
    v_rencana := ('d0000001-2000-4000-8000-' || lpad(v_minggu::text, 12, '0'))::uuid;

    insert into rencana (id, profil_anak_id, periode_mulai, periode_selesai, status)
    values (
      v_rencana, v_anak,
      v_hari_ini - ((4 - v_minggu) * 7 + 6),
      v_hari_ini - ((4 - v_minggu) * 7),
      case when v_minggu = 4 then 'aktif' else 'selesai' end
    );

    for v_kategori in select unnest(v_kategori_urut) loop
      v_mudah    := v_pola[v_minggu][array_position(v_kategori_urut, v_kategori)];
      v_terpakai := 0;
      v_urut     := array_position(v_kategori_urut, v_kategori);

      -- 7 per category per week, 6 recorded: 140 scheduled, 120 recorded, 86%.
      for v_hari in 0..6 loop
        select id into v_aktivitas
          from aktivitas
         where kategori = v_kategori
         order by tingkat, judul
         offset (v_hari % 4) limit 1;

        v_tanggal := v_hari_ini - ((4 - v_minggu) * 7 + 6 - v_hari);

        -- "Mudah" responses lean into the 08.00-09.00 block so rule E_jadwal
        -- has a real basis, not merely a way to run.
        v_jam := case when v_terpakai < v_mudah then time '08:30'
                      else time '16:00' end + (v_urut * interval '7 minutes');

        -- Stable id: week, category, day. See the header.
        v_jadwal := ('d0000001-5000-4000-8000-' ||
                     lpad((v_minggu * 100 + v_urut * 10 + v_hari)::text, 12, '0'))::uuid;

        insert into jadwal_aktivitas (
          id, rencana_id, aktivitas_id, tanggal, waktu, urutan,
          durasi_menit, tingkat_disesuaikan
        ) values (
          v_jadwal, v_rencana, v_aktivitas, v_tanggal, v_jam, v_urut,
          case when v_kategori = 'komunikasi' and v_minggu >= 3 then 15 else 10 end,
          case when v_kategori = 'komunikasi' and v_minggu = 4 then 3 else 2 end
        );

        -- The seventh day is left open on purpose: that is today, and it is
        -- what the home screen invites the caregiver to record.
        continue when v_hari = 6;

        if v_terpakai < v_mudah then
          v_nilai := 'mudah';
        elsif v_terpakai < v_mudah + 1 then
          v_nilai := 'sulit';
        else
          v_nilai := 'pas';
        end if;
        v_terpakai := v_terpakai + 1;

        insert into catatan_respons (jadwal_aktivitas_id, nilai, dicatat_pada, klien_id)
        values (
          v_jadwal, v_nilai,
          (v_tanggal + v_jam)::timestamptz + interval '20 minutes',
          'demo-' || v_jadwal::text
        );
      end loop;
    end loop;
  end loop;

  -- Caregiver check-ins: 28 days, mostly 3-4, with a run of 2s in week three.
  for v_hari in 0..27 loop
    insert into catatan_pengasuh (pengguna_id, tanggal, kondisi)
    values (
      v_pengasuh, v_hari_ini - v_hari,
      case
        when v_hari between 8 and 11 then 2
        when v_hari % 3 = 0 then 4
        else 3
      end
    );
  end loop;

  -- Five rows across four rules. Every figure comes from the pattern above.
  insert into adaptasi_log (
    rencana_id, aturan_id, kategori, nilai_sebelum, nilai_sesudah, alasan,
    dikoreksi_manual, dibuat_pada
  ) values
    ('d0000001-2000-4000-8000-000000000004', 'A_naik', 'komunikasi',
     '{"tingkat": 2}', '{"tingkat": 3}',
     'Capaian komunikasi 83% minggu ini dari 6 catatan. Tingkat aktivitas '
     'komunikasi naik dari 2 ke 3.',
     false, now() - interval '1 day'),
    ('d0000001-2000-4000-8000-000000000004', 'C_porsi', 'komunikasi',
     '{"porsi": 6}', '{"porsi": 7}',
     'Komunikasi mencapai 83% sementara sosial 33% pada periode yang sama. '
     'Porsi sesi komunikasi minggu ini naik dari 6 menjadi 7.',
     false, now() - interval '1 day'),
    ('d0000001-2000-4000-8000-000000000004', 'B_turun', 'sosial',
     '{"tingkat": 2, "durasi_menit": 10}', '{"tingkat": 1, "durasi_menit": 8}',
     'Capaian sosial 33% minggu ini dari 6 catatan. Tingkat diturunkan dari 2 ke '
     '1 dan durasi sesi dari 10 menjadi 8 menit.',
     false, now() - interval '1 day'),
    ('d0000001-2000-4000-8000-000000000004', 'D_tandai', 'sosial',
     '{"capaian": [67, 50]}', '{"capaian": 33}',
     'Capaian Sosial menurun dua periode berturut-turut: 67% pada periode '
     'pertama, 50% pada periode kedua, lalu 33% pada periode ini. Ditandai untuk '
     'dibahas bersama tenaga profesional.',
     false, now() - interval '1 day'),
    ('d0000001-2000-4000-8000-000000000004', 'E_jadwal', 'komunikasi',
     '{"jam": 16}', '{"jam": 8}',
     'Dari 5 respons mudah komunikasi minggu ini, seluruhnya tercatat pada blok '
     'pukul 08.00-09.00. Sesi komunikasi dipindahkan ke blok tersebut.',
     false, now() - interval '1 day');

  -- One report already shared, so the professional side can be shown; one not
  -- yet shared, so sharing can be shown.
  insert into laporan (
    id, profil_anak_id, periode_mulai, periode_selesai, metrik, per_kategori,
    ringkasan, penanda_perhatian, dibuat_pada
  ) values
    ('d0000001-3000-4000-8000-000000000001', v_anak,
     v_hari_ini - 27, v_hari_ini,
     '{"aktivitas_terjadwal": 140, "aktivitas_tercatat": 120, "persen_tercatat": 86}',
     '[{"kategori":"komunikasi","persen":83,"tren":"naik"},
       {"kategori":"motorik","persen":67,"tren":"datar"},
       {"kategori":"sensorik","persen":33,"tren":"turun"},
       {"kategori":"kemandirian","persen":83,"tren":"naik"},
       {"kategori":"sosial","persen":33,"tren":"turun"}]',
     'Dari 140 aktivitas terjadwal, 120 tercatat (86%). Komunikasi naik dari 50% '
     'menjadi 83% selama empat minggu. Sosial menurun tiga periode berturut-turut '
     'dari 67% menjadi 33% dan ditandai untuk dibahas bersama tenaga profesional. '
     'Dokumen ini disusun dari catatan pengasuh dan bukan hasil pemeriksaan '
     'klinis.',
     array['sosial'],
     now() - interval '1 day'),
    ('d0000001-3000-4000-8000-000000000002', v_anak,
     v_hari_ini - 13, v_hari_ini,
     '{"aktivitas_terjadwal": 70, "aktivitas_tercatat": 60, "persen_tercatat": 86}',
     '[{"kategori":"komunikasi","persen":75,"tren":"naik"},
       {"kategori":"sosial","persen":42,"tren":"turun"}]',
     'Laporan dua minggu terakhir, belum dibagikan kepada siapa pun. Dokumen ini '
     'disusun dari catatan pengasuh dan bukan hasil pemeriksaan klinis.',
     array['sosial'],
     now() - interval '2 hours');

  insert into izin_berbagi (laporan_id, profesional_id, diberikan_pada)
  values ('d0000001-3000-4000-8000-000000000001',
          'd0000000-0002-4000-8000-000000000002',
          now() - interval '20 hours');

  -- All five kinds, two unread.
  insert into notifikasi (pengguna_id, jenis, judul, tautan, dibaca, dibuat_pada)
  values
    (v_pengasuh, 'penyesuaian', 'Rencana minggu ini disesuaikan',
     '/rencana', false, now() - interval '3 hours'),
    (v_pengasuh, 'belum_dicatat', 'Satu aktivitas belum tercatat',
     '/rencana', false, now() - interval '5 hours'),
    (v_pengasuh, 'balasan', 'Ada balasan pada tulisan Anda',
     '/komunitas', true, now() - interval '1 day'),
    (v_pengasuh, 'artikel', 'Artikel baru selesai ditinjau',
     '/pustaka', true, now() - interval '2 days'),
    (v_pengasuh, 'jadwal', 'Pengajuan jadwal disetujui',
     '/direktori', true, now() - interval '4 days');

  return query
    select
      v_hari_ini,
      v_geser,
      max(j.tanggal),
      count(*) filter (where j.tanggal = v_hari_ini),
      (select count(*) from rencana
        where profil_anak_id = v_anak and status = 'aktif'),
      v_hapus
    from jadwal_aktivitas j
    join rencana r on r.id = j.rencana_id
   where r.profil_anak_id = v_anak;
end $$;

revoke all on function public.segarkan_tanggal_demo() from public, anon, authenticated;
grant execute on function public.segarkan_tanggal_demo() to service_role;
