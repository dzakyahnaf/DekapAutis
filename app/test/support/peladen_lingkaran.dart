import 'package:dekapautis/data/models/direktori.dart';
import 'package:dekapautis/data/models/profesional_admin.dart';
import 'package:dekapautis/data/repositories/penerapan_saran_repository.dart';
import 'package:dekapautis/data/repositories/profesional_repository.dart';
import 'package:dekapautis/domain/adaptasi/adaptation_engine.dart';
import 'package:dekapautis/domain/adaptasi/saran_profesional.dart';

/// One in-memory store shared by both sides of the loop.
///
/// This is what makes the end-to-end test worth running. Separate stubs per
/// role would prove each screen renders; a single store means the row the
/// professional writes is the row the caregiver reads, so the test fails if the
/// two halves ever stop lining up - a renamed field, a status the caregiver's
/// screen does not recognise, a suggestion that arrives empty.
class PeladenLingkaran {
  PeladenLingkaran({required this.laporanId, required this.profilAnakId});

  final String laporanId;
  final String profilAnakId;

  /// The plan as it stands. The test reads these back to check the loop
  /// actually moved something.
  final Map<Kategori, int> porsi = {
    Kategori.komunikasi: 3,
    Kategori.motorik: 2,
    Kategori.sensorik: 2,
    Kategori.kemandirian: 1,
    Kategori.sosial: 1,
  };

  final Map<Kategori, int> durasi = {
    Kategori.komunikasi: 15,
    Kategori.motorik: 15,
    Kategori.sensorik: 10,
    Kategori.kemandirian: 10,
    Kategori.sosial: 10,
  };

  /// Rows that would go to `adaptasi_log`.
  final List<BarisAdaptasiLog> log = [];

  final List<TanggapanProfesional> tanggapan = [];

  /// Notifications the server would raise. The trigger does this for real;
  /// here it stands in for it so the test can assert the caregiver is told.
  final List<String> notifikasi = [];

  var _berikutnya = 1;

  String tambahTanggapan({
    required String isi,
    required List<Kategori> saranKategori,
    int? saranDurasiMenit,
  }) {
    final id = 'tg-${_berikutnya++}';
    tanggapan.add(
      TanggapanProfesional(
        id: id,
        laporanId: laporanId,
        isi: isi,
        saranKategori: saranKategori,
        status: StatusTanggapan.baru,
        saranDurasiMenit: saranDurasiMenit,
        dibuatPada: DateTime.now(),
      ),
    );
    // Mirrors trg_beritahu_tanggapan in migration 009.
    notifikasi.add('Tanggapan baru dari tenaga profesional');
    return id;
  }

  void ubahStatus(String id, StatusTanggapan status) {
    final i = tanggapan.indexWhere((t) => t.id == id);
    if (i < 0) return;
    final lama = tanggapan[i];
    tanggapan[i] = TanggapanProfesional(
      id: lama.id,
      laporanId: lama.laporanId,
      isi: lama.isi,
      saranKategori: lama.saranKategori,
      status: status,
      saranDurasiMenit: lama.saranDurasiMenit,
      dibuatPada: lama.dibuatPada,
    );
  }
}

/// Stands in for the professional's repository, backed by [PeladenLingkaran].
class ProfesionalPalsu implements ProfesionalRepository {
  ProfesionalPalsu(this.peladen, {this.profil});

  final PeladenLingkaran peladen;
  Profesional? profil;

  @override
  Future<Profesional?> profilSaya() async => profil;

  @override
  Future<StatusVerifikasi> statusVerifikasiSaya() async =>
      profil == null ? StatusVerifikasi.menunggu : StatusVerifikasi.disetujui;

  @override
  Future<void> simpanProfil({
    required String namaLengkap,
    required String spesialisasi,
    String? gelar,
    String? tentang,
    List<String> layanan = const [],
    List<JamPraktik> jadwalPraktik = const [],
    String? kota,
    double? lat,
    double? lng,
    String? buktiKredensial,
  }) async {
    profil = Profesional(
      id: 'pr-1',
      namaLengkap: namaLengkap,
      spesialisasi: spesialisasi,
      terverifikasi: false,
      gelar: gelar,
      tentang: tentang,
      layanan: layanan,
      jadwalPraktik: jadwalPraktik,
      kota: kota,
      buktiKredensial: buktiKredensial,
    );
  }

  @override
  Future<List<LaporanMasuk>> kotakMasuk() async => [
    LaporanMasuk(
      id: peladen.laporanId,
      profilAnakId: peladen.profilAnakId,
      periodeMulai: DateTime(2026, 7, 25),
      periodeSelesai: DateTime(2026, 8, 22),
      ringkasan: 'Disusun dari catatan pengasuh selama empat minggu.',
      penandaPerhatian: const ['komunikasi'],
      sudahDitanggapi: peladen.tanggapan.isNotEmpty,
      namaAnak: 'Bima',
      usiaAnak: 6,
      dibuatPada: DateTime(2026, 8, 22),
    ),
  ];

  @override
  Future<LaporanMasuk?> laporan(String id) async =>
      (await kotakMasuk()).where((l) => l.id == id).firstOrNull;

  @override
  Future<List<TanggapanProfesional>> tanggapan(String laporanId) async => [
    for (final t in peladen.tanggapan)
      if (t.laporanId == laporanId) t,
  ];

  @override
  Future<void> tanggapi({
    required String laporanId,
    required String isi,
    required Set<Kategori> saranKategori,
    required String klienId,
    int? saranDurasiMenit,
  }) async => peladen.tambahTanggapan(
    isi: isi,
    saranKategori: saranKategori.toList(),
    saranDurasiMenit: saranDurasiMenit,
  );
}

/// Stands in for applying a suggestion. Runs the *real*
/// [terapkanSaranProfesional], so the arithmetic under test is production code
/// and only the storage is faked.
class PenerapanPalsu implements PenerapanSaranRepository {
  PenerapanPalsu(this.peladen);

  final PeladenLingkaran peladen;

  @override
  Future<RencanaSaatIni?> rencanaAktif(String profilAnakId) async =>
      RencanaSaatIni(
        id: 'rencana-1',
        porsi: Map.of(peladen.porsi),
        durasi: Map.of(peladen.durasi),
      );

  @override
  Future<HasilPenerapanSaran> terapkan({
    required String tanggapanId,
    required SaranProfesional saran,
    required RencanaSaatIni rencana,
  }) async {
    final hasil = terapkanSaranProfesional(
      saran: saran,
      porsi: rencana.porsi,
      durasi: rencana.durasi,
    );

    peladen.porsi
      ..clear()
      ..addAll(hasil.porsi);
    peladen.durasi
      ..clear()
      ..addAll(hasil.durasi);
    peladen.log.addAll(hasil.log);
    peladen.ubahStatus(tanggapanId, StatusTanggapan.diterapkan);

    return hasil;
  }

  @override
  Future<void> tolak(String tanggapanId) async =>
      peladen.ubahStatus(tanggapanId, StatusTanggapan.ditolak);
}
