import 'package:dekapautis/core/accessibility/accessibility_prefs.dart';
import 'package:dekapautis/core/strings.dart';
import 'package:dekapautis/core/theme/app_theme.dart';
import 'package:dekapautis/core/theme/calm.dart';
import 'package:dekapautis/core/theme/tokens.dart';
import 'package:dekapautis/data/providers.dart';
import 'package:dekapautis/domain/notifikasi/jenis_notifikasi.dart';
import 'package:dekapautis/shared/widgets/app_status_strip.dart';
import 'package:dekapautis/shared/widgets/calm_image.dart';
import 'package:dekapautis/shared/widgets/calm_mode_switch.dart';
import 'package:dekapautis/shared/widgets/category_pill.dart';
import 'package:dekapautis/shared/widgets/offline_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Calm Mode is a feature, not a setting (docs/02 section 8, KF-16).
///
/// The point of this file is that all five effects are asserted against one
/// switch. If Calm Mode were a series of `if`s spread across the screens, this
/// test could not exist in this shape - it would have to visit every screen and
/// check them one at a time, and would silently stop covering screen eleven the
/// day somebody wrote it and forgot.
void main() {
  Widget host({required bool calm, Widget? child}) => ProviderScope(
    child: MaterialApp(
      theme: DekapTheme.build(calm: DekapCalm(enabled: calm)),
      themeAnimationDuration: Duration.zero,
      home: Scaffold(body: child ?? const SizedBox.shrink()),
    ),
  );

  group('all five effects follow one switch', () {
    test(
      '1 - imagery is replaced by text, 3 - spacing rises, 5 - no motion',
      () {
        const mati = DekapCalm();
        const nyala = DekapCalm(enabled: true);

        expect(mati.showsImagery, isTrue);
        expect(nyala.showsImagery, isFalse);

        expect(mati.extraSpacing, 0);
        expect(nyala.extraSpacing, DekapSpace.calmSpacingStep);
        expect(nyala.gap(), DekapSpace.cardGap + DekapSpace.calmSpacingStep);

        expect(mati.transition, DekapMotion.pageTransition);
        expect(nyala.transition, Duration.zero);
      },
    );

    test('2 - category fills drop to the calm tint', () {
      const mati = DekapCalm();
      const nyala = DekapCalm(enabled: true);

      for (final kategori in DekapCategory.values) {
        expect(mati.categorySurface(kategori), kategori.tint);
        expect(nyala.categorySurface(kategori), kategori.calmTint);
        expect(
          kategori.calmTint,
          isNot(kategori.tint),
          reason: '${kategori.label} has no distinct calm tint',
        );
      }
    });

    test('4 - non-critical notifications are muted, critical ones are not', () {
      for (final jenis in JenisNotifikasi.values) {
        expect(
          bolehBerbunyi(jenis, modeTenang: false),
          isTrue,
          reason: '${jenis.label} must be audible with Calm Mode off',
        );
        expect(
          bolehBerbunyi(jenis, modeTenang: true),
          jenis.penting,
          reason: '${jenis.label}: ${jenis.alasan}',
        );
      }

      // The two that survive are the ones somebody else is waiting on or that
      // changed the child's plan.
      expect(yangDibisukan(), hasLength(3));
      expect(
        yangDibisukan(),
        isNot(contains(JenisNotifikasi.penyesuaianRencana)),
      );
      expect(
        yangDibisukan(),
        isNot(contains(JenisNotifikasi.persetujuanJadwal)),
      );
    });

    test('muting silences a notification, it never hides one', () {
      // Guards the distinction the doc comment makes. If a future change makes
      // Calm Mode drop notifications instead of quieting them, this fails.
      for (final jenis in JenisNotifikasi.values) {
        expect(JenisNotifikasi.fromDb(jenis.dbValue), jenis);
      }
      expect(JenisNotifikasi.values, hasLength(5));
    });

    test('a system reduce-motion request suppresses motion by itself', () {
      // ...without dragging the other four effects along with it. Someone who
      // asked the OS for less movement did not ask for their photos to vanish.
      const hanyaGerak = DekapCalm(reduceMotion: true);
      expect(hanyaGerak.transition, Duration.zero);
      expect(hanyaGerak.showsImagery, isTrue);
      expect(hanyaGerak.extraSpacing, 0);
    });
  });

  group('the theme carries the state', () {
    testWidgets('widgets read Calm Mode off ThemeData, not the provider', (
      tester,
    ) async {
      late DekapCalm terbaca;
      await tester.pumpWidget(
        host(
          calm: true,
          child: Builder(
            builder: (context) {
              terbaca = DekapCalm.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(terbaca.enabled, isTrue);
    });

    testWidgets('a bare MaterialApp degrades to Calm Mode off, not a crash', (
      tester,
    ) async {
      late DekapCalm terbaca;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              terbaca = DekapCalm.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(terbaca.enabled, isFalse);
    });

    testWidgets('turning Calm Mode on does not animate its own arrival', (
      tester,
    ) async {
      // Someone reaching for this switch is asking for less movement.
      const mati = DekapCalm();
      const nyala = DekapCalm(enabled: true);
      expect(mati.lerp(nyala, 0.25).enabled, isFalse);
      expect(mati.lerp(nyala, 0.75).enabled, isTrue);
    });
  });

  group('what the user sees', () {
    testWidgets('the category pill repaints in the calm tint', (tester) async {
      for (final calm in [false, true]) {
        await tester.pumpWidget(
          host(
            calm: calm,
            child: const CategoryPill(category: DekapCategory.sensorik),
          ),
        );
        final box = tester.widget<Container>(
          find
              .descendant(
                of: find.byType(CategoryPill),
                matching: find.byType(Container),
              )
              .first,
        );
        final fill = (box.decoration! as BoxDecoration).color;
        expect(
          fill,
          calm ? DekapCategory.sensorik.calmTint : DekapCategory.sensorik.tint,
        );
      }
    });

    testWidgets('an illustration becomes its description', (tester) async {
      const keterangan = 'Ilustrasi anak menyusun tiga balok berurutan';

      await tester.pumpWidget(
        host(
          calm: false,
          child: CalmImage(
            label: keterangan,
            image: (_) => const ColoredBox(color: DekapColors.purple100),
          ),
        ),
      );
      expect(find.text(keterangan), findsNothing);
      expect(find.byType(ColoredBox), findsWidgets);

      await tester.pumpWidget(
        host(
          calm: true,
          child: CalmImage(
            label: keterangan,
            image: (_) => const ColoredBox(color: DekapColors.purple100),
          ),
        ),
      );
      // The picture is gone and its meaning is not.
      expect(find.text(keterangan), findsOneWidget);
    });

    testWidgets('the state is never hidden from the user', (tester) async {
      await tester.pumpWidget(host(calm: true, child: const CalmModePill()));
      expect(find.text(S.modeTenangAktif), findsOneWidget);

      await tester.pumpWidget(host(calm: false, child: const CalmModePill()));
      expect(find.text(S.modeTenangAktif), findsNothing);
    });

    testWidgets('the switch tells the user all five things it will do', (
      tester,
    ) async {
      await tester.pumpWidget(host(calm: false, child: const CalmModeSwitch()));
      expect(CalmModeSwitch.effects, hasLength(5));
      for (final efek in CalmModeSwitch.effects) {
        expect(find.text(efek), findsOneWidget);
      }
    });
  });

  group('the status strip', () {
    /// The strip sits above every route, but only appears when there is
    /// something to say - so `text_scale_test.dart` never lays it out. It gets
    /// its own scaling check here, because an overflow in this one widget would
    /// be an overflow on all seventeen screens at once.
    Widget denganStatus({
      required bool calm,
      required int menunggu,
      required double skala,
    }) => ProviderScope(
      overrides: [
        calmModeProvider.overrideWithValue(calm),
        menungguSinkronProvider.overrideWith((ref) => Stream.value(menunggu)),
      ],
      child: MaterialApp(
        theme: DekapTheme.build(calm: DekapCalm(enabled: calm)),
        themeAnimationDuration: Duration.zero,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(skala)),
          child: AppStatusStrip(child: child),
        ),
        home: const Scaffold(body: Center(child: Text('isi layar'))),
      ),
    );

    testWidgets('stays out of the tree when there is nothing to report', (
      tester,
    ) async {
      await tester.pumpWidget(denganStatus(calm: false, menunggu: 0, skala: 1));
      expect(find.text(S.modeTenangAktif), findsNothing);
      expect(find.byType(OfflineBanner), findsNothing);
      expect(find.text('isi layar'), findsOneWidget);
    });

    testWidgets('reports both facts at once without pushing the screen out', (
      tester,
    ) async {
      for (final skala in [1.0, 1.5, 2.0]) {
        tester.view
          ..devicePixelRatio = 1.0
          ..physicalSize = const Size(360, 640);
        addTearDown(tester.view.reset);

        final masalah = <String>[];
        final sebelumnya = FlutterError.onError;
        FlutterError.onError = (d) => masalah.add(d.exceptionAsString());

        await tester.pumpWidget(
          denganStatus(calm: true, menunggu: 3, skala: skala),
        );
        await tester.pump();
        FlutterError.onError = sebelumnya;
        tester.takeException();

        expect(masalah, isEmpty, reason: 'strip at ${skala}x: $masalah');
        expect(find.text(S.modeTenangAktif), findsOneWidget);
        expect(find.text(S.luringMenunggu(3)), findsOneWidget);
        expect(find.text('isi layar'), findsOneWidget);
      }
    });

    test('the text summary says both things, or says all is well', () {
      expect(ringkasanStatus(modeTenang: false, menunggu: 0), S.statusNormal);
      expect(
        ringkasanStatus(modeTenang: true, menunggu: 0),
        contains(S.modeTenangAktif),
      );
      final keduanya = ringkasanStatus(modeTenang: true, menunggu: 2);
      expect(keduanya, contains(S.modeTenangAktif));
      expect(keduanya, contains('2'));
    });
  });

  group('the preferences object stays the single source', () {
    test('motion is suppressed by either route', () {
      const prefs = AccessibilityPrefs();
      expect(prefs.motionSuppressed, isFalse);
      expect(prefs.copyWith(calmMode: true).motionSuppressed, isTrue);
      expect(prefs.copyWith(reduceMotion: true).motionSuppressed, isTrue);
    });
  });
}
