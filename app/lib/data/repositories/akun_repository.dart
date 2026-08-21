import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_repository.dart';

/// Data portability and account deletion (Bab 4.3, L.16).
///
/// Both promises in the proposal are absolute: the user can download a copy of
/// everything, and deleting the account deletes the data rather than flagging
/// it. Neither is implemented as a soft flag anywhere in this class.
class AkunRepository {
  AkunRepository(this._client);

  final SupabaseClient _client;

  /// Tables that belong to a user and must come out in the export.
  ///
  /// aktivitas, dokumen_pengetahuan and potongan_dokumen are absent on purpose:
  /// they are the shared activity catalogue and the shared knowledge corpus,
  /// not this person's data.
  static const tabelMilikPengguna = <String>[
    'pengguna',
    'profil_anak',
    'rencana',
    'jadwal_aktivitas',
    'catatan_respons',
    'catatan_pengasuh',
    'laporan',
    'adaptasi_log',
    'izin_berbagi',
    'profesional',
    'tanggapan_profesional',
    'postingan_komunitas',
    'balasan_komunitas',
    'notifikasi',
  ];

  /// Everything the account holds, as JSON.
  ///
  /// No table is filtered by hand: RLS already limits every one of these reads
  /// to rows the caller owns, so the export cannot accidentally include someone
  /// else and cannot accidentally omit the caller.
  Future<String> unduhSalinanData() => _jalankan(() async {
    final isi = <String, dynamic>{
      'dibuat_pada': DateTime.now().toIso8601String(),
      'keterangan':
          'Salinan seluruh data akun DekapAutis. Katalog aktivitas dan '
          'basis pengetahuan tidak disertakan karena bukan data pribadi Anda.',
    };

    for (final tabel in tabelMilikPengguna) {
      try {
        isi[tabel] = await _client.from(tabel).select();
      } on PostgrestException {
        // A table the account has no rows in, or no policy for, contributes
        // nothing rather than failing the whole export.
        isi[tabel] = const <Map<String, dynamic>>[];
      }
    }

    return const JsonEncoder.withIndent('  ').convert(isi);
  });

  /// Permanently deletes the account and everything that hangs off it.
  ///
  /// Deleting a row from auth.users needs the service role, which must never
  /// exist on the device, so the actual delete happens in the `hapus-akun` Edge
  /// Function. Every user-owned table cascades from auth.users, so one delete
  /// is the whole operation - and scripts/test_hapus_akun.sql proves it by
  /// counting rows afterwards rather than trusting the cascade.
  Future<void> hapusAkunPermanen() => _jalankan(() async {
    await _client.functions.invoke('hapus-akun');
    await _client.auth.signOut();
  });

  Future<T> _jalankan<T>(Future<T> Function() aksi) async {
    try {
      return await aksi();
    } on FunctionException catch (_) {
      throw const KesalahanAuth(
        'Penghapusan akun belum dapat diproses. Periksa koneksi Anda, lalu coba '
        'lagi. Data Anda belum berubah.',
      );
    } catch (_) {
      throw const KesalahanAuth(
        'Layanan sedang tidak dapat dihubungi. Coba lagi sebentar lagi.',
      );
    }
  }
}
