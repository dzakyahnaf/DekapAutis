import 'package:dekapautis/core/router/app_router.dart';
import 'package:dekapautis/main.dart';
import 'package:dekapautis/shared/widgets/placeholder_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// The route tree is the demo script's backbone: docs/05 relies on named routes
/// so a screen can be reached directly while the camera is running. A route
/// that silently stopped resolving would only be discovered mid-recording.
void main() {
  /// Every path that must resolve, including the professional and administrator
  /// surfaces, so all three actors in Gambar 6.1 are reachable.
  const paths = <String>[
    '/splash',
    '/masuk',
    '/daftar',
    '/onboarding/1',
    '/notifikasi',
    '/beranda',
    '/rencana',
    '/rencana/aktivitas/abc',
    '/tanya',
    '/tanya/sumber/xyz',
    '/direktori',
    '/direktori/abc',
    '/pustaka',
    '/pustaka/abc',
    '/komunitas',
    '/komunitas/abc',
    '/profil',
    '/profil/laporan',
    '/profil/laporan/abc',
    '/profil/aksesibilitas',
    '/profil/izin',
    '/profil/cara-pakai',
    '/profesional/masuk-kotak',
    '/profesional/laporan/abc',
    '/profesional/profil',
    '/admin/verifikasi',
    '/admin/pengetahuan',
    '/admin/moderasi',
  ];

  List<GoRoute> flatten(List<RouteBase> routes) => [
    for (final route in routes) ...[
      if (route is GoRoute) route,
      if (route is GoRoute) ...flatten(route.routes),
      if (route is ShellRouteBase) ...flatten(route.routes),
    ],
  ];

  test('route names are unique', () {
    final names = flatten(
      appRouter.configuration.routes,
    ).map((r) => r.name).whereType<String>().toList();

    expect(names, isNotEmpty);
    expect(
      names.toSet().length,
      names.length,
      reason: 'duplicate route name in app_router.dart',
    );
  });

  test('28 routes are declared, covering all three actors', () {
    expect(flatten(appRouter.configuration.routes).length, paths.length);
  });

  testWidgets('every declared path resolves to a screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: DekapAutisApp()));
    await tester.pumpAndSettle();

    for (final path in paths) {
      appRouter.go(path);
      await tester.pumpAndSettle();

      expect(
        find.byType(PlaceholderScreen),
        findsOneWidget,
        reason: 'no screen rendered for $path',
      );
      expect(
        find.textContaining(path),
        findsOneWidget,
        reason: 'wrong screen rendered for $path',
      );
    }
  });

  testWidgets('the five bottom destinations are labelled in Indonesian', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: DekapAutisApp()));
    appRouter.go('/beranda');
    await tester.pumpAndSettle();

    for (final label in ['Beranda', 'Rencana', 'Tanya', 'Jelajah', 'Profil']) {
      expect(
        find.text(label),
        findsWidgets,
        reason: 'bottom destination "$label" is missing its label',
      );
    }
  });
}
