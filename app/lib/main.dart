import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/accessibility/accessibility_prefs.dart';
import 'core/router/app_router.dart';
import 'core/strings.dart';
import 'core/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: DekapAutisApp()));
}

class DekapAutisApp extends ConsumerWidget {
  const DekapAutisApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(accessibilityProvider);

    return MaterialApp.router(
      title: S.appName,
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
      theme: DekapTheme.build(
        calm: prefs.calmMode,
        spacingScale: prefs.spacingScale,
      ),
      // Indonesian only. There is no language switcher and there will not be
      // one: the audience is Indonesian caregivers.
      locale: const Locale('id', 'ID'),
      supportedLocales: const [Locale('id', 'ID')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => _AccessibilityScope(child: child),
    );
  }
}

/// Folds the platform accessibility state into the app's own preferences and
/// applies the chosen text scale on top of the system one.
class _AccessibilityScope extends ConsumerWidget {
  const _AccessibilityScope({required this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final media = MediaQuery.of(context);
    final prefs = ref.watch(accessibilityProvider);

    // A platform reduce-motion request is honoured even if the user never
    // opened the accessibility screen.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(accessibilityProvider.notifier)
          .applyPlatformReduceMotion(
            disableAnimations: media.disableAnimations,
          );
    });

    // The in-app text size multiplies the system setting rather than replacing
    // it, so a user who has already enlarged text system-wide is not silently
    // reset. Layouts are verified up to a combined factor of 2.0 in F8; beyond
    // that the design degrades but must still not throw.
    final combined = media.textScaler.scale(prefs.textScale.factor);

    return MediaQuery(
      data: media.copyWith(textScaler: TextScaler.linear(combined)),
      child: child ?? const SizedBox.shrink(),
    );
  }
}
