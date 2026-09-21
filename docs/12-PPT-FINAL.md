# 12 — PPT dan Presentasi Final

Kerangka slide, naskah demo, dan bank pertanyaan untuk Final IT CONVERT 2026
Software Development. Sabtu, 26 September 2026, Zoom.

Sumber: *Rulebook Final Softdev IT Convert 2026*, dan jawaban narahubung
tanggal 22 September 2026.

---

## Bagian 0 — Yang rulebook wajibkan

### Berkas yang dikumpulkan

Yang diunggah ke dashboard **bukan PPT-nya**. Yang diunggah adalah berkas teks
berisi tautan Drive. Ini butir yang paling mudah salah.

| Butir | Nilai |
|---|---|
| Nama berkas | `ITC2026_1_SOFTDEV_PPT_Fable 5 Enjoyer_DekapAutis.txt` |
| Ekstensi | **TXT** |
| Isi | **satu tautan Google Drive ke PPT** |
| Ukuran maksimal | 5 MB |
| Batas waktu | **24 September 2026, 23.59 WIB** |
| Dikirim lewat | dashboard tim finalis |

Angka `1` pada nama berkas dikonfirmasi narahubung pada 22 September 2026,
bersama tenggat 24 September. Rulebook tahap sebelumnya memakai pola berbeda;
yang berlaku adalah yang dikonfirmasi ini.

### Isi PPT yang diwajibkan

1. **Nama seluruh anggota tim** harus tampil.
2. Menjelaskan **latar belakang, tujuan, manfaat, keunggulan, fitur aplikasi
   secara detail, dan kesimpulan**.
3. **Tiga logo di kiri atas**: logo universitas (ITS), logo HIMASIF, dan logo
   IT CONVERT 2026. Dua logo terakhir diunduh di
   <https://himasif.id/LogoITC2026>.
4. Desain bebas, tidak mengandung SARA.
5. Gambar harus tajam dan terbaca — akan dilihat lewat *share screen* Zoom,
   yang menurunkan kualitas. Hindari tangkapan layar kecil dan teks di bawah
   20 pt.
6. PPT diunggah ke Drive pribadi dan **hak aksesnya publik**. Periksa dengan
   membuka tautannya di jendela penyamaran.

### Bobot penilaian

| Kriteria | Bobot |
|---|---|
| **Tanya Jawab** | **40%** |
| Presentasi | 30% |
| Prototyping | 30% |

Tanya jawab adalah komponen terbesar, dan satu-satunya yang tidak bisa
disiapkan dalam bentuk slide. Bagian 3 di bawah ada karena itu.

### Waktu

25 menit per tim: **presentasi 10 menit**, **tanya jawab 15 menit** (5 menit
per juri, tiga juri). Time keeper mengingatkan sisa 5 menit, 2 menit, dan
habis. Sesi yang melewati batas berhak dihentikan panitia.

Rundown: finalis 1 presentasi 09.20, finalis 2 09.50, finalis 3 10.20,
finalis 4 10.50, finalis 5 11.20. Urutan ditentukan saat Technical Meeting.

---

## Bagian 1 — Kerangka slide

Delapan slide untuk sepuluh menit, dengan demo langsung di tengahnya. Bukan
sebelas slide: pada 10 menit, tiap slide tambahan memotong waktu demo, dan
demo itulah komponen Prototyping 30%.

Kolom "Pembicara" membagi peran secara sengaja. Rulebook menganjurkan seluruh
anggota tampil, dan keaktifan anggota terlihat oleh juri.

| # | Slide | Waktu | Pembicara |
|---|---|---|---|
| 1 | Judul dan tim | 0.00–0.30 | Dzaky |
| 2 | Latar belakang | 0.30–1.45 | Diffa |
| 3 | Tujuan dan manfaat | 1.45–2.30 | Diffa |
| 4 | Cara kerja sistem | 2.30–3.30 | Dzaky |
| 5 | Keunggulan | 3.30–4.30 | Dzaky |
| — | **Demo langsung** | 4.30–8.00 | Diffa menjalankan, Dzaky menarasikan |
| 6 | Peta fitur lengkap | 8.00–9.00 | Diffa |
| 7 | Kesimpulan | 9.00–9.40 | Dzaky |
| 8 | Penutup | 9.40–10.00 | berdua |

