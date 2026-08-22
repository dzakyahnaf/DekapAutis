-- Data demo (docs/07). Dijalankan otomatis oleh `supabase db reset`.
--
-- ATURAN PERTAMA BERKAS INI: tidak ada satu pun tanggal absolut.
--
-- Seluruh riwayat dihitung mundur dari `current_date`, jadi empat minggu
-- terakhir selalu berakhir hari ini. Juri membuka aplikasi ini sampai 11
-- September; laporan yang berakhir pada tanggal mati membuat produk terlihat
-- ditinggalkan, dan itu kerugian yang tidak perlu.
--
-- Idempoten: seluruh baris demo memakai UUID tetap dan dihapus lebih dulu,
-- jadi menjalankannya dua kali tidak menggandakan apa pun.
--
-- CATATAN TENTANG PERSENTASE TREN
-- --------------------------------
-- docs/07 §3 meminta dua hal yang tidak bisa berlaku bersamaan. Volume yang
-- diminta - 140 jadwal, 86% tercatat - menghasilkan 6 catatan per kategori per
-- minggu. Dengan 6 sampel, persentase yang mungkin hanya kelipatan 16,7
-- (0, 17, 33, 50, 67, 83, 100), sehingga angka seperti 45%, 78%, atau 52% tidak
-- dapat dihasilkan sama sekali.
--
-- Yang dipertahankan di sini adalah volume (140 jadwal, 120 catatan, 86%) dan
-- BENTUK tren, karena bentuk itulah yang docs/07 jelaskan alasannya kolom demi
-- kolom. Persentase dibulatkan ke nilai terdekat yang dapat dicapai:
--
--   Kategori     minggu 1 -> 4      diminta      dihasilkan
--   Komunikasi   naik konsisten     45 -> 78     50 -> 83
--   Motorik      datar              60 -> 65     67 -> 67
--   Sensorik     sedikit turun      55 -> 52     50 -> 33
--   Kemandirian  naik landai        68 -> 71     67 -> 83
--   Sosial       turun 2 periode    52 -> 40     67 -> 50 -> 33
--
-- Sosial adalah yang paling penting dan dihitung mundur dari aturannya:
-- `D_tandai` menuntut tiga periode terakhir menurun KETAT (p1 > p2 > p3), jadi
-- 67 > 50 > 33 membuat penanda `perhatian` benar-benar muncul. Empat kategori
-- lain sengaja tidak memenuhi syarat itu, supaya penandanya berarti sesuatu.

-- ============================================================ pembersihan ==

delete from auth.users where email in (
  'demo@dekapautis.id',
  'demo.profesional@dekapautis.id',
  'demo.admin@dekapautis.id',
  'demo.antre1@dekapautis.id',
  'demo.antre2@dekapautis.id'
);
delete from profesional where id::text like 'd0000000-%';
delete from auth.users where email like 'direktori%@dekapautis.demo';
delete from dokumen_pengetahuan where id::text like 'd0000000-%';

-- ================================================================== akun ==

-- Kata sandi di-hash dengan bcrypt lewat pgcrypto, sama seperti yang dilakukan
-- GoTrue saat pendaftaran biasa, supaya tombol "Masuk sebagai demo" benar-benar
-- melewati alur autentikasi yang sama dengan pengguna lain.
insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at
)
select
  '00000000-0000-0000-0000-000000000000',
  d.id::uuid,
  'authenticated',
  'authenticated',
  d.email,
  crypt('DemoDekap2026', gen_salt('bf')),
  now(),
  '{"provider":"email","providers":["email"]}'::jsonb,
  jsonb_build_object('peran', d.peran, 'nama', d.nama),
  now(),
  now()
