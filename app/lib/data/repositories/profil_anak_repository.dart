import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/profil_anak.dart';
import 'auth_repository.dart';

/// Child profiles (KF-02).
///
/// Every call relies on RLS rather than filtering by hand: the policies in
/// migration 003 already restrict these rows to the signed-in caregiver, and a
/// client-side `where` would only be a second, weaker copy of that rule.
class ProfilAnakRepository {
  ProfilAnakRepository(this._client);

  final SupabaseClient _client;

  Future<List<ProfilAnak>> daftarAnak() => _jalankan(() async {
    final baris = await _client
        .from('profil_anak')
        .select()
        .order('dibuat_pada');
    return [for (final b in baris) ProfilAnak.fromMap(b)];
  });

  Future<ProfilAnak> simpan(ProfilAnak profil) => _jalankan(() async {
    final baris = await _client
        .from('profil_anak')
        .insert(profil.toInsert())
        .select()
        .single();
    return ProfilAnak.fromMap(baris);
  });

  Future<ProfilAnak> perbarui(ProfilAnak profil) => _jalankan(() async {
    final baris = await _client
        .from('profil_anak')
        .update(profil.toInsert()..remove('pengguna_id'))
        .eq('id', profil.id)
        .select()
        .single();
    return ProfilAnak.fromMap(baris);
  });

  Future<void> hapus(String id) => _jalankan(() async {
    await _client.from('profil_anak').delete().eq('id', id);
  });

  Future<T> _jalankan<T>(Future<T> Function() aksi) async {
    try {
      return await aksi();
    } on PostgrestException catch (e) {
      // 23514 is a check-constraint violation, which here means the form let
      // through a value the database refuses - an age outside 1-18, say.
      if (e.code == '23514') {
        throw const KesalahanAuth(
          'Ada isian yang belum sesuai. Periksa kembali usia dan pilihan Anda.',
        );
      }
      throw const KesalahanAuth(
        'Profil belum tersimpan ke peladen. Periksa koneksi Anda, lalu simpan lagi.',
      );
    } catch (_) {
      throw const KesalahanAuth(
        'Layanan sedang tidak dapat dihubungi. Coba lagi sebentar lagi.',
      );
    }
  }
}
