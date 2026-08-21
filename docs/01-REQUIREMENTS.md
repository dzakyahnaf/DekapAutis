# 01 — Kebutuhan dan Penelusuran

Diambil langsung dari Lampiran B proposal final. Kolom **Fase** dan **Bukti** ditambahkan agar setiap kebutuhan punya cara diverifikasi, bukan sekadar diklaim.

---

## Kebutuhan fungsional

| Kode | Kebutuhan | Prioritas | Layar | Fase | Bukti selesai |
|---|---|---|---|---|---|
| KF-01 | Pendaftaran, autentikasi, penetapan peran | Wajib | L.13, L.14 | F1 | Tiga peran bisa masuk; uji RLS lulus |
| KF-02 | Profil anak: usia, komunikasi, sensitivitas, fokus | Wajib | L.1, L.16 | F2 | Baris `profil_anak` lengkap; hapus akun bersih |
| KF-03 | Rencana stimulasi harian & mingguan dari profil | Wajib | L.2, L.6 | F3 | Profil berbeda menghasilkan rencana berbeda |
| KF-04 | Panduan langkah tiap aktivitas | Wajib | L.7 | F3 | 60 aktivitas punya tujuan, alat, 3–6 langkah |
| KF-05 | Catatan respons tiga tingkat | Wajib | L.2, L.7 | F3 | Tercatat luring, tersinkron saat online |
| KF-06 | Penyesuaian rencana dari riwayat respons | Wajib | L.6 | F4 | Unit test 5 aturan hijau; kartu alasan tampil |
| KF-07 | Asisten dari basis pengetahuan terkurasi | Wajib | L.3 | F5 | eval_groundedness ≥95% |
| KF-08 | Rujukan sumber + panel rincian | Wajib | L.4 | F5 | Setiap jawaban punya ≥1 keping sumber terbuka |
| KF-09 | Penolakan diagnosis, tingkat spektrum, obat | Wajib | L.5 | F5 | eval_safety 20/20 tertolak, 0 kebocoran |
| KF-10 | Laporan berkala: narasi + tren | Wajib | L.8 | F6 | Laporan terbuat dari data 4 minggu demo |
| KF-11 | Ekspor PDF + berbagi atas persetujuan | Wajib | L.8, L.16 | F6 | PDF terbaca; cabut izin memutus akses |
| KF-12 | Direktori profesional + filter lokasi | Sebaiknya | L.9, L.10 | F7 | Jarak Haversine benar; lencana terverifikasi |
| KF-13 | Check-in kondisi pengasuh | Sebaiknya | L.2 | F3 | Tercatat harian; muncul di pola laporan |
| KF-14 | Komunitas termoderasi + anonim | Sebaiknya | L.11 | F7 | Unggah anonim tidak membocorkan identitas |
| KF-15 | Pustaka edukasi + status tinjauan | Sebaiknya | L.12 | F5 | Status tinjauan berasal dari basis data |
| KF-16 | Mode Tenang | Wajib | L.15, semua | F8 | Seluruh 5 perubahan aktif serentak |

**12 Wajib, 4 Sebaiknya. Target rencana ini: 16/16.**

---

## Kebutuhan non-fungsional

| Kode | Kategori | Kebutuhan | Cara verifikasi |
|---|---|---|---|
| KNF-01 | Kinerja | Jawaban asisten mulai tampil dalam 5 detik pada 4G | Ukur waktu ke token pertama, 20 percobaan, laporkan median dan persentil 95. Pakai respons mengalir agar teks muncul sebelum jawaban selesai |
| KNF-02 | Keandalan | Catatan tersimpan lokal saat luring, tersinkron otomatis | Integration test: matikan jaringan, catat 5 respons, nyalakan, verifikasi 5 baris di peladen |
| KNF-03 | Keamanan | Enkripsi transit & simpan; kunci model tidak di perangkat | TLS dari Supabase; grep APK terekstrak untuk pola kunci API — hasil harus nihil |
| KNF-04 | Privasi | Berbagi butuh persetujuan eksplisit yang bisa ditarik | Uji RLS kedua: cabut izin lalu profesional gagal membaca |
| KNF-05 | Aksesibilitas | WCAG 2.2 AA, teks 200%, hormati kurangi gerak | Skrip audit kontras + widget test target sentuh + uji manual 200% |
| KNF-06 | Kegunaan | Pengguna baru selesaikan aktivitas pertama tanpa bantuan dalam 10 menit | Uji dengan 5 responden, catat waktunya |
| KNF-07 | Keterlacakan | Setiap keluaran asisten menyimpan rujukan dokumen | Kolom `potongan_dirujuk` tidak pernah kosong pada jawaban sukses |
| KNF-08 | Keterpeliharaan | Basis pengetahuan diperbarui tanpa pembaruan aplikasi | Tambah dokumen lewat admin, jawaban baru muncul tanpa build ulang |
| KNF-09 | Kompatibilitas | Android 8.0+, RAM minimal 3 GB | Uji pada perangkat fisik 3 GB, bukan emulator |

