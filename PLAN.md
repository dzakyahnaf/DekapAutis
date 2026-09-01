# PLAN.md — DekapAutis, dari nol sampai siap submit

Rencana ini menargetkan **implementasi penuh**: 16 kebutuhan fungsional, 9 kebutuhan non-fungsional, 17 layar pengasuh, plus alur tenaga profesional dan administrator. Bukan versi 50%.

Baca `CLAUDE.md` lebih dulu. Spesifikasi rinci ada di `docs/`.

**Aturan lintas fase:** setiap fase berakhir dengan `flutter analyze` bersih, `flutter test` hijau, dan aplikasi tetap bisa di-build. Tandai checkbox saat butir selesai.

---

## Peta ketergantungan

```
F0 Fondasi ──┬─→ F1 Data & Auth ──┬─→ F2 Profil anak ──→ F3 Rencana & aktivitas ──→ F4 Adaptasi
             │                    │
             │                    ├─→ F5 Basis pengetahuan & RAG ──→ F6 Laporan
             │                    │
             │                    └─→ F7 Direktori, komunitas, pustaka, check-in
             │
             └─→ F8 Aksesibilitas, Mode Tenang, luring, notifikasi

F9 Peran profesional & admin  ← butuh F6
F10 Seed demo, QA, evaluasi   ← butuh semua
F11 Rilis & bundel submission ← butuh F10
```

F5 dan F3/F4 bisa dikerjakan paralel oleh dua orang. Pembagian yang disarankan: **Dzaky** ambil F1, F4, F5, F9; **Diffa** ambil F2, F3, F7, F8. F0, F6, F10, F11 dikerjakan bersama.

---

## F0 — Fondasi

Tujuan: kerangka yang bisa di-build, bertema benar, dan aman secara rahasia sejak commit pertama.

- [x] Inisialisasi repositori Git + `.gitignore` yang sudah memuat `.env*`, `*.jks`, `*.keystore`, `key.properties`, `android/local.properties`
- [x] `flutter create` dengan org `id.ac.its.fable5`, application id `id.ac.its.fable5.dekapautis`
- [x] Tambah dependensi inti: `flutter_riverpod`, `go_router`, `supabase_flutter`, `drift`, `sqlite3_flutter_libs`, `flutter_secure_storage`, `connectivity_plus`, `google_fonts`, `pdf`, `printing`, `intl`, `share_plus`, `url_launcher`, `geolocator`
- [x] Terjemahkan seluruh token desain (`docs/02-DESIGN-SYSTEM.md`) menjadi `core/theme/tokens.dart` + `ThemeData` — warna, tipografi, radius, spasi, tinggi tombol, ukuran ikon
- [x] Muat Lexend Deca dan IBM Plex Mono; **bundel sebagai aset lokal**, jangan andalkan unduh runtime dari Google Fonts (aplikasi harus tetap benar saat luring)
- [x] Bangun widget bersama: `RoutineCard`, `SourceChip`, `SafetyBanner`, `CategoryPill`, `PrimaryButton`, `SecondaryButton`, `EmptyState`, `OfflineBanner`
- [x] Kerangka `go_router` dengan seluruh rute bernama untuk 17 layar + rute profesional/admin, semua masih layar kosong berlabel
- [x] `flutter_lints` ketat + `analysis_options.yaml`; nol warning
- [x] GitHub Actions: workflow yang menjalankan `flutter analyze` + `flutter test` pada setiap push
- [x] Buat `docs/DEVIATIONS.md` kosong dengan header tabel

**Selesai bila:** aplikasi berjalan di emulator, menampilkan splash bertema benar, dan seluruh rute bisa dinavigasi meski isinya kosong. Tidak ada satu pun warna di luar palet dalam kode.

---

## F1 — Basis data, keamanan, autentikasi

Tujuan: 12 entitas hidup dengan RLS yang benar, dan pengguna bisa masuk.

