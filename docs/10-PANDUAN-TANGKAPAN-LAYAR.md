# 10 — Panduan Tangkapan Layar untuk Poster dan Video

Dari mengunduh APK sampai punya semua berkas yang dibutuhkan poster.
Perkiraan waktu: **20 menit**.

Yang dihasilkan di akhir: **empat tangkapan layar wajib** untuk poster, plus
tiga tambahan yang berguna untuk video.

---

## Bagian 1 — Pasang APK di ponsel (5 menit)

### 1.1 Unduh

Buka salah satu di ponsel Android:

- Google Drive: https://drive.google.com/file/d/1HL3snBeFZ93py99Gv_GmH6Erk4i2KRpL/view
- Cadangan: https://github.com/dzakyahnaf/DekapAutis/releases/download/v1.0.0/DekapAutis-v1.0.0.apk

Drive akan menampilkan **"Google Drive tidak dapat memindai file ini dari
virus"** — itu normal untuk berkas 67,6 MB, bukan tanda masalah. Tekan
**Download anyway / Tetap unduh**.

> **Pastikan Anda memasang versi yang benar.** Berkas yang sah berukuran
> **70.908.969 bita (67,6 MB)**. Kalau yang terunduh 70.794.281 bita, itu
> versi lama yang menggantung di layar "Menyiapkan rencana hari ini…" setelah
> menekan "Masuk sebagai demo". Copot pemasangannya dan unduh ulang.
> Kalau ragu, pakai tautan GitHub Release — di sana sudah pasti versi terbaru.

### 1.2 Izinkan pemasangan

Android akan menolak sekali. Buka tautan yang muncul, atau:
**Setelan → Aplikasi → Akses khusus → Pasang aplikasi tak dikenal →**
pilih Chrome atau Files → aktifkan.

Lalu tekan berkasnya lagi → **Pasang**.

### 1.3 Periksa cepat

Buka DekapAutis. Anda harus melihat layar pembuka lalu **layar Masuk** dalam
beberapa detik. Layar pembuka sekarang selalu berpindah: kalau peladen tidak
menjawab, aplikasi tetap mendarat di beranda dengan data tersimpan, bukan
menggantung. Kalau berhenti di layar putih, periksa koneksi internet.

---

## Bagian 2 — Siapkan ponsel supaya tangkapan layarnya bersih (5 menit)

Ini yang membedakan tangkapan layar yang terlihat rapi di poster dari yang
terlihat asal ambil. Lakukan **sebelum** membuka aplikasi.

| Langkah | Alasan |
|---|---|
| **Mode pesawat MATI**, WiFi menyala penuh | Bilah status memperlihatkan sinyal penuh, bukan tanda seru |
| **Baterai di atas 80%**, cabut pengisi daya | Ikon baterai penuh terbaca lebih baik daripada 14% merah |
| **Jangan Ganggu / Do Not Disturb NYALA** | Tidak ada notifikasi masuk di tengah pengambilan |
| **Ukuran teks sistem: Bawaan** | Setelan → Layar → Ukuran font → posisi tengah |
| **Mode gelap MATI** | Aplikasi ini terang; mode gelap sistem bisa mengubah bilah status |
| **Rotasi otomatis MATI**, tegak | — |

Jangan mengubah apa pun di dalam aplikasi. **Mode Tenang harus tetap MATI** —
kalau menyala, warna kategori meredup dan poster kehilangan warnanya.

**Bilah status dibiarkan apa adanya.** Jangan menggambar bingkai ponsel palsu
di poster nanti — chrome yang digambar ulang adalah tanda paling khas desain
buatan mesin. Bilah status sungguhan justru membuktikan ini aplikasi nyata.

---

## Bagian 3 — Masuk dan lewati tur (2 menit)

1. Di layar Masuk, gulir ke bawah. Ada pita krem berisi keterangan akun demo,
   lalu tombol **"Masuk sebagai demo"**. Tekan itu.
2. Aplikasi masuk sebagai **Rina Kartika**, pengasuh Bima.
3. **Tur pertama kali** akan muncul menutupi beranda — empat sorotan.
   → Kalau ingin tangkapan layar tur untuk video, ambil **sekarang** (opsional
     ke-7 di bawah).
   → Lalu tekan **"Lewati"**.

Tur hanya muncul sekali. Kalau ingin mengulangnya: **Profil → Cara pakai →
"Ulangi tur pertama kali"**.

---

## Bagian 4 — Empat tangkapan layar WAJIB untuk poster

Ambil dengan **tombol Daya + Volume Bawah** bersamaan.

### ① Beranda — simpul 3 pada diagram lingkaran

Ini layar yang muncul setelah tur dilewati.

**Yang harus terlihat:** sapaan dan tanggal hari ini, kartu check-in pengasuh,
judul "Rencana hari ini", dan minimal dua kartu aktivitas dengan tiga tombol
respons **Mudah · Pas · Sulit**.

- Gulir ke **paling atas** sebelum mengambil.
- Kalau daftar aktivitas kosong, tarik ke bawah untuk menyegarkan.

Simpan sebagai `01-beranda.png`.

### ② Rencana Mingguan — simpul 2 dan 4

Tekan tab **Rencana** di bilah bawah.

**Yang harus terlihat:** pemilih hari, dan — ini bagian terpentingnya — kartu
**"Mengapa rencana ini berubah"** berisi alasan penyesuaian yang menyebut
angka nyata, dengan tombol **"Saya koreksi sendiri"**.

- Gulir sampai kartu penjelasan itu terlihat penuh. **Itu buktinya mesin
  adaptasi bekerja dan bukan kotak hitam** — jangan sampai terpotong.
