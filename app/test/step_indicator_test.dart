import 'package:dekapautis/core/theme/app_theme.dart';
import 'package:dekapautis/core/theme/tokens.dart';
import 'package:dekapautis/shared/widgets/step_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The onboarding progress bar must be static.
///
/// This is easy to regress: reaching for AnimatedContainer to make a progress
/// bar "feel nicer" is the most natural thing in the world, and nothing in
/// `flutter analyze` would object. A bar that fills on every step is a small
/// repeating movement, which is the one pattern this product will not ship, so
/// the check lives here instead.
void main() {
  Widget host(Widget child) => MaterialApp(
    theme: DekapTheme.build(calm: false, spacingScale: 0),
    home: Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(DekapSpace.screenPadding),
        child: child,
      ),
    ),
  );

  group('static by construction', () {
    testWidgets('no implicitly animated widget anywhere in the subtree', (
      tester,
    ) async {
      await tester.pumpWidget(host(const StepIndicator(langkahSaatIni: 2)));

      final terlarang = <Type>[
        AnimatedContainer,
        AnimatedOpacity,
        AnimatedAlign,
        AnimatedPadding,
        AnimatedPositioned,
        AnimatedSize,
        AnimatedSwitcher,
        AnimatedCrossFade,
        AnimatedDefaultTextStyle,
        AnimatedPhysicalModel,
        AnimatedRotation,
        AnimatedScale,
        AnimatedSlide,
        FadeTransition,
        ScaleTransition,
        SlideTransition,
        SizeTransition,
        RotationTransition,
        DecoratedBoxTransition,
        LinearProgressIndicator,
        CircularProgressIndicator,
      ];

      // Scoped to the indicator's own subtree: MaterialApp and Scaffold bring
      // their own transitions, and finding those would prove nothing.
      for (final t in terlarang) {
        expect(
          find.descendant(
            of: find.byType(StepIndicator),
            matching: find.byType(t),
          ),
          findsNothing,
          reason: '$t membuat indikator bergerak; indikator harus statis',
        );
      }
    });

    testWidgets('nothing is scheduled, so no frame is ever repainted', (
      tester,
    ) async {
      await tester.pumpWidget(host(const StepIndicator(langkahSaatIni: 3)));

      // pumpAndSettle returns the number of frames it had to pump. A widget
      // with any running animation forces more than one; a truly static widget
      // settles on the first.
      final frames = await tester.pumpAndSettle();
      expect(frames, 1, reason: 'ada animasi yang masih berjalan');

      expect(
        tester.binding.transientCallbackCount,
        0,
        reason: 'ada ticker aktif; indikator harus statis',
      );
    });

    testWidgets('changing the step redraws without transition frames', (
      tester,
    ) async {
      await tester.pumpWidget(host(const StepIndicator(langkahSaatIni: 1)));
      await tester.pumpWidget(host(const StepIndicator(langkahSaatIni: 4)));

      // One pump is enough for the new state to be fully on screen. An
      // animated bar would still be mid-transition here.
      expect(tester.binding.transientCallbackCount, 0);
      expect(await tester.pumpAndSettle(), 1);
    });
  });

  group('reads correctly', () {
    testWidgets('has exactly four segments', (tester) async {
      await tester.pumpWidget(host(const StepIndicator(langkahSaatIni: 2)));
      expect(
        find.descendant(
          of: find.byType(StepIndicator),
          matching: find.byType(Container),
        ),
        findsNWidgets(4),
      );
    });

    testWidgets('completed segments differ by height as well as colour', (
      tester,
    ) async {
      await tester.pumpWidget(host(const StepIndicator(langkahSaatIni: 2)));

      final tinggi = tester
          .widgetList<Container>(
            find.descendant(
              of: find.byType(StepIndicator),
              matching: find.byType(Container),
            ),
          )
          .map((c) => c.constraints?.maxHeight)
          .toList();

      // Segments 1-2 done, 3-4 pending. Someone who cannot separate the two
      // purples still sees the difference.
      expect(tinggi[0], tinggi[1]);
      expect(tinggi[2], tinggi[3]);
      expect(tinggi[0], isNot(tinggi[2]));
    });

    testWidgets('announces the step to a screen reader', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(const StepIndicator(langkahSaatIni: 3)));

      expect(
        find.bySemanticsLabel('Langkah 3 dari 4'),
        findsOneWidget,
        reason: 'deretan kotak tanpa label tidak berarti apa pun bagi TalkBack',
      );
      handle.dispose();
    });
  });
}
