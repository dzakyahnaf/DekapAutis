import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Design tokens for DekapAutis.
///
/// Source of truth: `docs/02-DESIGN-SYSTEM.md`. This file is a contract, not a
/// suggestion: no widget may declare a literal `Color(0x...)`, font size, radius
/// or spacing of its own. `palette_test.dart` fails the build if one does.
///
/// Two colour families only, purple and cream. No blue, green, red, orange, or
/// pure neutral grey. Even the neutrals carry purple pigment.
abstract final class DekapColors {
  // Base ---------------------------------------------------------------------
  /// Card surface.
  static const surface = Color(0xFFFFFFFF);

  /// Application background.
  static const background = Color(0xFFF2E8F6);

  /// 1px hairlines. Never used to carry meaning on its own.
  static const border = Color(0xFFD8C6E0);

  /// 12.3:1 on [surface].
  static const textPrimary = Color(0xFF4A2657);

  /// Purple-pigmented neutral, 5.98:1 on [surface].
  static const textSecondary = Color(0xFF6B5F73);

  // Purple - system and AI path ----------------------------------------------
  /// Primary. Safe for text at 6.84:1 on [surface].
  static const purple700 = Color(0xFF7B4490);

  /// Secondary. Fills and non-text accents only - see [DekapContrast].
  static const purple500 = Color(0xFFA96CC0);
  static const purple300 = Color(0xFFCA9CDB);
  static const purple100 = Color(0xFFE4CEEC);

  // Cream - human path (caregiver check-in, community) ------------------------
  /// Safe for text at 6.86:1 on [surface].
  static const cream700 = Color(0xFF6F5722);
  static const cream400 = Color(0xFFD9BE7E);
  static const cream200 = Color(0xFFEDDFBC);
  static const cream50 = Color(0xFFFBF6EA);

  // Medical boundary - NOT TO BE USED FOR ANYTHING ELSE -----------------------
  /// Darkest colour in the system. Reserved for the medical-boundary notice
  /// (L.5) at [DekapSpace.boundaryBorderWidth]. Using it as a thick border
  /// anywhere else dilutes the one signal that must never be diluted.
  static const boundary = Color(0xFF4A2657);

  /// Every colour in the system, by name.
  ///
  /// `contrast_test.dart` walks this and fails if a colour is neither part of a
  /// checked text pair nor declared non-text with a reason. Without it the
  /// audit only covers what somebody remembered to register, which is the one
  /// thing an audit must not depend on.
  static const semua = <String, Color>{
    'surface': surface,
    'background': background,
    'border': border,
    'textPrimary': textPrimary,
    'textSecondary': textSecondary,
    'purple700': purple700,
    'purple500': purple500,
    'purple300': purple300,
    'purple100': purple100,
    'cream700': cream700,
    'cream400': cream400,
    'cream200': cream200,
    'cream50': cream50,
    'boundary': boundary,
  };
}

/// Typography. Both families are bundled locally under `assets/fonts/`
/// (SIL OFL 1.1) so the app renders correctly with no network.
abstract final class DekapType {
  /// Headings and body. Lexend Deca's width axis is designed to reduce visual
  /// crowding while reading - that is why it was chosen, not aesthetics.
  static const family = 'LexendDeca';

  /// Figures in reports only.
  static const familyMono = 'IBMPlexMono';

  static const displayTitle = 24.0;
  static const sectionTitle = 19.0;
  static const bodyLarge = 17.0;
  static const bodyDefault = 15.0;
  static const caption = 13.0;

  /// Body line height. Applied as a multiplier, so it survives text scaling.
  static const lineHeight = 1.5;

  static const weightRegular = FontWeight.w400;
  static const weightMedium = FontWeight.w500;
  static const weightSemiBold = FontWeight.w600;
  static const weightBold = FontWeight.w700;
}

/// Space, shape and size.
abstract final class DekapSpace {
  static const screenPadding = 20.0;
  static const cardGap = 12.0;
  static const cardPadding = 16.0;
  static const radiusCard = 16.0;
  static const radiusControl = 12.0;
  static const buttonHeight = 52.0;

  /// Nothing interactive may be smaller than this.
  /// `touch_target_test.dart` fails the build if something is.
  static const minTouch = 48.0;

  static const iconSize = 24.0;
  static const borderWidth = 1.0;

  /// Thickest line in the application. Medical boundary only.
  static const boundaryBorderWidth = 2.4;

  /// Focus ring for keyboard and switch navigation.
  static const focusWidth = 2.0;
  static const focusOffset = 2.0;

  /// Calm Mode raises spacing by one step.
  static const calmSpacingStep = 4.0;
}

/// Motion. There is exactly one rule worth remembering: no repeating animation,
/// in any form. Repeating movement is a sensory-load trigger, and this app is
/// often open while the child is also looking at the screen.
abstract final class DekapMotion {
  static const pageTransition = Duration(milliseconds: 200);
  static const none = Duration.zero;

  /// Resolves the transition duration for the current accessibility state.
  /// Calm Mode or a system reduce-motion request collapses it to zero.
  static Duration transition({required bool reduced}) =>
      reduced ? none : pageTransition;
}

/// The five activity categories.
///
/// Colour is never the only carrier of meaning: every category always renders
/// with its icon *and* its label. [tint] is what surfaces actually paint, so
/// that [DekapColors.textPrimary] stays legible on top of it; [base] is for the
/// category bar on the left edge of a card and the dot in report breakdowns.
enum DekapCategory {
  komunikasi(
    label: 'Komunikasi',
    base: DekapColors.purple700,
    tint: Color(0xFFE7DDEB),
    calmTint: Color(0xFFF2ECF4),
    icon: Symbols.chat_bubble_rounded,
  ),
  motorik(
    label: 'Motorik',
    base: DekapColors.purple500,
    tint: Color(0xFFF0E5F4),
    calmTint: Color(0xFFF6F0F9),
    icon: Symbols.directions_run_rounded,
  ),
  sensorik(
    label: 'Sensorik',
    base: DekapColors.purple300,
    tint: Color(0xFFF5EDF9),
    calmTint: Color(0xFFFAF5FB),
    icon: Symbols.blur_on_rounded,
  ),
  kemandirian(
    label: 'Kemandirian',
    base: DekapColors.cream400,
    tint: Color(0xFFF8F3E8),
    calmTint: Color(0xFFFBF8F2),
    icon: Symbols.accessibility_new_rounded,
  ),
  sosial(
    label: 'Sosial',
    base: DekapColors.cream700,
    tint: Color(0xFFE5E1D7),
    calmTint: Color(0xFFF1EEE9),
    icon: Symbols.groups_rounded,
  );

  const DekapCategory({
    required this.label,
    required this.base,
    required this.tint,
    required this.calmTint,
    required this.icon,
  });

  /// Indonesian label shown to the user.
  final String label;

  /// Full-strength colour. Non-text use only.
  final Color base;

  /// Surface fill in normal mode.
  final Color tint;

  /// Surface fill in Calm Mode - saturation dropped one further step.
  final Color calmTint;

  final IconData icon;

  Color surfaceFor({required bool calm}) => calm ? calmTint : tint;

  /// Matches the `kategori` check constraint in `profil_anak`/`aktivitas`.
  String get dbValue => name;

  static DekapCategory fromDb(String value) =>
      DekapCategory.values.firstWhere((c) => c.name == value);
}
