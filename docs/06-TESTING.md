# 06 — Strategi Pengujian

Tabel 5.1 proposal menjanjikan lima jenis pengujian dengan kriteria keberhasilan yang spesifik. Juri boleh menanyakan angkanya. Berkas ini menerjemahkan janji itu menjadi berkas test yang benar-benar bisa dijalankan.

---

## Rekap janji proposal

| Jenis | Cakupan | Kriteria keberhasilan |
|---|---|---|
| Unit | Logika mesin adaptasi dan perhitungan skor kesiapan | Seluruh kasus uji utama berhasil |
| Integrasi | Alur data aplikasi, layanan perantara, basis data | Tidak ada kegagalan sinkronisasi |
| Keterpaduan jawaban | Kesesuaian jawaban asisten dengan dokumen sumber | Minimal 95% jawaban dapat ditelusuri |
| Batas aman | Penolakan permintaan diagnosis, obat, dosis | Seluruh permintaan pada daftar uji ditolak |
| Penerimaan pengguna | Kemudahan penggunaan oleh pengasuh | Skor System Usability Scale minimal 70 |

---

## 1. Unit — `app/test/`

**Mesin adaptasi** (`adaptation_engine_test.dart`) — kelima aturan plus tujuh kasus batas yang terdaftar di `docs/04-AI-PIPELINE.md` bagian 3. Ini test terpenting di seluruh repositori, karena mesin adaptasi adalah pilar AI yang paling mudah salah secara diam-diam.

**Skor kesiapan** (`readiness_score_test.dart`) — pembobotan menurun benar, sampel < 3 mengembalikan null, urutan waktu dihormati.

**Penapis leksikon** (`lexicon_filter_test.dart`) — setiap kategori terpicu, variasi ejaan tertangkap, kata yang mirip tapi tidak berbahaya **tidak** terpicu. Contoh yang harus lolos: "apa itu terapi okupasi" jangan terpicu oleh kata "terapi".

**Jarak Haversine** (`distance_test.dart`) — bandingkan dengan nilai referensi untuk beberapa pasang koordinat Surabaya.

**Perhitungan metrik laporan** (`report_metrics_test.dart`) — persentase aktivitas selesai, rata-rata sesi harian, tren per kategori.

Semua logika ini harus di kelas Dart murni. Kalau sebuah test butuh `WidgetTester` untuk menguji aturan bisnis, logikanya salah tempat.

---

## 2. Widget dan aksesibilitas — `app/test/`

**Audit target sentuh** (`touch_target_test.dart`) — telusuri pohon widget setiap layar, gagalkan test bila ada kontrol interaktif di bawah 48×48 dp.

**Audit kontras** (`contrast_test.dart`) — baca setiap pasangan warna latar–teks di `tokens.dart`, hitung rasio kontras, gagalkan bila ada yang di bawah ambang WCAG 2.2 AA. Ini mengubah aksesibilitas dari niat menjadi jaring pengaman otomatis.

**Penskalaan teks** (`text_scale_test.dart`) — render setiap layar pada `textScaleFactor` 1,0 / 1,5 / 2,0 dan gagalkan bila ada overflow.

**Mode Tenang** (`calm_mode_test.dart`) — saat aktif, verifikasi kelima efeknya benar-benar terjadi, bukan hanya sakelarnya berubah.

**Palet** (`palette_test.dart`) — pindai seluruh berkas Dart untuk nilai warna literal `Color(0x...)` di luar `tokens.dart` dan gagalkan bila ditemukan. Ini mencegah drift palet yang sulit dilihat mata.

---

## 3. Integrasi — `app/integration_test/`

**Sinkronisasi luring** — matikan jaringan, catat 5 respons, tutup dan buka ulang aplikasi, nyalakan jaringan, verifikasi **tepat 5** baris di peladen. Bukan 4, bukan 10. Idempotensi `klien_id` diuji dengan sengaja memicu sinkronisasi dua kali.

**Alur ujung ke ujung pengasuh** — daftar → onboarding → beranda → buka aktivitas → catat respons → tanya asisten → picu batas aman → buat laporan → ekspor PDF.

**Alur berbagi** — pengasuh membagikan laporan → profesional membaca → profesional menanggapi → tanggapan muncul di sisi pengasuh → pengasuh mencabut izin → profesional gagal membaca.

---

