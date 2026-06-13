import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../shared/widgets/status_badge.dart';
import '../application/order_status_timeline_provider.dart';
import '../data/order_status_mapper.dart';
import '../domain/order_status_event.dart';
import '../domain/tracked_order.dart';

String formatTimelineTimestamp(DateTime dt) {
  final d = dt.toLocal();
  final day = d.day.toString().padLeft(2, '0');
  final month = d.month.toString().padLeft(2, '0');
  final hour = d.hour.toString().padLeft(2, '0');
  final minute = d.minute.toString().padLeft(2, '0');
  return '$day.$month.${d.year}  $hour:$minute';
}

/// Alıcı takip detayında dikey durum zaman çizelgesi.
class OrderStatusTimelineCard extends ConsumerWidget {
  const OrderStatusTimelineCard({required this.order, super.key});

  final TrackedOrder order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(orderStatusTimelineProvider(order));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Durum geçmişi',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 14),
            async.when(
              data: (events) {
                if (events.isEmpty) {
                  return const Text(
                    'Henüz kayıtlı durum adımı yok.',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                  );
                }
                return Column(
                  children: [
                    for (var i = 0; i < events.length; i++) ...[
                      _TimelineRow(
                        event: events[i],
                        isFirst: i == 0,
                        isLast: i == events.length - 1,
                      ),
                    ],
                  ],
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
              error: (e, _) => Text(
                'Geçmiş yüklenemedi: $e',
                style: const TextStyle(
                  color: AppColors.critical,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.event,
    required this.isFirst,
    required this.isLast,
  });

  final OrderStatusEvent event;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final statusColor = orderStatusColor(event.status);
    final dotColor = event.isLatest ? statusColor : AppColors.textMuted;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                if (!isFirst)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: AppColors.border,
                    ),
                  ),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: event.isLatest
                        ? [
                            BoxShadow(
                              color: dotColor.withValues(alpha: 0.35),
                              blurRadius: 6,
                            ),
                          ]
                        : null,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: AppColors.border,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                top: isFirst ? 0 : 8,
                bottom: isLast ? 0 : 12,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          OrderStatusMapper.timelineTitle(event.status),
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: event.isLatest
                                ? AppColors.text
                                : AppColors.textMuted,
                          ),
                        ),
                      ),
                      StatusBadge.order(event.status),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatTimelineTimestamp(event.at),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                  if (event.note != null && event.note!.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      event.note!.trim(),
                      style: const TextStyle(fontSize: 12, height: 1.35),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
