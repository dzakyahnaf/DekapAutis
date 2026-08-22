/// Community moderation, layer one.
///
/// A word filter cannot make a community safe on its own, and pretending
/// otherwise is how moderation gets neglected. This catches the obvious before
/// it is published; the abuse queue an administrator works through catches what
/// it misses. Both are needed, and docs/05 asks for both.
///
/// Two categories, and they are treated differently on purpose:
///
///   * [KategoriModerasi.batasMedis] - a post recommending a drug or claiming a
///     cure. The same boundary the assistant enforces applies to what parents
///     tell each other here: a dosage passed between caregivers is no safer for
///     having come from a person.
///   * [KategoriModerasi.kasar] - abuse and slurs, including the words used
///     about disabled children. Those are held to the same line as any other
///     slur, which is not a line most word lists bother to draw.
///
/// Phrases with word boundaries, never bare words - the same reason as the
/// assistant lexicon. "obat" appears in "obat nyamuk", and a support forum
/// where parents cannot mention mosquito repellent is not a support forum.
library;

enum KategoriModerasi {
  batasMedis('Menyentuh batas medis'),
  kasar('Bahasa yang merendahkan');

  const KategoriModerasi(this.label);

  final String label;
}

class HasilModerasi {
  const HasilModerasi.lolos()
    : perluDitinjau = false,
      kategori = null,
      frasa = null;

  const HasilModerasi.tertahan(this.kategori, this.frasa)
    : perluDitinjau = true;

  final bool perluDitinjau;
  final KategoriModerasi? kategori;
  final String? frasa;

  /// What the author is told. Never an accusation: most posts that trip this
  /// are written by a worried parent repeating something they were told.
  String get pesan => switch (kategori) {
    KategoriModerasi.batasMedis =>
      'Tulisan ini menyentuh anjuran obat, dosis, atau kesembuhan. DekapAutis '
          'tidak membahas hal itu antar pengguna, karena keputusannya hanya '
          'boleh diambil dokter yang memeriksa anak secara langsung. Anda dapat '
          'menuliskannya kembali sebagai pengalaman, tanpa anjuran.',
    KategoriModerasi.kasar =>
      'Ada kata yang merendahkan di tulisan ini. Ubah bagian itu, lalu kirim '
          'kembali.',
    null => '',
  };
}

String _normalkan(String teks) => teks
    .toLowerCase()
    .replaceAll(RegExp(r'[^\p{L}\p{N}\s-]', unicode: true), ' ')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

/// Household products Indonesian also calls "obat". Mosquito coils, mouthwash,
/// weedkiller - none of them are something a parent gives a child, and a forum
/// where you cannot say you burn obat nyamuk at night is not a forum.
const _bukanObatAnak =
    r'(?!\s+(?:nyamuk|serangga|tikus|kutu|rumput|kumur|pel))';

final _batasMedis = <RegExp>[
  RegExp(
    r'\bobat'
    '$_bukanObatAnak'
    r'\s+(?:apa|yang|untuk|buat|ini|itu)\b',
  ),
  RegExp(
    r'\b(?:coba|pakai|kasih|beri|berikan|minum)\b[^.?!]{0,20}\bobat'
    '$_bukanObatAnak'
    r'\b',
  ),
  RegExp(r'\bdosis(?:nya)?\b'),
  RegExp(r'\btakaran(?:nya)?\b'),
  RegExp(r'\b\d+\s*(?:mg|miligram|ml|tetes|kapsul|tablet)\b'),
  RegExp(r'\brisperidon(?:e)?\b|\bmelatonin\b|\babilify\b|\britalin\b'),
  RegExp(r'\bsuplemen\s+(?:apa|yang|untuk|ini|itu)\b'),
  RegExp(
    r'\b(?:bisa|dapat|pasti|akan)\b[^.?!]{0,20}\b(?:sembuh|disembuhkan)\b',
  ),
  RegExp(r'\bcara\s+(?:menyembuhkan|mengobati)\b'),
  RegExp(r'\bkhelasi\b|\bkelasi logam\b|\bhiperbarik\b'),
  RegExp(r'\bterbukti\s+(?:sembuh|menyembuhkan|manjur)\b'),
];

final _kasar = <RegExp>[
  // Slurs aimed at disabled children. They appear in Indonesian parenting
  // forums often enough that leaving them out would be a choice, not an
  // oversight.
  RegExp(r'\b(?:idiot|bego|goblok|tolol|bodoh)\b'),
  RegExp(r'\bketerbelakangan\b|\bketerbelakang\b'),
  RegExp(r'\bcacat\b(?!\s*catat)'),
  RegExp(r'\bgila\b|\bsinting\b|\bstres+\s*berat\b'),
  RegExp(r'\banak\s+(?:aneh|abnormal|rusak)\b'),
  RegExp(r'\bkutuk(?:an)?\b|\bkarma\b'),
  RegExp(r'\bsalah\s+(?:ibu|orang tua|bunda)\b'),
  RegExp(r'\bgak\s+becus\b|\btidak\s+becus\b'),
];

/// Checks one post or reply before it is published.
HasilModerasi periksaTulisan(String teks) {
  final bersih = _normalkan(teks);

  for (final p in _batasMedis) {
    final cocok = bersih.firstMatch(p);
    if (cocok != null) {
      return HasilModerasi.tertahan(KategoriModerasi.batasMedis, cocok);
    }
  }
  for (final p in _kasar) {
    final cocok = bersih.firstMatch(p);
    if (cocok != null) {
      return HasilModerasi.tertahan(KategoriModerasi.kasar, cocok);
    }
  }
  return const HasilModerasi.lolos();
}

extension on String {
  String? firstMatch(RegExp p) => p.firstMatch(this)?.group(0);
}
