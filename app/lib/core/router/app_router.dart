import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/widgets/app_shell.dart';
import '../../shared/widgets/placeholder_screen.dart';
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

/// Full route tree for the 17 caregiver screens plus the professional and
/// administrator surfaces, so all three actors in Gambar 6.1 are reachable.
final appRouter = GoRouter(
  navigatorKey: _rootKey,
  initialLocation: '/splash',
  routes: [
    _stub('/splash', R.splash, S.appName, phase: 'L.13 - F1'),
    _stub('/masuk', R.masuk, S.titleMasuk, phase: 'L.14 - F1'),
    _stub('/daftar', R.daftar, S.titleDaftar, phase: 'F1'),
    _stub(
      '/onboarding/:langkah',
      R.onboarding,
      S.titleOnboarding,
      phase: 'L.1 - F2',
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
            _stub('/beranda', R.beranda, S.titleBeranda, phase: 'L.2 - F3'),
          ],
        ),
        StatefulShellBranch(
          routes: [
            _stub(
              '/rencana',
              R.rencana,
              S.titleRencana,
              phase: 'L.6 - F3',
              routes: [
                _stub(
                  'aktivitas/:id',
                  R.aktivitas,
                  S.titleAktivitas,
                  phase: 'L.7 - F3',
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            _stub(
              '/tanya',
              R.tanya,
              S.titleTanya,
              phase: 'L.3 - F5',
              routes: [
                _stub(
                  'sumber/:jawabanId',
                  R.sumber,
                  S.titleSumber,
                  phase: 'L.4 - F5',
                ),
              ],
            ),
          ],
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
            _stub(
              '/profil',
              R.profil,
              S.titleProfil,
              phase: 'L.16 - F2',
              routes: [
                _stub(
                  'laporan',
                  R.laporan,
                  S.titleLaporan,
                  phase: 'L.8 - F6',
                  routes: [
                    _stub(':id', R.laporanDetail, S.titleLaporan, phase: 'F6'),
                  ],
                ),
                _stub(
                  'aksesibilitas',
                  R.aksesibilitas,
                  S.titleAksesibilitas,
                  phase: 'L.15 - F2',
                ),
                _stub('izin', R.izin, S.titleIzin, phase: 'F6'),
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
