/// Notification kinds and what Calm Mode does to them.
///
/// Pure Dart, no Flutter: this is a policy decision about the child's care, not
/// a rendering detail, and it is tested with `package:test` for that reason.
///
/// The distinction that matters here is between *muting* and *hiding*. Calm
/// Mode silences a notification - no sound, no vibration, no banner over
/// whatever the caregiver is doing - but it never removes it from the list on
/// L.17. Someone who turned on Calm Mode asked for less noise, not for less
/// information about their child, and quietly dropping a notification would be
/// a different and much worse thing than the switch promises.
library;

enum JenisNotifikasi {
  /// The plan was adapted after the child's recorded responses.
  penyesuaianRencana(
    dbValue: 'penyesuaian',
    label: 'Penyesuaian rencana',
    penting: true,
    alasan:
        'Rencana anak berubah, dan pengasuh perlu tahu sebelum sesi '
        'berikutnya.',
  ),

  /// A professional answered a schedule request.
  persetujuanJadwal(
    dbValue: 'jadwal',
    label: 'Persetujuan jadwal',
    penting: true,
    alasan: 'Ada orang lain yang menunggu jawaban, dan waktunya terikat.',
  ),

  /// A gentle nudge that today's activity has not been recorded.
  aktivitasBelumTercatat(
    dbValue: 'belum_dicatat',
    label: 'Aktivitas belum tercatat',
    penting: false,
    alasan: 'Pengingat, bukan kabar baru. Tetap muncul di daftar.',
  ),

  /// Someone replied in the community.
  balasanKomunitas(
    dbValue: 'balasan',
    label: 'Balasan komunitas',
    penting: false,
    alasan: 'Bisa dibaca kapan saja.',
  ),

  /// A new library article passed review.
  artikelBaru(
    dbValue: 'artikel',
    label: 'Artikel baru ditinjau',
    penting: false,
    alasan: 'Informasi, tanpa tenggat.',
  );

  const JenisNotifikasi({
    required this.dbValue,
    required this.label,
    required this.penting,
    required this.alasan,
  });

  /// Matches the `jenis` check constraint on the `notifikasi` table. Spelled
  /// out rather than derived from `name`: the Dart names read as sentences and
  /// the column values are short, and letting them drift apart would mean
  /// every insert failing the constraint at runtime.
  final String dbValue;

  /// Indonesian label, shown as the group heading on L.17.
  final String label;

  /// Whether this survives Calm Mode with its sound intact.
  final bool penting;

  /// Why it was classified that way. Kept next to the decision so the next
  /// person changing it can see the reasoning rather than guessing at it.
  final String alasan;

  static JenisNotifikasi fromDb(String value) =>
      JenisNotifikasi.values.firstWhere(
        (j) => j.dbValue == value,
        orElse: () => JenisNotifikasi.artikelBaru,
      );
}

/// Whether this notification may make a sound right now.
///
/// Effect 4 of Calm Mode. Note what this does *not* control: whether the
/// notification is stored, and whether it appears on L.17. Both always happen.
bool bolehBerbunyi(JenisNotifikasi jenis, {required bool modeTenang}) =>
    !modeTenang || jenis.penting;

/// The kinds that go quiet when Calm Mode is on. Useful for showing the user
/// what the switch will actually do before they flip it.
List<JenisNotifikasi> yangDibisukan() =>
    JenisNotifikasi.values.where((j) => !j.penting).toList();
