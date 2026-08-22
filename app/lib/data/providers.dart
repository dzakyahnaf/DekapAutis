import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'local/database.dart';
import 'models/item_rencana.dart';
import 'models/profil_anak.dart';
import 'repositories/akun_repository.dart';
import 'repositories/auth_repository.dart';
import 'repositories/laporan_repository.dart';
import 'repositories/profil_anak_repository.dart';
import 'repositories/rencana_repository.dart';
import 'repositories/sinkron_peladen.dart';
import 'sync/sync_service.dart';

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

/// Overridden in tests with an in-memory database.
final databaseProvider = Provider<DekapDatabase>((ref) {
  final db = DekapDatabase(bukaDatabaseTerenkripsi());
  ref.onDispose(db.close);
  return db;
});

final sinkronPeladenProvider = Provider<SinkronPeladen>(
  (ref) => SupabaseSinkron(ref.watch(supabaseClientProvider)),
);

final rencanaRepositoryProvider = Provider<RencanaRepository>(
  (ref) => RencanaRepository(
    ref.watch(sinkronPeladenProvider),
    ref.watch(databaseProvider),
  ),
);

final syncServiceProvider = Provider<SyncService>((ref) {
  final layanan = SyncService(ref.watch(rencanaRepositoryProvider));
  ref.onDispose(layanan.berhenti);
  return layanan;
});

/// Rows still waiting to sync, for the offline banner in the header.
final menungguSinkronProvider = StreamProvider<int>(
  (ref) => ref.watch(rencanaRepositoryProvider).pantauMenunggu(),
);

/// The child whose plan is on screen. One account may hold several, so this is
/// the first one until a picker exists.
final anakAktifProvider = FutureProvider<ProfilAnak?>((ref) async {
  final daftar = await ref.watch(daftarAnakProvider.future);
  return daftar.firstOrNull;
});

/// Today's activities (L.2).
final agendaHariIniProvider = FutureProvider<List<ItemRencana>>((ref) async {
  final anak = await ref.watch(anakAktifProvider.future);
  if (anak == null) return const [];
  return ref.watch(rencanaRepositoryProvider).hariIni(anak.namaPanggilan);
});

/// The day currently selected on the weekly plan screen (L.6).
final hariTerpilihProvider = StateProvider<DateTime>((ref) {
  final n = DateTime.now();
  return DateTime(n.year, n.month, n.day);
});

/// Monday of the week containing the selected day.
DateTime awalMinggu(DateTime d) =>
    DateTime(d.year, d.month, d.day).subtract(Duration(days: d.weekday - 1));

final rencanaMingguanProvider = FutureProvider<List<ItemRencana>>((ref) async {
  final anak = await ref.watch(anakAktifProvider.future);
  if (anak == null) return const [];
  final awal = awalMinggu(ref.watch(hariTerpilihProvider));
  return ref
      .watch(rencanaRepositoryProvider)
      .rentang(awal, awal.add(const Duration(days: 6)), anak.namaPanggilan);
});

final checkInHariIniProvider = FutureProvider<int?>(
  (ref) => ref.watch(rencanaRepositoryProvider).checkInHariIni(),
);

final laporanRepositoryProvider = Provider<LaporanRepository>(
  (ref) => LaporanRepository(ref.watch(supabaseClientProvider)),
);

/// Who currently has access to which report (L.16, KNF-04).
final daftarIzinProvider = FutureProvider<List<IzinBerbagi>>((ref) {
  ref.watch(statusAuthProvider);
  return ref.watch(laporanRepositoryProvider).daftarIzin();
});
