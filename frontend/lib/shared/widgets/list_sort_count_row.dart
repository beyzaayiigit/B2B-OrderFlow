import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// Liste üstü: filtrelenmiş kart sayısı + sıra yönünü ters çeviren ok.
class ListSortCountRow extends StatelessWidget {
  const ListSortCountRow({
    required this.count,
    required this.arrowPointsUp,
    required this.onToggle,
    this.unitLabel = 'sipariş',
    this.sortHint,
    super.key,
  });

  final int count;
  final bool arrowPointsUp;
  final VoidCallback onToggle;
  final String unitLabel;
  final String? sortHint;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '$count $unitLabel',
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 15,
            color: AppColors.text,
          ),
        ),
        if (sortHint != null) ...[
          const SizedBox(width: 8),
          Text(
            sortHint!,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        const Spacer(),
        IconButton(
          onPressed: onToggle,
          tooltip: 'Sıralamayı ters çevir',
          icon: Icon(
            arrowPointsUp
                ? Icons.arrow_upward_rounded
                : Icons.arrow_downward_rounded,
            size: 20,
          ),
          color: AppColors.navyDark,
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }
}