### Slide 1 — Judul dan tim

- Tiga logo di kiri atas (berlaku untuk **semua** slide, bukan hanya ini).
- **DekapAutis** — Pendamping keluarga anak dengan spektrum autisme.
- Tim **Fable 5 Enjoyer**, Institut Teknologi Sepuluh Nopember:
  - Muhammad Dzaky Ahnaf (5027231039) — backend dan AI
  - Diffa Adzra Anelya (5051231021) — antarmuka dan klien Flutter
- Sub-tema: AI in Health and Well-being.

### Slide 2 — Latar belakang

Satu kalimat masalah, lalu bukti. Jangan menumpuk statistik.

- Terapi berlangsung satu sampai dua jam seminggu. **Sisa 166 jam ada di
  rumah**, dan di situlah orang tua berdiri sendirian.
- Yang dicari orang tua di antara dua jadwal terapi: apa yang harus dilakukan
  hari ini, apakah yang kemarin berhasil, dan apa yang perlu diceritakan ke
  terapis nanti.
- Yang tersedia sekarang: grup pesan, pencarian daring, dan ingatan.
- Gambar: satu foto atau ilustrasi tenang. Bukan grafik batang.

> Catatan: pakai angka yang ada di proposal final. Jangan menambah statistik
> baru yang tidak punya sumber — juri boleh menanyakan sumbernya.

### Slide 3 — Tujuan dan manfaat

Dua kolom, jangan paragraf.

**Tujuan**
- Memberi orang tua rencana stimulasi harian yang bisa dijalankan di rumah.
- Mengubah catatan harian menjadi penyesuaian rencana, bukan sekadar arsip.
- Menyiapkan bahan yang berguna untuk tenaga profesional.

**Manfaat**
- Orang tua: tahu apa yang dikerjakan hari ini, dan alasannya.
- Anak: rutinitas yang dapat diprediksi, disesuaikan dengan sensitivitasnya.
- Tenaga profesional: laporan ringkas berbasis catatan nyata, bukan ingatan.

### Slide 4 — Cara kerja sistem

Satu diagram, empat kotak. Jangan menampilkan daftar dependensi.

```
Flutter (Android)  →  Supabase Edge Function  →  Gemini → Groq (cadangan)
       ↓                        ↓
  Drift/SQLite            Postgres + pgvector
  terenkripsi             RLS tolak-bawaan
```

Tiga kalimat yang harus terucap:

1. **Kunci model bahasa tidak pernah ada di ponsel.** Semua panggilan lewat
   Edge Function; APK-nya sudah kami pindai untuk memastikan.
2. **Jawaban disusun dari dokumen**, bukan dari ingatan model: pencarian
   vektor pgvector mengambil potongan dokumen, model merangkainya, dan setiap
   kalimat membawa rujukan yang bisa dibuka.
3. **Gemini gagal, Groq menggantikan otomatis.** Kalau keduanya gagal,
   aplikasi menjawab dari pencarian teks penuh dan menandai dirinya mode
   terbatas — tidak pernah layar kosong.

### Slide 5 — Keunggulan

Empat pembeda. Ini slide yang paling menentukan, dan tiap butirnya harus bisa
ditunjukkan di demo atau dipertanggungjawabkan saat tanya jawab.

1. **Batas medis ditegakkan tiga lapis, bukan kalimat penyangkalan.**
   Tidak mendiagnosis, tidak menilai tingkat spektrum, tidak menganjurkan obat
   atau dosis. Pertanyaan yang menyentuh batas itu ditolak dan dialihkan ke
   tenaga profesional.
2. **Rencana yang berubah dengan alasan berangka.**
   Bukan "AI menyesuaikan". Aplikasi menulis: *"Capaian komunikasi 83% minggu
   ini dari 6 catatan. Tingkat aktivitas komunikasi naik dari 2 ke 3."* —
   lengkap dengan tombol "Saya koreksi sendiri".
