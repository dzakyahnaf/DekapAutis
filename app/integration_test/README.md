Uji alur ujung ke ujung.

Lingkaran penuh Gambar 7.1 (laporan -> profesional -> tanggapan -> rencana
berubah) diuji di dua tempat, dan keduanya berjalan tanpa perangkat:

- `test/e2e_lingkaran_laporan_test.dart` menggerakkan layar sungguhan lewat
  router, dengan kedua peran berbagi satu penyimpanan di memori. Ditaruh di
  `test/` supaya ikut berjalan pada setiap `flutter test`; berkas di dalam
  `integration_test/` menuntut perangkat terhubung, dan mesin ini hanya punya
  Chrome dan Edge.
- `scripts/test_lingkaran_penuh.sql` menjalankan lingkaran yang sama di
  Postgres sungguhan dengan empat JWT terpisah. Ini yang membuktikan bagian
  yang tidak bisa dibuktikan fake: RLS, yaitu bahwa data pengasuh hanya sampai
  ke profesional yang mereka pilih.

Uji di perangkat Android sungguhan (paket `integration_test` + emulator) belum
disiapkan. Kalau nanti dibutuhkan, berkas uji di sini yang jadi tempatnya.
