import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/notifikasi.dart';
import 'auth_repository.dart';

/// Notifications (L.17).
///
/// Rows are written by the server - the trigger in migration 008 raises one
/// when a schedule request is made or answered - so this only reads and marks
/// them read.
class NotifikasiRepository {
  NotifikasiRepository(this._client);

  final SupabaseClient _client;

  /// RLS already limits this to the signed-in user, so there is no
  /// client-side filter to get wrong.
  Future<List<Notifikasi>> daftar({int batas = 50}) => _jalankan(() async {
    final baris = await _client
        .from('notifikasi')
        .select()
        .order('dibuat_pada', ascending: false)
        .limit(batas);
    return [for (final b in baris) Notifikasi.fromMap(b)];
  });

  Future<void> tandaiDibaca(String id) => _jalankan(() async {
    await _client.from('notifikasi').update({'dibaca': true}).eq('id', id);
  });

  /// Marks everything read. Deliberately not offered as "clear all": a
  /// caregiver who has not opened the app in a week should still be able to
  /// see what happened, just without the unread dots.
  Future<void> tandaiSemuaDibaca() => _jalankan(() async {
    await _client
        .from('notifikasi')
        .update({'dibaca': true})
        .eq('dibaca', false);
  });

  Future<int> jumlahBelumDibaca() => _jalankan(() async {
    final n = await _client
        .from('notifikasi')
        .select()
        .eq('dibaca', false)
        .count(CountOption.exact);
    return n.count;
  });

  Future<T> _jalankan<T>(Future<T> Function() aksi) async {
    try {
      return await aksi();
    } on PostgrestException {
      throw const KesalahanAuth(
        'Notifikasi belum dapat dimuat. Periksa koneksi Anda, lalu coba lagi.',
      );
    } catch (_) {
      throw const KesalahanAuth(
        'Layanan sedang tidak dapat dihubungi. Coba lagi sebentar lagi.',
      );
    }
  }
}
