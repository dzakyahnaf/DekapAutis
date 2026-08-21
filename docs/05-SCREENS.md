# 05 — Spesifikasi Layar

17 layar pengasuh sesuai Lampiran A proposal, plus layar peran profesional dan administrator yang dibutuhkan agar tiga aktor pada Gambar 6.1 benar-benar terimplementasi.

Setiap layar wajib memakai widget bersama dari `docs/02-DESIGN-SYSTEM.md`. Maksimal **3 aksi utama** per layar.

---

## Navigasi utama

Bilah bawah 5 tab, ikon **selalu disertai label**: Beranda · Rencana · Tanya · Komunitas · Profil.

Rute go_router:
```
/splash  /masuk  /daftar  /onboarding/:langkah
/beranda  /rencana  /rencana/aktivitas/:id
/tanya  /tanya/sumber/:jawabanId
/komunitas  /komunitas/:postId
/profil  /profil/laporan  /profil/laporan/:id
/profil/aksesibilitas  /profil/izin  /profil/cara-pakai
/direktori  /direktori/:id
/pustaka  /pustaka/:id
/notifikasi
/profesional/masuk-kotak  /profesional/laporan/:id  /profesional/profil
/admin/verifikasi  /admin/pengetahuan  /admin/moderasi
```

Rute bernama dipakai untuk skenario demo di video — Anda bisa melompat langsung ke layar tanpa menavigasi manual.

---

## Layar pengasuh

### L.13 Layar Pembuka (`/splash`, P2)
Nama produk, tagline "Pendamping keluarga anak dengan spektrum autisme", bilah progres **statis**, teks pemuatan "Menyiapkan rencana hari ini…". Memuat sesi lalu mengarah ke `/beranda` atau `/masuk`.

### L.14 Masuk (`/masuk`, P2)
Email, kata sandi dengan toggle lihat, lupa kata sandi, tombol Masuk, pemisah "atau", Masuk dengan Google, tautan Daftar.

**Tambahan wajib yang tidak ada di mockup:** tombol **"Masuk sebagai demo"**. Ini yang mengamankan bobot Cara Penggunaan 30% — juri tidak perlu mendaftar. Beri label jelas bahwa akun ini berisi data contoh.

### L.1 Onboarding Profil Anak (`/onboarding/:langkah`, P0)
Empat langkah, indikator progres 4 segmen statis.
1. Nama panggilan anak, usia
2. Kemampuan komunikasi (pilih satu: Belum verbal / Beberapa kata / Kalimat pendek / Lancar), sensitivitas sensorik (pilih semua: Suara keras / Cahaya terang / Tekstur / Keramaian / Bau)
3. Fokus perkembangan tiga bulan ke depan
4. Preferensi aksesibilitas (= L.15)

Sub-teks di bawah judul: "Jawaban Anda dipakai untuk menyusun rencana harian. Bisa diubah kapan saja."
Pita privasi melekat di atas tombol: ikon gembok + "Data anak dienkripsi dan tidak dibagikan tanpa izin Anda."

### L.2 Beranda (`/beranda`, P0)
- Sapaan berdasarkan waktu + nama pengasuh, tanggal, ikon notifikasi dengan penanda
- **Kartu check-in kondisi pengasuh** (jalur krem `#EDDFBC`): "Bagaimana kondisi Anda hari ini?" dengan lima tingkat berlabel Berat / Lelah / Biasa / Cukup baik / Baik, plus catatan "Hanya untuk Anda, tidak dibagikan" (KF-13)
- Judul "Rencana hari ini" + tautan Lihat semua
- Daftar `RoutineCard` dengan tombol respons Mudah / Pas / Sulit

### L.6 Rencana Stimulasi Mingguan (`/rencana`, P0)
- Judul + rentang tanggal, ikon filter
- Pemilih hari 7 kolom, hari terpilih ditandai isi ungu
- **Kartu penjelasan penyesuaian**: ikon percikan, kalimat alasan dari `adaptasi_log`, keterangan "Disesuaikan otomatis · [tanggal]", tombol koreksi manual
- Daftar `RoutineCard`; kartu yang sudah dicatat menampilkan centang dan tombol respons terpilih dalam keadaan aktif

