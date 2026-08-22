/// Where a caregiver is searching from, resolved without a geocoding service.
///
/// L.9 needs one point to measure distances against. A typed city rather than a
/// device GPS fix: asking for location permission to order a list of five
/// clinics is a poor trade, and a caregiver looking for a practice near their
/// mother's house is not helped by where they happen to be standing.
///
/// A lookup table rather than an API, because the alternative is a paid key and
/// a network round trip for something the directory has to do offline anyway.
/// The list is short and honest about being short - an unrecognised city
/// returns null and the screen says so, rather than guessing at a point and
/// presenting a confident wrong ordering.
library;

import 'jarak.dart';

/// Approximate city centres. Add to this as the directory grows.
const kotaDikenal = <String, Koordinat>{
  'surabaya': Koordinat(-7.2575, 112.7521),
  'sidoarjo': Koordinat(-7.4478, 112.7183),
  'gresik': Koordinat(-7.1554, 112.6531),
  'malang': Koordinat(-7.9666, 112.6326),
  'jakarta': Koordinat(-6.2088, 106.8456),
  'bandung': Koordinat(-6.9175, 107.6191),
  'yogyakarta': Koordinat(-7.7956, 110.3695),
  'semarang': Koordinat(-6.9932, 110.4203),
};

/// The point to measure from, or null when the input names no city we know.
Koordinat? koordinatKota(String masukan) {
  final bersih = masukan.trim().toLowerCase();
  if (bersih.isEmpty) return null;
  for (final entry in kotaDikenal.entries) {
    if (bersih.contains(entry.key)) return entry.value;
  }
  return null;
}
