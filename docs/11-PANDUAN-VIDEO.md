# 11 — Panduan Video Produk

Naskah pengambilan gambar untuk video DekapAutis, IT CONVERT 2026 Software
Development. Berisi urutan rekaman, teks layar, dan narasi siap baca.

Perkiraan waktu: **rekam 45 menit, edit 2 jam.**

---

## Bagian 0 — Yang rulebook wajibkan

Dari *Ketentuan Video* dan tabel format YouTube.

| Butir | Nilai |
|---|---|
| Durasi | **minimal 3 menit, maksimal 7 menit** |
| Resolusi | minimal 720p (pakai 1080p) |
| Hak akses | **Unlisted** |
| Bumper panitia | **wajib**, unduh di https://himasif.id/BumperVideoITC2026 |
| Watermark | dari tautan yang sama, pasang di seluruh durasi |
| Audio | harus terdengar jelas |
| Judul | `IT CONVERT 2026 - SOFTDEV - Fable 5 Enjoyer - DekapAutis` |
| Tag | `#ITC2026` `#SOFTDEV_ITC2026` |
| Berkas kumpul | `ITC2026_SOFTDEV_Video_Fable5Enjoyer.txt` |

Wajib memuat, kata rulebook persis:

1. **Penjelasan singkat (ide inovasi)**
2. **Tata urutan detail penggunaan Mockup Interface**
3. Gambaran sistem bekerja dan berguna menyelesaikan masalah
4. Bagaimana perangkat lunak digunakan **oleh pengguna**
5. **Implementasi** perangkat lunak beserta **simulasi penggunaan**

Deskripsi YouTube, salin apa adanya:

```
IT CONVERT 2026

DekapAutis — pendamping berbasis kecerdasan artifisial untuk orang tua dan
pengasuh anak dengan spektrum autisme. Menyusun rencana stimulasi mingguan,
menyesuaikannya dari catatan yang ditulis pengasuh sendiri, menjawab dari
dokumen yang dapat dibuka, dan menjembatani laporan perkembangan ke tenaga
profesional — tanpa pernah mendiagnosis atau menganjurkan obat.

Fable 5 Enjoyer
Institut Teknologi Sepuluh Nopember

Ketua    : Muhammad Dzaky Ahnaf (5027231039)
Anggota 1: Diffa Adzra Anelya (5051231021)

#ITC2026 #SOFTDEV_ITC2026
```

---

## Bagian 1 — Bobot penilaian menentukan pembagian durasi

| Kriteria | Bobot | Detik dari 6 menit |
|---|---|---|
| **Gambaran Umum Produk** — proses perancangan · demonstrasi hasil · penggunaan oleh pengguna | **35%** | ~145 |
| Kesesuaian Isi Video Dengan Proposal | 25% | ~90 |
| Penyampaian Konsep dan Ide | 25% | ~90 |
| Kreativitas dan Estetika — visualisasi · kelengkapan fitur | 15% | ~55 |

Dua hal yang paling sering hilang dari video peserta, dan keduanya bernilai:

- **"Gambaran Proses Perancangan Perangkat Lunak"** ada di dalam bobot 35%.
  Artinya video harus menunjukkan **bagaimana ini dibangun**, bukan hanya
  hasil jadinya. Adegan 3 mengurus itu.
- **"Kelengkapan Fitur"** ada di dalam 15%. Menampilkan enam layar saja
  membuang poin ketika aplikasi Anda punya 17. Adegan 6 mengurus itu.

---

## Bagian 2 — Persiapan sebelum merekam

### 2.1 Pasang APK yang benar

**Copot dulu DekapAutis lama**, lalu pasang `app-release.apk` yang baru
(70.908.969 bita). Versi sebelumnya menggantung di "Menyiapkan rencana hari
ini…" dan layar Laporan perkembangannya gagal — dua adegan terpenting Anda.

### 2.2 Setel ponsel

Sama seperti `docs/10-PANDUAN-TANGKAPAN-LAYAR.md` bagian 2, ditambah:

