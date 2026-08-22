import 'package:dekapautis/domain/laporan/metrik_laporan.dart';
import 'package:test/test.dart';

/// Report metrics (docs/06 §1).
///
/// `package:test`, not `flutter_test`: these numbers end up in a PDF a therapist
/// may read, and they are computed with no widget, no model and no network
/// anywhere near them. This file stops compiling if that changes.
void main() {
  final mulai = DateTime(2026, 8, 3); // Monday
  final selesai = DateTime(2026, 8, 30); // four weeks

  CatatanLaporan c(
    NilaiRespons? nilai, {
    Kategori kategori = Kategori.komunikasi,
    int hariKe = 0,
  }) => CatatanLaporan(
    kategori: kategori,
    tanggal: mulai.add(Duration(days: hariKe)),
    nilai: nilai,
  );

  MetrikLaporan hitung(List<CatatanLaporan> catatan) => hitungMetrik(
    catatan: catatan,
    periodeMulai: mulai,
    periodeSelesai: selesai,
  );

  group('an empty period', () {
    test('produces zeroes rather than throwing', () {
      final m = hitung([]);
      expect(m.aktivitasTerjadwal, 0);
      expect(m.aktivitasTercatat, 0);
      expect(m.persenTercatat, 0);
      expect(m.rataSesiHarian, 0);
      expect(m.trenMingguan, isEmpty);
      expect(m.perKategori, isEmpty);
    });

    test('a caregiver who recorded nothing still gets a readable period', () {
      final m = hitung([c(null), c(null, hariKe: 1)]);
      expect(m.aktivitasTerjadwal, 2);
      expect(m.aktivitasTercatat, 0);
      expect(m.persenTercatat, 0);
    });
  });

  group('counting', () {
    test('separates what was planned from what was recorded', () {
      final m = hitung([
        c(NilaiRespons.mudah),
        c(NilaiRespons.pas, hariKe: 1),
        c(null, hariKe: 2),
        c(null, hariKe: 3),
      ]);
      expect(m.aktivitasTerjadwal, 4);
      expect(m.aktivitasTercatat, 2);
      expect(m.persenTercatat, 50);
    });

    test('notes outside the period are ignored', () {
      final m = hitung([
        c(NilaiRespons.mudah, hariKe: -3),
        c(NilaiRespons.mudah, hariKe: 0),
        c(NilaiRespons.mudah, hariKe: 60),
      ]);
      expect(m.aktivitasTerjadwal, 1);
    });

    test('the daily average is per calendar day, not per recorded day', () {
      // 28 notes across 28 days is one a day, even if they all fell on Mondays.
      final m = hitung([
        for (var i = 0; i < 28; i++) c(NilaiRespons.pas, hariKe: i),
      ]);
      expect(m.jumlahHari, 28);
      expect(m.rataSesiHarian, closeTo(1.0, 0.001));
    });
  });

  group('weekly trend', () {
    test('one entry per week that has notes, in order', () {
      final m = hitung([
        c(NilaiRespons.mudah),
        c(NilaiRespons.mudah, hariKe: 7),
        c(NilaiRespons.sulit, hariKe: 14),
      ]);
      expect(m.trenMingguan.length, 3);
      final tanggal = m.trenMingguan.map((t) => t.mingguMulai).toList();
      expect(tanggal, [...tanggal]..sort());
    });

    test('percentages are whole numbers, so chart and narrative agree', () {
      final m = hitung([
        c(NilaiRespons.mudah),
        c(NilaiRespons.mudah, hariKe: 1),
        c(NilaiRespons.sulit, hariKe: 2),
      ]);
      expect(m.trenMingguan.single.persenMudah, 67);
      expect(m.trenMingguan.single.jumlahTercatat, 3);
    });

    test('a week with no notes leaves no entry rather than a false zero', () {
      final m = hitung([
        c(NilaiRespons.mudah),
        // week two silent
        c(NilaiRespons.mudah, hariKe: 14),
      ]);
      expect(m.trenMingguan.length, 2);
    });
  });

  group('per category', () {
    test('each category is counted on its own notes only', () {
      final m = hitung([
        c(NilaiRespons.mudah, kategori: Kategori.komunikasi),
        c(NilaiRespons.sulit, kategori: Kategori.komunikasi, hariKe: 1),
        c(NilaiRespons.mudah, kategori: Kategori.motorik, hariKe: 2),
      ]);
      final komunikasi = m.perKategori.firstWhere(
        (k) => k.kategori == Kategori.komunikasi,
      );
      expect(komunikasi.persenMudah, 50);
      expect(komunikasi.jumlahTercatat, 2);
    });

    test('a category with no notes is absent, not shown as zero', () {
      final m = hitung([c(NilaiRespons.mudah, kategori: Kategori.sosial)]);
      expect(m.perKategori.length, 1);
      expect(m.perKategori.single.kategori, Kategori.sosial);
    });

    test('improvement across the period reads as naik', () {
      final m = hitung([
        for (var i = 0; i < 6; i++) c(NilaiRespons.sulit, hariKe: i),
        for (var i = 0; i < 6; i++) c(NilaiRespons.mudah, hariKe: 20 + i),
      ]);
      expect(m.perKategori.single.tren, Tren.naik);
    });

    test('decline reads as turun', () {
      final m = hitung([
        for (var i = 0; i < 6; i++) c(NilaiRespons.mudah, hariKe: i),
        for (var i = 0; i < 6; i++) c(NilaiRespons.sulit, hariKe: 20 + i),
      ]);
      expect(m.perKategori.single.tren, Tren.turun);
    });

    test('a small wobble is called steady, not movement', () {
      // 50 percent then 60: real but within the noise of a handful of notes.
      final m = hitung([
        for (var i = 0; i < 5; i++)
          c(i < 3 ? NilaiRespons.mudah : NilaiRespons.sulit, hariKe: i),
        for (var i = 0; i < 5; i++)
          c(i < 3 ? NilaiRespons.mudah : NilaiRespons.sulit, hariKe: 20 + i),
      ]);
      expect(m.perKategori.single.tren, Tren.datar);
    });

    test('too few notes on either side is steady, never a guess', () {
      final m = hitung([
        c(NilaiRespons.sulit),
        for (var i = 0; i < 6; i++) c(NilaiRespons.mudah, hariKe: 20 + i),
      ]);
      expect(m.perKategori.single.tren, Tren.datar);
    });
  });

  group('no single score anywhere', () {
    test('nothing aggregates the categories into one figure', () {
      final m = hitung([
        for (var i = 0; i < 10; i++)
          c(
            NilaiRespons.values[i % 3],
            kategori: Kategori.values[i % 5],
            hariKe: i,
          ),
      ]);

      // Every published number is either about the plan or about one category.
      // There is deliberately no field that could be read as "the child scored
      // N", because Bab 4.2 forbids producing one.
      final metrik = m.toMetrikJson();
      expect(metrik.keys.toSet(), {
        'aktivitas_terjadwal',
        'aktivitas_tercatat',
        'persen_tercatat',
        'rata_sesi_harian',
        'jumlah_hari',
      });
      for (final kunci in metrik.keys) {
        for (final terlarang in ['skor', 'nilai_anak', 'kemampuan', 'indeks']) {
          expect(kunci, isNot(contains(terlarang)));
        }
      }
    });

    test('trends are named directions, not numbers', () {
      for (final t in Tren.values) {
        expect(int.tryParse(t.label), isNull);
      }
    });
  });

  group('the closed set of figures the narrative may use', () {
    test('every number the report publishes is in it', () {
      final m = hitung([
        c(NilaiRespons.mudah),
        c(NilaiRespons.sulit, hariKe: 1),
        c(NilaiRespons.mudah, kategori: Kategori.motorik, hariKe: 8),
        c(null, hariKe: 9),
      ]);

      final sah = m.angkaSah;
      expect(sah, contains('${m.aktivitasTerjadwal}'));
      expect(sah, contains('${m.aktivitasTercatat}'));
      expect(sah, contains('${m.persenTercatat}'));
      for (final t in m.trenMingguan) {
        expect(sah, contains('${t.persenMudah}'));
      }
      for (final k in m.perKategori) {
        expect(sah, contains('${k.persenMudah}'));
      }
    });

    test('it accepts both decimal separators for the daily average', () {
      final m = hitung([
        for (var i = 0; i < 14; i++) c(NilaiRespons.pas, hariKe: i),
      ]);
      // Indonesian writes 0,5 and the model may echo 0.5. Both are the same
      // fact, and rejecting a narrative over a comma would be absurd.
      expect(m.angkaSah, contains(m.rataSesiHarian.toStringAsFixed(1)));
      expect(
        m.angkaSah,
        contains(m.rataSesiHarian.toStringAsFixed(1).replaceAll('.', ',')),
      );
    });

    test('a figure that was never computed is not in the set', () {
      final m = hitung([c(NilaiRespons.mudah)]);
      expect(m.angkaSah, isNot(contains('9999')));
    });
  });
}
