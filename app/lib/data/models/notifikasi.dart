import '../../domain/notifikasi/jenis_notifikasi.dart';

/// One row on L.17.
class Notifikasi {
  const Notifikasi({
    required this.id,
    required this.jenis,
    required this.judul,
    required this.dibaca,
    required this.dibuatPada,
    this.tautan,
  });

  factory Notifikasi.fromMap(Map<String, dynamic> m) => Notifikasi(
    id: m['id'] as String,
    jenis: JenisNotifikasi.fromDb(m['jenis'] as String? ?? ''),
    judul: m['judul'] as String,
    dibaca: (m['dibaca'] as bool?) ?? false,
    dibuatPada:
        DateTime.tryParse(m['dibuat_pada'] as String? ?? '') ?? DateTime.now(),
    tautan: m['tautan'] as String?,
  );

  final String id;
  final JenisNotifikasi jenis;
  final String judul;
  final bool dibaca;
  final DateTime dibuatPada;

  /// Where tapping the row goes. Null means the row is informational only, and
  /// the screen must not pretend it is tappable.
  final String? tautan;
}

/// The three headings on L.17.
enum KelompokWaktu {
  hariIni('Hari ini'),
  kemarin('Kemarin'),
  mingguIni('Minggu ini'),
  lebihLama('Lebih lama');

  const KelompokWaktu(this.label);

  final String label;
}

/// Which heading a notification belongs under.
///
/// Pure date arithmetic against a supplied `sekarang` rather than
/// `DateTime.now()`, so the grouping is testable and does not change meaning
/// while a test is running just after midnight.
KelompokWaktu kelompokkan(DateTime waktu, DateTime sekarang) {
  final hariIni = DateTime(sekarang.year, sekarang.month, sekarang.day);
  final hari = DateTime(waktu.year, waktu.month, waktu.day);
  final selisih = hariIni.difference(hari).inDays;

  if (selisih <= 0) return KelompokWaktu.hariIni;
  if (selisih == 1) return KelompokWaktu.kemarin;
  if (selisih <= 7) return KelompokWaktu.mingguIni;
  return KelompokWaktu.lebihLama;
}

/// Groups notifications under their headings, newest first inside each, and
/// drops headings that would be empty rather than showing a bare title.
Map<KelompokWaktu, List<Notifikasi>> kelompokkanSemua(
  List<Notifikasi> daftar,
  DateTime sekarang,
) {
  final hasil = <KelompokWaktu, List<Notifikasi>>{};
  final urut = [...daftar]
    ..sort((a, b) => b.dibuatPada.compareTo(a.dibuatPada));

  for (final n in urut) {
    hasil.putIfAbsent(kelompokkan(n.dibuatPada, sekarang), () => []).add(n);
  }

  return {
    for (final k in KelompokWaktu.values)
      if (hasil[k] != null) k: hasil[k]!,
  };
}
