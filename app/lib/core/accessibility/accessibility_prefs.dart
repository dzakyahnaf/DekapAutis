import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/tokens.dart';

/// Text size choice offered on L.15. Mirrors the `skala_teks` check constraint
/// on the `pengguna` table.
enum DekapTextScale {
  standar('Standar', 1.0),
  besar('Besar', 1.35),
  sangatBesar('Sangat besar', 1.8);

  const DekapTextScale(this.label, this.factor);

  final String label;
  final double factor;

  String get dbValue => switch (this) {
    DekapTextScale.standar => 'standar',
    DekapTextScale.besar => 'besar',
    DekapTextScale.sangatBesar => 'sangat_besar',
  };

  static DekapTextScale fromDb(String value) => switch (value) {
    'besar' => DekapTextScale.besar,
    'sangat_besar' => DekapTextScale.sangatBesar,
    _ => DekapTextScale.standar,
  };
}

/// Accessibility state, shared by the theme, the router and every widget that
/// needs to know about it.
///
/// Calm Mode is a feature, not a setting: one switch changes the whole app.
/// Keeping it here rather than as scattered `if`s is what makes that possible,
/// and what makes `calm_mode_test.dart` able to assert all five effects at once.
@immutable
class AccessibilityPrefs {
  const AccessibilityPrefs({
    this.calmMode = false,
    this.textScale = DekapTextScale.standar,
    this.reduceMotion = false,
  });

  /// L.15 switch. When on: images hidden and replaced by text labels, category
  /// saturation dropped to tint, spacing raised one step, non-critical
  /// notifications muted, and every transition set to 0 ms.
  final bool calmMode;

  final DekapTextScale textScale;

  /// User asked for less movement, independently of Calm Mode.
  final bool reduceMotion;

  /// True when motion must be suppressed, from either source.
  bool get motionSuppressed => calmMode || reduceMotion;

  /// Calm Mode raises spacing by one step.
  double get spacingScale => calmMode ? DekapSpace.calmSpacingStep : 0;

  /// Illustrations are replaced by their text label in Calm Mode.
  bool get showsImagery => !calmMode;

  AccessibilityPrefs copyWith({
    bool? calmMode,
    DekapTextScale? textScale,
    bool? reduceMotion,
  }) => AccessibilityPrefs(
    calmMode: calmMode ?? this.calmMode,
    textScale: textScale ?? this.textScale,
    reduceMotion: reduceMotion ?? this.reduceMotion,
  );

  @override
  bool operator ==(Object other) =>
      other is AccessibilityPrefs &&
      other.calmMode == calmMode &&
      other.textScale == textScale &&
      other.reduceMotion == reduceMotion;

  @override
  int get hashCode => Object.hash(calmMode, textScale, reduceMotion);
}

class AccessibilityController extends StateNotifier<AccessibilityPrefs> {
  AccessibilityController() : super(const AccessibilityPrefs());

  void setCalmMode({required bool enabled}) =>
      state = state.copyWith(calmMode: enabled);

  void setTextScale(DekapTextScale scale) =>
      state = state.copyWith(textScale: scale);

  void setReduceMotion({required bool enabled}) =>
      state = state.copyWith(reduceMotion: enabled);

  /// Folds in the platform request so `MediaQuery.disableAnimations` is
  /// honoured even when the user never opened L.15.
  void applyPlatformReduceMotion({required bool disableAnimations}) {
    if (disableAnimations && !state.reduceMotion) {
      state = state.copyWith(reduceMotion: true);
    }
  }
}

final accessibilityProvider =
    StateNotifierProvider<AccessibilityController, AccessibilityPrefs>(
      (ref) => AccessibilityController(),
    );

/// Convenience reads, so widgets do not each re-derive the same slice.
final calmModeProvider = Provider<bool>(
  (ref) => ref.watch(accessibilityProvider).calmMode,
);

final motionSuppressedProvider = Provider<bool>(
  (ref) => ref.watch(accessibilityProvider).motionSuppressed,
);
