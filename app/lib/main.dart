import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/accessibility/accessibility_prefs.dart';
import 'core/config/app_config.dart';
import 'core/router/app_router.dart';
import 'core/strings.dart';
import 'core/theme/tokens.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/calm.dart';
import 'data/providers.dart';
import 'data/supabase/secure_session_storage.dart';
import 'shared/widgets/app_status_strip.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(await _akar());
}

/// Whatever happens during setup, something is drawn.
///
/// Both awaits below used to sit between `ensureInitialized` and `runApp` with
/// nothing catching them. A phone whose keystore refused to decrypt, or a
/// locale load that never returned, left the person holding a white screen
/// that could not be tapped: no dialog, no message, no way back, and nothing
/// to report to us either. Rule 7 asks for graceful degradation, and a screen
/// that never appears is the least graceful failure there is.
Future<Widget> _akar() async {
  final gagal = await _siapkan();
  if (gagal != null) return LayarGagalMulai(rincian: gagal);
  return const ProviderScope(child: DekapAutisApp());
}

/// Returns null when the app is ready, or the technical detail when it is not.
Future<String?> _siapkan() async {
  try {
    // Indonesian date names. Without this, DateFormat throws on the first
    // screen that shows a date - which is the home screen.
    await initializeDateFormatting(
      'id_ID',
    ).timeout(const Duration(seconds: 15));
  } on Object catch (e) {
    return 'Nama tanggal Bahasa Indonesia: $e';
  }

  try {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      publishableKey: AppConfig.supabasePublishableKey,
      authOptions: FlutterAuthClientOptions(
        // The session is a bearer token for a child's records, so it lives in
        // the platform keystore rather than in SharedPreferences. Keystore
        // failures fall back to memory inside the storage itself.
        localStorage: SecureSessionStorage(),
        // Google sign-in hands control to an external browser and comes back
        // through the dekapautis:// deep link registered in AndroidManifest.
        authFlowType: AuthFlowType.pkce,
      ),
      // A device with no network must still reach the sign-in screen rather
      // than wait here forever.
    ).timeout(const Duration(seconds: 20));
  } on Object catch (e) {
    return 'Menyiapkan layanan: $e';
  }
  return null;
}

/// Shown instead of a blank screen when setup fails.
///
/// Deliberately depends on nothing: no providers, no theme extension, no
/// router. Whatever broke, this still has to render.
class LayarGagalMulai extends StatefulWidget {
  const LayarGagalMulai({required this.rincian, super.key});

  final String rincian;

  @override
  State<LayarGagalMulai> createState() => _LayarGagalMulaiState();
}

class _LayarGagalMulaiState extends State<LayarGagalMulai> {
  bool _sibuk = false;

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: DekapColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'DekapAutis belum dapat dimulai',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: DekapColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Periksa koneksi internet Anda, lalu coba lagi. Bila tetap '
                  'gagal, tutup aplikasi dan buka kembali.',
                  style: const TextStyle(
                    fontSize: 16,
                    color: DekapColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: DekapColors.surface,
                    border: Border.all(color: DekapColors.border),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rincian teknis',
                        style: TextStyle(
                          fontSize: 12,
                          letterSpacing: 1.2,
                          color: DekapColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      SelectableText(
                        widget.rincian,
                        style: TextStyle(
                          fontSize: 13,
                          color: DekapColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: DekapColors.purple700,
                      minimumSize: const Size.fromHeight(52),
                    ),
                    onPressed: _sibuk ? null : _ulangi,
                    child: Text(_sibuk ? 'Mencoba…' : 'Coba lagi'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Future<void> _ulangi() async {
    setState(() => _sibuk = true);
    runApp(await _akar());
  }
}

class DekapAutisApp extends ConsumerWidget {
  const DekapAutisApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Signing out must not leave one account's child, plan and notes readable
    // by the next account on the same phone. DekapDatabase.kosongkan() was
    // written for exactly this and never called. Listening to the auth stream
    // catches every way out - the button, an expired session, a deleted
    // account - instead of only the one screen that has a button.
    ref.listen(statusAuthProvider, (_, next) {
      switch (next.value?.event) {
        case AuthChangeEvent.signedOut:
          ref.read(databaseProvider).kosongkan();
        case AuthChangeEvent.passwordRecovery:
          // The recovery link has reopened the app and supabase_flutter has
          // exchanged it for a session. Without this the person lands on the
          // home screen signed in, the old password still in force, and
          // nothing ever asks them for a new one.
          appRouter.go('/sandi-baru');
        case _:
          break;
      }
    });

    final prefs = ref.watch(accessibilityProvider);

    return MaterialApp.router(
      title: S.appName,
      debugShowCheckedModeBanner: false,
      // Calm Mode must arrive the instant it is switched on. Material's
      // default 200ms theme cross-fade would fade the five effects in, which
      // is motion the person reaching for that switch just asked to stop.
      themeAnimationDuration: Duration.zero,
      routerConfig: appRouter,
      // Calm Mode is resolved exactly once, here, and carried on the theme.
      // Nothing downstream re-derives it.
      theme: DekapTheme.build(
        calm: DekapCalm(
          enabled: prefs.calmMode,
          reduceMotion: prefs.reduceMotion,
        ),
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
      child: AppStatusStrip(child: child),
    );
  }
}
