import 'dart:io';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

/// Android and desktop: a real file, encrypted.
///
/// KNF-03 and Bab 4.3 promise encryption at rest. package:sqlite3 is built with
/// SQLite3MultipleCiphers (see the hook in pubspec.yaml), so the file is
/// unreadable without the key - and the key lives in the Android Keystore, not
/// beside the data.
///
/// Losing the key means losing the cache, which is the correct trade: the cache
/// is a copy, and the server still holds anything that finished syncing. That
/// sentence was here from the start and the code underneath it did not keep the
/// promise - it lost the key and kept the file.
///
/// HOW THE KEY AND THE FILE COME APART
/// -----------------------------------
/// flutter_secure_storage defaults to resetOnError. When the keystore becomes
/// unusable - an OEM reset, a restore that brought back the encrypted blob
/// without the key material behind it, an algorithm migration - the plugin does
/// not raise anything for this file to catch. It deletes its own entries,
/// reinitialises, and answers the next read with a perfectly innocent null.
///
/// The key is then gone and the database file is not. A fresh key cannot open
/// a file encrypted with the old one, sqlite calls that a corrupt file rather
/// than a wrong password, and every read of the cache fails from that moment
/// on. The home and plan screens read the plan out of that cache, so both
/// showed "Layanan sedang tidak dapat dihubungi" on a phone with a working
/// connection, for any account, permanently - and reinstalling did not help,
/// because the backup restored the same stale file again.
///
/// Reproduced on an emulator by replacing the wrapped key with a bogus one:
/// the plugin wiped itself, the app minted a new key, and the very next launch
/// showed that message. So the rule below is simply: a new key means the old
/// file is unreadable by definition, and it goes.
QueryExecutor bukaDatabaseTerenkripsi() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final berkas = File(p.join(dir.path, 'dekapautis.sqlite'));
    final kunci = await _kunciDatabase(berkas);

    // A key that exists is not the same as a key that fits. The plugin can
    // reset itself between two launches, the app then mints a fresh key, and
    // the file already on disk still belongs to the old one - a pair that
    // reads perfectly and opens nothing. That is the state a caregiver's phone
    // was in, and it is the state reinstalling could not get out of, so the
    // file is tried here rather than at the first query on the home screen.
    if (berkas.existsSync() && !_dapatDibuka(berkas, kunci)) {
      debugPrint('Cache lama tidak cocok dengan kunci saat ini, dibuat ulang.');
      await _buangBerkas(berkas);
    }

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

/// Set when the keystore could not hold the key, so the cache lasts only as
/// long as this run of the app. Read by the status strip.
bool get cacheTidakPermanen => _cacheTidakPermanen;
bool _cacheTidakPermanen = false;

@visibleForTesting
void lupakanKegagalanCache() => _cacheTidakPermanen = false;

/// The key for the cache, obtained however it can be.
///
/// Three outcomes, in order of preference: the key already in the keystore, a
/// fresh key the keystore accepts, or a key that lives only in this process.
/// The last one costs the caregiver a re-download of their plan next launch.
/// The alternative - throwing - costs them the whole app, so it is not a
/// trade worth making.
Future<String> _kunciDatabase(File berkas) async {
  try {
    final ada = await _penyimpanan.read(key: _kunciNama);
    if (ada != null && ada.isNotEmpty) return ada;
  } on Object catch (e) {
    // Any failure at all, not just PlatformException: a plugin missing on this
    // device throws MissingPluginException, and the outcome for the person
    // holding the phone is identical.
    debugPrint('Kunci cache tidak dapat dibaca: $e');
  }

  // Reaching here means there is no key, so whatever is on disk was encrypted
  // with one nobody can produce again. The file has to go with it.
  //
  // This is the case that actually reached a caregiver's phone, and it is the
  // quiet one: flutter_secure_storage defaults to resetOnError, so a keystore
  // it cannot use is not an exception to catch - the plugin wipes its own
  // entries and returns an innocent null. The app minted a fresh key, left the
  // old file where it was, and every read of the cache failed from then on.
  // The home and plan screens read the plan out of that cache, so both showed
  // "Layanan sedang tidak dapat dihubungi" on a phone with a working
  // connection, for any account, permanently.
  await _buang(berkas);

  final baru = _kunciAcak();
  try {
    await _penyimpanan.write(key: _kunciNama, value: baru);
  } on Object catch (e) {
    debugPrint('Kunci cache tidak dapat disimpan, cache hanya untuk sesi: $e');
    _cacheTidakPermanen = true;
  }
  return baru;
}

/// Drops the stale key entry and the file it belonged to.
///
/// Both have to go together. A new key cannot open a file encrypted with the
/// old one, and sqlite reports that as a corrupt file rather than a wrong
/// password, so leaving the file behind only moves the failure one step later
/// - to every read, forever.
Future<void> _buang(File berkas) async {
  try {
    await _penyimpanan.delete(key: _kunciNama);
  } on Object {
    // Nothing to do about it, and nothing depends on it having worked.
  }
  await _buangBerkas(berkas);
}

/// Deletes the cache and the two files sqlite keeps beside it.
Future<void> _buangBerkas(File berkas) async {
  for (final akhiran in ['', '-wal', '-shm', '-journal']) {
    final f = File('${berkas.path}$akhiran');
    try {
      if (f.existsSync()) await f.delete();
    } on Object catch (e) {
      debugPrint('Berkas cache lama tidak dapat dihapus: $e');
    }
  }
}

/// Whether this key actually opens this file.
///
/// SQLite3MultipleCiphers reports a wrong key as a corrupt file rather than a
/// refused password, and only when something reads a page - which is why the
/// mismatch surfaced as a failure on the home screen instead of here. Reading
/// the schema is the cheapest thing that touches a page.
bool _dapatDibuka(File berkas, String kunci) {
  Database? db;
  try {
    db = sqlite3.open(berkas.path);
    db.execute("PRAGMA key = '$kunci';");
    db.select('select count(*) from sqlite_master;');
    return true;
  } on Object {
    return false;
  } finally {
    db?.close();
  }
}

/// 32 bytes from the platform CSPRNG, hex encoded so it survives PRAGMA quoting
/// and can never contain a quote character of its own.
String _kunciAcak() {
  final acak = Random.secure();
  final bytes = List<int>.generate(32, (_) => acak.nextInt(256));
  return [for (final b in bytes) b.toRadixString(16).padLeft(2, '0')].join();
}
