import 'package:supabase_flutter/supabase_flutter.dart';

/// The four things the plan needs from the server.
///
/// Kept behind an interface so the offline queue can be tested for what it
/// actually promises - exactly five rows after five offline notes, not four and
/// not ten - without a network, a device, or a running backend. A queue whose
/// idempotency is only ever verified by hand is a queue nobody will dare change.
abstract interface class SinkronPeladen {
  Future<List<Map<String, dynamic>>> ambilKatalog();

  Future<List<Map<String, dynamic>>> ambilJadwal(String profilAnakId);

  /// Upsert keyed on `klien_id`, which is UNIQUE on the server. Sending the
  /// same row twice updates it rather than inserting a second one.
  Future<void> kirimRespons(Map<String, dynamic> baris);

  /// Upsert keyed on (pengguna_id, tanggal).
  Future<void> kirimCheckIn(Map<String, dynamic> baris);

  Future<Map<String, dynamic>> mintaRencana(String profilAnakId);

  String? get penggunaId;
}

class SupabaseSinkron implements SinkronPeladen {
  SupabaseSinkron(this._client);

  final SupabaseClient _client;

  @override
  String? get penggunaId => _client.auth.currentUser?.id;

  @override
  Future<List<Map<String, dynamic>>> ambilKatalog() async {
    final baris = await _client
        .from('aktivitas')
        .select(
          'id, kategori, tingkat, judul, tujuan, durasi_menit, alat, langkah, '
          'saran_lingkungan',
        );
    return List<Map<String, dynamic>>.from(baris);
  }

  @override
  Future<List<Map<String, dynamic>>> ambilJadwal(String profilAnakId) async {
    final baris = await _client
        .from('jadwal_aktivitas')
        .select(
          'id, rencana_id, aktivitas_id, tanggal, waktu, urutan, durasi_menit, '
          'tingkat_disesuaikan, rencana!inner(profil_anak_id, status)',
        )
        .eq('rencana.profil_anak_id', profilAnakId)
        .eq('rencana.status', 'aktif');
    return List<Map<String, dynamic>>.from(baris);
  }

  @override
  Future<void> kirimRespons(Map<String, dynamic> baris) =>
      _client.from('catatan_respons').upsert(baris, onConflict: 'klien_id');

  @override
  Future<void> kirimCheckIn(Map<String, dynamic> baris) => _client
      .from('catatan_pengasuh')
      .upsert(baris, onConflict: 'pengguna_id,tanggal');

  @override
  Future<Map<String, dynamic>> mintaRencana(String profilAnakId) async {
    final res = await _client.functions.invoke(
      'generate-plan',
      body: {'profil_anak_id': profilAnakId},
    );
    return Map<String, dynamic>.from(res.data as Map);
  }
}
