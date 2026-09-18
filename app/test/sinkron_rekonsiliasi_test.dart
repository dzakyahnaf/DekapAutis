import 'package:dekapautis/data/local/database.dart';
import 'package:dekapautis/data/repositories/rencana_repository.dart';
import 'package:dekapautis/data/repositories/sinkron_peladen.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

import 'support/fakes.dart';

/// The refresh path, measured against what the server actually sends.
///
/// Until 19 September the device cache only ever added and updated rows. Three
/// faults followed from that, all of them invisible to a fake that returned an
/// empty schedule:
///
///   * after "Susun rencana" the superseded plan's rows stayed on the phone
///     beside the new plan's, and the plan screen showed each overlapping day
///     twice
///   * a response the server no longer had stayed "recorded" on the phone for
///     good - which, once the demo account began resetting every night, meant
///     rehearsal answers would still be on the cards during the final
///   * correcting an activity the server already held under another client id
///     collided with satu_respons_per_jadwal and retried forever
void main() {
  late DekapDatabase db;
  late _Peladen peladen;
  late RencanaRepository repo;

  setUp(() {
    db = DekapDatabase.memori();
    peladen = _Peladen();
    repo = RencanaRepository(peladen, db);
  });

  tearDown(() => db.close());

  DateTime hari(int d) => DateTime(2026, 9, d);

  test(
    'Susun rencana tidak lagi menampilkan hari yang sama dua kali',
    () async {
      // Old plan A covers 14-20 September.
      peladen.jadwal = [
        for (var d = 14; d <= 20; d++) _baris('a$d', 'A', hari(d)),
      ];
      await repo.segarkan('anak');

      // Regenerated plan B starts on the 17th and supersedes A on the server.
      peladen.jadwal = [
        for (var d = 17; d <= 23; d++) _baris('b$d', 'B', hari(d)),
      ];
      await repo.segarkan('anak');

      final hariKe18 = await db.jadwalPada(hari(18));
      expect(hariKe18.map((j) => j.id), [
        'b18',
      ], reason: 'A tidak boleh tersisa');

      // Before the new plan's window it is history, and history stays.
      final hariKe15 = await db.jadwalPada(hari(15));
      expect(hariKe15.map((j) => j.id), ['a15']);
    },
  );

  test('jawaban kosong dari peladen tidak mengosongkan cache', () async {
    peladen.jadwal = [_baris('a19', 'A', hari(19))];
    await repo.segarkan('anak');

    // "No rows" is not a trustworthy reason to wipe an offline-first cache.
    peladen.jadwal = [];
    await repo.segarkan('anak');

    expect(await db.jadwalPada(hari(19)), hasLength(1));
  });

  test(
    'catatan yang menunggu untuk aktivitas yang hilang ikut dibuang',
    () async {
      peladen.jadwal = [_baris('a18', 'A', hari(18))];
      await repo.segarkan('anak');
      await _catatLokal(db, 'k1', 'a18', 'pas', tersinkron: false);

      peladen.jadwal = [_baris('b18', 'B', hari(18))];
      await repo.segarkan('anak');

      // Its foreign key is gone; it could never be accepted, and would sit in
      // the offline banner for good.
      expect(await db.responsMenunggu(), isEmpty);
    },
  );

  test('respons yang dihapus peladen tidak lagi tampil tercatat', () async {
    peladen.jadwal = [_baris('j1', 'A', hari(19), respons: _tanpa)];
    await repo.segarkan('anak');
    await _catatLokal(db, 'k1', 'j1', 'pas', tersinkron: true);

    // The nightly demo reset removed it on the server.
    peladen.jadwal = [_baris('j1', 'A', hari(19), respons: null)];
    await repo.segarkan('anak');

    expect(await db.responsUntuk('j1'), isNull);
  });

  test('respons dari perangkat lain ikut tampil', () async {
    peladen.jadwal = [
      _baris('j1', 'A', hari(19), respons: _respons('lain', 'mudah')),
    ];
    await repo.segarkan('anak');

    final r = await db.responsUntuk('j1');
    expect(r?.nilai, 'mudah');
    expect(r?.klienId, 'lain');
    expect(
      r?.tersinkron,
      isTrue,
      reason: 'sudah ada di peladen, bukan antrean',
    );
  });

  test('catatan antre memakai klien_id peladen agar tidak bentrok', () async {
    peladen.jadwal = [_baris('j1', 'A', hari(19), respons: _tanpa)];
    await repo.segarkan('anak');
    await _catatLokal(db, 'lokal', 'j1', 'sulit', tersinkron: false);

    // The server already holds this activity under the seed's client id.
    peladen.jadwal = [
      _baris('j1', 'A', hari(19), respons: _respons('seed', 'mudah')),
    ];
    await repo.segarkan('anak');

    final r = await db.responsUntuk('j1');
    expect(r?.klienId, 'seed', reason: 'upsert on klien_id then updates it');
    expect(r?.nilai, 'sulit', reason: 'the note written last wins');
    expect(r?.tersinkron, isFalse, reason: 'still has to reach the server');
  });

  test('catatan antre tanpa pasangan di peladen dibiarkan', () async {
    peladen.jadwal = [_baris('j1', 'A', hari(19), respons: null)];
    await repo.segarkan('anak');
    await _catatLokal(db, 'lokal', 'j1', 'pas', tersinkron: false);

    await repo.segarkan('anak');

    expect((await db.responsUntuk('j1'))?.klienId, 'lokal');
  });

  test('baris tanpa kunci catatan_respons tidak menyentuh catatan', () async {
    peladen.jadwal = [_baris('j1', 'A', hari(19), respons: _tanpa)];
    await repo.segarkan('anak');
    await _catatLokal(db, 'k1', 'j1', 'pas', tersinkron: true);

    await repo.segarkan('anak');

    // Missing means "not asked", which is not the same as "no answer".
    expect((await db.responsUntuk('j1'))?.klienId, 'k1');
  });

  test('bentuk larik dari peladen juga diterima', () async {
    peladen.jadwal = [
      _baris('j1', 'A', hari(19), respons: [_respons('lain', 'pas')]),
    ];
    await repo.segarkan('anak');

    expect((await db.responsUntuk('j1'))?.nilai, 'pas');
  });

  testWidgets('keluar akun membersihkan data di perangkat', (tester) async {
    final basis = DekapDatabase.memori();
    addTearDown(basis.close);
    await basis.simpanJadwal([_cache('j1', hari(19))]);
    await _catatLokal(basis, 'k1', 'j1', 'pas', tersinkron: false);

    final auth = FakeAuthRepository(masuk_: true, denganAliranStatus: true);
    addTearDown(auth.tutupStatus);
    await tester.pumpWidget(aplikasiUji(auth: auth, db: basis));
    await tester.pump();

    auth.pancarkanKeluar();
    await tester.pumpAndSettle();

    // The next account on this phone must not see Bima's plan or notes.
    expect(await basis.jadwalPada(hari(19)), isEmpty);
    expect(await basis.responsMenunggu(), isEmpty);
  });
}

