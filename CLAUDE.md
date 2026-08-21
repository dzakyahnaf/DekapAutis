# CLAUDE.md — DekapAutis

Berkas ini dibaca otomatis setiap sesi Claude Code. Isinya aturan yang tidak boleh dilanggar.
Rencana kerja bertahap ada di `PLAN.md`. Spesifikasi rinci ada di `docs/`.

---

## Konteks

**Produk:** DekapAutis — aplikasi pendamping berbasis kecerdasan artifisial untuk orang tua dan pengasuh anak dengan spektrum autisme.
**Tim:** Fable 5 Enjoyer — Institut Teknologi Sepuluh Nopember, Surabaya.
- Muhammad Dzaky Ahnaf (5027231039) — ketua, backend + AI
- Diffa Adzra Anelya (5051231021) — UI + klien Flutter

**Kompetisi:** IT CONVERT 2026, bidang Software Development, HIMASIF Universitas Jember.
Tema: *Empowering Society Through AI-Based Innovation*. Sub-tema: **AI in Health and Well-being**.
Tahap 2 (Prototype + Poster + Video) — batas unggah **1 September 2026 23.59 WIB**, penjurian 2–11 September 2026.

**Sumber kebenaran:** proposal final `ITC2026_SOFTDEV_Proposal_Fable_5_Enjoyer.pdf`.
Rulebook Tahap 2 butir 4 mewajibkan desain produk dan fiturnya **sesuai dengan produk yang telah dirancang sebelumnya**. Setiap penyimpangan dari proposal harus dicatat di `docs/DEVIATIONS.md` beserta alasannya — jangan menyimpang diam-diam.

---

## Aturan mutlak

### 1. Batas medis tidak boleh dilanggar
Aplikasi ini **tidak mendiagnosis, tidak menilai tingkat keparahan spektrum, tidak menganjurkan obat atau dosis**. Ini bukan disclaimer, ini mekanisme teknis berlapis (lihat `docs/04-AI-PIPELINE.md`).
Jangan pernah menulis kode, prompt, konten seed, atau teks UI yang:
- memberi label derajat/tingkat autisme pada anak
- menyarankan obat, suplemen, dosis, atau diet sebagai terapi medis
- menghasilkan skor tunggal atas kemampuan anak yang bisa disalahartikan sebagai hasil klinis
- mengklaim kesembuhan atau menyebut autisme sebagai penyakit yang disembuhkan

### 2. Tidak ada data karangan yang disajikan sebagai fakta
- Setiap dokumen basis pengetahuan wajib punya sumber nyata yang bisa dibuka. Tidak boleh ada dokumen fiktif.
- Angka apa pun yang tampil di UI (jumlah dokumen, jumlah profesional, statistik) **dihitung dari basis data**, bukan hardcode.
  Catatan: mockup L.4 di proposal menulis "148 dokumen". Angka itu harus diganti hitungan riil `COUNT(*)` dari tabel `dokumen_pengetahuan`. Kalau korpus Anda 60 dokumen, tulis 60.
- Data demo (Rina & Bima) adalah data sintetis yang **ditandai jelas sebagai demo di dalam aplikasi**, bukan disamarkan sebagai pengguna nyata.

### 3. Bahasa
- Seluruh teks antarmuka **100% Bahasa Indonesia**. Tidak ada string Inggris yang bocor ke UI.
- Sapaan **"Anda"**. Jangan "kamu", jangan "bunda" (pengguna mencakup ayah, pengasuh, dan guru pendamping).
- Jangan pernah menyebut anak "penderita" atau "penyandang". Gunakan **"anak"** atau **"anak dengan spektrum autisme"**.
- Tombol memakai kata kerja hasil: "Simpan catatan", bukan "Kirim".
- Pesan kosong adalah ajakan, bukan permintaan maaf.
- Pesan error menjelaskan apa yang terjadi dan langkah berikutnya. Tidak minta maaf, tidak menyalahkan pengguna.
- Kode, komentar, nama variabel, dan pesan commit dalam Bahasa Inggris. Hanya string yang dilihat pengguna yang Bahasa Indonesia.

