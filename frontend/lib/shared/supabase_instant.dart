/// Supabase `timestamptz` → cihazın yerel saati.
///
/// PostgREST bazen `2026-05-20T14:30:00` gibi offset’siz döner; bu UTC kabul
/// edilir. Offset veya `Z` varsa normal parse + [DateTime.toLocal] kullanılır.
DateTime parseSupabaseInstant(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return DateTime.now();

  final hasOffset = trimmed.endsWith('Z') ||
      RegExp(r'[+-]\d{2}:\d{2}$').hasMatch(trimmed);

  final parsed = DateTime.tryParse(trimmed);
  if (parsed == null) return DateTime.now();

  if (parsed.isUtc) return parsed.toLocal();

  if (!hasOffset) {
    return DateTime.utc(
      parsed.year,
      parsed.month,
      parsed.day,
      parsed.hour,
      parsed.minute,
      parsed.second,
      parsed.millisecond,
      parsed.microsecond,
    ).toLocal();
  }

  return parsed.toLocal();
}
