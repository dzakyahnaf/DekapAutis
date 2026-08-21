import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/app_config.dart';
import '../models/profil_anak.dart';

/// A failure the user is allowed to see.
///
/// Supabase reports errors in English. Rule 3 in CLAUDE.md says no English
/// string reaches the interface and rule 7 says an error explains what happened
/// and what to do next, without apologising or blaming the user. Every failure
/// therefore passes through here and comes out as a sentence we wrote.
class KesalahanAuth implements Exception {
  const KesalahanAuth(this.pesan);

  /// Indonesian, ready to display.
  final String pesan;

  @override
  String toString() => pesan;
}

/// Authentication and role assignment (KF-01).
///
/// Kept free of Flutter imports so it can be exercised without a widget tree.
class AuthRepository {
  AuthRepository(this._client);

  final SupabaseClient _client;

  Session? get sesi => _client.auth.currentSession;

  User? get pengguna => _client.auth.currentUser;

  bool get sudahMasuk => sesi != null;

  Stream<AuthState> get perubahanStatus => _client.auth.onAuthStateChange;

  Future<void> daftar({
    required String nama,
    required String email,
    required String sandi,
    required Peran peran,
  }) => _jalankan(() async {
    await _client.auth.signUp(
      email: email.trim(),
      password: sandi,
      // The trigger in migration 001 reads this and creates the pengguna row
      // with the right role. Anything unrecognised falls back to pengasuh, so
      // a tampered sign-up cannot mint an administrator.
      data: {'nama': nama.trim(), 'peran': peran.dbValue},
      emailRedirectTo: AppConfig.redirectMasuk,
    );
  });

  Future<void> masuk({required String email, required String sandi}) =>
      _jalankan(() async {
        await _client.auth.signInWithPassword(
          email: email.trim(),
          password: sandi,
        );
      });

  /// Browser-based OAuth rather than the native SDK.
  ///
  /// The native path needs the release keystore's SHA-1 registered in Google
  /// Cloud, and the release keystore is not created until F11 - so native
  /// Google sign-in would work all the way through development and break in
  /// the release APK on the last night. This route has no such dependency.
  Future<void> masukDenganGoogle() => _jalankan(() async {
    await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: AppConfig.redirectMasuk,
      authScreenLaunchMode: LaunchMode.externalApplication,
    );
  });

  Future<void> kirimTautanAturUlangSandi(String email) => _jalankan(() async {
    await _client.auth.resetPasswordForEmail(
      email.trim(),
      redirectTo: AppConfig.redirectMasuk,
    );
  });

  Future<void> keluar() => _jalankan(() async {
    await _client.auth.signOut();
  });

  /// Role of the signed-in account, read from `pengguna`.
  Future<Peran?> peranSaya() async {
    final id = pengguna?.id;
    if (id == null) return null;
    return _jalankan(() async {
      final baris = await _client
          .from('pengguna')
          .select('peran')
          .eq('id', id)
          .maybeSingle();
      if (baris == null) return null;
      return Peran.fromDb(baris['peran'] as String);
    });
  }

  Future<T> _jalankan<T>(Future<T> Function() aksi) async {
    try {
      return await aksi();
    } on AuthException catch (e) {
      throw KesalahanAuth(_terjemahkan(e));
    } on PostgrestException catch (_) {
      throw const KesalahanAuth(
        'Data tidak dapat diambil dari peladen. Periksa koneksi Anda, lalu coba lagi.',
      );
    } catch (_) {
      throw const KesalahanAuth(
        'Layanan sedang tidak dapat dihubungi. Coba lagi sebentar lagi.',
      );
    }
  }

  /// Maps a provider error onto a sentence that says what to do next.
  static String _terjemahkan(AuthException e) {
    final kode = e.code ?? '';
    final pesan = e.message.toLowerCase();

    if (kode == 'invalid_credentials' ||
        pesan.contains('invalid login credentials')) {
      return 'Email atau kata sandi belum cocok. Periksa kembali, atau gunakan '
          'tautan lupa kata sandi.';
    }
    if (kode == 'user_already_exists' || pesan.contains('already registered')) {
      return 'Email ini sudah terdaftar. Masuk dengan kata sandi Anda, atau '
          'gunakan tautan lupa kata sandi.';
    }
    if (kode == 'weak_password' || pesan.contains('password should be')) {
      return 'Kata sandi minimal 8 karakter. Gunakan kombinasi yang mudah Anda '
          'ingat tetapi sulit ditebak.';
    }
    if (kode == 'email_not_confirmed' || pesan.contains('not confirmed')) {
      return 'Email Anda belum dikonfirmasi. Buka tautan konfirmasi yang kami '
          'kirim, lalu masuk kembali.';
    }
    if (kode == 'over_email_send_rate_limit' ||
        pesan.contains('rate limit') ||
        pesan.contains('too many')) {
      return 'Terlalu banyak percobaan dalam waktu singkat. Tunggu beberapa '
          'menit, lalu coba lagi.';
    }
    if (kode == 'validation_failed' || pesan.contains('invalid email')) {
      return 'Format email belum benar. Periksa kembali penulisannya.';
    }
    if (pesan.contains('network') || pesan.contains('socket')) {
      return 'Perangkat sedang tidak terhubung ke internet. Sambungkan kembali, '
          'lalu coba lagi.';
    }
    return 'Masuk belum berhasil. Periksa koneksi Anda, lalu coba lagi.';
  }
}
