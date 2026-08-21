import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:uuid/uuid.dart';

import '../local/database.dart';
import '../models/item_rencana.dart';
import '../models/response_level.dart';
import 'auth_repository.dart';
import 'sinkron_peladen.dart';

/// The plan, the activity catalogue, and the response notes (KF-03 to KF-05).
///
/// Reads always come from the local database and writes always go there first.
/// The network is a background concern, not a precondition: docs/03 §5 says
/// opening a downloaded plan and recording a response must work with no
/// connection at all, and the only way to guarantee that is to never put the
/// network on the read path.
class RencanaRepository {
  RencanaRepository(this._peladen, this._db);

  final SinkronPeladen _peladen;
  final DekapDatabase _db;

  static const _uuid = Uuid();

  // ------------------------------------------------------------ reads --

  Future<List<ItemRencana>> hariIni(
    String namaAnak, {
    DateTime? tanggal,
  }) async => _rakit(await _db.jadwalPada(tanggal ?? DateTime.now()), namaAnak);

  Future<List<ItemRencana>> rentang(
    DateTime dari,
    DateTime sampai,
    String namaAnak,
  ) async => _rakit(await _db.jadwalRentang(dari, sampai), namaAnak);

  Future<ItemRencana?> satu(String jadwalId, String namaAnak) async {
    final semua = await _db.jadwalRentang(
      DateTime.now().subtract(const Duration(days: 60)),
      DateTime.now().add(const Duration(days: 60)),
    );
    final jadwal = semua.where((j) => j.id == jadwalId).firstOrNull;
    if (jadwal == null) return null;
    final hasil = await _rakit([jadwal], namaAnak);
    return hasil.firstOrNull;
  }

  Future<List<ItemRencana>> _rakit(
    List<CacheJadwalData> jadwal,
    String namaAnak,
  ) async {
    final hasil = <ItemRencana>[];
    for (final j in jadwal) {
      final aktivitas = await _db.aktivitas(j.aktivitasId);
      if (aktivitas == null) continue;
      hasil.add(
        ItemRencana(
          jadwal: j,
          aktivitas: aktivitas,
          namaAnak: namaAnak,
          respons: await _db.responsUntuk(j.id),
        ),
      );
    }
    return hasil;
  }

  // ------------------------------------------------------------ writes --

  /// Records a response (KF-05).
  ///
  /// Writes locally, then attempts a push. The attempt failing is an ordinary
  /// outcome, not an error worth telling the user about: the note is saved, the
  /// offline banner already says how many are waiting, and the sync service will
  /// drain it. Surfacing a failure here would teach caregivers that recording a
  /// response offline does not work, which is the opposite of the truth.
  Future<void> catatRespons({
    required String jadwalAktivitasId,
    required ResponseLevel nilai,
    String? catatan,
  }) async {
    final sudahAda = await _db.responsUntuk(jadwalAktivitasId);

    // Reuse the client id when correcting an earlier note, so the server sees an
    // update to the same row rather than a second answer for one activity.
    final klienId = sudahAda?.klienId ?? _uuid.v4();

    await _db.catatRespons(
      CacheResponsCompanion.insert(
        klienId: klienId,
        jadwalAktivitasId: jadwalAktivitasId,
        nilai: nilai.dbValue,
        catatan: Value(catatan),
        dicatatPada: DateTime.now(),
        // Both of these have to be written explicitly. The upsert only sets the
        // columns present in the companion, so a correction to an already-synced
        // note would otherwise keep tersinkron = true, drop straight out of the
        // queue, and never reach the server - the note would look saved on the
        // device and simply not exist in the report weeks later.
        tersinkron: const Value(false),
        percobaan: const Value(0),
      ),
    );

    await dorongSatuRespons(klienId);
  }

  /// Caregiver check-in (KF-13). Same path: local first.
  Future<void> catatCheckIn(int kondisi, {DateTime? tanggal}) async {
    final hari = tanggal ?? DateTime.now();
    final tepat = DateTime(hari.year, hari.month, hari.day);
    final sudahAda = await _db.checkInPada(tepat);

    await _db.catatCheckIn(
      CacheCheckInCompanion.insert(
        klienId: sudahAda?.klienId ?? _uuid.v4(),
        tanggal: tepat,
        kondisi: kondisi,
        tersinkron: const Value(false),
        percobaan: const Value(0),
      ),
    );
    await kurasAntrean();
  }

