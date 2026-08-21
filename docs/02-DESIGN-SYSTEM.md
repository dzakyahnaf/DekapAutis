# 02 — Sistem Desain → Flutter

Token ini diambil dari Tabel E.1 proposal final dan `DESIGN-SYSTEM.md` Tahap 1. **Ini bukan saran, ini kontrak.** Setiap nilai warna, ukuran, dan jarak dalam kode harus merujuk ke `tokens.dart`, tidak boleh ada nilai literal yang tersebar di widget.

---

## 1. Prinsip yang menurunkan setiap keputusan

| # | Prinsip | Konsekuensi teknis |
|---|---|---|
| 1 | **Prediktabilitas di atas kebaruan** | Elemen yang sama muncul di posisi, bentuk, dan warna yang sama di semua layar. `RoutineCard` punya anatomi identik di mana pun |
| 2 | **Rendah stimulus** | Saturasi rendah, tanpa gradasi, tanpa pola bergerak, tanpa latar krem terang sebagai permukaan besar (memantulkan cahaya) |
| 3 | **Satu layar, satu keputusan** | Maksimal 3 aksi utama per layar |
| 4 | **Transparansi sumber** | Setiap keluaran AI menampilkan asal informasinya, bisa ditekan |
| 5 | **Batas yang terlihat** | Batas kemampuan sistem tampil menonjol, bukan tersembunyi di catatan kaki |

---

## 2. Warna

Hanya **dua keluarga**: ungu dan krem. Tidak ada biru, hijau, merah, oranye, atau abu-abu netral murni. Netral pun berpigmen ungu.

```dart
// core/theme/tokens.dart
abstract final class DekapColors {
  // Dasar
  static const surface       = Color(0xFFFFFFFF); // permukaan kartu
  static const background    = Color(0xFFF2E8F6); // latar aplikasi
  static const border        = Color(0xFFD8C6E0); // garis 1px
  static const textPrimary   = Color(0xFF4A2657); // kontras 12,3:1
  static const textSecondary = Color(0xFF6B5F73); // netral berpigmen, 5,9:1

  // Ungu — jalur sistem dan kecerdasan artifisial
  static const purple700 = Color(0xFF7B4490); // utama, aman untuk teks 6,8:1
  static const purple500 = Color(0xFFA96CC0); // sekunder
  static const purple300 = Color(0xFFCA9CDB); // bidang
  static const purple100 = Color(0xFFE4CEEC); // bidang

  // Krem — jalur manusia (kondisi pengasuh, komunitas)
  static const cream700 = Color(0xFF6F5722); // aman untuk teks 6,8:1
  static const cream400 = Color(0xFFD9BE7E); // aksen
  static const cream200 = Color(0xFFEDDFBC); // bidang
  static const cream50  = Color(0xFFFBF6EA); // bidang

  // Batas medis — TIDAK DIPAKAI UNTUK KEPERLUAN LAIN
  static const boundary = Color(0xFF4A2657);
}
```

**Dua jalur semantik.** Ungu menandai jalur sistem dan AI: asisten, laporan, direktori, rencana. Krem menandai jalur manusia: check-in kondisi pengasuh, komunitas. Pengkodean ini menyatakan bahwa aplikasi punya dua pihak yang didampingi — anak *dan* pengasuh.

**Larangan warna:**
1. Hue di luar ungu dan krem
2. `#F2E8F6`, `#E4CEEC`, `#CA9CDB`, `#EDDFBC` sebagai warna teks — kontrasnya gagal
3. `#4A2657` dengan garis tebal untuk elemen selain batas medis
4. Gradasi, glassmorphism, bayangan berwarna
5. Kategori atau status yang hanya dibedakan warna tanpa ikon dan label

### Kategori aktivitas

| Kategori | Warna | Ikon (Material Symbols Rounded) |
|---|---|---|
| Komunikasi | `#7B4490` | `chat_bubble` |
| Motorik | `#A96CC0` | `directions_run` |
| Sensorik | `#CA9CDB` | `blur_on` |
| Kemandirian | `#D9BE7E` | `accessibility_new` |
| Sosial | `#6F5722` | `groups` |

Warna **tidak pernah** menjadi satu-satunya pembawa makna. Setiap kategori selalu tampil dengan ikon **dan** label teks.

### Catatan kritis soal ketiadaan merah

Palet ini tidak punya merah, sementara pemberitahuan batas medis adalah elemen paling penting di aplikasi. Kompensasinya harus konsisten dan tidak boleh dikurangi:

- Warna **tergelap dalam sistem** (`#4A2657`)
- Garis **2,4 px** — paling tebal di seluruh aplikasi
- **Ikon perisai** (`shield`)
- **Label tebal eksplisit** yang menyatakan penolakan, bukan eufemisme

Kalau juri bertanya kenapa tidak ada merah, jawabannya: merah memicu respons kewaspadaan yang tidak diinginkan pada pengguna dengan sensitivitas sensorik, dan aplikasi kerap dibuka saat anak ikut melihat layar. Bobot visual dicapai lewat kegelapan, ketebalan, dan ikon.

---

## 3. Tipografi

```dart
abstract final class DekapType {
  static const family     = 'LexendDeca';  // judul dan isi
  static const familyMono = 'IBMPlexMono'; // angka pada laporan

  // ukuran dalam logical pixels
  static const displayTitle = 24.0; // judul layar, berat 600
  static const sectionTitle = 19.0; // judul bagian, berat 600
  static const bodyLarge    = 17.0;
  static const bodyDefault  = 15.0;
  static const caption      = 13.0;
}
```

