import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/sync/remote_data_sync.dart';
import '../../../core/widgets/responsive_page.dart';
import '../../../shared/search_prefix_match.dart';
import '../../../shared/widgets/buyer_order_summary_card.dart';
import '../../../shared/widgets/list_pagination_controls.dart';
import '../../../shared/widgets/list_sort_count_row.dart';
import '../application/tracked_orders_notifier.dart';
import '../domain/tracked_order.dart';
import 'tracking_order_list_card.dart';

/// Alıcı — sevk edilmiş siparişler (üretici «Sevke Hazır» sonrası).
class BuyerShippedPage extends ConsumerStatefulWidget {
  const BuyerShippedPage({super.key});

  @override
  ConsumerState<BuyerShippedPage> createState() => _BuyerShippedPageState();
}

class _BuyerShippedPageState extends ConsumerState<BuyerShippedPage> {
  String _query = '';
  bool _newestFirst = true;
  int _page = 0;

  List<TrackedOrder> _filtered(List<TrackedOrder> all) {
    var list = all.where((order) {
      if (order.status != 'shipped') return false;
      return matchesSearchPrefix(order.orderNo, _query);
    }).toList();

    list.sort((a, b) {
      final c = _newestFirst
          ? b.createdAt.compareTo(a.createdAt)
          : a.createdAt.compareTo(b.createdAt);
      if (c != 0) return c;
      return b.orderNo.compareTo(a.orderNo);
    });
    return list;
  }

  void _resetPage() => setState(() => _page = 0);

  @override
  Widget build(BuildContext context) {
    final listState = ref.watch(trackedOrdersProvider);
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
          'Üretici tarafından sevk edilen siparişleriniz. Durum «Sevk Edildi» olarak görünür.',
          style: TextStyle(color: AppColors.textMuted),
        ),
        if (listState.isLoading && listState.items.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          ),
        if (listState.error != null)
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 12),
            child: Text(
              listState.error!,
              style: const TextStyle(color: AppColors.critical),
            ),
          ),
        const SizedBox(height: 16),
        BuyerOrderSummaryCard(
          orderCountLabel: 'Sevk edilen sipariş',
          orderCount: shipped.length,
          totalUnits: totalUnits,
          orderCountIcon: Icons.local_shipping_outlined,
        ),
        const SizedBox(height: 16),
        TextField(
          decoration: InputDecoration(
            hintText: 'Sipariş kodu ara…',
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
          sortHint: 'Sipariş tarihine göre',
          onToggle: () {
            setState(() => _newestFirst = !_newestFirst);
            _resetPage();
          },
        ),
        const SizedBox(height: 16),
        if (shipped.isEmpty)
          const _EmptyBuyerShippedCard()
        else ...[
          for (final order in pageItems) ...[
            TrackingOrderCard(order: order),
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

class _EmptyBuyerShippedCard extends StatelessWidget {
  const _EmptyBuyerShippedCard();

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
                'Henüz sevk edilmiş sipariş yok. Üretici sevk ettikçe siparişleriniz burada listelenir.',
                style: TextStyle(color: AppColors.textMuted, height: 1.35),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
