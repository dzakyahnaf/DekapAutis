import 'package:dekapautis/domain/komunitas/penapis_kata.dart';
import 'package:test/test.dart';

/// Community moderation, layer one.
///
/// Tested from both sides, like the assistant lexicon. A support forum that
/// blocks ordinary sentences is not a support forum, and the people posting here
/// are worried parents writing at eleven at night - being told their post is
/// unacceptable when it was fine is its own kind of harm.
void main() {
  group('the medical boundary applies between users too', () {
    test('advice about medication is held', () {
      // A dosage passed between caregivers is no safer for having come from a
      // person rather than from the assistant.
      for (final teks in [
        'Coba kasih obat penenang sebelum tidur, anak saya cocok.',
        'Dosisnya berapa ya untuk anak 6 tahun?',
        'Saya beri melatonin 3 mg tiap malam.',
        'Suplemen apa yang bagus untuk anak spektrum?',
        'Anak saya bisa sembuh setelah terapi khelasi.',
        'Ini cara menyembuhkan autisme yang terbukti manjur.',
      ]) {
        final hasil = periksaTulisan(teks);
        expect(hasil.perluDitinjau, isTrue, reason: 'lolos: "$teks"');
        expect(hasil.kategori, KategoriModerasi.batasMedis);
      }
    });

    test('the author is told what to change, never accused', () {
      final pesan = periksaTulisan('Dosisnya berapa ya?').pesan;
      expect(pesan, contains('dokter'));
      expect(pesan, contains('Anda dapat menuliskannya kembali'));
      for (final menuduh in ['melanggar', 'dilarang', 'tidak boleh Anda']) {
        expect(pesan, isNot(contains(menuduh)));
      }
    });
  });

  group('language that demeans a child is held', () {
    test(
      'slurs are caught, including the ones used about disabled children',
      () {
        for (final teks in [
          'Anak saya memang bodoh, susah diajari.',
          'Tetangga bilang anak saya idiot.',
          'Katanya ini keterbelakangan mental.',
          'Ada yang bilang ini kutukan dari keluarga.',
          'Mereka bilang ini salah ibu yang tidak becus.',
        ]) {
          final hasil = periksaTulisan(teks);
          expect(hasil.perluDitinjau, isTrue, reason: 'lolos: "$teks"');
          expect(hasil.kategori, KategoriModerasi.kasar);
        }
      },
    );
  });

  group('ordinary posts get through', () {
    test('the posts a support forum exists for', () {
      for (final teks in [
        'Bagaimana cara membangun rutinitas pagi yang bisa diprediksi?',
        'Anak saya menutup telinga di mal, ada yang punya pengalaman serupa?',
        'Saya baru menjelaskan kondisi anak ke gurunya, ternyata lega sekali.',
        'Ada rekomendasi tempat istirahat sensorik di Surabaya?',
        'Terapi okupasi anak saya jalan tiga bulan, ini yang saya pelajari.',
        'Saya capek sekali minggu ini, boleh cerita di sini?',
        // "obat" is not always medicine, and the filter has to know that.
        'Kami pakai obat nyamuk elektrik supaya kamarnya tidak berbau.',
        'Ada rekomendasi obat nyamuk yang aman untuk anak sensitif bau?',
        'Jadwal praktiknya berapa lama biasanya?',
      ]) {
        final hasil = periksaTulisan(teks);
        expect(
          hasil.perluDitinjau,
          isFalse,
          reason: '"$teks" tertahan oleh "${hasil.frasa}" (${hasil.kategori})',
        );
      }
    });

    test('describing an experience without advising is fine', () {
      // The line is between "this is what happened to us" and "do this".
      final hasil = periksaTulisan(
        'Dokter anak kami meresepkan sesuatu dan kondisinya membaik, tapi kami '
        'tidak tahu apakah itu cocok untuk anak lain.',
      );
      expect(hasil.perluDitinjau, isFalse, reason: hasil.frasa);
    });
  });

  group('reporting', () {
    test('the matched phrase is returned so a false positive is traceable', () {
      final hasil = periksaTulisan('Dosisnya berapa ya?');
      expect(hasil.frasa, isNotNull);
      expect(hasil.frasa, isNotEmpty);
    });

    test('a post that passes carries no category or phrase', () {
      final hasil = periksaTulisan('Selamat pagi, ada yang sudah coba ini?');
      expect(hasil.kategori, isNull);
      expect(hasil.frasa, isNull);
      expect(hasil.pesan, isEmpty);
    });

    test('punctuation and capitals do not let anything slip past', () {
      expect(periksaTulisan('D O S I S').perluDitinjau, isFalse);
      expect(periksaTulisan('DOSISNYA berapa?!').perluDitinjau, isTrue);
      expect(periksaTulisan('dosis-nya berapa').perluDitinjau, isTrue);
    });
  });
}