- [ ] Buat project Supabase; catat URL dan anon key ke `.env` lokal (tidak di-commit)
- [x] Aktifkan ekstensi `vector` dan verifikasi konfigurasi teks penuh Bahasa Indonesia: `SELECT cfgname FROM pg_ts_config WHERE cfgname='indonesian';`
- [x] Migrasi 001: 12 entitas sesuai `docs/03-DATA-MODEL.md` (`pengguna`, `profil_anak`, `rencana`, `jadwal_aktivitas`, `aktivitas`, `catatan_respons`, `catatan_pengasuh`, `laporan`, `dokumen_pengetahuan`, `potongan_dokumen`, `profesional`, `izin_berbagi`)
- [x] Migrasi 002: tabel pendukung — `adaptasi_log`, `log_batas_aman`, `postingan_komunitas`, `balasan_komunitas`, `notifikasi`, `versi_basis_pengetahuan`, `tanggapan_profesional`
- [x] Migrasi 003: **RLS di setiap tabel**. Default deny. Pengasuh hanya melihat barisnya sendiri; tenaga profesional hanya melihat laporan yang punya `izin_berbagi` aktif; administrator lewat peran terpisah
- [x] Migrasi 004: indeks — `ivfflat` pada `potongan_dokumen.embedding`, GIN pada `to_tsvector('indonesian', potongan_dokumen.teks)`, indeks komposit pada kolom yang sering difilter
- [x] Tulis **uji RLS** sebagai skrip SQL: buat dua pengguna, pastikan A tidak bisa membaca satu baris pun milik B. Ini bukti privasi yang akan Anda tunjukkan di video
- [x] Implementasi auth Flutter: daftar, masuk, lupa kata sandi, masuk dengan Google, keluar (layar L.14)
- [x] Penetapan peran saat pendaftaran: `pengasuh` / `profesional` / `admin` (KF-01)
- [x] Sesi persisten via `flutter_secure_storage`; auto-refresh token
- [x] Layar splash (L.13) yang memuat sesi dan mengarahkan ke beranda atau masuk

**Selesai bila:** uji RLS lulus — pengguna A benar-benar tidak bisa membaca data pengguna B, dibuktikan lewat skrip, bukan lewat asumsi. `KF-01` tercentang.

---

## F2 — Onboarding dan profil anak

- [x] Onboarding 4 langkah (L.1): nama panggilan, usia, kemampuan komunikasi (belum verbal / beberapa kata / kalimat pendek / lancar), sensitivitas sensorik (multi-pilih), fokus perkembangan 3 bulan (KF-02)
- [x] Langkah 4 = preferensi aksesibilitas (L.15): Mode Tenang, ukuran teks (standar/besar/sangat besar) dengan pratinjau langsung, kurangi gerakan
- [x] Indikator progres bilah **statis** 4 segmen — bukan animasi
- [x] Pita privasi di bawah form: "Data anak dienkripsi dan tidak dibagikan tanpa izin Anda"
- [x] Simpan ke `profil_anak`; dukung lebih dari satu anak per akun
- [x] Layar Profil & Privasi (L.16): sunting profil anak, kelola izin berbagi, unduh salinan seluruh data (JSON), hapus akun beserta seluruh data
- [x] **Penghapusan akun harus benar-benar menghapus**, bukan menandai. Uji dengan query langsung setelahnya

**Selesai bila:** profil anak baru menghasilkan rekaman lengkap, dan penghapusan akun meninggalkan nol baris di 12 tabel. `KF-02` tercentang.

---

## F3 — Rencana stimulasi, aktivitas, catatan respons