from (values
  ('d0000001-0000-4000-8000-000000000001', 'demo@dekapautis.id',
   'pengasuh', 'Rina Kartika'),
  ('d0000002-0000-4000-8000-000000000002', 'demo.profesional@dekapautis.id',
   'profesional', 'Dra. Sari Wulandari'),
  ('d0000003-0000-4000-8000-000000000003', 'demo.admin@dekapautis.id',
   'admin', 'Admin DekapAutis'),
  ('d0000004-0000-4000-8000-000000000004', 'demo.antre1@dekapautis.id',
   'profesional', 'Budi Hartono'),
  ('d0000005-0000-4000-8000-000000000005', 'demo.antre2@dekapautis.id',
   'profesional', 'Maya Puspita')
) as d(id, email, peran, nama);

-- Ditandai demo supaya aplikasi menampilkan keping "Akun demo" di header
-- profil. Data sintetis harus terlihat sebagai data sintetis.
update pengguna set adalah_demo = true
 where id::text like 'd000000%';

-- =============================================================== profil anak ==

insert into profil_anak (
  id, pengguna_id, nama_panggilan, usia, kemampuan_komunikasi,
  sensitivitas_sensorik, fokus_perkembangan
) values (
  'd0000001-1111-4000-8000-000000000001',
  'd0000001-0000-4000-8000-000000000001',
  'Bima', 6, 'beberapa_kata',
  array['suara_keras', 'cahaya_terang'],
  array['komunikasi', 'kemandirian']
) on conflict (id) do nothing;

-- ============================================================== profesional ==

insert into profesional (
  id, pengguna_id, nama_lengkap, gelar, spesialisasi, tentang, layanan,
  jadwal_praktik, lokasi_lat, lokasi_lng, kota, status_verifikasi,
  bukti_kredensial
) values
  ('d0000000-0002-4000-8000-000000000002',
   'd0000002-0000-4000-8000-000000000002',
   'Sari Wulandari', 'Dra., M.Psi.', 'Psikolog anak',
   'Mendampingi keluarga menyusun rutinitas harian yang dapat diprediksi.',
   array['Konsultasi orang tua', 'Asesmen perkembangan'],
   '[{"hari":"Selasa","jam":"15.00-17.00"},{"hari":"Kamis","jam":"09.00-11.00"}]',
   -7.2819, 112.7951, 'Surabaya', 'disetujui', 'STR-DEMO-0002'),

  -- Dua pengajuan menunggu, supaya antrean verifikasi admin tidak kosong.
  ('d0000000-0004-4000-8000-000000000004',
   'd0000004-0000-4000-8000-000000000004',
   'Budi Hartono', 'S.Psi.', 'Terapis okupasi',
   'Fokus pada keterampilan motorik halus.',
   array['Terapi okupasi'],
   '[{"hari":"Rabu","jam":"09.00-11.00"}]',
   -7.2456, 112.7378, 'Surabaya', 'menunggu', 'STR-DEMO-0004'),
  ('d0000000-0005-4000-8000-000000000005',
   'd0000005-0000-4000-8000-000000000005',
   'Maya Puspita', 'S.Tr.Kes.', 'Terapis wicara',
   'Pendampingan komunikasi ekspresif usia dini.',
   array['Terapi wicara'],
   '[{"hari":"Senin","jam":"13.00-15.00"}]',
   -7.3298, 112.7314, 'Sidoarjo', 'menunggu', 'STR-DEMO-0005');

-- Direktori demo: 15 lembaga di Surabaya dan sekitarnya dengan koordinat nyata
-- supaya perhitungan Haversine di L.9 menghasilkan jarak yang masuk akal.
--
-- Nama praktik di sini adalah CONTOH, bukan daftar praktisi sungguhan. Ini
-- dicatat juga di README.md. Mencantumkan nama praktisi nyata tanpa izin bukan
-- sesuatu yang boleh dilakukan demi sebuah demo.
--
-- Tiap entri punya akunnya sendiri. Menumpuk lima belas listing pada satu akun
-- akan membuat satu orang bisa bertindak sebagai semuanya lewat
-- `profesional_saya()`, dan kemudahan seed bukan alasan yang cukup untuk itu.
insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at
)
select
  '00000000-0000-0000-0000-000000000000',
  ('d0000000-1000-4000-8000-' || lpad(i::text, 12, '0'))::uuid,
  'authenticated', 'authenticated',
  'direktori' || lpad(i::text, 2, '0') || '@dekapautis.demo',
  -- Kata sandi acak yang tidak dicatat di mana pun: akun ini tidak untuk
  -- dimasuki, hanya untuk memiliki entri direktorinya.
  crypt(gen_random_uuid()::text, gen_salt('bf')),
  now(),
  '{"provider":"email","providers":["email"]}'::jsonb,
  jsonb_build_object('peran', 'profesional', 'nama', nama),
  now(), now()
