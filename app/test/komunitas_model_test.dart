import 'package:dekapautis/data/models/komunitas.dart';
import 'package:test/test.dart';

/// The client half of the anonymity guarantee.
///
/// The server half is proved in `scripts/test_direktori_komunitas.sql`, which
/// asserts the view has no identity column at all. This file guards the other
/// direction: that nothing on the client would display a name even if one
/// somehow arrived in the payload. Both halves are needed - the server one
/// stops the data leaving, this one stops a future change quietly using it.
void main() {
  group('an author is an initial or the word Anonim, never a name', () {
    test('a name in the payload is ignored, not rendered', () {
      // If somebody later adds `nama_penulis` back to the view and wires it to
      // the card, this test fails rather than shipping.
      final p = Postingan.fromMap({
        'id': 'p1',
        'topik': 'sensorik',
        'judul': 'Anak menutup telinga di mal',
        'isi': 'Ada yang punya pengalaman serupa?',
        'anonim': false,
        'jumlah_balasan': 2,
        'milik_saya': false,
        'inisial': 'BS',
        'nama_penulis': 'Bagus Setiawan',
        'pengguna_id': 'user-123',
        'dibuat_pada': '2026-08-20T09:00:00Z',
      });

      expect(p.penulisTampil, 'BS');
      expect(p.penulisTampil, isNot(contains('Bagus')));
      expect(p.penulisTampil, isNot(contains('Setiawan')));
    });

    test('an anonymous post shows Anonim even if an initial arrives', () {
      // Defence in depth: the view already sends null for an anonymous post.
      // If that ever regressed, the screen still would not identify anyone.
      final p = Postingan.fromMap({
        'id': 'p2',
        'topik': 'rutinitas',
        'judul': 'Rutinitas pagi',
        'isi': 'Ini yang kami coba.',
        'anonim': true,
        'jumlah_balasan': 0,
        'milik_saya': false,
        'inisial': 'RK',
      });

      expect(p.penulisTampil, 'Anonim');
      expect(p.penulisTampil, isNot(contains('R')));
    });

    test('a missing initial degrades to a placeholder, not a crash', () {
      final p = Postingan.fromMap({
        'id': 'p3',
        'topik': 'sekolah',
        'judul': 'Bicara dengan guru',
        'isi': 'Lega sekali.',
        'anonim': false,
        'jumlah_balasan': 0,
        'milik_saya': true,
      });
      expect(p.penulisTampil, '?');
    });

    test('replies obey the same rule', () {
      final anonim = Balasan.fromMap({
        'id': 'b1',
        'postingan_id': 'p1',
        'isi': 'Kami juga mengalaminya.',
        'anonim': true,
        'milik_saya': false,
        'inisial': 'RK',
      });
      final bernama = Balasan.fromMap({
        'id': 'b2',
        'postingan_id': 'p1',
        'isi': 'Terima kasih sudah berbagi.',
        'anonim': false,
        'milik_saya': false,
        'inisial': 'BS',
      });

      expect(anonim.penulisTampil, 'Anonim');
      expect(bernama.penulisTampil, 'BS');
    });
  });

  group('ownership without identity', () {
    test('milik_saya lets the screen offer edit without naming anyone', () {
      final punyaSaya = Postingan.fromMap({
        'id': 'p4',
        'topik': 'dukungan',
        'judul': 'Capek minggu ini',
        'isi': 'Boleh cerita di sini?',
        'anonim': true,
        'jumlah_balasan': 0,
        'milik_saya': true,
      });

      // Even on my own anonymous post, the chip says Anonim - what other
      // people see is what I see, so there is no way to be misled about how
      // exposed the post is.
      expect(punyaSaya.milikSaya, isTrue);
      expect(punyaSaya.penulisTampil, 'Anonim');
    });
  });

  group('topics', () {
    test('an unknown topic falls back rather than throwing', () {
      expect(
        TopikKomunitas.fromDb('topik-yang-belum-ada'),
        TopikKomunitas.semua,
      );
    });

    test('every topic round-trips through its database value', () {
      for (final t in TopikKomunitas.values) {
        if (t == TopikKomunitas.semua) continue;
        expect(TopikKomunitas.fromDb(t.dbValue), t);
      }
    });
  });

  group('report reasons match the database constraint', () {
    test('every reason is one the check constraint accepts', () {
      // Mirrors `kategori in ('batas_medis','kasar','spam','lainnya')` in
      // migration 008. A mismatch here fails at runtime on insert, not here,
      // so it is worth pinning.
      const diterima = {'batas_medis', 'kasar', 'spam', 'lainnya'};
      for (final a in AlasanLaporan.values) {
        expect(diterima, contains(a.dbValue), reason: a.label);
      }
      expect(AlasanLaporan.values, hasLength(diterima.length));
    });
  });
}
