/// Arama: içinde rastgele `contains` yok; metnin **başından** önek eşleşmesi
/// veya tire/boşluk sonrası **yeni bir bölümün başından** önek eşleşmesi.
///
/// - [query] boş: her şey geçer.
/// - Tek karakter: filtre uygulanmaz.
/// - İki ve üzeri karakter: tam metin `startsWith(query)` **veya** bölünen
///   herhangi bir bölüm `startsWith(query)` (örn. `MD-2024-X01` içinde `2024`).
final RegExp _segmentSplit = RegExp(r'[\s\-_/]+');

bool matchesSearchPrefix(String field, String queryRaw) {
  final q = queryRaw.trim().toLowerCase();
  if (q.isEmpty) return true;
  if (q.length < 2) return true;

  final f = field.trim().toLowerCase();
  if (f.isEmpty) return false;

  if (f.startsWith(q)) return true;

  for (final part in f.split(_segmentSplit)) {
    if (part.isEmpty) continue;
    if (part.startsWith(q)) return true;
  }
  return false;
}

/// [fields] içinden herhangi biri [query] ile eşleşirse `true`.
bool matchesAnySearchPrefix(Iterable<String> fields, String queryRaw) {
  final q = queryRaw.trim().toLowerCase();
  if (q.isEmpty) return true;
  if (q.length < 2) return true;
  for (final field in fields) {
    if (matchesSearchPrefix(field, q)) return true;
  }
  return false;
}
