import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// Sipariş durumlarının marka paleti renkleri (çok renkli aksanlar).
Color orderStatusColor(String status) => switch (status) {
  'submitted' => AppColors.warning, // turuncu
  'approved' => AppColors.success, // yeşil
  'in_production' => AppColors.softBlue, // teal
  'shipped' => AppColors.navy, // mor
  _ => AppColors.neutral, // gri
};

class StatusBadge extends StatelessWidget {
  const StatusBadge({required this.label, required this.color, super.key});

  final String label;
  final Color color;

  factory StatusBadge.order(String status) {
    final color = orderStatusColor(status);
    final label = switch (status) {
      // Alıcı gönderdi, üretici henüz onaylamadı (üretici tarafıyla aynı anahtar: submitted)
      'submitted' => 'Bekleniyor',
      'approved' => 'Onaylandı',
      'in_production' => 'Üretimde',
      'shipped' => 'Sevk Edildi',
      _ => 'Gönderildi',
    };
    return StatusBadge(label: label, color: color);
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
