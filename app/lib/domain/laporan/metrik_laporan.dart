import '../adaptasi/kategori.dart';

export '../adaptasi/kategori.dart';

/// Report metrics, computed here and nowhere else.
///
/// Pure Dart, no Flutter, no network. The language model never calculates
/// anything: it receives these numbers already finished and is asked only to
/// put them into sentences. That split is what makes the verification in
/// `summarize-report` possible at all - a narrative can be checked against a
/// closed set of figures precisely because the figures were never the model's
/// to produce.
///
/// There is deliberately no overall score. Bab 4.2 forbids producing a single
/// figure for a child's ability, and the surest way to honour that is to have
/// no field capable of holding one. What is measured here is the *plan* and the
/// household's week: how much of it happened, how it was recorded, how each
/// category moved. Never the child.

/// Direction of travel within the period. Three values, not a number: a trend
/// is a shape, and turning it into a figure invites it to be read as a grade.
enum Tren {
  naik('naik'),
  datar('tetap'),
  turun('menurun');

  const Tren(this.label);

  final String label;
}

/// One scheduled activity in the period. A null [nilai] means it was scheduled
/// but never recorded, which is a fact about the week, not about the child.
class CatatanLaporan {
  const CatatanLaporan({
    required this.kategori,
    required this.tanggal,
    this.nilai,
  });

  final Kategori kategori;
  final DateTime tanggal;
  final NilaiRespons? nilai;

  bool get tercatat => nilai != null;
}

/// Percentage of "Mudah" in one calendar week.
class TrenMingguan {
  const TrenMingguan({
    required this.mingguMulai,
    required this.persenMudah,
    required this.jumlahTercatat,
  });

  final DateTime mingguMulai;

  /// Rounded whole percent, so what the chart draws and what the narrative
  /// says are the same number.
  final int persenMudah;

  final int jumlahTercatat;
}

class RincianKategori {
  const RincianKategori({
    required this.kategori,
    required this.persenMudah,
    required this.jumlahTercatat,
    required this.tren,
  });

  final Kategori kategori;
  final int persenMudah;
  final int jumlahTercatat;
  final Tren tren;
}

class MetrikLaporan {
  const MetrikLaporan({
    required this.periodeMulai,
    required this.periodeSelesai,
    required this.aktivitasTerjadwal,
    required this.aktivitasTercatat,
    required this.trenMingguan,
    required this.perKategori,
    this.penandaPerhatian = const {},
  });

  final DateTime periodeMulai;
  final DateTime periodeSelesai;

  /// How many activities the plan contained.
  final int aktivitasTerjadwal;

  /// How many of them carry a response note.
  final int aktivitasTercatat;

  final List<TrenMingguan> trenMingguan;
  final List<RincianKategori> perKategori;

  /// Categories flagged by rule D_tandai, for a professional to look at.
  final Set<Kategori> penandaPerhatian;

  int get jumlahHari => periodeSelesai.difference(periodeMulai).inDays + 1;

  /// How much of the plan was carried out. A measure of the household's week,
  /// not of the child - the UI labels it that way too.
  int get persenTercatat => aktivitasTerjadwal == 0
      ? 0
      : (aktivitasTercatat / aktivitasTerjadwal * 100).round();

  /// One decimal place, because the difference between 2.0 and 2.4 sessions a
  /// day is the difference between a manageable week and a heavy one.
  double get rataSesiHarian =>
      jumlahHari == 0 ? 0 : aktivitasTercatat / jumlahHari;

  /// Every figure the narrative is allowed to mention, as written strings.
  ///
  /// This is the closed set `summarize-report` checks the model's sentences
  /// against. Anything outside it was invented, and an invented number in a
  /// document a therapist may read is the failure this whole design exists to
  /// prevent.
  Set<String> get angkaSah => {
    '$aktivitasTerjadwal',
    '$aktivitasTercatat',
    '$persenTercatat',
    '$jumlahHari',
    rataSesiHarian.toStringAsFixed(1),
    rataSesiHarian.toStringAsFixed(1).replaceAll('.', ','),
    '${rataSesiHarian.round()}',
    for (final t in trenMingguan) ...[
      '${t.persenMudah}',
      '${t.jumlahTercatat}',
    ],
    for (final k in perKategori) ...['${k.persenMudah}', '${k.jumlahTercatat}'],
    '${trenMingguan.length}',
    '${perKategori.length}',
    '${periodeMulai.year}',
    '${periodeSelesai.year}',
    '${periodeMulai.day}',
    '${periodeSelesai.day}',
    '${periodeMulai.month}',
    '${periodeSelesai.month}',
  };

