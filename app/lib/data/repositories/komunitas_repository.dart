import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/komunitas/penapis_kata.dart';
import '../models/komunitas.dart';
import 'auth_repository.dart';

/// Community (L.11), read through the views and written to the base tables.
///
/// Reads go to `postingan_publik` / `balasan_publik` and never to
/// `postingan_komunitas` directly. That is not a convenience: the base table's
/// RLS shows a caregiver only their own rows, so a screen that queried it would
/// render an empty community and look broken. The views are the way in, and
/// they are also what strips author identity server-side.
class KomunitasRepository {
  KomunitasRepository(this._client);

  final SupabaseClient _client;

  Future<List<Postingan>> daftar({TopikKomunitas? topik}) =>
      _jalankan(() async {
        var q = _client.from('postingan_publik').select();
        if (topik != null && topik != TopikKomunitas.semua) {
          q = q.eq('topik', topik.dbValue);
        }
        final baris = await q.order('dibuat_pada', ascending: false);
        return [for (final b in baris) Postingan.fromMap(b)];
      });

  Future<Postingan?> satu(String id) => _jalankan(() async {
    final baris = await _client
        .from('postingan_publik')
        .select()
        .eq('id', id)
        .maybeSingle();
    return baris == null ? null : Postingan.fromMap(baris);
  });

  Future<List<Balasan>> balasan(String postinganId) => _jalankan(() async {
    final baris = await _client
        .from('balasan_publik')
        .select()
        .eq('postingan_id', postinganId)
        .order('dibuat_pada');
    return [for (final b in baris) Balasan.fromMap(b)];
  });

  /// Publishes a post, or holds it for review if the word filter catches
  /// something.
  ///
  /// The filter runs before the write rather than after, so a post that trips
  /// the medical boundary is never publicly visible even briefly. A held post
  /// is stored with status `ditinjau` rather than discarded: the author's words
  /// are not thrown away, and an administrator can release it.
  Future<HasilModerasi> tulis({
    required TopikKomunitas topik,
    required String judul,
    required String isi,
    required bool anonim,
  }) => _jalankan(() async {
    final pengguna = _client.auth.currentUser;
    if (pengguna == null) {
      throw const KesalahanAuth('Masuk dahulu untuk menulis di komunitas.');
    }

    final moderasi = periksaTulisan('$judul\n$isi');

    await _client.from('postingan_komunitas').insert({
      'pengguna_id': pengguna.id,
      'topik': topik.dbValue,
      'judul': judul,
      'isi': isi,
      'anonim': anonim,
      'status': moderasi.perluDitinjau ? 'ditinjau' : 'terbit',
    });

    return moderasi;
  });

  Future<HasilModerasi> balas({
    required String postinganId,
    required String isi,
    required bool anonim,
  }) => _jalankan(() async {
    final pengguna = _client.auth.currentUser;
    if (pengguna == null) {
      throw const KesalahanAuth('Masuk dahulu untuk membalas.');
    }

    final moderasi = periksaTulisan(isi);
    if (moderasi.perluDitinjau) return moderasi;

    await _client.from('balasan_komunitas').insert({
      'postingan_id': postinganId,
      'pengguna_id': pengguna.id,
      'isi': isi,
      'anonim': anonim,
    });
    return moderasi;
  });

  /// Reports a post or reply to the moderation queue.
  ///
  /// Exactly one of [postinganId] and [balasanId] is passed; the database
  /// enforces the same rule with a check constraint.
  Future<void> laporkan({
    required AlasanLaporan alasan,
    String? postinganId,
    String? balasanId,
    String? catatan,
    String? frasa,
  }) => _jalankan(() async {
    final pengguna = _client.auth.currentUser;
    if (pengguna == null) {
      throw const KesalahanAuth('Masuk dahulu untuk melaporkan.');
    }
    await _client.from('laporan_penyalahgunaan').insert({
      'pelapor_id': pengguna.id,
      'postingan_id': postinganId,
      'balasan_id': balasanId,
      'kategori': alasan.dbValue,
      'catatan': catatan,
      'frasa': frasa,
    });
  });

  Future<T> _jalankan<T>(Future<T> Function() aksi) async {
    try {
      return await aksi();
    } on KesalahanAuth {
      rethrow;
    } on PostgrestException {
      throw const KesalahanAuth(
        'Komunitas belum dapat dimuat. Periksa koneksi Anda, lalu coba lagi.',
      );
    } catch (_) {
      throw const KesalahanAuth(
        'Layanan sedang tidak dapat dihubungi. Coba lagi sebentar lagi.',
      );
    }
  }
}
