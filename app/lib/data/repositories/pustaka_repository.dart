import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/pustaka.dart';
import 'auth_repository.dart';

/// The education library (L.12).
///
/// The same `dokumen_pengetahuan` rows the assistant cites on L.4, on purpose:
/// a caregiver who follows a citation and then browses the library should find
/// the same document, not a parallel article.
class PustakaRepository {
  PustakaRepository(this._client);

  final SupabaseClient _client;

  /// Reviewed documents, newest first.
  ///
  /// Rejected documents are excluded outright. A document that failed review
  /// sitting in a list with a small grey chip is still a document a tired
  /// caregiver will open.
  Future<List<DokumenPustaka>> terbaru({int batas = 20}) => _jalankan(() async {
    final baris = await _client
        .from('dokumen_pengetahuan')
        .select()
        .neq('status_tinjauan', 'ditolak')
        .order('dibuat_pada', ascending: false)
        .limit(batas);
    return [for (final b in baris) DokumenPustaka.fromMap(b)];
  });

  Future<List<DokumenPustaka>> cari(String kata) => _jalankan(() async {
    final bersih = kata.trim();
    if (bersih.isEmpty) return terbaru();

    final baris = await _client
        .from('dokumen_pengetahuan')
        .select()
        .neq('status_tinjauan', 'ditolak')
        .or('judul.ilike.%$bersih%,penerbit.ilike.%$bersih%')
        .order('dibuat_pada', ascending: false);
    return [for (final b in baris) DokumenPustaka.fromMap(b)];
  });

  Future<DokumenPustaka?> satu(String id) => _jalankan(() async {
    final baris = await _client
        .from('dokumen_pengetahuan')
        .select()
        .eq('id', id)
        .maybeSingle();
    return baris == null ? null : DokumenPustaka.fromMap(baris);
  });

  /// Counted, never hard-coded. The mockup's "148 dokumen" is a drawing; this
  /// is what the corpus actually holds.
  Future<int> jumlahDokumen() => _jalankan(() async {
    final n = await _client
        .from('dokumen_pengetahuan')
        .count(CountOption.exact);
    return n;
  });

  Future<T> _jalankan<T>(Future<T> Function() aksi) async {
    try {
      return await aksi();
    } on PostgrestException {
      throw const KesalahanAuth(
        'Pustaka belum dapat dimuat. Periksa koneksi Anda, lalu coba lagi.',
      );
    } catch (_) {
      throw const KesalahanAuth(
        'Layanan sedang tidak dapat dihubungi. Coba lagi sebentar lagi.',
      );
    }
  }
}
