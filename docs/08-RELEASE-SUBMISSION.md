# 08 — Rilis, Ketahanan, dan Bundel Submission

Penjurian Tahap 2 berlangsung **2–11 September 2026**, sampai sepuluh hari setelah Anda submit, kemungkinan tanpa Anda dampingi. Berkas ini memastikan produk masih hidup saat dibuka.

---

## 1. Build rilis Android

**Keystore.** Buat keystore rilis, simpan `key.properties` di luar Git, dan **cadangkan keystore-nya di tempat aman** — kehilangan keystore berarti tidak bisa menerbitkan pembaruan dengan identitas aplikasi yang sama.

```bash
keytool -genkey -v -keystore ~/dekapautis-release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias dekapautis
```

**Build.**
```bash
cd app
flutter build apk --release                 # APK universal — WAJIB
flutter build apk --release --split-per-abi # opsional, ukuran lebih kecil
```

Sediakan **APK universal**. Juri tidak akan tahu ABI perangkatnya, dan APK yang gagal dipasang adalah nilai nol pada kriteria Implementasi yang berbobot 35%.

**Verifikasi wajib sebelum submit:**
- [ ] Pasang pada perangkat bersih yang tidak punya Flutter terpasang
- [ ] Pasang pada perangkat Android 8.0 dan pada Android versi terbaru
- [ ] Pasang pada perangkat RAM 3 GB (KNF-09)
- [ ] Grep APK terekstrak untuk kunci API — hasilnya harus nihil
- [ ] Buka aplikasi dalam keadaan jaringan mati; harus tetap membuka layar masuk, tidak crash
- [ ] Masuk sebagai demo, jalankan alur enam langkah Bab IX sampai tuntas

**Permission.** Hanya `INTERNET` dan `ACCESS_COARSE_LOCATION` untuk direktori. Jangan minta izin yang tidak dipakai — juri yang teliti akan menanyakannya, dan Bab 4.3 Anda berbicara tentang privasi.

---

## 2. Build web sebagai tautan hasil karya pendamping

Rulebook mewajibkan produk berbasis aplikasi menyertakan tautan Google Drive berisi APK. Itu wajib. Tetapi build web dari basis kode yang sama memberi juri jalan mencoba **tanpa memasang apa pun**, dan biayanya nyaris nol.

```bash
flutter build web --release
```

Deploy ke hosting statis gratis. Catatan praktis:
- Font sudah dibundel sebagai aset lokal, jadi tampilannya benar sejak muat pertama
- Uji pada lebar viewport ponsel — layout dirancang untuk 393×852
- Beri catatan di README bahwa web adalah pendamping; APK tetap artefak utama

---

## 3. Ketahanan selama masa penjurian

Ini bagian yang paling sering menjatuhkan tim yang kodenya bagus.

**Supabase ter-pause.** Project free ter-pause setelah 7 hari tanpa aktivitas database, dan yang dihitung adalah aktivitas database — bukan kunjungan dashboard. Project yang di-resume butuh sekitar 30 detik untuk bangun. Penjurian berlangsung sampai 11 September.

Mitigasi berlapis:
1. **Cron GitHub Actions harian** memanggil Edge Function `keep-alive` yang melakukan satu query ringan. Gratis, sepuluh menit menyiapkannya

```yaml
# .github/workflows/keep-alive.yml
name: keep-alive
on:
  schedule:
    - cron: '0 2 * * *'
  workflow_dispatch:
jobs:
  ping:
    runs-on: ubuntu-latest
    steps:
      - run: curl -fsS -X POST "$SUPABASE_URL/functions/v1/keep-alive" \
               -H "Authorization: Bearer $SUPABASE_ANON_KEY"
        env:
          SUPABASE_URL: ${{ secrets.SUPABASE_URL }}
          SUPABASE_ANON_KEY: ${{ secrets.SUPABASE_ANON_KEY }}
```

2. **Pertimbangkan Pro selama bulan penjurian.** Upgrade menghapus pause sepenuhnya. Kalau anggaran memungkinkan, ini menghapus seluruh kelas risiko ini dengan satu langkah, dan Anda bisa turun lagi setelah pengumuman
3. Cek dashboard setiap beberapa hari selama 2–11 September

**Kuota API model habis.** Pantau penggunaan harian. Siapkan kunci cadangan pada penyedia kedua. Rantai fallback Gemini → Groq → mode terbatas sudah menangani kasus terburuk, tapi Anda tetap ingin jawaban berkualitas penuh saat juri mencoba.

**Data demo terlihat basi.** Seed memakai tanggal relatif. Jalankan ulang seed lewat cron mingguan selama masa penjurian.

**Tautan mati.** Rulebook menegaskan tautan yang tidak bisa diakses panitia adalah di luar tanggung jawab panitia. Uji setiap tautan dari **jendela penyamaran dan jaringan berbeda**, bukan dari browser Anda yang sudah masuk akun Google.

---

## 4. README repositori

GitHub adalah artefak yang dinilai. README yang baik menaikkan kesan Implementasi dan Cara Penggunaan sekaligus.

