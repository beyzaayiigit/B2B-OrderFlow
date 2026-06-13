import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_button_styles.dart';
import '../../../core/widgets/responsive_page.dart';
import '../../../shared/search_prefix_match.dart';
import '../../../shared/widgets/list_pagination_controls.dart';
import '../../../shared/widgets/list_sort_count_row.dart';
import '../../requests/application/request_threads_notifier.dart';
import '../../requests/domain/request_thread.dart';
import '../../../core/sync/remote_data_sync.dart';
import '../application/producer_orders_notifier.dart';
import '../domain/producer_order.dart';
import 'widgets/producer_order_card.dart';

class ProducerProductionPage extends ConsumerStatefulWidget {
  const ProducerProductionPage({super.key});

  @override
  ConsumerState<ProducerProductionPage> createState() =>
      _ProducerProductionPageState();
}

class _ProducerProductionPageState extends ConsumerState<ProducerProductionPage> {
  static const _allStage = 'all';
  static const _stages = ['Kesim', 'Dikim', 'Paketleme', 'Lojistik'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(requestThreadsProvider.notifier).refresh();
    });
  }

  String _query = '';
  String _selectedStage = _allStage;
  bool _dueSoonFirst = true;
  int _page = 0;

  void _resetPage() => setState(() => _page = 0);

  List<ProducerOrder> _filtered(List<ProducerOrder> all) {
    final baseInProduction =
        all.where((order) => order.status == 'in_production').toList();
    var list = baseInProduction.where((order) {
      final matchesCode = matchesAnySearchPrefix(
        [order.code, order.product.code],
        _query,
      );
      final stage = order.productionStage;
      final matchesStage = _selectedStage == _allStage ||
          (stage != null && stage == _selectedStage);
      return matchesCode && matchesStage;
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
    final inProduction = _filtered(listState.items);
    final pageItems = paginateSlice(inProduction, _page);
    clampPageIfNeeded(
      currentPage: _page,
      totalCount: inProduction.length,
      pageSize: listPageSize,
      onPageChanged: (p) {
        if (mounted) setState(() => _page = p);
      },
    );
    final totalUnits = inProduction.fold<int>(
      0,
      (sum, order) => sum + order.totalQuantity,
    );

    return ResponsivePage(
      onRefresh: () =>
          RemoteDataSync.refreshAfterRemoteEvent(ref.container),
      children: [
        Text(
          'Üretim Yönetimi',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 6),
        const Text(
          'Aktif üretimdeki siparişlerin aşamalarını takip edin ve güncelleyin.',
          style: TextStyle(color: AppColors.textMuted),
        ),
        const SizedBox(height: 16),
        _ProductionSummaryCard(
          activeOrderCount: inProduction.length,
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
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _StageChip(
                label: 'Tüm aşamalar',
                selected: _selectedStage == _allStage,
                onTap: () {
                  setState(() => _selectedStage = _allStage);
                  _resetPage();
                },
              ),
              for (final stage in _stages)
                _StageChip(
                  label: stage,
                  selected: _selectedStage == stage,
                  onTap: () {
                    setState(() => _selectedStage = stage);
                    _resetPage();
                  },
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ListSortCountRow(
          count: inProduction.length,
          arrowPointsUp: _dueSoonFirst,
          onToggle: () {
            setState(() => _dueSoonFirst = !_dueSoonFirst);
            _resetPage();
          },
        ),
        const SizedBox(height: 16),
        if (inProduction.isEmpty)
          const _EmptyProductionListCard()
        else ...[
          for (final order in pageItems) ...[
            ProducerOrderCard(
              order: order,
              actions: [
                OutlinedButton.icon(
                  onPressed: () =>
                      context.push('/producer/incoming/${order.code}'),
                  icon: const Icon(Icons.visibility_outlined, size: 18),
                  label: const Text('Detay'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _changeStage(context, order),
                  icon: const Icon(Icons.swap_horiz, size: 18),
                  label: const Text('Aşama Değiştir'),
                ),
                FilledButton.icon(
                  onPressed: () => _confirmAndMarkShipped(context, order),
                  icon: const Icon(Icons.local_shipping_outlined, size: 18),
                  label: const Text('Sevke Hazır'),
                  style: AppButtonStyles.brand,
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          ListPaginationControls(
            totalCount: inProduction.length,
            currentPage: _page,
            onPageChanged: (p) => setState(() => _page = p),
          ),
        ],
      ],
    );
  }

  RequestThread? _updateThreadFor(ProducerOrder order) {
    if (order.buyerOrderNo.isEmpty) return null;
    return ref
        .read(requestThreadsProvider.notifier)
        .threadByOrderNo(order.buyerOrderNo);
  }

  Future<void> _confirmAndMarkShipped(
    BuildContext context,
    ProducerOrder order,
  ) async {
    await ref.read(requestThreadsProvider.notifier).refresh();
    if (!context.mounted) return;
    final thread = _updateThreadFor(order);
    if (thread != null && thread.hasOpenUpdateWorkflow) {
      _showSnack(
        context,
        'Bu siparişte kapanmamış güncelleme talebi var. '
        'Önce talebi onaylayın veya alıcı ile süreci tamamlayın.',
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sevk onayı'),
        content: Text(
          '${order.code} siparişini sevk edildi olarak işaretlemek istiyor musunuz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: AppButtonStyles.brand,
            child: const Text('Sevk et'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await ref.read(producerOrdersProvider.notifier).markShipped(order.code);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${order.code} sevk edildi olarak işaretlendi.'),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Sevk listesi',
            onPressed: () => context.go('/producer/shipped'),
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      _showSnack(context, e.toString());
    }
  }

  Future<void> _changeStage(BuildContext context, ProducerOrder order) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Text(
                '${order.code} aşaması',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              Text(
                order.product.name,
                style: const TextStyle(color: AppColors.textMuted),
              ),
              const SizedBox(height: 8),
              for (final stage in _stages)
                ListTile(
                  leading: const Icon(Icons.precision_manufacturing_outlined),
                  title: Text(stage),
                  trailing: stage == order.productionStage
                      ? const Icon(Icons.check, color: AppColors.success)
                      : null,
                  onTap: () => Navigator.of(context).pop(stage),
                ),
            ],
          ),
        );
      },
    );
    if (selected == null || !context.mounted) return;
    try {
      await ref
          .read(producerOrdersProvider.notifier)
          .updateProductionStage(order.code, selected);
      if (!context.mounted) return;
      _showSnack(context, '${order.code} aşaması: $selected');
    } catch (e) {
      if (!context.mounted) return;
      _showSnack(context, e.toString());
    }
  }

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }
}

class _StageChip extends StatelessWidget {
  const _StageChip({
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

class _ProductionSummaryCard extends StatelessWidget {
  const _ProductionSummaryCard({
    required this.activeOrderCount,
    required this.totalUnits,
  });

  final int activeOrderCount;
  final int totalUnits;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: _Metric(
                icon: Icons.factory_outlined,
                label: 'Aktif sipariş',
                value: '$activeOrderCount',
              ),
            ),
            Container(
              width: 1,
              height: 36,
              color: AppColors.border,
              margin: const EdgeInsets.symmetric(horizontal: 12),
            ),
            Expanded(
              child: _Metric(
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

class _Metric extends StatelessWidget {
  const _Metric({
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

class _EmptyProductionListCard extends StatelessWidget {
  const _EmptyProductionListCard();

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
                'Bu kriterlere uyan üretim siparişi yok. Aramayı veya aşama filtresini değiştirin.',
                style: TextStyle(color: AppColors.textMuted, height: 1.35),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
