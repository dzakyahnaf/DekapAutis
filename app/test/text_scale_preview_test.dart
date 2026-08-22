import 'package:dekapautis/core/accessibility/accessibility_prefs.dart';
import 'package:dekapautis/core/theme/app_theme.dart';
import 'package:dekapautis/core/theme/calm.dart';
import 'package:dekapautis/features/profile/preferensi_aksesibilitas.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// The text size preview on L.15 has to actually change.
///
/// A preview that stays the same size is worse than no preview at all: it
/// teaches the person who most needs larger text that the control does nothing,
/// and they stop looking. So this measures the rendered sample rather than
/// checking that a variable was set.
void main() {
  Widget host() => ProviderScope(
    child: MaterialApp(
      theme: DekapTheme.build(calm: const DekapCalm()),
      home: const Scaffold(
        body: SingleChildScrollView(child: PreferensiAksesibilitasPanel()),
      ),
    ),
  );

  /// Font size the sample is really painted at, read off the render tree.
  double ukuranSampel(WidgetTester tester) {
    final teks = tester.renderObject<RenderParagraph>(
      find.byKey(PratinjauUkuranTeks.kunciContoh),
    );
    return teks.textScaler.scale(teks.text.style!.fontSize!);
  }

  testWidgets('sample grows when a larger size is chosen', (tester) async {
    await tester.pumpWidget(host());

    final standar = ukuranSampel(tester);

    await tester.tap(find.text(DekapTextScale.besar.label));
    await tester.pumpAndSettle();
    final besar = ukuranSampel(tester);

    await tester.tap(find.text(DekapTextScale.sangatBesar.label));
    await tester.pumpAndSettle();
    final sangatBesar = ukuranSampel(tester);

    expect(
      besar,
      greaterThan(standar),
      reason: 'pratinjau tidak berubah saat "Besar" dipilih',
    );
    expect(
      sangatBesar,
      greaterThan(besar),
      reason: 'pratinjau tidak berubah saat "Sangat besar" dipilih',
    );

    // And by the amount the tokens promise, not merely "a bit bigger".
    expect(
      besar / standar,
      closeTo(
        DekapTextScale.besar.factor / DekapTextScale.standar.factor,
        0.01,
      ),
    );
    expect(
      sangatBesar / standar,
      closeTo(
        DekapTextScale.sangatBesar.factor / DekapTextScale.standar.factor,
        0.01,
      ),
    );
  });

  testWidgets('choosing a smaller size shrinks it back', (tester) async {
    await tester.pumpWidget(host());

    await tester.tap(find.text(DekapTextScale.sangatBesar.label));
    await tester.pumpAndSettle();
    final sangatBesar = ukuranSampel(tester);

    await tester.tap(find.text(DekapTextScale.standar.label));
    await tester.pumpAndSettle();
    final standar = ukuranSampel(tester);

    expect(standar, lessThan(sangatBesar));
  });

  testWidgets('the preview box is really taller on screen, not just in style', (
    tester,
  ) async {
    await tester.pumpWidget(host());
    final sebelum = tester.getSize(find.byKey(PratinjauUkuranTeks.kunciContoh));

    await tester.tap(find.text(DekapTextScale.sangatBesar.label));
    await tester.pumpAndSettle();
    final sesudah = tester.getSize(find.byKey(PratinjauUkuranTeks.kunciContoh));

    expect(
      sesudah.height,
      greaterThan(sebelum.height),
      reason: 'sampel harus benar-benar memakan ruang lebih banyak',
    );
  });

  testWidgets('the choice reaches the shared accessibility state', (
    tester,
  ) async {
    late WidgetRef ref;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: DekapTheme.build(calm: const DekapCalm()),
          home: Scaffold(
            body: Consumer(
              builder: (context, r, _) {
                ref = r;
                return const SingleChildScrollView(
                  child: PreferensiAksesibilitasPanel(),
                );
              },
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text(DekapTextScale.besar.label));
    await tester.pumpAndSettle();

    // The preview is not a local toy: the same state drives the whole app.
    expect(ref.read(accessibilityProvider).textScale, DekapTextScale.besar);
  });

  testWidgets('the resize is instant, not animated', (tester) async {
    await tester.pumpWidget(host());

    await tester.tap(find.text(DekapTextScale.sangatBesar.label));
    // Exactly one frame. The tap ripple is still running at this point - that
    // is one-shot touch feedback and is allowed - so counting scheduled frames
    // would measure the wrong thing. What matters is that the sample has
    // already reached its final size in that single frame: an animated resize
    // would still be part way there.
    await tester.pump();
    final satuFrame = tester.getSize(
      find.byKey(PratinjauUkuranTeks.kunciContoh),
    );

    await tester.pumpAndSettle();
    final setelahTenang = tester.getSize(
      find.byKey(PratinjauUkuranTeks.kunciContoh),
    );

    expect(
      satuFrame,
      setelahTenang,
      reason:
          'ukuran pratinjau masih berubah setelah frame pertama, '
          'berarti ada animasi',
    );
  });

  testWidgets('the preview subtree contains no implicit animation', (
    tester,
  ) async {
    await tester.pumpWidget(host());

    for (final t in <Type>[
      AnimatedContainer,
      AnimatedSize,
      AnimatedDefaultTextStyle,
      AnimatedSwitcher,
      AnimatedOpacity,
    ]) {
      expect(
        find.descendant(
          of: find.byType(PratinjauUkuranTeks),
          matching: find.byType(t),
        ),
        findsNothing,
        reason: '$t membuat pratinjau bergerak saat ukuran berubah',
      );
    }
  });
}
