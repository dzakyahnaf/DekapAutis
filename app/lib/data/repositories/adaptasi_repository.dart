import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/adaptasi/adaptation_engine.dart';
import 'auth_repository.dart';

/// Runs the adaptation engine and writes down what it decided.
///
/// The engine itself (F4) has been complete and tested since its first commit,
/// but nothing invoked it: the plan was generated server-side and the five
/// rules never ran against a real child's notes. This is the missing half.
///
/// The split is deliberate. `AdaptationEngine` stays pure Dart with no network
/// and no database, so its rules are arguable in a test. Everything that has to
/// touch a backend lives here, and the two meet only through
/// [MasukanAdaptasi] and [HasilAdaptasi].
class AdaptasiRepository {
  AdaptasiRepository(this._client);

  final SupabaseClient _client;

  static const _engine = AdaptationEngine();

  /// Reads the last three weeks of notes, runs the rules, persists the log.
  ///
  /// Returns null when there is no active plan to adapt - a caregiver who has
  /// not generated a plan yet has nothing for the rules to move, and inventing
  /// a starting point would put numbers in `adaptasi_log` that describe
  /// nothing.
  Future<HasilAdaptasi?> jalankan(String profilAnakId) => _jalankan(() async {
    final rencana = await _client
        .from('rencana')
        .select('id, periode_mulai')
        .eq('profil_anak_id', profilAnakId)
        .eq('status', 'aktif')
        .order('periode_mulai', ascending: false)
        .limit(1)
        .maybeSingle();
    if (rencana == null) return null;

    final rencanaId = rencana['id'] as String;
    final periode =
        DateTime.tryParse(rencana['periode_mulai'] as String? ?? '') ??
        _awalMinggu(DateTime.now());

    // Three periods back: rule D compares the current week against the two
    // before it, so anything shorter cannot fire it at all.
    final sejak = periode.subtract(const Duration(days: 21));
    final baris = await _client
        .from('catatan_respons')
        .select(
          'nilai, dicatat_pada, '
          'jadwal_aktivitas!inner(waktu, tanggal, rencana_id, '
          'aktivitas!inner(kategori), rencana!inner(profil_anak_id))',
        )
        .eq('jadwal_aktivitas.rencana.profil_anak_id', profilAnakId)
        .gte('jadwal_aktivitas.tanggal', _tanggal(sejak));

    final catatan = <CatatanUntukAdaptasi>[];
    for (final b in baris) {
      final jadwal = b['jadwal_aktivitas'] as Map<String, dynamic>?;
      final aktivitas = jadwal?['aktivitas'] as Map<String, dynamic>?;
      final kategori = Kategori.values
          .where((k) => k.name == aktivitas?['kategori'])
          .firstOrNull;
      final dicatat = DateTime.tryParse(b['dicatat_pada'] as String? ?? '');
      if (kategori == null || dicatat == null) continue;

      catatan.add(
        CatatanUntukAdaptasi(
          kategori: kategori,
          nilai: NilaiRespons.fromDb(b['nilai'] as String),
          dicatatPada: dicatat,
          // The hour the activity was *scheduled* for. Rule E is about which
          // time of day works, and a note typed at bedtime says nothing
          // about that.
          jamJadwal: _jam(jadwal?['waktu'] as String?),
        ),
      );
    }

    final sekarang = await _keadaanRencana(rencanaId);
    final dikoreksi = await _dikoreksiManual(rencanaId, periode);

    final hasil = _engine.jalankan(
      MasukanAdaptasi(
        catatan: catatan,
        tingkat: sekarang.tingkat,
        durasi: sekarang.durasi,
        porsi: sekarang.porsi,
        periodeSekarang: periode,
        dikoreksiManual: dikoreksi,
      ),
    );

    await _simpanLog(rencanaId, hasil);
    return hasil;
  });

  /// Marks a category as corrected by hand for the rest of the period (KF-06).
  ///
  /// A caregiver who overrode the plan knows something the notes do not
  /// contain, so the rules leave that category alone until the next period.
  /// Recorded as a log row rather than a flag on the plan, because "why does
  /// my plan look like this" has to have one answer, in one place.
  Future<void> koreksiManual({
    required String rencanaId,
    required Kategori kategori,
    required String alasan,
  }) => _jalankan(() async {
    await _client.from('adaptasi_log').insert({
      'rencana_id': rencanaId,
      // Its own id, not a rule's. The plan screen reads `aturan_id` to explain
      // *why* the plan changed, and a caregiver's own correction dressed up as
      // rule C would be explained as a machine decision.
      'aturan_id': 'G_manual',
      'kategori': kategori.name,
      'nilai_sebelum': <String, Object?>{},
      'nilai_sesudah': <String, Object?>{},
      'alasan': alasan,
      'dikoreksi_manual': true,
    });
  });

