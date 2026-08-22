# DekapAutis

Pendamping berbasis kecerdasan artifisial untuk orang tua dan pengasuh anak
dengan spektrum autisme.

**Tim Fable 5 Enjoyer** — Institut Teknologi Sepuluh Nopember, Surabaya
IT CONVERT 2026, bidang Software Development · *AI in Health and Well-being*

- Muhammad Dzaky Ahnaf (5027231039) — backend dan AI
- Diffa Adzra Anelya (5051231021) — UI dan klien Flutter

---

## Apa yang dikerjakan aplikasi ini

Seorang pengasuh mengisi profil singkat anaknya. DekapAutis menyusun rencana
stimulasi satu minggu dari katalog 60 aktivitas, pengasuh menjalankannya dan
mencatat respons anak, lalu rencana minggu berikutnya **menyesuaikan diri dari
catatan itu** — dengan alasan yang menyebut angka nyata, bukan kalimat umum.
Menjelang jadwal terapi, laporan perkembangan dapat dibagikan ke tenaga
profesional, dan tanggapan profesional kembali memengaruhi rencana.

### Batas medis, dan mengapa ia berlapis

Aplikasi ini **tidak mendiagnosis, tidak menilai tingkat keparahan spektrum,
dan tidak menganjurkan obat atau dosis.** Itu bukan kalimat penyangkalan di
kaki halaman — ada tiga lapis teknis yang menegakkannya:

| Lapis | Mekanisme | Berjalan tanpa model? |
|---|---|---|
| 1 | Penapis leksikon deterministik atas pertanyaan | ya |
| 2 | Klasifikasi niat oleh model bahasa | tidak |
| 3 | Verifikasi keluaran sebelum ditampilkan | ya |

Setiap pemicu dicatat ke `log_batas_aman`. Lapis 3 memutus stream di tempat
begitu kata terlarang muncul, karena verifikasi setelah jawaban selesai tidak
dapat menarik kembali teks yang sudah terbaca.

`scripts/eval_safety.py` mengukurnya terhadap 40 prompt: 20 wajib ditolak, 20
wajib dijawab. Penolakan berlebihan dilaporkan sama seriusnya dengan kebocoran.

---

## Menjalankan secara lokal

Prasyarat: Flutter 3.41+, Docker, Supabase CLI.

```bash
# 1. Backend
supabase start                 # port 553xx, lihat supabase/config.toml
supabase db reset              # migrasi + katalog aktivitas + data demo

# 2. Aplikasi
cd app
flutter pub get
flutter run                    # atau: flutter build apk --release
```

Build lokal menunjuk ke `http://127.0.0.1:55321` secara otomatis (emulator
Android memakai `10.0.2.2`). Build rilis **wajib** menyertakan konfigurasi
remote:

```bash
flutter build apk --release \
  --dart-define=SUPABASE_URL=https://<proyek>.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_...
```

Kunci model bahasa (Gemini, Groq) **tidak pernah** ada di klien. Keduanya hidup
hanya sebagai secret Edge Function. Ini diverifikasi dengan mengekstrak APK dan
menggrep polanya — lihat bagian Pengujian.

---

## Akun demo

Tekan **"Masuk sebagai demo"** di layar masuk, atau ketik sendiri:

| Peran | Email | Kata sandi |
|---|---|---|
| Pengasuh | `demo@dekapautis.id` | `DemoDekap2026` |
| Profesional | `demo.profesional@dekapautis.id` | `DemoDekap2026` |
| Administrator | `demo.admin@dekapautis.id` | `DemoDekap2026` |

Akun demo berisi **data sintetis**. Rina Kartika dan Bima adalah persona
contoh, bukan pengguna sungguhan, dan aplikasi menampilkan keping "Akun demo"
di header profil supaya hal itu tidak pernah kabur.

Riwayat empat minggunya dihitung mundur dari `now()`, jadi laporan selalu
berakhir hari ini — kapan pun aplikasi dibuka.

---

## Arsitektur

```
Flutter (Android + Web)
  ├─ Riverpod            state, tanpa BuildContext untuk logika
  ├─ go_router           rute bernama + deep link dekapautis://
  ├─ Drift (SQLite)      cache baca + antrean tulis luring, terenkripsi
  └─ domain/             Dart murni: mesin adaptasi, jarak, moderasi, laporan
        │
        ▼  hanya lewat Edge Function, tidak pernah langsung ke model
Supabase
  ├─ Postgres + RLS      default-deny, dibuktikan scripts/test_rls.sql
  ├─ pgvector + HNSW     pengambilan hibrida vektor + teks penuh (RRF)
  └─ Edge Functions      ask · generate-plan · summarize-report · hapus-akun
        │
        ▼
  Gemini  ──gagal──▶  Groq  ──gagal──▶  teks penuh + tanda "mode terbatas"
```

