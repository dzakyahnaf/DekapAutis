/// Reads a PostgREST embed that holds at most one row.
///
/// PostgREST decides the shape from the schema, not the query: a foreign key
/// covered by a unique constraint makes the relationship one-to-one, and the
/// embed arrives as a single object or null. Without that constraint it
/// arrives as a list. `catatan_respons` has `satu_respons_per_jadwal`, so it is
/// an object today - and code that cast it to `List?` threw on every row of the
/// report screen in production while every test, running against fakes, passed.
///
/// Both shapes are accepted so that dropping or adding such a constraint later
/// cannot break a reader again.
Map<String, dynamic>? satuTertanam(Object? mentah) => switch (mentah) {
  final Map<String, dynamic> m => m,
  final Map<dynamic, dynamic> m => Map<String, dynamic>.from(m),
  final List<dynamic> l when l.isNotEmpty => satuTertanam(l.first),
  _ => null,
};
