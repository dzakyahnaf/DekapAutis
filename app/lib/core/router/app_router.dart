import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/activity/detail_aktivitas_screen.dart';
import '../../features/assistant/tanya_screen.dart';
import '../../features/auth/auth_screens.dart';
import '../../features/home/beranda_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/plan/rencana_screen.dart';
import '../../features/profile/preferensi_aksesibilitas.dart';
import '../../features/profile/profil_screen.dart';
import '../../features/profile/sunting_anak_screen.dart';
import '../../features/report/izin_berbagi_screen.dart';
import '../../features/report/laporan_screen.dart';
import '../../shared/widgets/app_shell.dart';
import '../../shared/widgets/placeholder_screen.dart';
import '../../shared/widgets/states.dart';
import '../accessibility/accessibility_prefs.dart';
import '../strings.dart';
import '../theme/tokens.dart';

/// Named routes, so a demo scenario can jump straight to a screen instead of
/// navigating there by hand while the camera is running.
abstract final class R {
  static const splash = 'splash';
  static const masuk = 'masuk';
  static const daftar = 'daftar';
  static const onboarding = 'onboarding';

  static const beranda = 'beranda';
  static const rencana = 'rencana';
  static const aktivitas = 'aktivitas';
  static const tanya = 'tanya';
  static const sumber = 'sumber';

  static const direktori = 'direktori';
  static const direktoriDetail = 'direktori-detail';
  static const pustaka = 'pustaka';
  static const pustakaDetail = 'pustaka-detail';
  static const komunitas = 'komunitas';
  static const komunitasDetail = 'komunitas-detail';

  static const profil = 'profil';
  static const laporan = 'laporan';
  static const laporanDetail = 'laporan-detail';
  static const suntingAnak = 'sunting-anak';
  static const aksesibilitas = 'aksesibilitas';
  static const izin = 'izin';
  static const caraPakai = 'cara-pakai';
  static const notifikasi = 'notifikasi';

  static const profesionalKotakMasuk = 'profesional-kotak-masuk';
  static const profesionalLaporan = 'profesional-laporan';
  static const profesionalProfil = 'profesional-profil';

  static const adminVerifikasi = 'admin-verifikasi';
  static const adminPengetahuan = 'admin-pengetahuan';
  static const adminModerasi = 'admin-moderasi';
}

final _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');

/// Page transitions are at most 200 ms and collapse to 0 ms whenever Calm Mode
/// or a system reduce-motion request is active. A one-shot fade is not a
/// repeating pattern, so it is the only motion this app permits.
CustomTransitionPage<void> _page(
  BuildContext context,
  GoRouterState state,
  Widget child,
) {
  final reduced = ProviderScope.containerOf(
    context,
    listen: false,
  ).read(motionSuppressedProvider);
  final duration = DekapMotion.transition(reduced: reduced);

  return CustomTransitionPage<void>(
    key: state.pageKey,
    transitionDuration: duration,
    reverseTransitionDuration: duration,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) =>
        duration == Duration.zero
        ? child
        : FadeTransition(opacity: animation, child: child),
  );
}

GoRoute _stub(
  String path,
  String name,
  String title, {
  String? phase,
  List<RouteBase> routes = const [],
}) => GoRoute(
  path: path,
  name: name,
  pageBuilder: (context, state) => _page(
    context,
    state,
    PlaceholderScreen(title: title, route: state.uri.path, phase: phase),
  ),
  routes: routes,
);

GoRoute _layar(
  String path,
  String name,
  Widget Function(BuildContext, GoRouterState) bangun, {
  List<RouteBase> routes = const [],
}) => GoRoute(
  path: path,
  name: name,
  pageBuilder: (context, state) =>
      _page(context, state, bangun(context, state)),
  routes: routes,
);

/// Turns an incoming `dekapautis://` deep link into a plain path.
///
/// Android hands the engine the whole URI, so `dekapautis://beranda` arrives
/// with `beranda` as the *host* and `/` as the path, which matches no route.
/// Both docs/05 (jumping straight to a screen while recording the demo) and
/// Supabase `signInWithOAuth` (the callback after the browser hands control
/// back) depend on this working, so it is normalised here rather than relying
/// on whoever types the link to remember a third slash.
String? normaliseDeepLink(Uri uri) {
  if (uri.scheme != 'dekapautis' || uri.host.isEmpty) return null;
  final path = uri.path == '/' ? '' : uri.path;
  final target = '/${uri.host}$path';
  return uri.hasQuery ? '$target?${uri.query}' : target;
}