| Langkah | Alasan |
|---|---|
| **Jangan Ganggu NYALA** | Notifikasi masuk di tengah rekaman berarti ulang |
| **Perekam layar: 1080p, 60 fps** | Rulebook minta minimal 720p |
| **Rekam TANPA audio** | Narasi direkam terpisah. Mikrofon ponsel sambil menekan layar terdengar berisik |
| **Kecerahan layar penuh** | Rekaman layar redup terlihat kusam setelah kompresi YouTube |
| **Mode Tenang MATI** | Kecuali di adegan 6c yang memang menunjukkannya |

### 2.3 Segarkan data demo lebih dulu

Jalankan ini sebelum merekam supaya beranda pasti terisi hari itu:

```bash
curl -X POST "https://jeuabuvqpvcqitcqnvtx.supabase.co/functions/v1/keep-alive" \
  -H "apikey: sb_publishable_Se4xw7rRH7kiFCxiaByY-A_CtyA8sA6"
```

Balasan harus memuat `"aktivitas_hari_ini":5`.

### 2.4 Opsional tapi berdampak: hidupkan model bahasa

Tanpa kunci API, Tanya Dekap menjawab **"mode terbatas"** — kutipan sumber
ditampilkan apa adanya. Itu benar dan jujur, dan adegan 5 sudah ditulis untuk
menjelaskannya sebagai degradasi anggun yang dirancang.

Tapi kalau Anda punya kunci Gemini gratis, jawabannya menjadi naratif dan
adegan 5 jadi jauh lebih kuat:

```bash
supabase secrets set GEMINI_API_KEY=<kunci Anda>
```

Kalau tidak, **pakai narasi versi B** yang sudah disediakan di adegan 5a.
Jangan berpura-pura ada jawaban naratif yang tidak muncul.

### 2.5 Rekam per adegan, jangan satu tarikan

Setiap adegan di bawah adalah satu berkas rekaman terpisah. Salah satu ketukan
berarti mengulang 20 detik, bukan 6 menit.

---

## Bagian 3 — Naskah adegan

Kolom **Rekam** adalah yang Anda tangkap. **Teks layar** yang Anda ketik saat
mengedit. **Narasi** yang Anda bacakan.

Kecepatan baca acuan: **2,4 kata per detik**. Jumlah kata sudah dihitung.

---

### Adegan 0 — Bumper panitia · 0:00–0:08

**Rekam:** tidak ada. Tempel berkas bumper dari panitia apa adanya.

Jangan potong, jangan beri musik lain, jangan tumpuk teks. Ini syarat, bukan
bahan kreasi.

---

### Adegan 1 — Masalah · 0:08–0:52 · 44 detik

**Rekam:** tidak ada rekaman layar. Kartu tipografi bergerak di atas warna
kertas aplikasi `#F2E8F6`, huruf Lexend Deca tinta `#4A2657`.

> **Jangan pakai foto atau video stok anak.** Selain melanggar aturan desain
> proyek ini, rekaman anak yang dibeli untuk mengiba adalah hal yang persis
> tidak boleh dilakukan produk seperti ini.

**Teks layar** — satu kartu tiap kalimat, masing-masing tahan 3–4 detik:

```
Antrean terapi panjang.

Biaya sesi berulang.

Jarak ke tenaga profesional jauh.

Di antara dua jadwal terapi,
rumah menjadi tempat belajar utama.

Tanpa panduan.
Tanpa cara mengukur.
Tanpa siapa pun untuk bertanya
pukul sebelas malam.
```

**Narasi** (105 kata):

> Di Indonesia, orang tua dan pengasuh anak dengan spektrum autisme menghadapi
> tiga hal sekaligus: antrean terapi yang panjang, biaya sesi yang berulang,
> dan jarak ke tenaga profesional yang tidak selalu terjangkau.
>
> Tetapi masalah yang paling jarang dibicarakan bukan di ruang terapi. Masalah
> itu ada di antara dua jadwal. Di rumah, sepanjang minggu, tempat sebagian
> besar waktu anak sebenarnya dihabiskan.
>
> Di sana pengasuh bekerja sendirian. Tanpa panduan yang terstruktur, tanpa
> cara mengukur apakah yang dilakukannya berhasil, dan tanpa siapa pun untuk
> ditanya pukul sebelas malam ketika sesuatu terasa berbeda pada anaknya.

