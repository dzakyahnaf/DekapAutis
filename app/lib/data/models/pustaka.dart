/// Library documents (L.12).
///
/// These are the same rows the assistant cites on L.4. That is deliberate: a
/// caregiver who reads an answer and then goes looking for the source should
/// land on the same document, not a parallel article written for the library.
library;

/// Review state, mirroring the `status_tinjauan` constraint on
/// `dokumen_pengetahuan`.
///
/// Shown as a chip with a word, never as colour alone. A caregiver deciding
/// how much weight to give a document needs to be told, not hinted at.
enum StatusTinjauan {
  menunggu('Menunggu tinjauan', 'menunggu'),
  ditinjau('Ditinjau profesional', 'ditinjau_profesional'),
  ditolak('Tidak lolos tinjauan', 'ditolak');

  const StatusTinjauan(this.label, this.dbValue);

  final String label;
  final String dbValue;

  static StatusTinjauan fromDb(String v) => StatusTinjauan.values.firstWhere(
    (s) => s.dbValue == v,
    orElse: () => StatusTinjauan.menunggu,
  );
}

/// The four cards at the top of L.12.
enum KategoriPustaka {
  terapiRumah('Terapi di rumah'),
  manajemenPerilaku('Manajemen perilaku'),
  nutrisi('Nutrisi'),
  kesehatanMentalOrangTua('Kesehatan mental orang tua');

  const KategoriPustaka(this.label);

  final String label;
}

class DokumenPustaka {
  const DokumenPustaka({
    required this.id,
    required this.judul,
    required this.penerbit,
    required this.tahun,
    required this.url,
    required this.status,
  });

  factory DokumenPustaka.fromMap(Map<String, dynamic> m) => DokumenPustaka(
    id: m['id'] as String,
    judul: m['judul'] as String,
    penerbit: m['penerbit'] as String,
    tahun: (m['tahun'] as num).toInt(),
    url: m['url'] as String,
    status: StatusTinjauan.fromDb(
      m['status_tinjauan'] as String? ?? 'menunggu',
    ),
  );

  final String id;
  final String judul;
  final String penerbit;
  final int tahun;

  /// Always a real, openable source. There are no invented documents in this
  /// corpus, so this is never a placeholder.
  final String url;

  final StatusTinjauan status;

  /// `Penerbit · 2024` for the card's second line.
  String get sumberRingkas => '$penerbit · $tahun';
}
