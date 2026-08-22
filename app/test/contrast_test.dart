import 'dart:ui' show Color;

import 'package:dekapautis/core/theme/contrast.dart';
import 'package:dekapautis/core/theme/tokens.dart';
import 'package:flutter_test/flutter_test.dart';

/// Turns accessibility from an intention into a safety net.
///
/// The palette has no red and leans on low saturation, which is exactly the
/// kind of palette where a contrast failure is invisible to the eye that chose
/// it. This test fails the build instead of trusting anyone to notice.
void main() {
  group('WCAG 2.2 AA', () {
    test('every registered text pair clears 4.5:1', () {
      final failures = <String>[];
      for (final pair in DekapContrast.allowedTextPairs) {
        if (pair.ratio < DekapContrast.aaNormal) {
          failures.add('${pair.usage}: ${pair.ratio.toStringAsFixed(2)}:1');
        }
      }
      expect(failures, isEmpty, reason: failures.join('\n'));
    });

    test(
      'category fills stay legible under textPrimary, calm mode included',
      () {
        final failures = <String>[];
        for (final pair in DekapContrast.categoryPairs()) {
          if (pair.ratio < DekapContrast.aaNormal) {
            failures.add('${pair.usage}: ${pair.ratio.toStringAsFixed(2)}:1');
          }
        }
        expect(failures, isEmpty, reason: failures.join('\n'));
      },
    );

    test('every colour in tokens.dart is accounted for', () {
      // The audit is only as good as its coverage. A new token that nobody
      // registered would otherwise sail past every check above and still end
      // up behind text on a real screen.
      final tidakDiklasifikasi = <String>[];

      for (final entry in DekapColors.semua.entries) {
        final dipakaiUntukTeks = DekapContrast.allowedTextPairs.any(
          (p) => p.background == entry.value || p.foreground == entry.value,
        );
        final dinyatakanBukanTeks = DekapContrast.nonTextColours.containsKey(
          entry.key,
        );

        if (!dipakaiUntukTeks && !dinyatakanBukanTeks) {
          tidakDiklasifikasi.add(entry.key);
        }
      }

      expect(
        tidakDiklasifikasi,
        isEmpty,
        reason:
            'Add these to allowedTextPairs with a measured ratio, or to '
            'nonTextColours with a reason: ${tidakDiklasifikasi.join(', ')}',
      );
    });

    test('a colour declared non-text is not also used behind text', () {
      for (final nama in DekapContrast.nonTextColours.keys) {
        final warna = DekapColors.semua[nama];
        expect(
          warna,
          isNotNull,
          reason: '$nama is not a colour in tokens.dart',
        );

        final dipakai = DekapContrast.allowedTextPairs.any(
          (p) => p.background == warna || p.foreground == warna,
        );
        expect(
          dipakai,
          isFalse,
          reason:
              '$nama is declared non-text but appears in a text pair - one of '
              'the two statements is wrong',
        );
      }
    });

    test('banned pairs really do fail, and are absent from the registry', () {
      for (final banned in DekapContrast.forbiddenTextPairs) {
        expect(
          banned.ratio,
          lessThan(DekapContrast.aaNormal),
          reason:
              '${banned.usage} no longer fails - re-check why it was banned',
        );
        final registered = DekapContrast.allowedTextPairs.any(
          (p) =>
              p.background == banned.background &&
              p.foreground == banned.foreground,
        );
        expect(
          registered,
          isFalse,
          reason:
              'banned pair leaked in: '
              '${banned.usage}',
        );
      }
    });
  });

  group('ratio maths', () {
    test('white on black is 21:1', () {
      expect(
        DekapContrast.ratio(const Color(0xFFFFFFFF), const Color(0xFF000000)),
        closeTo(21, 0.01),
      );
    });

    test('a colour against itself is 1:1', () {
      expect(
        DekapContrast.ratio(DekapColors.purple700, DekapColors.purple700),
        closeTo(1, 0.0001),
      );
    });

    test('order does not matter', () {
      final a = DekapContrast.ratio(
        DekapColors.surface,
        DekapColors.textPrimary,
      );
      final b = DekapContrast.ratio(
        DekapColors.textPrimary,
        DekapColors.surface,
      );
      expect(a, closeTo(b, 0.0001));
    });

    test('documented values in docs/02 still hold', () {
      expect(
        DekapContrast.ratio(DekapColors.surface, DekapColors.textPrimary),
        closeTo(12.31, 0.05),
      );
      expect(
        DekapContrast.ratio(DekapColors.surface, DekapColors.purple700),
        closeTo(6.84, 0.05),
      );
      expect(
        DekapContrast.ratio(DekapColors.surface, DekapColors.cream700),
        closeTo(6.86, 0.05),
      );
    });
  });
}
