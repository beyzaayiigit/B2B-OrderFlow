import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/responsive_page.dart';
import '../../../shared/search_prefix_match.dart';
import '../../../shared/widgets/list_sort_count_row.dart';
import '../../../core/sync/remote_data_sync.dart';
import '../application/producer_orders_notifier.dart';
import '../domain/producer_order.dart';
import 'widgets/producer_order_card.dart';

class ProducerOrdersPage extends ConsumerStatefulWidget {
  const ProducerOrdersPage({super.key});

  @override
  ConsumerState<ProducerOrdersPage> createState() => _ProducerOrdersPageState();
}

class _ProducerOrdersPageState extends ConsumerState<ProducerOrdersPage> {
  static const _allStatus = 'all';

  String _query = '';
  String _selectedStatus = _allStatus;
  /// `true`: yakın teslim önce (dueAt artan).
  bool _dueSoonFirst = true;

  List<ProducerOrder> _filtered(List<ProducerOrder> all) {
    final baseIncoming = all
        .where(
          (order) =>
              order.status == 'submitted' || order.status == 'approved',
        )
        .toList();
    var list = baseIncoming.where((order) {
      final matchesCode = matchesAnySearchPrefix(
        [order.code, order.product.code],
        _query,
      );
      final matchesStatus = _selectedStatus == _allStatus ||
          order.status == _selectedStatus;
      return matchesCode && matchesStatus;
    }).toList();

    list.sort((a, b) {
      final c = _dueSoonFirst
          ? a.dueAt.compareTo(b.dueAt)
          : b.dueAt.compareTo(a.dueAt);
      if (c != 0) return c;
      return a.code.compareTo(b.code);
    });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final listState = ref.watch(producerOrdersProvider);
    final results = _filtered(listState.items);

    return ResponsivePage(
      onRefresh: () =>
          RemoteDataSync.refreshAfterRemoteEvent(ref.container),
      children: [
        Text(
          'Gelen Siparişler',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 6),
        const Text(
          'Alıcıdan gelen siparişleri inceleyin ve üretime alın.',
          style: TextStyle(color: AppColors.textMuted),
        ),
        const SizedBox(height: 16),
        TextField(
          decoration: InputDecoration(
            hintText: 'Sipariş veya model kodu ara…',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _query.isEmpty
                ? null
                : IconButton(
                    onPressed: () => setState(() => _query = ''),
                    icon: const Icon(Icons.close),
                    tooltip: 'Aramayı temizle',
                  ),
          ),
          onChanged: (v) => setState(() => _query = v),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _FilterChip(
                label: 'Tümü',
                selected: _selectedStatus == _allStatus,
                onTap: () => setState(() => _selectedStatus = _allStatus),
              ),
              _FilterChip(
                label: 'Bekliyor',
                selected: _selectedStatus == 'submitted',
                onTap: () => setState(() => _selectedStatus = 'submitted'),
              ),
              _FilterChip(
                label: 'Onaylandı',
                selected: _selectedStatus == 'approved',
                onTap: () => setState(() => _selectedStatus = 'approved'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ListSortCountRow(
          count: results.length,
          arrowPointsUp: _dueSoonFirst,
          onToggle: () => setState(() => _dueSoonFirst = !_dueSoonFirst),
        ),
        const SizedBox(height: 16),
        if (results.isEmpty)
          const _EmptyProducerListCard()
        else
          for (final order in results) ...[
            ProducerOrderCard(
              order: order,
              layout: ProducerOrderCardLayout.summary,
              showDueDateInSummary: true,
              actions: _actionsFor(context, order),
            ),
            const SizedBox(height: 12),
          ],
      ],
    );
  }

  List<Widget> _actionsFor(BuildContext context, ProducerOrder order) {
    return [
      OutlinedButton.icon(
        onPressed: () => context.push('/producer/incoming/${order.code}'),
        icon: const Icon(Icons.visibility_outlined, size: 18),
        label: const Text('Görüntüle'),
      ),
    ];
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
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

class _EmptyProducerListCard extends StatelessWidget {
  const _EmptyProducerListCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(Icons.search_off, color: AppColors.textMuted),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Bu kriterlere uyan sipariş yok. Aramayı veya filtreyi değiştirin.',
                style: TextStyle(color: AppColors.textMuted, height: 1.35),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
