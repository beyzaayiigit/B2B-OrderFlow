import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../shared/widgets/status_badge.dart';

/// Talep kartlarında sipariş rozetini “talep onayı” ile karıştırmamak için açık etiket.
class RequestThreadOrderStatusRow extends StatelessWidget {
  const RequestThreadOrderStatusRow({
    required this.orderStatusKey,
    super.key,
  });

  final String orderStatusKey;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message:
          'Bağlı siparişin güncel durumu (üretici akışı). Güncelleme talebinin onayı değildir.',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.local_shipping_outlined,
            size: 16,
            color: AppColors.textMuted.withValues(alpha: 0.9),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Sipariş durumu',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          StatusBadge.order(orderStatusKey),
        ],
      ),
    );
  }
}