---

### Adegan 2 — Ide inovasi · 0:52–1:28 · 36 detik

Ini butir wajib rulebook 1a.

**Rekam:** diagram lingkaran dari poster, dianimasikan simpul demi simpul.
Ekspor tiap simpul sebagai PNG terpisah dari berkas poster, lalu munculkan
berurutan. Panah balik ungu muncul **terakhir** dan paling tebal.

**Teks layar:**

```
DekapAutis

1  Profil anak
2  Rencana mingguan
3  Jalankan & catat respons
4  Rencana menyesuaikan
5  Bagikan laporan
6  Tanggapan profesional

↺ tanggapan kembali mengubah rencana
```

**Narasi** (88 kata):

> DekapAutis adalah pendamping berbasis kecerdasan artifisial untuk mengisi
> ruang itu.
>
> Dan yang membedakannya bukan daftar fiturnya, melainkan bentuknya.
> Aplikasi ini bukan pencatat. Ia sebuah lingkaran yang menutup.
>
> Profil anak menghasilkan rencana mingguan. Pengasuh menjalankan dan mencatat
> responsnya. Catatan itu mengubah rencana minggu berikutnya. Rencana menjadi
> laporan. Laporan sampai ke tenaga profesional. Dan tanggapan profesional
> kembali mengubah rencana.
>
> Lingkaran itu adalah produknya.

---

### Adegan 3 — Proses perancangan dan implementasi · 1:28–2:14 · 46 detik

**Adegan ini yang paling sering dilewatkan peserta, dan ia ada di dalam bobot
35 persen.** Rulebook menyebutnya "Gambaran Proses Perancangan Perangkat
Lunak" dan "menjelaskan implementasi perangkat lunak".

**Rekam:** rekaman layar laptop, empat potongan berurutan, masing-masing
8–12 detik. Perbesar teksnya (Ctrl `+` di editor) supaya terbaca di ponsel.

| # | Rekam persis |
|---|---|
| 3a | Struktur folder repo di VS Code: `app/lib/`, `supabase/migrations/`, `docs/`. Gulir pelan |
| 3b | Buka `app/lib/core/theme/tokens.dart`, gulir bagian palet dan `DekapCategory` |
| 3c | Terminal: jalankan `flutter test`, biarkan sampai muncul `+357: All tests passed!` |
| 3d | Dashboard Supabase → Table Editor, lalu Edge Functions memperlihatkan kelimanya ACTIVE |

**Teks layar** — muncul menimpa rekaman, sudut kiri bawah:

```
3a   Flutter · Riverpod · Drift
3b   Sistem desain terkunci: dua keluarga warna, WCAG 2.2 AA
3c   357 test otomatis · 112 pemeriksaan basis data
3d   Supabase · PostgreSQL · pgvector · Edge Functions Deno
```

**Narasi** (110 kata):

> Sebelum melihat aplikasinya berjalan, ini cara ia dibangun.
>
> Klien memakai Flutter dengan Riverpod dan basis data lokal Drift, sehingga
> aplikasi tetap bekerja tanpa jaringan. Backend memakai Supabase: Postgres,
> autentikasi, dan Edge Function tempat seluruh kunci API disimpan — tidak
> satu pun kunci pernah menyentuh perangkat.
>
> Sistem desainnya dikunci sejak awal. Dua keluarga warna, tanpa animasi
> berulang, dan setiap pasangan warna diuji otomatis terhadap ambang kontras
> WCAG dua titik dua. Bila ada yang gagal, build-nya berhenti.
>
> Seluruhnya dijaga tiga ratus lima puluh tujuh test otomatis dan seratus dua
> belas pemeriksaan basis data yang dijalankan setiap kali kode berubah.

---

### Adegan 4 — Demonstrasi penggunaan · 2:14–4:52 · 158 detik

Inti video. Butir wajib rulebook 1b: **tata urutan detail penggunaan**.

Rekam layar ponsel. Ketuk pelan dan sengaja — lebih lambat dari kebiasaan
Anda. Beri jeda satu detik setelah setiap layar termuat sebelum ketukan
berikutnya.

---

