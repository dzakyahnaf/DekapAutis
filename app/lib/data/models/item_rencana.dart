import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../core/theme/tokens.dart';
import '../local/database.dart';
import 'response_level.dart';

/// One scheduled activity as the caregiver sees it: the slot, the activity it
/// points at, and the response already recorded for it, if any.
@immutable
class ItemRencana {
  const ItemRencana({
    required this.jadwal,
    required this.aktivitas,
    required this.namaAnak,
    this.respons,
  });

  final CacheJadwalData jadwal;
  final CacheAktivitasData aktivitas;

  /// Substituted into {nama} so the steps read as instructions about this child.
  final String namaAnak;

  final CacheResponsData? respons;

  String get id => jadwal.id;

  DekapCategory get kategori => DekapCategory.fromDb(aktivitas.kategori);

  ResponseLevel? get nilai =>
      respons == null ? null : ResponseLevel.fromDb(respons!.nilai);

  bool get sudahDicatat => respons != null;

  /// True while the note is still sitting in the outbox.
  bool get menungguSinkron => respons != null && !respons!.tersinkron;

  /// "08.00" rather than "08:00" - Indonesian writes time with a full stop.
  String get waktuTampil => jadwal.waktu.substring(0, 5).replaceAll(':', '.');

  String get judul => _isi(aktivitas.judul);
  String get tujuan => _isi(aktivitas.tujuan);
  String? get saranLingkungan => aktivitas.saranLingkungan == null
      ? null
      : _isi(aktivitas.saranLingkungan!);

  List<String> get alat {
    final raw = jsonDecode(aktivitas.alatJson);
    return [for (final a in raw as List) a.toString()];
  }

  /// Numbered steps, already in order and already carrying the child's name.
  List<String> get langkah {
    final raw = jsonDecode(aktivitas.langkahJson) as List;
    final urut = [...raw]
      ..sort(
        (a, b) => ((a as Map)['urutan'] as num).compareTo(
          ((b as Map)['urutan'] as num),
        ),
      );
    return [for (final l in urut) _isi(((l as Map)['teks']).toString())];
  }

  String _isi(String teks) => teks.replaceAll('{nama}', namaAnak);
}