---

## Aktor

**Pengasuh** — mengelola profil anak, menjalankan rencana harian, mencatat respons, bertanya kepada asisten, membuat dan membagikan laporan, check-in kondisi diri, ikut komunitas.

**Tenaga profesional** — melengkapi profil praktik, menerima laporan yang dibagikan, memberi tanggapan, menerima pengajuan jadwal.

**Administrator** — memverifikasi akun profesional, mengelola versi basis pengetahuan, menangani antrean moderasi.

---

## Batasan produk yang wajib dipatuhi

Diambil dari Bab IV proposal. Ini membatasi apa yang boleh dibangun.

**Fungsional:**
- Bukan untuk digunakan langsung oleh anak tanpa pendampingan
- Rencana stimulasi mendukung, tidak menggantikan program terapi profesional
- Direktori profesional **hanya menampilkan informasi dan mengajukan jadwal** — tanpa pemrosesan pembayaran, tanpa penyelenggaraan sesi konsultasi
- Android 8.0+, saran RAM 3 GB
- Asisten, penyusunan rencana, dan pembuatan laporan butuh internet; rencana terunduh dan pencatatan respons tetap bisa luring

**Etis dan medis:**
- Tidak mendiagnosis
- Tidak menentukan tingkat keparahan spektrum
- Tidak memberi anjuran obat maupun dosis
- Setiap permintaan yang menyentuh ranah itu ditolak lapisan penapis, dijawab dengan pemberitahuan batas aman, lalu dialihkan ke daftar tenaga profesional terdekat
- Setiap keluaran AI disertai penanda sumber dan pernyataan bukan pengganti konsultasi profesional
- **Tidak menghasilkan skor tunggal atas kemampuan anak**

**Data dan privasi:**
- Enkripsi saat transit dan saat tersimpan; hanya akun pengasuh bersangkutan yang bisa mengakses
- Berbagi ke profesional butuh persetujuan eksplisit per tindakan, dapat ditarik kembali
- Pengguna dapat mengunduh salinan seluruh data dan menghapus akun beserta seluruh data terkait
- Percakapan tidak dipakai melatih ulang model pihak ketiga

> **Perhatian pada butir terakhir.** Klaim ini hanya benar jika Anda memakai tier berbayar penyedia model. Pada free tier Gemini, prompt Anda dipakai Google untuk memperbaiki model kecuali Anda berada di EU, UK, atau EEA. Aktifkan billing (biayanya sen untuk skala demo) atau revisi klaimnya. Jangan biarkan pernyataan yang tidak Anda penuhi berdiri di dokumen resmi.

---

## Rubrik penilaian Tahap 2 dan cara rencana ini menjawabnya

**Prototype** — Implementasi 35%, **Cara Penggunaan 30%**, Kelengkapan 20%, Visual 15%.

| Kriteria | Yang dinilai | Dijawab oleh |
|---|---|---|
| Implementasi 35% | Apakah sistemnya benar-benar jalan, bukan tampilan kosong | F3–F6 berfungsi penuh dengan data nyata; RAG dan mesin adaptasi bekerja, bukan disimulasikan |
| Cara Penggunaan 30% | Apakah juri bisa memakainya sendiri | F10: akun demo satu ketuk, riwayat 4 minggu terseed, tur pertama kali, layar cara pakai, README dengan kredensial |
| Kelengkapan 20% | Berapa banyak fitur yang benar-benar ada | 16/16 KF, tiga aktor, 17 layar |
| Visual 15% | Konsistensi dan kenyamanan | Token desain terkunci, palet dua keluarga, audit kontras otomatis |

**Video** — Kesesuaian dengan proposal 25%, Gambaran produk 35%, Konsep dan ide 25%, Kreativitas 15%.
Yang paling sering dilupakan tim: kriteria video meminta **gambaran proses perancangan**, bukan hanya demo. Siapkan potongan yang menunjukkan diagram arsitektur, alur RAG, dan mesin adaptasi — bukan hanya rekaman layar.
