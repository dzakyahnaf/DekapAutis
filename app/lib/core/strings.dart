/// Every string the user can see, in one place.
///
/// Rules from `CLAUDE.md` that this file exists to make checkable:
/// - 100% Bahasa Indonesia. No English may leak into the UI.
/// - Address the user as "Anda". Never "kamu", never "bunda" - users include
///   fathers, carers and classroom aides.
/// - Never call a child "penderita" or "penyandang". Use "anak" or
///   "anak dengan spektrum autisme".
/// - Buttons name their result: "Simpan catatan", not "Kirim".
/// - Empty states invite. They do not apologise.
/// - Errors say what happened and what to do next. They do not apologise and
///   they do not blame the user.
abstract final class S {
  // Product ------------------------------------------------------------------
  static const appName = 'DekapAutis';
  static const tagline = 'Pendamping keluarga anak dengan spektrum autisme';

  // Navigation --------------------------------------------------------------
  static const navBeranda = 'Beranda';
  static const navRencana = 'Rencana';
  static const navTanya = 'Tanya';
  static const navJelajah = 'Jelajah';
  static const navProfil = 'Profil';

  // Screen titles -----------------------------------------------------------
  static const titleBeranda = 'Beranda';
  static const titleRencana = 'Rencana stimulasi';
  static const titleAktivitas = 'Detail aktivitas';
  static const titleTanya = 'Tanya Dekap';
  static const titleSumber = 'Sumber jawaban';
  static const titleLaporan = 'Laporan perkembangan';
  static const titleDirektori = 'Direktori profesional';
  static const titleProfesional = 'Profil profesional';
  static const titleKomunitas = 'Komunitas';
  static const titleDiskusi = 'Diskusi';
  static const titlePustaka = 'Pustaka edukasi';
  static const titleArtikel = 'Artikel';
  static const titleProfil = 'Profil dan privasi';
  static const titleAksesibilitas = 'Preferensi aksesibilitas';
  static const titleIzin = 'Izin berbagi data';
  static const titleCaraPakai = 'Cara pakai';
  static const titleNotifikasi = 'Notifikasi';
  static const titleOnboarding = 'Profil anak';
  static const titleMasuk = 'Masuk';
  static const titleDaftar = 'Daftar';
  static const titleKotakMasuk = 'Kotak masuk laporan';
  static const titleProfilPraktik = 'Profil praktik';
  static const titleVerifikasi = 'Verifikasi profesional';
  static const titlePengetahuan = 'Basis pengetahuan';
  static const titleModerasi = 'Antrean moderasi';

  // Actions -----------------------------------------------------------------
  static const aksiSimpanCatatan = 'Simpan catatan';
  static const aksiBuatLaporan = 'Buat laporan';
  static const aksiCobaLagi = 'Coba lagi';
  static const aksiLewati = 'Lewati';
  static const aksiLanjut = 'Lanjut';
  static const aksiKembali = 'Kembali';
  static const aksiTutup = 'Tutup';
  static const aksiBukaSumber = 'Buka sumber asli';
  static const aksiLihatProfesional = 'Lihat profesional terdekat';
  static const aksiLihatSemua = 'Lihat semua';

  // Loading, empty, error ---------------------------------------------------
  /// Static text, never a shimmer. Repeating motion is a sensory-load trigger.
  static const memuatRencana = 'Menyiapkan rencana hari ini…';
  static const memuatJawaban = 'Menyusun jawaban…';
  static const memuat = 'Memuat…';

  static const kosongCatatan =
      'Belum ada catatan minggu ini. Catat satu aktivitas untuk mulai melihat polanya.';
  static const kosongUmum = 'Belum ada isi di sini.';

  static const gagalJaringan =
      'Perangkat sedang tidak terhubung ke internet. Catatan Anda tersimpan di perangkat dan akan dikirim otomatis saat jaringan kembali.';
  static const gagalLayanan =
      'Layanan sedang tidak dapat dihubungi. Data yang sudah tersimpan tetap bisa Anda buka.';

  // Offline -----------------------------------------------------------------
  static const luringAktif = 'Mode luring';
  static String luringMenunggu(int jumlah) =>
      'Tersimpan di perangkat. $jumlah catatan menunggu sinkronisasi.';

  // Calm Mode ---------------------------------------------------------------
  static const modeTenang = 'Mode Tenang';
  static const modeTenangAktif = 'Mode Tenang aktif';

  // Medical boundary --------------------------------------------------------
  static const batasJudul = 'DekapAutis tidak dapat mendiagnosis';
  static const batasBisaDibantu = 'Yang bisa saya bantu';
  static const batasCatatanKaki =
      'Disusun AI dari sumber terverifikasi. Bukan pengganti konsultasi profesional.';

  // Privacy -----------------------------------------------------------------
  static const pitaPrivasi =
      'Data anak dienkripsi dan tidak dibagikan tanpa izin Anda.';

  // Demo --------------------------------------------------------------------
  static const akunDemo = 'Akun demo';
  static const masukSebagaiDemo = 'Masuk sebagai demo';
  static const demoKeterangan =
      'Akun ini berisi data contoh, bukan data pengguna sungguhan.';

  // Placeholder used by the F0 route skeleton only. Removed as screens land.
  static const belumDibangun = 'Layar ini belum dibangun.';
}
