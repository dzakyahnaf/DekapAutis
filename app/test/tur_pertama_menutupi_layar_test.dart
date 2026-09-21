import 'package:dekapautis/core/router/app_router.dart';
import 'package:dekapautis/features/onboarding/tur_pertama.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fakes.dart';

/// The first-run tour has to be given the screen it places itself on.
///
/// It was an unpositioned child of a Stack, which hands loose constraints
/// down: the tour shrank to the height of its own card and sat in the top
/// corner. The scrim then dimmed nothing, the card covered the greeting
/// instead of sitting under the plan it describes, and the home screen behind
/// it stayed live to touch - so it read as a banner stuck to the top rather
/// than as onboarding. Reported from a phone, with a screenshot of a purple
/// band across the top third.
void main() {
  testWidgets('tur menutupi seluruh layar, bukan hanya pita di atas', (
    tester,
  ) async {
    appRouter.go('/beranda');
    await tester.pumpWidget(
      aplikasiUji(auth: FakeAuthRepository(masuk_: true)),
    );
    await tester.pumpAndSettle();

    expect(find.byType(TurPertama), findsOneWidget, reason: 'tur tidak muncul');

    // Against the Stack it lives in rather than against a pixel count, so the
    // check holds at any screen size. Unpositioned, the tour took the height
    // of its own card - which on a tall phone is a band across the top third
    // and leaves the rest of the screen undimmed and live to touch.
    final induk = find
        .ancestor(of: find.byType(TurPertama), matching: find.byType(Stack))
        .first;
    expect(
      tester.getRect(find.byType(TurPertama)),
      tester.getRect(induk),
      reason: 'tur tidak mengisi layar yang ditumpanginya',
    );
  });

  testWidgets('kartunya duduk di bawah, tidak menutupi sapaan', (tester) async {
    appRouter.go('/beranda');
    await tester.pumpWidget(
      aplikasiUji(auth: FakeAuthRepository(masuk_: true)),
    );
    await tester.pumpAndSettle();

    final layar = tester.getRect(
      find
          .ancestor(of: find.byType(TurPertama), matching: find.byType(Stack))
          .first,
    );
    final kartu = tester.getRect(
      find
          .descendant(
            of: find.byType(TurPertama),
            matching: find.byType(Container),
          )
          .first,
    );

    // Bottom-aligned, which is what the widget's own layout asks for and what
    // it could not do while it was being handed the height of its own card.
    expect(
      layar.bottom - kartu.bottom,
      lessThan(48),
      reason: 'kartu tur tidak duduk di bawah layar',
    );
    expect(
      kartu.top,
      greaterThanOrEqualTo(layar.center.dy),
      reason: 'kartu tur menempel di atas, menutupi sapaan dan check-in',
    );
  });

  testWidgets('empat langkah, dan yang terakhir menutup tur', (tester) async {
    appRouter.go('/beranda');
    await tester.pumpWidget(
      aplikasiUji(auth: FakeAuthRepository(masuk_: true)),
    );
    await tester.pumpAndSettle();

    for (var i = 0; i < sorotanTur.length - 1; i++) {
      expect(
        find.text(sorotanTur[i]),
        findsOneWidget,
        reason: 'langkah ${i + 1} tidak tampil',
      );
      await tester.tap(find.text('Berikutnya'));
      await tester.pumpAndSettle();
    }

    expect(find.text(sorotanTur.last), findsOneWidget);
    expect(
      find.text('Berikutnya'),
      findsNothing,
      reason: 'langkah terakhir masih menawarkan "Berikutnya"',
    );

    await tester.tap(find.text('Mulai memakai'));
    await tester.pumpAndSettle();

    expect(
      find.byType(TurPertama),
      findsNothing,
      reason: 'tur tidak menutup setelah langkah terakhir',
    );
  });
}
