import 'package:flutter/foundation.dart';

/// Account role, assigned at sign-up (KF-01). Mirrors the `peran` constraint on
/// the `pengguna` table, and every RLS policy keys off it.
enum Peran {
  pengasuh('Orang tua atau pengasuh'),
  profesional('Tenaga profesional'),
  admin('Administrator');

  const Peran(this.label);

  final String label;

  String get dbValue => name;

  static Peran fromDb(String value) => Peran.values.firstWhere(
    (p) => p.name == value,
    orElse: () => Peran.pengasuh,
  );
}

/// Step 2 of onboarding. One choice only.
///
/// These describe how the child communicates today so the plan can meet them
/// there. They are not a severity scale and must never be presented as one:
/// the product does not grade a child.
enum KemampuanKomunikasi {
  belumVerbal('Belum verbal', 'belum_verbal'),
  beberapaKata('Beberapa kata', 'beberapa_kata'),
  kalimatPendek('Kalimat pendek', 'kalimat_pendek'),
  lancar('Lancar', 'lancar');

  const KemampuanKomunikasi(this.label, this.dbValue);

  final String label;
  final String dbValue;

  static KemampuanKomunikasi fromDb(String value) => KemampuanKomunikasi.values
      .firstWhere((k) => k.dbValue == value, orElse: () => beberapaKata);
}

/// Step 2, multiple choice. Drives the environment suggestions attached when
/// the adaptation engine lowers a level.
enum SensitivitasSensorik {
  suaraKeras('Suara keras', 'suara_keras'),
  cahayaTerang('Cahaya terang', 'cahaya_terang'),
  tekstur('Tekstur', 'tekstur'),
  keramaian('Keramaian', 'keramaian'),
  bau('Bau', 'bau');

  const SensitivitasSensorik(this.label, this.dbValue);

  final String label;
  final String dbValue;

  static SensitivitasSensorik? fromDb(String value) {
    for (final s in SensitivitasSensorik.values) {
      if (s.dbValue == value) return s;
    }
    return null;
  }
}

/// Step 3, multiple choice.
///
/// Deliberately plain language, no clinical terms, and no promise that any of
/// it will be reached in three months. Two entries match the wording already
/// used for the demo persona in docs/07 so the app and the proposal agree.
///
/// The list of options is a product decision and is settled. How a selection
/// maps onto categories and starting levels is decision 17 in KEPUTUSAN.md and
/// is still awaiting review before F3.
enum FokusPerkembangan {
  komunikasiEkspresif('Komunikasi ekspresif', 'komunikasi_ekspresif'),
  memahamiInstruksi('Memahami instruksi', 'memahami_instruksi'),
  rutinitasPagi('Kemandirian rutinitas pagi', 'rutinitas_pagi'),
  makanBerpakaian('Kemandirian makan dan berpakaian', 'makan_berpakaian'),
  bermainBersama('Bermain bersama anak lain', 'bermain_bersama'),
  menenangkanDiri('Menenangkan diri saat kewalahan', 'menenangkan_diri');

  const FokusPerkembangan(this.label, this.dbValue);

  final String label;
  final String dbValue;

  static FokusPerkembangan? fromDb(String value) {
    for (final f in FokusPerkembangan.values) {
      if (f.dbValue == value) return f;
    }
    return null;
  }
}

/// A child profile. One account may hold several.
@immutable
class ProfilAnak {
  const ProfilAnak({
    required this.id,
    required this.penggunaId,
    required this.namaPanggilan,
    required this.usia,
    required this.kemampuanKomunikasi,
    this.sensitivitasSensorik = const {},
    this.fokusPerkembangan = const {},
    this.dibuatPada,
  });

  factory ProfilAnak.fromMap(Map<String, dynamic> map) => ProfilAnak(
    id: map['id'] as String,
    penggunaId: map['pengguna_id'] as String,
    namaPanggilan: map['nama_panggilan'] as String,
    usia: (map['usia'] as num).toInt(),
    kemampuanKomunikasi: KemampuanKomunikasi.fromDb(
      map['kemampuan_komunikasi'] as String,
    ),
    sensitivitasSensorik: {
      for (final v
          in (map['sensitivitas_sensorik'] as List? ?? const <Object?>[]))
        ?SensitivitasSensorik.fromDb(v! as String),
    },
    fokusPerkembangan: {
      for (final v in (map['fokus_perkembangan'] as List? ?? const <Object?>[]))
        ?FokusPerkembangan.fromDb(v! as String),
    },
    dibuatPada: switch (map['dibuat_pada']) {
      final String s => DateTime.tryParse(s),
      _ => null,
    },
  );

  final String id;
  final String penggunaId;
  final String namaPanggilan;
  final int usia;
  final KemampuanKomunikasi kemampuanKomunikasi;
  final Set<SensitivitasSensorik> sensitivitasSensorik;
  final Set<FokusPerkembangan> fokusPerkembangan;
  final DateTime? dibuatPada;

  Map<String, dynamic> toInsert() => {
    'pengguna_id': penggunaId,
    'nama_panggilan': namaPanggilan,
    'usia': usia,
    'kemampuan_komunikasi': kemampuanKomunikasi.dbValue,
    'sensitivitas_sensorik': [for (final s in sensitivitasSensorik) s.dbValue],
    'fokus_perkembangan': [for (final f in fokusPerkembangan) f.dbValue],
  };
}
