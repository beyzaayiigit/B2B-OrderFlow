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

class TrackingPage extends ConsumerStatefulWidget {
  const TrackingPage({super.key});

  @override
  ConsumerState<TrackingPage> createState() => _TrackingPageState();
}

class _TrackingPageState extends ConsumerState<TrackingPage> {
  static const _allKey = 'all';
  static const _statusFilters = <_StatusFilter>[
    _StatusFilter(key: _allKey, label: 'Tümü'),
    _StatusFilter(key: 'submitted', label: 'Bekleniyor'),
    _StatusFilter(key: 'approved', label: 'Onaylandı'),
    _StatusFilter(key: 'in_production', label: 'Üretimde'),
  ];

  String _query = '';
  String _selectedStatus = _allKey;
  /// `true`: sipariş tarihine göre yeniden eskiye.
  bool _newestFirst = true;
  final _pageByStatus = <String, int>{};

  int _pageFor(String statusKey) => _pageByStatus[statusKey] ?? 0;

  void _setPageFor(String statusKey, int page) {
    setState(() => _pageByStatus[statusKey] = page);
  }

  List<TrackedOrder> _filtered(List<TrackedOrder> all) {
    final out = all.where((order) {
      if (order.status == 'shipped') return false;
      final matchesCode = matchesSearchPrefix(order.orderNo, _query);
      final matchesStatus =
          _selectedStatus == _allKey || order.status == _selectedStatus;
      return matchesCode && matchesStatus;
    }).toList()
      ..sort((a, b) => _newestFirst
          ? b.createdAt.compareTo(a.createdAt)
          : a.createdAt.compareTo(b.createdAt));
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final listState = ref.watch(trackedOrdersProvider);
    final results = _filtered(listState.items);
    final page = _pageFor(_selectedStatus);
    final pageItems = paginateSlice(results, page);
    clampPageIfNeeded(
      currentPage: page,
      totalCount: results.length,
      pageSize: listPageSize,
      onPageChanged: (p) => _setPageFor(_selectedStatus, p),
    );

    final totalUnits = results.fold<int>(
      0,
      (sum, order) => sum + order.totalQuantity,
    );

    return ResponsivePage(
      onRefresh: () =>
          RemoteDataSync.refreshAfterRemoteEvent(ref.container),
      children: [
        Text(
          'Sipariş Takip Listesi',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 6),
        const Text(
          'Aktif siparişlerinizi buradan takip edin. Sevk edilenler «Sevk» sekmesindedir.',
          style: TextStyle(color: AppColors.textMuted),
        ),
        if (listState.isLoading && listState.items.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          ),
        if (listState.error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              listState.error!,
              style: const TextStyle(color: AppColors.critical),
            ),
          ),
        const SizedBox(height: 16),
        BuyerOrderSummaryCard(
          orderCountLabel: trackingSummaryOrderLabel(_selectedStatus),
          orderCount: results.length,
          totalUnits: totalUnits,
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
                      _pageByStatus.clear();
                    },
                    icon: const Icon(Icons.close),
                    tooltip: 'Aramayı temizle',
                  ),
          ),
          onChanged: (value) {
            setState(() => _query = value);
            _pageByStatus.clear();
          },
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final filter in _statusFilters)
                _StatusFilterChip(
                  label: filter.label,
                  selected: filter.key == _selectedStatus,
                  onTap: () => setState(() => _selectedStatus = filter.key),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ListSortCountRow(
          count: results.length,
          arrowPointsUp: _newestFirst,
          sortHint: 'Sipariş tarihine göre',
          onToggle: () {
            setState(() => _newestFirst = !_newestFirst);
            _pageByStatus.clear();
          },
        ),
        const SizedBox(height: 16),
        if (results.isEmpty)
          const _EmptyResultsCard()
        else ...[
          for (final order in pageItems) ...[
            TrackingOrderCard(order: order),
            const SizedBox(height: 12),
          ],
          ListPaginationControls(
            totalCount: results.length,
            currentPage: page,
            onPageChanged: (p) => _setPageFor(_selectedStatus, p),
          ),
        ],
      ],
    );
  }
}

class _StatusFilter {
  const _StatusFilter({required this.key, required this.label});

  final String key;
  final String label;
}

class _StatusFilterChip extends StatelessWidget {
  const _StatusFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(label),
        onPressed: onTap,
        backgroundColor: selected ? AppColors.navyDark : AppColors.surfaceMuted,
        labelStyle: TextStyle(
          color: selected ? Colors.white : AppColors.text,
          fontWeight: FontWeight.w700,
        ),
        side: BorderSide.none,
      ),
    );
  }
}

class _EmptyResultsCard extends StatelessWidget {
  const _EmptyResultsCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: const [
            Icon(Icons.search_off, color: AppColors.textMuted),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Bu kriterlere uyan sipariş yok. Aramayı veya durum filtresini değiştirin.',
                style: TextStyle(color: AppColors.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