### L.7 Detail Aktivitas dan Catatan Respons (`/rencana/aktivitas/:id`, P0)
Keping kategori di header, judul aktivitas, meta (durasi, waktu pelaksanaan, "Tingkat 2 dari 4"), bagian Tujuan, Yang perlu disiapkan (daftar), Langkah (bernomor dalam kotak).
**Pita catatan respons melekat di bawah layar**, tidak ikut tergulir: "Bagaimana respons [nama anak]?" dengan tiga tombol lebar sama + "Tambah catatan (opsional)".

### L.3 Tanya Dekap (`/tanya`, P0)
Percakapan, ikon riwayat di kanan atas. Gelembung pengguna rata kanan bidang `#E4CEEC`; jawaban asisten rata kiri dengan batang ungu di tepi kiri. Jawaban memuat keping rujukan bernomor yang bisa ditekan. Kolom input melekat di bawah.
Saat memuat: teks statis "Menyusun jawaban…", **bukan** animasi.
Saat mode terbatas: pita "Sumber ditampilkan tanpa rangkuman. Layanan sedang terbatas."

### L.4 Panel Sumber (`/tanya/sumber/:jawabanId`, P0)
Lembar bawah. Judul "Sumber jawaban" + tombol tutup. Setiap sumber: keping nomor, judul dokumen, baris meta `Penerbit · Tahun · Halaman`, kutipan asli dalam huruf miring dengan garis tepi kiri, tautan "Buka sumber asli".
Baris kaki: "DekapAutis hanya menjawab dari **N** dokumen yang telah ditinjau tenaga profesional." — **N dihitung dari basis data**, bukan angka tetap.

### L.5 Pemberitahuan Batas Aman (`/tanya`, keadaan khusus, P0)
Kartu batas: latar `#E4CEEC`, garis **2,4 px** `#4A2657`, ikon perisai, judul tebal "DekapAutis tidak dapat mendiagnosis", isi yang menjelaskan mengapa.
Di bawahnya kartu "Yang bisa saya bantu" berisi tiga butir bercentang.
Catatan kaki: "Disusun AI dari sumber terverifikasi. Bukan pengganti konsultasi profesional."
Dua tombol: **Lihat profesional terdekat** (utama) dan **Buat laporan untuk dokter** (sekunder).

Ini elemen terpenting di seluruh aplikasi. Jangan pernah mengurangi bobot visualnya.

### L.8 Laporan Perkembangan (`/profil/laporan`, P0)
Judul + nama anak dan periode, ikon unduh. Pemilih periode 2 minggu / 1 bulan / 3 bulan. Tiga kartu metrik (angka besar memakai IBM Plex Mono). Grafik tren "Mudah" per minggu dengan `CustomPainter`, tanpa animasi masuk. Rincian per kategori berupa batang horizontal + persentase, setiap baris dengan titik warna **dan** label. Kotak "Ringkasan untuk terapis" berisi narasi. Tombol ekspor PDF dan bagikan.

### L.9 Direktori Profesional (`/direktori`, P1)
Kolom lokasi, filter jenis layanan (Semua / Terapis wicara / Terapis okupasi / Psikolog anak / Dokter tumbuh kembang), penghitung hasil, kartu profesional berisi inisial, nama, spesialisasi, jarak, hari praktik, lencana Terverifikasi, tombol Lihat profil.
Jarak dihitung **Haversine di klien** dari koordinat tersimpan. Tanpa SDK peta berbayar.

### L.10 Detail Profesional (`/direktori/:id`, P1)
Header dengan inisial, nama, gelar, spesialisasi, lencana. Bagian Tentang, Layanan (keping), Jadwal praktik (tabel hari–jam). Dua tombol melekat di bawah: **Ajukan jadwal konsultasi** dan **Kirim laporan [nama anak]**.
Pengajuan jadwal hanya mencatat permintaan dan memberi notifikasi. **Tanpa pembayaran, tanpa sesi di dalam aplikasi** — Bab 4.1 melarangnya.