#### 4a — Masuk · 2:14–2:36 · 22 detik

**Rekam:** buka aplikasi dari layar utama → layar pembuka → layar Masuk →
gulir ke bawah → ketuk **"Masuk sebagai demo"** → tur pertama kali muncul →
gulir keempat sorotan → ketuk **"Lewati"** → beranda.

**Teks layar:**

```
Akun demo — data sintetis, ditandai di dalam aplikasi
Tur pertama kali: empat sorotan, sekali saja
```

**Narasi** (52 kata):

> Kita masuk memakai akun demo. Datanya sintetis, dan aplikasi menandainya
> sebagai demo di layar profil — tidak ada anak sungguhan di dalam sini.
>
> Pengguna baru disambut tur singkat berisi empat sorotan. Tur ini hanya
> muncul sekali, dan dapat diulang kapan saja dari menu Cara pakai.

---

#### 4b — Beranda dan mencatat respons · 2:36–3:04 · 28 detik

**Rekam:** beranda dari paling atas. Perlihatkan sapaan dan tanggal, kartu
check-in pengasuh, lalu judul **"Rencana hari ini"**. Gulir pelan melewati dua
kartu aktivitas. Ketuk **"Pas"** pada satu kartu, lalu **"Sulit"** pada kartu
lain. Perlihatkan keduanya berubah menjadi tercatat.

**Teks layar:**

```
Tiga tombol. Mudah · Pas · Sulit
Tercatat di perangkat lebih dulu — bekerja tanpa jaringan
```

**Narasi** (62 kata):

> Beranda menampilkan rencana hari ini, dan sebelum itu satu pertanyaan untuk
> pengasuhnya sendiri: bagaimana kondisi Anda hari ini.
>
> Mencatat respons hanya butuh satu ketukan. Mudah, Pas, atau Sulit. Tidak ada
> formulir, tidak ada skor, tidak ada penilaian terhadap anak.
>
> Catatan tersimpan di perangkat lebih dulu, lalu dikirim saat jaringan
> tersedia — jadi tidak ada yang hilang di daerah dengan sinyal buruk.

---

#### 4c — Rencana dan mesin adaptasi · 3:04–3:44 · 40 detik

**Adegan paling penting di seluruh video.** Ini yang membuktikan ada mesin di
dalamnya, bukan sekadar antarmuka.

**Rekam:** ketuk tab **Rencana** → perlihatkan pemilih hari → gulir ke bawah
sampai kartu **"Mengapa rencana ini berubah"** terlihat **penuh** → berhenti
tiga detik penuh di situ → ketuk **"Saya koreksi sendiri"** → pilih satu
alasan → simpan → perlihatkan kartunya bertambah.

**Teks layar:**

```
Lima aturan adaptasi
Alasannya menyebut angka nyata — bukan kotak hitam
"Saya koreksi sendiri" — pengasuh selalu bisa membantah mesinnya
```

**Narasi** (95 kata):

> Ini yang terjadi pada catatan tadi.
>
> Setiap minggu, lima aturan adaptasi membaca seluruh respons dan menyusun
> ulang rencana. Porsi kategori yang terlalu mudah dikurangi, yang terlalu
> sulit diturunkan tingkatnya, dan jam kegiatan digeser ke waktu yang
> respons anak paling baik.
>
> Yang penting bukan bahwa rencananya berubah, melainkan bahwa aplikasi
> mengatakan mengapa — dengan menyebut angka yang bisa Anda periksa sendiri.
>
> Dan kalau pengasuh tidak setuju, ada tombol "Saya koreksi sendiri". Koreksi
> manual dikunci, dan aturan otomatis tidak akan membatalkannya minggu depan.
> Pengasuh yang memegang keputusan akhir, bukan mesinnya.

---

#### 4d — Laporan perkembangan · 3:44–4:14 · 30 detik

**Rekam:** ketuk tab **Profil** → ketuk **"Laporan perkembangan"** → gulir
pelan melewati metrik, grafik tren, lalu rincian per kategori → **berhenti di
kategori Sosial yang bertanda perhatian** selama tiga detik.

**Teks layar:**

```
Empat minggu · 140 terjadwal · 120 tercatat · 86%
Sosial menurun tiga periode → penanda perhatian otomatis
```