### 4. Rahasia tidak pernah menyentuh perangkat
Kunci API model bahasa **hanya** hidup di Supabase Edge Function secrets. Tidak pernah di `pubspec.yaml`, `.env` yang di-commit, `--dart-define` yang masuk APK, atau kode klien. KNF-03 mensyaratkan ini. Kalau Anda menemukan kunci di sisi klien, itu bug tingkat blocker.
`.env` dan `*.keystore`/`*.jks` wajib ada di `.gitignore` sejak commit pertama.

### 5. Aksesibilitas bukan tugas akhir
Setiap widget yang Anda tulis harus sudah memenuhi ini saat ditulis, bukan diperbaiki nanti:
- Target sentuh minimum **48×48 dp**
- Kontras teks memenuhi **WCAG 2.2 AA** (4.5:1 teks normal, 3:1 teks besar)
- Setiap ikon bermakna punya label teks atau `Semantics(label:)`
- Layout tidak rusak saat penskalaan teks sistem 200%
- Menghormati `MediaQuery.disableAnimations` / `reduce motion`

### 6. Tanpa animasi berulang
Tidak ada skeleton shimmer, carousel otomatis, pulsing, atau loop animasi apa pun. Pola bergerak berulang adalah pemicu beban sensorik. Loading memakai teks statis. Transisi halaman maksimal 200ms, dan menjadi 0ms saat Mode Tenang aktif.

### 7. Degradasi anggun, bukan crash
Aplikasi ini akan dinilai juri sampai 10 hari setelah submit, kemungkinan tanpa Anda dampingi. Setiap jalur yang menyentuh jaringan wajib punya perilaku jelas saat gagal:
- API model habis kuota → jawab dari hasil pencarian teks penuh + tandai "mode terbatas", jangan layar putih
- Backend tidak terjangkau → jalankan dari cache lokal, tampilkan pita status luring
- Tidak pernah menampilkan stack trace atau pesan Inggris mentah ke pengguna

---

## Tumpukan teknologi (terkunci)

| Lapis | Teknologi | Alasan |
|---|---|---|
| Klien | **Flutter 3.x (Dart)**, Android 8.0+ (API 26), target API terbaru | Satu basis kode → APK + Web |
| State | **Riverpod** | Testable, tanpa BuildContext untuk logika |
| Routing | **go_router** | Deep link + rute bernama untuk skenario demo |
| Lokal/luring | **Drift (SQLite)** | Antrian tulis luring + cache baca |
| Backend | **Supabase** — Postgres, Auth, Storage, Edge Functions | Satu layanan terkelola, RLS deklaratif |
| Vektor | **pgvector** di Postgres yang sama | Tanpa layanan terpisah |
| Layanan perantara | **Supabase Edge Functions (Deno/TypeScript)** | Kunci API tetap di sisi peladen |
| Model bahasa | **Google Gemini** (primary) → **Groq** (fallback otomatis) | Bahasa Indonesia terbaik + failover |
| Embedding | **Gemini Embedding**, disimpan di pgvector | Satu vendor untuk chat dan embedding |
| PDF | **pdf** + **printing** (Dart) | Ekspor laporan di sisi klien, tanpa peladen |
| Peta | **Tidak ada SDK peta berbayar** | Layar L.9 hanya butuh jarak; Haversine lokal cukup |
| Versi | Git + GitHub, GitHub Actions | Wajib untuk link repositori Tahap 2 |

**Jangan menambah dependensi berat tanpa alasan tertulis.** Setiap paket baru masuk ke `docs/DEVIATIONS.md` dengan justifikasi satu kalimat.

---

## Struktur repositori

