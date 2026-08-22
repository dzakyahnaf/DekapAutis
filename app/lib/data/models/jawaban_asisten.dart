import 'package:flutter/foundation.dart';

/// What kind of thing came back from the assistant.
enum JenisJawaban {
  /// A grounded answer with at least one source.
  jawaban,

  /// The medical boundary fired (L.5). Not an error: the app working.
  batasAman,

  /// Nothing in the corpus supports an answer, or the model cited nothing.
  belumTersedia,

  /// Sources without a summary, because no model was reachable.
  modeTerbatas,
}

/// One numbered source behind an answer (L.4).
@immutable
class SumberJawaban {
  const SumberJawaban({
    required this.nomor,
    required this.judul,
    required this.penerbit,
    required this.tahun,
    required this.kutipan,
    required this.url,
    this.halaman,
  });

  factory SumberJawaban.fromMap(Map<String, dynamic> m) => SumberJawaban(
    nomor: (m['nomor'] as num).toInt(),
    judul: m['judul'] as String,
    penerbit: m['penerbit'] as String,
    tahun: (m['tahun'] as num).toInt(),
    kutipan: m['kutipan'] as String,
    url: m['url'] as String,
    halaman: (m['halaman'] as num?)?.toInt(),
  );

  final int nomor;
  final String judul;
  final String penerbit;
  final int tahun;
  final String kutipan;
  final String url;
  final int? halaman;

  /// "Kemenkes · 2024 · hlm. 12"
  String get meta =>
      [penerbit, '$tahun', if (halaman != null) 'hlm. $halaman'].join(' · ');
}

/// The safety notice payload (L.5).
@immutable
class BatasAman {
  const BatasAman({
    required this.kategori,
    required this.judul,
    required this.isi,
    required this.yangBisaDibantu,
  });

  factory BatasAman.fromMap(Map<String, dynamic> m) => BatasAman(
    kategori: m['kategori'] as String,
    judul: m['judul'] as String,
    isi: m['isi'] as String,
    yangBisaDibantu: [
      for (final s in (m['yang_bisa_dibantu'] as List? ?? const []))
        s.toString(),
    ],
  );

  final String kategori;
  final String judul;
  final String isi;

  /// What the app can do instead. A refusal must never be a dead end.
  final List<String> yangBisaDibantu;
}

@immutable
class JawabanAsisten {
  const JawabanAsisten({
    required this.jenis,
    this.teks = '',
    this.sumber = const [],
    this.jumlahDokumen = 0,
    this.modeTerbatas = false,
    this.batas,
    this.penyedia,
  });

  factory JawabanAsisten.fromMap(Map<String, dynamic> m) {
    final jenis = switch (m['jenis'] as String?) {
      'batas_aman' => JenisJawaban.batasAman,
      'belum_tersedia' => JenisJawaban.belumTersedia,
      'mode_terbatas' => JenisJawaban.modeTerbatas,
      _ => JenisJawaban.jawaban,
    };
    return JawabanAsisten(
      jenis: jenis,
      teks: (m['teks'] as String?) ?? '',
      sumber: [
        for (final s in (m['sumber'] as List? ?? const []))
          SumberJawaban.fromMap(Map<String, dynamic>.from(s as Map)),
      ],
      jumlahDokumen: (m['jumlah_dokumen'] as num?)?.toInt() ?? 0,
      modeTerbatas: (m['mode_terbatas'] as bool?) ?? false,
      batas: m['batas'] == null
          ? null
          : BatasAman.fromMap(Map<String, dynamic>.from(m['batas'] as Map)),
      penyedia: m['penyedia'] as String?,
    );
  }

  final JenisJawaban jenis;
  final String teks;
  final List<SumberJawaban> sumber;

  /// Real COUNT(*) from the database. The mockup said 148; that number is not
  /// something we can stand behind, and CLAUDE.md rule 2 forbids showing it.
  final int jumlahDokumen;

  final bool modeTerbatas;
  final BatasAman? batas;

  /// Which provider answered. Never shown to the user; useful in logs.
  final String? penyedia;
}

/// One turn in the conversation (L.3).
@immutable
class PesanPercakapan {
  const PesanPercakapan.pengguna(this.teks)
    : dariPengguna = true,
      jawaban = null;

  const PesanPercakapan.asisten(this.jawaban) : dariPengguna = false, teks = '';

  final bool dariPengguna;
  final String teks;
  final JawabanAsisten? jawaban;
}
