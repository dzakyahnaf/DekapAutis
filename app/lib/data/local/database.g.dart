// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $CacheAktivitasTable extends CacheAktivitas
    with TableInfo<$CacheAktivitasTable, CacheAktivitasData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CacheAktivitasTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kategoriMeta = const VerificationMeta(
    'kategori',
  );
  @override
  late final GeneratedColumn<String> kategori = GeneratedColumn<String>(
    'kategori',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tingkatMeta = const VerificationMeta(
    'tingkat',
  );
  @override
  late final GeneratedColumn<int> tingkat = GeneratedColumn<int>(
    'tingkat',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _judulMeta = const VerificationMeta('judul');
  @override
  late final GeneratedColumn<String> judul = GeneratedColumn<String>(
    'judul',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tujuanMeta = const VerificationMeta('tujuan');
  @override
  late final GeneratedColumn<String> tujuan = GeneratedColumn<String>(
    'tujuan',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durasiMenitMeta = const VerificationMeta(
    'durasiMenit',
  );
  @override
  late final GeneratedColumn<int> durasiMenit = GeneratedColumn<int>(
    'durasi_menit',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _alatJsonMeta = const VerificationMeta(
    'alatJson',
  );
  @override
  late final GeneratedColumn<String> alatJson = GeneratedColumn<String>(
    'alat_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _langkahJsonMeta = const VerificationMeta(
    'langkahJson',
  );
  @override
  late final GeneratedColumn<String> langkahJson = GeneratedColumn<String>(
    'langkah_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _saranLingkunganMeta = const VerificationMeta(
    'saranLingkungan',
  );
  @override
  late final GeneratedColumn<String> saranLingkungan = GeneratedColumn<String>(
    'saran_lingkungan',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    kategori,
    tingkat,
    judul,
    tujuan,
    durasiMenit,
    alatJson,
    langkahJson,
    saranLingkungan,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cache_aktivitas';
  @override
  VerificationContext validateIntegrity(
    Insertable<CacheAktivitasData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('kategori')) {
      context.handle(
        _kategoriMeta,
        kategori.isAcceptableOrUnknown(data['kategori']!, _kategoriMeta),
      );
    } else if (isInserting) {
      context.missing(_kategoriMeta);
    }
    if (data.containsKey('tingkat')) {
      context.handle(
        _tingkatMeta,
        tingkat.isAcceptableOrUnknown(data['tingkat']!, _tingkatMeta),
      );
    } else if (isInserting) {
      context.missing(_tingkatMeta);
    }
    if (data.containsKey('judul')) {
      context.handle(
        _judulMeta,
        judul.isAcceptableOrUnknown(data['judul']!, _judulMeta),
      );
    } else if (isInserting) {
      context.missing(_judulMeta);
    }
    if (data.containsKey('tujuan')) {
      context.handle(
        _tujuanMeta,
        tujuan.isAcceptableOrUnknown(data['tujuan']!, _tujuanMeta),
      );
    } else if (isInserting) {
      context.missing(_tujuanMeta);
    }
    if (data.containsKey('durasi_menit')) {
      context.handle(
        _durasiMenitMeta,
        durasiMenit.isAcceptableOrUnknown(
          data['durasi_menit']!,
          _durasiMenitMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_durasiMenitMeta);
    }
    if (data.containsKey('alat_json')) {
      context.handle(
        _alatJsonMeta,
        alatJson.isAcceptableOrUnknown(data['alat_json']!, _alatJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_alatJsonMeta);
    }
    if (data.containsKey('langkah_json')) {
      context.handle(
        _langkahJsonMeta,
        langkahJson.isAcceptableOrUnknown(
          data['langkah_json']!,
          _langkahJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_langkahJsonMeta);
    }
    if (data.containsKey('saran_lingkungan')) {
      context.handle(
        _saranLingkunganMeta,
        saranLingkungan.isAcceptableOrUnknown(
          data['saran_lingkungan']!,
          _saranLingkunganMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CacheAktivitasData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CacheAktivitasData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      kategori: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kategori'],
      )!,
      tingkat: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tingkat'],
      )!,
      judul: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}judul'],
      )!,
      tujuan: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tujuan'],
      )!,
      durasiMenit: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}durasi_menit'],
      )!,
      alatJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}alat_json'],
      )!,
      langkahJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}langkah_json'],
      )!,
      saranLingkungan: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}saran_lingkungan'],
      ),
    );
  }

  @override
  $CacheAktivitasTable createAlias(String alias) {
    return $CacheAktivitasTable(attachedDatabase, alias);
  }
}

