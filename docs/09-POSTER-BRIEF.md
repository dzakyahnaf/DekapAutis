# 09 — Brief Poster DekapAutis

Berkas ini dilampirkan ke Claude Design / Google Stitch. Isinya tiga bagian:
ketentuan wajib rulebook, sistem desain yang harus dipatuhi, dan prompt siap
tempel di bagian paling bawah.

Sumber ketentuan: `RULEBOOK SOFTWARE DEVELOPMENT ITC 2026`, bagian *Ketentuan
Poster* dan *Kriteria Penilaian → Penilaian Tahap 2 → Poster*.

---

## 1. Ketentuan wajib — daftar periksa

Bukan saran. Melanggar salah satunya berisiko diskualifikasi atau kehilangan
nilai penuh pada satu kriteria.

| # | Ketentuan | Cara memeriksanya |
|---|---|---|
| 1 | Ukuran **A3** | Portrait 297 × 420 mm → **3508 × 4961 px** pada 300 ppi |
| 2 | Resolusi **minimal 300 ppi** | Ekspor 300 ppi, bukan 72 ppi yang diperbesar |
| 3 | Format **JPG atau PNG** | PNG untuk teks tajam; JPG kualitas ≥ 90 bila ukuran jadi masalah |
| 4 | **Logo ITS + HIMASIF + IT CONVERT 2026 di KIRI ATAS** | Ketiganya, sebaris, sudut kiri atas. Unduh: https://himasif.id/LogoITC2026 |
| 5 | Memuat **judul** | "DekapAutis" |
| 6 | Memuat **nama tim** | "Fable 5 Enjoyer — Institut Teknologi Sepuluh Nopember" |
| 7 | Memuat **manfaat** | Bagian tersendiri, bukan tersirat |
| 8 | Memuat **tujuan** | Bagian tersendiri |
| 9 | Memuat **fitur aplikasi (mockup)** | Tangkapan layar aplikasi sungguhan, bukan ilustrasi generik |
| 10 | **Orisinal, belum pernah dipublikasikan** | Jangan pakai stok gambar yang sudah beredar |
| 11 | Tidak mengandung SARA atau pornografi | — |
| 12 | **Terbaca terstruktur**, mudah dinavigasi | Alur baca satu arah yang jelas |

Setelah jadi: unggah ke Instagram salah satu anggota, tandai
**@itconvert_unej** dan anggota lain, tagar **#ITC2026 #SOFTDEV**, caption
berisi deskripsi produk. Poster **tidak boleh diarsipkan atau dihapus** selama
masa penilaian.

---

## 2. Bobot penilaian menentukan tata letak

| Kriteria | Bobot | Artinya bagi desain |
|---|---:|---|
| Visualisasi Karya — **ilustrasi proses dan metode desain** | **30%** | Harus ada **diagram alur/proses** yang terlihat. Ini bobot terbesar bersama pesan, dan paling sering dilewatkan tim lain |
| Pesan — deskripsi singkat **permasalahan dan solusi** | **30%** | Masalah dan solusi harus terbaca dalam sepuluh detik pertama |
| Kesesuaian isi dengan **proposal** | 25% | Nama, persona, dan fitur harus sama persis dengan proposal Tahap 1 |
| Orisinalitas karya | 15% | Aset dan ilustrasi dibuat sendiri |

**Konsekuensi langsung:** enam puluh persen nilai ada pada *diagram proses* dan
*pernyataan masalah–solusi*. Keduanya harus mendapat ruang terbesar. Mockup
memang wajib, tetapi ia melayani kriteria 25%, bukan 30% — jangan sampai deretan
tangkapan layar memakan ruang diagram.

---

## 3. Sistem desain — nilai persis dari `app/lib/core/theme/tokens.dart`

Poster memakai palet yang sama dengan aplikasinya. Juri akan membandingkan
keduanya, dan poster berwarna lain membuat produknya terlihat seperti dua
proyek berbeda.

### Warna

Hanya **dua keluarga**: ungu dan krem. **Tidak ada biru, hijau, merah, oranye,
atau abu-abu netral murni.** Netralnya pun berpigmen ungu.

