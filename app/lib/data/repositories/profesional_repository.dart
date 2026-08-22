import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/adaptasi/kategori.dart';
import '../models/direktori.dart';
import '../models/profesional_admin.dart';
import 'auth_repository.dart';

/// The professional's side of the loop (F9).
///
/// Every read here relies on RLS. `profesional_berizin` is what decides which
/// reports come back, so the inbox query has no `where` clause naming the
/// professional - adding one would be a second, weaker copy of the rule that
/// already holds, and the weaker copy is the one that eventually disagrees.
class ProfesionalRepository {
  ProfesionalRepository(this._client);

  final SupabaseClient _client;

  /// The practice profile belonging to the signed-in user, if any.
  Future<Profesional?> profilSaya() => _jalankan(() async {
    final pengguna = _client.auth.currentUser;
    if (pengguna == null) return null;

    final baris = await _client
        .from('profesional')
        .select()
        .eq('pengguna_id', pengguna.id)
        .maybeSingle();
    return baris == null ? null : Profesional.fromMap(baris);
  });

  Future<StatusVerifikasi> statusVerifikasiSaya() => _jalankan(() async {
    final pengguna = _client.auth.currentUser;
    if (pengguna == null) return StatusVerifikasi.menunggu;

    final baris = await _client
        .from('profesional')
        .select('status_verifikasi')
        .eq('pengguna_id', pengguna.id)
        .maybeSingle();
    return StatusVerifikasi.fromDb(
      baris?['status_verifikasi'] as String? ?? 'menunggu',
    );
  });

  /// Creates or updates the practice profile.
  ///
  /// Submitting always returns the practice to `menunggu`: a listing that
  /// changed its specialisation or address after being approved has not been
  /// checked in that form, and the badge must not carry over.
  Future<void> simpanProfil({
    required String namaLengkap,
    required String spesialisasi,
    String? gelar,
    String? tentang,
    List<String> layanan = const [],
    List<JamPraktik> jadwalPraktik = const [],
    String? kota,
    double? lat,
    double? lng,
    String? buktiKredensial,
  }) => _jalankan(() async {
    final pengguna = _client.auth.currentUser;
    if (pengguna == null) {
      throw const KesalahanAuth('Masuk dahulu untuk mengisi profil praktik.');
    }

    final isi = {
      'pengguna_id': pengguna.id,
      'nama_lengkap': namaLengkap,
      'spesialisasi': spesialisasi,
      'gelar': gelar,
      'tentang': tentang,
      'layanan': layanan,
      'jadwal_praktik': [for (final j in jadwalPraktik) j.toMap()],
      'kota': kota,
      'lokasi_lat': lat,
      'lokasi_lng': lng,
      'bukti_kredensial': buktiKredensial,
      'status_verifikasi': 'menunggu',
      'alasan_penolakan': null,
      'diajukan_pada': DateTime.now().toIso8601String(),
    };

    final ada = await _client
        .from('profesional')
        .select('id')
        .eq('pengguna_id', pengguna.id)
        .maybeSingle();

    if (ada == null) {
      await _client.from('profesional').insert(isi);
    } else {
      await _client
          .from('profesional')
          .update(isi..remove('pengguna_id'))
          .eq('id', ada['id'] as String);
    }
  });

  /// Reports shared with this professional. Flagged and unanswered first.
  Future<List<LaporanMasuk>> kotakMasuk() => _jalankan(() async {
    final baris = await _client
        .from('laporan')
        .select(
          'id, profil_anak_id, periode_mulai, periode_selesai, ringkasan, '
          'penanda_perhatian, dibuat_pada, '
          'profil_anak(nama_panggilan, usia), '
          'tanggapan_profesional(id)',
        )
        .order('dibuat_pada', ascending: false);

    final daftar = [for (final b in baris) LaporanMasuk.fromMap(b)]
      ..sort((a, b) {
        final p = a.prioritas.compareTo(b.prioritas);
        if (p != 0) return p;
        return (b.dibuatPada ?? DateTime(0)).compareTo(
          a.dibuatPada ?? DateTime(0),
        );
      });
    return daftar;
  });

  Future<LaporanMasuk?> laporan(String id) => _jalankan(() async {
    final baris = await _client
        .from('laporan')
        .select(
          'id, profil_anak_id, periode_mulai, periode_selesai, ringkasan, '
          'penanda_perhatian, dibuat_pada, metrik, per_kategori, '
          'profil_anak(nama_panggilan, usia), '
          'tanggapan_profesional(id)',
        )
        .eq('id', id)
        .maybeSingle();
    return baris == null ? null : LaporanMasuk.fromMap(baris);
  });

  Future<List<TanggapanProfesional>> tanggapan(String laporanId) =>
      _jalankan(() async {
        final baris = await _client
            .from('tanggapan_profesional')
            .select()
            .eq('laporan_id', laporanId)
            .order('dibuat_pada');
        return [for (final b in baris) TanggapanProfesional.fromMap(b)];
      });

  /// Writes a response. The prose and the actionable part travel together.
  Future<void> tanggapi({
    required String laporanId,
    required String isi,
    required Set<Kategori> saranKategori,
    required String klienId,
    int? saranDurasiMenit,
  }) => _jalankan(() async {
    final profil = await profilSaya();
    if (profil == null) {
      throw const KesalahanAuth(
        'Profil praktik Anda belum ada. Isi profil praktik terlebih dahulu.',
      );
    }

    await _client.from('tanggapan_profesional').upsert({
      'laporan_id': laporanId,
      'profesional_id': profil.id,
      'isi': isi,
      'saran_kategori': [for (final k in saranKategori) k.name],
      'saran_durasi_menit': saranDurasiMenit,
      'klien_id': klienId,
    }, onConflict: 'klien_id');
  });

  Future<T> _jalankan<T>(Future<T> Function() aksi) async {
    try {
      return await aksi();
    } on KesalahanAuth {
      rethrow;
    } on PostgrestException catch (e) {
      // 42501 is RLS refusing the write: the caregiver revoked permission
      // between the report opening and the response being sent.
      if (e.code == '42501') {
        throw const KesalahanAuth(
          'Akses ke laporan ini sudah dicabut oleh pengasuh, jadi tanggapan '
          'tidak dapat dikirim.',
        );
      }
      throw const KesalahanAuth(
        'Data belum dapat dimuat. Periksa koneksi Anda, lalu coba lagi.',
      );
    } catch (_) {
      throw const KesalahanAuth(
        'Layanan sedang tidak dapat dihubungi. Coba lagi sebentar lagi.',
      );
    }
  }
}