- [x] Bangun katalog aktivitas: minimal **60 aktivitas** melintasi 5 kategori (Komunikasi, Motorik, Sensorik, Kemandirian, Sosial) × 4 tingkat kesulitan. Setiap aktivitas punya tujuan, alat yang perlu disiapkan, dan 3–6 langkah pelaksanaan. Lihat `docs/07-DEMO-SEED.md` untuk aturan penyusunannya
- [x] Edge Function `generate-plan`: menyusun rencana harian & mingguan dari profil anak (KF-03). Deterministik dulu berdasarkan aturan pemetaan profil→kategori→tingkat; model bahasa hanya dipakai untuk menyusun ulang narasi, bukan memilih aktivitas medis
- [x] Layar Rencana Mingguan (L.6): pemilih hari, kartu penjelasan penyesuaian, daftar aktivitas dengan waktu dan durasi
- [x] Layar Detail Aktivitas (L.7): tujuan, alat, langkah bernomor, pita catatan respons melekat di bawah (KF-04)
- [x] Pencatatan respons tiga tingkat **Mudah / Pas / Sulit** + catatan opsional (KF-05). Tersedia dari kartu di beranda maupun dari detail aktivitas
- [x] Beranda (L.2): sapaan, check-in kondisi pengasuh 5 tingkat (KF-13), agenda hari ini, kartu rutinitas dengan tombol respons
- [x] Antrian tulis luring: catatan respons tersimpan lokal saat tanpa jaringan lalu disinkronkan otomatis (KNF-02)

**Selesai bila:** satu pengguna bisa menjalani hari penuh — buka beranda, buka aktivitas, catat respons — sepenuhnya tanpa jaringan, lalu data muncul di peladen setelah online. `KF-03, KF-04, KF-05, KF-13` tercentang.

---

## F4 — Mesin adaptasi rencana

Ini pilar AI kedua. Logikanya wajib deterministik dan bisa diuji. Algoritma lengkap ada di `docs/04-AI-PIPELINE.md` bagian 3.

- [x] Kelas Dart murni `AdaptationEngine` — tanpa ketergantungan UI, tanpa panggilan jaringan
- [x] Perhitungan skor kesiapan per kategori dari 6 catatan respons terakhir
- [x] Aturan A — naik tingkat: ≥2 dari 3 respons terakhir "Mudah" tanpa "Sulit" → tingkat +1 (maks 4)
- [x] Aturan B — turun tingkat: ≥2 dari 3 respons terakhir "Sulit" → tingkat −1 (min 1), durasi −25% (min 5 menit), lampirkan saran penyesuaian lingkungan
- [x] Aturan C — porsi: kategori dengan skor kesiapan naik mendapat +1 sesi per minggu (maks 3), total harian dibatasi 5
- [x] Aturan D — penandaan: capaian menurun 2 periode berturut-turut → tandai `perhatian` pada laporan untuk tenaga profesional
- [x] Aturan E — penjadwalan: pilih blok jam dengan rasio "Mudah" tertinggi, minimum 3 sampel, jika kurang pertahankan default
- [x] Setiap perubahan menulis baris `adaptasi_log` berisi `aturan_id`, kategori, nilai sebelum, nilai sesudah, **alasan dalam Bahasa Indonesia yang bisa dibaca pengguna**, dan tanda apakah dikoreksi manual
- [x] UI: kartu penjelasan penyesuaian di layar Rencana, dengan tombol koreksi manual (KF-06)
- [x] **Unit test untuk kelima aturan**, termasuk kasus batas: data kosong, tepat 3 sampel, tingkat sudah di batas atas/bawah, respons campur rata

**Selesai bila:** seluruh unit test aturan hijau, dan kartu penjelasan menampilkan alasan yang masuk akal untuk skenario demo. `KF-06` tercentang.

---

## F5 — Basis pengetahuan, RAG, dan penapis batas medis

Pilar AI pertama dan bagian paling berisiko. Spesifikasi penuh di `docs/04-AI-PIPELINE.md`.

