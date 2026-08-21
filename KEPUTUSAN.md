# KEPUTUSAN.md — register keputusan proyek

Dua puluh empat keputusan yang diambil sebelum F0 dimulai, setelah pembacaan penuh
`CLAUDE.md`, `PLAN.md`, dan seluruh `docs/`. Berkas ini adalah memori lintas sesi
kedua setelah `PLAN.md`: kalau sebuah sesi baru bertanya "kenapa begini", jawabannya
ada di sini. Konsekuensi teknis yang menyimpang dari proposal juga tercatat di
`docs/DEVIATIONS.md`.

Diputuskan **21 Agustus 2026** oleh Muhammad Dzaky Ahnaf.

---

## Fondasi

| # | Keputusan | Pilihan | Konsekuensi yang harus diingat |
|---|---|---|---|
| 1 | Lokasi repositori | `C:\Users\Dzaky Ahnaf\kompetisi\itconvert\dekapautis` | Paket rencana asli di `Downloads/` tetap utuh sebagai cadangan |
| 2 | Cakupan | **108/108 butir, 12 fase, tanpa pemotongan** | Keberatan soal 11 hari sudah disampaikan dan ditolak. Tidak dibahas lagi |
| 3 | Platform | Android; web dicoba di F11 sebagai bonus | F0–F10 tidak berkompromi demi web |
| 4 | Penyimpanan lokal | SQLCipher, via `sqlite3` v3 + hook `source: sqlite3mc` | Jangan pernah mengubah hook itu ke `sqlite3` polos — itu mematikan enkripsi tanpa error |

## Kontrak teknis

| # | Keputusan | Pilihan | Konsekuensi |
|---|---|---|---|
| 5 | Audit kontras | Pasangan teks saja + dua aturan token baru | Nol pengecualian: 16 pasangan terdaftar semuanya lulus AA |
| 6 | Streaming vs Lapis 3 | Streaming penuh, Lapis 3 menandai | Ditambah pemutusan stream inkremental agar kalimat terlarang tidak selesai terbaca |
| 7 | Login Google | `signInWithOAuth` bawaan Supabase | Tanpa ketergantungan SHA-1 keystore, jadi APK rilis F11 tidak akan rusak |
| 8 | Pembagian kerja | Satu sesi, dikerjakan berurutan | Diffa memegang poster, video, korpus, dan uji SUS |

## Layanan dan kunci

| # | Keputusan | Pilihan | Konsekuensi |
|---|---|---|---|
| 9 | Gemini | Free tier, klaim Bab 4.3 direvisi jujur | Kuota bisa habis saat penjurian; rantai fallback jadi jalur nyata, bukan darurat |
| 10 | Embedding | 768 dimensi + indeks **HNSW** | Ganti dimensi = embed ulang seluruh korpus |
| 11 | Toolchain | Dipasang lengkap 21 Agustus | Lihat "Catatan lingkungan" di bawah |
| 12 | Ketahanan Supabase | Free + cron keep-alive harian | Cron wajib diverifikasi berhasil sekali sebelum submit |

## Klaim dan data demo

| # | Keputusan | Pilihan |
|---|---|---|
| 13 | Kalimat L.4 | Diubah jadi "dokumen sumber resmi yang dapat Anda buka sendiri"; RAG menyaring status `ditolak` |
| 14 | Direktori | Lembaga nyata Surabaya, tanpa nama praktisi perorangan |
| 15 | Akun admin demo | Kredensial dicantumkan, aksi destruktif dinonaktifkan |
| 16 | Volume demo | ±120 catatan respons; plafon `C_porsi` dinaikkan 3 → 7 sesi/minggu |

## Lubang spesifikasi yang ditutup

| # | Keputusan | Pilihan |
|---|---|---|
| 17 | Pemetaan profil → rencana | **Belum diputuskan.** Draf tabel disusun lebih dulu, ditinjau Dzaky sebelum dikodekan. **Gerbang sebelum F3** |
| 18 | Istilah mesin adaptasi | capaian = % "mudah" per kategori per minggu · blok jam = 1 jam · periode = minggu kalender Senin–Minggu |
| 19 | Pencocokan leksikon | Regex batas-kata atas frasa, bukan kata tunggal |
| 20 | Sumber lokasi L.9 | GPS opsional + pilihan kota manual |
| 21 | Navigasi | Tab Komunitas menjadi **Jelajah**, memuat Direktori · Pustaka · Komunitas |
| 22 | Kesegaran data demo | Tanggal dihitung saat baca; tanpa reset otomatis |
| 23 | Durasi aktivitas | Katalog 5–20 menit; constraint basis data ikut diperketat |
| 24 | Dua butir web di F11 | Tetap dikerjakan, di akhir, tanpa mengorbankan F0–F10 |

---

## Catatan lingkungan

Flutter 3.41.6 menolak path SDK yang mengandung spasi, dan hook native assets
memanggil `dart` tanpa tanda kutip. Keduanya menggagalkan `flutter test` serta
`flutter build apk`. Dibereskan pada 21 Agustus:

- **SDK Flutter dipindahkan** dari `C:\Users\Dzaky Ahnaf\flutter` ke **`C:\flutter`**.
  Path lama tetap bekerja lewat directory junction, jadi konfigurasi IDE yang
  menunjuk ke sana tidak perlu diubah.
- **Android SDK** diakses lewat junction **`C:\Android\Sdk`**, alasan yang sama.
  SDK aslinya tidak dipindahkan.
- `JAVA_HOME` menunjuk **Temurin JDK 17**; JBR bawaan Android Studio rusak
  (`jbr\lib\jvm.cfg` hilang) dan dibiarkan apa adanya.
- `FLUTTER_ROOT=C:\flutter` diset di level pengguna.

Kalau suatu saat muncul error `'C:\Users\Dzaky' is not recognized as an internal
or external command`, penyebabnya selalu sama: ada path berspasi yang kembali
masuk ke rantai build.

## Yang masih di tangan Anda, bukan di tangan kode

1. **Biaya Rp40.001** ke Seabank 901063117348 a.n. Adine Vivia — akses unggah baru
   terbuka setelah panitia mengonfirmasi.
2. **Korpus 40 dokumen nyata** berbahasa Indonesia dengan URL yang bisa dibuka.
3. **15 lembaga terapi nyata di Surabaya** dengan alamat dan koordinat, untuk seed
   direktori (keputusan 14).
4. **Kunci API Gemini dan Groq.**
5. **Poster A3, video 3–7 menit, dan uji SUS 5 responden.**
