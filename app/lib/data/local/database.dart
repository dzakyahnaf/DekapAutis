import 'dart:io';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'database.g.dart';

/// Cached copy of the shared activity catalogue.
///
/// The explicit @DataClassName is not cosmetic: Drift strips a trailing "s"
/// to singularise, which turns Aktivitas into "Aktivita" and Respons into
/// "Respon". Indonesian table names do not pluralise that way.
///
/// Needed offline because L.7 shows the steps, and a caregiver opening an
/// activity on the bus has no use for a plan that cannot tell them what to do.
@DataClassName('CacheAktivitasData')
class CacheAktivitas extends Table {
  TextColumn get id => text()();
  TextColumn get kategori => text()();
  IntColumn get tingkat => integer()();
  TextColumn get judul => text()();
  TextColumn get tujuan => text()();
  IntColumn get durasiMenit => integer()();
  TextColumn get alatJson => text()();
  TextColumn get langkahJson => text()();
  TextColumn get saranLingkungan => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Cached copy of the scheduled week.
class CacheJadwal extends Table {
  TextColumn get id => text()();
  TextColumn get rencanaId => text()();
  TextColumn get aktivitasId => text()();
  DateTimeColumn get tanggal => dateTime()();
  TextColumn get waktu => text()();
  IntColumn get urutan => integer()();
  IntColumn get durasiMenit => integer()();
  IntColumn get tingkatDisesuaikan => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Response notes, written here first and pushed later (KNF-02).
///
/// This is both the display source and the outbox: [tersinkron] false means the
/// row is still waiting. Keeping one table rather than a cache plus a separate
/// queue is what makes a response appear on screen instantly while offline
/// without the two copies ever disagreeing.
@DataClassName('CacheResponsData')
class CacheRespons extends Table {
  /// UUID minted on the device. The server column is UNIQUE, so replaying a
  /// queued write can never produce a second row - that is the whole of the
  /// idempotency guarantee, and it lives in the database rather than in
  /// carefully written client code.
  TextColumn get klienId => text()();
  TextColumn get jadwalAktivitasId => text()();
  TextColumn get nilai => text()();
  TextColumn get catatan => text().nullable()();
  DateTimeColumn get dicatatPada => dateTime()();
  BoolColumn get tersinkron => boolean().withDefault(const Constant(false))();
  IntColumn get percobaan => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {klienId};
}

/// Caregiver check-in, same outbox pattern.
class CacheCheckIn extends Table {
  TextColumn get klienId => text()();
  DateTimeColumn get tanggal => dateTime()();
  IntColumn get kondisi => integer()();
  BoolColumn get tersinkron => boolean().withDefault(const Constant(false))();
  IntColumn get percobaan => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {klienId};
}

@DriftDatabase(
  tables: [CacheAktivitas, CacheJadwal, CacheRespons, CacheCheckIn],
)
class DekapDatabase extends _$DekapDatabase {
  DekapDatabase(super.e);

  /// For tests: an in-memory database with no encryption and no file.
  DekapDatabase.memori() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 1;

  // ------------------------------------------------------------- catalogue --

  Future<void> simpanKatalog(List<CacheAktivitasCompanion> daftar) async {
    await batch((b) => b.insertAllOnConflictUpdate(cacheAktivitas, daftar));
  }

  Future<CacheAktivitasData?> aktivitas(String id) =>
      (select(cacheAktivitas)..where((t) => t.id.equals(id))).getSingleOrNull();

  // ------------------------------------------------------------- schedule --

  Future<void> simpanJadwal(List<CacheJadwalCompanion> daftar) async {
    await batch((b) => b.insertAllOnConflictUpdate(cacheJadwal, daftar));
  }

  Future<List<CacheJadwalData>> jadwalPada(DateTime tanggal) {
    final awal = DateTime(tanggal.year, tanggal.month, tanggal.day);
    return (select(cacheJadwal)
          ..where((t) => t.tanggal.equals(awal))
          ..orderBy([(t) => OrderingTerm(expression: t.urutan)]))
        .get();
  }

  Future<List<CacheJadwalData>> jadwalRentang(DateTime dari, DateTime sampai) {
    return (select(cacheJadwal)
          ..where((t) => t.tanggal.isBetweenValues(dari, sampai))
          ..orderBy([
            (t) => OrderingTerm(expression: t.tanggal),
            (t) => OrderingTerm(expression: t.urutan),
          ]))
        .get();
  }

  // -------------------------------------------------------------- outbox --

  Future<void> catatRespons(CacheResponsCompanion respons) =>
      into(cacheRespons).insertOnConflictUpdate(respons);

  Future<CacheResponsData?> responsUntuk(String jadwalId) =>
      (select(cacheRespons)
            ..where((t) => t.jadwalAktivitasId.equals(jadwalId))
            ..orderBy([
              (t) => OrderingTerm(
                expression: t.dicatatPada,
                mode: OrderingMode.desc,
              ),
            ])
            ..limit(1))
          .getSingleOrNull();

  Future<List<CacheResponsData>> responsMenunggu() =>
      (select(cacheRespons)..where((t) => t.tersinkron.equals(false))).get();

  Future<void> tandaiResponsTersinkron(String klienId) =>
      (update(cacheRespons)..where((t) => t.klienId.equals(klienId))).write(
        const CacheResponsCompanion(tersinkron: Value(true)),
      );

  Future<void> naikkanPercobaanRespons(String klienId) => customUpdate(
    'UPDATE cache_respons SET percobaan = percobaan + 1 WHERE klien_id = ?',
    variables: [Variable.withString(klienId)],
    updates: {cacheRespons},
  );

  Future<void> catatCheckIn(CacheCheckInCompanion checkIn) =>
      into(cacheCheckIn).insertOnConflictUpdate(checkIn);

  Future<CacheCheckInData?> checkInPada(DateTime tanggal) {
    final awal = DateTime(tanggal.year, tanggal.month, tanggal.day);
    return (select(
      cacheCheckIn,
    )..where((t) => t.tanggal.equals(awal))).getSingleOrNull();
  }

  Future<List<CacheCheckInData>> checkInMenunggu() =>
      (select(cacheCheckIn)..where((t) => t.tersinkron.equals(false))).get();

  Future<void> tandaiCheckInTersinkron(String klienId) =>
      (update(cacheCheckIn)..where((t) => t.klienId.equals(klienId))).write(
        const CacheCheckInCompanion(tersinkron: Value(true)),
      );

  /// Total rows still waiting, for the offline banner in the header.
  Future<int> jumlahMenunggu() async =>
      (await responsMenunggu()).length + (await checkInMenunggu()).length;

  Stream<int> pantauJumlahMenunggu() {
    final r = select(cacheRespons)..where((t) => t.tersinkron.equals(false));
    final c = select(cacheCheckIn)..where((t) => t.tersinkron.equals(false));
    return r.watch().asyncMap(
      (baris) async => baris.length + (await c.get()).length,
    );
  }

  /// Signing out must not leave one account's records readable by the next.
  Future<void> kosongkan() async {
    await batch((b) {
      b
        ..deleteAll(cacheRespons)
        ..deleteAll(cacheCheckIn)
        ..deleteAll(cacheJadwal)
        ..deleteAll(cacheAktivitas);
    });
  }
}

/// Opens the on-device database, encrypted.
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
  return List<int>.generate(
    32,
    (_) => acak.nextInt(256),
  ).map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}
