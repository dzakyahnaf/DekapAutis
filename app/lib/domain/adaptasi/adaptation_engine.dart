import 'kategori.dart';

export 'kategori.dart';

/// The plan adaptation engine (KF-06), the second AI pillar.
///
/// Pure Dart: no Flutter, no network, no database. Everything it needs arrives
/// in [MasukanAdaptasi] and everything it decides leaves in [HasilAdaptasi].
/// That is what makes the rules arguable rather than mysterious - and it is why
/// the tests can pin down all five rules and all seven edge cases without a
/// widget or a running backend anywhere near them.
///
/// The engine never grades a child. It reads what a caregiver recorded and
/// moves a *plan*, and every move it makes writes a sentence saying which real
/// numbers caused it. That transparency is the whole difference between this
/// and a black box, and it is the point worth defending in a viva.

/// Weights for the last six notes, newest first (docs/04 §3).
const _bobot = [1.0, 0.9, 0.8, 0.7, 0.6, 0.5];

/// Below this many notes in a category, nothing moves. Three days of notes is
/// not enough to change a child's week.
const _minSampel = 3;

const _maksTingkat = 4;
const _minTingkat = 1;
const _minDurasi = 5;

/// Raised from 3, see docs/DEVIATIONS.md.
const maksSesiMingguan = 7;
const maksSesiHarian = 5;

/// Weighted average of the last six notes in one category, newest weighted
/// most. Returns null below [_minSampel] samples, and null means no rule runs.
double? skorKesiapan(List<CatatanUntukAdaptasi> catatan) {
  if (catatan.length < _minSampel) return null;

  final urut = [...catatan]
    ..sort((a, b) => b.dicatatPada.compareTo(a.dicatatPada));
  final ambil = urut.take(_bobot.length).toList();

  var atas = 0.0;
  var bawah = 0.0;
  for (var i = 0; i < ambil.length; i++) {
    atas += _bobot[i] * ambil[i].nilai.bobot;
    bawah += _bobot[i];
  }
  return atas / bawah;
}

/// Everything the rules read.
class MasukanAdaptasi {
  const MasukanAdaptasi({
    required this.catatan,
    required this.tingkat,
    required this.durasi,
    required this.porsi,
    required this.periodeSekarang,
    this.saranLingkungan = const {},
    this.dikoreksiManual = const {},
  });

  final List<CatatanUntukAdaptasi> catatan;
  final Map<Kategori, int> tingkat;
  final Map<Kategori, int> durasi;
  final Map<Kategori, int> porsi;

  /// Attached by rule B_turun when it lowers a level.
  final Map<Kategori, String> saranLingkungan;

  /// Categories the caregiver corrected by hand. The rules leave these alone
  /// for the rest of the period: a caregiver who overrode the plan knows
  /// something the notes do not contain.
  final Set<Kategori> dikoreksiManual;

  /// Monday of the current week. Periods are calendar weeks (KEPUTUSAN.md 18).
  final DateTime periodeSekarang;
}

/// One row of adaptasi_log.
class BarisAdaptasiLog {
  const BarisAdaptasiLog({
    required this.aturanId,
    required this.kategori,
    required this.nilaiSebelum,
    required this.nilaiSesudah,
    required this.alasan,
    this.dikoreksiManual = false,
    this.tampilkanKePengasuh = true,
  });

  /// One of A_naik, B_turun, C_porsi, D_tandai, E_jadwal.
  final String aturanId;
  final Kategori kategori;
  final Map<String, Object?> nilaiSebelum;
  final Map<String, Object?> nilaiSesudah;

  /// Indonesian, citing the numbers that caused the change. Never
  /// "sistem menyesuaikan rencana Anda".
  final String alasan;

  final bool dikoreksiManual;

  /// D_tandai is for the report and the professional's inbox. Showing a
  /// caregiver "your child is declining" helps nobody and is not the app's
  /// place to say.
  final bool tampilkanKePengasuh;
}

