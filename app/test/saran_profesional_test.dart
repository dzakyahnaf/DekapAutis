import 'package:dekapautis/domain/adaptasi/adaptation_engine.dart';
import 'package:dekapautis/domain/adaptasi/saran_profesional.dart';
import 'package:test/test.dart';

/// The closing arc of Gambar 7.1: a professional's response changing the plan.
///
/// `package:test`, not `flutter_test`, for the same reason the engine itself is
/// tested that way - if this needed a widget, the logic would be in the wrong
/// place.
void main() {
  Map<Kategori, int> porsiAwal() => {
    Kategori.komunikasi: 3,
    Kategori.motorik: 2,
    Kategori.sensorik: 2,
    Kategori.kemandirian: 1,
    Kategori.sosial: 1,
  };

  Map<Kategori, int> durasiAwal() => {
    Kategori.komunikasi: 15,
    Kategori.motorik: 15,
    Kategori.sensorik: 10,
    Kategori.kemandirian: 10,
    Kategori.sosial: 10,
  };

  SaranProfesional saran({Set<Kategori> kategori = const {}, int? durasi}) =>
      SaranProfesional(
        tanggapanId: 'tg-1',
        kategoriDitekankan: kategori,
        durasiMenit: durasi,
      );

  group('a suggestion moves the plan', () {
    test('an emphasised category gets one more session a week', () {
      final hasil = terapkanSaranProfesional(
        saran: saran(kategori: {Kategori.komunikasi}),
        porsi: porsiAwal(),
        durasi: durasiAwal(),
      );

      expect(hasil.porsi[Kategori.komunikasi], 4);
      // Nothing else moved.
      expect(hasil.porsi[Kategori.motorik], 2);
      expect(hasil.log, hasLength(1));
    });

    test('a suggested session length is applied to the named categories', () {
      final hasil = terapkanSaranProfesional(
        saran: saran(kategori: {Kategori.sensorik}, durasi: 20),
        porsi: porsiAwal(),
        durasi: durasiAwal(),
      );

      expect(hasil.durasi[Kategori.sensorik], 20);
      expect(hasil.durasi[Kategori.komunikasi], 15, reason: 'tidak disebut');
      expect(hasil.log, hasLength(2), reason: 'porsi naik dan durasi berubah');
    });

    test('a duration with no category named applies to the whole plan', () {
      final hasil = terapkanSaranProfesional(
        saran: saran(durasi: 10),
        porsi: porsiAwal(),
        durasi: durasiAwal(),
      );

      expect(hasil.durasi[Kategori.komunikasi], 10);
      expect(hasil.durasi[Kategori.motorik], 10);
      // Sensorik was already 10, so it did not move and wrote no row.
      expect(hasil.log.where((l) => l.kategori == Kategori.sensorik), isEmpty);
    });
  });

  group('every row explains itself with real numbers', () {
    test('the reason names the before and after, never a generic sentence', () {
      final hasil = terapkanSaranProfesional(
        saran: saran(kategori: {Kategori.komunikasi}, durasi: 25),
        porsi: porsiAwal(),
        durasi: durasiAwal(),
      );

      final porsiLog = hasil.log.firstWhere(
        (l) => l.nilaiSebelum.containsKey('porsi'),
      );
      expect(porsiLog.alasan, contains('3'));
      expect(porsiLog.alasan, contains('4'));

      final durasiLog = hasil.log.firstWhere(
        (l) => l.nilaiSebelum.containsKey('durasi_menit'),
      );
      expect(durasiLog.alasan, contains('15'));
      expect(durasiLog.alasan, contains('25'));

      for (final baris in hasil.log) {
        expect(baris.aturanId, 'F_profesional');
        expect(
          baris.alasan,
          isNot(contains('sistem menyesuaikan')),
          reason: 'alasan generik',
        );
      }
    });

    test('the reason says a person asked, and that the caregiver agreed', () {
      final hasil = terapkanSaranProfesional(
        saran: saran(kategori: {Kategori.sosial}),
        porsi: porsiAwal(),
        durasi: durasiAwal(),
      );

      final alasan = hasil.log.single.alasan;
      expect(alasan, contains('profesional'));
      expect(alasan, contains('Anda yang menyetujui'));
    });

    test('no row grades the child or strays into medical language', () {
      final hasil = terapkanSaranProfesional(
        saran: saran(kategori: Kategori.values.toSet(), durasi: 30),
        porsi: porsiAwal(),
        durasi: durasiAwal(),
      );

      const terlarang = [
        'ringan',
        'sedang',
        'berat',
        'tingkat autisme',
        'derajat',
        'obat',
        'dosis',
        'terapi medis',
        'sembuh',
        'gangguan',
      ];
      for (final baris in hasil.log) {
        for (final kata in terlarang) {
          expect(
            baris.alasan.toLowerCase(),
            isNot(contains(kata)),
            reason: '"$kata" muncul di: ${baris.alasan}',
          );
        }
      }
    });
  });

  group('the plan is protected from the suggestion, too', () {
    test('a category already at the weekly ceiling does not go past it', () {
      final penuh = porsiAwal()..[Kategori.komunikasi] = maksSesiMingguan;
      final hasil = terapkanSaranProfesional(
        saran: saran(kategori: {Kategori.komunikasi}),
        porsi: penuh,
        durasi: durasiAwal(),
      );

      expect(hasil.porsi[Kategori.komunikasi], maksSesiMingguan);
      expect(hasil.log, isEmpty, reason: 'tidak ada angka yang bergerak');
      // Still hands-off, so an automatic rule does not lower it the same week
      // a professional asked for more.
      expect(hasil.dikoreksiManual, contains(Kategori.komunikasi));
    });

    test('a duration outside the plan bounds is clamped, not obeyed', () {
      final terlaluLama = terapkanSaranProfesional(
        saran: saran(kategori: {Kategori.motorik}, durasi: 240),
        porsi: porsiAwal(),
        durasi: durasiAwal(),
      );
      expect(terlaluLama.durasi[Kategori.motorik], maksDurasiSaran);

      final terlaluSingkat = terapkanSaranProfesional(
        saran: saran(kategori: {Kategori.motorik}, durasi: 1),
        porsi: porsiAwal(),
        durasi: durasiAwal(),
      );
      expect(terlaluSingkat.durasi[Kategori.motorik], minDurasiSaran);
    });

    test('an empty suggestion changes nothing and logs nothing', () {
      final hasil = terapkanSaranProfesional(
        saran: saran(),
        porsi: porsiAwal(),
        durasi: durasiAwal(),
      );

      expect(hasil.porsi, porsiAwal());
      expect(hasil.durasi, durasiAwal());
      expect(hasil.log, isEmpty);
      expect(hasil.adaPerubahan, isFalse);
      expect(saran().kosong, isTrue);
    });

    test('the input maps are not mutated', () {
      // The caller still holds the plan it passed in; changing it underneath
      // them would make "what changed" impossible to show.
      final porsi = porsiAwal();
      final durasi = durasiAwal();
      terapkanSaranProfesional(
        saran: saran(kategori: {Kategori.komunikasi}, durasi: 30),
        porsi: porsi,
        durasi: durasi,
      );

      expect(porsi, porsiAwal());
      expect(durasi, durasiAwal());
    });
  });

  group('handing the result back to the engine', () {
    test('touched categories are left alone by the automatic rules', () {
      final hasil = terapkanSaranProfesional(
        saran: saran(kategori: {Kategori.komunikasi, Kategori.sosial}),
        porsi: porsiAwal(),
        durasi: durasiAwal(),
      );

      // Fed into MasukanAdaptasi.dikoreksiManual on the next run, which is
      // what stops rule C redistributing the week and undoing this.
      expect(hasil.dikoreksiManual, {Kategori.komunikasi, Kategori.sosial});
      for (final baris in hasil.log) {
        expect(baris.dikoreksiManual, isTrue);
      }
    });
  });
}