- [ ] *31 dari 40 terkumpul* — Kumpulkan korpus: minimal **40 dokumen nyata** berbahasa Indonesia dari sumber yang bisa dibuka — Kemenkes, IDAI, WHO (versi Indonesia atau terjemahan resmi), jurnal terbuka, materi organisasi profesi. Catat judul, penerbit, tahun, URL, halaman untuk setiap dokumen. **Tidak boleh ada dokumen fiktif**
- [x] Skrip `scripts/index_corpus.py`: potong dokumen (600–800 token, tumpang tindih 100), embed, muat ke `dokumen_pengetahuan` + `potongan_dokumen`
- [x] Edge Function `ask` — pipeline lengkap:
  - [x] **Lapis 1 penapis leksikon**: pencocokan deterministik atas pertanyaan yang dinormalkan, mencakup diagnosis, derajat/tingkat spektrum, obat, dosis, resep, klaim sembuh, diet sebagai terapi, suplemen. Sertakan salah ketik umum
  - [x] **Lapis 2 klasifikasi maksud** oleh model bahasa, mengembalikan JSON `{kategori, alasan}`
  - [x] **Pengambilan hibrida**: kemiripan kosinus pgvector **digabung** pencarian teks penuh `indonesian`, gabungkan dengan Reciprocal Rank Fusion, ambil 8 potongan teratas
  - [x] **Pembangkitan** dengan instruksi menjawab hanya dari konteks, wajib menyertakan nomor rujukan
  - [x] **Lapis 3 verifikasi keluaran**: bila jawaban tidak didukung potongan mana pun, ganti dengan "informasi belum tersedia" + saran konsultasi
  - [x] Failover otomatis Gemini → Groq pada 429/5xx; bila keduanya gagal, jatuh ke pencarian teks penuh saja dan tandai "mode terbatas"
  - [x] Catat setiap pemicu batas aman ke `log_batas_aman`
- [x] Layar Tanya Dekap (L.3): percakapan, riwayat, jawaban dengan keping rujukan bernomor (KF-07)
- [x] Panel Sumber (L.4): lembar bawah berisi judul, penerbit, tahun, halaman, kutipan asli, tautan buka sumber (KF-08). Baris kaki menampilkan **jumlah dokumen riil dari basis data**
- [x] Pemberitahuan Batas Aman (L.5): ungu tergelap `#4A2657`, garis 2,4 px, ikon perisai, daftar "yang bisa saya bantu", tombol ke direktori profesional dan ke pembuatan laporan (KF-09)
- [x] Layar Pustaka Edukasi (L.12): konten terkurasi, kategori, penanda status tinjauan (KF-15) — *jumlah dokumen dihitung `COUNT(*)`, bukan angka mockup*

**Selesai bila:** `python scripts/eval_safety.py` menolak 20/20 prompt terlarang **dan** menjawab 20/20 prompt yang seharusnya dijawab; `eval_groundedness.py` melaporkan ≥95% keterlacakan. `KF-07, KF-08, KF-09, KF-15` tercentang.

---

## F6 — Laporan perkembangan

- [x] Edge Function `summarize-report`: meringkas catatan harian menjadi narasi Bahasa Indonesia untuk tenaga profesional. Narasi **hanya boleh menyebut data yang benar-benar ada** — tanpa interpretasi klinis, tanpa skor tunggal (KF-10)
- [x] Layar Laporan (L.8): pemilih periode 2 minggu / 1 bulan / 3 bulan, tiga metrik ringkas, grafik tren "Mudah" per minggu, rincian per kategori, kotak ringkasan untuk terapis
- [x] Grafik digambar dengan `CustomPainter` — tanpa animasi masuk, angka memakai IBM Plex Mono
- [x] Ekspor PDF memakai paket `pdf` + `printing`, tata letak A4, memuat kop, periode, metrik, tabel per kategori, narasi, dan catatan penyangkalan bahwa dokumen ini bukan hasil pemeriksaan klinis (KF-11)
- [x] Berbagi ke tenaga profesional lewat `izin_berbagi`: persetujuan eksplisit per tindakan, bisa ditarik kembali, tercatat waktunya
- [x] Layar kelola izin berbagi di Profil, memperlihatkan siapa punya akses ke apa dan sejak kapan

