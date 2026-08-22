import 'package:dekapautis/data/local/database.dart';
import 'package:dekapautis/data/models/profil_anak.dart';
import 'package:dekapautis/data/providers.dart';
import 'package:dekapautis/data/repositories/akun_repository.dart';
import 'package:dekapautis/data/repositories/auth_repository.dart';
import 'package:dekapautis/data/repositories/profil_anak_repository.dart';
import 'package:dekapautis/data/repositories/rencana_repository.dart';
import 'package:dekapautis/data/repositories/sinkron_peladen.dart';
import 'package:dekapautis/data/sync/sync_service.dart';
import 'package:dekapautis/main.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Stand-ins for the repositories, so widget tests never reach a backend.
///
/// They implement the interface rather than extending it, which keeps them free
/// of a SupabaseClient. Anything a test does not use throws, so a test that
/// silently starts depending on a network call fails loudly instead of quietly
/// passing against a stub that returned null.

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.masuk_ = false, this.peran = Peran.pengasuh});

  bool masuk_;
  Peran? peran;

  @override
  bool get sudahMasuk => masuk_;

  @override
  Session? get sesi => null;

  @override
  User? get pengguna => null;

  @override
  Stream<AuthState> get perubahanStatus => const Stream.empty();

  @override
  Future<Peran?> peranSaya() async => peran;

  @override
  Future<void> keluar() async => masuk_ = false;

  @override
  Future<void> masuk({required String email, required String sandi}) async =>
      masuk_ = true;

  @override
  Future<void> daftar({
    required String nama,
    required String email,
    required String sandi,
    required Peran peran,
  }) async => masuk_ = true;

  @override
  Future<void> masukDenganGoogle() async => masuk_ = true;

  @override
  Future<void> kirimTautanAturUlangSandi(String email) async {}
}

class FakeProfilAnakRepository implements ProfilAnakRepository {
  FakeProfilAnakRepository({List<ProfilAnak>? awal}) : anak = awal ?? [];

  final List<ProfilAnak> anak;

  @override
  Future<List<ProfilAnak>> daftarAnak() async => anak;

  @override
  Future<ProfilAnak> simpan(ProfilAnak profil) async {
    final tersimpan = ProfilAnak(
      id: 'anak-${anak.length + 1}',
      penggunaId: profil.penggunaId,
      namaPanggilan: profil.namaPanggilan,
      usia: profil.usia,
      kemampuanKomunikasi: profil.kemampuanKomunikasi,
      sensitivitasSensorik: profil.sensitivitasSensorik,
      fokusPerkembangan: profil.fokusPerkembangan,
    );
    anak.add(tersimpan);
    return tersimpan;
  }

  @override
  Future<ProfilAnak> perbarui(ProfilAnak profil) async {
    final i = anak.indexWhere((a) => a.id == profil.id);
    if (i >= 0) anak[i] = profil;
    return profil;
  }

  @override
  Future<void> hapus(String id) async => anak.removeWhere((a) => a.id == id);
}

class FakeAkunRepository implements AkunRepository {
  bool terhapus = false;

  @override
  Future<String> unduhSalinanData() async => '{}';

  @override
  Future<void> hapusAkunPermanen() async => terhapus = true;
}

/// A server that can be switched off, and that behaves like the real one:
/// `klien_id` is UNIQUE, so an upsert with a client id already present replaces
/// that row instead of adding another.
class PeladenPalsu implements SinkronPeladen {
  bool daring = true;
  int panggilanKirim = 0;

  final Map<String, Map<String, dynamic>> respons = {};
  final Map<String, Map<String, dynamic>> checkIn = {};

  @override
  String? get penggunaId => 'pengguna-uji';

  void _pastikanDaring() {
    if (!daring) throw Exception('tidak ada jaringan');
  }

  @override
  Future<void> kirimRespons(Map<String, dynamic> baris) async {
    panggilanKirim++;
    _pastikanDaring();
    respons[baris['klien_id'] as String] = baris;
  }

  @override
  Future<void> kirimCheckIn(Map<String, dynamic> baris) async {
    _pastikanDaring();
    checkIn['${baris['pengguna_id']}|${baris['tanggal']}'] = baris;
  }

  @override
  Future<List<Map<String, dynamic>>> ambilKatalog() async {
    _pastikanDaring();
    return const [];
  }

  @override
  Future<List<Map<String, dynamic>>> ambilJadwal(String profilAnakId) async {
    _pastikanDaring();
    return const [];
  }

  @override
  Future<Map<String, dynamic>> mintaRencana(String profilAnakId) async {
    _pastikanDaring();
    return const {'alasan': ''};
  }
}

/// The whole app wired to fakes, ready to pump.
Widget aplikasiUji({
  FakeAuthRepository? auth,
  FakeProfilAnakRepository? profil,
  FakeAkunRepository? akun,
  PeladenPalsu? peladen,
  DekapDatabase? db,

  /// Extra overrides, appended last so they win. Used by the end-to-end loop
  /// test to hand both roles the same in-memory store.
  List<Override> tambahan = const [],
}) {
  // An in-memory database and a fake server: no file, no keystore, no network.
  final basis = db ?? DekapDatabase.memori();
  final server = peladen ?? PeladenPalsu();
  final repo = RencanaRepository(server, basis);

  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(auth ?? FakeAuthRepository()),
      profilAnakRepositoryProvider.overrideWithValue(
        profil ?? FakeProfilAnakRepository(),
      ),
      akunRepositoryProvider.overrideWithValue(akun ?? FakeAkunRepository()),
      databaseProvider.overrideWithValue(basis),
      sinkronPeladenProvider.overrideWithValue(server),
      rencanaRepositoryProvider.overrideWithValue(repo),
      // A connectivity stream that never fires, so no plugin is needed.
      syncServiceProvider.overrideWithValue(
        SyncService(repo, konektivitas: const Stream.empty()),
      ),
      // Drift's query streams keep a timer alive past widget disposal, which
      // the test binding rightly complains about. Widget tests have no business
      // exercising drift's streaming machinery anyway - the queue itself is
      // tested for real in antrean_luring_test.dart.
      menungguSinkronProvider.overrideWith((ref) => Stream.value(0)),
      ...tambahan,
    ],
    child: const DekapAutisApp(),
  );
}
