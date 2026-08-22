/// Applying a professional's response to the plan - the closing arc of the
/// loop in Gambar 7.1.
///
/// This is deliberately *not* a sixth rule of [AdaptationEngine]. The five
/// rules read what a caregiver recorded and move the plan on their own. This
/// moves the plan because a person asked, and the difference matters in three
/// ways:
///
///   * It only runs when the caregiver applies it. Nothing a professional
///     writes rewrites a child's plan on its own - the response arrives, the
///     caregiver reads it, and they decide.
///   * It reads only the structured part of the response. The prose stays
///     prose and is never parsed: a plan change has to be explainable in real
///     numbers, and a sentence cannot be.
///   * The categories it touches are marked corrected-by-hand for the period,
///     so the automatic rules leave them alone. Without that, rule C could
///     redistribute the week's sessions and quietly undo the suggestion the
///     same week it was applied.
library;

import 'adaptation_engine.dart';

/// Bounds the database also enforces (migration 009).
const minDurasiSaran = 5;
const maksDurasiSaran = 60;

/// The actionable half of a response.
class SaranProfesional {
  const SaranProfesional({
    required this.tanggapanId,
    required this.kategoriDitekankan,
    this.durasiMenit,
  });

  final String tanggapanId;

  /// Categories the professional asked for more of.
  final Set<Kategori> kategoriDitekankan;

  /// Suggested session length, or null to leave durations alone.
  final int? durasiMenit;

  bool get kosong => kategoriDitekankan.isEmpty && durasiMenit == null;
}

class HasilPenerapanSaran {
  const HasilPenerapanSaran({
    required this.porsi,
    required this.durasi,
    required this.dikoreksiManual,
    required this.log,
  });

  final Map<Kategori, int> porsi;
  final Map<Kategori, int> durasi;

  /// Hand back to [MasukanAdaptasi.dikoreksiManual] on the next run.
  final Set<Kategori> dikoreksiManual;

  final List<BarisAdaptasiLog> log;

  /// False when the suggestion asked for something the plan already did.
  bool get adaPerubahan => log.isNotEmpty;
}

/// Applies the structured part of a response to the current plan.
///
/// Returns the plan unchanged, with an empty log, when the suggestion asks for
/// nothing the plan is not already doing. An `adaptasi_log` row is written only
/// where a number actually moved - a row saying a value went from 3 to 3 is
/// noise in the one place that has to stay trustworthy.
HasilPenerapanSaran terapkanSaranProfesional({
  required SaranProfesional saran,
  required Map<Kategori, int> porsi,
  required Map<Kategori, int> durasi,
}) {
  final porsiBaru = Map<Kategori, int>.from(porsi);
  final durasiBaru = Map<Kategori, int>.from(durasi);
  final log = <BarisAdaptasiLog>[];
  final disentuh = <Kategori>{};

  for (final kategori in saran.kategoriDitekankan) {
    final sebelum = porsiBaru[kategori] ?? 0;
    final sesudah = (sebelum + 1).clamp(0, maksSesiMingguan);

    if (sesudah != sebelum) {
      porsiBaru[kategori] = sesudah;
      disentuh.add(kategori);
      log.add(
        BarisAdaptasiLog(
          aturanId: 'F_profesional',
          kategori: kategori,
          nilaiSebelum: {'porsi': sebelum},
          nilaiSesudah: {'porsi': sesudah},
          alasan:
              'Tenaga profesional yang membaca laporan Anda menyarankan lebih '
              'banyak latihan ${kategori.label.toLowerCase()}. Sesi '
              '${kategori.label.toLowerCase()} minggu ini naik dari $sebelum '
              'menjadi $sesudah. Anda yang menyetujui penerapannya.',
          dikoreksiManual: true,
        ),
      );
    } else {
      // Already at the weekly ceiling. Still hands-off for the period, so the
      // automatic rules do not lower it right after a professional asked for
      // more of it.
      disentuh.add(kategori);
    }
  }

  final diminta = saran.durasiMenit;
  if (diminta != null) {
    final target = diminta.clamp(minDurasiSaran, maksDurasiSaran);
    // With no categories named, a duration applies to the whole plan.
    final sasaran = saran.kategoriDitekankan.isEmpty
        ? durasiBaru.keys.toSet()
        : saran.kategoriDitekankan;

    for (final kategori in sasaran) {
      final sebelum = durasiBaru[kategori];
      if (sebelum == null || sebelum == target) continue;

      durasiBaru[kategori] = target;
      disentuh.add(kategori);
      log.add(
        BarisAdaptasiLog(
          aturanId: 'F_profesional',
          kategori: kategori,
          nilaiSebelum: {'durasi_menit': sebelum},
          nilaiSesudah: {'durasi_menit': target},
          alasan:
              'Tenaga profesional menyarankan sesi '
              '${kategori.label.toLowerCase()} sepanjang $target menit. '
              'Sebelumnya $sebelum menit. Anda yang menyetujui penerapannya.',
          dikoreksiManual: true,
        ),
      );
    }
  }

  return HasilPenerapanSaran(
    porsi: porsiBaru,
    durasi: durasiBaru,
    dikoreksiManual: disentuh,
    log: log,
  );
}
