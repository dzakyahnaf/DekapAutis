# 07 — Data Demo dan Katalog Aktivitas

Berkas ini mengamankan bobot penilaian **Cara Penggunaan 30%** — bobot terbesar kedua pada rubrik Prototype. Aplikasi yang dibuka dengan basis data kosong kehilangan poin di sana, sebagus apa pun kodenya.

Prinsipnya sederhana: **juri harus bisa melihat produk yang sudah dipakai empat minggu, bukan produk yang baru dipasang.**

---

## 1. Akun demo

| Peran | Email | Kata sandi | Isi |
|---|---|---|---|
| Pengasuh | `demo@dekapautis.id` | `DemoDekap2026` | Rina Kartika, anak Bima, riwayat 4 minggu |
| Profesional | `demo.profesional@dekapautis.id` | `DemoDekap2026` | Dra. Sari Wulandari, sudah terverifikasi, punya 1 laporan masuk |
| Admin | `demo.admin@dekapautis.id` | `DemoDekap2026` | Antrean verifikasi berisi 2 pengajuan |

Tombol **"Masuk sebagai demo"** di layar masuk mengisi kredensial pengasuh secara otomatis. Kredensial ketiganya juga ditulis di `README.md` repositori.

Setiap akun demo punya `adalah_demo = true`, dan aplikasi menampilkan keping kecil **"Akun demo"** di header profil. Data ini sintetis dan harus terlihat sebagai data sintetis — jangan menyamarkannya sebagai pengguna nyata.

---

## 2. Profil demo

**Rina Kartika**, pengasuh. **Bima**, 6 tahun.
- Kemampuan komunikasi: `beberapa_kata`
- Sensitivitas sensorik: `suara_keras`, `cahaya_terang`
- Fokus perkembangan: komunikasi ekspresif, kemandirian rutinitas pagi

Persona ini sudah dipakai di Bab IX proposal dan di seluruh mockup. **Pertahankan konsistensinya** — juri akan mencocokkan aplikasi dengan proposal, dan nama yang berbeda menimbulkan keraguan yang tidak perlu.

---

## 3. Riwayat empat minggu

Bukan data acak. Riwayat ini dirancang supaya setiap fitur punya sesuatu untuk ditampilkan.

**Volume:** 4 minggu × 5 aktivitas/hari × 7 hari ≈ 140 jadwal, dengan **86% tercatat** (sesuai angka pada mockup L.8), menghasilkan sekitar 120 catatan respons.

**Bentuk tren yang harus terlihat:**

| Kategori | Minggu 1 → 4 | Alasan dirancang begitu |
|---|---|---|
| Komunikasi | 45% → 78%, naik konsisten | Menunjukkan aturan `A_naik` dan `C_porsi` bekerja; grafik tren L.8 punya kemiringan yang jelas |
| Motorik | 60% → 65%, datar | Kontras terhadap kategori yang bergerak |
| Sensorik | 55% → 52%, sedikit turun | Memberi variasi realistis |
| Kemandirian | 68% → 71%, naik landai | — |
| **Sosial** | **52% → 40%, turun 2 periode berturut** | **Memicu aturan `D_tandai`** sehingga penanda `perhatian` benar-benar muncul di laporan dan di kotak masuk profesional |

Kategori Sosial sengaja dibuat menurun. Tanpa itu, penanda perhatian tidak pernah tampil, mesin adaptasi terlihat hanya bisa memuji, dan salah satu fitur terbaik Anda tidak terlihat oleh juri.

**Waktu pelaksanaan:** condongkan respons "mudah" ke blok jam 08.00–09.00 supaya aturan `E_jadwal` punya dasar dan menghasilkan alasan penjadwalan yang nyata.

**Check-in pengasuh:** 28 baris, kebanyakan 3–4, dengan beberapa hari bernilai 2 pada minggu ketiga. Ini membuat pola kelelahan pengasuh terlihat, yang merupakan salah satu masalah yang Anda angkat di Bab II.

**Catatan adaptasi:** minimal 5 baris `adaptasi_log`, mencakup keempat aturan yang menghasilkan perubahan terlihat, masing-masing dengan alasan Bahasa Indonesia yang menyebut angka nyata.

---

## 4. Konten demo lainnya

**Laporan:** satu laporan periode 1 bulan yang sudah dibuat dan **sudah dibagikan** ke Dra. Sari Wulandari, dengan izin berbagi berstatus aktif. Satu laporan lain yang belum dibagikan, supaya alur berbagi bisa didemonstrasikan langsung di video.

**Direktori:** minimal 15 tenaga profesional di area Surabaya dengan koordinat nyata agar perhitungan jarak masuk akal. Nama boleh fiktif — ini direktori demo, bukan klaim faktual — tetapi **beri catatan di README** bahwa data direktori adalah contoh dan bukan daftar praktisi sungguhan. Jangan mencantumkan nama praktisi nyata tanpa izin.

