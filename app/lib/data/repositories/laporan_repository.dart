import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/laporan/metrik_laporan.dart';
import 'auth_repository.dart';

/// How far back a report looks (L.8).
enum PeriodeLaporan {
  duaMinggu('2 minggu', 14),
  satuBulan('1 bulan', 30),
  tigaBulan('3 bulan', 90);

  const PeriodeLaporan(this.label, this.hari);

  final String label;
  final int hari;
}

/// One professional who currently has, or had, access to a report.
class IzinBerbagi {
  const IzinBerbagi({
    required this.id,
    required this.laporanId,
    required this.profesionalId,
    required this.namaProfesional,
    required this.spesialisasi,
    required this.aktif,
    required this.diberikanPada,
    this.dicabutPada,
  });

  factory IzinBerbagi.fromMap(Map<String, dynamic> m) {
    final pr = m['profesional'] as Map<String, dynamic>?;
    return IzinBerbagi(
      id: m['id'] as String,
      laporanId: m['laporan_id'] as String,
      profesionalId: m['profesional_id'] as String,
      namaProfesional: pr?['nama_lengkap'] as String? ?? 'Tenaga profesional',
      spesialisasi: pr?['spesialisasi'] as String? ?? '',
      aktif: m['status'] == 'aktif',
      diberikanPada: DateTime.parse(m['diberikan_pada'] as String),
      dicabutPada: m['dicabut_pada'] == null
          ? null
          : DateTime.parse(m['dicabut_pada'] as String),
    );
  }

  final String id;
  final String laporanId;
  final String profesionalId;
  final String namaProfesional;
  final String spesialisasi;
  final bool aktif;
  final DateTime diberikanPada;
  final DateTime? dicabutPada;
}

/// Reports, and who may see them (KF-10, KF-11).
///
/// Every figure is computed here in Dart via [hitungMetrik]; the Edge Function
/// receives them already finished and only writes sentences. Consent is
/// per report and per action, and revoking it cuts access off through RLS
/// rather than by hiding a row in the interface.
/// Turns the rows of the report query into notes.
///
/// Pure and public so a test can feed it the exact JSON the server returns,
/// which is the only thing that would have caught what went wrong here.
///
/// `catatan_respons` arrives as an OBJECT, not a list. PostgREST reads
/// `satu_respons_per_jadwal unique (jadwal_aktivitas_id)` in migration 001,
/// concludes the relationship is one-to-one, and embeds a single object -
/// exactly as it should. The old code cast it to `List?`, which threw on the
/// first row and left the whole report screen showing "Layanan sedang tidak
/// dapat dihubungi". No test caught it because every test used fakes and the
/// SQL checks query Postgres directly, so nothing ever went through PostgREST.
///
/// Both shapes are accepted deliberately: dropping that unique constraint
/// would flip the embed back to a list, and this should not break again if
/// anyone ever does.
List<CatatanLaporan> catatanDariBaris(Iterable<Map<String, dynamic>> baris) {
  final catatan = <CatatanLaporan>[];
  for (final b in baris) {
    final mentah = b['catatan_respons'];
    final respons = switch (mentah) {
      final Map<String, dynamic> m => m,
      final List<dynamic> l when l.isNotEmpty => l.first as Map,
      _ => null,
    };
    final nilai = respons == null
        ? null
        : NilaiRespons.fromDb(respons['nilai'] as String);
    catatan.add(
      CatatanLaporan(
        kategori: Kategori.fromDb(
          (b['aktivitas'] as Map)['kategori'] as String,
        ),
        tanggal: DateTime.parse(b['tanggal'] as String),
        nilai: nilai,
      ),
    );
  }
  return catatan;
}

class LaporanRepository {
  LaporanRepository(this._client);

  final SupabaseClient _client;

  /// Reads the raw notes for a period and computes every figure locally.
  Future<MetrikLaporan> hitung({
    required String profilAnakId,
    required PeriodeLaporan periode,
    DateTime? sampai,
  }) => _jalankan(() async {
    final akhir = sampai ?? DateTime.now();
    final mulai = akhir.subtract(Duration(days: periode.hari - 1));

    final baris = await _client
        .from('jadwal_aktivitas')
        .select(
          'tanggal, aktivitas!inner(kategori), '
          'rencana!inner(profil_anak_id), catatan_respons(nilai)',
        )
        .eq('rencana.profil_anak_id', profilAnakId)
        .gte('tanggal', mulai.toIso8601String().split('T').first)
        .lte('tanggal', akhir.toIso8601String().split('T').first);

    final catatan = catatanDariBaris(baris);

    // Categories rule D_tandai flagged, carried through from the most recent
    // report so a professional sees the same flag the engine raised.
    final penanda = <Kategori>{};
    final terakhir = await _client
        .from('laporan')
        .select('penanda_perhatian')
        .eq('profil_anak_id', profilAnakId)
        .order('dibuat_pada', ascending: false)
        .limit(1)
        .maybeSingle();
    for (final p in (terakhir?['penanda_perhatian'] as List? ?? const [])) {
      penanda.add(Kategori.fromDb(p as String));
    }

    return hitungMetrik(
      catatan: catatan,
      periodeMulai: mulai,
      periodeSelesai: akhir,
      penandaPerhatian: penanda,
    );
  });

