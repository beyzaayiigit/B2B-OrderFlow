import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// `17052026` → `17.05.2026`
class TurkishDateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final limited = digits.length > 8 ? digits.substring(0, 8) : digits;

    final buf = StringBuffer();
    for (var i = 0; i < limited.length; i++) {
      if (i == 2 || i == 4) buf.write('.');
      buf.write(limited[i]);
    }

    final formatted = buf.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Alan tam dolu mu? (8 rakam veya `dd.MM.yyyy`)
bool isTurkishDateInputComplete(String raw) {
  final digits = raw.replaceAll(RegExp(r'\D'), '');
  if (digits.length == 8) return true;
  return RegExp(r'^\d{2}\.\d{2}\.\d{4}$').hasMatch(raw.trim());
}

DateTime? parseTurkishDateString(String raw) {
  final t = raw.trim();

  final dotted = RegExp(r'^(\d{2})\.(\d{2})\.(\d{4})$').firstMatch(t);
  if (dotted != null) {
    return _dateFromParts(
      dotted.group(1)!,
      dotted.group(2)!,
      dotted.group(3)!,
    );
  }

  final digits = t.replaceAll(RegExp(r'\D'), '');
  if (digits.length == 8) {
    return _dateFromParts(
      digits.substring(0, 2),
      digits.substring(2, 4),
      digits.substring(4, 8),
    );
  }

  return null;
}

DateTime? _dateFromParts(String dd, String mm, String yyyy) {
  final day = int.tryParse(dd);
  final month = int.tryParse(mm);
  final year = int.tryParse(yyyy);
  if (day == null || month == null || year == null) return null;
  if (month < 1 || month > 12 || day < 1 || day > 31) return null;
  try {
    return DateTime(year, month, day);
  } catch (_) {
    return null;
  }
}

String formatTurkishDateInput(DateTime date) {
  return DateFormat('dd.MM.yyyy').format(date);
}
