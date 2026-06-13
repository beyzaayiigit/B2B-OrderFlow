import 'package:flutter/material.dart';

/// TextileFlow — Palet 2 / Çok Renkli (logodan türetilmiş)
/// İndigo birincil + turuncu / mercan / teal aksanlar; layout token isimleri aynı.
abstract final class AppColors {
  static const navy = Color(0xFF6047D6);
  static const navyDark = Color(0xFF2D2A6E);

  /// Aksan / bilgi tonu (teal) — durum rozetleri ve ikincil vurgular.
  static const softBlue = Color(0xFF14B8A6);

  /// Marka aksanları (logonun turuncu ve mercan yaprakları).
  static const secondary = Color(0xFFF07818);
  static const tertiary = Color(0xFFF0554C);

  static const surface = Color(0xFFF8FAFC);
  static const surfaceContainer = Color(0xFFFFFFFF);
  static const surfaceMuted = Color(0xFFF4F2FB);
  static const border = Color(0xFFE7E5F4);
  static const text = Color(0xFF17142B);
  static const textMuted = Color(0xFF6B6786);
  static const success = Color(0xFF16A34A);
  static const warning = Color(0xFFF97316);
  static const critical = Color(0xFFEF4444);
  static const neutral = Color(0xFF828282);
}
