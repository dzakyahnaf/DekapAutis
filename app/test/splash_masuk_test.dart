import 'dart:async';

import 'package:dekapautis/core/router/app_router.dart';
import 'package:dekapautis/core/strings.dart';
import 'package:dekapautis/data/models/profil_anak.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fakes.dart';

/// Guards the first thing a judge ever taps.
///
/// "Masuk sebagai demo" left the app sitting on "Menyiapkan rencana hari ini..."
/// in a shipped release. Two separate defects, both invisible to every test that
/// existed at the time, because the fake auth stream was `Stream.empty()` and so
/// never emitted:
///
///   * the splash awaited providers that watch `statusAuthProvider`; signing in
///     made that stream emit, invalidating them mid-await, and the discarded
///     future never completed
///   * the demo button signed in but never navigated
///
/// Nothing threw. The screen simply stopped, with no timeout and no error state.
void main() {
  const anak = ProfilAnak(
    id: 'anak-1',
    penggunaId: 'p1',
    namaPanggilan: 'Bima',
    usia: 6,
    kemampuanKomunikasi: KemampuanKomunikasi.kalimatPendek,
    sensitivitasSensorik: {SensitivitasSensorik.suaraKeras},
    fokusPerkembangan: {FokusPerkembangan.rutinitasPagi},
  );

  /// Navigate before the first pump, never after. `appRouter` is a global: a
  /// preceding test leaves it wherever it landed, so without this reset the
  /// splash never runs and every `findsNothing` below passes for the wrong
  /// reason.
  Future<void> jalankanSplash(
    WidgetTester tester,
    FakeAuthRepository auth, {
    List<ProfilAnak> daftar = const [],
    bool pancarkanSaatMemuatAnak = false,
  }) async {
    addTearDown(auth.tutupStatus);
    appRouter.go('/splash');
    await tester.pumpWidget(
      aplikasiUji(
        auth: auth,
        profil: FakeProfilAnakRepository(
          awal: [...daftar],
          saatMemuat: pancarkanSaatMemuatAnak ? auth.pancarkanMasuk : null,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('layar muat memang terlihat selagi splash memutuskan', (
    tester,
  ) async {
    // The positive control. Without it, a splash that never ran would satisfy
    // every findsNothing below, and this file would guard nothing at all.
    final auth = _AuthTertahan();
    addTearDown(auth.lepas);
    addTearDown(auth.tutupStatus);
    appRouter.go('/splash');
    await tester.pumpWidget(aplikasiUji(auth: auth));
    await tester.pump();

    expect(find.text(S.memuatRencana), findsOneWidget);

    auth.lepas();
    await tester.pumpAndSettle();
    expect(find.text(S.memuatRencana), findsNothing);
  });

  testWidgets('splash tidak menggantung saat auth memancar mid-await', (
    tester,
  ) async {
    // The shipped bug, reproduced: the sign-in emission lands while the child
    // lookup is still pending. Reading the repository directly is what makes
    // this survivable - through daftarAnakProvider the await never returns.
    await jalankanSplash(
      tester,
      FakeAuthRepository(masuk_: true, pancarkanSaatPeranDibaca: true),
      daftar: const [anak],
      pancarkanSaatMemuatAnak: true,
    );
    expect(find.text(S.memuatRencana), findsNothing);
    expect(find.text('Rencana hari ini'), findsOneWidget);
  });

  testWidgets('pengasuh dengan anak mendarat di beranda', (tester) async {
    await jalankanSplash(
      tester,
      FakeAuthRepository(masuk_: true, pancarkanSaatPeranDibaca: true),
      daftar: const [anak],
    );
    expect(find.text(S.memuatRencana), findsNothing);
    expect(find.text('Rencana hari ini'), findsOneWidget);
  });

  testWidgets('pengasuh tanpa anak mendarat di onboarding', (tester) async {
    await jalankanSplash(
      tester,
      FakeAuthRepository(masuk_: true, pancarkanSaatPeranDibaca: true),
    );
    expect(find.text(S.memuatRencana), findsNothing);
    expect(find.text('Rencana hari ini'), findsNothing);
  });

  testWidgets('belum masuk diarahkan ke layar masuk', (tester) async {
    await jalankanSplash(tester, FakeAuthRepository());
    expect(find.text(S.memuatRencana), findsNothing);
    expect(find.text(S.titleMasuk), findsWidgets);
  });

  testWidgets('peranSaya yang gagal tetap mendarat, tidak menggantung', (
    tester,
  ) async {
    await jalankanSplash(tester, _AuthGagal(), daftar: const [anak]);
    // The plan and catalogue are cached on device, so /beranda has something to
    // show. Landing anywhere beats a splash that will never move.
    expect(find.text(S.memuatRencana), findsNothing);
  });
}

/// Signed in, with the role lookup held open until the test releases it.
class _AuthTertahan extends FakeAuthRepository {
  _AuthTertahan() : super(masuk_: true);

  final _tahan = Completer<void>();

  void lepas() {
    if (!_tahan.isCompleted) _tahan.complete();
  }

  @override
  Future<Peran?> peranSaya() async {
    await _tahan.future;
    return Peran.pengasuh;
  }
}

/// Signed in, but the role lookup throws - the shape of a backend outage.
class _AuthGagal extends FakeAuthRepository {
  _AuthGagal() : super(masuk_: true);

  @override
  Future<Peran?> peranSaya() async =>
      throw Exception('peladen tidak terjangkau');
}