/// Everything the rules decided.
class HasilAdaptasi {
  const HasilAdaptasi({
    required this.tingkat,
    required this.durasi,
    required this.porsi,
    required this.penandaPerhatian,
    required this.blokJam,
    required this.saranDitampilkan,
    required this.log,
  });

  final Map<Kategori, int> tingkat;
  final Map<Kategori, int> durasi;
  final Map<Kategori, int> porsi;

  /// Categories to flag on the report for a professional to look at.
  final Set<Kategori> penandaPerhatian;

  /// Hour to schedule next period in, only for categories rule E moved.
  final Map<Kategori, int> blokJam;

  /// Environment suggestion to surface with the activity, from rule B.
  final Map<Kategori, String> saranDitampilkan;

  final List<BarisAdaptasiLog> log;
}

class AdaptationEngine {
  const AdaptationEngine();

  HasilAdaptasi jalankan(MasukanAdaptasi m) {
    final tingkat = {...m.tingkat};
    final durasi = {...m.durasi};
    final porsi = {...m.porsi};
    final penanda = <Kategori>{};
    final blokJam = <Kategori, int>{};
    final saran = <Kategori, String>{};
    final log = <BarisAdaptasiLog>[];

    // Fixed order, so the same input always produces the same rows. Anything
    // that made the output depend on map iteration order would make the engine
    // impossible to test and impossible to explain.
    for (final k in Kategori.values) {
      if (m.dikoreksiManual.contains(k)) continue;

      final semua = m.catatan.where((c) => c.kategori == k).toList()
        ..sort((a, b) => b.dicatatPada.compareTo(a.dicatatPada));
      if (semua.length < _minSampel) continue;

      final tigaTerakhir = semua.take(3).toList();
      final jumlahMudah = tigaTerakhir
          .where((c) => c.nilai == NilaiRespons.mudah)
          .length;
      final jumlahSulit = tigaTerakhir
          .where((c) => c.nilai == NilaiRespons.sulit)
          .length;

      _aturanA(k, tingkat, tigaTerakhir.length, jumlahMudah, jumlahSulit, log);
      _aturanB(
        k,
        m,
        tingkat,
        durasi,
        saran,
        tigaTerakhir.length,
        jumlahSulit,
        log,
      );
      _aturanC(k, m, semua, porsi, log);
      _aturanD(k, m, semua, penanda, log);
      _aturanE(k, semua, blokJam, log);
    }

    return HasilAdaptasi(
      tingkat: tingkat,
      durasi: durasi,
      porsi: porsi,
      penandaPerhatian: penanda,
      blokJam: blokJam,
      saranDitampilkan: saran,
      log: log,
    );
  }

  // -------------------------------------------------------------- rule A --

  void _aturanA(
    Kategori k,
    Map<Kategori, int> tingkat,
    int dariBerapa,
    int jumlahMudah,
    int jumlahSulit,
    List<BarisAdaptasiLog> log,
  ) {
    if (jumlahMudah < 2 || jumlahSulit > 0) return;

    final sebelum = tingkat[k]!;
    // At the ceiling nothing changes, so nothing is written. A log row that
    // reports no change is noise in the one place that must stay readable.
    if (sebelum >= _maksTingkat) return;

    final sesudah = sebelum + 1;
    tingkat[k] = sesudah;
    log.add(
      BarisAdaptasiLog(
        aturanId: 'A_naik',
        kategori: k,
        nilaiSebelum: {'tingkat': sebelum},
        nilaiSesudah: {'tingkat': sesudah},
        alasan:
            'Tingkat aktivitas ${k.label} dinaikkan dari $sebelum menjadi '
            '$sesudah karena $jumlahMudah dari $dariBerapa catatan terakhir '
            'Anda menandai Mudah.',
      ),
    );
  }

  // -------------------------------------------------------------- rule B --