**Narasi** (76 kata):

> Empat minggu catatan menjadi satu laporan.
>
> Seluruh angkanya dihitung dari catatan nyata, bukan dikarang: berapa yang
> terjadwal, berapa yang benar-benar tercatat, dan bagaimana tiap kategori
> bergerak dari minggu ke minggu.
>
> Perhatikan kategori Sosial. Ia menurun tiga periode berturut-turut, dan
> aplikasi menandainya sendiri sebagai perlu perhatian.
>
> Aplikasi tidak menyimpulkan apa pun dari penurunan itu. Ia tidak menilai,
> tidak mendiagnosis. Ia hanya memastikan pola itu tidak lewat tanpa
> terlihat — lalu menyerahkannya kepada orang yang berhak menafsirkan.

---

#### 4e — Berbagi dengan izin · 4:14–4:30 · 16 detik

**Rekam:** di layar laporan, ketuk aksi berbagi → pilih tenaga profesional
dari daftar → perlihatkan status izin menjadi aktif → perlihatkan tombol
**cabut** izin.

**Teks layar:**

```
Izin per laporan, bukan per akun
Dapat dicabut kapan saja — akses terputus di sisi peladen
```

**Narasi** (46 kata):

> Laporan tidak terkirim sendiri. Pengasuh memilih profesionalnya, dan izin
> diberikan per laporan — bukan sekali untuk selamanya.
>
> Izin itu dapat dicabut kapan saja, dan pencabutannya memutus akses di sisi
> peladen lewat Row Level Security, bukan sekadar menyembunyikan barisnya di
> layar.

---

#### 4f — Sisi profesional, lingkaran menutup · 4:30–4:52 · 22 detik

**Rekam:** keluar dari akun → masuk sebagai `demo.profesional@dekapautis.id` →
kotak masuk laporan → buka laporan Bima → gulir melihat ringkasan dan penanda
→ tulis satu saran terstruktur → kirim. **Lalu kembali ke akun pengasuh dan
perlihatkan saran itu muncul di layar Rencana.**

**Teks layar:**

```
Profesional melihat laporan — bukan catatan mentah anak
Tanggapan masuk ke rencana pengasuh
↺ lingkaran menutup
```

**Narasi** (58 kata):

> Dari sisi tenaga profesional, laporan itu sudah siap dibaca. Ia melihat
> ringkasan dan penanda perhatian — tetapi tidak pernah melihat catatan harian
> mentah anak. Batas itu ditegakkan basis data, bukan antarmuka.
>
> Profesional menulis saran terstruktur. Dan saran itu masuk kembali ke
> rencana pengasuh minggu berikutnya.
>
> Di titik ini lingkarannya menutup.

---

### Adegan 5 — Batas medis · 4:52–5:34 · 42 detik

Pembeda produk Anda. Jangan dipangkas.

#### 5a — Pertanyaan aman

**Rekam:** tab **Tanya** → ketik persis `Bagaimana cara membangun rutinitas
pagi yang bisa diprediksi?` → tunggu jawaban → **ketuk salah satu keping
sumber bernomor** → perlihatkan rincian sumbernya.

**Teks layar:**

```
31 dokumen sumber resmi · 190 potongan terindeks
Setiap jawaban membawa sumber yang dapat dibuka
```

**Narasi versi A** — pakai ini kalau kunci Gemini terpasang (48 kata):

> Tanya Dekap menjawab dari korpus tiga puluh satu dokumen resmi — Kementerian
> Kesehatan dan sumber sejenis — yang dipotong menjadi seratus sembilan puluh
> bagian terindeks.
>
> Setiap jawaban membawa keping sumber bernomor yang dapat ditekan. Tidak ada
> kalimat tanpa asal.

**Narasi versi B** — pakai ini kalau menjawab "mode terbatas" (66 kata):

> Tanya Dekap menjawab dari korpus tiga puluh satu dokumen resmi yang dipotong
> menjadi seratus sembilan puluh bagian terindeks.
>
> Perhatikan label "mode terbatas" di sini. Layanan perangkuman sedang tidak
> tersedia, jadi aplikasi menampilkan kutipan sumbernya apa adanya alih-alih
> mengarang jawaban atau menampilkan layar kosong. Degradasi seperti ini
> dirancang sejak awal — dan sumbernya tetap nyata serta tetap dapat dibuka.

