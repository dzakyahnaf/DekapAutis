import 'package:dekapautis/data/models/notifikasi.dart';
import 'package:dekapautis/domain/notifikasi/jenis_notifikasi.dart';
import 'package:test/test.dart';

/// L.17 - grouping, and the mapping onto the database.
void main() {
  final sekarang = DateTime(2026, 8, 22, 14, 30);

  Notifikasi pada(DateTime waktu, {String id = 'n'}) => Notifikasi(
    id: id,
    jenis: JenisNotifikasi.balasanKomunitas,
    judul: 'Balasan baru',
    dibaca: false,
    dibuatPada: waktu,
  );

  group('the database mapping is the one the constraint accepts', () {
    test('every kind uses a value the check constraint allows', () {
      // Mirrors `jenis in ('penyesuaian','belum_dicatat','balasan','artikel',
      // 'jadwal')` on the notifikasi table. These were the enum's Dart names
      // for a while, which no insert would have accepted - the failure would
      // only have shown up at runtime against a real database.
      const diterima = {
        'penyesuaian',
        'belum_dicatat',
        'balasan',
        'artikel',
        'jadwal',
      };
      for (final j in JenisNotifikasi.values) {
        expect(diterima, contains(j.dbValue), reason: j.label);
      }
      expect(JenisNotifikasi.values, hasLength(diterima.length));
    });

    test('every kind round-trips', () {
      for (final j in JenisNotifikasi.values) {
        expect(JenisNotifikasi.fromDb(j.dbValue), j);
      }
    });

    test('an unknown value falls back rather than throwing', () {
      expect(JenisNotifikasi.fromDb('jenis-baru'), JenisNotifikasi.artikelBaru);
    });
  });

  group('grouping by when it arrived', () {
    test('the three headings docs/05 asks for', () {
      expect(
        kelompokkan(DateTime(2026, 8, 22, 8), sekarang),
        KelompokWaktu.hariIni,
      );
      expect(
        kelompokkan(DateTime(2026, 8, 21, 23), sekarang),
        KelompokWaktu.kemarin,
      );
      expect(
        kelompokkan(DateTime(2026, 8, 17), sekarang),
        KelompokWaktu.mingguIni,
      );
      expect(
        kelompokkan(DateTime(2026, 7, 1), sekarang),
        KelompokWaktu.lebihLama,
      );
    });

    test('a minute past midnight is today, not yesterday', () {
      // Grouping is by calendar day, not by elapsed hours. A notification from
      // 00.05 is "Hari ini" even though it is twelve hours old.
      expect(
        kelompokkan(DateTime(2026, 8, 22, 0, 5), sekarang),
        KelompokWaktu.hariIni,
      );
    });

    test('a clock skew into the future still reads as today', () {
      expect(
        kelompokkan(DateTime(2026, 8, 23), sekarang),
        KelompokWaktu.hariIni,
      );
    });

    test('headings come out in order and empty ones are dropped', () {
      final hasil = kelompokkanSemua([
        pada(DateTime(2026, 7, 1), id: 'lama'),
        pada(DateTime(2026, 8, 22, 9), id: 'pagi'),
      ], sekarang);

      // No "Kemarin" and no "Minggu ini": a bare heading with nothing under it
      // reads as something having gone missing.
      expect(hasil.keys.toList(), [
        KelompokWaktu.hariIni,
        KelompokWaktu.lebihLama,
      ]);
    });

    test('newest first inside a heading', () {
      final hasil = kelompokkanSemua([
        pada(DateTime(2026, 8, 22, 9), id: 'pagi'),
        pada(DateTime(2026, 8, 22, 13), id: 'siang'),
        pada(DateTime(2026, 8, 22, 11), id: 'tengah'),
      ], sekarang);

      expect(hasil[KelompokWaktu.hariIni]!.map((n) => n.id).toList(), [
        'siang',
        'tengah',
        'pagi',
      ]);
    });

    test('an empty list produces no headings at all', () {
      expect(kelompokkanSemua([], sekarang), isEmpty);
    });
  });

  group('a row knows whether it can be acted on', () {
    test('a notification with no link is not pretending to be tappable', () {
      final n = Notifikasi.fromMap({
        'id': 'n1',
        'jenis': 'artikel',
        'judul': 'Artikel baru ditinjau',
        'dibaca': false,
        'dibuat_pada': '2026-08-22T09:00:00Z',
      });
      expect(n.tautan, isNull);
    });

    test('the schedule trigger sends a link to act on', () {
      final n = Notifikasi.fromMap({
        'id': 'n2',
        'jenis': 'jadwal',
        'judul': 'Pengajuan jadwal disetujui',
        'dibaca': false,
        'dibuat_pada': '2026-08-22T09:00:00Z',
        'tautan': '/direktori/abc',
      });
      expect(n.jenis, JenisNotifikasi.persetujuanJadwal);
      expect(n.tautan, '/direktori/abc');
    });
  });
}