  Future<int?> checkInHariIni() async {
    final now = DateTime.now();
    final baris = await _db.checkInPada(DateTime(now.year, now.month, now.day));
    return baris?.kondisi;
  }

  // ------------------------------------------------------------- sync --

  /// Pulls the catalogue and the current week into the local database.
  Future<void> segarkan(String profilAnakId) async {
    final katalog = await _peladen.ambilKatalog();

    await _db.simpanKatalog([
      for (final a in katalog)
        CacheAktivitasCompanion.insert(
          id: a['id'] as String,
          kategori: a['kategori'] as String,
          tingkat: (a['tingkat'] as num).toInt(),
          judul: a['judul'] as String,
          tujuan: a['tujuan'] as String,
          durasiMenit: (a['durasi_menit'] as num).toInt(),
          alatJson: jsonEncode(a['alat'] ?? const []),
          langkahJson: jsonEncode(a['langkah'] ?? const []),
          saranLingkungan: Value(a['saran_lingkungan'] as String?),
        ),
    ]);

    final jadwal = await _peladen.ambilJadwal(profilAnakId);

    await _db.simpanJadwal([
      for (final j in jadwal)
        CacheJadwalCompanion.insert(
          id: j['id'] as String,
          rencanaId: j['rencana_id'] as String,
          aktivitasId: j['aktivitas_id'] as String,
          tanggal: DateTime.parse(j['tanggal'] as String),
          waktu: j['waktu'] as String,
          urutan: (j['urutan'] as num).toInt(),
          durasiMenit: (j['durasi_menit'] as num).toInt(),
          tingkatDisesuaikan: (j['tingkat_disesuaikan'] as num).toInt(),
        ),
    ]);
  }

  /// Asks the Edge Function for a fresh week (KF-03).
  Future<String> buatRencana(String profilAnakId) async {
    try {
      final data = await _peladen.mintaRencana(profilAnakId);
      await segarkan(profilAnakId);
      return (data['alasan'] as String?) ?? '';
    } catch (_) {
      throw const KesalahanAuth(
        'Rencana belum dapat disusun. Periksa koneksi Anda, lalu coba lagi.',
      );
    }
  }

  Future<bool> dorongSatuRespons(String klienId) async {
    final menunggu = await _db.responsMenunggu();
    final baris = menunggu.where((r) => r.klienId == klienId).firstOrNull;
    if (baris == null) return true;
    return _dorongRespons(baris);
  }

  /// Drains everything waiting. Safe to call as often as you like: each row
  /// carries the client id the server column is unique on, so a double drain
  /// updates the same row instead of inserting a second one.
  Future<int> kurasAntrean() async {
    var terkirim = 0;

    for (final baris in await _db.responsMenunggu()) {
      if (await _dorongRespons(baris)) terkirim++;
    }

    for (final baris in await _db.checkInMenunggu()) {
      try {
        await _peladen.kirimCheckIn({
          'pengguna_id': _peladen.penggunaId,
          'tanggal': baris.tanggal.toIso8601String().split('T').first,
          'kondisi': baris.kondisi,
        });
        await _db.tandaiCheckInTersinkron(baris.klienId);
        terkirim++;
      } catch (_) {
        // Still offline, or the server is unhappy. Leave it queued.
      }
    }

    return terkirim;
  }

  Future<bool> _dorongRespons(CacheResponsData baris) async {
    try {
      await _peladen.kirimRespons({
        'jadwal_aktivitas_id': baris.jadwalAktivitasId,
        'nilai': baris.nilai,
        'catatan': baris.catatan,
        'dicatat_pada': baris.dicatatPada.toIso8601String(),
        'klien_id': baris.klienId,
      });
      await _db.tandaiResponsTersinkron(baris.klienId);
      return true;
    } catch (_) {
      await _db.naikkanPercobaanRespons(baris.klienId);
      return false;
    }
  }

  Future<int> jumlahMenunggu() => _db.jumlahMenunggu();

  Stream<int> pantauMenunggu() => _db.pantauJumlahMenunggu();
}
