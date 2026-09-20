import 'package:dekapautis/core/router/app_router.dart';
import 'package:dekapautis/data/repositories/auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fakes.dart';

/// "Lupa kata sandi" used to stop halfway.
///
/// The button sent the mail, the link reopened the app, supabase_flutter
/// exchanged it for a session - and the person landed on the home screen,
/// signed in, with the old password still in force. Nothing ever asked for a
/// new one, so the feature quietly did the opposite of what it promised: it
/// was a magic-link sign-in wearing a password reset's label.
void main() {
  Future<void> pulihkan(WidgetTester tester, FakeAuthRepository auth) async {
    addTearDown(auth.tutupStatus);
    appRouter.go('/masuk');
    await tester.pumpWidget(aplikasiUji(auth: auth));
    await tester.pump();
    auth.pancarkanPemulihanSandi();
    await tester.pumpAndSettle();
  }

  FakeAuthRepository fake() =>
      FakeAuthRepository(masuk_: true, denganAliranStatus: true);

  testWidgets('tautan pemulihan membuka layar kata sandi baru', (tester) async {
    await pulihkan(tester, fake());

    expect(find.text('Kata sandi baru'), findsWidgets);
    expect(find.text('Simpan kata sandi'), findsOneWidget);
  });

  testWidgets('kata sandi terlalu pendek ditolak sebelum menyentuh peladen', (
    tester,
  ) async {
    final auth = fake();
    await pulihkan(tester, auth);

    await tester.enterText(find.byType(TextField).first, 'abc');
    await tester.enterText(find.byType(TextField).last, 'abc');
    await tester.tap(find.text('Simpan kata sandi'));
    await tester.pumpAndSettle();

    expect(find.textContaining('minimal 6 karakter'), findsOneWidget);
    expect(auth.sandiTersimpan, isNull, reason: 'jangan panggil peladen');
  });

  testWidgets('dua isian yang berbeda ditolak', (tester) async {
    final auth = fake();
    await pulihkan(tester, auth);

    await tester.enterText(find.byType(TextField).first, 'rahasiabaru');
    await tester.enterText(find.byType(TextField).last, 'rahasialain');
    await tester.tap(find.text('Simpan kata sandi'));
    await tester.pumpAndSettle();

    expect(find.textContaining('belum sama'), findsOneWidget);
    expect(auth.sandiTersimpan, isNull);
  });

  testWidgets('kata sandi yang sah tersimpan lalu lanjut ke aplikasi', (
    tester,
  ) async {
    final auth = fake();
    await pulihkan(tester, auth);

    await tester.enterText(find.byType(TextField).first, 'rahasiabaru');
    await tester.enterText(find.byType(TextField).last, 'rahasiabaru');
    await tester.tap(find.text('Simpan kata sandi'));
    await tester.pumpAndSettle();

    expect(auth.sandiTersimpan, 'rahasiabaru');
    expect(
      find.text('Simpan kata sandi'),
      findsNothing,
      reason: 'layar ini tidak boleh tertinggal setelah berhasil',
    );
  });

  testWidgets('galat dari peladen tampil, layar tetap terbuka', (tester) async {
    final auth = _AuthMenolak();
    await pulihkan(tester, auth);

    await tester.enterText(find.byType(TextField).first, 'rahasiabaru');
    await tester.enterText(find.byType(TextField).last, 'rahasiabaru');
    await tester.tap(find.text('Simpan kata sandi'));
    await tester.pumpAndSettle();

    expect(find.text('Tautan sudah kedaluwarsa.'), findsOneWidget);
    expect(find.text('Simpan kata sandi'), findsOneWidget);
  });
}

/// A recovery link that has already been used, which is the common way this
/// fails in real life.
class _AuthMenolak extends FakeAuthRepository {
  _AuthMenolak() : super(masuk_: true, denganAliranStatus: true);

  @override
  Future<void> gantiSandi(String sandiBaru) async =>
      throw const KesalahanAuth('Tautan sudah kedaluwarsa.');
}