from (values
  (1,  'Klinik Tumbuh Harmoni',      'Klinik',  'Terapis wicara',          'Terapi wicara',      '[{"hari":"Senin","jam":"09.00-11.00"}]',  -7.2575, 112.7521, 'Surabaya'),
  (2,  'Pusat Terapi Anak Melati',   'Pusat',   'Terapis okupasi',         'Terapi okupasi',     '[{"hari":"Selasa","jam":"13.00-15.00"}]', -7.2650, 112.7420, 'Surabaya'),
  (3,  'Ruang Tenang Kenjeran',      'Pusat',   'Terapis sensorik',        'Integrasi sensorik', '[{"hari":"Rabu","jam":"09.00-11.00"}]',   -7.2360, 112.7930, 'Surabaya'),
  (4,  'Praktik Psikologi Anggrek',  'Praktik', 'Psikolog anak',           'Konsultasi orang tua','[{"hari":"Kamis","jam":"15.00-17.00"}]', -7.2890, 112.7350, 'Surabaya'),
  (5,  'Klinik Tumbuh Kembang Cakra','Klinik',  'Dokter tumbuh kembang',   'Pemeriksaan berkala','[{"hari":"Jumat","jam":"09.00-11.00"}]',  -7.2700, 112.7680, 'Surabaya'),
  (6,  'Sanggar Bicara Ceria',       'Sanggar', 'Terapis wicara',          'Terapi wicara',      '[{"hari":"Senin","jam":"13.00-15.00"}]',  -7.3050, 112.7250, 'Surabaya'),
  (7,  'Klinik Anak Nusantara',      'Klinik',  'Dokter tumbuh kembang',   'Pemeriksaan berkala','[{"hari":"Selasa","jam":"09.00-11.00"}]', -7.2480, 112.7280, 'Surabaya'),
  (8,  'Rumah Belajar Pelangi',      'Pusat',   'Terapis okupasi',         'Terapi okupasi',     '[{"hari":"Rabu","jam":"13.00-15.00"}]',   -7.3180, 112.7400, 'Sidoarjo'),
  (9,  'Praktik Psikologi Cempaka',  'Praktik', 'Psikolog anak',           'Asesmen perkembangan','[{"hari":"Kamis","jam":"09.00-11.00"}]', -7.4478, 112.7183, 'Sidoarjo'),
  (10, 'Klinik Bina Mandiri',        'Klinik',  'Terapis okupasi',         'Terapi okupasi',     '[{"hari":"Jumat","jam":"13.00-15.00"}]',  -7.1554, 112.6531, 'Gresik'),
  (11, 'Sanggar Wicara Gresik',      'Sanggar', 'Terapis wicara',          'Terapi wicara',      '[{"hari":"Senin","jam":"09.00-11.00"}]',  -7.1620, 112.6600, 'Gresik'),
  (12, 'Pusat Sensorik Darmo',       'Pusat',   'Terapis sensorik',        'Integrasi sensorik', '[{"hari":"Selasa","jam":"15.00-17.00"}]', -7.2900, 112.7400, 'Surabaya'),
  (13, 'Klinik Anak Rungkut',        'Klinik',  'Dokter tumbuh kembang',   'Pemeriksaan berkala','[{"hari":"Rabu","jam":"09.00-11.00"}]',   -7.3300, 112.7650, 'Surabaya'),
  (14, 'Praktik Psikologi Wiyung',   'Praktik', 'Psikolog anak',           'Konsultasi orang tua','[{"hari":"Kamis","jam":"13.00-15.00"}]', -7.3100, 112.6800, 'Surabaya'),
  (15, 'Rumah Terapi Malang Raya',   'Pusat',   'Terapis okupasi',         'Terapi okupasi',     '[{"hari":"Jumat","jam":"09.00-11.00"}]',  -7.9666, 112.6326, 'Malang')
) as t(i, nama, gelar, spesialisasi, layanan, jadwal, lat, lng, kota);