```
dekapautis/
├── app/                        # Flutter
│   ├── lib/
│   │   ├── main.dart
│   │   ├── core/               # theme, tokens, router, error, connectivity
│   │   ├── data/               # models, repositories, drift, supabase clients
│   │   ├── features/           # satu folder per fitur, bukan per lapisan
│   │   │   ├── auth/ onboarding/ home/ plan/ activity/ assistant/
│   │   │   ├── report/ directory/ community/ library/ profile/
│   │   │   ├── caregiver_checkin/ notifications/ professional/ admin/
│   │   └── shared/             # widget lintas fitur (RoutineCard, SourceChip, SafetyBanner)
│   ├── test/                   # unit + widget
│   ├── integration_test/
│   └── android/
├── supabase/
│   ├── migrations/             # SQL bernomor, idempoten
│   ├── functions/              # Edge Functions
│   │   ├── ask/                # pipeline RAG + guardrail
│   │   ├── generate-plan/
│   │   ├── adapt-plan/
│   │   ├── summarize-report/
│   │   └── keep-alive/
│   └── seed/                   # data demo + korpus pengetahuan
├── scripts/                    # indexing korpus, evaluasi, build
├── docs/
└── .github/workflows/
```

---

## Cara kerja yang saya harapkan

1. **Baca `PLAN.md` dan kerjakan fase berurutan.** Jangan lompat fase. Setiap fase punya kriteria selesai yang harus lulus sebelum lanjut.
2. **Setiap fase berakhir dengan aplikasi yang tetap bisa di-build.** Jalankan `flutter analyze` dan `flutter test` sebelum menyatakan fase selesai. Nol warning, nol test gagal.
3. **Tulis test bersamaan dengan kode**, bukan di fase terpisah. Mesin adaptasi dan penapis batas medis wajib punya unit test sejak commit pertamanya.
4. **Commit kecil dan sering**, format Conventional Commits (`feat:`, `fix:`, `test:`, `docs:`, `chore:`).
5. **Kalau spesifikasi ambigu, tanya.** Jangan mengarang perilaku produk dan jangan mengarang isi konten kesehatan.
6. **Perbarui checkbox di `PLAN.md`** setiap kali sebuah butir selesai, supaya progres terlihat lintas sesi.
7. **Jangan pernah menulis ulang berkas di `docs/` tanpa diminta.** Berkas itu adalah spesifikasi, bukan catatan kerja.

## Perintah yang sering dipakai

```bash
# Flutter
cd app && flutter pub get
flutter analyze && flutter test
flutter run -d <device>
flutter build apk --release
flutter build web --release

# Supabase
supabase start                          # stack lokal
supabase db reset                       # migrasi ulang + seed
supabase functions serve ask --env-file ./supabase/.env.local
supabase db push                        # migrasi ke remote
supabase functions deploy ask --no-verify-jwt=false

# Evaluasi AI
python scripts/eval_safety.py           # 40 prompt uji batas medis
python scripts/eval_groundedness.py     # keterlacakan jawaban ke sumber
python scripts/index_corpus.py          # embed + muat korpus pengetahuan
```

## Jangan lakukan

- Jangan pakai `localStorage`/`sessionStorage` — ini Flutter, pakai Drift atau `flutter_secure_storage`.
- Jangan menaruh logika bisnis di widget. Mesin adaptasi, guardrail, dan penilaian harus di kelas murni Dart/TS yang bisa diuji tanpa UI.
- Jangan pakai warna di luar dua keluarga palet (ungu dan krem). Tidak ada biru, hijau, merah, oranye, atau abu-abu netral murni. Netral pun berpigmen ungu (`#6B5F73`).
- Jangan pakai `#F2E8F6`, `#E4CEEC`, `#CA9CDB`, atau `#EDDFBC` sebagai warna teks — kontrasnya gagal.
- Jangan pakai `#4A2657` dengan garis tebal untuk elemen selain pemberitahuan batas medis.
- Jangan menampilkan kategori atau status yang hanya dibedakan warna tanpa ikon atau label.
- Jangan lebih dari 3 aksi utama dalam satu layar.
- Jangan menampilkan angka atau klaim medis di UI tanpa sumber yang bisa ditekan.
