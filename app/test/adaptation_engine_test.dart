import 'package:dekapautis/domain/adaptasi/adaptation_engine.dart';
import 'package:dekapautis/domain/adaptasi/kategori.dart';
import 'package:test/test.dart';

/// The adaptation engine (KF-06), the second AI pillar.
///
/// `package:test`, not `flutter_test`: the engine is pure Dart with no widget,
/// no network and no database, and this file stops compiling the moment that
/// stops being true.
///
/// This is the most important test file in the repository. The engine is the
/// part most able to be quietly wrong: a rule that fires one week early moves a
/// child to a harder activity on evidence that was not there, and nothing about
/// the screen would look broken.
void main() {
  // Monday. Periods are calendar weeks, Monday to Sunday (KEPUTUSAN.md 18).
  final minggu3 = DateTime(2026, 8, 24);
  final minggu2 = minggu3.subtract(const Duration(days: 7));
  final minggu1 = minggu3.subtract(const Duration(days: 14));

  CatatanUntukAdaptasi c(
    NilaiRespons nilai, {
    Kategori kategori = Kategori.komunikasi,
    DateTime? minggu,
    int hariKe = 0,
    int jam = 8,
  }) => CatatanUntukAdaptasi(
    kategori: kategori,
    nilai: nilai,
    dicatatPada: (minggu ?? minggu3).add(Duration(days: hariKe, hours: jam)),
    jamJadwal: jam,
  );

  MasukanAdaptasi masukan({
    List<CatatanUntukAdaptasi> catatan = const [],
    Map<Kategori, int>? tingkat,
    Map<Kategori, int>? durasi,
    Map<Kategori, int>? porsi,
    Map<Kategori, String>? saran,
    Set<Kategori> dikoreksiManual = const {},
  }) => MasukanAdaptasi(
    catatan: catatan,
    tingkat: tingkat ?? {for (final k in Kategori.values) k: 2},
    durasi: durasi ?? {for (final k in Kategori.values) k: 12},
    porsi: porsi ?? {for (final k in Kategori.values) k: 2},
    saranLingkungan:
        saran ?? {Kategori.komunikasi: 'Matikan televisi saat aktivitas.'},
    dikoreksiManual: dikoreksiManual,
    periodeSekarang: minggu3,
  );

  HasilAdaptasi jalankan(MasukanAdaptasi m) => const AdaptationEngine().jalankan(m);

  BarisAdaptasiLog? logUntuk(HasilAdaptasi h, String aturan, Kategori k) =>
      h.log.where((l) => l.aturanId == aturan && l.kategori == k).firstOrNull;

  // =========================================================== rule A ==

  group('A_naik - the level goes up', () {
    test('fires on two of the last three easy, with no hard', () {
      final hasil = jalankan(
        masukan(
          catatan: [
            c(NilaiRespons.mudah, hariKe: 0),
            c(NilaiRespons.pas, hariKe: 1),
            c(NilaiRespons.mudah, hariKe: 2),
          ],
        ),
      );

      expect(hasil.tingkat[Kategori.komunikasi], 3);
      final log = logUntuk(hasil, 'A_naik', Kategori.komunikasi);
      expect(log, isNotNull);
      expect(log!.nilaiSebelum['tingkat'], 2);
      expect(log.nilaiSesudah['tingkat'], 3);
    });

    test('does not fire when a hard note is among the last three', () {
      final hasil = jalankan(
        masukan(
          catatan: [
            c(NilaiRespons.mudah, hariKe: 0),
            c(NilaiRespons.mudah, hariKe: 1),
            c(NilaiRespons.sulit, hariKe: 2),
          ],
        ),
      );
      expect(hasil.tingkat[Kategori.komunikasi], 2);
      expect(logUntuk(hasil, 'A_naik', Kategori.komunikasi), isNull);
    });

    test('does not fire on only one easy note out of three', () {
      final hasil = jalankan(
        masukan(
          catatan: [
            c(NilaiRespons.mudah, hariKe: 0),
            c(NilaiRespons.pas, hariKe: 1),
            c(NilaiRespons.pas, hariKe: 2),
          ],
        ),
      );
      expect(hasil.tingkat[Kategori.komunikasi], 2);
    });

    test('the reason names the category and the real counts', () {
      final hasil = jalankan(
        masukan(
          catatan: [
            c(NilaiRespons.mudah, hariKe: 0),
            c(NilaiRespons.pas, hariKe: 1),
            c(NilaiRespons.mudah, hariKe: 2),
          ],
        ),
      );
      final alasan = logUntuk(hasil, 'A_naik', Kategori.komunikasi)!.alasan;

      expect(alasan, contains('Komunikasi'));
      expect(alasan, contains('2 dari 3'));
      expect(alasan, contains('Mudah'));
      // From 2 to 3, said out loud rather than left for the caregiver to guess.
      expect(alasan, contains('2'));
      expect(alasan, contains('3'));
      expect(alasan, isNot(contains('sistem menyesuaikan')));
    });

    test('each category moves on its own evidence', () {
      final hasil = jalankan(
        masukan(
          catatan: [
            for (var i = 0; i < 3; i++)
              c(NilaiRespons.mudah, hariKe: i, kategori: Kategori.motorik),
            for (var i = 0; i < 3; i++)
              c(NilaiRespons.pas, hariKe: i, kategori: Kategori.sosial),
          ],
        ),
      );
      expect(hasil.tingkat[Kategori.motorik], 3);
      expect(hasil.tingkat[Kategori.sosial], 2);
      expect(hasil.tingkat[Kategori.komunikasi], 2);
    });
  });

  // =========================================================== rule B ==

  group('B_turun - the level comes down and the session shortens', () {
    test('fires on two of the last three hard', () {
      final hasil = jalankan(
        masukan(
          catatan: [
            c(NilaiRespons.sulit, hariKe: 0),
            c(NilaiRespons.pas, hariKe: 1),
            c(NilaiRespons.sulit, hariKe: 2),
          ],
          tingkat: {Kategori.komunikasi: 3},
          durasi: {Kategori.komunikasi: 16},
        ),
      );

      expect(hasil.tingkat[Kategori.komunikasi], 2);
      // 16 minus 25 percent is 12.
      expect(hasil.durasi[Kategori.komunikasi], 12);
    });

    test('it attaches the environment suggestion from the activity', () {
      final hasil = jalankan(
        masukan(
          catatan: [
            c(NilaiRespons.sulit, hariKe: 0),
            c(NilaiRespons.sulit, hariKe: 1),
            c(NilaiRespons.pas, hariKe: 2),
          ],
          saran: {Kategori.komunikasi: 'Matikan televisi saat aktivitas.'},
        ),
      );
      final log = logUntuk(hasil, 'B_turun', Kategori.komunikasi)!;
      expect(log.alasan, contains('Matikan televisi'));
      expect(hasil.saranDitampilkan[Kategori.komunikasi],
          'Matikan televisi saat aktivitas.');
    });

    test('the reason names the real minutes, before and after', () {
      final hasil = jalankan(
        masukan(
          catatan: [
            c(NilaiRespons.sulit, hariKe: 0),
            c(NilaiRespons.sulit, hariKe: 1),
            c(NilaiRespons.pas, hariKe: 2),
          ],
          tingkat: {Kategori.komunikasi: 3},
          durasi: {Kategori.komunikasi: 16},
        ),
      );
      final alasan = logUntuk(hasil, 'B_turun', Kategori.komunikasi)!.alasan;
      expect(alasan, contains('16'));
      expect(alasan, contains('12'));
      expect(alasan, contains('menit'));
      expect(alasan, contains('2 dari 3'));
    });

    test('A and B cannot both fire for one category', () {
      final hasil = jalankan(
        masukan(
          catatan: [
            c(NilaiRespons.sulit, hariKe: 0),
            c(NilaiRespons.sulit, hariKe: 1),
            c(NilaiRespons.mudah, hariKe: 2),
          ],
        ),
      );
      expect(logUntuk(hasil, 'A_naik', Kategori.komunikasi), isNull);
      expect(logUntuk(hasil, 'B_turun', Kategori.komunikasi), isNotNull);
    });
  });

  // =========================================================== rule C ==

  group('C_porsi - the weekly share grows', () {
    List<CatatanUntukAdaptasi> mingguPenuh(
      DateTime minggu,
      NilaiRespons nilai, {
      int jumlah = 4,
      Kategori kategori = Kategori.komunikasi,
    }) => [
      for (var i = 0; i < jumlah; i++)
        c(nilai, kategori: kategori, minggu: minggu, hariKe: i),
    ];

    test('fires when the readiness score rose since last week', () {
      final hasil = jalankan(
        masukan(
          catatan: [
            ...mingguPenuh(minggu2, NilaiRespons.sulit),
            ...mingguPenuh(minggu3, NilaiRespons.mudah),
          ],
          porsi: {Kategori.komunikasi: 2},
        ),
      );
      expect(hasil.porsi[Kategori.komunikasi], 3);
      expect(logUntuk(hasil, 'C_porsi', Kategori.komunikasi), isNotNull);
    });

    test('does not fire when the score fell or held', () {
      final turun = jalankan(
        masukan(
          catatan: [
            ...mingguPenuh(minggu2, NilaiRespons.mudah),
            ...mingguPenuh(minggu3, NilaiRespons.sulit),
          ],
        ),
      );
      expect(turun.porsi[Kategori.komunikasi], 2);

      final datar = jalankan(
        masukan(
          catatan: [
            ...mingguPenuh(minggu2, NilaiRespons.pas),
            ...mingguPenuh(minggu3, NilaiRespons.pas),
          ],
        ),
      );
      expect(datar.porsi[Kategori.komunikasi], 2);
    });

    test('stops at the weekly ceiling of seven', () {
      final hasil = jalankan(
        masukan(
          catatan: [
            ...mingguPenuh(minggu2, NilaiRespons.sulit),
            ...mingguPenuh(minggu3, NilaiRespons.mudah),
          ],
          porsi: {Kategori.komunikasi: 7},
        ),
      );
      expect(hasil.porsi[Kategori.komunikasi], 7);
      expect(logUntuk(hasil, 'C_porsi', Kategori.komunikasi), isNull);
    });

    test('the total stays inside five sessions a day', () {
      // Every category rising at once must not produce a week nobody could run.
      final catatan = <CatatanUntukAdaptasi>[];
      for (final k in Kategori.values) {
        catatan
          ..addAll(mingguPenuh(minggu2, NilaiRespons.sulit, kategori: k))
          ..addAll(mingguPenuh(minggu3, NilaiRespons.mudah, kategori: k));
      }
      final hasil = jalankan(
        masukan(
          catatan: catatan,
          porsi: {for (final k in Kategori.values) k: 6},
        ),
      );
      final total = hasil.porsi.values.reduce((a, b) => a + b);
      expect(total, lessThanOrEqualTo(5 * 7));
    });

    test('the reason names both scores and both session counts', () {
      final hasil = jalankan(
        masukan(
          catatan: [
            ...mingguPenuh(minggu2, NilaiRespons.sulit),
            ...mingguPenuh(minggu3, NilaiRespons.mudah),
          ],
          porsi: {Kategori.komunikasi: 2},
        ),
      );
      final alasan = logUntuk(hasil, 'C_porsi', Kategori.komunikasi)!.alasan;
      expect(alasan, contains('2'));
      expect(alasan, contains('3'));
      expect(alasan, contains('sesi'));
      expect(alasan, contains('Komunikasi'));
    });
  });

  // =========================================================== rule D ==

  group('D_tandai - two periods of decline get flagged', () {
    List<CatatanUntukAdaptasi> minggu(
      DateTime awal,
      int mudah,
      int sulit, {
      Kategori kategori = Kategori.sosial,
    }) => [
      for (var i = 0; i < mudah; i++)
        c(NilaiRespons.mudah, kategori: kategori, minggu: awal, hariKe: i),
      for (var i = 0; i < sulit; i++)
        c(NilaiRespons.sulit, kategori: kategori, minggu: awal, hariKe: i),
    ];

    test('fires after two consecutive declines', () {
      // 75 percent easy, then 50, then 25.
      final hasil = jalankan(
        masukan(
          catatan: [
            ...minggu(minggu1, 3, 1),
            ...minggu(minggu2, 2, 2),
            ...minggu(minggu3, 1, 3),
          ],
        ),
      );
      expect(hasil.penandaPerhatian, contains(Kategori.sosial));
      expect(logUntuk(hasil, 'D_tandai', Kategori.sosial), isNotNull);
    });

    test('one decline is not enough', () {
      final hasil = jalankan(
        masukan(
          catatan: [
            ...minggu(minggu1, 1, 3),
            ...minggu(minggu2, 3, 1),
            ...minggu(minggu3, 2, 2),
          ],
        ),
      );
      expect(hasil.penandaPerhatian, isNot(contains(Kategori.sosial)));
    });

    test('the flag goes to the report, never to the caregiver as a warning', () {
      final hasil = jalankan(
        masukan(
          catatan: [
            ...minggu(minggu1, 3, 1),
            ...minggu(minggu2, 2, 2),
            ...minggu(minggu3, 1, 3),
          ],
        ),
      );
      final log = logUntuk(hasil, 'D_tandai', Kategori.sosial)!;
      expect(log.tampilkanKePengasuh, isFalse);
      // Nothing that reads as a verdict on the child.
      for (final kata in ['gagal', 'menurun drastis', 'buruk', 'khawatir']) {
        expect(log.alasan.toLowerCase(), isNot(contains(kata)));
      }
    });

    test('the reason names the three real percentages', () {
      final hasil = jalankan(
        masukan(
          catatan: [
            ...minggu(minggu1, 3, 1),
            ...minggu(minggu2, 2, 2),
            ...minggu(minggu3, 1, 3),
          ],
        ),
      );
      final alasan = logUntuk(hasil, 'D_tandai', Kategori.sosial)!.alasan;
      expect(alasan, contains('75'));
      expect(alasan, contains('50'));
      expect(alasan, contains('25'));
      expect(alasan, contains('%'));
    });
  });

  // =========================================================== rule E ==

  group('E_jadwal - move to the hour that works', () {
    test('picks the block with the best easy ratio', () {
      final hasil = jalankan(
        masukan(
          catatan: [
            for (var i = 0; i < 4; i++)
              c(NilaiRespons.mudah, hariKe: i, jam: 8),
            for (var i = 0; i < 4; i++)
              c(NilaiRespons.sulit, hariKe: i, jam: 16),
          ],
        ),
      );
      expect(hasil.blokJam[Kategori.komunikasi], 8);
      expect(logUntuk(hasil, 'E_jadwal', Kategori.komunikasi), isNotNull);
    });

    test('needs at least three samples in a block before trusting it', () {
      final hasil = jalankan(
        masukan(
          catatan: [
            // One perfect hour, but only twice. Not evidence yet.
            c(NilaiRespons.mudah, hariKe: 0, jam: 6),
            c(NilaiRespons.mudah, hariKe: 1, jam: 6),
            c(NilaiRespons.pas, hariKe: 2, jam: 10),
            c(NilaiRespons.pas, hariKe: 3, jam: 10),
            c(NilaiRespons.pas, hariKe: 4, jam: 10),
          ],
        ),
      );
      expect(hasil.blokJam[Kategori.komunikasi], isNot(6));
    });

    test('keeps the current hour when nothing stands out', () {
      final hasil = jalankan(
        masukan(
          catatan: [
            for (var i = 0; i < 3; i++) c(NilaiRespons.pas, hariKe: i, jam: 8),
            for (var i = 0; i < 3; i++) c(NilaiRespons.pas, hariKe: i, jam: 16),
          ],
        ),
      );
      expect(logUntuk(hasil, 'E_jadwal', Kategori.komunikasi), isNull);
    });

    test('the reason names the hour and the counts behind it', () {
      final hasil = jalankan(
        masukan(
          catatan: [
            for (var i = 0; i < 5; i++)
              c(NilaiRespons.mudah, hariKe: i, jam: 8),
            c(NilaiRespons.pas, hariKe: 5, jam: 8),
            for (var i = 0; i < 4; i++)
              c(NilaiRespons.sulit, hariKe: i, jam: 16),
          ],
        ),
      );
      final alasan = logUntuk(hasil, 'E_jadwal', Kategori.komunikasi)!.alasan;
      expect(alasan, contains('08.00'));
      expect(alasan, contains('5 dari 6'));
      expect(alasan, contains('Mudah'));
    });
  });

  // ================================================= the seven edge cases ==

  group('the seven edge cases from docs/04', () {
    test('1. no notes at all: nothing runs, nothing is logged', () {
      final hasil = jalankan(masukan());
      expect(hasil.log, isEmpty);
      expect(hasil.tingkat, masukan().tingkat);
      expect(hasil.durasi, masukan().durasi);
      expect(hasil.porsi, masukan().porsi);
      expect(hasil.penandaPerhatian, isEmpty);
    });

    test('2. exactly three notes: A and B may run, C may not', () {
      final hasil = jalankan(
        masukan(
          catatan: [
            c(NilaiRespons.mudah, hariKe: 0),
            c(NilaiRespons.mudah, hariKe: 1),
            c(NilaiRespons.pas, hariKe: 2),
          ],
        ),
      );
      expect(logUntuk(hasil, 'A_naik', Kategori.komunikasi), isNotNull);
      expect(logUntuk(hasil, 'C_porsi', Kategori.komunikasi), isNull,
          reason: 'C butuh dua periode, tidak boleh jalan dari satu minggu');
    });

    test('3. already at level 4 and A fires: stays 4, and nothing is logged', () {
      final hasil = jalankan(
        masukan(
          catatan: [
            c(NilaiRespons.mudah, hariKe: 0),
            c(NilaiRespons.mudah, hariKe: 1),
            c(NilaiRespons.pas, hariKe: 2),
          ],
          tingkat: {Kategori.komunikasi: 4},
        ),
      );
      expect(hasil.tingkat[Kategori.komunikasi], 4);
      expect(logUntuk(hasil, 'A_naik', Kategori.komunikasi), isNull,
          reason: 'log tanpa perubahan hanya menambah kebisingan');
    });

    test('4. already at level 1 and B fires: stays 1, duration still shortens', () {
      final hasil = jalankan(
        masukan(
          catatan: [
            c(NilaiRespons.sulit, hariKe: 0),
            c(NilaiRespons.sulit, hariKe: 1),
            c(NilaiRespons.pas, hariKe: 2),
          ],
          tingkat: {Kategori.komunikasi: 1},
          durasi: {Kategori.komunikasi: 12},
        ),
      );
      expect(hasil.tingkat[Kategori.komunikasi], 1);
      expect(hasil.durasi[Kategori.komunikasi], 9);
      expect(logUntuk(hasil, 'B_turun', Kategori.komunikasi), isNotNull,
          reason: 'ada yang berubah, jadi harus tercatat');
    });

    test('5. an even mix moves nothing', () {
      final hasil = jalankan(
        masukan(
          catatan: [
            c(NilaiRespons.mudah, hariKe: 0),
            c(NilaiRespons.pas, hariKe: 1),
            c(NilaiRespons.sulit, hariKe: 2),
          ],
        ),
      );
      expect(hasil.tingkat[Kategori.komunikasi], 2);
      expect(logUntuk(hasil, 'A_naik', Kategori.komunikasi), isNull);
      expect(logUntuk(hasil, 'B_turun', Kategori.komunikasi), isNull);
    });

    test('6. already at five minutes and B fires: stays five', () {
      final hasil = jalankan(
        masukan(
          catatan: [
            c(NilaiRespons.sulit, hariKe: 0),
            c(NilaiRespons.sulit, hariKe: 1),
            c(NilaiRespons.pas, hariKe: 2),
          ],
          tingkat: {Kategori.komunikasi: 3},
          durasi: {Kategori.komunikasi: 5},
        ),
      );
      expect(hasil.durasi[Kategori.komunikasi], 5);
      // The level still moved, so the row is still written.
      expect(hasil.tingkat[Kategori.komunikasi], 2);
    });

    test('7. a manual correction is not overwritten in the same period', () {
      final hasil = jalankan(
        masukan(
          catatan: [
            c(NilaiRespons.mudah, hariKe: 0),
            c(NilaiRespons.mudah, hariKe: 1),
            c(NilaiRespons.pas, hariKe: 2),
          ],
          dikoreksiManual: {Kategori.komunikasi},
        ),
      );
      expect(hasil.tingkat[Kategori.komunikasi], 2);
      expect(logUntuk(hasil, 'A_naik', Kategori.komunikasi), isNull);
    });

    test('7b. a correction on one category does not freeze the others', () {
      final hasil = jalankan(
        masukan(
          catatan: [
            for (var i = 0; i < 3; i++)
              c(NilaiRespons.mudah, hariKe: i, kategori: Kategori.komunikasi),
            for (var i = 0; i < 3; i++)
              c(NilaiRespons.mudah, hariKe: i, kategori: Kategori.motorik),
          ],
          dikoreksiManual: {Kategori.komunikasi},
        ),
      );
      expect(hasil.tingkat[Kategori.komunikasi], 2);
      expect(hasil.tingkat[Kategori.motorik], 3);
    });
  });

  // ============================================== promises about the log ==

  group('every row explains itself with real numbers', () {
    test('no reason is generic', () {
      final hasil = jalankan(
        masukan(
          catatan: [
            for (var i = 0; i < 4; i++)
              c(NilaiRespons.sulit, minggu: minggu2, hariKe: i),
            for (var i = 0; i < 4; i++)
              c(NilaiRespons.mudah, minggu: minggu3, hariKe: i, jam: 8),
          ],
        ),
      );

      expect(hasil.log, isNotEmpty);
      for (final baris in hasil.log) {
        expect(
          RegExp(r'\d').hasMatch(baris.alasan),
          isTrue,
          reason: '${baris.aturanId} tidak menyebut satu pun angka: '
              '"${baris.alasan}"',
        );
        expect(baris.alasan.trim(), endsWith('.'));
        expect(baris.alasan.length, greaterThan(30));
        for (final generik in [
          'sistem menyesuaikan',
          'telah disesuaikan otomatis',
          'perubahan diterapkan',
        ]) {
          expect(baris.alasan.toLowerCase(), isNot(contains(generik)));
        }
      }
    });

    test('no reason grades the child or strays into medical language', () {
      final hasil = jalankan(
        masukan(
          catatan: [
            for (var i = 0; i < 4; i++)
              c(NilaiRespons.sulit, minggu: minggu1, hariKe: i),
            for (var i = 0; i < 4; i++)
              c(NilaiRespons.sulit, minggu: minggu2, hariKe: i),
            for (var i = 0; i < 4; i++)
              c(NilaiRespons.sulit, minggu: minggu3, hariKe: i),
          ],
        ),
      );

      for (final baris in hasil.log) {
        final teks = baris.alasan.toLowerCase();
        for (final terlarang in [
          'autis', 'diagnos', 'derajat', 'keparahan', 'penderita',
          'penyandang', 'pasien', 'obat', 'dosis', 'terapi', 'skor anak',
          'kemampuan anak', 'normal', 'terlambat', 'gangguan',
        ]) {
          expect(teks, isNot(contains(terlarang)),
              reason: '${baris.aturanId} memuat "$terlarang"');
        }
      }
    });

    test('every row carries before and after, so the change is auditable', () {
      final hasil = jalankan(
        masukan(
          catatan: [
            for (var i = 0; i < 4; i++)
              c(NilaiRespons.sulit, minggu: minggu2, hariKe: i),
            for (var i = 0; i < 4; i++)
              c(NilaiRespons.mudah, minggu: minggu3, hariKe: i),
          ],
        ),
      );
      for (final baris in hasil.log) {
        expect(baris.kategori, isNotNull);
        expect(baris.nilaiSebelum, isNotEmpty);
        expect(baris.nilaiSesudah, isNotEmpty);
        expect(baris.dikoreksiManual, isFalse);
      }
    });

    test('the engine is deterministic: same input, same rows', () {
      final m = masukan(
        catatan: [
          for (var i = 0; i < 4; i++)
            c(NilaiRespons.sulit, minggu: minggu2, hariKe: i),
          for (var i = 0; i < 4; i++)
            c(NilaiRespons.mudah, minggu: minggu3, hariKe: i),
        ],
      );
      final a = jalankan(m).log.map((l) => '${l.aturanId}|${l.alasan}').toList();
      final b = jalankan(m).log.map((l) => '${l.aturanId}|${l.alasan}').toList();
      expect(a, b);
    });
  });

  group('it refuses to invent evidence', () {
    test('notes from other categories never move a category', () {
      final hasil = jalankan(
        masukan(
          catatan: [
            for (var i = 0; i < 6; i++)
              c(NilaiRespons.mudah, hariKe: i, kategori: Kategori.motorik),
          ],
        ),
      );
      expect(hasil.tingkat[Kategori.komunikasi], 2);
      expect(logUntuk(hasil, 'A_naik', Kategori.komunikasi), isNull);
    });

    test('two notes are never enough for anything', () {
      final hasil = jalankan(
        masukan(
          catatan: [
            c(NilaiRespons.mudah, hariKe: 0),
            c(NilaiRespons.mudah, hariKe: 1),
          ],
        ),
      );
      expect(hasil.log, isEmpty);
    });

    test('a category with no recorded notes is left exactly as it was', () {
      final awal = masukan(
        catatan: [
          for (var i = 0; i < 3; i++)
            c(NilaiRespons.mudah, hariKe: i, kategori: Kategori.komunikasi),
        ],
      );
      final hasil = jalankan(awal);
      for (final k in Kategori.values.where((k) => k != Kategori.komunikasi)) {
        expect(hasil.tingkat[k], awal.tingkat[k]);
        expect(hasil.durasi[k], awal.durasi[k]);
        expect(hasil.porsi[k], awal.porsi[k]);
      }
    });
  });
}