| Peran | Hex | Pakai untuk |
|---|---|---|
| Latar aplikasi | `#F2E8F6` | Latar utama poster |
| Permukaan kartu | `#FFFFFF` | Kartu, panel, bidang mockup |
| Garis rambut | `#D8C6E0` | Garis 1–2 px, pemisah |
| Teks utama | `#4A2657` | Seluruh teks utama dan judul |
| Teks sekunder | `#6B5F73` | Keterangan, label kecil |
| Ungu primer | `#7B4490` | Aksen jalur AI, ikon, penekanan |
| Ungu 500 | `#A96CC0` | Bidang non-teks |
| Ungu 300 | `#CA9CDB` | Bidang non-teks |
| Ungu 100 | `#E4CEEC` | Bidang di belakang teks utama |
| Krem 700 | `#6F5722` | Aksen jalur manusia (pengasuh, komunitas) |
| Krem 400 | `#D9BE7E` | Bidang non-teks |
| Krem 200 | `#EDDFBC` | Bidang di belakang teks utama |
| Krem 50 | `#FBF6EA` | Permukaan lembut |

**Aturan kontras — jangan dilanggar.** `#F2E8F6`, `#E4CEEC`, `#CA9CDB`, dan
`#EDDFBC` **tidak boleh dipakai sebagai warna teks**; kontrasnya gagal WCAG.
Teks selalu `#4A2657` di atas bidang terang, atau `#FFFFFF` di atas `#7B4490`
atau `#6F5722`.

**Arti kedua keluarga warna** — pertahankan ini, ia punya makna di aplikasi:
ungu untuk jalur sistem dan AI; krem untuk jalur manusia (catatan pengasuh,
komunitas, tanggapan tenaga profesional).

### Tipografi

- **Lexend Deca** untuk judul dan teks. Dipilih karena sumbu lebarnya
  mengurangi kerumunan visual saat membaca, bukan karena estetika.
- **IBM Plex Mono** khusus untuk angka statistik, dengan angka tabular.
- Hierarki A3: judul ±180 pt, subjudul ±72 pt, judul bagian ±48 pt, teks isi
  ±28 pt, keterangan ±20 pt. Teks isi jangan di bawah 24 pt pada A3 — poster
  dinilai juga dari layar.

### Bentuk dan ruang

- Sudut membulat: 16 px untuk kartu, 12 px untuk elemen kecil (skala A3: ±48 px
  dan ±36 px).
- **Garis tipis, bukan bayangan.** Sistem desain ini tidak memakai elevasi.
- Margin tepi poster minimal 15 mm.

### Larangan

- Tanpa gradien mencolok, tanpa glow, tanpa efek 3D.
- Tanpa stok foto anak. Gunakan ilustrasi geometris sederhana atau tangkapan
  layar aplikasi sungguhan.
- Jangan pernah menampilkan kategori atau status yang **hanya** dibedakan warna
  — selalu sertakan ikon atau label teks.

---

## 4. Isi poster — teks siap pakai

Salin apa adanya. Seluruhnya Bahasa Indonesia, sapaan "Anda", dan tidak pernah
menyebut anak "penderita" atau "penyandang".

### Judul dan identitas

```
DekapAutis
Pendamping berbasis kecerdasan artifisial untuk orang tua
dan pengasuh anak dengan spektrum autisme

Tim Fable 5 Enjoyer — Institut Teknologi Sepuluh Nopember
Muhammad Dzaky Ahnaf · Diffa Adzra Anelya
IT CONVERT 2026 · Software Development · AI in Health and Well-being
```

### Masalah (bobot 30%, separuhnya di sini)

```
MASALAH
Orang tua anak dengan spektrum autisme menghadapi tiga hal sekaligus:
antrean terapi yang panjang, biaya sesi yang berulang, dan jarak ke
tenaga profesional. Di antara dua jadwal terapi, rumah menjadi tempat
belajar utama — tanpa panduan, tanpa cara mengukur, dan tanpa siapa pun
untuk bertanya pukul sebelas malam.
```

### Solusi (separuh sisanya)

```
SOLUSI
DekapAutis mendampingi di antara jadwal terapi. Ia menyusun rencana
stimulasi mingguan, menyesuaikannya dari catatan yang Anda tulis sendiri,
menjawab pertanyaan dari dokumen yang dapat Anda buka, dan menjembatani
laporan perkembangan ke tenaga profesional.

Yang TIDAK dilakukannya, dan itu disengaja: tidak mendiagnosis, tidak
menilai tingkat spektrum, tidak menganjurkan obat. Batas itu ditegakkan
tiga lapis teknis, bukan kalimat penyangkalan.
```

### Diagram proses — bobot 30%, elemen terpenting

Gambar **dua diagram** berdampingan atau bertumpuk.

**A. Alur pengguna — lingkaran tertutup** (ini pembeda produknya):

