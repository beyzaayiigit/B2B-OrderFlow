import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/responsive_page.dart';
import '../../../shared/order_date_labels.dart';
import '../../../shared/search_prefix_match.dart';
import '../../../shared/widgets/list_pagination_controls.dart';
import '../../../shared/widgets/list_sort_count_row.dart';
import '../../../core/sync/remote_data_sync.dart';
import '../application/producer_orders_notifier.dart';
import '../domain/producer_order.dart';
import 'widgets/producer_order_card.dart';

/// Üretici — sevk edilmiş siparişler (Üretim'den «Sevke Hazır» sonrası).
class ProducerShippedPage extends ConsumerStatefulWidget {
  const ProducerShippedPage({super.key});

  @override
  ConsumerState<ProducerShippedPage> createState() => _ProducerShippedPageState();
}

class _ProducerShippedPageState extends ConsumerState<ProducerShippedPage> {
  String _query = '';
  /// `true`: sevk tarihi (sipariş tarihi) yeniden eskiye.
  bool _newestFirst = true;
  int _page = 0;

  void _resetPage() => setState(() => _page = 0);

  List<ProducerOrder> _filtered(List<ProducerOrder> all) {
    var list = all.where((order) => order.status == 'shipped').where((order) {
      return matchesAnySearchPrefix(
        [order.code, order.product.code],
        _query,
      );
    }).toList();

    list.sort((a, b) {
      final c = _newestFirst
          ? b.orderedAt.compareTo(a.orderedAt)
          : a.orderedAt.compareTo(b.orderedAt);
      if (c != 0) return c;
      return b.code.compareTo(a.code);
    });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final listState = ref.watch(producerOrdersProvider);
    final shipped = _filtered(listState.items);
    final pageItems = paginateSlice(shipped, _page);
    clampPageIfNeeded(
      currentPage: _page,
      totalCount: shipped.length,
      pageSize: listPageSize,
      onPageChanged: (p) {
        if (mounted) setState(() => _page = p);
      },
    );
    final totalUnits = shipped.fold<int>(
      0,
      (sum, order) => sum + order.totalQuantity,
    );

    return ResponsivePage(
      onRefresh: () =>
          RemoteDataSync.refreshAfterRemoteEvent(ref.container),
      children: [
        Text(
          'Sevk Edilenler',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 6),
        const Text(
          'Sevke hazır işaretlenen siparişlerin geçmişi. Alıcı tarafında durum «Sevk Edildi» olarak görünür.',
          style: TextStyle(color: AppColors.textMuted),
        ),
        const SizedBox(height: 16),
        _ShippedSummaryCard(
          shippedOrderCount: shipped.length,
          totalUnits: totalUnits,
        ),
        const SizedBox(height: 16),
        TextField(
          decoration: InputDecoration(
            hintText: 'Sipariş veya model kodu ara…',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _query.isEmpty
                ? null
                : IconButton(
                    onPressed: () {
                      setState(() => _query = '');
                      _resetPage();
                    },
                    icon: const Icon(Icons.close),
                    tooltip: 'Aramayı temizle',
                  ),
          ),
          onChanged: (v) {
            setState(() => _query = v);
            _resetPage();
          },
        ),
        const SizedBox(height: 12),
        ListSortCountRow(
          count: shipped.length,
          arrowPointsUp: _newestFirst,
          onToggle: () {
            setState(() => _newestFirst = !_newestFirst);
            _resetPage();
          },
        ),
        const SizedBox(height: 16),
        if (shipped.isEmpty)
          const _EmptyShippedListCard()
        else ...[
          for (final order in pageItems) ...[
            ProducerOrderCard(
              order: order,
              layout: ProducerOrderCardLayout.summary,
              showDueDateInSummary: true,
              trailing: _ShippedDateChip(orderedAt: order.orderedAt),
              actions: [
                OutlinedButton.icon(
                  onPressed: () =>
                      context.push('/producer/incoming/${order.code}'),
                  icon: const Icon(Icons.visibility_outlined, size: 18),
                  label: const Text('Görüntüle'),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          ListPaginationControls(
            totalCount: shipped.length,
            currentPage: _page,
            onPageChanged: (p) => setState(() => _page = p),
          ),
        ],
      ],
    );
  }
}

class _ShippedSummaryCard extends StatelessWidget {
  const _ShippedSummaryCard({
    required this.shippedOrderCount,
    required this.totalUnits,
  });

  final int shippedOrderCount;
  final int totalUnits;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: _ShippedMetric(
                icon: Icons.local_shipping_outlined,
                label: 'Sevk edilen sipariş',
                value: '$shippedOrderCount',
              ),
            ),
            Container(
              width: 1,
              height: 36,
              color: AppColors.border,
              margin: const EdgeInsets.symmetric(horizontal: 12),
            ),
            Expanded(
              child: _ShippedMetric(
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

class _ShippedMetric extends StatelessWidget {
  const _ShippedMetric({
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
        Column(
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
      ],
    );
  }
}

class _ShippedDateChip extends StatelessWidget {
  const _ShippedDateChip({required this.orderedAt});

  final DateTime orderedAt;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        formatOrderDateLong(orderedAt),
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppColors.textMuted,
        ),
      ),
    );
  }
}

class _EmptyShippedListCard extends StatelessWidget {
  const _EmptyShippedListCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(Icons.local_shipping_outlined, color: AppColors.textMuted),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Henüz sevk edilmiş sipariş yok. Üretim sekmesinde «Sevke Hazır» ile işaretlenen siparişler burada listelenir.',
                style: TextStyle(color: AppColors.textMuted, height: 1.35),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
