/// Decides which reminders are due right now, and whether each may make a
/// sound. Pure Dart: no plugin, no platform channel, no clock of its own.
///
/// The scheduling *decision* is separated from the platform call on purpose.
/// Deciding to nudge a caregiver about their child is a judgement with real
/// consequences at eleven at night, and it should be testable without an
/// Android emulator attached.
library;

import 'jenis_notifikasi.dart';

/// One scheduled activity, reduced to what the reminder logic needs.
class JadwalRingkas {
  const JadwalRingkas({
    required this.id,
    required this.judul,
    required this.waktu,
    required this.sudahDicatat,
  });

  final String id;
  final String judul;

  /// When the activity was planned for.
  final DateTime waktu;

  /// Whether the caregiver has already recorded a response.
  final bool sudahDicatat;
}

/// A reminder ready to hand to the platform.
class Pengingat {
  const Pengingat({
    required this.jenis,
    required this.judul,
    required this.isi,
    required this.berbunyi,
  });

  final JenisNotifikasi jenis;
  final String judul;
  final String isi;

  /// False means: show it in the list, but silently. Calm Mode, effect 4.
  final bool berbunyi;
}

/// Nothing is raised before this hour or after it.
///
/// A caregiver of a child with a sleep-disrupted routine does not need their
/// phone speaking up at midnight, and an app that nags at 02.00 gets its
/// notifications switched off entirely - after which it cannot help at all.
const jamPalingAwal = 8;
const jamPalingAkhir = 20;

/// How long after the planned time an activity is considered missed. Short
/// enough to still be the same part of the day, long enough that a caregiver
/// running fifteen minutes behind is not chased.
const tenggangDefault = Duration(minutes: 45);

/// Reminders due at [sekarang], newest schedule first.
///
/// At most one is returned however many activities were missed. Five separate
/// notifications about five missed activities is not five times as helpful; it
/// is a phone the caregiver puts face down.
List<Pengingat> pengingatAktivitas({
  required DateTime sekarang,
  required List<JadwalRingkas> jadwal,
  required bool modeTenang,
  Duration tenggang = tenggangDefault,
}) {
  if (sekarang.hour < jamPalingAwal || sekarang.hour >= jamPalingAkhir) {
    return const [];
  }

  final terlewat =
      jadwal
          .where(
            (j) =>
                !j.sudahDicatat &&
                _hariSama(j.waktu, sekarang) &&
                sekarang.difference(j.waktu) >= tenggang,
          )
          .toList()
        ..sort((a, b) => a.waktu.compareTo(b.waktu));

  if (terlewat.isEmpty) return const [];

  const jenis = JenisNotifikasi.aktivitasBelumTercatat;
  final jumlah = terlewat.length;

  return [
    Pengingat(
      jenis: jenis,
      judul: jumlah == 1
          ? 'Satu aktivitas belum tercatat'
          : '$jumlah aktivitas belum tercatat',
      // Names the first one so the notification is actionable, and never
      // implies the caregiver did something wrong.
      isi: jumlah == 1
          ? '"${terlewat.first.judul}" masih menunggu catatan Anda. '
                'Mencatat "belum mau" juga membantu.'
          : 'Termasuk "${terlewat.first.judul}". Mencatat "belum mau" juga '
                'membantu.',
      berbunyi: bolehBerbunyi(jenis, modeTenang: modeTenang),
    ),
  ];
}

bool _hariSama(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
