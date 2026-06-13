/// Alıcı sipariş notu (üretici / Excel ile paylaşılan metin).
const kBuyerOrderNoteMaxLength = 500;

/// Boşsa `null`; fazlaysa ilk [kBuyerOrderNoteMaxLength] karakter.
String? normalizeBuyerOrderNote(String? raw) {
  final t = raw?.trim();
  if (t == null || t.isEmpty) return null;
  if (t.length <= kBuyerOrderNoteMaxLength) return t;
  return t.substring(0, kBuyerOrderNoteMaxLength);
}

bool isBuyerOrderNoteTooLong(String? raw) {
  final t = raw?.trim();
  if (t == null || t.isEmpty) return false;
  return t.length > kBuyerOrderNoteMaxLength;
}
