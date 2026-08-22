import 'package:go_router/go_router.dart';

/// Walks the go_router tree and returns every concrete path it can serve.
///
/// Shared by `text_scale_test.dart` and `semantics_test.dart` so neither keeps
/// its own hand-typed list of screens. A hand-kept list is a list that goes
/// stale: the screens F7 still owes are covered by both audits the moment they
/// land, with nobody having to remember to add them twice.
///
/// Shell routes contribute no path of their own; their branches do. Path
/// parameters are filled with `demo`, which also exercises what a screen does
/// with an id that matches nothing - the deep-link case from docs/05.
List<String> kumpulkanRute(List<RouteBase> routes, [String induk = '']) {
  final hasil = <String>[];

  for (final route in routes) {
    switch (route) {
      case GoRoute():
        final path = _gabung(induk, route.path);
        // A route with a builder serves a screen; one with only children is
        // just a namespace and has nothing to render.
        if (route.builder != null || route.pageBuilder != null) {
          hasil.add(_isiParameter(path));
        }
        hasil.addAll(kumpulkanRute(route.routes, path));
      case StatefulShellRoute():
        for (final branch in route.branches) {
          hasil.addAll(kumpulkanRute(branch.routes, induk));
        }
      case ShellRouteBase():
        hasil.addAll(kumpulkanRute(route.routes, induk));
    }
  }

  return hasil;
}

String _gabung(String induk, String path) {
  if (path.startsWith('/')) return path;
  final dasar = induk.endsWith('/')
      ? induk.substring(0, induk.length - 1)
      : induk;
  return '$dasar/$path';
}

String _isiParameter(String path) =>
    path.replaceAll(RegExp(r':[A-Za-z]+'), 'demo');