  /// Asks the Edge Function for the narrative and saves the report.
  ///
  /// The metrics travel as finished numbers. If the model invents one, the
  /// function rejects its whole narrative and returns the deterministic
  /// version - the client never has to know which it got.
  Future<String> buatLaporan({
    required String profilAnakId,
    required MetrikLaporan metrik,
  }) => _jalankan(() async {
    final res = await _client.functions.invoke(
      'summarize-report',
      body: {
        'profil_anak_id': profilAnakId,
        'metrik': {
          ...metrik.toMetrikJson(),
          'tren_mingguan': [
            for (final t in metrik.trenMingguan)
              {'persen': t.persenMudah, 'jumlah': t.jumlahTercatat},
          ],
          'per_kategori': [
            for (final k in metrik.perKategori)
              {
                'kategori': k.kategori.dbValue,
                'label': k.kategori.label,
                'persen': k.persenMudah,
                'jumlah': k.jumlahTercatat,
                'tren': k.tren.name,
              },
          ],
          'penanda_perhatian': [
            for (final k in metrik.penandaPerhatian) k.dbValue,
          ],
          'periode_mulai': metrik.periodeMulai
              .toIso8601String()
              .split('T')
              .first,
          'periode_selesai': metrik.periodeSelesai
              .toIso8601String()
              .split('T')
              .first,
        },
      },
    );
    final data = Map<String, dynamic>.from(res.data as Map);
    return (data['ringkasan'] as String?) ?? '';
  });

  Future<List<Map<String, dynamic>>> daftarLaporan(String profilAnakId) =>
      _jalankan(() async {
        final baris = await _client
            .from('laporan')
            .select()
            .eq('profil_anak_id', profilAnakId)
            .order('dibuat_pada', ascending: false);
        return List<Map<String, dynamic>>.from(baris);
      });

  // ------------------------------------------------------------- consent --

  Future<List<Map<String, dynamic>>> daftarProfesional() => _jalankan(() async {
    final baris = await _client
        .from('profesional')
        .select('id, nama_lengkap, gelar, spesialisasi, kota, terverifikasi')
        .order('nama_lengkap');
    return List<Map<String, dynamic>>.from(baris);
  });

  /// Grants access to one report, for one professional. Never a blanket
  /// permission: Bab 4.3 asks for explicit consent per action.
  Future<void> bagikan({
    required String laporanId,
    required String profesionalId,
  }) => _jalankan(() async {
    await _client.from('izin_berbagi').insert({
      'laporan_id': laporanId,
      'profesional_id': profesionalId,
    });
  });

  /// Withdraws access. The professional stops being able to read the report at
  /// this moment, enforced by RLS rather than by the interface - which is what
  /// check 4 in scripts/test_rls.sql proves.
  Future<void> cabut(String izinId) => _jalankan(() async {
    await _client
        .from('izin_berbagi')
        .update({
          'status': 'dicabut',
          'dicabut_pada': DateTime.now().toIso8601String(),
        })
        .eq('id', izinId);
  });

  Future<List<IzinBerbagi>> daftarIzin() => _jalankan(() async {
    final baris = await _client
        .from('izin_berbagi')
        .select(
          'id, laporan_id, profesional_id, status, diberikan_pada, dicabut_pada, '
          'profesional(nama_lengkap, spesialisasi)',
        )
        .order('diberikan_pada', ascending: false);
    return [
      for (final b in baris) IzinBerbagi.fromMap(Map<String, dynamic>.from(b)),
    ];
  });

  Future<T> _jalankan<T>(Future<T> Function() aksi) async {
    try {
      return await aksi();
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        throw const KesalahanAuth(
          'Laporan ini sudah dibagikan kepada tenaga profesional tersebut.',
        );
      }
      throw const KesalahanAuth(
        'Data laporan belum dapat diambil. Periksa koneksi Anda, lalu coba lagi.',
      );
    } catch (_) {
      throw const KesalahanAuth(
        'Layanan sedang tidak dapat dihubungi. Coba lagi sebentar lagi.',
      );
    }
  }
}
