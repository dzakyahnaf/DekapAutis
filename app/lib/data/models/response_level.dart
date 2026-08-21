import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';

/// The three-level response a caregiver records after an activity (KF-05).
///
/// Deliberately three levels and no more: a finer scale invites the caregiver
/// to grade the child, and this app never produces a single score of a child's
/// ability. Mirrors the `nilai` check constraint on `catatan_respons`.
enum ResponseLevel {
  mudah('Mudah', 1, Symbols.sentiment_satisfied_rounded),
  pas('Pas', 0, Symbols.remove_rounded),
  sulit('Sulit', -1, Symbols.sentiment_dissatisfied_rounded);

  const ResponseLevel(this.label, this.weight, this.icon);

  /// Indonesian label shown on the button.
  final String label;

  /// Numeric mapping used by the adaptation engine: mudah +1, pas 0, sulit -1.
  final int weight;

  final IconData icon;

  String get dbValue => name;

  static ResponseLevel fromDb(String value) =>
      ResponseLevel.values.firstWhere((r) => r.name == value);
}