Wajib memuat:
- Nama produk, satu paragraf deskripsi, sub-tema kompetisi, nama tim dan anggota
- Tiga sampai lima tangkapan layar
- Diagram arsitektur empat lapis
- **Kredensial akun demo ketiga peran**
- Cara menjalankan dari nol: prasyarat, `.env.example`, migrasi, seed, run
- Cakupan fitur: tabel 16 KF dengan status
- Hasil evaluasi: angka keamanan, keterlacakan, SUS
- Batasan yang diketahui, ditulis jujur
- Lisensi aset: Lexend Deca dan IBM Plex Mono (SIL OFL 1.1), Material Symbols (Apache 2.0), diagram dan rancangan antarmuka karya tim

Menulis batasan secara jujur menaikkan kredibilitas, bukan menurunkannya. Juri berpengalaman langsung mengenali README yang menyembunyikan sesuatu.

---

## 5. Bundel submission

**Nama berkas ZIP:** `ITC2026_2_SOFTDEV_Fable5Enjoyer_DekapAutis.zip`
**Ukuran maksimum:** 5 MB — mudah dipenuhi karena isinya hanya tiga berkas teks
**Batas waktu:** 1 September 2026 pukul 23.59 WIB

Isi:

**`ITC2026_SOFTDEV_ImplementasiAplikasi_Fable5Enjoyer.txt`**
```
DekapAutis — Implementasi Aplikasi
Tim Fable 5 Enjoyer — Institut Teknologi Sepuluh Nopember

APK (Google Drive) : <tautan>
Repositori GitHub  : <tautan>
Coba tanpa pasang  : <tautan web>

Akun demo
  Pengasuh     : demo@dekapautis.id / DemoDekap2026
  Profesional  : demo.profesional@dekapautis.id / DemoDekap2026
  Administrator: demo.admin@dekapautis.id / DemoDekap2026

Atau tekan "Masuk sebagai demo" pada layar masuk.
Minimum: Android 8.0, RAM 3 GB.
```

**`ITC2026_SOFTDEV_Video_Fable5Enjoyer.txt`** — tautan YouTube
**`ITC2026_SOFTDEV_Poster_Fable5Enjoyer.txt`** — tautan unggahan Instagram

Rulebook meminta tautan hasil karya **dan** tautan GitHub atau Google Drive. Cantumkan ketiganya dalam satu berkas — memberi lebih dari yang diminta tidak merugikan, sedangkan kurang bisa dianggap tidak memenuhi.

---

## 6. Yang berjalan paralel dengan pengembangan

Dua deliverable lain berbagi tenggat yang sama.

**Poster** — A3, minimal 300 ppi, JPG/PNG. Logo ITS, HIMASIF, dan IT CONVERT 2026 di **kiri atas**. Wajib memuat judul, nama tim, logo, manfaat, tujuan, dan fitur aplikasi dalam bentuk mockup. Diunggah ke Instagram salah satu anggota, menandai `@itconvert_unej` dan anggota lain, tagar `#ITC2026 #SOFTDEV`, caption berisi deskripsi produk. Jangan diarsipkan atau dihapus selama masa penilaian, dan jangan pernah memakai bot likes — sanksinya diskualifikasi dari nominasi poster favorit.

**Video** — 3–7 menit, minimal 720p, hak akses **Unlisted**, wajib memakai bumper panitia. Judul `IT CONVERT 2026 - SOFTDEV - Fable 5 Enjoyer - DekapAutis`. Tag `#ITC2026 #SOFTDEV_ITC2026`.

Perhatikan bobot video: Gambaran Umum Produk 35% meminta **gambaran proses perancangan** dan demonstrasi hasil, bukan hanya rekaman layar. Sisipkan diagram arsitektur, alur RAG, dan mesin adaptasi. Kesesuaian dengan proposal berbobot 25% — pastikan istilah, nama fitur, dan angka yang Anda sebut cocok dengan yang tertulis di proposal.

Alur demo yang saya sarankan untuk video, mengikuti Bab IX proposal supaya kesesuaiannya terlihat: onboarding profil Bima → beranda dengan check-in → buka aktivitas dan catat respons → tanya asisten dan buka panel sumber → **picu pemberitahuan batas aman** → tampilkan rencana yang sudah disesuaikan beserta alasannya → buat laporan dan bagikan → tampilkan sisi profesional menerima dan menanggapi.

Pemberitahuan batas aman adalah momen paling kuat dalam demo Anda. Aplikasi kesehatan berbasis AI yang **menolak menjawab** dan mengarahkan ke tenaga profesional menunjukkan kematangan yang jarang terlihat di kompetisi mahasiswa. Beri waktu di layar, jangan lewati cepat.

---

## 7. Daftar periksa terakhir

- [ ] Biaya Rp40.001 sudah ditransfer **dan sudah dikonfirmasi panitia** — akses unggah baru terbuka setelahnya
- [ ] APK terpasang dan berjalan pada perangkat bersih
- [ ] Ketiga akun demo bisa masuk
- [ ] Data demo memakai tanggal relatif, tidak terlihat basi
- [ ] `eval_safety.py` dan `eval_groundedness.py` dijalankan ulang pada konfigurasi produksi
- [ ] Uji RLS lulus kelima pemeriksaan
- [ ] Grep APK untuk kunci API: nihil
- [ ] Cron keep-alive aktif dan sudah berhasil sekali
- [ ] Seluruh tautan diuji dari jendela penyamaran
- [ ] README lengkap dengan kredensial demo
- [ ] Nama berkas persis sesuai format rulebook — periksa huruf demi huruf
- [ ] ZIP di bawah 5 MB
- [ ] Diunggah sebelum 1 September 23.59 WIB, bukan pada menit terakhir