  /// Log rows for a plan, newest first. What the plan screen reads.
  Future<List<BarisLogTersimpan>> log(String rencanaId) => _jalankan(() async {
    final baris = await _client
        .from('adaptasi_log')
        .select()
        .eq('rencana_id', rencanaId)
        .order('dibuat_pada', ascending: false);
    return [for (final b in baris) BarisLogTersimpan.fromMap(b)];
  });

  Future<void> _simpanLog(String rencanaId, HasilAdaptasi hasil) async {
    if (hasil.log.isEmpty) return;

    await _client.from('adaptasi_log').insert([
      for (final b in hasil.log)
        {
          'rencana_id': rencanaId,
          'aturan_id': b.aturanId,
          'kategori': b.kategori.name,
          'nilai_sebelum': b.nilaiSebelum,
          'nilai_sesudah': b.nilaiSesudah,
          'alasan': b.alasan,
          'dikoreksi_manual': b.dikoreksiManual,
        },
    ]);
  }

  /// What the plan currently does, per category, read back from the schedule
  /// rather than assumed.
  Future<_KeadaanRencana> _keadaanRencana(String rencanaId) async {
    final baris = await _client
        .from('jadwal_aktivitas')
        .select('durasi_menit, tingkat_disesuaikan, aktivitas!inner(kategori)')
        .eq('rencana_id', rencanaId);

    final tingkat = <Kategori, int>{};
    final durasi = <Kategori, int>{};
    final porsi = <Kategori, int>{};

    for (final b in baris) {
      final nama = (b['aktivitas'] as Map<String, dynamic>?)?['kategori'];
      final kategori = Kategori.values.where((k) => k.name == nama).firstOrNull;
      if (kategori == null) continue;

      porsi[kategori] = (porsi[kategori] ?? 0) + 1;
      tingkat[kategori] ??= (b['tingkat_disesuaikan'] as num).toInt();
      durasi[kategori] ??= (b['durasi_menit'] as num).toInt();
    }
    return _KeadaanRencana(tingkat: tingkat, durasi: durasi, porsi: porsi);
  }

  Future<Set<Kategori>> _dikoreksiManual(
    String rencanaId,
    DateTime periode,
  ) async {
    final baris = await _client
        .from('adaptasi_log')
        .select('kategori')
        .eq('rencana_id', rencanaId)
        .eq('dikoreksi_manual', true)
        .gte('dibuat_pada', periode.toIso8601String());

    return {
      for (final b in baris)
        ...Kategori.values.where((k) => k.name == b['kategori']),
    };
  }

  static DateTime _awalMinggu(DateTime t) =>
      DateTime(t.year, t.month, t.day).subtract(Duration(days: t.weekday - 1));

  static String _tanggal(DateTime t) =>
      '${t.year.toString().padLeft(4, '0')}-'
      '${t.month.toString().padLeft(2, '0')}-'
      '${t.day.toString().padLeft(2, '0')}';

  /// `waktu` arrives as "08:30:00".
  static int _jam(String? waktu) =>
      int.tryParse((waktu ?? '').split(':').first) ?? 0;

  Future<T> _jalankan<T>(Future<T> Function() aksi) async {
    try {
      return await aksi();
    } on KesalahanAuth {
      rethrow;
    } on PostgrestException {
      throw const KesalahanAuth(
        'Penyesuaian rencana belum dapat dijalankan. Periksa koneksi Anda, '
        'lalu coba lagi.',
      );
    } catch (_) {
      throw const KesalahanAuth(
        'Layanan sedang tidak dapat dihubungi. Coba lagi sebentar lagi.',
      );
    }
  }
}

class _KeadaanRencana {
  const _KeadaanRencana({
    required this.tingkat,
    required this.durasi,
    required this.porsi,
  });

  final Map<Kategori, int> tingkat;
  final Map<Kategori, int> durasi;
  final Map<Kategori, int> porsi;
}

/// One `adaptasi_log` row as the plan screen reads it back.
class BarisLogTersimpan {
  const BarisLogTersimpan({
    required this.id,
    required this.aturanId,
    required this.alasan,
    required this.dikoreksiManual,
    this.kategori,
    this.dibuatPada,
  });

  factory BarisLogTersimpan.fromMap(Map<String, dynamic> m) =>
      BarisLogTersimpan(
        id: m['id'] as String,
        aturanId: m['aturan_id'] as String,
        alasan: m['alasan'] as String,
        dikoreksiManual: (m['dikoreksi_manual'] as bool?) ?? false,
        kategori: Kategori.values
            .where((k) => k.name == m['kategori'])
            .firstOrNull,
        dibuatPada: DateTime.tryParse(m['dibuat_pada'] as String? ?? ''),
      );

  final String id;
  final String aturanId;
  final String alasan;
  final bool dikoreksiManual;
  final Kategori? kategori;
  final DateTime? dibuatPada;

  /// D_tandai is written for the report and the professional's inbox, never
  /// shown to the caregiver. Telling a parent "your child is declining" helps
  /// nobody and is not this app's place to say.
  bool get tampilkanKePengasuh => aturanId != 'D_tandai';
}
