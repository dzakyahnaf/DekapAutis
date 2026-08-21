import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'tokens.dart';

/// One background/foreground combination the app is allowed to render text in.
@immutable
class DekapTextPair {
  const DekapTextPair(this.background, this.foreground, this.usage);

  final Color background;
  final Color foreground;

  /// Where this pair appears, so a failing audit points at a real screen.
  final String usage;

  double get ratio => DekapContrast.ratio(background, foreground);
}

/// WCAG 2.2 contrast maths and the registry of legal text pairs.
///
/// `contrast_test.dart` walks [allowedTextPairs] and fails the build when any
/// pair drops below [aaNormal]. That is what turns accessibility from an
/// intention into a safety net.
///
/// Scope note: the audit covers **text** pairs. Hairlines
/// ([DekapColors.border]) and category dots are deliberately out of scope,
/// because colour is never the sole carrier of meaning in this design - every
/// category and status also renders an icon and a text label, so WCAG 1.4.11
/// does not apply to them.
abstract final class DekapContrast {
  /// WCAG 2.2 AA, normal text.
  static const aaNormal = 4.5;

  /// WCAG 2.2 AA, large text (>=18.66px bold or >=24px regular).
  static const aaLarge = 3.0;

  static double _linear(double channel) => channel <= 0.04045
      ? channel / 12.92
      : math.pow((channel + 0.055) / 1.055, 2.4).toDouble();

  static double relativeLuminance(Color c) =>
      0.2126 * _linear(c.r) + 0.7152 * _linear(c.g) + 0.0722 * _linear(c.b);

  static double ratio(Color a, Color b) {
    final la = relativeLuminance(a);
    final lb = relativeLuminance(b);
    return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
  }

  /// Every text pair the application is permitted to paint.
  /// Adding a pair here without checking it is how palettes drift; the test
  /// exists precisely so that cannot happen silently.
  static const allowedTextPairs = <DekapTextPair>[
    DekapTextPair(DekapColors.surface, DekapColors.textPrimary, 'body on card'),
    DekapTextPair(
      DekapColors.surface,
      DekapColors.textSecondary,
      'meta on card',
    ),
    DekapTextPair(DekapColors.surface, DekapColors.purple700, 'link on card'),
    DekapTextPair(
      DekapColors.surface,
      DekapColors.cream700,
      'human-path text on card',
    ),
    DekapTextPair(
      DekapColors.background,
      DekapColors.textPrimary,
      'body on app background',
    ),
    DekapTextPair(
      DekapColors.background,
      DekapColors.textSecondary,
      'meta on app background',
    ),
    DekapTextPair(
      DekapColors.background,
      DekapColors.purple700,
      'link on app background',
    ),
    DekapTextPair(
      DekapColors.purple100,
      DekapColors.textPrimary,
      'L.3 user bubble, L.5 boundary card',
    ),
    DekapTextPair(
      DekapColors.purple100,
      DekapColors.purple700,
      'accent on purple field',
    ),
    DekapTextPair(
      DekapColors.cream200,
      DekapColors.textPrimary,
      'L.2 caregiver check-in card',
    ),
    DekapTextPair(
      DekapColors.cream200,
      DekapColors.cream700,
      'accent on cream field',
    ),
    DekapTextPair(
      DekapColors.cream50,
      DekapColors.textPrimary,
      'community surface',
    ),
    DekapTextPair(
      DekapColors.cream50,
      DekapColors.textSecondary,
      'community meta',
    ),
    DekapTextPair(
      DekapColors.purple700,
      DekapColors.surface,
      'primary button label',
    ),
    DekapTextPair(
      DekapColors.cream700,
      DekapColors.surface,
      'human-path button label',
    ),
    DekapTextPair(
      DekapColors.boundary,
      DekapColors.surface,
      'boundary banner title',
    ),
  ];

  /// Combinations that measured below AA and are therefore banned outright.
  /// Kept as data so the test can assert they are still absent from
  /// [allowedTextPairs] rather than relying on anyone remembering.
  static const forbiddenTextPairs = <DekapTextPair>[
    DekapTextPair(
      DekapColors.purple100,
      DekapColors.textSecondary,
      '4.09:1 - use textPrimary instead',
    ),
    DekapTextPair(
      DekapColors.cream400,
      DekapColors.textSecondary,
      '3.31:1 - use textPrimary instead',
    ),
    DekapTextPair(
      DekapColors.purple500,
      DekapColors.surface,
      '3.75:1 - purple500 is not a text background',
    ),
    DekapTextPair(DekapColors.purple300, DekapColors.textSecondary, '2.65:1'),
  ];

  /// Category fills must stay legible under [DekapColors.textPrimary] in both
  /// normal and Calm Mode.
  static Iterable<DekapTextPair> categoryPairs() sync* {
    for (final c in DekapCategory.values) {
      yield DekapTextPair(c.tint, DekapColors.textPrimary, '${c.label} pill');
      yield DekapTextPair(
        c.calmTint,
        DekapColors.textPrimary,
        '${c.label} pill, Calm Mode',
      );
    }
  }
}