### L.11 Komunitas (`/komunitas`, P1 · jalur krem)
Filter topik, pita "Dimoderasi relawan dan tenaga profesional", kartu diskusi berisi judul, cuplikan, penulis (inisial atau keping "Anonim"), jumlah balasan, waktu relatif. Tombol tulis mengambang di kanan bawah.

### L.12 Pustaka Edukasi (`/pustaka`, P1)
Kolom pencarian, empat kartu kategori (Terapi di rumah, Manajemen perilaku, Nutrisi, Kesehatan mental orang tua), bagian "Terbaru ditinjau" berisi kartu artikel dengan ikon jenis, judul, `Penerbit · durasi baca`, dan keping status tinjauan.

### L.15 Preferensi Aksesibilitas (`/profil/aksesibilitas`, P2)
Kartu Mode Tenang dengan sakelar dan penjelasan tiga efeknya. Ukuran teks tiga pilihan dengan **kotak pratinjau langsung** yang benar-benar berubah. Kartu Kurangi gerakan dengan sakelar dan keterangan "Semua transisi menjadi 0 milidetik."

### L.16 Profil dan Privasi (`/profil`, P2)
Header pengguna, keping status Mode Tenang. Bagian Profil anak (daftar, bisa lebih dari satu). Bagian **Privasi data**: Kelola izin berbagi data, Unduh salinan data saya, Hapus akun dan seluruh data. Bagian Aplikasi: Preferensi aksesibilitas, Notifikasi, Cara pakai, Tentang & sumber pustaka.

Penghapusan akun butuh konfirmasi ketik ulang dan **benar-benar menghapus baris**, bukan menandai.

### L.17 Notifikasi (`/notifikasi`, P2)
Dikelompokkan Hari ini / Kemarin / Minggu ini. Setiap baris: ikon jenis dalam bidang berwarna, judul, waktu, titik belum dibaca. Jenis: penyesuaian rencana, aktivitas belum dicatat, balasan komunitas, artikel baru ditinjau, persetujuan jadwal.

---

## Layar tambahan yang tidak ada di mockup tapi wajib ada

### Daftar (`/daftar`)
Nama, email, kata sandi, pilih peran (Orang tua atau pengasuh / Tenaga profesional), persetujuan kebijakan privasi.

### Cara pakai (`/profil/cara-pakai`)
Meringkas enam langkah alur pada Bab IX proposal, dengan tautan ke layar terkait. Ini yang dibaca juri kalau mereka bingung — jangan lewatkan.

### Kotak masuk profesional (`/profesional/masuk-kotak`)
Daftar laporan yang dibagikan, penanda `perhatian` dari mesin adaptasi terlihat jelas, urut berdasarkan yang belum ditanggapi.

### Detail laporan profesional (`/profesional/laporan/:id`)
Tampilan laporan yang sama dengan L.8 dalam keadaan hanya-baca, plus form tanggapan. Tanggapan yang terkirim muncul di sisi pengasuh dan menutup lingkaran alur bisnis Gambar 7.1.

### Admin (`/admin/*`)
Tiga layar sederhana: antrean verifikasi profesional (setujui/tolak dengan alasan), pengelolaan dokumen basis pengetahuan (unggah, tandai status tinjauan, picu indexing ulang), antrean moderasi komunitas.

Tidak perlu indah. Perlu ada dan berfungsi — Kelengkapan berbobot 20%, dan tiga aktor yang tergambar di proposal tapi hanya satu yang terimplementasi adalah celah yang mudah ditanyakan juri.

---

## Keadaan yang sering terlupa

Untuk **setiap** layar yang mengambil data, tiga keadaan ini wajib dirancang, bukan dibiarkan default:

| Keadaan | Perilaku |
|---|---|
| Memuat | Teks statis, tanpa shimmer |
| Kosong | Ajakan, bukan permintaan maaf. "Belum ada catatan minggu ini. Catat satu aktivitas untuk mulai melihat polanya." |
| Gagal | Menjelaskan apa yang terjadi dan langkah berikutnya, dengan tombol coba lagi. Tidak minta maaf, tidak menyalahkan pengguna, tidak menampilkan pesan Inggris mentah |

Widget `EmptyState` dan `ErrorState` bersama sudah menangani ini — pakai, jangan tulis ulang per layar.
