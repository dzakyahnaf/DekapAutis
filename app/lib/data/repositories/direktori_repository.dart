import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/direktori.dart';
import 'auth_repository.dart';

/// The professional directory (L.9, L.10) and schedule requests.
///
/// Distance is not computed here and is not asked of the database. Coordinates
/// come down with the row and `urutkanTerdekat` does the arithmetic on the
/// device - docs/05 L.9, and the reason there is no map SDK anywhere in this
/// project.
class DirektoriRepository {
  DirektoriRepository(this._client);

  final SupabaseClient _client;

  /// Verified practices only.
  ///
  /// An unverified listing is not shown at all rather than shown without the
  /// badge: a caregiver scanning a list reads presence as endorsement, and
  /// KF-12 exists precisely so that reading is safe.
  Future<List<Profesional>> daftar() => _jalankan(() async {
    final baris = await _client
        .from('profesional')
        .select()
        .eq('terverifikasi', true)
        .order('nama_lengkap');
    return [for (final b in baris) Profesional.fromMap(b)];
  });

  Future<Profesional?> satu(String id) => _jalankan(() async {
    final baris = await _client
        .from('profesional')
        .select()
        .eq('id', id)
        .maybeSingle();
    return baris == null ? null : Profesional.fromMap(baris);
  });

  /// Records a request. It notifies the practice and does nothing else.
  ///
  /// No payment is taken and no session is opened, here or anywhere else -
  /// Bab 4.1 rules both out, and the table has no column for either.
  /// `klienId` makes a replay from the offline queue land on the same row.
  Future<PengajuanJadwal> ajukan({
    required String profesionalId,
    required String hari,
    required String jam,
    required String klienId,
    String? anakId,
    String? catatan,
  }) => _jalankan(() async {
    final pengguna = _client.auth.currentUser;
    if (pengguna == null) {
      throw const KesalahanAuth('Masuk dahulu untuk mengajukan jadwal.');
    }

    final baris = await _client
        .from('pengajuan_jadwal')
        .upsert({
          'pengasuh_id': pengguna.id,
          'profesional_id': profesionalId,
          'anak_id': anakId,
          'hari': hari,
          'jam': jam,
          'catatan': catatan,
          'klien_id': klienId,
        }, onConflict: 'klien_id')
        .select()
        .single();
    return PengajuanJadwal.fromMap(baris);
  });

  /// Requests this caregiver has made, newest first. RLS limits it to their
  /// own without a client-side filter.
  Future<List<PengajuanJadwal>> pengajuanSaya() => _jalankan(() async {
    final baris = await _client
        .from('pengajuan_jadwal')
        .select()
        .order('dibuat_pada', ascending: false);
    return [for (final b in baris) PengajuanJadwal.fromMap(b)];
  });

  Future<T> _jalankan<T>(Future<T> Function() aksi) async {
    try {
      return await aksi();
    } on KesalahanAuth {
      rethrow;
    } on PostgrestException {
      throw const KesalahanAuth(
        'Direktori belum dapat dimuat. Periksa koneksi Anda, lalu coba lagi.',
      );
    } catch (_) {
      throw const KesalahanAuth(
        'Layanan sedang tidak dapat dihubungi. Coba lagi sebentar lagi.',
      );
    }
  }
}
