import 'package:dekapautis/core/theme/app_theme.dart';
import 'package:dekapautis/core/theme/tokens.dart';
import 'package:dekapautis/data/models/response_level.dart';
import 'package:dekapautis/shared/widgets/routine_card.dart';
import 'package:dekapautis/shared/widgets/safety_banner.dart';
import 'package:dekapautis/shared/widgets/source_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) => ProviderScope(
  child: MaterialApp(
    theme: DekapTheme.build(calm: false, spacingScale: 0),
    home: Scaffold(body: SingleChildScrollView(child: child)),
  ),
);

/// Behaviour of the shared widgets. Their 48dp tap targets are covered
/// separately in `touch_target_test.dart`.
void main() {
  group('source chip', () {
    testWidgets('renders its reference number', (tester) async {
      await tester.pumpWidget(
        _host(Align(child: SourceChip(number: 3, onOpen: () {}))),
      );
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('opens the source panel when pressed', (tester) async {
      var opened = 0;
      await tester.pumpWidget(
        _host(Align(child: SourceChip(number: 1, onOpen: () => opened++))),
      );
      await tester.tap(find.byType(SourceChip));
      await tester.pump();
      expect(opened, 1);
    });
  });

  group('routine card', () {
    testWidgets('shows all three response levels by their Indonesian labels', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          RoutineCard(
            position: 2,
            total: 5,
            time: '09.30',
            durationMinutes: 15,
            category: DekapCategory.sensorik,
            title: 'Meraba tiga tekstur berbeda',
            onRespond: (_) {},
          ),
        ),
      );

      for (final level in ResponseLevel.values) {
        expect(find.text(level.label), findsOneWidget);
      }
      expect(find.text('2 dari 5'), findsOneWidget);
      expect(find.text('Sensorik'), findsOneWidget);
    });

    testWidgets('reports the level the caregiver tapped', (tester) async {
      ResponseLevel? recorded;
      await tester.pumpWidget(
        _host(
          RoutineCard(
            position: 1,
            total: 3,
            time: '08.00',
            durationMinutes: 10,
            category: DekapCategory.motorik,
            title: 'Melompat di atas bantal',
            onRespond: (level) => recorded = level,
          ),
        ),
      );

      await tester.tap(find.text('Sulit'));
      await tester.pump();
      expect(recorded, ResponseLevel.sulit);
    });
  });

  group('safety banner', () {
    testWidgets('keeps the three things that carry its weight', (tester) async {
      await tester.pumpWidget(
        _host(
          const Padding(
            padding: EdgeInsets.all(DekapSpace.screenPadding),
            child: SafetyBanner(
              title: 'DekapAutis tidak dapat mendiagnosis',
              body:
                  'Penilaian spektrum hanya dapat dilakukan tenaga '
                  'profesional melalui pemeriksaan langsung.',
              canHelpWith: ['Menyusun rutinitas harian yang dapat diprediksi'],
            ),
          ),
        ),
      );

      // 1. The darkest colour in the system, at the thickest line width.
      final container = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(SafetyBanner),
              matching: find.byType(Container),
            )
            .first,
      );
      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.border!.top.color, DekapColors.boundary);
      expect(decoration.border!.top.width, DekapSpace.boundaryBorderWidth);

      // 2. An explicit refusal, not a euphemism.
      expect(find.text('DekapAutis tidak dapat mendiagnosis'), findsOneWidget);

      // 3. A way forward, so the refusal is never a dead end.
      expect(find.text('Yang bisa saya bantu'), findsOneWidget);
    });
  });

  group('no repeating motion', () {
    test('transition collapses to zero when motion is suppressed', () {
      expect(DekapMotion.transition(reduced: true), Duration.zero);
      expect(
        DekapMotion.transition(reduced: false),
        DekapMotion.pageTransition,
      );
      expect(DekapMotion.pageTransition.inMilliseconds, lessThanOrEqualTo(200));
    });
  });
}
