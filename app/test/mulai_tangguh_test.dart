import 'package:dekapautis/data/supabase/secure_session_storage.dart';
import 'package:dekapautis/main.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// A phone that hands back a white screen has nothing to report and nothing to
/// tap. Both guards below exist because that is what one did.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const saluran = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  final pesan =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  void keystoreMenolak() {
    pesan.setMockMethodCallHandler(
      saluran,
      (_) async => throw PlatformException(
        code: 'Keystore',
        message: 'Failed to unwrap key',
      ),
    );
  }

  void keystoreBekerja() {
    final isi = <String, String>{};
    pesan.setMockMethodCallHandler(saluran, (panggilan) async {
      final arg = Map<String, dynamic>.from(panggilan.arguments as Map);
      final kunci = arg['key'] as String;
      return switch (panggilan.method) {
        'write' => isi[kunci] = arg['value'] as String,
        'read' => isi[kunci],
        'containsKey' => isi.containsKey(kunci),
        'delete' => isi.remove(kunci),
        _ => null,
      };
    });
  }

  setUp(SecureSessionStorage.lupakanKegagalan);
  tearDown(() => pesan.setMockMethodCallHandler(saluran, null));

  group('penyimpanan sesi', () {
    test('memakai keystore saat keystore sehat', () async {
      keystoreBekerja();
      final simpanan = SecureSessionStorage();

      await simpanan.persistSession('{"sesi":1}');

      expect(await simpanan.hasAccessToken(), isTrue);
      expect(await simpanan.accessToken(), '{"sesi":1}');
      expect(SecureSessionStorage.sesiTidakTersimpan, isFalse);
    });

    test('keystore yang menolak tidak menjatuhkan aplikasi', () async {
      keystoreMenolak();
      final simpanan = SecureSessionStorage();

      // None of these may throw: Supabase.initialize calls them while starting,
      // and an exception there never reaches a screen - it reaches nothing.
      await simpanan.persistSession('{"sesi":2}');

      expect(await simpanan.hasAccessToken(), isTrue);
      expect(await simpanan.accessToken(), '{"sesi":2}');
      expect(
        SecureSessionStorage.sesiTidakTersimpan,
        isTrue,
        reason: 'ditandai agar keadaan ini tidak diam-diam',
      );
    });

    test('sesi dalam memori dapat dihapus saat keluar akun', () async {
      keystoreMenolak();
      final simpanan = SecureSessionStorage();
      await simpanan.persistSession('{"sesi":3}');

      await simpanan.removePersistedSession();

      expect(await simpanan.hasAccessToken(), isFalse);
      expect(await simpanan.accessToken(), isNull);
    });
  });

  group('layar gagal mulai', () {
    testWidgets('menjelaskan keadaan dan menawarkan langkah', (tester) async {
      await tester.pumpWidget(
        const LayarGagalMulai(rincian: 'PlatformException(Keystore)'),
      );

      expect(find.text('DekapAutis belum dapat dimulai'), findsOneWidget);
      expect(find.textContaining('Periksa koneksi internet'), findsOneWidget);
      expect(find.text('Coba lagi'), findsOneWidget);
    });

    testWidgets('menampilkan rincian teknis agar dapat dilaporkan', (
      tester,
    ) async {
      await tester.pumpWidget(
        const LayarGagalMulai(rincian: 'Menyiapkan layanan: TimeoutException'),
      );

      expect(find.text('Rincian teknis'), findsOneWidget);
      expect(find.textContaining('TimeoutException'), findsOneWidget);
    });
  });
}