  Map<String, Object?> toMetrikJson() => {
    'aktivitas_terjadwal': aktivitasTerjadwal,
    'aktivitas_tercatat': aktivitasTercatat,
    'persen_tercatat': persenTercatat,
    'rata_sesi_harian': double.parse(rataSesiHarian.toStringAsFixed(1)),
    'jumlah_hari': jumlahHari,
  };

  List<Map<String, Object?>> toPerKategoriJson() => [
    for (final k in perKategori)
      {
        'kategori': k.kategori.dbValue,
        'persen': k.persenMudah,
        'jumlah': k.jumlahTercatat,
        'tren': k.tren.name,
      },
  ];
}

/// Monday of the week containing [d].
DateTime awalMingguDari(DateTime d) =>
    DateTime(d.year, d.month, d.day).subtract(Duration(days: d.weekday - 1));

/// Builds every figure in the report from the raw notes.
///
/// Deterministic and total: an empty period produces zeroes rather than an
/// exception, because a caregiver who recorded nothing still deserves a report
/// that opens and says so plainly.
MetrikLaporan hitungMetrik({
  required List<CatatanLaporan> catatan,
  required DateTime periodeMulai,
  required DateTime periodeSelesai,
  Set<Kategori> penandaPerhatian = const {},
}) {
  final mulai = DateTime(
    periodeMulai.year,
    periodeMulai.month,
    periodeMulai.day,
  );
  final selesai = DateTime(
    periodeSelesai.year,
    periodeSelesai.month,
    periodeSelesai.day,
  );

  final dalamPeriode = catatan.where((c) {
    final t = DateTime(c.tanggal.year, c.tanggal.month, c.tanggal.day);
    return !t.isBefore(mulai) && !t.isAfter(selesai);
  }).toList();

  final tercatat = dalamPeriode.where((c) => c.tercatat).toList();

  // ------------------------------------------------------------ weekly --

  final perMinggu = <DateTime, List<CatatanLaporan>>{};
  for (final c in tercatat) {
    perMinggu.putIfAbsent(awalMingguDari(c.tanggal), () => []).add(c);
  }

  final trenMingguan = [
    for (final minggu in perMinggu.keys.toList()..sort())
      TrenMingguan(
        mingguMulai: minggu,
        persenMudah: _persenMudah(perMinggu[minggu]!),
        jumlahTercatat: perMinggu[minggu]!.length,
      ),
  ];

  // ---------------------------------------------------------- category --

  final perKategori = <RincianKategori>[];
  for (final k in Kategori.values) {
    final milikK = tercatat.where((c) => c.kategori == k).toList();
    if (milikK.isEmpty) continue;
    perKategori.add(
      RincianKategori(
        kategori: k,
        persenMudah: _persenMudah(milikK),
        jumlahTercatat: milikK.length,
        tren: _tren(milikK, mulai, selesai),
      ),
    );
  }

  return MetrikLaporan(
    periodeMulai: mulai,
    periodeSelesai: selesai,
    aktivitasTerjadwal: dalamPeriode.length,
    aktivitasTercatat: tercatat.length,
    trenMingguan: trenMingguan,
    perKategori: perKategori,
    penandaPerhatian: penandaPerhatian,
  );
}

int _persenMudah(List<CatatanLaporan> catatan) {
  if (catatan.isEmpty) return 0;
  final mudah = catatan.where((c) => c.nilai == NilaiRespons.mudah).length;
  return (mudah / catatan.length * 100).round();
}

/// First half of the period against the second.
///
/// Deliberately coarse. A finer measure would tempt someone to print it, and a
/// printed slope is a number about a child. Five percentage points is the
/// threshold below which a difference is called steady rather than movement.
Tren _tren(List<CatatanLaporan> catatan, DateTime mulai, DateTime selesai) {
  final tengah = mulai.add(
    Duration(days: (selesai.difference(mulai).inDays / 2).round()),
  );
  final awal = catatan.where((c) => c.tanggal.isBefore(tengah)).toList();
  final akhir = catatan.where((c) => !c.tanggal.isBefore(tengah)).toList();

  // Too little on either side to compare. Saying "steady" is honest; inventing
  // a direction from two notes is not.
  if (awal.length < 2 || akhir.length < 2) return Tren.datar;

  final selisih = _persenMudah(akhir) - _persenMudah(awal);
  if (selisih >= 5) return Tren.naik;
  if (selisih <= -5) return Tren.turun;
  return Tren.datar;
}
