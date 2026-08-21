import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/profil_anak.dart';
import '../../data/providers.dart';

/// The four-step draft, held while onboarding is in progress (L.1).
@immutable
class DraftProfilAnak {
  const DraftProfilAnak({
    this.namaPanggilan = '',
    this.usia,
    this.kemampuanKomunikasi,
    this.sensitivitasSensorik = const {},
    this.fokusPerkembangan = const {},
  });

  final String namaPanggilan;
  final int? usia;
  final KemampuanKomunikasi? kemampuanKomunikasi;
  final Set<SensitivitasSensorik> sensitivitasSensorik;
  final Set<FokusPerkembangan> fokusPerkembangan;

  /// Nothing on a step blocks the next one except the facts the database
  /// actually requires. Sensory sensitivity and development focus may legitimately
  /// be empty: a caregiver who does not know yet should not be stuck.
  bool langkahLengkap(int langkah) => switch (langkah) {
    1 =>
      namaPanggilan.trim().isNotEmpty &&
          usia != null &&
          usia! >= 1 &&
          usia! <= 18,
    2 => kemampuanKomunikasi != null,
    3 => true,
    4 => true,
    _ => false,
  };

  bool get siapDisimpan => langkahLengkap(1) && langkahLengkap(2);

  DraftProfilAnak copyWith({
    String? namaPanggilan,
    int? usia,
    bool hapusUsia = false,
    KemampuanKomunikasi? kemampuanKomunikasi,
    Set<SensitivitasSensorik>? sensitivitasSensorik,
    Set<FokusPerkembangan>? fokusPerkembangan,
  }) => DraftProfilAnak(
    namaPanggilan: namaPanggilan ?? this.namaPanggilan,
    usia: hapusUsia ? null : (usia ?? this.usia),
    kemampuanKomunikasi: kemampuanKomunikasi ?? this.kemampuanKomunikasi,
    sensitivitasSensorik: sensitivitasSensorik ?? this.sensitivitasSensorik,
    fokusPerkembangan: fokusPerkembangan ?? this.fokusPerkembangan,
  );

  ProfilAnak jadiProfil(String penggunaId) => ProfilAnak(
    id: '',
    penggunaId: penggunaId,
    namaPanggilan: namaPanggilan.trim(),
    usia: usia!,
    kemampuanKomunikasi: kemampuanKomunikasi!,
    sensitivitasSensorik: sensitivitasSensorik,
    fokusPerkembangan: fokusPerkembangan,
  );
}

class OnboardingController extends StateNotifier<DraftProfilAnak> {
  OnboardingController(this._ref) : super(const DraftProfilAnak());

  final Ref _ref;

  void setNama(String v) => state = state.copyWith(namaPanggilan: v);

  void setUsia(String v) {
    final n = int.tryParse(v.trim());
    state = n == null
        ? state.copyWith(hapusUsia: true)
        : state.copyWith(usia: n);
  }

  void setKomunikasi(KemampuanKomunikasi v) =>
      state = state.copyWith(kemampuanKomunikasi: v);

  void toggleSensitivitas(SensitivitasSensorik v) {
    final baru = {...state.sensitivitasSensorik};
    baru.contains(v) ? baru.remove(v) : baru.add(v);
    state = state.copyWith(sensitivitasSensorik: baru);
  }

  void toggleFokus(FokusPerkembangan v) {
    final baru = {...state.fokusPerkembangan};
    baru.contains(v) ? baru.remove(v) : baru.add(v);
    state = state.copyWith(fokusPerkembangan: baru);
  }

  void mulaiUlang() => state = const DraftProfilAnak();

  /// Writes the profile. The caregiver id comes from the session rather than
  /// from the form, so a profile can only ever be created for the signed-in
  /// account - and RLS refuses it otherwise anyway.
  Future<ProfilAnak> simpan() async {
    final auth = _ref.read(authRepositoryProvider);
    final penggunaId = auth.pengguna?.id;
    if (penggunaId == null) {
      throw StateError('simpan() dipanggil tanpa sesi aktif');
    }
    final tersimpan = await _ref
        .read(profilAnakRepositoryProvider)
        .simpan(state.jadiProfil(penggunaId));
    _ref.invalidate(daftarAnakProvider);
    return tersimpan;
  }
}

final onboardingProvider =
    StateNotifierProvider<OnboardingController, DraftProfilAnak>(
      OnboardingController.new,
    );
