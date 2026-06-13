import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';

/// Sipariş oluşturma ve takip detayında kullanılan renk adları ve tonları.
const defaultColorOrder = [
  'Siyah',
  'Beyaz',
  'Lacivert',
  'Mürdüm',
  'Nefti',
  'Haki',
  'Taş',
  'Bej',
  'Kahverengi',
  'Açık Kahverengi',
  'Kiremit',
  'Antrasit',
  'İndigo',
  'Bebe Mavisi',
  'Gri',
  'Sarı',
  'Kırmızı',
  'Bordo',
  'Füme',
  'Petrol Mavisi',
  'Vizon',
];

const orderColorPalette = <String, Color>{
  'Siyah': Color(0xFF1B1B1B),
  'Beyaz': Color(0xFFFFFFFF),
  'Lacivert': Color(0xFF1D2A4A),
  'Mürdüm': Color(0xFF5A2A5C),
  'Nefti': Color(0xFF2F4F4F),
  'Haki': Color(0xFF6B7A4A),
  'Taş': Color(0xFFD4C7B0),
  'Bej': Color(0xFFE8DCC8),
  'Kahverengi': Color(0xFF6B4423),
  'Açık Kahverengi': Color(0xFFC4A484),
  'Kiremit': Color(0xFFB55239),
  'Antrasit': Color(0xFF383838),
  'İndigo': Color(0xFF3F51B5),
  'Bebe Mavisi': Color(0xFF93C5FD),
  'Gri': Color(0xFF9CA3AF),
  'Sarı': Color(0xFFFDE047),
  'Kırmızı': Color(0xFFEF4444),
  'Bordo': Color(0xFF7F1D1D),
  'Füme': Color(0xFF4B5563),
  'Petrol Mavisi': Color(0xFF0F766E),
  'Vizon': Color(0xFFA16207),
};

Color toneForOrderColorName(String name) =>
    orderColorPalette[name] ?? AppColors.neutral;