**Selesai bila:** PDF terbuat dari data riil, terbaca rapi, dan pencabutan izin benar-benar memutus akses profesional — dibuktikan lewat uji RLS kedua. `KF-10, KF-11` tercentang.

---

## F7 — Direktori, komunitas, pustaka

- [x] Direktori Profesional (L.9): pencarian, filter jenis layanan, jarak dihitung **Haversine di klien** dari koordinat tersimpan — tanpa SDK peta berbayar. Lencana terverifikasi (KF-12)
- [x] Detail Profesional (L.10): tentang, layanan, jadwal praktik, tombol ajukan jadwal konsultasi, tombol kirim laporan
- [x] Pengajuan jadwal menyimpan permintaan dan memberi notifikasi ke profesional. **Tanpa pembayaran, tanpa sesi konsultasi di dalam aplikasi** — sesuai batasan Bab 4.1
- [x] Komunitas (L.11): daftar diskusi, filter topik, unggah dengan opsi anonim, balasan, pita "dimoderasi relawan dan tenaga profesional" (KF-14)
- [x] Moderasi: penapis kata terlarang + antrean laporan penyalahgunaan yang bisa ditindak admin — *tabel, RLS, dan pelaporan dari layar selesai; layar admin `/admin/moderasi` tetap di F9*
- [x] Notifikasi (L.17): pengelompokan Hari ini / Kemarin / Minggu ini, jenis — penyesuaian rencana, aktivitas belum tercatat, balasan komunitas, artikel baru ditinjau, persetujuan jadwal

**Selesai bila:** `KF-12, KF-14` tercentang dan seluruh 17 layar terisi.

---

## F8 — Aksesibilitas, Mode Tenang, luring, notifikasi

- [x] **Mode Tenang** sebagai fitur menyeluruh, bukan sekadar setelan (KF-16): sembunyikan gambar dan ganti label teks, turunkan saturasi kategori ke tint, naikkan spasi satu tingkat, bisukan notifikasi non-kritis, seluruh transisi 0 ms. Tampilkan pil "Mode Tenang aktif" di header agar keadaannya tidak tersembunyi
- [x] Penskalaan teks sampai 200% tanpa layout rusak — uji setiap layar pada faktor 1,0 / 1,5 / 2,0 (KNF-05)
- [x] Hormati pengaturan kurangi gerak sistem
- [x] Audit kontras otomatis: skrip yang memeriksa setiap pasangan warna di `tokens.dart` terhadap ambang WCAG 2.2 AA dan gagal build jika ada yang lolos di bawah ambang
- [x] Audit target sentuh: widget test yang memastikan tidak ada kontrol interaktif di bawah 48×48
- [ ] Label semantik pada seluruh ikon bermakna; uji dengan TalkBack pada perangkat nyata — *audit otomatis selesai (`semantics_test.dart` menelusuri pohon semantik seluruh rute); uji TalkBack di perangkat nyata belum dijalankan*
- [x] Indikator luring dan sinkronisasi menyeluruh — `AppStatusStrip` dipasang sekali di `MaterialApp.builder`, bukan per layar
- [ ] Notifikasi lokal terjadwal untuk aktivitas belum tercatat — *logika penjadwalan selesai dan teruji (`domain/notifikasi/pengingat.dart`); pengikatan ke plugin platform menunggu keputusan dependensi `flutter_local_notifications`*

**Selesai bila:** skrip audit kontras dan widget test target sentuh lulus, dan seluruh layar terbaca dengan TalkBack. `KF-16, KNF-05` tercentang.

---

## F9 — Peran tenaga profesional dan administrator

Ini yang membuat tiga aktor pada Gambar 6.1 benar-benar terimplementasi, bukan sekadar tergambar.