class CacheAktivitasData extends DataClass
    implements Insertable<CacheAktivitasData> {
  final String id;
  final String kategori;
  final int tingkat;
  final String judul;
  final String tujuan;
  final int durasiMenit;
  final String alatJson;
  final String langkahJson;
  final String? saranLingkungan;
  const CacheAktivitasData({
    required this.id,
    required this.kategori,
    required this.tingkat,
    required this.judul,
    required this.tujuan,
    required this.durasiMenit,
    required this.alatJson,
    required this.langkahJson,
    this.saranLingkungan,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['kategori'] = Variable<String>(kategori);
    map['tingkat'] = Variable<int>(tingkat);
    map['judul'] = Variable<String>(judul);
    map['tujuan'] = Variable<String>(tujuan);
    map['durasi_menit'] = Variable<int>(durasiMenit);
    map['alat_json'] = Variable<String>(alatJson);
    map['langkah_json'] = Variable<String>(langkahJson);
    if (!nullToAbsent || saranLingkungan != null) {
      map['saran_lingkungan'] = Variable<String>(saranLingkungan);
    }
    return map;
  }

  CacheAktivitasCompanion toCompanion(bool nullToAbsent) {
    return CacheAktivitasCompanion(
      id: Value(id),
      kategori: Value(kategori),
      tingkat: Value(tingkat),
      judul: Value(judul),
      tujuan: Value(tujuan),
      durasiMenit: Value(durasiMenit),
      alatJson: Value(alatJson),
      langkahJson: Value(langkahJson),
      saranLingkungan: saranLingkungan == null && nullToAbsent
          ? const Value.absent()
          : Value(saranLingkungan),
    );
  }

  factory CacheAktivitasData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CacheAktivitasData(
      id: serializer.fromJson<String>(json['id']),
      kategori: serializer.fromJson<String>(json['kategori']),
      tingkat: serializer.fromJson<int>(json['tingkat']),
      judul: serializer.fromJson<String>(json['judul']),
      tujuan: serializer.fromJson<String>(json['tujuan']),
      durasiMenit: serializer.fromJson<int>(json['durasiMenit']),
      alatJson: serializer.fromJson<String>(json['alatJson']),
      langkahJson: serializer.fromJson<String>(json['langkahJson']),
      saranLingkungan: serializer.fromJson<String?>(json['saranLingkungan']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'kategori': serializer.toJson<String>(kategori),
      'tingkat': serializer.toJson<int>(tingkat),
      'judul': serializer.toJson<String>(judul),
      'tujuan': serializer.toJson<String>(tujuan),
      'durasiMenit': serializer.toJson<int>(durasiMenit),
      'alatJson': serializer.toJson<String>(alatJson),
      'langkahJson': serializer.toJson<String>(langkahJson),
      'saranLingkungan': serializer.toJson<String?>(saranLingkungan),
    };
  }

  CacheAktivitasData copyWith({
    String? id,
    String? kategori,
    int? tingkat,
    String? judul,
    String? tujuan,
    int? durasiMenit,
    String? alatJson,
    String? langkahJson,
    Value<String?> saranLingkungan = const Value.absent(),
  }) => CacheAktivitasData(
    id: id ?? this.id,
    kategori: kategori ?? this.kategori,
    tingkat: tingkat ?? this.tingkat,
    judul: judul ?? this.judul,
    tujuan: tujuan ?? this.tujuan,
    durasiMenit: durasiMenit ?? this.durasiMenit,
    alatJson: alatJson ?? this.alatJson,
    langkahJson: langkahJson ?? this.langkahJson,
    saranLingkungan: saranLingkungan.present
        ? saranLingkungan.value
        : this.saranLingkungan,
  );
  CacheAktivitasData copyWithCompanion(CacheAktivitasCompanion data) {
    return CacheAktivitasData(
      id: data.id.present ? data.id.value : this.id,
      kategori: data.kategori.present ? data.kategori.value : this.kategori,
      tingkat: data.tingkat.present ? data.tingkat.value : this.tingkat,
      judul: data.judul.present ? data.judul.value : this.judul,
      tujuan: data.tujuan.present ? data.tujuan.value : this.tujuan,
      durasiMenit: data.durasiMenit.present
          ? data.durasiMenit.value
          : this.durasiMenit,
      alatJson: data.alatJson.present ? data.alatJson.value : this.alatJson,
      langkahJson: data.langkahJson.present
          ? data.langkahJson.value
          : this.langkahJson,
      saranLingkungan: data.saranLingkungan.present
          ? data.saranLingkungan.value
          : this.saranLingkungan,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CacheAktivitasData(')
          ..write('id: $id, ')
          ..write('kategori: $kategori, ')
          ..write('tingkat: $tingkat, ')
          ..write('judul: $judul, ')
          ..write('tujuan: $tujuan, ')
          ..write('durasiMenit: $durasiMenit, ')
          ..write('alatJson: $alatJson, ')
          ..write('langkahJson: $langkahJson, ')
          ..write('saranLingkungan: $saranLingkungan')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    kategori,
    tingkat,
    judul,
    tujuan,
    durasiMenit,
    alatJson,
    langkahJson,
    saranLingkungan,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CacheAktivitasData &&
          other.id == this.id &&
          other.kategori == this.kategori &&
          other.tingkat == this.tingkat &&
          other.judul == this.judul &&
          other.tujuan == this.tujuan &&
          other.durasiMenit == this.durasiMenit &&
          other.alatJson == this.alatJson &&
          other.langkahJson == this.langkahJson &&
          other.saranLingkungan == this.saranLingkungan);
}

class CacheAktivitasCompanion extends UpdateCompanion<CacheAktivitasData> {
  final Value<String> id;
  final Value<String> kategori;
  final Value<int> tingkat;
  final Value<String> judul;
  final Value<String> tujuan;
  final Value<int> durasiMenit;
  final Value<String> alatJson;
  final Value<String> langkahJson;
  final Value<String?> saranLingkungan;
  final Value<int> rowid;
  const CacheAktivitasCompanion({
    this.id = const Value.absent(),
    this.kategori = const Value.absent(),
    this.tingkat = const Value.absent(),
    this.judul = const Value.absent(),
    this.tujuan = const Value.absent(),
    this.durasiMenit = const Value.absent(),
    this.alatJson = const Value.absent(),
    this.langkahJson = const Value.absent(),
    this.saranLingkungan = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CacheAktivitasCompanion.insert({
    required String id,
    required String kategori,
    required int tingkat,
    required String judul,
    required String tujuan,
    required int durasiMenit,
    required String alatJson,
    required String langkahJson,
    this.saranLingkungan = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       kategori = Value(kategori),
       tingkat = Value(tingkat),
       judul = Value(judul),
       tujuan = Value(tujuan),
       durasiMenit = Value(durasiMenit),
       alatJson = Value(alatJson),
       langkahJson = Value(langkahJson);
  static Insertable<CacheAktivitasData> custom({
    Expression<String>? id,
    Expression<String>? kategori,
    Expression<int>? tingkat,
    Expression<String>? judul,
    Expression<String>? tujuan,
    Expression<int>? durasiMenit,
    Expression<String>? alatJson,
    Expression<String>? langkahJson,
    Expression<String>? saranLingkungan,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (kategori != null) 'kategori': kategori,
      if (tingkat != null) 'tingkat': tingkat,
      if (judul != null) 'judul': judul,
      if (tujuan != null) 'tujuan': tujuan,
      if (durasiMenit != null) 'durasi_menit': durasiMenit,
      if (alatJson != null) 'alat_json': alatJson,
      if (langkahJson != null) 'langkah_json': langkahJson,
      if (saranLingkungan != null) 'saran_lingkungan': saranLingkungan,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CacheAktivitasCompanion copyWith({
    Value<String>? id,
    Value<String>? kategori,
    Value<int>? tingkat,
    Value<String>? judul,
    Value<String>? tujuan,
    Value<int>? durasiMenit,
    Value<String>? alatJson,
    Value<String>? langkahJson,
    Value<String?>? saranLingkungan,
    Value<int>? rowid,
  }) {
    return CacheAktivitasCompanion(
      id: id ?? this.id,
      kategori: kategori ?? this.kategori,
      tingkat: tingkat ?? this.tingkat,
      judul: judul ?? this.judul,
      tujuan: tujuan ?? this.tujuan,
      durasiMenit: durasiMenit ?? this.durasiMenit,
      alatJson: alatJson ?? this.alatJson,
      langkahJson: langkahJson ?? this.langkahJson,
      saranLingkungan: saranLingkungan ?? this.saranLingkungan,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (kategori.present) {
      map['kategori'] = Variable<String>(kategori.value);
    }
    if (tingkat.present) {
      map['tingkat'] = Variable<int>(tingkat.value);
    }
    if (judul.present) {
      map['judul'] = Variable<String>(judul.value);
    }
    if (tujuan.present) {
      map['tujuan'] = Variable<String>(tujuan.value);
    }
    if (durasiMenit.present) {
      map['durasi_menit'] = Variable<int>(durasiMenit.value);
    }
    if (alatJson.present) {
      map['alat_json'] = Variable<String>(alatJson.value);
    }
    if (langkahJson.present) {
      map['langkah_json'] = Variable<String>(langkahJson.value);
    }
    if (saranLingkungan.present) {
      map['saran_lingkungan'] = Variable<String>(saranLingkungan.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CacheAktivitasCompanion(')
          ..write('id: $id, ')
          ..write('kategori: $kategori, ')
          ..write('tingkat: $tingkat, ')
          ..write('judul: $judul, ')
          ..write('tujuan: $tujuan, ')
          ..write('durasiMenit: $durasiMenit, ')
          ..write('alatJson: $alatJson, ')
          ..write('langkahJson: $langkahJson, ')
          ..write('saranLingkungan: $saranLingkungan, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CacheJadwalTable extends CacheJadwal
    with TableInfo<$CacheJadwalTable, CacheJadwalData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CacheJadwalTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rencanaIdMeta = const VerificationMeta(
    'rencanaId',
  );
  @override
  late final GeneratedColumn<String> rencanaId = GeneratedColumn<String>(
    'rencana_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _aktivitasIdMeta = const VerificationMeta(
    'aktivitasId',
  );
  @override
  late final GeneratedColumn<String> aktivitasId = GeneratedColumn<String>(
    'aktivitas_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tanggalMeta = const VerificationMeta(
    'tanggal',
  );
  @override
  late final GeneratedColumn<DateTime> tanggal = GeneratedColumn<DateTime>(
    'tanggal',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _waktuMeta = const VerificationMeta('waktu');
  @override
  late final GeneratedColumn<String> waktu = GeneratedColumn<String>(
    'waktu',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _urutanMeta = const VerificationMeta('urutan');
  @override
  late final GeneratedColumn<int> urutan = GeneratedColumn<int>(
    'urutan',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durasiMenitMeta = const VerificationMeta(
    'durasiMenit',
  );
  @override
  late final GeneratedColumn<int> durasiMenit = GeneratedColumn<int>(
    'durasi_menit',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tingkatDisesuaikanMeta =
      const VerificationMeta('tingkatDisesuaikan');
  @override
  late final GeneratedColumn<int> tingkatDisesuaikan = GeneratedColumn<int>(
    'tingkat_disesuaikan',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    rencanaId,
    aktivitasId,
    tanggal,
    waktu,
    urutan,
    durasiMenit,
    tingkatDisesuaikan,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cache_jadwal';
  @override
  VerificationContext validateIntegrity(
    Insertable<CacheJadwalData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('rencana_id')) {
      context.handle(
        _rencanaIdMeta,
        rencanaId.isAcceptableOrUnknown(data['rencana_id']!, _rencanaIdMeta),
      );
    } else if (isInserting) {
      context.missing(_rencanaIdMeta);
    }
    if (data.containsKey('aktivitas_id')) {
      context.handle(
        _aktivitasIdMeta,
        aktivitasId.isAcceptableOrUnknown(
          data['aktivitas_id']!,
          _aktivitasIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_aktivitasIdMeta);
    }
    if (data.containsKey('tanggal')) {
      context.handle(
        _tanggalMeta,
        tanggal.isAcceptableOrUnknown(data['tanggal']!, _tanggalMeta),
      );
    } else if (isInserting) {
      context.missing(_tanggalMeta);
    }
    if (data.containsKey('waktu')) {
      context.handle(
        _waktuMeta,
        waktu.isAcceptableOrUnknown(data['waktu']!, _waktuMeta),
      );
    } else if (isInserting) {
      context.missing(_waktuMeta);
    }
    if (data.containsKey('urutan')) {
      context.handle(
        _urutanMeta,
        urutan.isAcceptableOrUnknown(data['urutan']!, _urutanMeta),
      );
    } else if (isInserting) {
      context.missing(_urutanMeta);
    }
    if (data.containsKey('durasi_menit')) {
      context.handle(
        _durasiMenitMeta,
        durasiMenit.isAcceptableOrUnknown(
          data['durasi_menit']!,
          _durasiMenitMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_durasiMenitMeta);
    }
    if (data.containsKey('tingkat_disesuaikan')) {
      context.handle(
        _tingkatDisesuaikanMeta,
        tingkatDisesuaikan.isAcceptableOrUnknown(
          data['tingkat_disesuaikan']!,
          _tingkatDisesuaikanMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_tingkatDisesuaikanMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CacheJadwalData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CacheJadwalData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      rencanaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rencana_id'],
      )!,
      aktivitasId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}aktivitas_id'],
      )!,
      tanggal: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}tanggal'],
      )!,
      waktu: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}waktu'],
      )!,
      urutan: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}urutan'],
      )!,
      durasiMenit: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}durasi_menit'],
      )!,
      tingkatDisesuaikan: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tingkat_disesuaikan'],
      )!,
    );
  }

  @override
  $CacheJadwalTable createAlias(String alias) {
    return $CacheJadwalTable(attachedDatabase, alias);
  }
}

class CacheJadwalData extends DataClass implements Insertable<CacheJadwalData> {
  final String id;
  final String rencanaId;
  final String aktivitasId;
  final DateTime tanggal;
  final String waktu;
  final int urutan;
  final int durasiMenit;
  final int tingkatDisesuaikan;
  const CacheJadwalData({
    required this.id,
    required this.rencanaId,
    required this.aktivitasId,
    required this.tanggal,
    required this.waktu,
    required this.urutan,
    required this.durasiMenit,
    required this.tingkatDisesuaikan,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['rencana_id'] = Variable<String>(rencanaId);
    map['aktivitas_id'] = Variable<String>(aktivitasId);
    map['tanggal'] = Variable<DateTime>(tanggal);
    map['waktu'] = Variable<String>(waktu);
    map['urutan'] = Variable<int>(urutan);
    map['durasi_menit'] = Variable<int>(durasiMenit);
    map['tingkat_disesuaikan'] = Variable<int>(tingkatDisesuaikan);
    return map;
  }

  CacheJadwalCompanion toCompanion(bool nullToAbsent) {
    return CacheJadwalCompanion(
      id: Value(id),
      rencanaId: Value(rencanaId),
      aktivitasId: Value(aktivitasId),
      tanggal: Value(tanggal),
      waktu: Value(waktu),
      urutan: Value(urutan),
      durasiMenit: Value(durasiMenit),
      tingkatDisesuaikan: Value(tingkatDisesuaikan),
    );
  }

  factory CacheJadwalData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CacheJadwalData(
      id: serializer.fromJson<String>(json['id']),
      rencanaId: serializer.fromJson<String>(json['rencanaId']),
      aktivitasId: serializer.fromJson<String>(json['aktivitasId']),
      tanggal: serializer.fromJson<DateTime>(json['tanggal']),
      waktu: serializer.fromJson<String>(json['waktu']),
      urutan: serializer.fromJson<int>(json['urutan']),
      durasiMenit: serializer.fromJson<int>(json['durasiMenit']),
      tingkatDisesuaikan: serializer.fromJson<int>(json['tingkatDisesuaikan']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'rencanaId': serializer.toJson<String>(rencanaId),
      'aktivitasId': serializer.toJson<String>(aktivitasId),
      'tanggal': serializer.toJson<DateTime>(tanggal),
      'waktu': serializer.toJson<String>(waktu),
      'urutan': serializer.toJson<int>(urutan),
      'durasiMenit': serializer.toJson<int>(durasiMenit),
      'tingkatDisesuaikan': serializer.toJson<int>(tingkatDisesuaikan),
    };
  }

  CacheJadwalData copyWith({
    String? id,
    String? rencanaId,
    String? aktivitasId,
    DateTime? tanggal,
    String? waktu,
    int? urutan,
    int? durasiMenit,
    int? tingkatDisesuaikan,
  }) => CacheJadwalData(
    id: id ?? this.id,
    rencanaId: rencanaId ?? this.rencanaId,
    aktivitasId: aktivitasId ?? this.aktivitasId,
    tanggal: tanggal ?? this.tanggal,
    waktu: waktu ?? this.waktu,
    urutan: urutan ?? this.urutan,
    durasiMenit: durasiMenit ?? this.durasiMenit,
    tingkatDisesuaikan: tingkatDisesuaikan ?? this.tingkatDisesuaikan,
  );
  CacheJadwalData copyWithCompanion(CacheJadwalCompanion data) {
    return CacheJadwalData(
      id: data.id.present ? data.id.value : this.id,
      rencanaId: data.rencanaId.present ? data.rencanaId.value : this.rencanaId,
      aktivitasId: data.aktivitasId.present
          ? data.aktivitasId.value
          : this.aktivitasId,
      tanggal: data.tanggal.present ? data.tanggal.value : this.tanggal,
      waktu: data.waktu.present ? data.waktu.value : this.waktu,
      urutan: data.urutan.present ? data.urutan.value : this.urutan,
      durasiMenit: data.durasiMenit.present
          ? data.durasiMenit.value
          : this.durasiMenit,
      tingkatDisesuaikan: data.tingkatDisesuaikan.present
          ? data.tingkatDisesuaikan.value
          : this.tingkatDisesuaikan,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CacheJadwalData(')
          ..write('id: $id, ')
          ..write('rencanaId: $rencanaId, ')
          ..write('aktivitasId: $aktivitasId, ')
          ..write('tanggal: $tanggal, ')
          ..write('waktu: $waktu, ')
          ..write('urutan: $urutan, ')
          ..write('durasiMenit: $durasiMenit, ')
          ..write('tingkatDisesuaikan: $tingkatDisesuaikan')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    rencanaId,
    aktivitasId,
    tanggal,
    waktu,
    urutan,
    durasiMenit,
    tingkatDisesuaikan,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CacheJadwalData &&
          other.id == this.id &&
          other.rencanaId == this.rencanaId &&
          other.aktivitasId == this.aktivitasId &&
          other.tanggal == this.tanggal &&
          other.waktu == this.waktu &&
          other.urutan == this.urutan &&
          other.durasiMenit == this.durasiMenit &&
          other.tingkatDisesuaikan == this.tingkatDisesuaikan);
}

class CacheJadwalCompanion extends UpdateCompanion<CacheJadwalData> {
  final Value<String> id;
  final Value<String> rencanaId;
  final Value<String> aktivitasId;
  final Value<DateTime> tanggal;
  final Value<String> waktu;
  final Value<int> urutan;
  final Value<int> durasiMenit;
  final Value<int> tingkatDisesuaikan;
  final Value<int> rowid;
  const CacheJadwalCompanion({
    this.id = const Value.absent(),
    this.rencanaId = const Value.absent(),
    this.aktivitasId = const Value.absent(),
    this.tanggal = const Value.absent(),
    this.waktu = const Value.absent(),
    this.urutan = const Value.absent(),
    this.durasiMenit = const Value.absent(),
    this.tingkatDisesuaikan = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CacheJadwalCompanion.insert({
    required String id,
    required String rencanaId,
    required String aktivitasId,
    required DateTime tanggal,
    required String waktu,
    required int urutan,
    required int durasiMenit,
    required int tingkatDisesuaikan,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       rencanaId = Value(rencanaId),
       aktivitasId = Value(aktivitasId),
       tanggal = Value(tanggal),
       waktu = Value(waktu),
       urutan = Value(urutan),
       durasiMenit = Value(durasiMenit),
       tingkatDisesuaikan = Value(tingkatDisesuaikan);
  static Insertable<CacheJadwalData> custom({
    Expression<String>? id,
    Expression<String>? rencanaId,
    Expression<String>? aktivitasId,
    Expression<DateTime>? tanggal,
    Expression<String>? waktu,
    Expression<int>? urutan,
    Expression<int>? durasiMenit,
    Expression<int>? tingkatDisesuaikan,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (rencanaId != null) 'rencana_id': rencanaId,
      if (aktivitasId != null) 'aktivitas_id': aktivitasId,
      if (tanggal != null) 'tanggal': tanggal,
      if (waktu != null) 'waktu': waktu,
      if (urutan != null) 'urutan': urutan,
      if (durasiMenit != null) 'durasi_menit': durasiMenit,
      if (tingkatDisesuaikan != null) 'tingkat_disesuaikan': tingkatDisesuaikan,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CacheJadwalCompanion copyWith({
    Value<String>? id,
    Value<String>? rencanaId,
    Value<String>? aktivitasId,
    Value<DateTime>? tanggal,
    Value<String>? waktu,
    Value<int>? urutan,
    Value<int>? durasiMenit,
    Value<int>? tingkatDisesuaikan,
    Value<int>? rowid,
  }) {
    return CacheJadwalCompanion(
      id: id ?? this.id,
      rencanaId: rencanaId ?? this.rencanaId,
      aktivitasId: aktivitasId ?? this.aktivitasId,
      tanggal: tanggal ?? this.tanggal,
      waktu: waktu ?? this.waktu,
      urutan: urutan ?? this.urutan,
      durasiMenit: durasiMenit ?? this.durasiMenit,
      tingkatDisesuaikan: tingkatDisesuaikan ?? this.tingkatDisesuaikan,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (rencanaId.present) {
      map['rencana_id'] = Variable<String>(rencanaId.value);
    }
    if (aktivitasId.present) {
      map['aktivitas_id'] = Variable<String>(aktivitasId.value);
    }
    if (tanggal.present) {
      map['tanggal'] = Variable<DateTime>(tanggal.value);
    }
    if (waktu.present) {
      map['waktu'] = Variable<String>(waktu.value);
    }
    if (urutan.present) {
      map['urutan'] = Variable<int>(urutan.value);
    }
    if (durasiMenit.present) {
      map['durasi_menit'] = Variable<int>(durasiMenit.value);
    }
    if (tingkatDisesuaikan.present) {
      map['tingkat_disesuaikan'] = Variable<int>(tingkatDisesuaikan.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CacheJadwalCompanion(')
          ..write('id: $id, ')
          ..write('rencanaId: $rencanaId, ')
          ..write('aktivitasId: $aktivitasId, ')
          ..write('tanggal: $tanggal, ')
          ..write('waktu: $waktu, ')
          ..write('urutan: $urutan, ')
          ..write('durasiMenit: $durasiMenit, ')
          ..write('tingkatDisesuaikan: $tingkatDisesuaikan, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CacheResponsTable extends CacheRespons
    with TableInfo<$CacheResponsTable, CacheResponsData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CacheResponsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _klienIdMeta = const VerificationMeta(
    'klienId',
  );
  @override
  late final GeneratedColumn<String> klienId = GeneratedColumn<String>(
    'klien_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _jadwalAktivitasIdMeta = const VerificationMeta(
    'jadwalAktivitasId',
  );
  @override
  late final GeneratedColumn<String> jadwalAktivitasId =
      GeneratedColumn<String>(
        'jadwal_aktivitas_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _nilaiMeta = const VerificationMeta('nilai');
  @override
  late final GeneratedColumn<String> nilai = GeneratedColumn<String>(
    'nilai',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _catatanMeta = const VerificationMeta(
    'catatan',
  );
  @override
  late final GeneratedColumn<String> catatan = GeneratedColumn<String>(
    'catatan',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dicatatPadaMeta = const VerificationMeta(
    'dicatatPada',
  );
  @override
  late final GeneratedColumn<DateTime> dicatatPada = GeneratedColumn<DateTime>(
    'dicatat_pada',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tersinkronMeta = const VerificationMeta(
    'tersinkron',
  );
  @override
  late final GeneratedColumn<bool> tersinkron = GeneratedColumn<bool>(
    'tersinkron',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("tersinkron" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _percobaanMeta = const VerificationMeta(
    'percobaan',
  );
  @override
  late final GeneratedColumn<int> percobaan = GeneratedColumn<int>(
    'percobaan',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    klienId,
    jadwalAktivitasId,
    nilai,
    catatan,
    dicatatPada,
    tersinkron,
    percobaan,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cache_respons';
  @override
  VerificationContext validateIntegrity(
    Insertable<CacheResponsData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('klien_id')) {
      context.handle(
        _klienIdMeta,
        klienId.isAcceptableOrUnknown(data['klien_id']!, _klienIdMeta),
      );
    } else if (isInserting) {
      context.missing(_klienIdMeta);
    }
    if (data.containsKey('jadwal_aktivitas_id')) {
      context.handle(
        _jadwalAktivitasIdMeta,
        jadwalAktivitasId.isAcceptableOrUnknown(
          data['jadwal_aktivitas_id']!,
          _jadwalAktivitasIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_jadwalAktivitasIdMeta);
    }
    if (data.containsKey('nilai')) {
      context.handle(
        _nilaiMeta,
        nilai.isAcceptableOrUnknown(data['nilai']!, _nilaiMeta),
      );
    } else if (isInserting) {
      context.missing(_nilaiMeta);
    }
    if (data.containsKey('catatan')) {
      context.handle(
        _catatanMeta,
        catatan.isAcceptableOrUnknown(data['catatan']!, _catatanMeta),
      );
    }
    if (data.containsKey('dicatat_pada')) {
      context.handle(
        _dicatatPadaMeta,
        dicatatPada.isAcceptableOrUnknown(
          data['dicatat_pada']!,
          _dicatatPadaMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_dicatatPadaMeta);
    }
    if (data.containsKey('tersinkron')) {
      context.handle(
        _tersinkronMeta,
        tersinkron.isAcceptableOrUnknown(data['tersinkron']!, _tersinkronMeta),
      );
    }
    if (data.containsKey('percobaan')) {
      context.handle(
        _percobaanMeta,
        percobaan.isAcceptableOrUnknown(data['percobaan']!, _percobaanMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {klienId};
  @override
  CacheResponsData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CacheResponsData(
      klienId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}klien_id'],
      )!,
      jadwalAktivitasId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}jadwal_aktivitas_id'],
      )!,
      nilai: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nilai'],
      )!,
      catatan: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}catatan'],
      ),
      dicatatPada: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}dicatat_pada'],
      )!,
      tersinkron: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}tersinkron'],
      )!,
      percobaan: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}percobaan'],
      )!,
    );
  }

  @override
  $CacheResponsTable createAlias(String alias) {
    return $CacheResponsTable(attachedDatabase, alias);
  }
}

class CacheResponsData extends DataClass
    implements Insertable<CacheResponsData> {
  /// UUID minted on the device. The server column is UNIQUE, so replaying a
  /// queued write can never produce a second row - that is the whole of the
  /// idempotency guarantee, and it lives in the database rather than in
  /// carefully written client code.
  final String klienId;
  final String jadwalAktivitasId;
  final String nilai;
  final String? catatan;
  final DateTime dicatatPada;
  final bool tersinkron;
  final int percobaan;
  const CacheResponsData({
    required this.klienId,
    required this.jadwalAktivitasId,
    required this.nilai,
    this.catatan,
    required this.dicatatPada,
    required this.tersinkron,
    required this.percobaan,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['klien_id'] = Variable<String>(klienId);
    map['jadwal_aktivitas_id'] = Variable<String>(jadwalAktivitasId);
    map['nilai'] = Variable<String>(nilai);
    if (!nullToAbsent || catatan != null) {
      map['catatan'] = Variable<String>(catatan);
    }
    map['dicatat_pada'] = Variable<DateTime>(dicatatPada);
    map['tersinkron'] = Variable<bool>(tersinkron);
    map['percobaan'] = Variable<int>(percobaan);
    return map;
  }

  CacheResponsCompanion toCompanion(bool nullToAbsent) {
    return CacheResponsCompanion(
      klienId: Value(klienId),
      jadwalAktivitasId: Value(jadwalAktivitasId),
      nilai: Value(nilai),
      catatan: catatan == null && nullToAbsent
          ? const Value.absent()
          : Value(catatan),
      dicatatPada: Value(dicatatPada),
      tersinkron: Value(tersinkron),
      percobaan: Value(percobaan),
    );
  }

  factory CacheResponsData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CacheResponsData(
      klienId: serializer.fromJson<String>(json['klienId']),
      jadwalAktivitasId: serializer.fromJson<String>(json['jadwalAktivitasId']),
      nilai: serializer.fromJson<String>(json['nilai']),
      catatan: serializer.fromJson<String?>(json['catatan']),
      dicatatPada: serializer.fromJson<DateTime>(json['dicatatPada']),
      tersinkron: serializer.fromJson<bool>(json['tersinkron']),
      percobaan: serializer.fromJson<int>(json['percobaan']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'klienId': serializer.toJson<String>(klienId),
      'jadwalAktivitasId': serializer.toJson<String>(jadwalAktivitasId),
      'nilai': serializer.toJson<String>(nilai),
      'catatan': serializer.toJson<String?>(catatan),
      'dicatatPada': serializer.toJson<DateTime>(dicatatPada),
      'tersinkron': serializer.toJson<bool>(tersinkron),
      'percobaan': serializer.toJson<int>(percobaan),
    };
  }

  CacheResponsData copyWith({
    String? klienId,
    String? jadwalAktivitasId,
    String? nilai,
    Value<String?> catatan = const Value.absent(),
    DateTime? dicatatPada,
    bool? tersinkron,
    int? percobaan,
  }) => CacheResponsData(
    klienId: klienId ?? this.klienId,
    jadwalAktivitasId: jadwalAktivitasId ?? this.jadwalAktivitasId,
    nilai: nilai ?? this.nilai,
    catatan: catatan.present ? catatan.value : this.catatan,
    dicatatPada: dicatatPada ?? this.dicatatPada,
    tersinkron: tersinkron ?? this.tersinkron,
    percobaan: percobaan ?? this.percobaan,
  );
  CacheResponsData copyWithCompanion(CacheResponsCompanion data) {
    return CacheResponsData(
      klienId: data.klienId.present ? data.klienId.value : this.klienId,
      jadwalAktivitasId: data.jadwalAktivitasId.present
          ? data.jadwalAktivitasId.value
          : this.jadwalAktivitasId,
      nilai: data.nilai.present ? data.nilai.value : this.nilai,
      catatan: data.catatan.present ? data.catatan.value : this.catatan,
      dicatatPada: data.dicatatPada.present
          ? data.dicatatPada.value
          : this.dicatatPada,
      tersinkron: data.tersinkron.present
          ? data.tersinkron.value
          : this.tersinkron,
      percobaan: data.percobaan.present ? data.percobaan.value : this.percobaan,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CacheResponsData(')
          ..write('klienId: $klienId, ')
          ..write('jadwalAktivitasId: $jadwalAktivitasId, ')
          ..write('nilai: $nilai, ')
          ..write('catatan: $catatan, ')
          ..write('dicatatPada: $dicatatPada, ')
          ..write('tersinkron: $tersinkron, ')
          ..write('percobaan: $percobaan')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    klienId,
    jadwalAktivitasId,
    nilai,
    catatan,
    dicatatPada,
    tersinkron,
    percobaan,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CacheResponsData &&
          other.klienId == this.klienId &&
          other.jadwalAktivitasId == this.jadwalAktivitasId &&
          other.nilai == this.nilai &&
          other.catatan == this.catatan &&
          other.dicatatPada == this.dicatatPada &&
          other.tersinkron == this.tersinkron &&
          other.percobaan == this.percobaan);
}

class CacheResponsCompanion extends UpdateCompanion<CacheResponsData> {
  final Value<String> klienId;
  final Value<String> jadwalAktivitasId;
  final Value<String> nilai;
  final Value<String?> catatan;
  final Value<DateTime> dicatatPada;
  final Value<bool> tersinkron;
  final Value<int> percobaan;
  final Value<int> rowid;
  const CacheResponsCompanion({
    this.klienId = const Value.absent(),
    this.jadwalAktivitasId = const Value.absent(),
    this.nilai = const Value.absent(),
    this.catatan = const Value.absent(),
    this.dicatatPada = const Value.absent(),
    this.tersinkron = const Value.absent(),
    this.percobaan = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CacheResponsCompanion.insert({
    required String klienId,
    required String jadwalAktivitasId,
    required String nilai,
    this.catatan = const Value.absent(),
    required DateTime dicatatPada,
    this.tersinkron = const Value.absent(),
    this.percobaan = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : klienId = Value(klienId),
       jadwalAktivitasId = Value(jadwalAktivitasId),
       nilai = Value(nilai),
       dicatatPada = Value(dicatatPada);
  static Insertable<CacheResponsData> custom({
    Expression<String>? klienId,
    Expression<String>? jadwalAktivitasId,
    Expression<String>? nilai,
    Expression<String>? catatan,
    Expression<DateTime>? dicatatPada,
    Expression<bool>? tersinkron,
    Expression<int>? percobaan,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (klienId != null) 'klien_id': klienId,
      if (jadwalAktivitasId != null) 'jadwal_aktivitas_id': jadwalAktivitasId,
      if (nilai != null) 'nilai': nilai,
      if (catatan != null) 'catatan': catatan,
      if (dicatatPada != null) 'dicatat_pada': dicatatPada,
      if (tersinkron != null) 'tersinkron': tersinkron,
      if (percobaan != null) 'percobaan': percobaan,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CacheResponsCompanion copyWith({
    Value<String>? klienId,
    Value<String>? jadwalAktivitasId,
    Value<String>? nilai,
    Value<String?>? catatan,
    Value<DateTime>? dicatatPada,
    Value<bool>? tersinkron,
    Value<int>? percobaan,
    Value<int>? rowid,
  }) {
    return CacheResponsCompanion(
      klienId: klienId ?? this.klienId,
      jadwalAktivitasId: jadwalAktivitasId ?? this.jadwalAktivitasId,
      nilai: nilai ?? this.nilai,
      catatan: catatan ?? this.catatan,
      dicatatPada: dicatatPada ?? this.dicatatPada,
      tersinkron: tersinkron ?? this.tersinkron,
      percobaan: percobaan ?? this.percobaan,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (klienId.present) {
      map['klien_id'] = Variable<String>(klienId.value);
    }
    if (jadwalAktivitasId.present) {
      map['jadwal_aktivitas_id'] = Variable<String>(jadwalAktivitasId.value);
    }
    if (nilai.present) {
      map['nilai'] = Variable<String>(nilai.value);
    }
    if (catatan.present) {
      map['catatan'] = Variable<String>(catatan.value);
    }
    if (dicatatPada.present) {
      map['dicatat_pada'] = Variable<DateTime>(dicatatPada.value);
    }
    if (tersinkron.present) {
      map['tersinkron'] = Variable<bool>(tersinkron.value);
    }
    if (percobaan.present) {
      map['percobaan'] = Variable<int>(percobaan.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CacheResponsCompanion(')
          ..write('klienId: $klienId, ')
          ..write('jadwalAktivitasId: $jadwalAktivitasId, ')
          ..write('nilai: $nilai, ')
          ..write('catatan: $catatan, ')
          ..write('dicatatPada: $dicatatPada, ')
          ..write('tersinkron: $tersinkron, ')
          ..write('percobaan: $percobaan, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CacheCheckInTable extends CacheCheckIn
    with TableInfo<$CacheCheckInTable, CacheCheckInData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CacheCheckInTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _klienIdMeta = const VerificationMeta(
    'klienId',
  );
  @override
  late final GeneratedColumn<String> klienId = GeneratedColumn<String>(
    'klien_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tanggalMeta = const VerificationMeta(
    'tanggal',
  );
  @override
  late final GeneratedColumn<DateTime> tanggal = GeneratedColumn<DateTime>(
    'tanggal',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kondisiMeta = const VerificationMeta(
    'kondisi',
  );
  @override
  late final GeneratedColumn<int> kondisi = GeneratedColumn<int>(
    'kondisi',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tersinkronMeta = const VerificationMeta(
    'tersinkron',
  );
  @override
  late final GeneratedColumn<bool> tersinkron = GeneratedColumn<bool>(
    'tersinkron',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("tersinkron" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _percobaanMeta = const VerificationMeta(
    'percobaan',
  );
  @override
  late final GeneratedColumn<int> percobaan = GeneratedColumn<int>(
    'percobaan',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    klienId,
    tanggal,
    kondisi,
    tersinkron,
    percobaan,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cache_check_in';
  @override
  VerificationContext validateIntegrity(
    Insertable<CacheCheckInData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('klien_id')) {
      context.handle(
        _klienIdMeta,
        klienId.isAcceptableOrUnknown(data['klien_id']!, _klienIdMeta),
      );
    } else if (isInserting) {
      context.missing(_klienIdMeta);
    }
    if (data.containsKey('tanggal')) {
      context.handle(
        _tanggalMeta,
        tanggal.isAcceptableOrUnknown(data['tanggal']!, _tanggalMeta),
      );
    } else if (isInserting) {
      context.missing(_tanggalMeta);
    }
    if (data.containsKey('kondisi')) {
      context.handle(
        _kondisiMeta,
        kondisi.isAcceptableOrUnknown(data['kondisi']!, _kondisiMeta),
      );
    } else if (isInserting) {
      context.missing(_kondisiMeta);
    }
    if (data.containsKey('tersinkron')) {
      context.handle(
        _tersinkronMeta,
        tersinkron.isAcceptableOrUnknown(data['tersinkron']!, _tersinkronMeta),
      );
    }
    if (data.containsKey('percobaan')) {
      context.handle(
        _percobaanMeta,
        percobaan.isAcceptableOrUnknown(data['percobaan']!, _percobaanMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {klienId};
  @override
  CacheCheckInData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CacheCheckInData(
      klienId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}klien_id'],
      )!,
      tanggal: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}tanggal'],
      )!,
      kondisi: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}kondisi'],
      )!,
      tersinkron: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}tersinkron'],
      )!,
      percobaan: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}percobaan'],
      )!,
    );
  }

  @override
  $CacheCheckInTable createAlias(String alias) {
    return $CacheCheckInTable(attachedDatabase, alias);
  }
}

class CacheCheckInData extends DataClass
    implements Insertable<CacheCheckInData> {
  final String klienId;
  final DateTime tanggal;
  final int kondisi;
  final bool tersinkron;
  final int percobaan;
  const CacheCheckInData({
    required this.klienId,
    required this.tanggal,
    required this.kondisi,
    required this.tersinkron,
    required this.percobaan,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['klien_id'] = Variable<String>(klienId);
    map['tanggal'] = Variable<DateTime>(tanggal);
    map['kondisi'] = Variable<int>(kondisi);
    map['tersinkron'] = Variable<bool>(tersinkron);
    map['percobaan'] = Variable<int>(percobaan);
    return map;
  }

  CacheCheckInCompanion toCompanion(bool nullToAbsent) {
    return CacheCheckInCompanion(
      klienId: Value(klienId),
      tanggal: Value(tanggal),
      kondisi: Value(kondisi),
      tersinkron: Value(tersinkron),
      percobaan: Value(percobaan),
    );
  }

  factory CacheCheckInData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CacheCheckInData(
      klienId: serializer.fromJson<String>(json['klienId']),
      tanggal: serializer.fromJson<DateTime>(json['tanggal']),
      kondisi: serializer.fromJson<int>(json['kondisi']),
      tersinkron: serializer.fromJson<bool>(json['tersinkron']),
      percobaan: serializer.fromJson<int>(json['percobaan']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'klienId': serializer.toJson<String>(klienId),
      'tanggal': serializer.toJson<DateTime>(tanggal),
      'kondisi': serializer.toJson<int>(kondisi),
      'tersinkron': serializer.toJson<bool>(tersinkron),
      'percobaan': serializer.toJson<int>(percobaan),
    };
  }

  CacheCheckInData copyWith({
    String? klienId,
    DateTime? tanggal,
    int? kondisi,
    bool? tersinkron,
    int? percobaan,
  }) => CacheCheckInData(
    klienId: klienId ?? this.klienId,
    tanggal: tanggal ?? this.tanggal,
    kondisi: kondisi ?? this.kondisi,
    tersinkron: tersinkron ?? this.tersinkron,
    percobaan: percobaan ?? this.percobaan,
  );
  CacheCheckInData copyWithCompanion(CacheCheckInCompanion data) {
    return CacheCheckInData(
      klienId: data.klienId.present ? data.klienId.value : this.klienId,
      tanggal: data.tanggal.present ? data.tanggal.value : this.tanggal,
      kondisi: data.kondisi.present ? data.kondisi.value : this.kondisi,
      tersinkron: data.tersinkron.present
          ? data.tersinkron.value
          : this.tersinkron,
      percobaan: data.percobaan.present ? data.percobaan.value : this.percobaan,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CacheCheckInData(')
          ..write('klienId: $klienId, ')
          ..write('tanggal: $tanggal, ')
          ..write('kondisi: $kondisi, ')
          ..write('tersinkron: $tersinkron, ')
          ..write('percobaan: $percobaan')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(klienId, tanggal, kondisi, tersinkron, percobaan);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CacheCheckInData &&
          other.klienId == this.klienId &&
          other.tanggal == this.tanggal &&
          other.kondisi == this.kondisi &&
          other.tersinkron == this.tersinkron &&
          other.percobaan == this.percobaan);
}

class CacheCheckInCompanion extends UpdateCompanion<CacheCheckInData> {
  final Value<String> klienId;
  final Value<DateTime> tanggal;
  final Value<int> kondisi;
  final Value<bool> tersinkron;
  final Value<int> percobaan;
  final Value<int> rowid;
  const CacheCheckInCompanion({
    this.klienId = const Value.absent(),
    this.tanggal = const Value.absent(),
    this.kondisi = const Value.absent(),
    this.tersinkron = const Value.absent(),
    this.percobaan = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CacheCheckInCompanion.insert({
    required String klienId,
    required DateTime tanggal,
    required int kondisi,
    this.tersinkron = const Value.absent(),
    this.percobaan = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : klienId = Value(klienId),
       tanggal = Value(tanggal),
       kondisi = Value(kondisi);
  static Insertable<CacheCheckInData> custom({
    Expression<String>? klienId,
    Expression<DateTime>? tanggal,
    Expression<int>? kondisi,
    Expression<bool>? tersinkron,
    Expression<int>? percobaan,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (klienId != null) 'klien_id': klienId,
      if (tanggal != null) 'tanggal': tanggal,
      if (kondisi != null) 'kondisi': kondisi,
      if (tersinkron != null) 'tersinkron': tersinkron,
      if (percobaan != null) 'percobaan': percobaan,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CacheCheckInCompanion copyWith({
    Value<String>? klienId,
    Value<DateTime>? tanggal,
    Value<int>? kondisi,
    Value<bool>? tersinkron,
    Value<int>? percobaan,
    Value<int>? rowid,
  }) {
    return CacheCheckInCompanion(
      klienId: klienId ?? this.klienId,
      tanggal: tanggal ?? this.tanggal,
      kondisi: kondisi ?? this.kondisi,
      tersinkron: tersinkron ?? this.tersinkron,
      percobaan: percobaan ?? this.percobaan,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (klienId.present) {
      map['klien_id'] = Variable<String>(klienId.value);
    }
    if (tanggal.present) {
      map['tanggal'] = Variable<DateTime>(tanggal.value);
    }
    if (kondisi.present) {
      map['kondisi'] = Variable<int>(kondisi.value);
    }
    if (tersinkron.present) {
      map['tersinkron'] = Variable<bool>(tersinkron.value);
    }
    if (percobaan.present) {
      map['percobaan'] = Variable<int>(percobaan.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CacheCheckInCompanion(')
          ..write('klienId: $klienId, ')
          ..write('tanggal: $tanggal, ')
          ..write('kondisi: $kondisi, ')
          ..write('tersinkron: $tersinkron, ')
          ..write('percobaan: $percobaan, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PreferensiTable extends Preferensi
    with TableInfo<$PreferensiTable, PreferensiData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PreferensiTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _kunciMeta = const VerificationMeta('kunci');
  @override
  late final GeneratedColumn<String> kunci = GeneratedColumn<String>(
    'kunci',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nilaiMeta = const VerificationMeta('nilai');
  @override
  late final GeneratedColumn<String> nilai = GeneratedColumn<String>(
    'nilai',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [kunci, nilai];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'preferensi';
  @override
  VerificationContext validateIntegrity(
    Insertable<PreferensiData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('kunci')) {
      context.handle(
        _kunciMeta,
        kunci.isAcceptableOrUnknown(data['kunci']!, _kunciMeta),
      );
    } else if (isInserting) {
      context.missing(_kunciMeta);
    }
    if (data.containsKey('nilai')) {
      context.handle(
        _nilaiMeta,
        nilai.isAcceptableOrUnknown(data['nilai']!, _nilaiMeta),
      );
    } else if (isInserting) {
      context.missing(_nilaiMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {kunci};
  @override
  PreferensiData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PreferensiData(
      kunci: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kunci'],
      )!,
      nilai: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nilai'],
      )!,
    );
  }

  @override
  $PreferensiTable createAlias(String alias) {
    return $PreferensiTable(attachedDatabase, alias);
  }
}

class PreferensiData extends DataClass implements Insertable<PreferensiData> {
  final String kunci;
  final String nilai;
  const PreferensiData({required this.kunci, required this.nilai});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['kunci'] = Variable<String>(kunci);
    map['nilai'] = Variable<String>(nilai);
    return map;
  }

  PreferensiCompanion toCompanion(bool nullToAbsent) {
    return PreferensiCompanion(kunci: Value(kunci), nilai: Value(nilai));
  }

  factory PreferensiData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PreferensiData(
      kunci: serializer.fromJson<String>(json['kunci']),
      nilai: serializer.fromJson<String>(json['nilai']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'kunci': serializer.toJson<String>(kunci),
      'nilai': serializer.toJson<String>(nilai),
    };
  }

  PreferensiData copyWith({String? kunci, String? nilai}) =>
      PreferensiData(kunci: kunci ?? this.kunci, nilai: nilai ?? this.nilai);
  PreferensiData copyWithCompanion(PreferensiCompanion data) {
    return PreferensiData(
      kunci: data.kunci.present ? data.kunci.value : this.kunci,
      nilai: data.nilai.present ? data.nilai.value : this.nilai,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PreferensiData(')
          ..write('kunci: $kunci, ')
          ..write('nilai: $nilai')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(kunci, nilai);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PreferensiData &&
          other.kunci == this.kunci &&
          other.nilai == this.nilai);
}

class PreferensiCompanion extends UpdateCompanion<PreferensiData> {
  final Value<String> kunci;
  final Value<String> nilai;
  final Value<int> rowid;
  const PreferensiCompanion({
    this.kunci = const Value.absent(),
    this.nilai = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PreferensiCompanion.insert({
    required String kunci,
    required String nilai,
    this.rowid = const Value.absent(),
  }) : kunci = Value(kunci),
       nilai = Value(nilai);
  static Insertable<PreferensiData> custom({
    Expression<String>? kunci,
    Expression<String>? nilai,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (kunci != null) 'kunci': kunci,
      if (nilai != null) 'nilai': nilai,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PreferensiCompanion copyWith({
    Value<String>? kunci,
    Value<String>? nilai,
    Value<int>? rowid,
  }) {
    return PreferensiCompanion(
      kunci: kunci ?? this.kunci,
      nilai: nilai ?? this.nilai,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (kunci.present) {
      map['kunci'] = Variable<String>(kunci.value);
    }
    if (nilai.present) {
      map['nilai'] = Variable<String>(nilai.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PreferensiCompanion(')
          ..write('kunci: $kunci, ')
          ..write('nilai: $nilai, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$DekapDatabase extends GeneratedDatabase {
  _$DekapDatabase(QueryExecutor e) : super(e);
  $DekapDatabaseManager get managers => $DekapDatabaseManager(this);
  late final $CacheAktivitasTable cacheAktivitas = $CacheAktivitasTable(this);
  late final $CacheJadwalTable cacheJadwal = $CacheJadwalTable(this);
  late final $CacheResponsTable cacheRespons = $CacheResponsTable(this);
  late final $CacheCheckInTable cacheCheckIn = $CacheCheckInTable(this);
  late final $PreferensiTable preferensi = $PreferensiTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    cacheAktivitas,
    cacheJadwal,
    cacheRespons,
    cacheCheckIn,
    preferensi,
  ];
}

typedef $$CacheAktivitasTableCreateCompanionBuilder =
    CacheAktivitasCompanion Function({
      required String id,
      required String kategori,
      required int tingkat,
      required String judul,
      required String tujuan,
      required int durasiMenit,
      required String alatJson,
      required String langkahJson,
      Value<String?> saranLingkungan,
      Value<int> rowid,
    });
typedef $$CacheAktivitasTableUpdateCompanionBuilder =
    CacheAktivitasCompanion Function({
      Value<String> id,
      Value<String> kategori,
      Value<int> tingkat,
      Value<String> judul,
      Value<String> tujuan,
      Value<int> durasiMenit,
      Value<String> alatJson,
      Value<String> langkahJson,
      Value<String?> saranLingkungan,
      Value<int> rowid,
    });

class $$CacheAktivitasTableFilterComposer
    extends Composer<_$DekapDatabase, $CacheAktivitasTable> {
  $$CacheAktivitasTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kategori => $composableBuilder(
    column: $table.kategori,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tingkat => $composableBuilder(
    column: $table.tingkat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get judul => $composableBuilder(
    column: $table.judul,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tujuan => $composableBuilder(
    column: $table.tujuan,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durasiMenit => $composableBuilder(
    column: $table.durasiMenit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get alatJson => $composableBuilder(
    column: $table.alatJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get langkahJson => $composableBuilder(
    column: $table.langkahJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get saranLingkungan => $composableBuilder(
    column: $table.saranLingkungan,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CacheAktivitasTableOrderingComposer
    extends Composer<_$DekapDatabase, $CacheAktivitasTable> {
  $$CacheAktivitasTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kategori => $composableBuilder(
    column: $table.kategori,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tingkat => $composableBuilder(
    column: $table.tingkat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get judul => $composableBuilder(
    column: $table.judul,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tujuan => $composableBuilder(
    column: $table.tujuan,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durasiMenit => $composableBuilder(
    column: $table.durasiMenit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get alatJson => $composableBuilder(
    column: $table.alatJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get langkahJson => $composableBuilder(
    column: $table.langkahJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get saranLingkungan => $composableBuilder(
    column: $table.saranLingkungan,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CacheAktivitasTableAnnotationComposer
    extends Composer<_$DekapDatabase, $CacheAktivitasTable> {
  $$CacheAktivitasTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get kategori =>
      $composableBuilder(column: $table.kategori, builder: (column) => column);

  GeneratedColumn<int> get tingkat =>
      $composableBuilder(column: $table.tingkat, builder: (column) => column);

  GeneratedColumn<String> get judul =>
      $composableBuilder(column: $table.judul, builder: (column) => column);

  GeneratedColumn<String> get tujuan =>
      $composableBuilder(column: $table.tujuan, builder: (column) => column);

  GeneratedColumn<int> get durasiMenit => $composableBuilder(
    column: $table.durasiMenit,
    builder: (column) => column,
  );

  GeneratedColumn<String> get alatJson =>
      $composableBuilder(column: $table.alatJson, builder: (column) => column);

  GeneratedColumn<String> get langkahJson => $composableBuilder(
    column: $table.langkahJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get saranLingkungan => $composableBuilder(
    column: $table.saranLingkungan,
    builder: (column) => column,
  );
}

class $$CacheAktivitasTableTableManager
    extends
        RootTableManager<
          _$DekapDatabase,
          $CacheAktivitasTable,
          CacheAktivitasData,
          $$CacheAktivitasTableFilterComposer,
          $$CacheAktivitasTableOrderingComposer,
          $$CacheAktivitasTableAnnotationComposer,
          $$CacheAktivitasTableCreateCompanionBuilder,
          $$CacheAktivitasTableUpdateCompanionBuilder,
          (
            CacheAktivitasData,
            BaseReferences<
              _$DekapDatabase,
              $CacheAktivitasTable,
              CacheAktivitasData
            >,
          ),
          CacheAktivitasData,
          PrefetchHooks Function()
        > {
  $$CacheAktivitasTableTableManager(
    _$DekapDatabase db,
    $CacheAktivitasTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CacheAktivitasTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CacheAktivitasTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CacheAktivitasTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> kategori = const Value.absent(),
                Value<int> tingkat = const Value.absent(),
                Value<String> judul = const Value.absent(),
                Value<String> tujuan = const Value.absent(),
                Value<int> durasiMenit = const Value.absent(),
                Value<String> alatJson = const Value.absent(),
                Value<String> langkahJson = const Value.absent(),
                Value<String?> saranLingkungan = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CacheAktivitasCompanion(
                id: id,
                kategori: kategori,
                tingkat: tingkat,
                judul: judul,
                tujuan: tujuan,
                durasiMenit: durasiMenit,
                alatJson: alatJson,
                langkahJson: langkahJson,
                saranLingkungan: saranLingkungan,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String kategori,
                required int tingkat,
                required String judul,
                required String tujuan,
                required int durasiMenit,
                required String alatJson,
                required String langkahJson,
                Value<String?> saranLingkungan = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CacheAktivitasCompanion.insert(
                id: id,
                kategori: kategori,
                tingkat: tingkat,
                judul: judul,
                tujuan: tujuan,
                durasiMenit: durasiMenit,
                alatJson: alatJson,
                langkahJson: langkahJson,
                saranLingkungan: saranLingkungan,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CacheAktivitasTableProcessedTableManager =
    ProcessedTableManager<
      _$DekapDatabase,
      $CacheAktivitasTable,
      CacheAktivitasData,
      $$CacheAktivitasTableFilterComposer,
      $$CacheAktivitasTableOrderingComposer,
      $$CacheAktivitasTableAnnotationComposer,
      $$CacheAktivitasTableCreateCompanionBuilder,
      $$CacheAktivitasTableUpdateCompanionBuilder,
      (
        CacheAktivitasData,
        BaseReferences<
          _$DekapDatabase,
          $CacheAktivitasTable,
          CacheAktivitasData
        >,
      ),
      CacheAktivitasData,
      PrefetchHooks Function()
    >;
typedef $$CacheJadwalTableCreateCompanionBuilder =
    CacheJadwalCompanion Function({
      required String id,
      required String rencanaId,
      required String aktivitasId,
      required DateTime tanggal,
      required String waktu,
      required int urutan,
      required int durasiMenit,
      required int tingkatDisesuaikan,
      Value<int> rowid,
    });
typedef $$CacheJadwalTableUpdateCompanionBuilder =
    CacheJadwalCompanion Function({
      Value<String> id,
      Value<String> rencanaId,
      Value<String> aktivitasId,
      Value<DateTime> tanggal,
      Value<String> waktu,
      Value<int> urutan,
      Value<int> durasiMenit,
      Value<int> tingkatDisesuaikan,
      Value<int> rowid,
    });

class $$CacheJadwalTableFilterComposer
    extends Composer<_$DekapDatabase, $CacheJadwalTable> {
  $$CacheJadwalTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rencanaId => $composableBuilder(
    column: $table.rencanaId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get aktivitasId => $composableBuilder(
    column: $table.aktivitasId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get tanggal => $composableBuilder(
    column: $table.tanggal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get waktu => $composableBuilder(
    column: $table.waktu,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get urutan => $composableBuilder(
    column: $table.urutan,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durasiMenit => $composableBuilder(
    column: $table.durasiMenit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tingkatDisesuaikan => $composableBuilder(
    column: $table.tingkatDisesuaikan,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CacheJadwalTableOrderingComposer
    extends Composer<_$DekapDatabase, $CacheJadwalTable> {
  $$CacheJadwalTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rencanaId => $composableBuilder(
    column: $table.rencanaId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get aktivitasId => $composableBuilder(
    column: $table.aktivitasId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get tanggal => $composableBuilder(
    column: $table.tanggal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get waktu => $composableBuilder(
    column: $table.waktu,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get urutan => $composableBuilder(
    column: $table.urutan,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durasiMenit => $composableBuilder(
    column: $table.durasiMenit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tingkatDisesuaikan => $composableBuilder(
    column: $table.tingkatDisesuaikan,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CacheJadwalTableAnnotationComposer
    extends Composer<_$DekapDatabase, $CacheJadwalTable> {
  $$CacheJadwalTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get rencanaId =>
      $composableBuilder(column: $table.rencanaId, builder: (column) => column);

  GeneratedColumn<String> get aktivitasId => $composableBuilder(
    column: $table.aktivitasId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get tanggal =>
      $composableBuilder(column: $table.tanggal, builder: (column) => column);

  GeneratedColumn<String> get waktu =>
      $composableBuilder(column: $table.waktu, builder: (column) => column);

  GeneratedColumn<int> get urutan =>
      $composableBuilder(column: $table.urutan, builder: (column) => column);

  GeneratedColumn<int> get durasiMenit => $composableBuilder(
    column: $table.durasiMenit,
    builder: (column) => column,
  );

  GeneratedColumn<int> get tingkatDisesuaikan => $composableBuilder(
    column: $table.tingkatDisesuaikan,
    builder: (column) => column,
  );
}

class $$CacheJadwalTableTableManager
    extends
        RootTableManager<
          _$DekapDatabase,
          $CacheJadwalTable,
          CacheJadwalData,
          $$CacheJadwalTableFilterComposer,
          $$CacheJadwalTableOrderingComposer,
          $$CacheJadwalTableAnnotationComposer,
          $$CacheJadwalTableCreateCompanionBuilder,
          $$CacheJadwalTableUpdateCompanionBuilder,
          (
            CacheJadwalData,
            BaseReferences<_$DekapDatabase, $CacheJadwalTable, CacheJadwalData>,
          ),
          CacheJadwalData,
          PrefetchHooks Function()
        > {
  $$CacheJadwalTableTableManager(_$DekapDatabase db, $CacheJadwalTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CacheJadwalTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CacheJadwalTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CacheJadwalTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> rencanaId = const Value.absent(),
                Value<String> aktivitasId = const Value.absent(),
                Value<DateTime> tanggal = const Value.absent(),
                Value<String> waktu = const Value.absent(),
                Value<int> urutan = const Value.absent(),
                Value<int> durasiMenit = const Value.absent(),
                Value<int> tingkatDisesuaikan = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CacheJadwalCompanion(
                id: id,
                rencanaId: rencanaId,
                aktivitasId: aktivitasId,
                tanggal: tanggal,
                waktu: waktu,
                urutan: urutan,
                durasiMenit: durasiMenit,
                tingkatDisesuaikan: tingkatDisesuaikan,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String rencanaId,
                required String aktivitasId,
                required DateTime tanggal,
                required String waktu,
                required int urutan,
                required int durasiMenit,
                required int tingkatDisesuaikan,
                Value<int> rowid = const Value.absent(),
              }) => CacheJadwalCompanion.insert(
                id: id,
                rencanaId: rencanaId,
                aktivitasId: aktivitasId,
                tanggal: tanggal,
                waktu: waktu,
                urutan: urutan,
                durasiMenit: durasiMenit,
                tingkatDisesuaikan: tingkatDisesuaikan,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CacheJadwalTableProcessedTableManager =
    ProcessedTableManager<
      _$DekapDatabase,
      $CacheJadwalTable,
      CacheJadwalData,
      $$CacheJadwalTableFilterComposer,
      $$CacheJadwalTableOrderingComposer,
      $$CacheJadwalTableAnnotationComposer,
      $$CacheJadwalTableCreateCompanionBuilder,
      $$CacheJadwalTableUpdateCompanionBuilder,
      (
        CacheJadwalData,
        BaseReferences<_$DekapDatabase, $CacheJadwalTable, CacheJadwalData>,
      ),
      CacheJadwalData,
      PrefetchHooks Function()
    >;
typedef $$CacheResponsTableCreateCompanionBuilder =
    CacheResponsCompanion Function({
      required String klienId,
      required String jadwalAktivitasId,
      required String nilai,
      Value<String?> catatan,
      required DateTime dicatatPada,
      Value<bool> tersinkron,
      Value<int> percobaan,
      Value<int> rowid,
    });
typedef $$CacheResponsTableUpdateCompanionBuilder =
    CacheResponsCompanion Function({
      Value<String> klienId,
      Value<String> jadwalAktivitasId,
      Value<String> nilai,
      Value<String?> catatan,
      Value<DateTime> dicatatPada,
      Value<bool> tersinkron,
      Value<int> percobaan,
      Value<int> rowid,
    });

class $$CacheResponsTableFilterComposer
    extends Composer<_$DekapDatabase, $CacheResponsTable> {
  $$CacheResponsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get klienId => $composableBuilder(
    column: $table.klienId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get jadwalAktivitasId => $composableBuilder(
    column: $table.jadwalAktivitasId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nilai => $composableBuilder(
    column: $table.nilai,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get catatan => $composableBuilder(
    column: $table.catatan,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dicatatPada => $composableBuilder(
    column: $table.dicatatPada,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get tersinkron => $composableBuilder(
    column: $table.tersinkron,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get percobaan => $composableBuilder(
    column: $table.percobaan,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CacheResponsTableOrderingComposer
    extends Composer<_$DekapDatabase, $CacheResponsTable> {
  $$CacheResponsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get klienId => $composableBuilder(
    column: $table.klienId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get jadwalAktivitasId => $composableBuilder(
    column: $table.jadwalAktivitasId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nilai => $composableBuilder(
    column: $table.nilai,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get catatan => $composableBuilder(
    column: $table.catatan,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dicatatPada => $composableBuilder(
    column: $table.dicatatPada,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get tersinkron => $composableBuilder(
    column: $table.tersinkron,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get percobaan => $composableBuilder(
    column: $table.percobaan,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CacheResponsTableAnnotationComposer
    extends Composer<_$DekapDatabase, $CacheResponsTable> {
  $$CacheResponsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get klienId =>
      $composableBuilder(column: $table.klienId, builder: (column) => column);

  GeneratedColumn<String> get jadwalAktivitasId => $composableBuilder(
    column: $table.jadwalAktivitasId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get nilai =>
      $composableBuilder(column: $table.nilai, builder: (column) => column);

  GeneratedColumn<String> get catatan =>
      $composableBuilder(column: $table.catatan, builder: (column) => column);

  GeneratedColumn<DateTime> get dicatatPada => $composableBuilder(
    column: $table.dicatatPada,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get tersinkron => $composableBuilder(
    column: $table.tersinkron,
    builder: (column) => column,
  );

  GeneratedColumn<int> get percobaan =>
      $composableBuilder(column: $table.percobaan, builder: (column) => column);
}

class $$CacheResponsTableTableManager
    extends
        RootTableManager<
          _$DekapDatabase,
          $CacheResponsTable,
          CacheResponsData,
          $$CacheResponsTableFilterComposer,
          $$CacheResponsTableOrderingComposer,
          $$CacheResponsTableAnnotationComposer,
          $$CacheResponsTableCreateCompanionBuilder,
          $$CacheResponsTableUpdateCompanionBuilder,
          (
            CacheResponsData,
            BaseReferences<
              _$DekapDatabase,
              $CacheResponsTable,
              CacheResponsData
            >,
          ),
          CacheResponsData,
          PrefetchHooks Function()
        > {
  $$CacheResponsTableTableManager(_$DekapDatabase db, $CacheResponsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CacheResponsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CacheResponsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CacheResponsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> klienId = const Value.absent(),
                Value<String> jadwalAktivitasId = const Value.absent(),
                Value<String> nilai = const Value.absent(),
                Value<String?> catatan = const Value.absent(),
                Value<DateTime> dicatatPada = const Value.absent(),
                Value<bool> tersinkron = const Value.absent(),
                Value<int> percobaan = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CacheResponsCompanion(
                klienId: klienId,
                jadwalAktivitasId: jadwalAktivitasId,
                nilai: nilai,
                catatan: catatan,
                dicatatPada: dicatatPada,
                tersinkron: tersinkron,
                percobaan: percobaan,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String klienId,
                required String jadwalAktivitasId,
                required String nilai,
                Value<String?> catatan = const Value.absent(),
                required DateTime dicatatPada,
                Value<bool> tersinkron = const Value.absent(),
                Value<int> percobaan = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CacheResponsCompanion.insert(
                klienId: klienId,
                jadwalAktivitasId: jadwalAktivitasId,
                nilai: nilai,
                catatan: catatan,
                dicatatPada: dicatatPada,
                tersinkron: tersinkron,
                percobaan: percobaan,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CacheResponsTableProcessedTableManager =
    ProcessedTableManager<
      _$DekapDatabase,
      $CacheResponsTable,
      CacheResponsData,
      $$CacheResponsTableFilterComposer,
      $$CacheResponsTableOrderingComposer,
      $$CacheResponsTableAnnotationComposer,
      $$CacheResponsTableCreateCompanionBuilder,
      $$CacheResponsTableUpdateCompanionBuilder,
      (
        CacheResponsData,
        BaseReferences<_$DekapDatabase, $CacheResponsTable, CacheResponsData>,
      ),
      CacheResponsData,
      PrefetchHooks Function()
    >;
typedef $$CacheCheckInTableCreateCompanionBuilder =
    CacheCheckInCompanion Function({
      required String klienId,
      required DateTime tanggal,
      required int kondisi,
      Value<bool> tersinkron,
      Value<int> percobaan,
      Value<int> rowid,
    });
typedef $$CacheCheckInTableUpdateCompanionBuilder =
    CacheCheckInCompanion Function({
      Value<String> klienId,
      Value<DateTime> tanggal,
      Value<int> kondisi,
      Value<bool> tersinkron,
      Value<int> percobaan,
      Value<int> rowid,
    });

class $$CacheCheckInTableFilterComposer
    extends Composer<_$DekapDatabase, $CacheCheckInTable> {
  $$CacheCheckInTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get klienId => $composableBuilder(
    column: $table.klienId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get tanggal => $composableBuilder(
    column: $table.tanggal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get kondisi => $composableBuilder(
    column: $table.kondisi,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get tersinkron => $composableBuilder(
    column: $table.tersinkron,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get percobaan => $composableBuilder(
    column: $table.percobaan,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CacheCheckInTableOrderingComposer
    extends Composer<_$DekapDatabase, $CacheCheckInTable> {
  $$CacheCheckInTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get klienId => $composableBuilder(
    column: $table.klienId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get tanggal => $composableBuilder(
    column: $table.tanggal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get kondisi => $composableBuilder(
    column: $table.kondisi,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get tersinkron => $composableBuilder(
    column: $table.tersinkron,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get percobaan => $composableBuilder(
    column: $table.percobaan,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CacheCheckInTableAnnotationComposer
    extends Composer<_$DekapDatabase, $CacheCheckInTable> {
  $$CacheCheckInTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get klienId =>
      $composableBuilder(column: $table.klienId, builder: (column) => column);

  GeneratedColumn<DateTime> get tanggal =>
      $composableBuilder(column: $table.tanggal, builder: (column) => column);

  GeneratedColumn<int> get kondisi =>
      $composableBuilder(column: $table.kondisi, builder: (column) => column);

  GeneratedColumn<bool> get tersinkron => $composableBuilder(
    column: $table.tersinkron,
    builder: (column) => column,
  );

  GeneratedColumn<int> get percobaan =>
      $composableBuilder(column: $table.percobaan, builder: (column) => column);
}

class $$CacheCheckInTableTableManager
    extends
        RootTableManager<
          _$DekapDatabase,
          $CacheCheckInTable,
          CacheCheckInData,
          $$CacheCheckInTableFilterComposer,
          $$CacheCheckInTableOrderingComposer,
          $$CacheCheckInTableAnnotationComposer,
          $$CacheCheckInTableCreateCompanionBuilder,
          $$CacheCheckInTableUpdateCompanionBuilder,
          (
            CacheCheckInData,
            BaseReferences<
              _$DekapDatabase,
              $CacheCheckInTable,
              CacheCheckInData
            >,
          ),
          CacheCheckInData,
          PrefetchHooks Function()
        > {
  $$CacheCheckInTableTableManager(_$DekapDatabase db, $CacheCheckInTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CacheCheckInTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CacheCheckInTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CacheCheckInTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> klienId = const Value.absent(),
                Value<DateTime> tanggal = const Value.absent(),
                Value<int> kondisi = const Value.absent(),
                Value<bool> tersinkron = const Value.absent(),
                Value<int> percobaan = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CacheCheckInCompanion(
                klienId: klienId,
                tanggal: tanggal,
                kondisi: kondisi,
                tersinkron: tersinkron,
                percobaan: percobaan,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String klienId,
                required DateTime tanggal,
                required int kondisi,
                Value<bool> tersinkron = const Value.absent(),
                Value<int> percobaan = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CacheCheckInCompanion.insert(
                klienId: klienId,
                tanggal: tanggal,
                kondisi: kondisi,
                tersinkron: tersinkron,
                percobaan: percobaan,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CacheCheckInTableProcessedTableManager =
    ProcessedTableManager<
      _$DekapDatabase,
      $CacheCheckInTable,
      CacheCheckInData,
      $$CacheCheckInTableFilterComposer,
      $$CacheCheckInTableOrderingComposer,
      $$CacheCheckInTableAnnotationComposer,
      $$CacheCheckInTableCreateCompanionBuilder,
      $$CacheCheckInTableUpdateCompanionBuilder,
      (
        CacheCheckInData,
        BaseReferences<_$DekapDatabase, $CacheCheckInTable, CacheCheckInData>,
      ),
      CacheCheckInData,
      PrefetchHooks Function()
    >;
typedef $$PreferensiTableCreateCompanionBuilder =
    PreferensiCompanion Function({
      required String kunci,
      required String nilai,
      Value<int> rowid,
    });
typedef $$PreferensiTableUpdateCompanionBuilder =
    PreferensiCompanion Function({
      Value<String> kunci,
      Value<String> nilai,
      Value<int> rowid,
    });

class $$PreferensiTableFilterComposer
    extends Composer<_$DekapDatabase, $PreferensiTable> {
  $$PreferensiTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get kunci => $composableBuilder(
    column: $table.kunci,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nilai => $composableBuilder(
    column: $table.nilai,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PreferensiTableOrderingComposer
    extends Composer<_$DekapDatabase, $PreferensiTable> {
  $$PreferensiTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get kunci => $composableBuilder(
    column: $table.kunci,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nilai => $composableBuilder(
    column: $table.nilai,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PreferensiTableAnnotationComposer
    extends Composer<_$DekapDatabase, $PreferensiTable> {
  $$PreferensiTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get kunci =>
      $composableBuilder(column: $table.kunci, builder: (column) => column);

  GeneratedColumn<String> get nilai =>
      $composableBuilder(column: $table.nilai, builder: (column) => column);
}

class $$PreferensiTableTableManager
    extends
        RootTableManager<
          _$DekapDatabase,
          $PreferensiTable,
          PreferensiData,
          $$PreferensiTableFilterComposer,
          $$PreferensiTableOrderingComposer,
          $$PreferensiTableAnnotationComposer,
          $$PreferensiTableCreateCompanionBuilder,
          $$PreferensiTableUpdateCompanionBuilder,
          (
            PreferensiData,
            BaseReferences<_$DekapDatabase, $PreferensiTable, PreferensiData>,
          ),
          PreferensiData,
          PrefetchHooks Function()
        > {
  $$PreferensiTableTableManager(_$DekapDatabase db, $PreferensiTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PreferensiTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PreferensiTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PreferensiTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> kunci = const Value.absent(),
                Value<String> nilai = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) =>
                  PreferensiCompanion(kunci: kunci, nilai: nilai, rowid: rowid),
          createCompanionCallback:
              ({
                required String kunci,
                required String nilai,
                Value<int> rowid = const Value.absent(),
              }) => PreferensiCompanion.insert(
                kunci: kunci,
                nilai: nilai,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PreferensiTableProcessedTableManager =
    ProcessedTableManager<
      _$DekapDatabase,
      $PreferensiTable,
      PreferensiData,
      $$PreferensiTableFilterComposer,
      $$PreferensiTableOrderingComposer,
      $$PreferensiTableAnnotationComposer,
      $$PreferensiTableCreateCompanionBuilder,
      $$PreferensiTableUpdateCompanionBuilder,
      (
        PreferensiData,
        BaseReferences<_$DekapDatabase, $PreferensiTable, PreferensiData>,
      ),
      PreferensiData,
      PrefetchHooks Function()
    >;

class $DekapDatabaseManager {
  final _$DekapDatabase _db;
  $DekapDatabaseManager(this._db);
  $$CacheAktivitasTableTableManager get cacheAktivitas =>
      $$CacheAktivitasTableTableManager(_db, _db.cacheAktivitas);
  $$CacheJadwalTableTableManager get cacheJadwal =>
      $$CacheJadwalTableTableManager(_db, _db.cacheJadwal);
  $$CacheResponsTableTableManager get cacheRespons =>
      $$CacheResponsTableTableManager(_db, _db.cacheRespons);
  $$CacheCheckInTableTableManager get cacheCheckIn =>
      $$CacheCheckInTableTableManager(_db, _db.cacheCheckIn);
  $$PreferensiTableTableManager get preferensi =>
      $$PreferensiTableTableManager(_db, _db.preferensi);
}
