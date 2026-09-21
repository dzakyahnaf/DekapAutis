import 'package:dekapautis/core/router/app_router.dart';
import 'package:dekapautis/core/strings.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fakes.dart';

/// "Masuk dengan Google" signed the person in and left them on the sign-in
/// screen.
///
/// Reproduced on an emulator by handing the app a real session through the
/// deep link it uses as its OAuth callback: the session was created and
/// persisted - reopening the app landed straight on the home screen - but the
/// screen in front of the person never moved. Google's own confirmation mail
/// arrived, so from the outside the app had simply ignored a successful
/// sign-in.
///
/// Two separate faults, one symptom:
///
///   * `normaliseDeepLink` routed the callback by its host. `redirectTo` is
///     `dekapautis://masuk`, so the callback was sent to the sign-in screen -
///     the screen the person had just left - while the exchange ran in the
///     background.
///   * Nothing listened for `signedIn`. Email sign-in navigates from the
///     button that started it, but an OAuth session arrives long after that
///     button has returned, so no code was left to move anyone.
void main() {
  group('callback auth dikenali, bukan diperlakukan sebagai rute layar', () {
    test('kode PKCE di query tidak mendarat di layar masuk', () {
      final tujuan = normaliseDeepLink(
        Uri.parse('dekapautis://masuk?code=abc123'),
      );
      expect(tujuan, '/splash');
      expect(
        tujuan,
        isNot(contains('code')),
        reason: 'kode sekali pakai tidak boleh ikut di dalam rute',
      );
    });

    test('token di fragment juga dikenali', () {
      expect(
        normaliseDeepLink(
          Uri.parse('dekapautis://masuk#access_token=xyz&token_type=bearer'),
        ),
        '/splash',
      );
    });

    test('penolakan dari penyedia dikenali', () {
      expect(
        normaliseDeepLink(Uri.parse('dekapautis://masuk?error=access_denied')),
        '/splash',
      );
    });

    test('tautan pintasan demo tetap apa adanya', () {
      expect(normaliseDeepLink(Uri.parse('dekapautis://beranda')), '/beranda');
      expect(
        normaliseDeepLink(Uri.parse('dekapautis://profil/laporan')),
        '/profil/laporan',
      );
      expect(normaliseDeepLink(Uri.parse('https://contoh.id/beranda')), isNull);
    });
  });

  testWidgets('sesi yang datang belakangan memindahkan layar', (tester) async {
    final auth = FakeAuthRepository(denganAliranStatus: true);
    appRouter.go('/masuk');
    await tester.pumpWidget(aplikasiUji(auth: auth));
    await tester.pumpAndSettle();
    expect(
      find.text(S.masukSebagaiDemo),
      findsOneWidget,
      reason: 'mulai di layar masuk',
    );

    // What supabase_flutter does once it has exchanged the callback: the
    // session exists before anything on screen knows about it.
    auth.masuk_ = true;
    auth.pancarkanMasuk();
    await tester.pumpAndSettle();

    expect(
      appRouter.state.uri.path,
      isNot('/masuk'),
      reason: 'sudah masuk tetapi masih di layar masuk',
    );
    auth.tutupStatus();
  });

  testWidgets('callback yang gagal mengatakan sesuatu', (tester) async {
    final auth = FakeAuthRepository(denganAliranStatus: true);
    appRouter.go('/masuk');
    await tester.pumpWidget(aplikasiUji(auth: auth));
    await tester.pumpAndSettle();

    auth.pancarkanGalat();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      find.text(S.gagalMasukLuar),
      findsOneWidget,
      reason: 'gagal masuk tanpa sepatah kata pun',
    );
    auth.tutupStatus();
  });
}
