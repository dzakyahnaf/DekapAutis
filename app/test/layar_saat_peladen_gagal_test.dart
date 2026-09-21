import 'package:dekapautis/core/router/app_router.dart';
import 'package:dekapautis/data/models/profil_anak.dart';
import 'package:dekapautis/data/repositories/auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fakes.dart';
import 'support/rute.dart';

/// Every screen, with a server that refuses everything.
///
/// A signed-in phone with no usable backend used to show a grey rectangle:
/// `ref.watch(provider).value` rethrows when the provider holds an error, and
/// that rethrow happened inside `build`. In a release build Flutter paints a
/// plain grey box for a widget that throws while building, so the screen went
/// blank with no message, nothing to tap, and nothing to explain it.
/// Reproduced on an emulator by signing in, turning the network off and
/// reopening - which is exactly what a judge on hotel wifi would do.
///
/// This walks the route tree out of the router rather than naming screens by
/// hand. Three routes were checked here originally, and the bugs that followed
/// were each found on a fourth screen by the person using the app instead of
/// by this file. A hand-kept list is a list that goes stale.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final rute = kumpulkanRute(appRouter.configuration.routes);

  test('sapuan ini benar-benar menyentuh seluruh pohon rute', () {
    // Guards the sweep itself: a walk that quietly returned nothing would let
    // every test below pass while doing no work at all.
    expect(rute.length, greaterThanOrEqualTo(20), reason: rute.join('\n'));
    expect(rute, contains('/beranda'));
    expect(rute, contains('/tanya'));
    expect(rute, contains('/profil/laporan'));
  });

  for (final path in rute) {
    testWidgets('$path tetap tergambar saat peladen menolak', (tester) async {
      final masalah = <String>[];
      final sebelumnya = FlutterError.onError;
      FlutterError.onError = (d) =>
          masalah.add(d.exceptionAsString().split('\n').first);

      try {
        appRouter.go(path);
        await tester.pumpWidget(
          aplikasiUji(
            auth: FakeAuthRepository(masuk_: true),
            profil: _ProfilGagal(),
            peladen: PeladenPalsu()..daring = false,
          ),
        );
        await tester.pumpAndSettle(const Duration(milliseconds: 100));
      } finally {
        FlutterError.onError = sebelumnya;
      }

      expect(
        find.byType(ErrorWidget),
        findsNothing,
        reason: 'kotak abu-abu build rilis di $path',
      );
      expect(
        masalah,
        isEmpty,
        reason: '$path melempar saat peladen menolak:\n${masalah.join('\n')}',
      );
      expect(
        tester.takeException(),
        isNull,
        reason: 'pengecualian tidak tertangani di $path',
      );
      // A screen that renders nothing at all is a blank screen by another
      // name, which is the thing this file exists to prevent.
      expect(
        find.byType(Scaffold),
        findsWidgets,
        reason: '$path tidak menggambar apa pun',
      );
    });
  }

  testWidgets('beranda menyebut alasannya, bukan layar kosong', (tester) async {
    appRouter.go('/beranda');
    await tester.pumpWidget(
      aplikasiUji(
        auth: FakeAuthRepository(masuk_: true),
        profil: _ProfilGagal(),
        peladen: PeladenPalsu()..daring = false,
      ),
    );
    await tester.pumpAndSettle();

    // The message the repository raised, not a blanket one. Beranda used to
    // print S.gagalLayanan whatever had happened, which pointed the reader at
    // their signal bars for faults that had nothing to do with the network.
    expect(find.text(_pesan), findsWidgets);
  });
}

const _pesan = 'Layanan sedang tidak dapat dihubungi.';

class _ProfilGagal extends FakeProfilAnakRepository {
  @override
  Future<List<ProfilAnak>> daftarAnak() async =>
      throw const KesalahanAuth(_pesan);
}