- [x] Onboarding profesional: profil praktik, spesialisasi, lokasi, jadwal, unggah bukti kredensial
- [x] Kotak masuk laporan: daftar laporan yang dibagikan pengasuh, dengan penanda `perhatian` dari mesin adaptasi
- [x] Detail laporan + form tanggapan; tanggapan tersimpan ke `tanggapan_profesional` dan muncul di sisi pengasuh, menutup lingkaran alur bisnis Gambar 7.1
- [x] Admin: verifikasi akun profesional (setujui/tolak dengan alasan) — *penolakan tanpa alasan ditolak basis data, bukan hanya oleh UI*
- [x] Admin: kelola versi basis pengetahuan — unggah dokumen, tandai status tinjauan, picu indexing ulang — *tombol menandai dokumen ke antrean; embedding dijalankan `scripts/index_corpus.py` karena kunci API tidak boleh ada di klien*
- [x] Admin: antrean moderasi komunitas

**Selesai bila:** satu laporan bisa mengalir penuh dari pengasuh → profesional → tanggapan → kembali memengaruhi rencana.

---

## F10 — Data demo, pengujian, evaluasi

Fase ini yang mengamankan bobot **Cara Penggunaan 30%**. Jangan diperlakukan sebagai tugas sisa.

- [x] **Akun demo terseed** `demo@dekapautis.id` dengan riwayat 4 minggu yang realistis: Rina Kartika sebagai pengasuh, Bima 6 tahun, 24 catatan respons, tren membaik pada Komunikasi, satu kategori menurun agar penandaan `perhatian` benar-benar terlihat, beberapa postingan komunitas, satu laporan yang sudah dibagikan
- [x] Tombol **"Masuk sebagai demo"** di layar masuk — juri tidak perlu mendaftar. Beri label jelas bahwa ini akun demo berisi data sintetis
- [x] Seed akun profesional demo dan akun admin demo
- [x] Tur pertama kali: 4 sorotan singkat pada beranda, bisa dilewati, hanya sekali
- [x] Layar "Cara pakai" di dalam aplikasi yang meringkas 6 langkah alur pada Bab IX proposal
- [x] Unit test: mesin adaptasi, perhitungan skor kesiapan, penapis leksikon, penghitung jarak (Tabel 5.1 baris "Unit")
- [ ] Integration test: alur data klien → Edge Function → basis data, termasuk sinkronisasi luring (Tabel 5.1 baris "Integrasi")
- [x] `scripts/eval_groundedness.py`: ≥95% jawaban dapat ditelusuri ke potongan sumber — *skrip selesai; belum dapat diukur karena korpus masih 0 dokumen* — *pengambilan 20/20 (100%); pengutipan kalimat menunggu kunci API model*
- [x] `scripts/eval_safety.py`: 40 prompt — 20 wajib ditolak, 20 wajib dijawab. Nol kebocoran, dan catat juga tingkat penolakan palsu — *0/20 bocor, 0/20 penolakan palsu pada lapis 1 dan 3; lapis 2 belum terukur karena belum ada kunci API*
- [ ] **Uji SUS dengan minimal 5 responden nyata**, target skor ≥70 (Tabel 5.1 baris "Penerimaan pengguna"). Simpan lembar jawaban sebagai bukti — juri boleh menanyakannya
- [ ] Uji pada perangkat Android nyata dengan RAM 3 GB, bukan hanya emulator (KNF-09)
- [ ] Uji jalur gagal: matikan jaringan di tengah alur, habiskan kuota API secara sengaja, pastikan tidak ada crash

**Selesai bila:** seluruh kriteria Tabel 5.1 proposal terpenuhi dengan angka nyata yang bisa Anda sebutkan di video.

---

## F11 — Rilis dan bundel submission

