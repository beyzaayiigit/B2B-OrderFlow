/// Sipariş / teslim etiketleri (Türkçe ay adları; `intl` yerelleştirme gerektirmez).
String formatOrderDateLong(DateTime date) {
  return '${date.day} ${_turkishMonth(date.month)} ${date.year}';
}

String formatOrderDateTimeLabel(DateTime date) {
  final h = date.hour.toString().padLeft(2, '0');
  final m = date.minute.toString().padLeft(2, '0');
  return '${formatOrderDateLong(date)}, $h:$m';
}

String _turkishMonth(int month) {
  const months = [
    '',
    'Ocak',
    'Şubat',
    'Mart',
    'Nisan',
    'Mayıs',
    'Haziran',
    'Temmuz',
    'Ağustos',
    'Eylül',
    'Ekim',
    'Kasım',
    'Aralık',
  ];
  if (month < 1 || month > 12) return '';
  return months[month];
}

/// Karşılaştırma için gün başına normalize eder.
DateTime dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);