```
  Profil anak  →  Rencana mingguan  →  Jalankan & catat respons
        ↑                                        ↓
  Tanggapan profesional  ←  Bagikan laporan  ←  Rencana menyesuaikan diri
```

Beri label pada anak panah balik: **"tanggapan kembali mengubah rencana"**.
Lingkaran yang benar-benar menutup inilah yang membedakannya dari aplikasi
pencatat biasa.

**B. Metode pengembangan — pipeline AI berlapis:**

```
Pertanyaan pengasuh
   │
   ├─ Lapis 1  Penapis leksikon deterministik   ─ ditolak → pemberitahuan batas aman
   │
   ├─ Pengambilan hibrida: pgvector + teks penuh Bahasa Indonesia
   │            digabung Reciprocal Rank Fusion
   │
   ├─ Lapis 2  Klasifikasi niat oleh model      ─ ditolak → pemberitahuan batas aman
   │
   ├─ Gemini ─gagal→ Groq ─gagal→ teks penuh + tanda "mode terbatas"
   │
   └─ Lapis 3  Verifikasi keluaran              ─ ditolak → dibuang, dicatat
                     ↓
              Jawaban + sumber yang dapat dibuka
```

Beri catatan kecil: *"Setiap pemicu dicatat ke `log_batas_aman`."*

### Tujuan

```
TUJUAN
· Membuat waktu di rumah antara dua jadwal terapi menjadi terarah
· Menjaga setiap saran tetap dapat ditelusuri ke sumber yang dapat dibuka
· Menutup jarak antara pengasuh dan tenaga profesional tanpa menggantikannya
```

### Manfaat

```
MANFAAT
· Pengasuh   Rencana harian yang menyesuaikan diri, dengan alasan yang
             menyebut angka nyata — bukan kotak hitam
· Anak       Aktivitas pada tingkat yang sesuai, dalam rutinitas yang
             dapat diprediksi
· Profesional Laporan empat minggu yang siap dibaca, dengan penanda
             perhatian otomatis
```

### Fitur — dampingi dengan mockup

```
FITUR UTAMA
1. Rencana stimulasi mingguan dari katalog 60 aktivitas
2. Mesin adaptasi lima aturan — setiap perubahan menyebut angka nyata
3. Tanya Dekap — RAG dengan 31 dokumen sumber resmi yang dapat dibuka
4. Laporan perkembangan + berbagi berizin ke tenaga profesional
5. Mode Tenang — lima efek serentak untuk beban sensorik rendah
6. Bekerja luring: antrean tulis tersimpan, terkirim saat jaringan kembali
```

**Mockup yang dipakai** — ambil tangkapan layar sungguhan dari APK:
L.2 Beranda · L.6 Rencana Mingguan · L.3 Tanya Dekap · L.8 Laporan.
Tampilkan dalam bingkai ponsel sederhana, sejajar, ukuran sama.

### Angka yang boleh dicantumkan

Semuanya terhitung dari basis kode dan basis data, bukan klaim.

```
60   aktivitas dalam katalog
31   dokumen sumber resmi · 190 potongan terindeks
3    lapis batas medis
17   layar pengasuh
5    aturan adaptasi
347  test otomatis + 112 pemeriksaan basis data
```

Jangan menambahkan angka lain. Setiap angka di poster harus bisa Anda tunjuk
asalnya kalau juri bertanya.

---

## 5. Tata letak yang disarankan (A3 portrait)

```
┌──────────────────────────────────────────────┐
│ [ITS] [HIMASIF] [ITC2026]        ← KIRI ATAS │  ~8%
├──────────────────────────────────────────────┤
│  DekapAutis                                  │
│  subjudul · tim · institusi                  │  ~12%
├───────────────────────┬──────────────────────┤
│  MASALAH              │  SOLUSI              │  ~15%
├───────────────────────┴──────────────────────┤
│  DIAGRAM A — lingkaran alur pengguna         │  ~18%
├──────────────────────────────────────────────┤
│  DIAGRAM B — pipeline AI tiga lapis          │  ~17%
├──────────────────────────────────────────────┤
│  MOCKUP — empat layar sejajar                │  ~15%
├───────────┬──────────────┬───────────────────┤
│  TUJUAN   │  MANFAAT     │  FITUR UTAMA      │  ~12%
├───────────┴──────────────┴───────────────────┤
│  angka · #ITC2026 #SOFTDEV                   │  ~3%
└──────────────────────────────────────────────┘
```

