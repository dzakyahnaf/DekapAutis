import 'package:flutter/material.dart';

import 'tokens.dart';

/// Calm Mode, resolved once and carried on the theme.
///
/// docs/02 section 8 asks for Calm Mode to be a feature rather than a setting,
/// and says in as many words that it must not be "a series of `if`s scattered
/// across every screen". So the five effects are resolved in exactly one place
/// - built from `calmModeProvider` at the root of the app - and every widget
/// downstream reads the answer off [ThemeData] instead of deriving it again.
///
/// The practical difference: a widget that is not a `ConsumerWidget`, a
/// `showDialog` route with its own element tree, and a `PdfPreview` page all
/// see the same state without any of them knowing Riverpod exists.
@immutable
class DekapCalm extends ThemeExtension<DekapCalm> {
  const DekapCalm({this.enabled = false, this.reduceMotion = false});

  /// The L.15 switch.
  final bool enabled;

  /// A system reduce-motion request, which suppresses motion on its own
  /// without bringing the other four effects with it.
  final bool reduceMotion;

  /// Effect 1: illustrations are replaced by their text label.
  bool get showsImagery => !enabled;

  /// Effect 3: spacing rises one step.
  double get extraSpacing => enabled ? DekapSpace.calmSpacingStep : 0;

  /// A gap already adjusted for Calm Mode, so callers do not add it themselves
  /// and get it subtly wrong in one place out of thirty.
  double gap([double base = DekapSpace.cardGap]) => base + extraSpacing;

  /// Effect 5: every transition collapses to zero.
  Duration get transition =>
      DekapMotion.transition(reduced: enabled || reduceMotion);

  /// Effect 2: category fills drop to their calm tint.
  Color categorySurface(DekapCategory category) =>
      category.surfaceFor(calm: enabled);

  /// Reads the resolved state. Falls back to Calm Mode being off rather than
  /// throwing: a widget rendered in a bare `MaterialApp` in some future test
  /// should degrade to the normal appearance, not crash.
  static DekapCalm of(BuildContext context) =>
      Theme.of(context).extension<DekapCalm>() ?? const DekapCalm();

  @override
  DekapCalm copyWith({bool? enabled, bool? reduceMotion}) => DekapCalm(
    enabled: enabled ?? this.enabled,
    reduceMotion: reduceMotion ?? this.reduceMotion,
  );

  /// Deliberately a hard switch rather than an interpolation.
  ///
  /// Turning Calm Mode on must not animate its own arrival: a user reaching
  /// for this switch is asking for less movement, and half a second of colours
  /// and paddings sliding to new values is the opposite of what was asked for.
  @override
  DekapCalm lerp(ThemeExtension<DekapCalm>? other, double t) {
    if (other is! DekapCalm) return this;
    return t < 0.5 ? this : other;
  }

  @override
  bool operator ==(Object other) =>
      other is DekapCalm &&
      other.enabled == enabled &&
      other.reduceMotion == reduceMotion;

  @override
  int get hashCode => Object.hash(enabled, reduceMotion);
}
