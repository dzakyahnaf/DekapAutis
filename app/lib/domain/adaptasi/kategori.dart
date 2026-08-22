/// Pure domain vocabulary for the adaptation engine.
///
/// Deliberately separate from `DekapCategory` in `core/theme/tokens.dart`.
/// That one carries a Color and an IconData, so it drags Flutter in with it,
/// and the engine must stay free of Flutter entirely. A category is a domain
/// idea; its colour is a presentation detail.
///
/// The duplication is small and guarded: `kategori_sinkron_test.dart` fails if
/// the two ever stop matching.
library;

enum Kategori {
  komunikasi('Komunikasi'),
  motorik('Motorik'),
  sensorik('Sensorik'),
  kemandirian('Kemandirian'),
  sosial('Sosial');

  const Kategori(this.label);

  /// Indonesian label, used in the reasons written to adaptasi_log.
  final String label;

  /// Matches the `kategori` check constraint in the database.
  String get dbValue => name;

  static Kategori fromDb(String value) =>
      Kategori.values.firstWhere((k) => k.name == value);
}

/// The three-level response, as the engine sees it.
///
/// Three levels and no more, on purpose. A finer scale invites the caregiver to
/// grade the child, and Bab 4.2 forbids this product from producing a single
/// score of a child's ability.
enum NilaiRespons {
  mudah('Mudah', 1),
  pas('Pas', 0),
  sulit('Sulit', -1);

  const NilaiRespons(this.label, this.bobot);

  final String label;

  /// mudah +1, pas 0, sulit -1 (docs/04 §3).
  final int bobot;

  String get dbValue => name;

  static NilaiRespons fromDb(String value) =>
      NilaiRespons.values.firstWhere((n) => n.name == value);
}

/// One recorded response, reduced to what the rules actually need.
class CatatanUntukAdaptasi {
  const CatatanUntukAdaptasi({
    required this.kategori,
    required this.nilai,
    required this.dicatatPada,
    required this.jamJadwal,
  });

  final Kategori kategori;
  final NilaiRespons nilai;
  final DateTime dicatatPada;

  /// Hour the activity was *scheduled* for, not when the note was typed.
  /// Rule E_jadwal is about which time of day works, and a caregiver writing
  /// the note up at bedtime says nothing about that.
  final int jamJadwal;
}
