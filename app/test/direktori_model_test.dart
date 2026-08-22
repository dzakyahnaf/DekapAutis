import 'package:dekapautis/data/models/direktori.dart';
import 'package:dekapautis/domain/direktori/jarak.dart';
import 'package:dekapautis/domain/direktori/kota.dart';
import 'package:test/test.dart';

/// L.9 and L.10 - the parts that are arithmetic and rules rather than pixels.
void main() {
  Map<String, dynamic> baris({
    double? lat = -7.2819,
    double? lng = 112.7951,
    String nama = 'Sri Handayani',
    String spesialisasi = 'Terapis wicara',
  }) => {
    'id': 'pr1',
    'nama_lengkap': nama,
    'spesialisasi': spesialisasi,
    'terverifikasi': true,
    'gelar': 'M.Psi.',
    'layanan': ['Terapi wicara', 'Konsultasi orang tua'],
    'jadwal_praktik': [
      {'hari': 'Selasa', 'jam': '15.00-17.00'},
      {'hari': 'Kamis', 'jam': '09.00-11.00'},
    ],
    'kota': 'Surabaya',
    'lokasi_lat': lat,
    'lokasi_lng': lng,
  };

  group('a listing', () {
    test('reads its coordinates and its timetable', () {
      final p = Profesional.fromMap(baris());
      expect(p.posisi, isNotNull);
      expect(p.posisi!.lintang, closeTo(-7.2819, 0.0001));
      expect(p.jadwalPraktik, hasLength(2));
      expect(p.jadwalPraktik.first.hari, 'Selasa');
      expect(p.namaDenganGelar, 'Sri Handayani, M.Psi.');
      expect(p.inisial, 'SH');
    });

    test('a practice with no coordinates has no position, not a zero one', () {
      // Zero would place it off the coast of Africa and, worse, sort it to the
      // top of a distance-ordered list as if it were nearby.
      final p = Profesional.fromMap(baris(lat: null, lng: null));
      expect(p.posisi, isNull);
    });

    test('coordinates outside the globe are rejected, not stored', () {
      final p = Profesional.fromMap(baris(lat: 200, lng: 999));
      expect(p.posisi, isNull);
    });

    test('a one-word name still yields an initial', () {
      expect(Profesional.fromMap(baris(nama: 'Ratna')).inisial, 'R');
    });
  });

  group('the service filter', () {
    test('"Semua" matches everything', () {
      for (final s in [
        'Terapis wicara',
        'Psikolog anak',
        'Dokter tumbuh kembang',
      ]) {
        expect(JenisLayanan.semua.cocok(s), isTrue);
      }
    });

    test('a specific filter matches only its own kind', () {
      expect(JenisLayanan.terapisWicara.cocok('Terapis wicara anak'), isTrue);
      expect(JenisLayanan.terapisWicara.cocok('Psikolog anak'), isFalse);
      expect(JenisLayanan.psikologAnak.cocok('psikolog anak'), isTrue);
    });
  });

  group('where the caregiver is searching from', () {
    test('a known city resolves to a point', () {
      final surabaya = koordinatKota('Surabaya');
      expect(surabaya, isNotNull);
      expect(surabaya!.sah, isTrue);
    });

    test('case and surrounding words do not matter', () {
      expect(koordinatKota('  kota SURABAYA timur '), isNotNull);
    });

    test('an unknown city returns null rather than a guess', () {
      // The screen then says so instead of silently ordering by nothing.
      expect(koordinatKota('Wakanda'), isNull);
      expect(koordinatKota(''), isNull);
    });

    test('two known cities are the right distance apart', () {
      final surabaya = koordinatKota('Surabaya')!;
      final jakarta = koordinatKota('Jakarta')!;
      expect(jarakKm(surabaya, jakarta), closeTo(662, 15));
    });
  });

  group('ordering a real directory', () {
    test('nearest first, unknown positions last', () {
      final daftar = [
        Profesional.fromMap(
          baris(nama: 'Jauh Sekali', lat: -6.2088, lng: 106.8456),
        ),
        Profesional.fromMap(baris(nama: 'Tanpa Titik', lat: null, lng: null)),
        Profesional.fromMap(baris(nama: 'Dekat Sini')),
      ];

      final urut = urutkanTerdekat(
        daftar,
        koordinatKota('Surabaya'),
        (p) => p.posisi,
      ).map((p) => p.namaLengkap).toList();

      expect(urut, ['Dekat Sini', 'Jauh Sekali', 'Tanpa Titik']);
    });
  });

  group('a schedule request', () {
    test('carries no payment or session state, because there is none', () {
      final p = PengajuanJadwal.fromMap({
        'id': 'pj1',
        'profesional_id': 'pr1',
        'hari': 'Selasa',
        'jam': '15.00-17.00',
        'status': 'menunggu',
        'catatan': 'Bima lebih tenang sore hari.',
        'dibuat_pada': '2026-08-22T09:00:00Z',
      });

      expect(p.status, StatusPengajuan.menunggu);
      expect(p.status.label, 'Menunggu jawaban');
    });

    test('a declined request is worded as the practice being unable', () {
      // "Ditolak" reads as a judgement of the family. The practice being full
      // is not a rejection of them.
      expect(StatusPengajuan.ditolak.label, 'Belum dapat dipenuhi');
      expect(
        StatusPengajuan.ditolak.label.toLowerCase(),
        isNot(contains('tolak')),
      );
    });

    test('every status matches the database constraint', () {
      const diterima = {'menunggu', 'disetujui', 'ditolak', 'dibatalkan'};
      for (final s in StatusPengajuan.values) {
        expect(diterima, contains(s.dbValue), reason: s.label);
      }
    });
  });
}