Lapisan `domain/` sengaja memakai `package:test`, bukan `flutter_test`. Itu
jaminan struktural: kalau sebuah aturan bisnis butuh `WidgetTester`, logikanya
salah tempat.

---

## Pengujian

```bash
cd app && flutter test                      # 347 test
docker run --rm -v "${PWD}:/w" -w /w --entrypoint deno denoland/deno:alpine \
  test --allow-import supabase/functions/_shared/      # 52 test

# Bukti berbasis basis data, masing-masing mencetak baris LULUS/GAGAL
docker exec -i supabase_db_dekapautis psql -U postgres -d postgres -f - \
  < scripts/test_rls.sql                    # privasi, 13 pemeriksaan
  < scripts/test_lingkaran_penuh.sql        # alur Gambar 7.1, 18 pemeriksaan
  < scripts/test_seed_demo.sql              # data demo tidak basi, 18
  < scripts/test_direktori_komunitas.sql    # anonimitas sisi peladen, 20
  < scripts/test_hapus_akun.sql             # penghapusan tuntas, 20
  < scripts/test_katalog.sql                # batas isi katalog, 14
  < scripts/test_cari_potongan.sql          # RRF, 9

# Evaluasi AI
python scripts/eval_safety.py               # batas medis, 40 prompt
python scripts/eval_groundedness.py         # keterlacakan jawaban
```

Total: **347 test Flutter, 52 test Deno, 112 pemeriksaan SQL.**

**Verifikasi tidak ada kunci API di APK:**

```bash
flutter build apk --release
unzip -q build/app/outputs/flutter-apk/app-release.apk -d /tmp/apk
grep -ra "AIza\|gsk_\|sk-\|GEMINI_API_KEY\|GROQ_API_KEY\|service_role" /tmp/apk
```

Hasil harus nihil. Kunci `sb_publishable_...` memang ada dan memang aman — ia
dirancang untuk publik dan tidak berguna tanpa menembus RLS.

Izin yang diminta APK hanya `INTERNET`, `ACCESS_COARSE_LOCATION`, dan
`ACCESS_NETWORK_STATE` (deteksi luring).

---

## Batasan yang diketahui

Dicatat di sini karena menyembunyikannya lebih merugikan daripada menyebutnya.

- **Korpus pengetahuan masih kosong.** Sampai diisi lewat
  `scripts/index_corpus.py` atau layar admin, Tanya Dekap tidak punya dokumen
  untuk dirujuk dan L.4 menampilkan "0 dokumen". Angka itu dihitung `COUNT(*)`,
  bukan hardcode — mockup proposal menulis 148, dan angka itu sengaja tidak
  dipakai. Akibatnya `eval_groundedness.py` belum dapat mengukur apa pun.
- **Build web tidak menyimpan apa pun secara permanen.** Enkripsi saat
  tersimpan bergantung pada SQLite3MultipleCiphers dan Android Keystore;
  peramban tidak punya keduanya. Menulis catatan anak ke IndexedDB dalam bentuk
  polos akan melanggar janji KNF-03, jadi cache web hidup selama tab terbuka
  saja. **APK adalah artefak yang dinilai**; antrean tulis luring berlaku penuh
  di sana.
- **Notifikasi lokal terjadwal belum ada.** Logika penjadwalannya selesai dan
  teruji (`domain/notifikasi/pengingat.dart`), tetapi pengikatan ke plugin
  platform belum dikerjakan, dan dependensinya sudah dilepas supaya aplikasi
  tidak meminta izin untuk fitur yang tidak ada.
- **Uji SUS dan uji perangkat RAM 3 GB belum dijalankan.** Keduanya menuntut
  responden dan perangkat nyata.
- **Direktori profesional adalah contoh.** Lima belas entri di dalamnya adalah
  data demo dengan koordinat nyata supaya perhitungan jarak masuk akal, tetapi
  **bukan daftar praktisi sungguhan**. Tidak ada nama praktisi nyata yang
  dicantumkan tanpa izin.

Seluruh penyimpangan dari proposal dicatat di [`docs/DEVIATIONS.md`](docs/DEVIATIONS.md).

---

## Tangkapan layar

Belum dilampirkan. Diisi setelah pengujian pada perangkat Android nyata,
bersamaan dengan pengambilan video.

---

## Lisensi dan atribusi

Font Lexend Deca dan IBM Plex Mono dibundel di bawah SIL Open Font License 1.1.
Isi katalog aktivitas disusun tim; tidak ada protokol terapi klinis, alat
berbayar, maupun janji hasil di dalamnya.
