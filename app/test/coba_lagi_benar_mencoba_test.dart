import 'package:dekapautis/core/router/app_router.dart';
import 'package:dekapautis/core/strings.dart';
import 'package:dekapautis/data/models/profil_anak.dart';
import 'package:dekapautis/data/repositories/auth_repository.dart';
import 'package:dekapautis/shared/widgets/buttons.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fakes.dart';

/// One failed lookup used to break the home screen until the app was closed.
///
/// Riverpod keeps a failed future and hands the same failure back to every
/// later read, so the home screen's "Coba lagi" - which re-read that future
/// rather than invalidating it - could never recover. Every other screen in
/// the app invalidates the provider it is retrying; this was the one that did
/// not. The child profile it failed on is shared with the plan and profile
/// screens, so all three stayed broken together.
///
/// Reported from a real phone: signing in with Google landed on a home screen
/// reading "Layanan sedang tidak dapat dihubungi" over a working LTE
/// connection, with a retry button that did nothing at all.
void main() {
  testWidgets('satu kegagalan tidak mengunci beranda', (tester) async {
    final profil = _GagalSekali();
    appRouter.go('/beranda');
    await tester.pumpWidget(
      aplikasiUji(auth: FakeAuthRepository(masuk_: true), profil: profil),
    );
    await tester.pumpAndSettle();

    expect(
      profil.panggilan,
      greaterThan(1),
      reason: 'kegagalan pertama tidak pernah dicoba ulang',
    );
    expect(
      find.widgetWithText(SecondaryButton, S.aksiCobaLagi),
      findsNothing,
      reason: 'peladen sudah menjawab tetapi layar masih menampilkan galat',
    );
  });

  testWidgets('Coba lagi benar-benar bertanya ulang ke peladen', (
    tester,
  ) async {
    final profil = _SelaluGagal();
    appRouter.go('/beranda');
    await tester.pumpWidget(
      aplikasiUji(auth: FakeAuthRepository(masuk_: true), profil: profil),
    );
    await tester.pumpAndSettle();

    // The first-run tour covers the home screen, deliberately: it is modal.
    // Nothing behind it can be tapped until it is out of the way.
    await tester.tap(find.text('Lewati'));
    await tester.pumpAndSettle();

    final tombol = find.widgetWithText(SecondaryButton, S.aksiCobaLagi);
    expect(
      tombol,
      findsOneWidget,
      reason: 'galat harus menawarkan jalan keluar',
    );

    final sebelum = profil.panggilan;
    await tester.tap(tombol);
    await tester.pumpAndSettle();

    expect(
      profil.panggilan,
      greaterThan(sebelum),
      reason:
          'Coba lagi membaca ulang kegagalan yang sudah tersimpan, '
          'bukan bertanya lagi ke peladen',
    );
  });

  testWidgets('galat menyebutkan alasannya, bukan menyalahkan jaringan', (
    tester,
  ) async {
    appRouter.go('/beranda');
    await tester.pumpWidget(
      aplikasiUji(
        auth: FakeAuthRepository(masuk_: true),
        profil: _SelaluGagal(),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Profil anak belum dapat dibaca. Coba lagi sebentar lagi.'),
      findsOneWidget,
      reason: 'alasan sebenarnya disembunyikan di balik pesan umum',
    );
  });
}

class _GagalSekali extends FakeProfilAnakRepository {
  int panggilan = 0;

  @override
  Future<List<ProfilAnak>> daftarAnak() async {
    panggilan++;
    if (panggilan == 1) {
      throw const KesalahanAuth('Layanan sedang tidak dapat dihubungi.');
    }
    return super.daftarAnak();
  }
}

class _SelaluGagal extends FakeProfilAnakRepository {
  int panggilan = 0;

  @override
  Future<List<ProfilAnak>> daftarAnak() async {
    panggilan++;
    throw const KesalahanAuth(
      'Profil anak belum dapat dibaca. Coba lagi sebentar lagi.',
    );
  }
}
