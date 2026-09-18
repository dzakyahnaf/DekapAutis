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

/// A response as the server holds it, pulled during a refresh.
typedef ResponsPeladen = ({
  String klienId,
  String nilai,
  String? catatan,
  DateTime dicatatPada,
});

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

  /// Drops cached schedule rows the server no longer has, inside the window
  /// the server just answered for.
  ///
  /// The cache upserts by id and never deleted anything, so a superseded plan's
  /// rows stayed on the device beside its replacement: after "Susun rencana"
  /// the plan screen showed every overlapping day twice. [idAktif] is every
  /// row of every active plan the server returned; [sejak] is the earliest date
  /// among them. Rows older than that are history and are kept.
  ///
  /// Does nothing when [idAktif] is empty. An empty answer can mean "no active
  /// plan", but wiping the cache on anything less than a positive answer would
  /// break the offline guarantee the whole cache exists for.
  Future<void> pangkasJadwal(Set<String> idAktif, DateTime sejak) async {
    if (idAktif.isEmpty) return;
    final awal = DateTime(sejak.year, sejak.month, sejak.day);
    await transaction(() async {
      final basi =
          await (select(cacheJadwal)..where(
                (t) =>
                    t.id.isNotIn(idAktif) &
                    t.tanggal.isBiggerOrEqualValue(awal),
              ))
              .get();
      if (basi.isEmpty) return;
      final idBasi = [for (final j in basi) j.id];
      // A note still queued for an activity that no longer exists can never be
      // accepted - its foreign key is gone - and would sit in the offline
      // banner for good.
      await (delete(
        cacheRespons,
      )..where((t) => t.jadwalAktivitasId.isIn(idBasi))).go();
      await (delete(cacheJadwal)..where((t) => t.id.isIn(idBasi))).go();
    });
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

  /// Brings notes already synced in line with the server, and leaves notes
  /// still queued on this device alone.
  ///
  /// [peladen] maps each activity the server returned to its response, or to
  /// null when it has none. Activities missing from the map are not touched:
  /// missing means "not asked", which is different from "no answer".
  ///
  /// Until this existed the app never read responses back, so it could not
  /// see a response recorded on another device, a reset of the demo account
  /// left rehearsal answers on the phone for good, and correcting an activity
  /// the server already held under another client id collided with
  /// satu_respons_per_jadwal and retried forever.
  Future<void> selaraskanRespons(Map<String, ResponsPeladen?> peladen) async {
    if (peladen.isEmpty) return;
    await transaction(() async {
      final lokal = await (select(
        cacheRespons,
      )..where((t) => t.jadwalAktivitasId.isIn(peladen.keys))).get();

      final antre = <String, CacheResponsData>{};
      for (final r in lokal) {
        if (!r.tersinkron) {
          antre[r.jadwalAktivitasId] = r;
          continue;
        }
        // Synced here, but gone from the server or replaced there. The server
        // is the record.
        final s = peladen[r.jadwalAktivitasId];
        if (s == null || s.klienId != r.klienId) {
          await (delete(
            cacheRespons,
          )..where((t) => t.klienId.equals(r.klienId))).go();
        }
      }

      for (final MapEntry(key: jadwalId, value: s) in peladen.entries) {
        final tertunda = antre[jadwalId];
        if (tertunda != null) {
          // The queued note wins: the caregiver wrote it last. If the server
          // already holds this activity under another client id, adopt that id
          // so the push updates the row instead of colliding with it.
          if (s != null && s.klienId != tertunda.klienId) {
            await (delete(
              cacheRespons,
            )..where((t) => t.jadwalAktivitasId.equals(jadwalId))).go();
            await into(cacheRespons).insert(
              CacheResponsCompanion.insert(
                klienId: s.klienId,
                jadwalAktivitasId: jadwalId,
                nilai: tertunda.nilai,
                catatan: Value(tertunda.catatan),
                dicatatPada: tertunda.dicatatPada,
                tersinkron: const Value(false),
                percobaan: const Value(0),
              ),
            );
          }
          continue;
        }
        if (s == null) continue;
        await into(cacheRespons).insertOnConflictUpdate(
          CacheResponsCompanion.insert(
            klienId: s.klienId,
            jadwalAktivitasId: jadwalId,
            nilai: s.nilai,
            catatan: Value(s.catatan),
            dicatatPada: s.dicatatPada,
            tersinkron: const Value(true),
            percobaan: const Value(0),
          ),
        );
      }
    });
  }

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