  void _aturanB(
    Kategori k,
    MasukanAdaptasi m,
    Map<Kategori, int> tingkat,
    Map<Kategori, int> durasi,
    Map<Kategori, String> saran,
    int dariBerapa,
    int jumlahSulit,
    List<BarisAdaptasiLog> log,
  ) {
    if (jumlahSulit < 2) return;

    final tingkatSebelum = tingkat[k]!;
    final durasiSebelum = durasi[k]!;

    final tingkatSesudah = tingkatSebelum > _minTingkat
        ? tingkatSebelum - 1
        : tingkatSebelum;
    // Minus 25 percent, never below five minutes.
    final durasiSesudah = durasiSebelum <= _minDurasi
        ? _minDurasi
        : (durasiSebelum * 0.75).round().clamp(_minDurasi, durasiSebelum);

    // At both floors at once there is nothing left to change, so no row.
    if (tingkatSesudah == tingkatSebelum && durasiSesudah == durasiSebelum) {
      return;
    }

    tingkat[k] = tingkatSesudah;
    durasi[k] = durasiSesudah;

    final saranK = m.saranLingkungan[k];
    if (saranK != null) saran[k] = saranK;

    final bagian = StringBuffer('Tingkat aktivitas ${k.label} ');
    if (tingkatSesudah != tingkatSebelum) {
      bagian.write('diturunkan dari $tingkatSebelum menjadi $tingkatSesudah ');
      if (durasiSesudah != durasiSebelum) bagian.write('dan ');
    }
    if (durasiSesudah != durasiSebelum) {
      bagian.write(
        'durasinya dipendekkan dari $durasiSebelum menjadi '
        '$durasiSesudah menit ',
      );
    }
    bagian.write(
      'karena $jumlahSulit dari $dariBerapa catatan terakhir Anda menandai '
      'Sulit.',
    );
    if (saranK != null) bagian.write(' $saranK');

    log.add(
      BarisAdaptasiLog(
        aturanId: 'B_turun',
        kategori: k,
        nilaiSebelum: {'tingkat': tingkatSebelum, 'durasi': durasiSebelum},
        nilaiSesudah: {'tingkat': tingkatSesudah, 'durasi': durasiSesudah},
        alasan: bagian.toString().trim(),
      ),
    );
  }

  // -------------------------------------------------------------- rule C --

  void _aturanC(
    Kategori k,
    MasukanAdaptasi m,
    List<CatatanUntukAdaptasi> semua,
    Map<Kategori, int> porsi,
    List<BarisAdaptasiLog> log,
  ) {
    final sekarang = skorKesiapan(_padaPeriode(semua, m.periodeSekarang));
    final sebelumnya = skorKesiapan(
      _padaPeriode(semua, m.periodeSekarang.subtract(const Duration(days: 7))),
    );
    // Two periods, each with enough samples, or the comparison means nothing.
    if (sekarang == null || sebelumnya == null) return;
    if (sekarang <= sebelumnya) return;

    final porsiSebelum = porsi[k]!;
    if (porsiSebelum >= maksSesiMingguan) return;

    // A week nobody could actually run is not a plan.
    final totalSetelah =
        porsi.values.fold(0, (a, b) => a + b) - porsiSebelum + porsiSebelum + 1;
    if (totalSetelah > maksSesiHarian * 7) return;

    final porsiSesudah = porsiSebelum + 1;
    porsi[k] = porsiSesudah;

    log.add(
      BarisAdaptasiLog(
        aturanId: 'C_porsi',
        kategori: k,
        nilaiSebelum: {'porsi': porsiSebelum, 'skor': sebelumnya},
        nilaiSesudah: {'porsi': porsiSesudah, 'skor': sekarang},
        alasan:
            'Porsi aktivitas ${k.label} ditambah dari $porsiSebelum menjadi '
            '$porsiSesudah sesi per minggu karena skor kesiapan naik dari '
            '${_angka(sebelumnya)} menjadi ${_angka(sekarang)}.',
      ),
    );
  }

  // -------------------------------------------------------------- rule D --

