import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/adaptasi/adaptation_engine.dart';
import '../../domain/adaptasi/saran_profesional.dart';
import 'auth_repository.dart';

/// Applying a professional's suggestion to the plan, and writing down that it
/// happened.
///
/// Kept apart from [RencanaRepository] on purpose: that one never touches the
/// network on a read path, because opening a plan offline has to work. This is
/// a deliberate online action a caregiver takes once, so it can talk to the
/// server directly without weakening that rule.
///
/// This is also the first place in the app that writes `adaptasi_log`. Every
/// row it writes says which real numbers moved and that a person asked - the
/// same contract the five automatic rules are held to.
class PenerapanSaranRepository {
  PenerapanSaranRepository(this._client);

  final SupabaseClient _client;

  /// What the plan currently does, read back so the suggestion is applied to
  /// real numbers rather than to assumptions.
  Future<RencanaSaatIni?> rencanaAktif(
    String profilAnakId,
  ) => _jalankan(() async {
    final rencana = await _client
        .from('rencana')
        .select('id, periode_mulai, periode_selesai')
        .eq('profil_anak_id', profilAnakId)
        .eq('status', 'aktif')
        .order('periode_mulai', ascending: false)
        .limit(1)
        .maybeSingle();
    if (rencana == null) return null;

    final jadwal = await _client
        .from('jadwal_aktivitas')
        .select('id, tanggal, durasi_menit, aktivitas(kategori)')
        .eq('rencana_id', rencana['id'] as String);

    final porsi = <Kategori, int>{};
    final durasi = <Kategori, int>{};

    for (final baris in jadwal) {
      final nama =
          (baris['aktivitas'] as Map<String, dynamic>?)?['kategori'] as String?;
      final kategori = Kategori.values.where((k) => k.name == nama).firstOrNull;
      if (kategori == null) continue;

      porsi[kategori] = (porsi[kategori] ?? 0) + 1;
      // First one wins: a plan schedules one length per category, and if
      // that ever stops being true the log still records what it replaced.
      durasi[kategori] ??= (baris['durasi_menit'] as num).toInt();
    }

    return RencanaSaatIni(
      id: rencana['id'] as String,
      porsi: porsi,
      durasi: durasi,
    );
  });

  /// Applies a suggestion the caregiver accepted.
  ///
  /// Two things happen at different times, and the caller is expected to say so
  /// on screen rather than let the caregiver discover it:
  ///
  ///   * A session length change lands on this week's remaining activities
  ///     immediately. Past dates are left alone - rewriting the length of a
  ///     session that already happened would make the notes recorded against
  ///     it wrong.
  ///   * A session *count* change is recorded in the log and takes effect when
  ///     next week's plan is generated. Adding sessions means choosing
  ///     activities and times, which is generate-plan's job, not this one's.
  Future<HasilPenerapanSaran> terapkan({
    required String tanggapanId,
    required SaranProfesional saran,
    required RencanaSaatIni rencana,
  }) => _jalankan(() async {
    final hasil = terapkanSaranProfesional(
      saran: saran,
      porsi: rencana.porsi,
      durasi: rencana.durasi,
    );

    if (!hasil.adaPerubahan) {
      await _tandaiTanggapan(tanggapanId, 'diterapkan');
      return hasil;
    }

    final hariIni = DateTime.now();
    final batas =
        '${hariIni.year.toString().padLeft(4, '0')}-'
        '${hariIni.month.toString().padLeft(2, '0')}-'
        '${hariIni.day.toString().padLeft(2, '0')}';

    for (final entry in hasil.durasi.entries) {
      if (rencana.durasi[entry.key] == entry.value) continue;

      final jadwal = await _client
          .from('jadwal_aktivitas')
          .select('id, aktivitas(kategori)')
          .eq('rencana_id', rencana.id)
          .gte('tanggal', batas);

      final sasaran = [
        for (final b in jadwal)
          if ((b['aktivitas'] as Map<String, dynamic>?)?['kategori'] ==
              entry.key.name)
            b['id'] as String,
      ];

      for (final id in sasaran) {
        await _client
            .from('jadwal_aktivitas')
            .update({'durasi_menit': entry.value})
            .eq('id', id);
      }
    }

    await _client.from('adaptasi_log').insert([
      for (final baris in hasil.log)
        {
          'rencana_id': rencana.id,
          'aturan_id': baris.aturanId,
          'kategori': baris.kategori.name,
          'nilai_sebelum': baris.nilaiSebelum,
          'nilai_sesudah': baris.nilaiSesudah,
          'alasan': baris.alasan,
          'dikoreksi_manual': baris.dikoreksiManual,
        },
    ]);

    await _tandaiTanggapan(tanggapanId, 'diterapkan');
    return hasil;
  });

  /// The caregiver read it and decided not to apply it. Recorded rather than
  /// left as unread forever, so the response stops asking to be dealt with.
  Future<void> tolak(String tanggapanId) =>
      _tandaiTanggapan(tanggapanId, 'ditolak');

  Future<void> _tandaiTanggapan(String id, String status) => _jalankan(
    () async {
      await _client
          .from('tanggapan_profesional')
          .update({
            'status': status,
            'ditindaklanjuti_pada': DateTime.now().toIso8601String(),
          })
          .eq('id', id);
    },
  );

  Future<T> _jalankan<T>(Future<T> Function() aksi) async {
    try {
      return await aksi();
    } on KesalahanAuth {
      rethrow;
    } on PostgrestException {
      throw const KesalahanAuth(
        'Saran belum dapat diterapkan ke rencana. Periksa koneksi Anda, lalu '
        'coba lagi.',
      );
    } catch (_) {
      throw const KesalahanAuth(
        'Layanan sedang tidak dapat dihubungi. Coba lagi sebentar lagi.',
      );
    }
  }
}

/// What the active plan currently does, per category.
class RencanaSaatIni {
  const RencanaSaatIni({
    required this.id,
    required this.porsi,
    required this.durasi,
  });

  final String id;
  final Map<Kategori, int> porsi;
  final Map<Kategori, int> durasi;
}
