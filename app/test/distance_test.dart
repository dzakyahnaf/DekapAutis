import 'package:dekapautis/domain/direktori/jarak.dart';
import 'package:test/test.dart';

/// Haversine distance (docs/06 §1).
///
/// `package:test`: there is no map SDK and no network here, only arithmetic,
/// and it is checked against reference values rather than eyeballed on a card.
void main() {
  // Real Surabaya landmarks, with distances taken from an independent
  // great-circle calculator. If the maths drifts, these are what catch it.
  const tuguPahlawan = Koordinat(-7.2456, 112.7378);
  const its = Koordinat(-7.2819, 112.7951);
  const bandaraJuanda = Koordinat(-7.3798, 112.7869);
  const monas = Koordinat(-6.1754, 106.8272);

  group('reference distances', () {
    test('Tugu Pahlawan to ITS is about 7 km', () {
      expect(jarakKm(tuguPahlawan, its), closeTo(7.2, 0.4));
    });

    test('ITS to Juanda is about 11 km', () {
      expect(jarakKm(its, bandaraJuanda), closeTo(10.9, 0.5));
    });

    test('Surabaya to Jakarta is about 660 km', () {
      // Far enough that a flat-earth approximation would be visibly wrong,
      // which is the reason this is haversine and not Pythagoras.
      expect(jarakKm(tuguPahlawan, monas), closeTo(662, 8));
    });
  });

  group('the maths behaves', () {
    test('a point is zero from itself', () {
      expect(jarakKm(its, its), closeTo(0, 0.0001));
    });

    test('distance is symmetric', () {
      expect(
        jarakKm(its, bandaraJuanda),
        closeTo(jarakKm(bandaraJuanda, its), 0.0001),
      );
    });

    test('a degree of latitude is about 111 km anywhere', () {
      expect(
        jarakKm(const Koordinat(0, 0), const Koordinat(1, 0)),
        closeTo(111.2, 0.5),
      );
      expect(
        jarakKm(const Koordinat(-7, 112), const Koordinat(-8, 112)),
        closeTo(111.2, 0.5),
      );
    });

    test('a degree of longitude shrinks away from the equator', () {
      final diKhatulistiwa = jarakKm(
        const Koordinat(0, 0),
        const Koordinat(0, 1),
      );
      final diSurabaya = jarakKm(
        const Koordinat(-7.25, 112),
        const Koordinat(-7.25, 113),
      );
      expect(diSurabaya, lessThan(diKhatulistiwa));
      expect(diSurabaya, closeTo(110.4, 1));
    });

    test('antipodes are half the circumference apart', () {
      expect(
        jarakKm(const Koordinat(0, 0), const Koordinat(0, 180)),
        closeTo(20015, 5),
      );
    });
  });

  group('how a distance is written', () {
    test('under a kilometre reads in metres', () {
      // "400 m" reads as nearer than "0,4 km", though they are the same.
      expect(jarakTampil(0.4), '400 m');
      expect(jarakTampil(0.05), '50 m');
    });

    test('Indonesian writes the decimal with a comma', () {
      expect(jarakTampil(7.24), '7,2 km');
      expect(jarakTampil(1.0), '1,0 km');
    });

    test('past fifty kilometres the decimal is dropped', () {
      expect(jarakTampil(62.3), '62 km');
      expect(jarakTampil(662.4), '662 km');
    });

    test('nonsense renders as a dash rather than a wrong number', () {
      expect(jarakTampil(double.nan), '-');
      expect(jarakTampil(double.infinity), '-');
      expect(jarakTampil(-5), '-');
    });
  });

  group('validity', () {
    test('coordinates outside the globe are rejected', () {
      expect(const Koordinat(91, 0).sah, isFalse);
      expect(const Koordinat(0, 181).sah, isFalse);
      expect(const Koordinat(double.nan, 0).sah, isFalse);
      expect(const Koordinat(-7.25, 112.75).sah, isTrue);
    });
  });

  group('sorting nearest first', () {
    final daftar = [
      ('juanda', bandaraJuanda),
      ('jakarta', monas),
      ('its', its),
      ('tanpa posisi', null),
    ];

    test('orders by real distance', () {
      final urut = urutkanTerdekat(
        daftar,
        tuguPahlawan,
        (e) => e.$2,
      ).map((e) => e.$1).toList();
      expect(urut.take(3).toList(), ['its', 'juanda', 'jakarta']);
    });

    test('entries with no location go last, never first', () {
      // Treating a missing location as zero would put the least complete
      // entries in front of a caregiver looking for help.
      final urut = urutkanTerdekat(
        daftar,
        tuguPahlawan,
        (e) => e.$2,
      ).map((e) => e.$1).toList();
      expect(urut.last, 'tanpa posisi');
    });

    test('with no location of our own the order is left alone', () {
      final urut = urutkanTerdekat(daftar, null, (e) => e.$2);
      expect(urut.map((e) => e.$1).toList(), daftar.map((e) => e.$1).toList());
    });
  });
}