insert into profesional (
  id, pengguna_id, nama_lengkap, gelar, spesialisasi, tentang, layanan,
  jadwal_praktik, lokasi_lat, lokasi_lng, kota, status_verifikasi,
  bukti_kredensial
)
select
  ('d0000000-1000-4000-8000-' || lpad(i::text, 12, '0'))::uuid,
  ('d0000000-1000-4000-8000-' || lpad(i::text, 12, '0'))::uuid,
  nama, gelar, spesialisasi,
  'Contoh entri direktori demo. Bukan praktik sungguhan.',
  array[layanan], jadwal::jsonb, lat, lng, kota, 'disetujui',
  'STR-CONTOH-' || lpad(i::text, 4, '0')
from (values
  (1,  'Klinik Tumbuh Harmoni',      'Klinik',  'Terapis wicara',        'Terapi wicara',       '[{"hari":"Senin","jam":"09.00-11.00"}]',  -7.2575, 112.7521, 'Surabaya'),
  (2,  'Pusat Terapi Anak Melati',   'Pusat',   'Terapis okupasi',       'Terapi okupasi',      '[{"hari":"Selasa","jam":"13.00-15.00"}]', -7.2650, 112.7420, 'Surabaya'),
  (3,  'Ruang Tenang Kenjeran',      'Pusat',   'Terapis sensorik',      'Integrasi sensorik',  '[{"hari":"Rabu","jam":"09.00-11.00"}]',   -7.2360, 112.7930, 'Surabaya'),
  (4,  'Praktik Psikologi Anggrek',  'Praktik', 'Psikolog anak',         'Konsultasi orang tua','[{"hari":"Kamis","jam":"15.00-17.00"}]',  -7.2890, 112.7350, 'Surabaya'),
  (5,  'Klinik Tumbuh Kembang Cakra','Klinik',  'Dokter tumbuh kembang', 'Pemeriksaan berkala', '[{"hari":"Jumat","jam":"09.00-11.00"}]',  -7.2700, 112.7680, 'Surabaya'),
  (6,  'Sanggar Bicara Ceria',       'Sanggar', 'Terapis wicara',        'Terapi wicara',       '[{"hari":"Senin","jam":"13.00-15.00"}]',  -7.3050, 112.7250, 'Surabaya'),
  (7,  'Klinik Anak Nusantara',      'Klinik',  'Dokter tumbuh kembang', 'Pemeriksaan berkala', '[{"hari":"Selasa","jam":"09.00-11.00"}]', -7.2480, 112.7280, 'Surabaya'),
  (8,  'Rumah Belajar Pelangi',      'Pusat',   'Terapis okupasi',       'Terapi okupasi',      '[{"hari":"Rabu","jam":"13.00-15.00"}]',   -7.3180, 112.7400, 'Sidoarjo'),
  (9,  'Praktik Psikologi Cempaka',  'Praktik', 'Psikolog anak',         'Asesmen perkembangan','[{"hari":"Kamis","jam":"09.00-11.00"}]',  -7.4478, 112.7183, 'Sidoarjo'),
  (10, 'Klinik Bina Mandiri',        'Klinik',  'Terapis okupasi',       'Terapi okupasi',      '[{"hari":"Jumat","jam":"13.00-15.00"}]',  -7.1554, 112.6531, 'Gresik'),
  (11, 'Sanggar Wicara Gresik',      'Sanggar', 'Terapis wicara',        'Terapi wicara',       '[{"hari":"Senin","jam":"09.00-11.00"}]',  -7.1620, 112.6600, 'Gresik'),
  (12, 'Pusat Sensorik Darmo',       'Pusat',   'Terapis sensorik',      'Integrasi sensorik',  '[{"hari":"Selasa","jam":"15.00-17.00"}]', -7.2900, 112.7400, 'Surabaya'),
  (13, 'Klinik Anak Rungkut',        'Klinik',  'Dokter tumbuh kembang', 'Pemeriksaan berkala', '[{"hari":"Rabu","jam":"09.00-11.00"}]',   -7.3300, 112.7650, 'Surabaya'),
  (14, 'Praktik Psikologi Wiyung',   'Praktik', 'Psikolog anak',         'Konsultasi orang tua','[{"hari":"Kamis","jam":"13.00-15.00"}]',  -7.3100, 112.6800, 'Surabaya'),
  (15, 'Rumah Terapi Malang Raya',   'Pusat',   'Terapis okupasi',       'Terapi okupasi',      '[{"hari":"Jumat","jam":"09.00-11.00"}]',  -7.9666, 112.6326, 'Malang')
) as t(i, nama, gelar, spesialisasi, layanan, jadwal, lat, lng, kota);