3. **Jalan tanpa jaringan.**
   Catatan masuk antrean di perangkat, cache terenkripsi di Keystore, dan
   layar tetap menjelaskan keadaannya alih-alih kosong.
4. **Privasi yang ditegakkan basis data, bukan tampilan.**
   Aturan akses menolak semua permintaan secara bawaan. Izin berbagi laporan
   diberikan per laporan dan dapat dicabut; pencabutan memutus akses di sisi
   peladen. Anonim di komunitas disembunyikan di peladen — kolom namanya tidak
   pernah dikirim ke aplikasi.

### Slide 6 — Peta fitur lengkap

Demo tidak akan sempat menampilkan semuanya, jadi slide ini yang menutupi
tuntutan rulebook "fitur aplikasi secara detail". Satu halaman, ikon + label,
kelompokkan:

- **Rencana**: katalog aktivitas, jadwal mingguan, panduan langkah, catatan
  respons Mudah/Pas/Sulit, mesin adaptasi.
- **Tanya Dekap**: tanya jawab berbasis 31 dokumen sumber, rujukan yang bisa
  dibuka, penapis batas medis.
- **Laporan**: ringkasan periode, grafik, ekspor PDF, izin berbagi per laporan.
- **Direktori**: 16 profesional terverifikasi, jarak, pengajuan jadwal.
- **Pustaka**: 31 dokumen, kategori, penanda "Ditinjau profesional".
- **Komunitas**: topik, anonim di sisi peladen, moderasi.
- **Pengasuh**: check-in harian, Mode Tenang, aksesibilitas, luring.

> Angka 31 dan 16 dihitung dari basis data, bukan ditulis tangan. Poster dan
> video tahap 2 juga menyebut 31 — biarkan tetap 31 dan jelaskan sebagai
> kurasi kalau ditanya.

### Slide 7 — Kesimpulan

Tiga kalimat, tidak lebih.

- DekapAutis mengisi jam-jam di rumah di antara dua jadwal terapi, dengan
  rencana yang bisa dijalankan dan alasan yang bisa diperiksa.
- Yang tidak dilakukannya — mendiagnosis, menilai tingkat, menganjurkan obat —
  adalah keputusan desain yang ditegakkan secara teknis.
- Purwarupa berjalan penuh: Android, dengan backend dan basis pengetahuan yang
  aktif hari ini.

### Slide 8 — Penutup

- "Terima kasih" + nama tim + nama kedua anggota lagi.
- Kontak dan tautan repositori.
- Biarkan slide ini terbuka selama tanya jawab.

### Slide cadangan (tidak dipresentasikan)

Taruh setelah slide 8. Gunanya untuk melompat saat juri bertanya — jauh lebih
meyakinkan daripada menjawab lisan saja.

| Slide | Isi |
|---|---|
| C1 | Diagram pipeline AI lengkap: potong dokumen → embedding → pgvector HNSW → penapis batas → rangkai jawaban |
| C2 | Tiga lapis batas medis, dan contoh pertanyaan yang ditolak |
| C3 | Skema basis data dan contoh aturan RLS |
| C4 | Hasil pengujian: jumlah tes otomatis, evaluasi batas aman, keterlacakan jawaban |
| C5 | Rencana pengembangan setelah lomba |

---

## Bagian 2 — Naskah demo langsung (3,5 menit)

Prototyping bernilai 30%. Demo ini yang dinilai, jadi urutannya dipilih
berdasarkan apa yang paling membedakan DekapAutis, bukan berdasarkan urutan
menu.

**Sebelum masuk breakout room:** aplikasi sudah terbuka di layar Masuk,
sudah dalam keadaan masuk sebagai demo sekali sebelumnya supaya pemandu empat
langkah tidak muncul di tengah demo.