#### 5b — Pertanyaan yang harus ditolak

**Rekam:** di tab Tanya, ketik persis `Berapa dosis melatonin yang aman untuk
anak saya?` → perlihatkan **pemberitahuan batas aman** muncul → gulir melihat
daftar hal yang bisa dibantu.

**Teks layar:**

```
Tiga lapis: leksikon → klasifikasi niat → verifikasi keluaran
Tidak mendiagnosis · tidak menilai tingkat · tidak menganjurkan obat
Ini mekanisme teknis, bukan kalimat penyangkalan
```

**Narasi** (72 kata):

> Sekarang pertanyaan yang tidak boleh dijawab aplikasi mana pun.
>
> Aplikasi menolak, dan menjelaskan mengapa, lalu menawarkan apa yang bisa ia
> bantu.
>
> Penolakan ini melewati tiga lapis: penapis leksikon deterministik,
> klasifikasi niat oleh model, dan verifikasi keluaran sebelum satu kata pun
> sampai ke pengguna. Setiap pemicu dicatat.
>
> DekapAutis tidak mendiagnosis, tidak menilai tingkat spektrum, dan tidak
> menganjurkan obat. Itu bukan kalimat penyangkalan di bagian bawah layar —
> itu tiga lapis kode.

---

### Adegan 6 — Kelengkapan fitur dan aksesibilitas · 5:34–6:06 · 32 detik

Ini yang mengisi butir **"Kelengkapan Fitur"** pada bobot 15%. Gerak cepat,
4–6 detik per layar.

| # | Rekam |
|---|---|
| 6a | **Jelajah → Profesional** → ketik `Surabaya` → perlihatkan jarak dalam km di kartu |
| 6b | **Jelajah → Pustaka** → buka satu artikel → perlihatkan penerbit dan tautan asli |
| 6c | **Jelajah → Komunitas** → perlihatkan postingan anonim yang hanya menampilkan inisial |
| 6d | **Profil → Aksesibilitas** → nyalakan **Mode Tenang** → kembali ke Beranda, perlihatkan warna meredup dan transisi hilang |
| 6e | Nyalakan **mode pesawat** → perlihatkan pita luring muncul, lalu rencana tetap terbuka |

**Teks layar:**

```
6a   Jarak dihitung Haversine di perangkat — tanpa SDK peta berbayar
6b   Pustaka: sumber resmi, tautan asli selalu dapat dibuka
6c   Anonim disembunyikan di sisi peladen — identitas tidak pernah dikirim ke klien
6d   Mode Tenang: warna meredam, gambar jadi teks, transisi menjadi nol
6e   Luring: rencana tetap terbuka, catatan mengantre lalu terkirim sendiri
```

**Narasi** (84 kata):

> Selebihnya secara singkat.
>
> Direktori profesional menghitung jarak dengan rumus Haversine langsung di
> perangkat — tanpa SDK peta berbayar. Pustaka berisi dokumen resmi yang
> tautan aslinya selalu dapat dibuka. Komunitas menyembunyikan identitas di
> sisi peladen: kolom namanya tidak pernah dikirim ke aplikasi sama sekali.
>
> Mode Tenang meredam warna, mengganti gambar dengan teks, dan menghilangkan
> seluruh transisi — untuk anak dan pengasuh dengan sensitivitas sensorik.
>
> Dan tanpa jaringan sekalipun, rencana tetap terbuka. Catatan mengantre di
> perangkat lalu terkirim sendiri.

---

### Adegan 7 — Dampak dan penutup · 6:06–6:30 · 24 detik

**Rekam:** kartu penutup statis. Logo ITS, HIMASIF, IT CONVERT 2026. Nama tim
dan anggota. Tautan repositori.

**Teks layar:**

```
DekapAutis

Fable 5 Enjoyer
Institut Teknologi Sepuluh Nopember

Muhammad Dzaky Ahnaf · 5027231039
Diffa Adzra Anelya · 5051231021

github.com/dzakyahnaf/DekapAutis

#ITC2026 #SOFTDEV_ITC2026
```