  void _aturanD(
    Kategori k,
    MasukanAdaptasi m,
    List<CatatanUntukAdaptasi> semua,
    Set<Kategori> penanda,
    List<BarisAdaptasiLog> log,
  ) {
    final p3 = _capaian(_padaPeriode(semua, m.periodeSekarang));
    final p2 = _capaian(
      _padaPeriode(semua, m.periodeSekarang.subtract(const Duration(days: 7))),
    );
    final p1 = _capaian(
      _padaPeriode(semua, m.periodeSekarang.subtract(const Duration(days: 14))),
    );
    if (p1 == null || p2 == null || p3 == null) return;
    if (!(p1 > p2 && p2 > p3)) return;

    penanda.add(k);
    log.add(
      BarisAdaptasiLog(
        aturanId: 'D_tandai',
        kategori: k,
        nilaiSebelum: {
          'capaian': [p1, p2],
        },
        nilaiSesudah: {'capaian': p3},
        // Descriptive, and addressed to the professional who will read the
        // report - not a verdict handed to the caregiver.
        alasan:
            'Capaian ${k.label} menurun dua periode berturut-turut: $p1% pada '
            'periode pertama, $p2% pada periode kedua, lalu $p3% pada periode '
            'ini. Ditandai untuk dibahas bersama tenaga profesional.',
        tampilkanKePengasuh: false,
      ),
    );
  }

  // -------------------------------------------------------------- rule E --

  void _aturanE(
    Kategori k,
    List<CatatanUntukAdaptasi> semua,
    Map<Kategori, int> blokJam,
    List<BarisAdaptasiLog> log,
  ) {
    final perBlok = <int, List<CatatanUntukAdaptasi>>{};
    for (final c in semua) {
      perBlok.putIfAbsent(c.jamJadwal, () => []).add(c);
    }

    int? terbaik;
    var rasioTerbaik = 0.0;
    var mudahTerbaik = 0;
    var totalTerbaik = 0;

    // Ascending hour, so a tie always resolves the same way.
    for (final jam in perBlok.keys.toList()..sort()) {
      final blok = perBlok[jam]!;
      if (blok.length < _minSampel) continue;
      final mudah = blok.where((c) => c.nilai == NilaiRespons.mudah).length;
      final rasio = mudah / blok.length;
      if (rasio > rasioTerbaik) {
        terbaik = jam;
        rasioTerbaik = rasio;
        mudahTerbaik = mudah;
        totalTerbaik = blok.length;
      }
    }

    // No block earned it. Keep the current schedule rather than moving a
    // child's routine on a coin flip - predictability is the first principle.
    if (terbaik == null) return;

    blokJam[k] = terbaik;
    final jamTampil = '${terbaik.toString().padLeft(2, '0')}.00';
    log.add(
      BarisAdaptasiLog(
        aturanId: 'E_jadwal',
        kategori: k,
        nilaiSebelum: {'blok_jam': null},
        nilaiSesudah: {'blok_jam': terbaik},
        alasan:
            'Aktivitas ${k.label} dipindah ke pukul $jamTampil karena '
            '$mudahTerbaik dari $totalTerbaik catatan Anda pada jam itu '
            'menandai Mudah.',
      ),
    );
  }

  // ------------------------------------------------------------- helpers --

  /// Notes falling in the calendar week starting at [awal].
  static List<CatatanUntukAdaptasi> _padaPeriode(
    List<CatatanUntukAdaptasi> catatan,
    DateTime awal,
  ) {
    final mulai = DateTime(awal.year, awal.month, awal.day);
    final selesai = mulai.add(const Duration(days: 7));
    return catatan
        .where(
          (c) =>
              !c.dicatatPada.isBefore(mulai) && c.dicatatPada.isBefore(selesai),
        )
        .toList();
  }

  /// Percentage of notes marked Mudah in a period, rounded. Null below the
  /// sample floor, so a quiet week is never read as a decline.
  static int? _capaian(List<CatatanUntukAdaptasi> periode) {
    if (periode.length < _minSampel) return null;
    final mudah = periode.where((c) => c.nilai == NilaiRespons.mudah).length;
    return (mudah / periode.length * 100).round();
  }

  /// Indonesian writes decimals with a comma.
  static String _angka(double v) => v.toStringAsFixed(2).replaceAll('.', ',');
}
