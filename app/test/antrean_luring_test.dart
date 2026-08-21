import 'package:dekapautis/data/local/database.dart';
import 'package:dekapautis/data/models/response_level.dart';
import 'package:dekapautis/data/repositories/rencana_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fakes.dart';

/// The offline write queue (KNF-02).
///
/// docs/06 §3 states the acceptance test in plain words: turn off the network,
/// record five responses, close and reopen the app, turn the network back on,
/// and find exactly five rows on the server. Not four, not ten. Everything here
/// is that sentence, made executable.
///
/// The four-not-ten half is the one that bites. Four means a note was lost, and
/// a caregiver only finds out weeks later when the report is wrong. Ten means
/// the adaptation engine sees the same day twice and moves a level on evidence
/// that never happened.

void main() {
  late DekapDatabase db;
  late PeladenPalsu peladen;
  late RencanaRepository repo;

  setUp(() {
    db = DekapDatabase.memori();
    peladen = PeladenPalsu();
    repo = RencanaRepository(peladen, db);
  });

  tearDown(() => db.close());

  Future<void> catatLima() async {
    for (var i = 1; i <= 5; i++) {
      await repo.catatRespons(
        jadwalAktivitasId: 'jadwal-$i',
        nilai: ResponseLevel.values[i % 3],
        catatan: 'Catatan $i',
      );
    }
  }

  group('the acceptance test from docs/06', () {
    test('five offline notes become exactly five rows once online', () async {
      peladen.daring = false;
      await catatLima();

      expect(
        peladen.respons,
        isEmpty,
        reason: 'terkirim padahal sedang luring',
      );
      expect(await repo.jumlahMenunggu(), 5);

      peladen.daring = true;
      final terkirim = await repo.kurasAntrean();

      expect(terkirim, 5);
      expect(peladen.respons.length, 5, reason: 'bukan tepat 5 baris');
      expect(await repo.jumlahMenunggu(), 0);
    });

    test('the notes survive the app being closed and reopened', () async {
      peladen.daring = false;
      await catatLima();

      // Reopening the app is a new repository over the same database file.
      final repoBaru = RencanaRepository(peladen, db);
      expect(await repoBaru.jumlahMenunggu(), 5);

      peladen.daring = true;
      await repoBaru.kurasAntrean();
      expect(peladen.respons.length, 5);
    });

    test('draining twice still leaves five rows, not ten', () async {
      peladen.daring = false;
      await catatLima();
      peladen.daring = true;

      await repo.kurasAntrean();
      await repo.kurasAntrean();
      await repo.kurasAntrean();

      expect(
        peladen.respons.length,
        5,
        reason: 'sinkronisasi ganda menggandakan baris',
      );
    });

    test(
      'a replayed row keeps its client id, which is what makes it safe',
      () async {
        peladen.daring = false;
        await repo.catatRespons(
          jadwalAktivitasId: 'jadwal-1',
          nilai: ResponseLevel.mudah,
        );
        peladen.daring = true;
        await repo.kurasAntrean();

        final klienId = peladen.respons.keys.single;

        // Force the same row back into the queue and send it again.
        await db.customUpdate(
          'UPDATE cache_respons SET tersinkron = 0',
          updates: {db.cacheRespons},
        );
        await repo.kurasAntrean();

        expect(peladen.respons.length, 1);
        expect(peladen.respons.keys.single, klienId);
      },
    );
  });

  group('recording while offline', () {
    test('a note is readable immediately, before it has been sent', () async {
      peladen.daring = false;
      await repo.catatRespons(
        jadwalAktivitasId: 'jadwal-1',
        nilai: ResponseLevel.sulit,
        catatan: 'Suara di luar ramai',
      );

      final tersimpan = await db.responsUntuk('jadwal-1');
      expect(tersimpan, isNotNull);
      expect(tersimpan!.nilai, 'sulit');
      expect(tersimpan.catatan, 'Suara di luar ramai');
      expect(tersimpan.tersinkron, isFalse);
    });

    test('recording offline does not throw at the caller', () async {
      peladen.daring = false;
      // The note is saved and queued. Surfacing a failure here would teach the
      // caregiver that recording offline does not work, which is untrue.
      await expectLater(
        repo.catatRespons(
          jadwalAktivitasId: 'jadwal-1',
          nilai: ResponseLevel.pas,
        ),
        completes,
      );
    });

    test(
      'correcting a note updates the same row rather than adding one',
      () async {
        peladen.daring = true;
        await repo.catatRespons(
          jadwalAktivitasId: 'jadwal-1',
          nilai: ResponseLevel.mudah,
        );
        await repo.catatRespons(
          jadwalAktivitasId: 'jadwal-1',
          nilai: ResponseLevel.sulit,
          catatan: 'Ternyata berat',
        );

        expect(
          peladen.respons.length,
          1,
          reason: 'satu aktivitas punya dua baris',
        );
        expect(peladen.respons.values.single['nilai'], 'sulit');
        expect(peladen.respons.values.single['catatan'], 'Ternyata berat');
      },
    );

    test('a failed send is retried, and the attempt is counted', () async {
      peladen.daring = false;
      await repo.catatRespons(
        jadwalAktivitasId: 'jadwal-1',
        nilai: ResponseLevel.mudah,
      );
      await repo.kurasAntrean();
      await repo.kurasAntrean();

      final baris = await db.responsUntuk('jadwal-1');
      expect(baris!.percobaan, greaterThanOrEqualTo(2));
      expect(baris.tersinkron, isFalse);
    });
  });

  group('caregiver check-in queues the same way', () {
    test('an offline check-in is kept and sent later', () async {
      peladen.daring = false;
      await repo.catatCheckIn(2);

      expect(await repo.checkInHariIni(), 2);
      expect(peladen.checkIn, isEmpty);
      expect(await repo.jumlahMenunggu(), 1);

      peladen.daring = true;
      await repo.kurasAntrean();
      expect(peladen.checkIn.length, 1);
      expect(await repo.jumlahMenunggu(), 0);
    });

    test('changing the answer twice in one day still sends one row', () async {
      peladen.daring = false;
      await repo.catatCheckIn(2);
      await repo.catatCheckIn(4);
      peladen.daring = true;
      await repo.kurasAntrean();

      expect(peladen.checkIn.length, 1);
      expect(peladen.checkIn.values.single['kondisi'], 4);
      expect(await repo.checkInHariIni(), 4);
    });
  });

  group('the pending counter drives the offline banner', () {
    test('it counts responses and check-ins together', () async {
      peladen.daring = false;
      await repo.catatRespons(
        jadwalAktivitasId: 'jadwal-1',
        nilai: ResponseLevel.mudah,
      );
      await repo.catatCheckIn(3);

      expect(await repo.jumlahMenunggu(), 2);
    });

    test('it returns to zero once everything has gone through', () async {
      peladen.daring = false;
      await catatLima();
      await repo.catatCheckIn(3);
      expect(await repo.jumlahMenunggu(), 6);

      peladen.daring = true;
      await repo.kurasAntrean();
      expect(await repo.jumlahMenunggu(), 0);
    });
  });

  group('signing out', () {
    test('clears the local copy so the next account cannot read it', () async {
      peladen.daring = false;
      await catatLima();
      await repo.catatCheckIn(3);

      await db.kosongkan();

      expect(await repo.jumlahMenunggu(), 0);
      expect(await db.responsUntuk('jadwal-1'), isNull);
    });
  });
}
