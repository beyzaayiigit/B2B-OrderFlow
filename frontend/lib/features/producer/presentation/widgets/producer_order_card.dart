import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../shared/widgets/catalog_display_image.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../domain/producer_order.dart';

/// [summary]: liste özetı — renk/adet/teslim satırları yalnızca detay sayfasında.
/// [full]: çipler + renk dağılımı satırı dahil (ör. Üretim sekmesi).
enum ProducerOrderCardLayout { summary, full }

/// Üretici tarafındaki listelerde (Gelenler, Üretim) ortak kullanılan,
/// model thumbnail'ı ve sipariş özetini bir arada gösteren kart.
class ProducerOrderCard extends StatelessWidget {
  const ProducerOrderCard({
    required this.order,
    this.layout = ProducerOrderCardLayout.full,
    this.showDueDateInSummary = false,
    this.trailing,
    this.actions = const [],
    super.key,
  });

  final ProducerOrder order;
  final ProducerOrderCardLayout layout;
  final bool showDueDateInSummary;
  final Widget? trailing;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ModelThumbnail(
                  asset: order.product.imageAssetPreferringColors(
                    order.colorBreakdown.keys,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.product.code,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        order.product.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '#${order.code} · ${order.buyerCompany}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (trailing != null) trailing!
                else StatusBadge.order(order.status),
              ],
            ),
            if (layout == ProducerOrderCardLayout.summary &&
                showDueDateInSummary) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(
                    Icons.event_outlined,
                    size: 14,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Teslim: ${order.dueDate}',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
            if (layout == ProducerOrderCardLayout.full) ...[
              const SizedBox(height: 12),
              _InfoChips(
                chips: [
                  _InfoChipData(
                    icon: Icons.palette_outlined,
                    text: order.summaryLine,
                  ),
                  _InfoChipData(
                    icon: Icons.event_outlined,
                    text: 'Teslim: ${order.dueDate}',
                  ),
                  if (order.productionStage != null)
                    _InfoChipData(
                      icon: Icons.precision_manufacturing_outlined,
                      text: 'Aşama: ${order.productionStage}',
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                order.colorListLine,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
            if (actions.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8, children: actions),
            ],
          ],
        ),
      ),
    );
  }
}

class _ModelThumbnail extends StatelessWidget {
  const _ModelThumbnail({required this.asset});

  final String asset;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 64,
        height: 64,
        color: AppColors.surfaceMuted,
        child: catalogDisplayImage(asset, fit: BoxFit.cover),
      ),
    );
  }
}

class _InfoChipData {
  const _InfoChipData({required this.icon, required this.text});

  final IconData icon;
  final String text;
}

class _InfoChips extends StatelessWidget {
  const _InfoChips({required this.chips});

  final List<_InfoChipData> chips;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final chip in chips)
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(chip.icon, size: 14, color: AppColors.textMuted),
                  const SizedBox(width: 6),
                  Text(
                    chip.text,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