- Kalau kartunya belum ada, tekan **"Susun rencana"** dulu, tunggu selesai,
  lalu gulir lagi.

Simpan sebagai `02-rencana.png`.

### ③ Tanya Dekap — simpul yang disuplai pipeline AI

Tekan tab **Tanya**.

Ketik persis:

```
Bagaimana cara membangun rutinitas pagi yang bisa diprediksi?
```

**Yang harus terlihat:** jawaban dengan **keping sumber bernomor** yang dapat
ditekan. Sumbernya dokumen Kementerian Kesehatan sungguhan.

Karena kunci API model belum dipasang, jawabannya muncul sebagai **"mode
terbatas"** — kutipan sumber ditampilkan apa adanya. **Itu benar dan jujur**,
dan justru memperlihatkan bahwa sumbernya nyata. Jangan menunggu jawaban
naratif yang tidak akan datang.

Simpan sebagai `03-tanya.png`.

### ④ Laporan Perkembangan — simpul 5

**Profil → Laporan perkembangan.**

**Yang harus terlihat:** metrik (terjadwal, tercatat, rata-rata sesi), grafik
tren, dan rincian per kategori. Kategori **Sosial** akan bertanda perhatian —
itu memang dirancang begitu supaya penanda otomatisnya terlihat.

- Gulir sampai grafik tren dan tabel kategori terlihat bersama dalam satu
  layar kalau memungkinkan.

Simpan sebagai `04-laporan.png`.

---

## Bagian 5 — Tiga tambahan (berguna untuk video, opsional untuk poster)

### ⑤ Pemberitahuan batas aman — ini pembeda produknya

Di tab **Tanya**, ketik:

```
Berapa dosis melatonin yang aman untuk anak saya?
```

Aplikasi akan menolak menjawab dan menampilkan pemberitahuan batas aman
beserta daftar hal yang bisa dibantu. **Untuk video, ini adegan paling kuat
yang Anda punya** — dan bukti bahwa batas medisnya mekanisme teknis, bukan
kalimat penyangkalan.

Simpan sebagai `05-batas-aman.png`.

### ⑥ Direktori profesional

**Jelajah → Profesional.** Ketik `Surabaya` di kolom kota. Kartu akan
menampilkan jarak dalam kilometer — dihitung Haversine di perangkat, tanpa
SDK peta.

Simpan sebagai `06-direktori.png`.

### ⑦ Tur pertama kali

Kalau terlewat: **Profil → Cara pakai → "Ulangi tur pertama kali"**, lalu
beranda akan menampilkan turnya lagi.

Simpan sebagai `07-tur.png`.

---

## Bagian 6 — Pindahkan dan periksa

1. Sambungkan ponsel ke laptop, atau kirim lewat Google Drive / WhatsApp
   **sebagai dokumen** (jangan sebagai foto — WhatsApp akan mengompresinya
   dan teksnya menjadi buram).
2. Taruh di `dekapautis/docs/tangkapan-layar/`.
3. Periksa masing-masing:

- [ ] Lebar minimal **1080 px**. Kalau di bawah itu, teks akan pecah saat
      dicetak A3.
- [ ] Tidak ada notifikasi di bilah status
- [ ] Baterai tidak merah, sinyal tidak kosong
- [ ] Tidak ada nama atau nomor pribadi yang terlihat
- [ ] Keping **"Akun demo — data sintetis"** terlihat di layar Profil kalau
      Anda mengambilnya

---

## Bagian 7 — Menempelkannya ke poster

Ikuti `docs/09-POSTER-BRIEF.md`. Ringkasnya:

- Empat tangkapan layar menempel **langsung pada simpul diagram lingkaran**,
  bukan berbaris terpisah di bawahnya. Itu yang membuat mockup melayani
  diagram alih-alih bersaing dengannya.
- Tempel **apa adanya**: sudut membulat, garis rambut 1 px `#D8C6E0`.
  **Jangan menggambar bingkai ponsel, notch, atau speaker.**
- Ukuran di poster sekitar 60–90 mm lebar. Tangkapan 1080 px pada 90 mm
  menghasilkan sekitar 305 ppi — tepat memenuhi syarat 300 ppi.

Pemetaannya:

| Tangkapan | Menempel pada |
|---|---|
| `02-rencana.png` | Simpul 2 — Rencana mingguan |
| `01-beranda.png` | Simpul 3 — Jalankan & catat respons |
| `04-laporan.png` | Simpul 5 — Bagikan laporan |
| `03-tanya.png` | Simpul Tanya Dekap, tempat pipeline masuk |

---

## Kalau ada yang tidak beres

| Gejala | Sebab dan tindakan |
|---|---|
| Layar putih setelah splash | Tidak ada internet. Aplikasi menghubungi peladen saat pertama dibuka |
| Menggantung di "Menyiapkan rencana hari ini…" | Versi lama. Periksa ukuran berkas di 1.1 dan pasang ulang yang 70.908.969 bita |
| "Masuk sebagai demo" gagal | Beri tahu saya — akun demo baru diperbaiki hari ini dan sudah diuji berhasil untuk ketiga peran |
| Beranda kosong, tidak ada aktivitas | Tarik ke bawah untuk menyegarkan. Data demo empat minggu selalu berakhir hari ini |
| Tanya Dekap menjawab "mode terbatas" | **Benar**, bukan galat. Kunci API model belum dipasang; sumbernya tetap nyata |
| Kartu "Mengapa rencana ini berubah" tidak ada | Tekan "Susun rencana" dulu, lalu gulir |
| Tur tidak muncul | Sudah pernah dilewati. Profil → Cara pakai → "Ulangi tur pertama kali" |
