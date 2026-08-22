/// Community posts and replies, as they arrive from the server.
///
/// Note what these classes cannot represent: an author's name or user id.
/// `postingan_publik` and `balasan_publik` do not select those columns, so
/// there is nothing here to hold them and no way for a screen to render one by
/// accident. The anonymity guarantee is kept by the view in migration 008;
/// this file only makes it impossible to un-keep by mistake.
library;

/// Topic filter on L.11. Free text in the database, matched on the stored tag.
enum TopikKomunitas {
  semua('Semua', ''),
  rutinitas('Rutinitas', 'rutinitas'),
  sensorik('Sensorik', 'sensorik'),
  komunikasi('Komunikasi', 'komunikasi'),
  sekolah('Sekolah', 'sekolah'),
  dukungan('Dukungan pengasuh', 'dukungan');

  const TopikKomunitas(this.label, this.dbValue);

  final String label;
  final String dbValue;

  static TopikKomunitas fromDb(String v) => TopikKomunitas.values.firstWhere(
    (t) => t.dbValue == v,
    orElse: () => TopikKomunitas.semua,
  );
}

class Postingan {
  const Postingan({
    required this.id,
    required this.topik,
    required this.judul,
    required this.isi,
    required this.anonim,
    required this.jumlahBalasan,
    required this.milikSaya,
    this.inisial,
    this.dibuatPada,
  });

  factory Postingan.fromMap(Map<String, dynamic> m) => Postingan(
    id: m['id'] as String,
    topik: TopikKomunitas.fromDb(m['topik'] as String? ?? ''),
    judul: m['judul'] as String,
    isi: m['isi'] as String,
    anonim: (m['anonim'] as bool?) ?? false,
    jumlahBalasan: (m['jumlah_balasan'] as num?)?.toInt() ?? 0,
    milikSaya: (m['milik_saya'] as bool?) ?? false,
    inisial: m['inisial'] as String?,
    dibuatPada: DateTime.tryParse(m['dibuat_pada'] as String? ?? ''),
  );

  final String id;
  final TopikKomunitas topik;
  final String judul;
  final String isi;
  final bool anonim;
  final int jumlahBalasan;

  /// Whether the signed-in user wrote it, so the screen can offer edit and
  /// delete without ever learning who anybody else is.
  final bool milikSaya;

  /// Null for an anonymous post. Never a full name - the server does not send
  /// one.
  final String? inisial;

  final DateTime? dibuatPada;

  /// What the author chip shows.
  String get penulisTampil => anonim ? 'Anonim' : (inisial ?? '?');
}

class Balasan {
  const Balasan({
    required this.id,
    required this.postinganId,
    required this.isi,
    required this.anonim,
    required this.milikSaya,
    this.inisial,
    this.dibuatPada,
  });

  factory Balasan.fromMap(Map<String, dynamic> m) => Balasan(
    id: m['id'] as String,
    postinganId: m['postingan_id'] as String,
    isi: m['isi'] as String,
    anonim: (m['anonim'] as bool?) ?? false,
    milikSaya: (m['milik_saya'] as bool?) ?? false,
    inisial: m['inisial'] as String?,
    dibuatPada: DateTime.tryParse(m['dibuat_pada'] as String? ?? ''),
  );

  final String id;
  final String postinganId;
  final String isi;
  final bool anonim;
  final bool milikSaya;
  final String? inisial;
  final DateTime? dibuatPada;

  String get penulisTampil => anonim ? 'Anonim' : (inisial ?? '?');
}

/// Why something was reported, matching the `kategori` constraint on
/// `laporan_penyalahgunaan`.
enum AlasanLaporan {
  batasMedis('Anjuran obat atau klaim kesembuhan', 'batas_medis'),
  kasar('Bahasa yang merendahkan', 'kasar'),
  spam('Promosi atau spam', 'spam'),
  lainnya('Lainnya', 'lainnya');

  const AlasanLaporan(this.label, this.dbValue);

  final String label;
  final String dbValue;
}