Alur baca satu arah dari atas ke bawah. Diagram mendapat 35% ruang karena
menyumbang 30% nilai.

---

## 6. Prompt siap tempel

Salin seluruh blok di bawah ke Claude Design atau Google Stitch, lampirkan
berkas ini, dan lampirkan tangkapan layar aplikasi.

```
Buat poster kompetisi A3 portrait (3508 × 4961 px, 300 ppi) untuk aplikasi
bernama DekapAutis — pendamping berbasis AI untuk orang tua dan pengasuh anak
dengan spektrum autisme. Seluruh teks Bahasa Indonesia.

PALET — hanya dua keluarga, ungu dan krem. Dilarang biru, hijau, merah,
oranye, dan abu-abu netral murni.
  Latar        #F2E8F6
  Kartu        #FFFFFF
  Garis        #D8C6E0
  Teks utama   #4A2657
  Teks kedua   #6B5F73
  Ungu aksen   #7B4490   (jalur sistem dan AI)
  Krem aksen   #6F5722   (jalur manusia: pengasuh, komunitas, profesional)
  Bidang       #E4CEEC dan #EDDFBC (hanya sebagai latar, tidak untuk teks)

TIPOGRAFI
  Judul dan teks : Lexend Deca
  Angka statistik: IBM Plex Mono, angka tabular
  Judul ±180 pt, subjudul ±72 pt, judul bagian ±48 pt, isi ±28 pt

GAYA
  Datar, garis tipis 1–2 px, sudut membulat 48 px untuk kartu.
  TANPA bayangan, TANPA gradien mencolok, TANPA glow, TANPA efek 3D,
  TANPA stok foto. Tenang dan lapang — audiensnya pengasuh yang lelah dan
  anak dengan sensitivitas sensorik.

TATA LETAK dari atas ke bawah
  1. Sudut KIRI ATAS: tiga logo sebaris — Institut Teknologi Sepuluh
     Nopember, HIMASIF, IT CONVERT 2026. Sisakan ruang; saya sisipkan
     berkas logonya sendiri.
  2. Judul "DekapAutis" besar, subjudul, nama tim "Fable 5 Enjoyer —
     Institut Teknologi Sepuluh Nopember", dua nama anggota.
  3. Dua kolom berdampingan: MASALAH dan SOLUSI.
  4. Diagram lingkaran alur pengguna berlabel, enam simpul:
     Profil anak → Rencana mingguan → Jalankan & catat respons →
     Rencana menyesuaikan diri → Bagikan laporan → Tanggapan profesional,
     lalu kembali ke Rencana mingguan. Anak panah balik diberi label
     "tanggapan kembali mengubah rencana". Ini elemen terpenting poster.
  5. Diagram alir pipeline AI tiga lapis, dari atas ke bawah, dengan dua
     cabang penolakan ke samping.
  6. Empat mockup layar ponsel sejajar dengan ukuran sama.
  7. Tiga kolom: TUJUAN, MANFAAT, FITUR UTAMA.
  8. Baris angka statistik dan tagar #ITC2026 #SOFTDEV.

PENEKANAN — dua diagram itu bersama-sama menyumbang bobot penilaian
terbesar. Beri keduanya sekitar 35% tinggi poster. Jangan biarkan deretan
mockup memakan ruangnya.

Alur baca harus satu arah dan mudah dinavigasi. Margin tepi minimal 15 mm.
Teks isi tidak boleh di bawah 24 pt.
```

---

## 7. Sebelum diunggah — periksa ini

- [ ] Ukuran piksel tepat 3508 × 4961 (A3, 300 ppi)
- [ ] Metadata resolusi tertulis 300 ppi, bukan 72
- [ ] Tiga logo ada, di **kiri atas**
- [ ] Judul, nama tim, tujuan, manfaat, fitur, mockup — semuanya ada
- [ ] Tidak ada `#F2E8F6`, `#E4CEEC`, `#CA9CDB`, atau `#EDDFBC` sebagai warna teks
- [ ] Tidak ada warna di luar keluarga ungu dan krem
- [ ] Setiap angka dapat ditelusuri asalnya
- [ ] Tidak ada klaim medis: tidak ada kata "sembuh", "terapi medis", "diagnosis",
      atau tingkat/derajat autisme
- [ ] Ejaan "Fable 5 Enjoyer" dan "DekapAutis" konsisten dengan proposal
- [ ] Caption Instagram memuat deskripsi produk, tandai @itconvert_unej dan
      anggota tim, tagar #ITC2026 #SOFTDEV
