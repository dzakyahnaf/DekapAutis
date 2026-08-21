import 'package:dekapautis/core/router/app_router.dart';
import 'package:dekapautis/core/theme/app_theme.dart';
import 'package:dekapautis/core/theme/tokens.dart';
import 'package:dekapautis/shared/widgets/buttons.dart';
import 'package:dekapautis/shared/widgets/calm_mode_switch.dart';
import 'package:dekapautis/shared/widgets/category_pill.dart';
import 'package:dekapautis/shared/widgets/offline_banner.dart';
import 'package:dekapautis/shared/widgets/routine_card.dart';
import 'package:dekapautis/shared/widgets/safety_banner.dart';
import 'package:dekapautis/shared/widgets/source_chip.dart';
import 'package:dekapautis/shared/widgets/states.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fakes.dart';

/// Nothing interactive may be smaller than 48x48 dp.
///
/// This is checked at the point widgets are written rather than retrofitted in
/// F8, because a control that is too small is not a cosmetic defect here: the
/// people using this app are often holding a child with one hand, and the
/// caregiver check-in and the three response buttons are the controls they
/// reach for most.
void main() {
  Widget host(Widget child, {double textScale = 1.0}) => ProviderScope(
    child: MaterialApp(
      theme: DekapTheme.build(calm: false, spacingScale: 0),
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: Scaffold(
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(DekapSpace.screenPadding),
              child: child,
            ),
          ),
        ),
      ),
    ),
  );

  /// Measures every render box that actually handles a pointer, rather than
  /// trusting the semantics-based guideline alone. Returns the offenders.
  List<String> undersizedTapTargets(WidgetTester tester) {
    final offenders = <String>[];
    final seen = <RenderBox>{};

    for (final type in <Type>[
      InkWell,
      InkResponse,
      GestureDetector,
      IconButton,
      Switch,
      FilledButton,
      OutlinedButton,
      TextButton,
    ]) {
      for (final element in find.byType(type).evaluate()) {
        final box = element.renderObject;
        if (box is! RenderBox || !box.hasSize || !seen.add(box)) continue;
        final size = box.size;
        if (size.isEmpty) continue;
        if (size.width < DekapSpace.minTouch ||
            size.height < DekapSpace.minTouch) {
          offenders.add(
            '$type ${size.width.toStringAsFixed(1)}x'
            '${size.height.toStringAsFixed(1)}',
          );
        }
      }
    }
    return offenders;
  }

  /// Each entry renders one interactive shared widget in isolation.
  final cases = <String, Widget>{
    'PrimaryButton': PrimaryButton(label: 'Simpan catatan', onPressed: () {}),
    'PrimaryButton (menyusut)': Align(
      alignment: Alignment.centerLeft,
      child: PrimaryButton(label: 'Ya', onPressed: () {}, expand: false),
    ),
    'SecondaryButton': SecondaryButton(
      label: 'Buat laporan untuk dokter',
      onPressed: () {},
    ),
    'SourceChip': Align(
      alignment: Alignment.centerLeft,
      child: SourceChip(number: 3, onOpen: () {}),
    ),
    'CalmModeSwitch': const CalmModeSwitch(),
    'EmptyState dengan aksi': EmptyState(
      message: 'Belum ada catatan minggu ini.',
      actionLabel: 'Buka rencana',
      onAction: () {},
    ),
    'ErrorState dengan coba lagi': ErrorState(
      message: 'Layanan sedang tidak dapat dihubungi.',
      onRetry: () {},
    ),
    'RoutineCard': RoutineCard(
      position: 1,
      total: 5,
      time: '08.00',
      durationMinutes: 10,
      category: DekapCategory.komunikasi,
      title: 'Menamai benda di meja makan',
      onRespond: (_) {},
      onOpen: () {},
    ),
    'SafetyBanner dengan dua aksi': SafetyBanner(
      title: 'DekapAutis tidak dapat mendiagnosis',
      body: 'Penilaian spektrum hanya dapat dilakukan tenaga profesional.',
      canHelpWith: const ['Menyusun rutinitas pagi yang dapat diprediksi'],
      actions: [
        PrimaryButton(label: 'Lihat profesional terdekat', onPressed: () {}),
        SecondaryButton(label: 'Buat laporan untuk dokter', onPressed: () {}),
      ],
    ),
  };

  group('shared widgets meet 48x48 dp', () {
    for (final entry in cases.entries) {
      testWidgets(entry.key, (tester) async {
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(host(entry.value));
        await tester.pump();

        final offenders = undersizedTapTargets(tester);
        expect(
          offenders,
          isEmpty,
          reason:
              '${entry.key} has controls below '
              '${DekapSpace.minTouch}dp: ${offenders.join(', ')}',
        );

        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        handle.dispose();
      });
    }
  });

  group('targets survive text scaling', () {
    // KNF-05 asks for 200% text. A control that grows past 48dp is fine; one
    // that a larger label squeezes below it is not.
    for (final scale in <double>[1.5, 2.0]) {
      testWidgets('every shared widget at ${scale}x', (tester) async {
        final handle = tester.ensureSemantics();
        for (final entry in cases.entries) {
          await tester.pumpWidget(host(entry.value, textScale: scale));
          await tester.pump();

          expect(
            undersizedTapTargets(tester),
            isEmpty,
            reason: '${entry.key} shrinks below the minimum at ${scale}x',
          );
        }
        handle.dispose();
      });
    }
  });

  group('non-interactive widgets are not tap targets', () {
    testWidgets('OfflineBanner reports state without being pressable', (
      tester,
    ) async {
      await tester.pumpWidget(host(const OfflineBanner(pendingCount: 3)));
      expect(find.byType(InkWell), findsNothing);
      expect(find.byType(GestureDetector), findsNothing);
      expect(find.textContaining('3 catatan'), findsOneWidget);
    });

    testWidgets('CategoryPill is a label, not a button', (tester) async {
      await tester.pumpWidget(
        host(const CategoryPill(category: DekapCategory.sosial)),
      );
      expect(find.byType(InkWell), findsNothing);
      expect(find.text('Sosial'), findsOneWidget);
    });
  });

  group('navigation shell', () {
    testWidgets('five bottom destinations are all reachable by touch', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(aplikasiUji());
      appRouter.go('/beranda');
      await tester.pumpAndSettle();

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });
  });
}
