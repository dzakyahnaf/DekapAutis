import 'package:dekapautis/core/theme/tokens.dart';
import 'package:dekapautis/data/models/response_level.dart';
import 'package:dekapautis/domain/adaptasi/adaptation_engine.dart';
import 'package:flutter_test/flutter_test.dart';

/// The domain enums and the presentation enums must not drift apart.
///
/// There are deliberately two of each. `DekapCategory` carries a Color and an
/// IconData, so it drags Flutter in with it, and the adaptation engine has to
/// stay free of Flutter entirely. A category is a domain idea; its colour is a
/// presentation detail.
///
/// Duplication like that is exactly the kind that rots quietly - someone adds a
/// sixth category to one enum and the engine silently ignores it for months.
/// This is the guard that makes the split safe instead of merely tidy.
void main() {
  test(
    'Kategori and DekapCategory hold the same values, in the same order',
    () {
      expect(
        Kategori.values.map((k) => k.dbValue).toList(),
        DekapCategory.values.map((c) => c.dbValue).toList(),
      );
    },
  );

  test('their Indonesian labels match', () {
    for (var i = 0; i < Kategori.values.length; i++) {
      expect(Kategori.values[i].label, DekapCategory.values[i].label);
    }
  });

  test('every category maps in both directions', () {
    for (final k in Kategori.values) {
      expect(DekapCategory.fromDb(k.dbValue).dbValue, k.dbValue);
    }
    for (final c in DekapCategory.values) {
      expect(Kategori.fromDb(c.dbValue).dbValue, c.dbValue);
    }
  });

  test('NilaiRespons and ResponseLevel hold the same values, in order', () {
    expect(
      NilaiRespons.values.map((n) => n.dbValue).toList(),
      ResponseLevel.values.map((r) => r.dbValue).toList(),
    );
    for (var i = 0; i < NilaiRespons.values.length; i++) {
      expect(NilaiRespons.values[i].label, ResponseLevel.values[i].label);
    }
  });

  test('the response weights are the ones docs/04 maps: +1, 0, -1', () {
    expect(NilaiRespons.mudah.bobot, 1);
    expect(NilaiRespons.pas.bobot, 0);
    expect(NilaiRespons.sulit.bobot, -1);
    for (var i = 0; i < NilaiRespons.values.length; i++) {
      expect(NilaiRespons.values[i].bobot, ResponseLevel.values[i].weight);
    }
  });
}
