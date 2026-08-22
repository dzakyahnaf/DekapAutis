import 'dart:io';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Android and desktop: a real file, encrypted.
///
/// KNF-03 and Bab 4.3 promise encryption at rest. package:sqlite3 is built with
/// SQLite3MultipleCiphers (see the hook in pubspec.yaml), so the file is
/// unreadable without the key - and the key lives in the Android Keystore, not
/// beside the data.
///
/// Losing the key means losing the cache, which is the correct trade: the cache
/// is a copy, and the server still holds anything that finished syncing.
QueryExecutor bukaDatabaseTerenkripsi() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final berkas = File(p.join(dir.path, 'dekapautis.sqlite'));
    final kunci = await _kunciDatabase();

    return NativeDatabase.createInBackground(
      berkas,
      setup: (db) {
        // Must run before anything touches the file.
        db.execute("PRAGMA key = '$kunci';");
        db.execute('PRAGMA foreign_keys = ON;');
      },
    );
  });
}

/// For tests: in memory, no encryption and no file.
QueryExecutor bukaDatabaseMemori() => NativeDatabase.memory();

/// True when this build keeps the cache after the app is closed.
const menyimpanPermanen = true;

const _penyimpanan = FlutterSecureStorage(aOptions: AndroidOptions());
const _kunciNama = 'dekapautis.kunci_basis_data';

Future<String> _kunciDatabase() async {
  final ada = await _penyimpanan.read(key: _kunciNama);
  if (ada != null && ada.isNotEmpty) return ada;

  final baru = _kunciAcak();
  await _penyimpanan.write(key: _kunciNama, value: baru);
  return baru;
}

/// 32 bytes from the platform CSPRNG, hex encoded so it survives PRAGMA quoting
/// and can never contain a quote character of its own.
String _kunciAcak() {
  final acak = Random.secure();
  final bytes = List<int>.generate(32, (_) => acak.nextInt(256));
  return [for (final b in bytes) b.toRadixString(16).padLeft(2, '0')].join();
}