// ------------------------------------------------------------------ helpers --

/// Marks a row as "the key is absent", which is different from a null value.
const _tanpa = Object();

Map<String, dynamic> _baris(
  String id,
  String rencana,
  DateTime tanggal, {
  Object? respons = _tanpa,
}) => {
  'id': id,
  'rencana_id': rencana,
  'aktivitas_id': 'akt',
  'tanggal':
      '${tanggal.year}-'
      '${tanggal.month.toString().padLeft(2, '0')}-'
      '${tanggal.day.toString().padLeft(2, '0')}',
  'waktu': '08:30:00',
  'urutan': 1,
  'durasi_menit': 10,
  'tingkat_disesuaikan': 2,
  if (!identical(respons, _tanpa)) 'catatan_respons': respons,
};

Map<String, dynamic> _respons(String klien, String nilai) => {
  'klien_id': klien,
  'nilai': nilai,
  'catatan': null,
  'dicatat_pada': '2026-09-19T01:30:00+00:00',
};

CacheJadwalCompanion _cache(String id, DateTime tanggal) =>
    CacheJadwalCompanion.insert(
      id: id,
      rencanaId: 'A',
      aktivitasId: 'akt',
      tanggal: tanggal,
      waktu: '08:30:00',
      urutan: 1,
      durasiMenit: 10,
      tingkatDisesuaikan: 2,
    );

Future<void> _catatLokal(
  DekapDatabase db,
  String klien,
  String jadwal,
  String nilai, {
  required bool tersinkron,
}) => db.catatRespons(
  CacheResponsCompanion.insert(
    klienId: klien,
    jadwalAktivitasId: jadwal,
    nilai: nilai,
    dicatatPada: DateTime(2026, 9, 19, 9),
    tersinkron: Value(tersinkron),
  ),
);

class _Peladen implements SinkronPeladen {
  List<Map<String, dynamic>> jadwal = [];

  @override
  String? get penggunaId => 'pengguna-uji';

  @override
  Future<List<Map<String, dynamic>>> ambilKatalog() async => const [];

  @override
  Future<List<Map<String, dynamic>>> ambilJadwal(String profilAnakId) async =>
      jadwal;

  @override
  Future<void> kirimRespons(Map<String, dynamic> baris) async {}

  @override
  Future<void> kirimCheckIn(Map<String, dynamic> baris) async {}

  @override
  Future<Map<String, dynamic>> mintaRencana(String profilAnakId) async =>
      const {'alasan': ''};
}