**Narasi** (62 kata):

> DekapAutis tidak menggantikan terapis, dan tidak berusaha menjadi terapis.
>
> Yang ia lakukan adalah membuat waktu di rumah antara dua jadwal terapi
> menjadi terarah, menjaga setiap saran tetap dapat ditelusuri ke sumber yang
> dapat dibuka, dan menutup jarak antara pengasuh dan tenaga profesional.
>
> Terima kasih. Kami Fable 5 Enjoyer, dari Institut Teknologi Sepuluh
> Nopember.

---

## Bagian 4 — Catatan penyuntingan

### Total durasi

```
Adegan 0  bumper              0:08
Adegan 1  masalah             0:44
Adegan 2  ide inovasi         0:36
Adegan 3  proses perancangan  0:46
Adegan 4  demonstrasi         2:38
Adegan 5  batas medis         0:42
Adegan 6  kelengkapan         0:32
Adegan 7  penutup             0:24
                              ────
                              6:30
```

Aman di dalam jendela 3–7 menit, dengan cadangan satu setengah menit kalau
narasi Anda lebih lambat dari acuan.

### Merekam narasi

Rulebook mensyaratkan audio terdengar jelas, dan itu dinilai.

- Rekam di ruangan berkarpet atau di dalam lemari pakaian. Kain menyerap gema
  jauh lebih baik daripada perangkat lunak bisa menghilangkannya.
- Mikrofon earphone berkabel sudah cukup. Jangan pakai mikrofon laptop.
- Rekam per adegan. Salah satu kalimat berarti mengulang satu paragraf.
- Baca lebih lambat daripada yang terasa wajar. Rekaman selalu terdengar lebih
  cepat saat diputar ulang.

### Musik

Instrumental pelan, **volume −24 dB** di bawah narasi. Aplikasi ini untuk
orang dengan sensitivitas sensorik — musik yang menghentak bertentangan dengan
seluruh isi videonya. Pakai yang bebas royalti dan cantumkan sumbernya di
deskripsi.

### Teks di layar

- Lexend Deca, sama seperti aplikasi
- Tinta `#4A2657` di atas kertas `#F2E8F6`, atau putih di atas pita ungu pekat
- Setiap kartu tahan minimal **3 detik** — cukup untuk dibaca dua kali
- Maksimal dua baris per kartu
- **Tanpa transisi bergerak yang berulang.** Potong langsung atau larut halus.
  Video tentang produk yang melarang animasi berulang tidak boleh sendirinya
  penuh animasi berulang

### Watermark

Pasang watermark panitia di seluruh durasi, termasuk di atas adegan bumper
kalau berkas bumpernya belum memuatnya. Sudut kanan atas, opasitas 60%.

---

## Bagian 5 — Sebelum mengunggah

- [ ] Durasi antara 3:00 dan 7:00
- [ ] Resolusi ekspor 1920×1080, tidak diperbesar dari yang lebih kecil
- [ ] Bumper panitia ada di awal, tidak dipotong
- [ ] Watermark panitia tampak di seluruh durasi
- [ ] Audio terdengar jelas, narasi tidak tertimbun musik
- [ ] Judul persis: `IT CONVERT 2026 - SOFTDEV - Fable 5 Enjoyer - DekapAutis`
- [ ] Deskripsi memuat nama tim, ketua, dan anggota
- [ ] Tag `#ITC2026` dan `#SOFTDEV_ITC2026` terpasang
- [ ] Hak akses **Unlisted** — bukan Private, bukan Public
- [ ] Buka tautannya dari jendela penyamaran untuk memastikan bisa diputar
- [ ] Tidak ada klaim medis: tanpa "sembuh", "terapi", "diagnosis", atau
      tingkat spektrum
- [ ] Tidak ada nama atau data pribadi sungguhan yang terlihat
- [ ] Keping "Akun demo — data sintetis" terlihat setidaknya sekali

Lalu isi `submission/ITC2026_SOFTDEV_Video_Fable5Enjoyer.txt` dengan tautannya
dan susun ulang ZIP-nya.
