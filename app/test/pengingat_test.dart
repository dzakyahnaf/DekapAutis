import 'package:dekapautis/domain/notifikasi/jenis_notifikasi.dart';
import 'package:dekapautis/domain/notifikasi/pengingat.dart';
import 'package:test/test.dart';

/// Reminders for activities that were not recorded (F8).
///
/// `package:test`, not `flutter_test`: deciding whether to interrupt a
/// caregiver's evening is a judgement about their child, not a rendering
/// detail, and it is testable without an emulator for exactly that reason.
void main() {
  DateTime jam(int h, [int m = 0]) => DateTime(2026, 8, 22, h, m);

  JadwalRingkas jadwal(
    String judul,
    int h, {
    bool dicatat = false,
    int menit = 0,
  }) => JadwalRingkas(
    id: judul,
    judul: judul,
    waktu: jam(h, menit),
    sudahDicatat: dicatat,
  );

  group('what counts as missed', () {
    test('an activity past its window with no response is a reminder', () {
      final hasil = pengingatAktivitas(
        sekarang: jam(11),
        jadwal: [jadwal('Meniru tepuk tangan', 9)],
        modeTenang: false,
      );
      expect(hasil, hasLength(1));
      expect(hasil.single.jenis, JenisNotifikasi.aktivitasBelumTercatat);
      expect(hasil.single.judul, 'Satu aktivitas belum tercatat');
      expect(hasil.single.isi, contains('Meniru tepuk tangan'));
    });

    test('a caregiver running slightly late is not chased', () {
      // Fifteen minutes behind is not a missed activity, it is a Tuesday.
      final hasil = pengingatAktivitas(
        sekarang: jam(9, 15),
        jadwal: [jadwal('Meniru tepuk tangan', 9)],
        modeTenang: false,
      );
      expect(hasil, isEmpty);
    });

    test('an activity already recorded is never mentioned', () {
      final hasil = pengingatAktivitas(
        sekarang: jam(14),
        jadwal: [jadwal('Meniru tepuk tangan', 9, dicatat: true)],
        modeTenang: false,
      );
      expect(hasil, isEmpty);
    });

    test('an activity still ahead of its time is not missed', () {
      final hasil = pengingatAktivitas(
        sekarang: jam(10),
        jadwal: [jadwal('Cuci tangan mandiri', 16)],
        modeTenang: false,
      );
      expect(hasil, isEmpty);
    });

    test('yesterday is not chased today', () {
      final hasil = pengingatAktivitas(
        sekarang: jam(11),
        jadwal: [
          JadwalRingkas(
            id: 'kemarin',
            judul: 'Kemarin',
            waktu: DateTime(2026, 8, 21, 9),
            sudahDicatat: false,
          ),
        ],
        modeTenang: false,
      );
      expect(hasil, isEmpty);
    });
  });

  group('how much it is willing to say', () {
    test('five missed activities produce one reminder, not five', () {
      // A phone that buzzes five times gets put face down, after which the
      // app cannot help at all.
      final hasil = pengingatAktivitas(
        sekarang: jam(17),
        jadwal: [
          jadwal('Menyusun balok', 9),
          jadwal('Meniru tepuk tangan', 10),
          jadwal('Meraba tiga tekstur', 11),
          jadwal('Cuci tangan mandiri', 12),
          jadwal('Bermain giliran', 13),
        ],
        modeTenang: false,
      );
      expect(hasil, hasLength(1));
      expect(hasil.single.judul, '5 aktivitas belum tercatat');
      // Still names one, so the notification is actionable rather than a
      // vague accusation.
      expect(hasil.single.isi, contains('Menyusun balok'));
    });

    test('it never blames the caregiver, and offers the easy answer', () {
      final hasil = pengingatAktivitas(
        sekarang: jam(17),
        jadwal: [jadwal('Menyusun balok', 9)],
        modeTenang: false,
      );
      final isi = hasil.single.isi;
      expect(isi, contains('belum mau'));
      for (final menyalahkan in ['lupa', 'gagal', 'seharusnya', 'terlambat']) {
        expect(
          isi.toLowerCase(),
          isNot(contains(menyalahkan)),
          reason: 'the reminder blames the reader with "$menyalahkan"',
        );
      }
    });
  });

  group('quiet hours', () {
    test('nothing is raised late at night', () {
      for (final h in [21, 22, 23, 0, 3, 6]) {
        final hasil = pengingatAktivitas(
          sekarang: jam(h),
          jadwal: [jadwal('Menyusun balok', 9)],
          modeTenang: false,
        );
        expect(hasil, isEmpty, reason: 'raised a reminder at $h.00');
      }
    });

    test('nothing is raised before the day has started', () {
      final hasil = pengingatAktivitas(
        sekarang: jam(7),
        jadwal: [
          JadwalRingkas(
            id: 'x',
            judul: 'Rutinitas pagi',
            waktu: jam(6),
            sudahDicatat: false,
          ),
        ],
        modeTenang: false,
      );
      expect(hasil, isEmpty);
    });

    test('the window itself is the documented one', () {
      expect(jamPalingAwal, 8);
      expect(jamPalingAkhir, 20);
    });
  });

  group('Calm Mode, effect four', () {
    test('the reminder still appears, but silently', () {
      // Muted, never hidden. Someone who asked for less noise did not ask for
      // less news about their child.
      final tenang = pengingatAktivitas(
        sekarang: jam(17),
        jadwal: [jadwal('Menyusun balok', 9)],
        modeTenang: true,
      );
      expect(tenang, hasLength(1), reason: 'Calm Mode dropped the reminder');
      expect(tenang.single.berbunyi, isFalse);

      final biasa = pengingatAktivitas(
        sekarang: jam(17),
        jadwal: [jadwal('Menyusun balok', 9)],
        modeTenang: false,
      );
      expect(biasa.single.berbunyi, isTrue);
    });
  });
}
