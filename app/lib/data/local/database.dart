import 'package:drift/drift.dart';

import 'koneksi/koneksi.dart';

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

/// Small key-value store for things that belong to this installation rather
/// than to the account: whether the first-run tour has been seen, and whatever
/// else of that shape comes later.
///
/// Not `flutter_secure_storage`: that is for the session token and the database
/// key, and putting a boolean beside them makes the important entries harder to
/// find. Not the server either - a caregiver who reinstalls has good reason to
/// see the tour again.
class Preferensi extends Table {
  TextColumn get kunci => text()();
  TextColumn get nilai => text()();

  @override
  Set<Column> get primaryKey => {kunci};
}

@DriftDatabase(
  tables: [CacheAktivitas, CacheJadwal, CacheRespons, CacheCheckIn, Preferensi],
)
class DekapDatabase extends _$DekapDatabase {
  DekapDatabase(super.e);

  /// For tests: an in-memory database with no encryption and no file.
  DekapDatabase.memori() : super(bukaDatabaseMemori());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, dari, ke) async {
      // v2 added `preferensi`. The cache tables are untouched: they hold a copy
      // of server data and the queue, and dropping them on upgrade would throw
      // away writes a caregiver made offline.
      if (dari < 2) await m.createTable(preferensi);
    },
  );

  // ---------------------------------------------------------- preferences --

  Future<String?> bacaPreferensi(String kunci) async {
    final baris = await (select(
      preferensi,
    )..where((p) => p.kunci.equals(kunci))).getSingleOrNull();
    return baris?.nilai;
  }

  Future<void> simpanPreferensi(String kunci, String nilai) =>
      into(preferensi).insertOnConflictUpdate(
        PreferensiCompanion.insert(kunci: kunci, nilai: nilai),
      );

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
