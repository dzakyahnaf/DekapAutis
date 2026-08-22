import '../../domain/adaptasi/kategori.dart';

/// Models for the professional's inbox and the three administrator screens.

/// One report as it appears in a professional's inbox.
///
/// Reaching this at all means the caregiver granted permission for this
/// specific report, and RLS is what enforces that - there is no client-side
/// filter here doing the same job more weakly.
class LaporanMasuk {
  const LaporanMasuk({
    required this.id,
    required this.profilAnakId,
    required this.periodeMulai,
    required this.periodeSelesai,
    required this.ringkasan,
    required this.penandaPerhatian,
    required this.sudahDitanggapi,
    this.namaAnak,
    this.usiaAnak,
    this.dibuatPada,
  });

  factory LaporanMasuk.fromMap(Map<String, dynamic> m) {
    final anak = m['profil_anak'] as Map<String, dynamic>?;
    final tanggapan = m['tanggapan_profesional'] as List?;

    return LaporanMasuk(
      id: m['id'] as String,
      profilAnakId: m['profil_anak_id'] as String,
      periodeMulai:
          DateTime.tryParse(m['periode_mulai'] as String? ?? '') ??
          DateTime.now(),
      periodeSelesai:
          DateTime.tryParse(m['periode_selesai'] as String? ?? '') ??
          DateTime.now(),
      ringkasan: m['ringkasan'] as String? ?? '',
      penandaPerhatian: [
        for (final p in (m['penanda_perhatian'] as List? ?? [])) p as String,
      ],
      sudahDitanggapi: (tanggapan?.isNotEmpty ?? false),
      namaAnak: anak?['nama_panggilan'] as String?,
      usiaAnak: (anak?['usia'] as num?)?.toInt(),
      dibuatPada: DateTime.tryParse(m['dibuat_pada'] as String? ?? ''),
    );
  }

  final String id;
  final String profilAnakId;
  final DateTime periodeMulai;
  final DateTime periodeSelesai;
  final String ringkasan;

  /// Categories rule D flagged. These are why the report is in front of a
  /// professional, so they sort to the top of the inbox.
  final List<String> penandaPerhatian;

  final bool sudahDitanggapi;
  final String? namaAnak;
  final int? usiaAnak;
  final DateTime? dibuatPada;

  bool get perluPerhatian => penandaPerhatian.isNotEmpty;

  /// Flagged and unanswered first: a professional opening the inbox should see
  /// the reports somebody is waiting on, not the newest.
  int get prioritas => (sudahDitanggapi ? 2 : 0) + (perluPerhatian ? 0 : 1);

  List<Kategori> get kategoriPerhatian => [
    for (final nama in penandaPerhatian)
      ...Kategori.values.where((k) => k.name == nama),
  ];
}

/// A response, from either side of the loop.
class TanggapanProfesional {
  const TanggapanProfesional({
    required this.id,
    required this.laporanId,
    required this.isi,
    required this.saranKategori,
    required this.status,
    this.saranDurasiMenit,
    this.dibuatPada,
  });

  factory TanggapanProfesional.fromMap(Map<String, dynamic> m) =>
      TanggapanProfesional(
        id: m['id'] as String,
        laporanId: m['laporan_id'] as String,
        isi: m['isi'] as String,
        saranKategori: [
          for (final k in (m['saran_kategori'] as List? ?? []))
            ...Kategori.values.where((v) => v.name == k),
        ],
        status: StatusTanggapan.fromDb(m['status'] as String? ?? 'baru'),
        saranDurasiMenit: (m['saran_durasi_menit'] as num?)?.toInt(),
        dibuatPada: DateTime.tryParse(m['dibuat_pada'] as String? ?? ''),
      );

  final String id;
  final String laporanId;

  /// The prose. Shown to the caregiver, never parsed.
  final String isi;

  /// The actionable part.
  final List<Kategori> saranKategori;
  final int? saranDurasiMenit;

  final StatusTanggapan status;
  final DateTime? dibuatPada;

  bool get punyaSaran => saranKategori.isNotEmpty || saranDurasiMenit != null;
}

enum StatusTanggapan {
  baru('Belum dibaca', 'baru'),
  dibaca('Sudah dibaca', 'dibaca'),
  diterapkan('Sudah diterapkan ke rencana', 'diterapkan'),
  ditolak('Tidak diterapkan', 'ditolak');

  const StatusTanggapan(this.label, this.dbValue);

  final String label;
  final String dbValue;

  static StatusTanggapan fromDb(String v) => StatusTanggapan.values.firstWhere(
    (s) => s.dbValue == v,
    orElse: () => StatusTanggapan.baru,
  );
}

/// Verification state of a practice, as the admin queue sees it.
enum StatusVerifikasi {
  menunggu('Menunggu ditinjau', 'menunggu'),
  disetujui('Disetujui', 'disetujui'),
  ditolak('Ditolak', 'ditolak');

  const StatusVerifikasi(this.label, this.dbValue);

  final String label;
  final String dbValue;

  static StatusVerifikasi fromDb(String v) =>
      StatusVerifikasi.values.firstWhere(
        (s) => s.dbValue == v,
        orElse: () => StatusVerifikasi.menunggu,
      );
}

/// A report of abuse, as the moderation queue sees it.
class LaporanPenyalahgunaan {
  const LaporanPenyalahgunaan({
    required this.id,
    required this.kategori,
    required this.status,
    this.postinganId,
    this.balasanId,
    this.frasa,
    this.catatan,
    this.dibuatPada,
  });

  factory LaporanPenyalahgunaan.fromMap(Map<String, dynamic> m) =>
      LaporanPenyalahgunaan(
        id: m['id'] as String,
        kategori: m['kategori'] as String,
        status: m['status'] as String? ?? 'menunggu',
        postinganId: m['postingan_id'] as String?,
        balasanId: m['balasan_id'] as String?,
        frasa: m['frasa'] as String?,
        catatan: m['catatan'] as String?,
        dibuatPada: DateTime.tryParse(m['dibuat_pada'] as String? ?? ''),
      );

  final String id;
  final String kategori;
  final String status;
  final String? postinganId;
  final String? balasanId;

  /// What the client-side filter matched, when the filter raised this. Kept so
  /// a false positive can be traced to its phrase rather than argued about.
  final String? frasa;

  final String? catatan;
  final DateTime? dibuatPada;

  String get kategoriLabel => switch (kategori) {
    'batas_medis' => 'Menyentuh batas medis',
    'kasar' => 'Bahasa yang merendahkan',
    'spam' => 'Promosi atau spam',
    _ => 'Lainnya',
  };
}
