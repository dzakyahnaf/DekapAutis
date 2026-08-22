/// Great-circle distance, computed on the device.
///
/// docs/DEVIATIONS.md records why there is no map SDK: L.9 shows a distance and
/// a filter, never a map. Google Maps Platform would require a billing account
/// for no functional gain on this screen, and a directory that stops working
/// when a card expires is worse than one that does the arithmetic itself.
///
/// Pure Dart with no Flutter and no network, so it is checked against reference
/// values rather than eyeballed on a screen.
library;

import 'dart:math' as math;

/// Mean Earth radius in kilometres. The value the haversine formula assumes.
const radiusBumiKm = 6371.0088;

class Koordinat {
  const Koordinat(this.lintang, this.bujur);

  /// Degrees, -90 to 90.
  final double lintang;

  /// Degrees, -180 to 180.
  final double bujur;

  bool get sah =>
      lintang >= -90 &&
      lintang <= 90 &&
      bujur >= -180 &&
      bujur <= 180 &&
      !lintang.isNaN &&
      !bujur.isNaN;
}

double _rad(double derajat) => derajat * math.pi / 180;

/// Distance in kilometres between two points.
///
/// Haversine rather than a planar approximation: Surabaya to Jakarta is far
/// enough that flat-earth arithmetic is visibly wrong, and the directory is
/// meant to work for a family who moved.
double jarakKm(Koordinat a, Koordinat b) {
  final dLintang = _rad(b.lintang - a.lintang);
  final dBujur = _rad(b.bujur - a.bujur);
  final lat1 = _rad(a.lintang);
  final lat2 = _rad(b.lintang);

  final h =
      math.pow(math.sin(dLintang / 2), 2) +
      math.cos(lat1) * math.cos(lat2) * math.pow(math.sin(dBujur / 2), 2);

  return 2 * radiusBumiKm * math.asin(math.min(1, math.sqrt(h)));
}

/// How a distance is written on a card.
///
/// Under a kilometre it is metres, because "0,4 km" reads as further away than
/// "400 m" even though it is not. Past fifty kilometres the decimal is dropped:
/// nobody chooses a therapist on the strength of 62,3 against 62,8.
String jarakTampil(double km) {
  if (km.isNaN || km.isInfinite || km < 0) return '-';
  if (km < 1) return '${(km * 1000).round()} m';
  if (km < 50) return '${km.toStringAsFixed(1).replaceAll('.', ',')} km';
  return '${km.round()} km';
}

/// Sorts nearest first, with unknown locations last rather than first.
///
/// A professional whose coordinates were never filled in must not float to the
/// top of the list on a distance of zero - which is what sorting nulls as 0
/// would do, and it would put the least-complete entries in front of a
/// caregiver looking for help.
List<T> urutkanTerdekat<T>(
  List<T> daftar,
  Koordinat? dariMana,
  Koordinat? Function(T) posisi,
) {
  if (dariMana == null || !dariMana.sah) return daftar;

  final berjarak = <(T, double)>[];
  final tanpaPosisi = <T>[];
  for (final item in daftar) {
    final p = posisi(item);
    if (p == null || !p.sah) {
      tanpaPosisi.add(item);
    } else {
      berjarak.add((item, jarakKm(dariMana, p)));
    }
  }
  berjarak.sort((x, y) => x.$2.compareTo(y.$2));
  return [...berjarak.map((e) => e.$1), ...tanpaPosisi];
}