-- ====================================================== riwayat 4 minggu ==

do $$
declare
  v_pengasuh  uuid := 'd0000001-0000-4000-8000-000000000001';
  v_anak      uuid := 'd0000001-1111-4000-8000-000000000001';
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
  -- mudah per 6 catatan, per kategori per minggu. Baris = minggu 1..4.
  -- Sosial (kolom 5) turun ketat pada tiga periode terakhir: 4, 3, 2.
  v_pola      int[][] := array[
    [3, 4, 3, 4, 3],
    [4, 4, 3, 4, 4],
    [4, 4, 3, 5, 3],
    [5, 4, 2, 5, 2]
  ];
  v_kategori_urut text[] := array['komunikasi', 'motorik', 'sensorik',
                                  'kemandirian', 'sosial'];
begin
  -- Satu rencana per minggu, minggu ke-4 masih aktif.
  for v_minggu in 1..4 loop
    v_rencana := ('d0000001-2000-4000-8000-' || lpad(v_minggu::text, 12, '0'))::uuid;

    insert into rencana (id, profil_anak_id, periode_mulai, periode_selesai, status)
    values (
      v_rencana, v_anak,
      current_date - ((4 - v_minggu) * 7 + 6),
      current_date - ((4 - v_minggu) * 7),
      case when v_minggu = 4 then 'aktif' else 'selesai' end
    );

    for v_kategori in select unnest(v_kategori_urut) loop
      v_mudah := v_pola[v_minggu][array_position(v_kategori_urut, v_kategori)];
      v_terpakai := 0;

      -- 7 jadwal per kategori per minggu, 6 di antaranya dicatat.
      -- 7 x 5 x 4 = 140 jadwal, 120 catatan, tepat 86%.
      for v_hari in 0..6 loop
        select id into v_aktivitas
          from aktivitas
         where kategori = v_kategori
         order by tingkat, judul
         offset (v_hari % 4) limit 1;

        v_tanggal := current_date - ((4 - v_minggu) * 7 + 6 - v_hari);
        v_urut := array_position(v_kategori_urut, v_kategori);

        -- Respons "mudah" dicondongkan ke blok 08.00-09.00 supaya aturan
        -- E_jadwal punya dasar nyata, bukan sekadar bisa dijalankan.
        v_jam := case when v_terpakai < v_mudah then time '08:30'
                      else time '16:00' end + (v_urut * interval '7 minutes');

        v_jadwal := gen_random_uuid();
        insert into jadwal_aktivitas (
          id, rencana_id, aktivitas_id, tanggal, waktu, urutan,
          durasi_menit, tingkat_disesuaikan
        ) values (
          v_jadwal, v_rencana, v_aktivitas, v_tanggal, v_jam, v_urut,
          case when v_kategori = 'komunikasi' and v_minggu >= 3 then 15 else 10 end,
          case when v_kategori = 'komunikasi' and v_minggu = 4 then 3 else 2 end
        );

        -- Hari ke-7 sengaja tidak dicatat: itu yang membuat 86%, bukan 100%.
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

  -- Check-in pengasuh: 28 hari, kebanyakan 3-4, dengan beberapa hari bernilai 2
  -- pada minggu ketiga. Pola kelelahan pengasuh adalah salah satu masalah yang
  -- diangkat Bab II, dan tanpa baris ini pola itu tidak pernah terlihat.
  for v_hari in 0..27 loop
    v_tanggal := current_date - v_hari;
    insert into catatan_pengasuh (pengguna_id, tanggal, kondisi)
    values (
      v_pengasuh, v_tanggal,
      case
        when v_hari between 8 and 11 then 2
        when v_hari % 3 = 0 then 4
        else 3
      end
    )
    on conflict (pengguna_id, tanggal) do update set kondisi = excluded.kondisi;
  end loop;
