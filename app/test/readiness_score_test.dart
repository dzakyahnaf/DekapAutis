import 'package:dekapautis/domain/adaptasi/adaptation_engine.dart';
import 'package:test/test.dart';

/// Readiness score, on its own.
///
/// Note the import: `package:test`, not `flutter_test`. The engine has no
/// Flutter in it at all, and this file would stop compiling the moment someone
/// reached for a widget.
///
/// The score is a weighted average of the last six responses in one category,
/// newest first, with weights [1.0, 0.9, 0.8, 0.7, 0.6, 0.5]. Fewer than three
/// samples returns null, and null means no rule runs: three days of notes is
/// not enough to move anything about a child's week.
void main() {
  final senin = DateTime(2026, 8, 24);

  CatatanUntukAdaptasi catatan(
    NilaiRespons nilai, {
    int hariKe = 0,
    int jam = 8,
    Kategori kategori = Kategori.komunikasi,
  }) => CatatanUntukAdaptasi(
    kategori: kategori,
    nilai: nilai,
    dicatatPada: senin.add(Duration(days: hariKe, hours: jam)),
    jamJadwal: jam,
  );

  group('too few samples', () {
    test('no notes at all returns null', () {
      expect(skorKesiapan(const []), isNull);
    });

    test('one and two notes return null', () {
      expect(skorKesiapan([catatan(NilaiRespons.mudah)]), isNull);
      expect(
        skorKesiapan([
          catatan(NilaiRespons.mudah),
          catatan(NilaiRespons.mudah, hariKe: 1),
        ]),
        isNull,
      );
    });

    test('exactly three notes is enough', () {
      expect(
        skorKesiapan([
          catatan(NilaiRespons.mudah),
          catatan(NilaiRespons.mudah, hariKe: 1),
          catatan(NilaiRespons.mudah, hariKe: 2),
        ]),
        isNotNull,
      );
    });
  });

  group('the arithmetic', () {
    test('all easy scores +1, all hard scores -1', () {
      final semuaMudah = List.generate(
        6,
        (i) => catatan(NilaiRespons.mudah, hariKe: i),
      );
      final semuaSulit = List.generate(
        6,
        (i) => catatan(NilaiRespons.sulit, hariKe: i),
      );
      expect(skorKesiapan(semuaMudah), closeTo(1, 0.0001));
      expect(skorKesiapan(semuaSulit), closeTo(-1, 0.0001));
    });

    test('all "pas" scores zero', () {
      final semua = List.generate(
        4,
        (i) => catatan(NilaiRespons.pas, hariKe: i),
      );
      expect(skorKesiapan(semua), closeTo(0, 0.0001));
    });

    test('recent notes count for more than older ones', () {
      // Same three answers, opposite order. The newer one dominates, so the
      // scores must differ - a child who has just started finding something
      // easy is not in the same place as one who has just started struggling.
      final membaik = [
        catatan(NilaiRespons.mudah, hariKe: 2),
        catatan(NilaiRespons.pas, hariKe: 1),
        catatan(NilaiRespons.sulit),
      ];
      final memburuk = [
        catatan(NilaiRespons.sulit, hariKe: 2),
        catatan(NilaiRespons.pas, hariKe: 1),
        catatan(NilaiRespons.mudah),
      ];
      expect(skorKesiapan(membaik)!, greaterThan(skorKesiapan(memburuk)!));
    });

    test('weights are exactly the ones docs/04 lists', () {
      // Newest mudah (+1 x 1.0), then two sulit (-1 x 0.9, -1 x 0.8).
      // (1.0 - 0.9 - 0.8) / (1.0 + 0.9 + 0.8) = -0.7 / 2.7
      final campur = [
        catatan(NilaiRespons.mudah, hariKe: 2),
        catatan(NilaiRespons.sulit, hariKe: 1),
        catatan(NilaiRespons.sulit),
      ];
      expect(skorKesiapan(campur), closeTo(-0.7 / 2.7, 0.0001));
    });

    test('only the last six notes are considered', () {
      // Two easy weeks buried under six hard days must not keep the score up.
      final banyak = [
        for (var i = 0; i < 6; i++) catatan(NilaiRespons.sulit, hariKe: 20 - i),
        for (var i = 0; i < 10; i++) catatan(NilaiRespons.mudah, hariKe: i),
      ];
      expect(skorKesiapan(banyak), closeTo(-1, 0.0001));
    });

    test('order of the input list does not matter, only the timestamps', () {
      final urut = [
        catatan(NilaiRespons.mudah, hariKe: 2),
        catatan(NilaiRespons.sulit, hariKe: 1),
        catatan(NilaiRespons.sulit),
      ];
      final acak = [urut[2], urut[0], urut[1]];
      expect(skorKesiapan(acak), closeTo(skorKesiapan(urut)!, 0.0001));
    });
  });

  group('the score is a signal, never a grade', () {
    test('it stays inside -1 and 1 for any mix', () {
      for (final n in [3, 4, 5, 6, 12]) {
        final campur = List.generate(
          n,
          (i) => catatan(NilaiRespons.values[i % 3], hariKe: i),
        );
        final skor = skorKesiapan(campur)!;
        expect(skor, inInclusiveRange(-1, 1));
      }
    });
  });
}