| Waktu | Yang ditekan | Yang dikatakan |
|---|---|---|
| 0.00–0.20 | "Masuk sebagai demo" | "Akun demo berisi data sintetis. Rina dan Bima persona contoh, dan aplikasi menandainya begitu di dalam antarmuka." |
| 0.20–0.50 | Beranda → tandai satu aktivitas **Mudah** | "Rencana hari ini. Orang tua menandai hasilnya dengan tiga pilihan, bukan mengisi formulir." |
| 0.50–1.35 | Tab **Rencana** → "Mengapa rencana ini berubah" | **Bacakan kartunya apa adanya.** "Ini alasan yang ditulis aplikasi sendiri, dengan angka dari catatan minggu ini — dan orang tua bisa menolaknya lewat 'Saya koreksi sendiri'." |
| 1.35–2.20 | Tab **Tanya** → ketik pertanyaan rutinitas | "Jawabannya membawa rujukan bernomor." Tekan salah satu keping sumber, tunjukkan dokumennya. |
| 2.20–3.05 | **Tanya** → "Obat apa untuk menyembuhkan autisme anak saya?" | "Ini yang paling penting. Aplikasi menolak, menjelaskan alasannya, lalu menawarkan yang bisa dibantu — dan tombol menuju profesional terdekat." |
| 3.05–3.30 | **Profil → Laporan → Izin berbagi** | "Laporan untuk dibawa ke terapis, dan izinnya diberikan per laporan serta bisa dicabut kapan saja." |

Kalau waktu tersisa, satu tambahan bernilai tinggi: nyalakan mode pesawat,
buka ulang, tunjukkan aplikasi tetap menjelaskan keadaannya.

**Aturan demo:** jangan mengetik panjang di depan juri. Siapkan pertanyaan
yang pendek. Kalau satu langkah gagal, lanjut ke langkah berikutnya dan
katakan apa yang seharusnya terjadi — jangan mengulang-ulang.

---

## Bagian 3 — Bank pertanyaan juri

Tanya jawab 40%. Tiga juri, lima menit masing-masing, jadi perkirakan enam
sampai sepuluh pertanyaan. Bagi peran di depan supaya tidak ada jeda canggung,
dan supaya keduanya terlihat aktif.

### Untuk Dzaky — teknis, AI, keamanan

| Pertanyaan | Inti jawaban |
|---|---|
| Bagaimana memastikan jawaban AI tidak mengarang? | Jawaban disusun dari potongan dokumen yang diambil pencarian vektor; tiap kalimat membawa rujukan yang bisa dibuka pengguna. Kalau tidak ada dokumen yang relevan, aplikasi mengatakannya. |
| Bagaimana kalau model menyarankan hal medis? | Tiga lapis: penapis sebelum pertanyaan dikirim, instruksi batas pada model, dan pemeriksaan jawaban sebelum ditampilkan. Ditolak, dijelaskan, dialihkan ke profesional. |
| Kunci API disimpan di mana? | Hanya sebagai secret Edge Function. Tidak pernah di APK — kami pindai isi APK untuk membuktikannya. |
| Bagaimana data satu pengguna tidak terbaca pengguna lain? | Row Level Security di Postgres, menolak secara bawaan, lalu hanya mengizinkan baris milik akun yang meminta. Ditegakkan basis data, bukan tampilan. |
| Bagaimana mesin adaptasinya bekerja? | Menghitung capaian per kategori dari catatan respons pada periode berjalan, lalu menaikkan atau menurunkan tingkat aktivitas dan porsi sesi. Alasannya ditulis dengan angkanya, dan bisa dikoreksi pengguna. |
| Kenapa Gemini dan Groq sekaligus? | Cadangan otomatis. Kuota habis atau layanan terganggu tidak boleh menjatuhkan fitur saat dinilai. |
| Apa yang terjadi tanpa internet? | Rencana dan katalog dibaca dari cache terenkripsi di perangkat, catatan masuk antrean, dan layar menjelaskan keadaannya alih-alih kosong. |
| Bagaimana pengujiannya? | Uji otomatis untuk mesin adaptasi, penapis batas medis, aksesibilitas, penskalaan teks 200%, dan perilaku saat peladen menolak di seluruh rute. |

### Untuk Diffa — desain, aksesibilitas, pengguna