**Komunitas:** 8 postingan dengan balasan, 2 di antaranya anonim, mencakup topik yang tampil di mockup L.11 — rutinitas pagi, menjelaskan kondisi anak ke guru, tempat istirahat sensorik.

**Pustaka:** minimal 12 artikel yang menunjuk ke dokumen basis pengetahuan **yang nyata**, dengan status tinjauan bervariasi. Berbeda dengan direktori, isi pustaka tidak boleh fiktif — ini konten kesehatan yang akan dibaca.

**Notifikasi:** 5 notifikasi mencakup kelima jenis, dua di antaranya belum dibaca.

---

## 5. Aturan penyusunan katalog aktivitas

Minimal **60 aktivitas**: 5 kategori × 4 tingkat × 3 varian.

Setiap aktivitas wajib punya:
- **Judul** yang menyatakan tindakan konkret: "Menamai benda di meja makan", bukan "Latihan komunikasi"
- **Tujuan** satu kalimat yang menyebut perilaku yang dilatih
- **Durasi** 5–20 menit, naik seiring tingkat
- **Alat** yang tersedia di rumah biasa. Jangan pernah mensyaratkan alat terapi khusus atau yang harus dibeli — Bab II Anda mengangkat masalah biaya, jadi menuntut alat berbayar merusak argumen produknya
- **3–6 langkah** yang bisa diikuti pengasuh tanpa pelatihan
- **`saran_lingkungan`** yang dipakai mesin adaptasi saat menurunkan tingkat

**Batas isi yang tidak boleh dilanggar:**
- Aktivitas adalah stimulasi harian di rumah, **bukan protokol terapi klinis**
- Jangan menamai metode terapi berlisensi seolah aplikasi menjalankannya
- Jangan menjanjikan hasil perkembangan tertentu dalam jangka waktu tertentu
- Jangan memuat unsur pengekangan, penghukuman, atau penahanan respons anak
- Bahasa langkah menyebut anak dengan nama panggilannya, bukan "si anak" atau "pasien"

**Contoh yang benar:**
```yaml
kategori: komunikasi
tingkat: 2
judul: "Menamai benda di meja makan"
tujuan: "Melatih Bima menyebutkan nama benda yang sedang ia lihat, tanpa didahului pertanyaan."
durasi_menit: 10
alat: ["Piring", "Gelas", "Sendok"]
langkah:
  - "Duduk sejajar dengan Bima, bukan di seberang meja."
  - "Tunjuk satu benda dan tunggu 5 detik tanpa bicara."
  - "Jika Bima belum merespons, sebutkan namanya sekali dengan jelas."
  - "Beri jeda, lalu ulangi dengan benda berikutnya."
saran_lingkungan: "Matikan televisi dan kurangi benda di atas meja menjadi tiga saja."
```

---

## 6. Skrip seed

`supabase/seed/seed.sql` atau `scripts/seed_demo.ts`, dan harus:

- **Idempoten.** Jalankan dua kali tidak menggandakan apa pun
- **Berbasis tanggal relatif.** Hitung mundur dari `now()`, jangan tulis tanggal absolut. Kalau juri membuka aplikasi tanggal 8 September dan laporan berakhir 4 Agustus, produknya terlihat mati
- **Bisa direset.** Sediakan `scripts/reset_demo.ts` yang mengembalikan akun demo ke keadaan awal, supaya Anda bisa merekam ulang video tanpa membangun ulang basis data
- Dijalankan otomatis oleh `supabase db reset` untuk pengembangan lokal

Poin tanggal relatif itu penting dan mudah terlewat. Jalankan seed ulang lewat cron mingguan selama masa penjurian, atau hitung offset saat baca — apa pun caranya, pastikan data demo tidak pernah terlihat basi.

---

## 7. Tur pertama kali

Empat sorotan singkat di beranda, muncul sekali, bisa dilewati kapan saja:

1. "Ini rencana hari ini. Setiap aktivitas punya panduan langkahnya."
2. "Setelah selesai, tandai responsnya. Catatan ini yang menyesuaikan rencana besok."
3. "Punya pertanyaan? Tanya Dekap menjawab dari dokumen yang bisa Anda buka sendiri."
4. "Menjelang jadwal terapi, buat laporan dan bagikan ke tenaga profesional."

Statis, tanpa animasi, tombol "Lewati" terlihat sejak sorotan pertama. Simpan status "sudah dilihat" di lokal, dan sediakan "Ulangi tur" di layar Cara pakai supaya Anda bisa merekamnya berulang kali untuk video.