end $$;

-- ============================================================ adaptasi_log ==

-- Lima baris, mencakup empat aturan yang menghasilkan perubahan terlihat.
-- Setiap angka di sini berasal dari pola yang baru saja di-seed di atas, bukan
-- karangan: 83% dan 33% adalah capaian nyata minggu ini untuk komunikasi dan
-- sosial, dan 67/50/33 adalah tiga periode sosial yang memicu D_tandai.
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

-- ================================================================ laporan ==

-- Satu laporan sudah dibagikan (alur profesional bisa didemonstrasikan), satu
-- lagi belum (alur berbagi bisa didemonstrasikan di video).
insert into laporan (
  id, profil_anak_id, periode_mulai, periode_selesai, metrik, per_kategori,
  ringkasan, penanda_perhatian, dibuat_pada
) values
  ('d0000001-3000-4000-8000-000000000001',
   'd0000001-1111-4000-8000-000000000001',
   current_date - 27, current_date,
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

  ('d0000001-3000-4000-8000-000000000002',
   'd0000001-1111-4000-8000-000000000001',
   current_date - 13, current_date,
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

-- ============================================================== komunitas ==

insert into postingan_komunitas (id, pengguna_id, topik, judul, isi, anonim, dibuat_pada)
values
  ('d0000001-4000-4000-8000-000000000001', 'd0000001-0000-4000-8000-000000000001',
   'rutinitas', 'Rutinitas pagi yang bisa diprediksi',
   'Kami menempel urutan gambar di pintu kamar. Butuh dua minggu sampai Bima '
   'terbiasa, tapi sekarang dia yang menunjuk gambarnya sendiri.',
   false, now() - interval '6 days'),
  ('d0000001-4000-4000-8000-000000000002', 'd0000001-0000-4000-8000-000000000001',
   'sekolah', 'Menjelaskan kondisi anak ke guru pendamping',
   'Saya menulis satu halaman berisi hal yang menenangkan dan hal yang memicu. '
   'Gurunya bilang itu jauh lebih berguna daripada istilah medis.',
   false, now() - interval '5 days'),
  ('d0000001-4000-4000-8000-000000000003', 'd0000002-0000-4000-8000-000000000002',
   'sensorik', 'Tempat istirahat sensorik di Surabaya',
   'Beberapa mal sudah menyediakan ruang tenang. Menanyakannya ke petugas '
   'informasi biasanya lebih cepat daripada mencari di peta.',
   false, now() - interval '4 days'),
  ('d0000001-4000-4000-8000-000000000004', 'd0000001-0000-4000-8000-000000000001',
   'dukungan', 'Minggu ini berat, boleh cerita di sini?',
   'Tidak sedang mencari solusi. Hanya ingin menuliskannya di tempat yang '
   'mengerti.',
   true, now() - interval '3 days'),
  ('d0000001-4000-4000-8000-000000000005', 'd0000001-0000-4000-8000-000000000001',
   'komunikasi', 'Kartu gambar buatan sendiri',
   'Saya cetak foto benda yang sering diminta Bima, lalu dilaminating. Murah '
   'dan ternyata lebih dikenali daripada gambar umum.',
   false, now() - interval '3 days'),
  ('d0000001-4000-4000-8000-000000000006', 'd0000001-0000-4000-8000-000000000001',
   'sensorik', 'Anak menutup telinga di mal',
   'Ada yang punya pengalaman serupa? Kami mulai membawa penutup telinga dan '
   'itu membantu, tapi saya ingin tahu cara lain.',
   false, now() - interval '2 days'),
  ('d0000001-4000-4000-8000-000000000007', 'd0000001-0000-4000-8000-000000000001',
   'rutinitas', 'Transisi dari bermain ke makan',
   'Kami memakai timer lima menit yang bisa dilihat. Peringatan yang terlihat '
   'ternyata lebih mudah diterima daripada diucapkan.',
   true, now() - interval '1 day'),
  ('d0000001-4000-4000-8000-000000000008', 'd0000002-0000-4000-8000-000000000002',
   'dukungan', 'Menjaga diri sendiri juga bagian dari mendampingi',
   'Catatan singkat dari sisi profesional: pengasuh yang kelelahan bukan '
   'pengasuh yang gagal.',
   false, now() - interval '12 hours');

insert into balasan_komunitas (postingan_id, pengguna_id, isi, anonim, dibuat_pada)
values
  ('d0000001-4000-4000-8000-000000000001', 'd0000002-0000-4000-8000-000000000002',
   'Urutan gambar seperti ini memang sering lebih cepat diterima daripada '
   'instruksi lisan. Terima kasih sudah berbagi.', false, now() - interval '5 days'),
  ('d0000001-4000-4000-8000-000000000004', 'd0000002-0000-4000-8000-000000000002',
   'Terima kasih sudah menuliskannya. Cerita seperti ini membantu orang lain '
   'merasa tidak sendirian.', false, now() - interval '2 days'),
  ('d0000001-4000-4000-8000-000000000006', 'd0000001-0000-4000-8000-000000000001',
   'Kami juga mengalaminya. Datang saat mal baru buka membantu di rumah kami.',
   true, now() - interval '1 day');

-- ============================================================== notifikasi ==

-- Kelima jenis, dua di antaranya belum dibaca.
insert into notifikasi (pengguna_id, jenis, judul, tautan, dibaca, dibuat_pada)
values
  ('d0000001-0000-4000-8000-000000000001', 'penyesuaian',
   'Rencana minggu ini disesuaikan', '/rencana', false, now() - interval '3 hours'),
  ('d0000001-0000-4000-8000-000000000001', 'belum_dicatat',
   'Satu aktivitas belum tercatat', '/rencana', false, now() - interval '5 hours'),
  ('d0000001-0000-4000-8000-000000000001', 'balasan',
   'Ada balasan pada tulisan Anda', '/komunitas', true, now() - interval '1 day'),
  ('d0000001-0000-4000-8000-000000000001', 'artikel',
   'Artikel baru selesai ditinjau', '/pustaka', true, now() - interval '2 days'),
  ('d0000001-0000-4000-8000-000000000001', 'jadwal',
   'Pengajuan jadwal disetujui', '/direktori', true, now() - interval '4 days');

-- ================================================================= pustaka ==
--
-- SENGAJA KOSONG.
--
-- docs/07 §4 meminta minimal 12 artikel pustaka, dan pada baris yang sama
-- menegaskan isinya "tidak boleh fiktif - ini konten kesehatan yang akan
-- dibaca". Aturan mutlak nomor 2 di CLAUDE.md mengatakan hal yang sama: setiap
-- dokumen wajib punya sumber nyata yang bisa dibuka.
--
-- Karena itu tidak ada dokumen yang di-seed di sini. Mengarang dua belas judul
-- kesehatan beserta URL-nya akan melanggar aturan yang paling tidak boleh
-- dilanggar di proyek ini, dan satu tautan mati sudah cukup untuk meruntuhkan
-- kredibilitas seluruh pilar RAG.
--
-- Korpus diisi lewat `scripts/index_corpus.py` dari daftar sumber nyata, atau
-- satu per satu lewat layar admin `/admin/pengetahuan`. Sampai itu dilakukan,
-- L.4 akan menampilkan "0 dokumen" - dan itu jujur.
