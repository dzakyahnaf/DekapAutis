# 09 — Brief Poster DekapAutis

Dilampirkan ke Claude Design / Google Stitch bersama tangkapan layar aplikasi.

Dua sumber aturan:
- **Rulebook IT CONVERT 2026**, bagian *Ketentuan Poster* dan *Kriteria Penilaian → Tahap 2 → Poster*. Ini wajib.
- **[nutlope/hallmark](https://github.com/nutlope/hallmark)** — disiplin anti-desain-generik. Ini yang menjaga posternya tidak terlihat seperti keluaran mesin.

---

## 0. Posisi yang diambil poster ini

Hallmark menilai enam sumbu sebelum apa pun digambar, dan yang pertama adalah
**Philosophy**: apakah ada *alasan* — sebuah sikap yang diambil — atau ini
sekadar tata letak?

Sikap poster ini:

> **Aplikasi ini bukan pencatat. Ia lingkaran yang menutup.**
> Catatan pengasuh mengubah rencana; laporan sampai ke tenaga profesional;
> tanggapan profesional kembali mengubah rencana. Itu yang membedakannya dari
> jurnal harian berbentuk aplikasi, dan itu yang harus terlihat lebih dulu
> daripada apa pun.

Konsekuensinya keras: **lingkaran itu adalah posternya**, bukan salah satu
bagian di dalamnya. Segala sesuatu yang lain menggantung padanya.

Sumbu Hallmark lainnya untuk dinilai sendiri sebelum menyerahkan hasil —
Hierarchy, Execution, Specificity, Restraint, Variety. Skor di bawah 3 pada
sumbu mana pun berarti revisi, bukan lanjut.

---

## 1. Makrostruktur: **Map / Diagram**

Hallmark menyediakan 21 makrostruktur dan melarang jatuh ke yang generik.
Yang dipilih di sini adalah **19 · Map / Diagram** — *"sebuah diagram spasial
besar mengatur halaman; informasi ditata secara ruang, bukan linear."*

Alasannya bukan selera:

- Bobot penilaian terbesar (30%) adalah **ilustrasi proses dan metode desain**.
  Makrostruktur ini menjadikan diagram sebagai tulang punggung, bukan hiasan.
- Produknya memang sebuah siklus. Menata siklus sebagai tumpukan bagian
  vertikal justru mengingkari isinya.

**Yang ditolak dan alasannya** — ini gate Hallmark yang gagal dilewati oleh
rancangan pertama brief ini:

| Pola | Gate | Kenapa ditolak |
|---|---|---|
| Tiga kolom kartu seragam (Tujuan / Manfaat / Fitur) | 3 | Kisi tiga kolom berikon-di-atas-judul adalah tanda paling khas keluaran AI |
| Tumpukan bagian: judul → masalah → solusi → fitur → kaki | 8 | Template generik. Struktur harus dipilih, bukan jatuh sendiri |
| Bagian dipisah hanya oleh jarak kosong yang sama | 9 | Ritme yang identik membuat semuanya terasa setara — tak ada hierarki |
| Mockup dalam bingkai ponsel gambar-sendiri | 47 | Chrome digambar ulang adalah tanda kuat "buatan AI". Pakai tangkapan layar apa adanya |
| Judul dimiringkan | 38a | Header miring adalah tanda AI teratas. Penekanan lewat bobot atau warna |
| Gradien ungu-ke-biru, teks bergradien | 2 | Dilarang mutlak |
| Kartu di dalam kartu | 4 | — |
| Garis tebal berwarna di sisi kiri kartu | 5 | — |

---

## 2. Ketentuan wajib rulebook — daftar periksa

Melanggar salah satunya berisiko diskualifikasi atau kehilangan nilai penuh.

| # | Ketentuan | Cara memeriksa |
|---|---|---|
| 1 | Ukuran **A3** | Portrait 297 × 420 mm → **3508 × 4961 px** pada 300 ppi |
| 2 | **Minimal 300 ppi** | Ekspor 300 ppi, bukan 72 ppi diperbesar |
| 3 | **JPG atau PNG** | PNG untuk teks tajam |
| 4 | **Logo ITS + HIMASIF + IT CONVERT 2026 di KIRI ATAS** | Ketiganya. Unduh: https://himasif.id/LogoITC2026 |
| 5–8 | Memuat **judul, nama tim, tujuan, manfaat** | Masing-masing terbaca sebagai bagian tersendiri |
| 9 | Memuat **fitur aplikasi (mockup)** | Tangkapan layar sungguhan |
| 10 | Orisinal, belum pernah dipublikasikan | Tanpa stok gambar |
| 11 | Tanpa SARA dan pornografi | — |
| 12 | **Terbaca terstruktur** | Alur baca satu arah yang jelas |

Setelah jadi: unggah ke Instagram anggota tim, tandai **@itconvert_unej** dan
anggota lain, tagar **#ITC2026 #SOFTDEV**, caption berisi deskripsi produk.
**Jangan diarsipkan atau dihapus** selama masa penilaian.

---

## 3. Bobot penilaian menentukan proporsi ruang

| Kriteria | Bobot | Konsekuensi tata letak |
|---|---:|---|
| Visualisasi — **ilustrasi proses dan metode desain** | **30%** | Dua diagram mendapat ruang terbesar |
| Pesan — **permasalahan dan solusi** | **30%** | Terbaca dalam sepuluh detik pertama |
| Kesesuaian isi dengan **proposal** | 25% | Nama, persona, fitur sama persis dengan Tahap 1 |
| Orisinalitas | 15% | Aset dibuat sendiri |

Enam puluh persen nilai ada pada diagram dan pernyataan masalah–solusi.
Mockup melayani kriteria 25% — **jangan biarkan deretan tangkapan layar
memakan ruang diagram.**

---

## 4. Sistem desain — nilai persis dari `app/lib/core/theme/tokens.dart`

Poster memakai palet aplikasinya. Juri membandingkan keduanya, dan poster
berwarna lain membuat produknya terlihat seperti dua proyek berbeda.

### Warna

Hanya **dua keluarga**: ungu dan krem. **Tanpa biru, hijau, merah, oranye,
atau abu-abu netral murni.**

| Peran | Hex | Pakai untuk |
|---|---|---|
| Kertas | `#F2E8F6` | Latar poster |
| Permukaan | `#FFFFFF` | Panel, bidang tangkapan layar |
| Garis rambut | `#D8C6E0` | Garis 1–2 px, pemisah, penghubung diagram |
| Tinta utama | `#4A2657` | Seluruh teks dan judul |
| Tinta kedua | `#6B5F73` | Keterangan, label |
| Aksen ungu | `#7B4490` | Jalur sistem dan AI |
| Aksen krem | `#6F5722` | Jalur manusia: pengasuh, komunitas, profesional |
| Bidang ungu | `#E4CEEC` | Latar di belakang tinta utama |
| Bidang krem | `#EDDFBC` | Latar di belakang tinta utama |
| Krem lembut | `#FBF6EA` | Permukaan tenang |

**Netral berpigmen, bukan abu-abu.** `#6B5F73` adalah netral yang membawa
pigmen ungu — Hallmark gate 22 menolak netral berkroma nol karena terbaca
datar. Palet ini sudah memenuhinya; jangan menggantinya dengan abu-abu murni.

**Aksen maksimal ±5% luas poster** (gate 23). `#7B4490` dan `#6F5722` untuk
penekanan, bukan untuk mengisi bidang besar. Kertas `#F2E8F6` yang mendominasi.

**Larangan kontras — mutlak.** `#F2E8F6`, `#E4CEEC`, `#CA9CDB`, dan `#EDDFBC`
**tidak boleh menjadi warna teks**. Teks selalu `#4A2657` di atas bidang
terang, atau `#FFFFFF` di atas `#7B4490` / `#6F5722`. Setiap bidang gelap yang
membawa teks wajib membalik warna tintanya — gate 41 menyebut kegagalan ini
"ink-on-ink", dan ia yang paling sering lolos ke cetakan.

### Tipografi — aturan 2+1

Hallmark membatasi **tiga rupa huruf, tidak lebih** (gate 37), dan rupa ketiga
hanya boleh muncul di **maksimal dua tempat** (gate 38).

| Peran | Rupa | Dipakai di |
|---|---|---|
| Display + teks | **Lexend Deca** | Judul, subjudul, seluruh teks isi |
| Angka | **IBM Plex Mono**, angka tabular | Hanya dua tempat: baris statistik dan nomor simpul diagram |

Lexend Deca dipilih karena sumbu lebarnya mengurangi kerumunan visual saat
membaca — alasan fungsional, bukan estetika, dan itu bisa Anda katakan kalau
juri bertanya.

**Dilarang**: Inter, Roboto, Open Sans, Poppins, Lato, atau huruf bawaan
sistem sebagai rupa display (gate 1). **Judul tidak pernah miring** (gate 38a)
— penekanan lewat bobot, warna aksen, atau garis bawah tipis.

Hierarki A3: judul ±170 pt · subjudul ±64 pt · judul bagian ±42 pt ·
teks isi ±26 pt · keterangan ±19 pt. Jangan di bawah 24 pt untuk teks isi.

Lebar kolom teks **45–75 karakter** (gate 25). Di bawah 45 terasa patah-patah,
di atas 75 mata kehilangan barisnya.

### Ruang dan bentuk

- Skala jarak kelipatan 4: 8 · 16 · 24 · 32 · 48 · 64 · 96 · 144 px pada
  skala A3 300 ppi. **Nilai di luar skala adalah tanda** (gate 24) — tidak ada
  `padding: 17px`.
- Sudut membulat 48 px untuk panel, 36 px untuk elemen kecil.
- **Garis tipis, bukan bayangan.** Sistem desain ini tidak memakai elevasi.
- Margin tepi minimal 15 mm.
- **Pemisah antarbagian bukan hanya jarak kosong** (gate 9): pakai garis
  rambut `#D8C6E0`, pergeseran warna bidang, atau perubahan ritme kolom.

### Ikon dan ilustrasi

- **Satu pustaka ikon saja.** Aplikasinya memakai Material Symbols Rounded —
  pakai itu, jangan mencampur dua pustaka (gate 30).
- **Tanpa emoji sebagai ikon fitur** (gate 30). ✨🚀⚡ adalah tanda AI.
- Ilustrasi digambar sendiri sebagai bentuk geometris sederhana. Tanpa Lottie,
  tanpa stok foto anak.
- **Setiap hiasan harus punya alasan** (gate 45). Angka di sudut tanpa makna,
  bentuk abstrak tanpa jangkar isi — itu slop. Nomor simpul diagram punya
  makna; ornamen acak tidak.

---

## 5. Komposisi — Map / Diagram pada A3 portrait

Lingkaran adalah tulang punggungnya. Segala hal lain menggantung padanya.

```
┌─────────────────────────────────────────────────────────┐
│ [ITS][HIMASIF][ITC2026]                                 │  logo kiri atas
│                                                          │
│  DekapAutis                          Fable 5 Enjoyer     │  judul kiri,
│  Pendamping AI untuk pengasuh        Institut Teknologi  │  identitas kanan
│  anak dengan spektrum autisme        Sepuluh Nopember    │  — poros dipatahkan
├─────────────────────────────────────────────────────────┤  garis rambut
│                                                          │
│  MASALAH          ╭───────────────────────────╮          │
│  kolom sempit     │                           │          │
│  kiri, 50 ch      │   ◯ 1 Profil anak         │          │
│                   │        ↘                  │          │
│  Antrean terapi   │   ◯ 2 Rencana mingguan ←──┼──╮       │
│  panjang, biaya   │        ↘              [ss] │  │       │
│  berulang, jarak  │   ◯ 3 Catat respons       │  │       │
│  ke profesional.  │        ↘         [ss]     │  │       │
│  Di antara dua    │   ◯ 4 Rencana menyesuaikan│  │       │
│  jadwal, rumah    │        ↘                  │  │       │
│  jadi tempat      │   ◯ 5 Bagikan laporan[ss] │  │       │
│  belajar utama.   │        ↘                  │  │       │
│                   │   ◯ 6 Tanggapan ──────────┼──╯       │
│                   ╰───────────────────────────╯          │
│                     "tanggapan kembali mengubah rencana" │
├─────────────────────────────────────────────────────────┤  pergeseran bidang
│  PIPELINE BATAS MEDIS — tiga lapis                       │
│  spine vertikal, dua cabang penolakan ke kanan           │
│  masuk ke simpul ◯ Tanya Dekap pada lingkaran di atas    │
├─────────────────────────────────────────────────────────┤  garis rambut
│  TUJUAN · MANFAAT   ditulis sebagai prosa mengalir,      │
│                     bukan tiga kartu seragam             │
│  60 · 31 · 3 · 17 · 5 · 347    #ITC2026 #SOFTDEV         │  mono, hairline
└─────────────────────────────────────────────────────────┘
```

**Poros sengaja dipatahkan** (gate 6): judul rata kiri, identitas tim rata
kanan pada baris yang sama. Jangan menaruh semuanya di satu poros tengah.

**Tangkapan layar `[ss]` menempel pada simpul lingkaran**, bukan berbaris
terpisah di bawah. Itu yang membuat mockup melayani diagram alih-alih
bersaing dengannya — dan yang membuat kesesuaian dengan proposal (25%)
terbaca bersamaan dengan proses (30%).

**Tanpa bingkai ponsel gambar-sendiri** (gate 47). Tangkapan layar ditempel
apa adanya dengan sudut membulat 36 px dan garis rambut 1 px. Jangan
menggambar notch, speaker, atau bilah status palsu.

---

## 6. Isi — teks siap salin

Seluruhnya Bahasa Indonesia, sapaan "Anda", tidak pernah menyebut anak
"penderita" atau "penyandang".

### Judul dan identitas

```
DekapAutis
Pendamping berbasis kecerdasan artifisial untuk orang tua
dan pengasuh anak dengan spektrum autisme

Tim Fable 5 Enjoyer — Institut Teknologi Sepuluh Nopember
Muhammad Dzaky Ahnaf · Diffa Adzra Anelya
IT CONVERT 2026 · Software Development · AI in Health and Well-being
```

### Masalah

```
MASALAH
Antrean terapi panjang, biaya sesi berulang, dan jarak ke tenaga
profesional. Di antara dua jadwal terapi, rumah menjadi tempat belajar
utama — tanpa panduan, tanpa cara mengukur, dan tanpa siapa pun untuk
bertanya pukul sebelas malam.
```

### Solusi

```
SOLUSI
DekapAutis mendampingi di antara jadwal terapi. Ia menyusun rencana
stimulasi mingguan, menyesuaikannya dari catatan yang Anda tulis sendiri,
menjawab dari dokumen yang dapat Anda buka, dan menjembatani laporan
perkembangan ke tenaga profesional.

Yang tidak dilakukannya, dan itu disengaja: tidak mendiagnosis, tidak
menilai tingkat spektrum, tidak menganjurkan obat. Batas itu ditegakkan
tiga lapis teknis, bukan kalimat penyangkalan.
```

### Diagram A — lingkaran (tulang punggung poster)

Enam simpul bernomor, panah searah jarum jam, panah balik dari 6 ke 2.

```
1  Profil anak              usia, cara berkomunikasi, hal yang tidak nyaman
2  Rencana mingguan         dari katalog 60 aktivitas, dipilih aturan
3  Jalankan & catat respons Mudah · Pas · Sulit
4  Rencana menyesuaikan     lima aturan, alasan menyebut angka nyata
5  Bagikan laporan          izin per laporan, dapat dicabut
6  Tanggapan profesional    kembali mengubah rencana
```

Panah balik dari 6 ke 2 diberi label:
**"tanggapan kembali mengubah rencana"** — dan digambar lebih tebal daripada
panah lain. Itu kalimat terpenting di poster.

Simpul 3 diberi aksen krem `#6F5722` (jalur manusia); simpul 2 dan 4 aksen
ungu `#7B4490` (jalur sistem). Perbedaan itu punya makna di aplikasinya —
pertahankan.

### Diagram B — pipeline batas medis

Spine vertikal, dua cabang penolakan keluar ke kanan.

```
Pertanyaan pengasuh
   │
   ├─ Lapis 1  Penapis leksikon deterministik  ──→ pemberitahuan batas aman
   │
   ├─ Pengambilan hibrida
   │            pgvector + teks penuh Bahasa Indonesia
   │            digabung Reciprocal Rank Fusion
   │
   ├─ Lapis 2  Klasifikasi niat oleh model     ──→ pemberitahuan batas aman
   │
   ├─ Gemini ─gagal→ Groq ─gagal→ teks penuh + tanda "mode terbatas"
   │
   └─ Lapis 3  Verifikasi keluaran             ──→ dibuang, dicatat
                  │
                  ↓
           Jawaban + sumber yang dapat dibuka
```

Keterangan kecil di bawahnya: *"Setiap pemicu dicatat ke `log_batas_aman`."*

### Tujuan dan manfaat — prosa, bukan kartu

Tulis mengalir dalam dua kolom teks, bukan tiga kartu seragam:

```
TUJUAN
Membuat waktu di rumah antara dua jadwal terapi menjadi terarah; menjaga
setiap saran tetap dapat ditelusuri ke sumber yang dapat dibuka; dan
menutup jarak antara pengasuh dan tenaga profesional tanpa menggantikan
keduanya.

MANFAAT
Bagi pengasuh, rencana harian yang menyesuaikan diri dengan alasan yang
menyebut angka nyata — bukan kotak hitam. Bagi anak, aktivitas pada
tingkat yang sesuai dalam rutinitas yang dapat diprediksi. Bagi tenaga
profesional, laporan empat minggu yang siap dibaca, lengkap dengan
penanda perhatian otomatis.
```

### Angka — semuanya terhitung, tidak satu pun dikarang

Hallmark gate 46 menolak metrik yang dikarang untuk mengisi tata letak.
Enam angka ini seluruhnya dapat ditunjuk asalnya:

```
60   aktivitas dalam katalog
31   dokumen sumber resmi · 190 potongan terindeks
3    lapis batas medis
17   layar pengasuh
5    aturan adaptasi
347  test otomatis · 112 pemeriksaan basis data
```

Set dalam IBM Plex Mono di sepanjang garis rambut. **Jangan menambahkan angka
lain.** Setiap angka harus bisa Anda pertanggungjawabkan kalau juri bertanya.

---

## 7. Prompt siap tempel

Salin seluruh blok ini, lampirkan berkas ini dan tangkapan layar aplikasi.

```
Buat poster kompetisi A3 portrait, 3508 × 4961 px, 300 ppi, untuk DekapAutis —
aplikasi pendamping berbasis AI untuk orang tua dan pengasuh anak dengan
spektrum autisme. Seluruh teks Bahasa Indonesia.

MAKROSTRUKTUR: Map / Diagram. Sebuah diagram lingkaran besar mengatur
seluruh poster secara spasial. Ini BUKAN tumpukan bagian vertikal dan BUKAN
kisi kartu.

POSISI YANG DIAMBIL: aplikasi ini bukan pencatat, ia lingkaran yang menutup —
catatan pengasuh mengubah rencana, laporan sampai ke profesional, tanggapan
profesional kembali mengubah rencana. Lingkaran itu adalah posternya.

PALET — dua keluarga saja, ungu dan krem. Dilarang biru, hijau, merah,
oranye, abu-abu netral murni, dan gradien apa pun.
  Kertas       #F2E8F6   (mendominasi)
  Permukaan    #FFFFFF
  Garis rambut #D8C6E0
  Tinta utama  #4A2657
  Tinta kedua  #6B5F73
  Aksen ungu   #7B4490   jalur sistem/AI — maksimal 5% luas
  Aksen krem   #6F5722   jalur manusia — maksimal 5% luas
  Bidang       #E4CEEC dan #EDDFBC — hanya latar, TIDAK PERNAH warna teks

TIPOGRAFI — tepat dua rupa, tidak lebih.
  Lexend Deca  judul dan seluruh teks
  IBM Plex Mono  hanya di dua tempat: baris statistik dan nomor simpul
  Judul ±170 pt · subjudul ±64 pt · judul bagian ±42 pt · isi ±26 pt
  DILARANG Inter, Roboto, Open Sans, Poppins, Lato.
  DILARANG judul miring. Penekanan lewat bobot atau warna aksen.
  Lebar kolom teks 45–75 karakter.

KOMPOSISI dari atas ke bawah
  1. Kiri atas: tiga logo sebaris — Institut Teknologi Sepuluh Nopember,
     HIMASIF, IT CONVERT 2026. Sisakan ruang, logonya saya sisipkan sendiri.
  2. Baris judul dengan poros dipatahkan: "DekapAutis" dan subjudul rata
     KIRI, nama tim dan institusi rata KANAN pada baris yang sama.
     Jangan menaruh semuanya di satu poros tengah.
  3. Garis rambut pemisah.
  4. Kolom sempit kiri: MASALAH. Di sebelahnya, mendominasi tengah poster:
     diagram lingkaran enam simpul bernomor, panah searah jarum jam.
     Panah balik dari simpul 6 ke simpul 2 digambar LEBIH TEBAL dan diberi
     label "tanggapan kembali mengubah rencana". Ini elemen terpenting.
     Simpul 3 beraksen krem, simpul 2 dan 4 beraksen ungu.
  5. Empat tangkapan layar aplikasi menempel langsung pada simpul 2, 3, 5,
     dan pada simpul Tanya. Tempel apa adanya dengan sudut membulat dan
     garis rambut 1 px. JANGAN menggambar bingkai ponsel, notch, atau bilah
     status palsu.
  6. Pergeseran bidang warna sebagai pemisah, lalu diagram pipeline tiga
     lapis: spine vertikal dengan dua cabang penolakan keluar ke kanan.
  7. Garis rambut, lalu TUJUAN dan MANFAAT sebagai prosa mengalir dua kolom.
     BUKAN tiga kartu seragam.
  8. Baris angka dalam mono di sepanjang garis rambut, dengan tagar
     #ITC2026 #SOFTDEV.

PROPORSI: dua diagram bersama-sama mendapat sekitar 45% tinggi poster.
Bobot penilaian terbesar ada pada ilustrasi proses; jangan biarkan tangkapan
layar memakan ruangnya.

GAYA: datar, garis rambut 1–2 px, sudut membulat 48 px untuk panel.
TANPA bayangan, gradien, glow, efek 3D, stok foto, emoji sebagai ikon, dan
tanpa mencampur dua pustaka ikon. Setiap ornamen harus punya alasan —
ornamen tanpa jangkar isi jangan digambar sama sekali.
Jarak memakai kelipatan 4 px saja.
Tenang dan lapang: audiensnya pengasuh yang lelah dan anak dengan
sensitivitas sensorik.
```

---

## 8. Sebelum diunggah — daftar periksa gabungan

**Rulebook**
- [ ] 3508 × 4961 px, metadata 300 ppi (bukan 72 diperbesar)
- [ ] Tiga logo ada, di kiri atas
- [ ] Judul, nama tim, tujuan, manfaat, fitur, mockup — semuanya ada
- [ ] Caption Instagram + tandai @itconvert_unej + #ITC2026 #SOFTDEV

**Anti-slop (Hallmark)**
- [ ] Tidak ada kisi tiga kolom kartu seragam
- [ ] Bagian dipisah garis atau pergeseran bidang, bukan hanya jarak kosong
- [ ] Poros judul dipatahkan, tidak semuanya di tengah
- [ ] Tidak ada bingkai ponsel, notch, atau bilah status gambar-sendiri
- [ ] Tidak ada judul miring
- [ ] Tidak ada gradien, bayangan, atau glow
- [ ] Tepat dua rupa huruf; mono hanya di dua tempat
- [ ] Aksen ungu + krem bersama-sama ≤ 5% luas
- [ ] Satu pustaka ikon; tidak ada emoji sebagai ikon
- [ ] Semua jarak kelipatan 4
- [ ] Setiap ornamen punya alasan

**Isi dan kontras**
- [ ] Tidak ada `#F2E8F6`, `#E4CEEC`, `#CA9CDB`, `#EDDFBC` sebagai warna teks
- [ ] Setiap bidang gelap membalik warna tintanya
- [ ] Setiap angka dapat ditelusuri asalnya — tidak ada metrik karangan
- [ ] Tidak ada klaim medis: tanpa "sembuh", "terapi medis", "diagnosis",
      atau tingkat/derajat autisme
- [ ] Ejaan "Fable 5 Enjoyer" dan "DekapAutis" konsisten dengan proposal

**Kritik-diri Hallmark** — beri skor 1–5, revisi bila ada yang di bawah 3:
Philosophy · Hierarchy · Execution · Specificity · Restraint · Variety
