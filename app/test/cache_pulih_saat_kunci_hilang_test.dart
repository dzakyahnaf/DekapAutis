import 'dart:io';

import 'package:dekapautis/data/local/database.dart';
import 'package:dekapautis/data/local/koneksi/koneksi_native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// The cache key and the cache file have to be lost together.
///
/// flutter_secure_storage defaults to resetOnError: when the keystore becomes
/// unusable it deletes its own entries, reinitialises, and answers the next
/// read with an innocent null rather than raising anything. The app then
/// minted a fresh key and left the old encrypted file in place. A new key
/// cannot open it, sqlite calls that a corrupt file, and every read of the
/// cache failed from then on - which is what a caregiver saw as "Layanan
/// sedang tidak dapat dihubungi" on the home and plan screens, on a working
/// connection, for any account, permanently.
///
/// Reproduced on an emulator by replacing the wrapped key with a bogus one.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory dir;
  late List<String> dipanggil;
  late Map<String, String> tersimpan;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('dekap_uji');
    PathProviderPlatform.instance = _JalurUji(dir.path);
    dipanggil = [];
    tersimpan = {};
    lupakanKegagalanCache();

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
          (panggilan) async {
            dipanggil.add(panggilan.method);
            final arg = panggilan.arguments as Map?;
            final kunci = arg?['key'] as String?;
            switch (panggilan.method) {
              case 'read':
                return tersimpan[kunci];
              case 'write':
                tersimpan[kunci!] = arg!['value'] as String;
                return null;
              case 'delete':
                tersimpan.remove(kunci);
                return null;
              default:
                return null;
            }
          },
        );
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
          null,
        );
    if (dir.existsSync()) await dir.delete(recursive: true);
  });

  File berkasCache() => File('${dir.path}/dekapautis.sqlite');

  test('berkas lama dibuang saat kunci sudah tidak ada', () async {
    // What resetOnError leaves behind: a file written under a key that the
    // plugin has already deleted without telling anyone.
    await berkasCache().writeAsString('basi, terenkripsi kunci lama');
    await File('${berkasCache().path}-wal').writeAsString('basi');

    final db = DekapDatabase(bukaDatabaseTerenkripsi());
    // Any query at all. This is what threw on the phone: the file would not
    // open, so every read of the cache failed.
    await db.jadwalPada(DateTime.now());

    expect(
      tersimpan.values.single,
      hasLength(64),
      reason: 'kunci baru tidak dibuat',
    );
    await db.close();
  });

  test('berkas yang cocok dengan kuncinya dibiarkan', () async {
    // First run writes a key; the file that follows belongs to it and must
    // survive the second run, or the cache would be thrown away on every
    // single launch.
    var db = DekapDatabase(bukaDatabaseTerenkripsi());
    await db.jadwalPada(DateTime.now());
    await db.close();

    final kunciPertama = tersimpan.values.single;
    expect(berkasCache().existsSync(), isTrue, reason: 'berkas tidak dibuat');
    final isiSebelum = berkasCache().lengthSync();

    db = DekapDatabase(bukaDatabaseTerenkripsi());
    await db.jadwalPada(DateTime.now());
    await db.close();

    expect(tersimpan.values.single, kunciPertama, reason: 'kunci ikut berubah');
    expect(
      berkasCache().lengthSync(),
      isSebelumnya(isiSebelum),
      reason: 'cache yang masih terbaca ikut dibuang',
    );
  });

  test('kunci yang ada tetapi bukan pasangan berkasnya', () async {
    // The state a caregiver's phone was actually stuck in, and the one
    // reinstalling could not get out of: the plugin had already reset itself
    // once, the app had already minted a replacement key, and the file on disk
    // still belonged to the key before that. Both read back perfectly. Neither
    // opens the other.
    tersimpan['dekapautis.kunci_basis_data'] = 'a' * 64;
    await berkasCache().writeAsString('milik kunci yang sudah hilang');

    final db = DekapDatabase(bukaDatabaseTerenkripsi());
    // Threw SqliteException(26): file is not a database, which the repository
    // turned into "Layanan sedang tidak dapat dihubungi".
    await db.jadwalPada(DateTime.now());

    expect(
      tersimpan['dekapautis.kunci_basis_data'],
      'a' * 64,
      reason: 'kunci yang masih baik ikut dibuang',
    );
    await db.close();
  });

  test('keystore yang menolak menulis tidak menjatuhkan aplikasi', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
          (panggilan) async {
            if (panggilan.method == 'read') return null;
            if (panggilan.method == 'write') {
              throw PlatformException(code: 'Keystore', message: 'ditolak');
            }
            return null;
          },
        );

    final db = DekapDatabase(bukaDatabaseTerenkripsi());
    await db.jadwalPada(DateTime.now());

    expect(
      cacheTidakPermanen,
      isTrue,
      reason: 'kegagalan menyimpan kunci tidak dicatat',
    );
    await db.close();
  });
}

Matcher isSebelumnya(int nilai) => greaterThanOrEqualTo(nilai);

class _JalurUji extends PathProviderPlatform with MockPlatformInterfaceMixin {
  _JalurUji(this.jalur);
  final String jalur;

  @override
  Future<String?> getApplicationDocumentsPath() async => jalur;
}
