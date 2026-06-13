import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// Alıcı takip / sevk listelerinde sipariş sayısı + toplam adet özeti.
class BuyerOrderSummaryCard extends StatelessWidget {
  const BuyerOrderSummaryCard({
    required this.orderCountLabel,
    required this.orderCount,
    required this.totalUnits,
    this.orderCountIcon = Icons.receipt_long_outlined,
    super.key,
  });

  final String orderCountLabel;
  final int orderCount;
  final int totalUnits;
  final IconData orderCountIcon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: _SummaryMetric(
                icon: orderCountIcon,
                label: orderCountLabel,
                value: '$orderCount',
              ),
            ),
            Container(
              width: 1,
              height: 36,
              color: AppColors.border,
              margin: const EdgeInsets.symmetric(horizontal: 12),
            ),
            Expanded(
              child: _SummaryMetric(
                icon: Icons.layers_outlined,
                label: 'Toplam adet',
                value: '$totalUnits',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.navy),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Takip sekmesi durum filtresine göre sol metrik etiketi.
String trackingSummaryOrderLabel(String statusKey) {
  switch (statusKey) {
    case 'submitted':
      return 'Bekleyen sipariş';
    case 'approved':
      return 'Onaylanan sipariş';
    case 'in_production':
      return 'Üretimde sipariş';
    default:
      return 'Aktif sipariş';
  }
}
