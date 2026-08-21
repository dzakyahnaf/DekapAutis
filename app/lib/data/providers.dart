import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'models/profil_anak.dart';
import 'repositories/akun_repository.dart';
import 'repositories/auth_repository.dart';
import 'repositories/profil_anak_repository.dart';

/// Overridden in tests with a fake so nothing here needs a live backend.
final supabaseClientProvider = Provider<SupabaseClient>(
  (ref) => Supabase.instance.client,
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(supabaseClientProvider)),
);

final profilAnakRepositoryProvider = Provider<ProfilAnakRepository>(
  (ref) => ProfilAnakRepository(ref.watch(supabaseClientProvider)),
);

final akunRepositoryProvider = Provider<AkunRepository>(
  (ref) => AkunRepository(ref.watch(supabaseClientProvider)),
);

/// Auth changes, including the silent token refresh, so the router can react
/// without polling.
final statusAuthProvider = StreamProvider<AuthState>(
  (ref) => ref.watch(authRepositoryProvider).perubahanStatus,
);

final sudahMasukProvider = Provider<bool>((ref) {
  ref.watch(statusAuthProvider);
  return ref.watch(authRepositoryProvider).sudahMasuk;
});

final peranSayaProvider = FutureProvider<Peran?>(
  (ref) => ref.watch(authRepositoryProvider).peranSaya(),
);

/// One account may hold several children (KF-02).
final daftarAnakProvider = FutureProvider<List<ProfilAnak>>((ref) {
  ref.watch(statusAuthProvider);
  return ref.watch(profilAnakRepositoryProvider).daftarAnak();
});
