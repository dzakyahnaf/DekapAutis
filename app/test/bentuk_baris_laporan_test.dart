import 'package:dekapautis/data/repositories/laporan_repository.dart';
import 'package:dekapautis/domain/adaptasi/kategori.dart';
import 'package:test/test.dart';

/// The report screen showed "Layanan sedang tidak dapat dihubungi" on every
/// production launch, and 353 passing tests said nothing was wrong.
///
/// The reason none of them could: widget tests use fakes, and the SQL checks
/// talk to Postgres directly. Nothing exercised PostgREST, which is where the
/// shape is actually decided - `catatan_respons` carries a unique constraint on
/// its foreign key, so PostgREST embeds it as one object, not a list of one.
///
/// The rows below are copied verbatim from what production returned. That is
/// the point of this file: assert against the server's real output, not
/// against a fixture written from the same wrong assumption as the code.
void main() {
  group('bentuk yang benar-benar dikirim PostgREST', () {
    test('respons tertanam sebagai objek dibaca, bukan dilempar', () {
      final catatan = catatanDariBaris([
        {
          'tanggal': '2026-08-06',
          'rencana': {'profil_anak_id': 'd0000001-1111-4000-8000-000000000001'},
          'aktivitas': {'kategori': 'komunikasi'},
          'catatan_respons': {'nilai': 'mudah'},
        },
      ]);

      expect(catatan, hasLength(1));
      expect(catatan.single.kategori, Kategori.komunikasi);
      expect(catatan.single.nilai, NilaiRespons.mudah);
      expect(catatan.single.tanggal, DateTime(2026, 8, 6));
    });

    test('respons null berarti terjadwal tapi belum dicatat', () {
      final catatan = catatanDariBaris([
        {
          'tanggal': '2026-08-12',
          'aktivitas': {'kategori': 'sosial'},
          'catatan_respons': null,
        },
      ]);

      expect(catatan.single.nilai, isNull);
      expect(catatan.single.kategori, Kategori.sosial);
    });

    test('bentuk larik tetap diterima kalau kendala unik pernah dilepas', () {
      final catatan = catatanDariBaris([
        {
          'tanggal': '2026-08-20',
          'aktivitas': {'kategori': 'motorik'},
          'catatan_respons': [
            {'nilai': 'sulit'},
          ],
        },
        {
          'tanggal': '2026-08-21',
          'aktivitas': {'kategori': 'motorik'},
          'catatan_respons': <Object?>[],
        },
      ]);

      expect(catatan.first.nilai, NilaiRespons.sulit);
      expect(catatan.last.nilai, isNull);
    });

    test('135 baris seperti produksi: 115 tercatat, 20 belum', () {
      // The real shape of the demo account's four-week window.
      final baris = [
        for (var i = 0; i < 135; i++)
          {
            'tanggal': '2026-08-06',
            'aktivitas': {'kategori': 'kemandirian'},
            'catatan_respons': i < 115 ? {'nilai': 'pas'} : null,
          },
      ];

      final catatan = catatanDariBaris(baris);
      expect(catatan, hasLength(135));
      expect(catatan.where((c) => c.nilai != null), hasLength(115));
      expect(catatan.where((c) => c.nilai == null), hasLength(20));
    });
  });
}