## 4. Keamanan data — `scripts/test_rls.sql`

Lima pemeriksaan yang tercantum di `docs/03-DATA-MODEL.md` bagian 4. Jalankan terhadap basis data yang sudah terseed. Kalau salah satu gagal, itu blocker.

Tambahan: **audit APK**. Ekstrak APK rilis dan grep untuk pola kunci API. Hasilnya harus nihil (KNF-03).
```bash
unzip -o build/app/outputs/flutter-apk/app-release.apk -d /tmp/apk
grep -rEo 'AIza[0-9A-Za-z_-]{35}|sk-[A-Za-z0-9]{20,}|gsk_[A-Za-z0-9]{20,}' /tmp/apk || echo "bersih"
```

---

## 5. Evaluasi AI — `scripts/`

**`eval_safety.py`** — 40 prompt, 20 wajib ditolak dan 20 wajib dijawab. Laporkan keduanya. Penolakan berlebihan sama merugikannya dengan kebocoran: aplikasi yang menolak semua pertanyaan tidak berguna, dan juri akan mencobanya.

Keluaran yang diharapkan:
```
Kebocoran batas medis : 0/20
Terjawab benar        : 20/20
Penolakan palsu       : 0/20
```

**`eval_groundedness.py`** — untuk 20 prompt aman, ukur berapa persen kalimat faktual didukung potongan yang dirujuk. Target ≥95%. Simpan keluarannya sebagai bukti.

**Jalankan keduanya lagi tepat sebelum submit**, dengan konfigurasi produksi yang sebenarnya — bukan konfigurasi lokal. Perilaku model bisa berbeda antara lingkungan.

---

## 6. Penerimaan pengguna — SUS

Tabel 5.1 menjanjikan skor System Usability Scale minimal 70. Itu janji yang perlu Anda tepati dengan responden nyata.

**Minimal 5 responden.** Idealnya orang tua atau pengasuh anak dengan spektrum autisme; kalau sulit dijangkau, mahasiswa atau orang tua umum tetap sah asal Anda menyebutkan komposisinya dengan jujur.

Prosedur:
1. Serahkan perangkat berisi APK, tanpa penjelasan apa pun
2. Minta menyelesaikan tugas: buat profil anak, jalankan satu aktivitas dan catat responsnya, ajukan satu pertanyaan ke asisten
3. **Catat waktu sampai aktivitas pertama selesai** — ini sekaligus mengukur KNF-06 yang menargetkan di bawah 10 menit
4. Berikan 10 pernyataan SUS baku dalam Bahasa Indonesia, skala 1–5
5. Hitung skor SUS standar

Simpan lembar jawaban dan foto sesi. Ini bahan yang kuat untuk video dan untuk sesi tanya jawab final.

---

## 7. Pengujian perangkat nyata

KNF-09 menyebut Android 8.0 ke atas dengan RAM minimal 3 GB. **Uji pada perangkat fisik dengan RAM 3 GB**, bukan emulator. Emulator menyembunyikan masalah memori dan performa render yang nyata pada perangkat kelas bawah.

Periksa: waktu buka aplikasi, kelancaran gulir pada daftar rencana, penggunaan memori saat layar laporan terbuka, perilaku saat aplikasi dilatarbelakangkan lalu dibuka lagi.

---

## 8. Uji jalur gagal

Ini yang membedakan prototipe yang bertahan di tangan juri dari yang tidak.

| Skenario | Perilaku yang diharapkan |
|---|---|
| Jaringan mati di tengah percakapan asisten | Pesan jelas + tombol coba lagi, percakapan tidak hilang |
| Kuota API model habis | Jatuh ke fallback, lalu ke mode terbatas. Tidak pernah layar putih |
| Project Supabase ter-pause | Pita "Layanan sedang dipulihkan", data cache tetap terbaca |
| Token sesi kedaluwarsa | Perpanjang diam-diam; kalau gagal, arahkan ke masuk tanpa kehilangan draf |
| Perangkat kehabisan penyimpanan | Antrean luring gagal dengan anggun, beri tahu pengguna |
| Tanggal perangkat salah | Rencana tetap terbaca, tidak crash pada perbandingan tanggal |

Uji ini secara sengaja, bukan berharap tidak terjadi. Penjurian berlangsung sampai 10 hari setelah Anda submit, kemungkinan tanpa Anda dampingi.
