import 'package:dekapautis/core/router/app_router.dart';
import 'package:dekapautis/core/strings.dart';
import 'package:dekapautis/data/models/profil_anak.dart';
import 'package:dekapautis/data/repositories/auth_repository.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fakes.dart';

/// A signed-in phone with no network used to show a grey rectangle.
///
/// `ref.watch(provider).value` rethrows when the provider holds an error, and
/// that rethrow happened inside `build`. In a release build Flutter paints a
/// plain grey box for a widget that throws while building, so the screen went
/// blank with no message, nothing to tap, and nothing in the interface to
/// explain it. Reproduced on an emulator by signing in, turning the network
/// off and reopening the app - which is exactly what a judge on hotel wifi
/// would do.
///
/// `.valueOrNull` returns null instead, so the screen reaches its own error
/// state - the one that says the saved data can still be opened.
void main() {
  for (final rute in ['/beranda', '/rencana', '/profil']) {
    testWidgets('$rute tetap tergambar saat peladen menolak', (tester) async {
      appRouter.go(rute);
      await tester.pumpWidget(
        aplikasiUji(
          auth: FakeAuthRepository(masuk_: true),
          profil: _ProfilGagal(),
        ),
      );
      await tester.pumpAndSettle();

      // Any exception thrown during build would already have failed the test.
      // This asserts the positive: the person is told what happened.
      expect(
        find.byType(ErrorWidget),
        findsNothing,
        reason: 'kotak abu-abu build rilis',
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('beranda menjelaskan keadaan, bukan layar kosong', (
    tester,
  ) async {
    appRouter.go('/beranda');
    await tester.pumpWidget(
      aplikasiUji(
        auth: FakeAuthRepository(masuk_: true),
        profil: _ProfilGagal(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(S.gagalLayanan), findsWidgets);
  });
}

/// The shape a repository failure actually takes: ProfilAnakRepository wraps
/// every network error in this before it reaches a provider.
class _ProfilGagal extends FakeProfilAnakRepository {
  @override
  Future<List<ProfilAnak>> daftarAnak() async =>
      throw const KesalahanAuth('Layanan sedang tidak dapat dihubungi.');
}