| Pertanyaan | Inti jawaban |
|---|---|
| Kenapa tidak ada animasi? | Pola bergerak berulang adalah pemicu beban sensorik. Loading memakai teks statis, transisi maksimal 200 ms dan menjadi nol saat Mode Tenang. |
| Apa itu Mode Tenang? | Satu saklar yang menurunkan kontras berlebih, menghentikan transisi, dan menyederhanakan tampilan — untuk dipakai saat anak atau pengasuhnya sedang kewalahan. |
| Bagaimana aksesibilitasnya? | Target sentuh minimal 48 dp, kontras memenuhi WCAG 2.2 AA, setiap ikon bermakna punya label, dan tata letak diuji otomatis pada penskalaan teks 200%. |
| Kenapa warnanya ungu dan krem saja? | Palet sempit dan berpigmen tenang, dipilih agar tidak ada warna berteriak. Status tidak pernah dibedakan hanya lewat warna — selalu ada ikon atau label. |
| Siapa penggunanya, dan kenapa sapaannya "Anda"? | Orang dewasa: orang tua, pengasuh, guru pendamping. Bukan "Bunda", karena penggunanya bukan hanya ibu. |
| Bagaimana pengguna baru tahu cara memakainya? | Onboarding profil anak empat langkah, lalu pemandu empat sorotan di beranda, dan halaman "Cara pakai" yang bisa dibuka kapan saja. |
| Bagaimana menjaga komunitas tetap aman? | Moderasi, larangan nasihat medis, pelaporan penyalahgunaan, dan anonim yang disembunyikan di sisi peladen. |

### Pertanyaan sulit — siapkan jujur

| Pertanyaan | Sikap |
|---|---|
| Sudah diuji ke pengguna nyata? | Katakan apa adanya: status pengujian, jumlah responden, dan rencananya. Jangan mengarang angka. |
| Basis pengetahuannya cuma 31 dokumen? | Kurasi, bukan keterbatasan: semuanya sumber nyata yang bisa dibuka, bukan dokumen yang dikarang. Lebih baik 31 yang dapat dipertanggungjawabkan daripada ratusan yang tidak. |
| Direktori profesionalnya nyata? | **Jangan mengaku nyata.** Data contoh dengan koordinat nyata agar perhitungan jarak masuk akal; tidak ada nama praktisi sungguhan yang dipakai tanpa izin. |
| Bedanya dengan aplikasi terapi lain? | Batas medis yang ditegakkan teknis, alasan adaptasi yang berangka dan bisa dikoreksi, dan jalan tanpa jaringan. |
| Bagaimana model bisa salah? | Akui bisa. Karena itu setiap jawaban membawa sumber, ada tombol koreksi pada adaptasi, dan aplikasi menyatakan dirinya bukan pengganti tenaga profesional. |

---

## Bagian 4 — Daftar periksa pengumpulan

Sebelum 24 September 23.59 WIB:

- [ ] Tiga logo terpasang di kiri atas **setiap** slide
- [ ] Nama kedua anggota tampil di slide judul
- [ ] Latar belakang, tujuan, manfaat, keunggulan, fitur detail, kesimpulan —
      semuanya ada
- [ ] PPT diunggah ke Drive, hak akses **publik**, diuji di jendela penyamaran
- [ ] Berkas `.txt` dibuat, isinya **hanya tautan Drive itu**
- [ ] Nama berkas: `ITC2026_1_SOFTDEV_PPT_Fable 5 Enjoyer_DekapAutis.txt`
- [ ] Diunggah lewat dashboard tim finalis
- [ ] Biaya Rp60.001 sudah dibayar dan dikonfirmasi panitia

Sebelum 26 September:

- [ ] Nama Zoom diubah: `Fable 5 Enjoyer` (satu perangkat) atau
      `Fable 5 Enjoyer_Nama` (lebih dari satu)
- [ ] Virtual background dari panitia dipasang
- [ ] Technical Meeting diikuti — urutan tampil ditentukan di sana
- [ ] Gladi 10 menit dengan stopwatch, demo langsung termasuk
- [ ] Mirroring ponsel ke Zoom diuji
- [ ] Cadangan siap: hotspot, dan video tahap 2 kalau demo gagal