Lexend Deca dipilih bukan karena estetika — sumbu lebarnya memang dirancang untuk mengurangi *visual crowding* saat membaca. Ini poin yang bisa Anda pertahankan di sesi tanya jawab.

Rata kiri. Tanpa huruf kapital semua. Tinggi baris 1,5 untuk isi.

**Bundel font sebagai aset lokal** di `assets/fonts/`. Jangan mengandalkan unduh runtime — aplikasi harus tampil benar saat luring. Keduanya berlisensi SIL Open Font License 1.1, sekaligus memenuhi ketentuan lisensi aset.

---

## 4. Ruang, bentuk, ukuran

```dart
abstract final class DekapSpace {
  static const screenPadding = 20.0; // padding tepi layar
  static const cardGap       = 12.0; // jarak antar kartu
  static const cardPadding   = 16.0;
  static const radiusCard    = 16.0;
  static const radiusControl = 12.0;
  static const buttonHeight  = 52.0;
  static const minTouch      = 48.0; // tidak boleh ada yang di bawah ini
  static const iconSize      = 24.0;
  static const borderWidth   = 1.0;
  static const boundaryBorderWidth = 2.4; // hanya untuk batas medis
}
```

Utamakan **garis tipis, bukan bayangan**. Elevation Material default harus dimatikan.

---

## 5. Empat elemen penanda khas

Keempatnya harus punya widget bersama sendiri dan dipakai konsisten:

**`RoutineCard`** — anatomi tetap: nomor urut ("1 dari 5"), waktu dan durasi, batang warna kategori di tepi kiri, ikon + judul aktivitas, label kategori, lalu tiga tombol respons **Mudah / Pas / Sulit** dengan lebar sama. Anatominya identik di beranda maupun di layar rencana.

**`SourceChip`** — keping bernomor kecil yang bisa ditekan, membuka Panel Sumber. Nomor merujuk ke urutan sumber dalam jawaban.

**`SafetyBanner`** — pita batas aman. Ungu tergelap, garis 2,4 px, ikon perisai, judul tebal.

**`CalmModeSwitch`** — sakelar Mode Tenang. Saat aktif, pil kecil "Mode Tenang aktif" muncul di header agar keadaannya tidak tersembunyi.

---

## 6. Gerak

Satu-satunya aturan yang perlu diingat: **tidak ada animasi berulang, dalam bentuk apa pun.**

- Tanpa skeleton shimmer — loading memakai teks statis ("Menyiapkan rencana hari ini…")
- Tanpa carousel otomatis, tanpa pulsing, tanpa loop
- Transisi halaman maksimal 200 ms, kurva sederhana
- Saat Mode Tenang aktif atau sistem meminta kurangi gerak: **seluruh transisi menjadi 0 ms**

Ini keputusan berisiko secara estetika dan disengaja. Pola bergerak berulang adalah pemicu beban sensorik, dan aplikasi ini kerap dibuka saat anak turut melihat layar.

---

## 7. Aksesibilitas sebagai bagian dari sistem

- Seluruh target sentuh ≥ 48×48 dp
- Fokus keyboard atau switch terlihat: garis 2 px `purple700` dengan offset 2 px
- Setiap gambar punya teks alternatif
- Penskalaan teks sistem sampai 200% tanpa layout rusak — gunakan `Flexible`/`Wrap`, hindari tinggi tetap pada wadah berisi teks
- Kontras memenuhi WCAG 2.2 AA

**Skrip audit wajib.** Tulis test yang membaca setiap pasangan latar–teks di `tokens.dart`, menghitung rasio kontras, dan **gagal** bila ada yang di bawah ambang. Ini mengubah aksesibilitas dari niat menjadi jaring pengaman.

---

## 8. Mode Tenang — fitur, bukan setelan

Sakelar di Profil yang mengubah aplikasi secara menyeluruh. Kelima efek ini aktif serentak:

1. Seluruh gambar dan ilustrasi disembunyikan, diganti label teks
2. Saturasi warna kategori diturunkan ke tint saja
3. Spasi antar elemen naik satu tingkat
4. Notifikasi non-kritis dibisukan
5. Seluruh transisi menjadi 0 ms

Implementasikan sebagai `CalmModeProvider` yang dibaca `ThemeData` dan widget bersama — bukan sebagai serangkaian `if` yang tersebar di setiap layar.

---

## 9. Nada bahasa

- Bahasa Indonesia baku tapi hangat. Sapaan **"Anda"**
- Jangan pernah menyebut anak "penderita" atau "penyandang"
- Tombol memakai kata kerja hasil: "Simpan catatan", bukan "Kirim"
- Nama aksi konsisten sepanjang alur: tombol "Buat laporan" menghasilkan pesan "Laporan dibuat"
- Kondisi kosong adalah ajakan: "Belum ada catatan minggu ini. Catat satu aktivitas untuk mulai melihat polanya."
- Error menjelaskan apa yang terjadi dan langkah berikutnya. Tidak minta maaf, tidak menyalahkan pengguna
- Tanpa bahasa pemasaran, tanda seru berlebihan, atau nada menyemangati berlebihan

Kumpulkan seluruh string di satu berkas `core/strings.dart` supaya konsistensinya bisa diperiksa sekaligus.