/// Shown when a route does not exist.
///
/// go_router's own error page is an English "Page Not Found" with a raw
/// GoException on it. That breaks two absolute rules at once: the interface is
/// 100% Bahasa Indonesia, and a raw English message or stack trace is never
/// shown to the user. Judging runs for ten days without us present, so one
/// mistyped link must not produce a screen we would be embarrassed by.
class RouteNotFoundScreen extends StatelessWidget {
  const RouteNotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text(S.ruteTidakDitemukan)),
    body: Center(
      child: ErrorState(
        message: S.ruteTidakDitemukanIsi,
        retryLabel: S.aksiKeBeranda,
        onRetry: () => context.go('/beranda'),
      ),
    ),
  );
}

/// Full route tree for the 17 caregiver screens plus the professional and
/// administrator surfaces, so all three actors in Gambar 6.1 are reachable.
final appRouter = GoRouter(
  navigatorKey: _rootKey,
  initialLocation: '/splash',
  redirect: (context, state) => normaliseDeepLink(state.uri),
  errorBuilder: (context, state) => const RouteNotFoundScreen(),
  routes: [
    _layar('/splash', R.splash, (_, _) => const SplashScreen()),
    _layar('/masuk', R.masuk, (_, _) => const MasukScreen()),
    _layar('/daftar', R.daftar, (_, _) => const DaftarScreen()),
    _layar(
      '/onboarding/:langkah',
      R.onboarding,
      (_, state) => OnboardingScreen(
        langkah: int.tryParse(state.pathParameters['langkah'] ?? '1') ?? 1,
      ),
    ),
    _stub('/notifikasi', R.notifikasi, S.titleNotifikasi, phase: 'L.17 - F7'),

    // Professional actor.
    _stub(
      '/profesional/masuk-kotak',
      R.profesionalKotakMasuk,
      S.titleKotakMasuk,
      phase: 'F9',
    ),
    _stub(
      '/profesional/laporan/:id',
      R.profesionalLaporan,
      S.titleLaporan,
      phase: 'F9',
    ),
    _stub(
      '/profesional/profil',
      R.profesionalProfil,
      S.titleProfilPraktik,
      phase: 'F9',
    ),

    // Administrator actor.
    _stub(
      '/admin/verifikasi',
      R.adminVerifikasi,
      S.titleVerifikasi,
      phase: 'F9',
    ),
    _stub(
      '/admin/pengetahuan',
      R.adminPengetahuan,
      S.titlePengetahuan,
      phase: 'F9',
    ),
    _stub('/admin/moderasi', R.adminModerasi, S.titleModerasi, phase: 'F9'),

    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          AppShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            _layar('/beranda', R.beranda, (_, _) => const BerandaScreen()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            _layar(
              '/rencana',
              R.rencana,
              (_, _) => const RencanaScreen(),
              routes: [
                _layar(
                  'aktivitas/:id',
                  R.aktivitas,
                  (_, state) => DetailAktivitasScreen(
                    jadwalId: state.pathParameters['id']!,
                  ),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [_layar('/tanya', R.tanya, (_, _) => const TanyaScreen())],
        ),
        // Jelajah hosts three surfaces at their documented top-level paths, so
        // deep links from docs/05 keep working.
        StatefulShellBranch(
          initialLocation: '/direktori',
          routes: [
            _stub(
              '/direktori',
              R.direktori,
              S.titleDirektori,
              phase: 'L.9 - F7',
              routes: [
                _stub(
                  ':id',
                  R.direktoriDetail,
                  S.titleProfesional,
                  phase: 'L.10 - F7',
                ),
              ],
            ),
            _stub(
              '/pustaka',
              R.pustaka,
              S.titlePustaka,
              phase: 'L.12 - F5',
              routes: [
                _stub(':id', R.pustakaDetail, S.titleArtikel, phase: 'F5'),
              ],
            ),
            _stub(
              '/komunitas',
              R.komunitas,
              S.titleKomunitas,
              phase: 'L.11 - F7',
              routes: [
                _stub(
                  ':postId',
                  R.komunitasDetail,
                  S.titleDiskusi,
                  phase: 'F7',
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            _layar(
              '/profil',
              R.profil,
              (_, _) => const ProfilScreen(),
              routes: [
                _layar(
                  'anak/:id',
                  R.suntingAnak,
                  (_, state) =>
                      SuntingAnakScreen(id: state.pathParameters['id']!),
                ),
                _layar(
                  'laporan',
                  R.laporan,
                  (_, _) => const LaporanScreen(),
                  routes: [
                    _stub(':id', R.laporanDetail, S.titleLaporan, phase: 'F9'),
                  ],
                ),
                _layar(
                  'aksesibilitas',
                  R.aksesibilitas,
                  (_, _) => const AksesibilitasScreen(),
                ),
                _layar('izin', R.izin, (_, _) => const IzinBerbagiScreen()),
                _stub(
                  'cara-pakai',
                  R.caraPakai,
                  S.titleCaraPakai,
                  phase: 'F10',
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
);
