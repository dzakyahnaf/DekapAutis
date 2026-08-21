import 'package:flutter/material.dart';

import 'tokens.dart';

/// Builds the single [ThemeData] the whole application runs on.
///
/// Material elevation is switched off everywhere on purpose: the design system
/// asks for thin lines, not shadows. Page motion is owned by the router, which
/// knows whether Calm Mode is on, so Material's own zoom transition is disabled
/// here to stop two motions stacking on top of each other.
abstract final class DekapTheme {
  static ThemeData build({required bool calm, required double spacingScale}) {
    final text = _textTheme;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: _scheme,
      scaffoldBackgroundColor: DekapColors.background,
      canvasColor: DekapColors.background,
      fontFamily: DekapType.family,
      textTheme: text,
      splashFactory: calm ? NoSplash.splashFactory : InkRipple.splashFactory,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: _RouterOwnedTransitionsBuilder(),
          TargetPlatform.iOS: _RouterOwnedTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: DekapColors.background,
        foregroundColor: DekapColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge,
        iconTheme: const IconThemeData(
          color: DekapColors.textPrimary,
          size: DekapSpace.iconSize,
        ),
      ),
      cardTheme: CardThemeData(
        color: DekapColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DekapSpace.radiusCard),
          side: const BorderSide(
            color: DekapColors.border,
            width: DekapSpace.borderWidth,
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: DekapColors.border,
        thickness: DekapSpace.borderWidth,
        space: DekapSpace.cardGap,
      ),
      iconTheme: const IconThemeData(
        color: DekapColors.textPrimary,
        size: DekapSpace.iconSize,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: _primaryButtonStyle(text),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: _secondaryButtonStyle(text),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: DekapColors.purple700,
          textStyle: text.labelLarge,
          minimumSize: const Size(DekapSpace.minTouch, DekapSpace.minTouch),
          padding: const EdgeInsets.symmetric(horizontal: DekapSpace.cardGap),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: DekapColors.surface,
        contentPadding: EdgeInsets.symmetric(
          horizontal: DekapSpace.cardPadding,
          vertical: DekapSpace.cardGap + spacingScale,
        ),
        hintStyle: text.bodyMedium?.copyWith(color: DekapColors.textSecondary),
        border: _inputBorder(DekapColors.border),
        enabledBorder: _inputBorder(DekapColors.border),
        focusedBorder: _inputBorder(
          DekapColors.purple700,
          DekapSpace.focusWidth,
        ),
        errorBorder: _inputBorder(DekapColors.boundary, DekapSpace.focusWidth),
        focusedErrorBorder: _inputBorder(
          DekapColors.boundary,
          DekapSpace.focusWidth,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: DekapColors.textPrimary,
        contentTextStyle: text.bodyMedium?.copyWith(color: DekapColors.surface),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DekapSpace.radiusControl),
        ),
      ),
    );
  }

  static const _scheme = ColorScheme(
    brightness: Brightness.light,
    primary: DekapColors.purple700,
    onPrimary: DekapColors.surface,
    primaryContainer: DekapColors.purple100,
    onPrimaryContainer: DekapColors.textPrimary,
    secondary: DekapColors.cream700,
    onSecondary: DekapColors.surface,
    secondaryContainer: DekapColors.cream200,
    onSecondaryContainer: DekapColors.textPrimary,
    surface: DekapColors.surface,
    onSurface: DekapColors.textPrimary,
    onSurfaceVariant: DekapColors.textSecondary,
    outline: DekapColors.border,
    // There is no red in this palette. The medical boundary carries its visual
    // weight through darkness, a 2.4px line and a shield icon instead: red
    // triggers a vigilance response that is unwanted in users with sensory
    // sensitivity, and this app is often open while the child watches too.
    error: DekapColors.boundary,
    onError: DekapColors.surface,
  );

  static TextStyle _t(double size, FontWeight weight) => TextStyle(
    fontFamily: DekapType.family,
    fontSize: size,
    fontWeight: weight,
    height: DekapType.lineHeight,
    color: DekapColors.textPrimary,
  );

  static final _textTheme = TextTheme(
    displaySmall: _t(DekapType.displayTitle, DekapType.weightSemiBold),
    titleLarge: _t(DekapType.displayTitle, DekapType.weightSemiBold),
    titleMedium: _t(DekapType.sectionTitle, DekapType.weightSemiBold),
    bodyLarge: _t(DekapType.bodyLarge, DekapType.weightRegular),
    bodyMedium: _t(DekapType.bodyDefault, DekapType.weightRegular),
    bodySmall: _t(
      DekapType.caption,
      DekapType.weightRegular,
    ).copyWith(color: DekapColors.textSecondary),
    labelLarge: _t(DekapType.bodyDefault, DekapType.weightSemiBold),
    labelSmall: _t(DekapType.caption, DekapType.weightMedium),
  );

  /// Figures in reports. Tabular so columns stay aligned as values change.
  static const monoFigure = TextStyle(
    fontFamily: DekapType.familyMono,
    fontSize: DekapType.displayTitle,
    fontWeight: DekapType.weightSemiBold,
    color: DekapColors.textPrimary,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static ButtonStyle _primaryButtonStyle(TextTheme text) =>
      FilledButton.styleFrom(
        backgroundColor: DekapColors.purple700,
        foregroundColor: DekapColors.surface,
        disabledBackgroundColor: DekapColors.border,
        disabledForegroundColor: DekapColors.textSecondary,
        minimumSize: const Size.fromHeight(DekapSpace.buttonHeight),
        textStyle: text.labelLarge,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DekapSpace.radiusControl),
        ),
      );

  static ButtonStyle _secondaryButtonStyle(TextTheme text) =>
      OutlinedButton.styleFrom(
        foregroundColor: DekapColors.purple700,
        backgroundColor: DekapColors.surface,
        minimumSize: const Size.fromHeight(DekapSpace.buttonHeight),
        textStyle: text.labelLarge,
        side: const BorderSide(
          color: DekapColors.purple700,
          width: DekapSpace.borderWidth,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DekapSpace.radiusControl),
        ),
      );

  static OutlineInputBorder _inputBorder(
    Color color, [
    double width = DekapSpace.borderWidth,
  ]) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(DekapSpace.radiusControl),
    borderSide: BorderSide(color: color, width: width),
  );
}

/// Hands page motion to the router, which is the only place that knows whether
/// Calm Mode or a system reduce-motion request is active.
class _RouterOwnedTransitionsBuilder extends PageTransitionsBuilder {
  const _RouterOwnedTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T>? route,
    BuildContext? context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => child;
}
