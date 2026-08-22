import '../../domain/direktori/jarak.dart';

/// Service categories offered on L.9's filter. Free text in the database, so
/// the filter matches on the stored string rather than an enum id.
enum JenisLayanan {
  semua('Semua'),
  terapisWicara('Terapis wicara'),
  terapisOkupasi('Terapis okupasi'),
  psikologAnak('Psikolog anak'),
  dokterTumbuhKembang('Dokter tumbuh kembang');

  const JenisLayanan(this.label);

  final String label;

  /// Whether a professional's specialisation belongs to this filter.
  bool cocok(String spesialisasi) {
    if (this == semua) return true;
    return spesialisasi.toLowerCase().contains(label.toLowerCase());
  }
}

/// A listing on L.9 and L.10.
///
/// The full name is present here and that is correct: a professional directory
/// is a public listing the professional consented to. The community is the
/// opposite case, and its model carries an initial instead - see
/// `komunitas.dart`.
class Profesional {
  const Profesional({
    required this.id,
    required this.namaLengkap,
    required this.spesialisasi,
    required this.terverifikasi,
    this.gelar,
    this.tentang,
    this.layanan = const [],
    this.jadwalPraktik = const [],
    this.kota,
    this.posisi,
  });

  factory Profesional.fromMap(Map<String, dynamic> m) => Profesional(
    id: m['id'] as String,
    namaLengkap: m['nama_lengkap'] as String,
    spesialisasi: m['spesialisasi'] as String,
    terverifikasi: (m['terverifikasi'] as bool?) ?? false,
    gelar: m['gelar'] as String?,
    tentang: m['tentang'] as String?,
    layanan: [for (final l in (m['layanan'] as List? ?? [])) l as String],
    jadwalPraktik: [
      for (final j in (m['jadwal_praktik'] as List? ?? []))
        JamPraktik.fromMap(j as Map<String, dynamic>),
    ],
    kota: m['kota'] as String?,
    posisi: _posisi(m['lokasi_lat'], m['lokasi_lng']),
  );

  final String id;
  final String namaLengkap;
  final String spesialisasi;

  /// KF-12. Shown as a badge with a label, never as colour alone.
  final bool terverifikasi;

  final String? gelar;
  final String? tentang;
  final List<String> layanan;
  final List<JamPraktik> jadwalPraktik;
  final String? kota;

  /// Null when the practice never filled in coordinates. Those sort last on
  /// L.9 rather than appearing to be nearby - see [urutkanTerdekat].
  final Koordinat? posisi;

  /// Two letters, for the avatar field on the card.
  String get inisial {
    final kata = namaLengkap.trim().split(RegExp(r'\s+'));
    if (kata.isEmpty || kata.first.isEmpty) return '?';
    final pertama = kata.first[0];
    final kedua = kata.length > 1 && kata[1].isNotEmpty ? kata[1][0] : '';
    return (pertama + kedua).toUpperCase();
  }

  /// "Sri Handayani, M.Psi." when a title is recorded.
  String get namaDenganGelar =>
      gelar == null || gelar!.isEmpty ? namaLengkap : '$namaLengkap, $gelar';

  static Koordinat? _posisi(Object? lat, Object? lng) {
    if (lat is! num || lng is! num) return null;
    final k = Koordinat(lat.toDouble(), lng.toDouble());
    return k.sah ? k : null;
  }
}

/// One row of the practice timetable on L.10.
class JamPraktik {
  const JamPraktik({required this.hari, required this.jam});

  factory JamPraktik.fromMap(Map<String, dynamic> m) => JamPraktik(
    hari: (m['hari'] ?? '') as String,
    jam: (m['jam'] ?? '') as String,
  );

  final String hari;
  final String jam;

  Map<String, dynamic> toMap() => {'hari': hari, 'jam': jam};
}

/// Status of a schedule request (L.10).
///
/// There is no 'dibayar' and no 'sesi_berjalan' here, and there is no column
/// for either in the database. Bab 4.1 rules out payment and in-app sessions,
/// so a request is only ever waiting, answered, or withdrawn.
enum StatusPengajuan {
  menunggu('Menunggu jawaban', 'menunggu'),
  disetujui('Disetujui', 'disetujui'),
  ditolak('Belum dapat dipenuhi', 'ditolak'),
  dibatalkan('Dibatalkan', 'dibatalkan');

  const StatusPengajuan(this.label, this.dbValue);

  final String label;
  final String dbValue;

  static StatusPengajuan fromDb(String v) => StatusPengajuan.values.firstWhere(
    (s) => s.dbValue == v,
    orElse: () => StatusPengajuan.menunggu,
  );
}

class PengajuanJadwal {
  const PengajuanJadwal({
    required this.id,
    required this.profesionalId,
    required this.hari,
    required this.jam,
    required this.status,
    this.anakId,
    this.catatan,
    this.alasan,
    this.dibuatPada,
  });

  factory PengajuanJadwal.fromMap(Map<String, dynamic> m) => PengajuanJadwal(
    id: m['id'] as String,
    profesionalId: m['profesional_id'] as String,
    hari: m['hari'] as String,
    jam: m['jam'] as String,
    status: StatusPengajuan.fromDb(m['status'] as String? ?? 'menunggu'),
    anakId: m['anak_id'] as String?,
    catatan: m['catatan'] as String?,
    alasan: m['alasan'] as String?,
    dibuatPada: DateTime.tryParse(m['dibuat_pada'] as String? ?? ''),
  );

  final String id;
  final String profesionalId;
  final String hari;
  final String jam;
  final StatusPengajuan status;
  final String? anakId;
  final String? catatan;
  final String? alasan;
  final DateTime? dibuatPada;
}
