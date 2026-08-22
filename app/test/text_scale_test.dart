import 'package:dekapautis/core/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fakes.dart';
import 'support/rute.dart';

/// KNF-05: text scaling to 200% without the layout breaking.
///
/// Every screen is rendered at 1.0, 1.5 and 2.0 and the build fails on the
/// first overflow. This is not a cosmetic check. A caregiver who has enlarged
/// system text is exactly the user this app is for, and an overflow at 2.0 is
/// the difference between reading the boundary notice and not reading it.
///
/// The route list is walked out of the router itself rather than typed here.
/// A hand-kept list is a list that goes stale: the five screens F7 still owes
/// (L.9 to L.12, L.17) will be covered the moment they stop being placeholders,
/// with nobody having to remember to add them.
void main() {
  // Reading `appRouter` below constructs a GoRouter, which initializes a
  // WidgetsFlutterBinding of its own. Claim the test binding first or the whole
  // file fails to load before a single test runs.
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Small Android phone in logical pixels. Chosen as the worst realistic case
  /// rather than a comfortable one: at 2.0 this is the size where a Row of two
  /// buttons stops fitting, which is precisely what needs to be caught.
  const layarKecil = Size(360, 640);

  const faktor = <double>[1.0, 1.5, 2.0];

  /// Every concrete path in the route tree, with parameters filled in.
  final rute = kumpulkanRute(appRouter.configuration.routes);

  test('the walk found the whole route tree', () {
    // Guards the test itself: if the walk silently returned nothing, every
    // scaling test below would pass by doing no work at all.
    expect(rute.length, greaterThanOrEqualTo(20), reason: rute.join('\n'));
    expect(rute, contains('/beranda'));
    expect(rute, contains('/profil/aksesibilitas'));
    expect(rute, contains('/rencana/aktivitas/demo'));
  });

  for (final skala in faktor) {
    group('at ${skala}x text', () {
      for (final path in rute) {
        testWidgets(path, (tester) async {
          tester.view
            ..devicePixelRatio = 1.0
            ..physicalSize = layarKecil;
          tester.platformDispatcher.textScaleFactorTestValue = skala;
          addTearDown(tester.view.reset);
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

          final masalah = await _renderDanKumpulkanMasalah(tester, path);

          expect(
            masalah,
            isEmpty,
            reason:
                '$path at ${skala}x on ${layarKecil.width.toInt()}x'
                '${layarKecil.height.toInt()}:\n${masalah.join('\n')}',
          );
        });
      }
    });
  }
}

/// Renders one route and returns everything that went wrong laying it out.
///
/// Overflow is reported through [FlutterError.onError] during layout rather
/// than thrown, so it has to be captured rather than caught. Anything else the
/// frame reports is returned too: a screen that throws on an unknown id is just
/// as broken as one that overflows, and judges will deep-link to exactly that.
Future<List<String>> _renderDanKumpulkanMasalah(
  WidgetTester tester,
  String path,
) async {
  final masalah = <String>[];
  final sebelumnya = FlutterError.onError;
  FlutterError.onError = (details) =>
      masalah.add(details.exceptionAsString().split('\n').first);

  try {
    // Navigate before the first pump, not after. `appRouter` is a global, so
    // pumping first renders whatever route the previous test left behind and
    // attributes its overflow to this one - which made the suite pass or fail
    // depending on the order tests happened to run in.
    appRouter.go(path);
    await tester.pumpWidget(aplikasiUji());
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
  } finally {
    FlutterError.onError = sebelumnya;
  }

  // Drain anything the binding recorded before the override was installed, so
  // it is not carried into the next test as a phantom failure.
  tester.takeException();
  return masalah;
}