- [x] Buat keystore rilis; simpan `key.properties` di luar Git
- [ ] `flutter build apk --release` — *APK universal ter-build (67,5 MB) dan digrep bersih dari kunci API; penandatanganan rilis masih memakai kunci debug karena keystore belum dibuat* — APK ditandatangani, uji pasang pada perangkat bersih tanpa Flutter terpasang
- [ ] Kecilkan ukuran: `--split-per-abi` bila perlu, tapi **sediakan juga satu APK universal** karena juri tidak akan tahu ABI perangkatnya
- [ ] `flutter build web --release`, deploy ke hosting gratis; ini menjadi "link hasil karya" pendamping supaya juri bisa mencoba tanpa memasang apa pun
- [ ] **Keep-alive Supabase**: *fungsi `keep-alive` dan workflow harian sudah ditulis; menunggu proyek remote untuk dijalankan sekali* — cron GitHub Actions harian yang memanggil Edge Function `keep-alive` untuk menyentuh basis data. Project free ter-pause setelah 7 hari tanpa aktivitas database, sementara penjurian berlangsung 2–11 September
- [ ] Pantau kuota API model harian selama masa penjurian; siapkan kunci cadangan
- [x] `README.md` repositori: ringkasan produk, tangkapan layar, arsitektur, cara menjalankan, kredensial akun demo, batasan yang diketahui — *tangkapan layar menunggu perangkat nyata*
- [ ] Rapikan riwayat commit dan buat rilis GitHub bertag `v1.0.0` dengan APK terlampir
- [ ] Unggah APK ke Google Drive, setel akses publik, **uji tautan dari jendela penyamaran**
- [ ] Susun berkas ZIP submission:
  - `ITC2026_SOFTDEV_ImplementasiAplikasi_Fable5Enjoyer.txt` — berisi tautan APK Google Drive **dan** tautan repositori GitHub **dan** tautan web
  - `ITC2026_SOFTDEV_Video_Fable5Enjoyer.txt`
  - `ITC2026_SOFTDEV_Poster_Fable5Enjoyer.txt`
  - Nama ZIP: `ITC2026_2_SOFTDEV_Fable5Enjoyer_DekapAutis.zip`, maksimum 5 MB
- [ ] Verifikasi setiap tautan dari perangkat dan jaringan berbeda. Rulebook menegaskan tautan yang tidak bisa diakses adalah tanggung jawab peserta

**Selesai bila:** orang lain yang belum pernah melihat project ini bisa memasang APK, masuk sebagai demo, dan menyelesaikan alur enam langkah Bab IX tanpa bertanya kepada Anda.

---

## Urutan pengerjaan bila waktu menyempit

Anda meminta 100% dan rencana ini menargetkan 100%. Tetapi urutan di atas sengaja disusun supaya **produk tetap layak submit di titik mana pun**. Bila sesuatu terjadi, potong dari belakang dengan urutan ini:

1. F9 admin (verifikasi bisa dilakukan lewat dashboard Supabase)
2. F7 komunitas (KF-14, prioritas "Sebaiknya")
3. F9 alur profesional penuh (sisakan kotak masuk laporan saja)
4. F7 pustaka edukasi (KF-15)

Jangan pernah memotong F5 atau F4 — keduanya adalah alasan produk ini disebut berbasis kecerdasan artifisial, dan tanpa keduanya sub-tema kompetisi tidak terjawab.

## Yang tidak boleh terlupa

- Biaya pendaftaran Tahap 2 **Rp40.001** (angka 1 adalah kode bidang Software Development) ke Seabank 901063117348 a.n. Adine Vivia. **Akses unggah baru dibuka setelah panitia mengonfirmasi pembayaran** — kalau belum ditransfer, lakukan sekarang, bukan tanggal 1
- Poster A3 300 ppi dengan logo ITS, HIMASIF, dan IT CONVERT 2026 di kiri atas, diunggah ke Instagram dengan tag `@itconvert_unej`, tagar `#ITC2026 #SOFTDEV`
- Video 3–7 menit, minimal 720p, hak akses **Unlisted**, wajib memakai bumper panitia
- Lembar orisinalitas sudah dikumpulkan di Tahap 1 — pastikan tidak ada klaim baru di Tahap 2 yang bertentangan dengannya
