import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_button_styles.dart';
import '../../../core/sync/push_navigation.dart';
import '../../../core/widgets/responsive_page.dart';
import '../../../shared/order_date_labels.dart';
import '../../../shared/widgets/catalog_display_image.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../catalog/domain/product_model.dart';
import '../../orders/application/buyer_order_notes_notifier.dart';
import '../application/producer_orders_notifier.dart';
import '../domain/producer_order.dart';
import '../../requests/presentation/open_request_thread.dart';
import '../export/producer_order_excel_preview_sheet.dart';

/// Üretici — gelen sipariş tam ekran detayı (onay / üretime al burada).
class ProducerOrderDetailPage extends ConsumerWidget {
  const ProducerOrderDetailPage({required this.orderCode, super.key});

  final String orderCode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listState = ref.watch(producerOrdersProvider);
    ProducerOrder? order;
    for (final o in listState.items) {
      if (o.code == orderCode) {
        order = o;
        break;
      }
    }

    if (order == null) {
      return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Geri',
            onPressed: () => safePopDetail(context),
          ),
          title: Text(
            '#$orderCode',
            overflow: TextOverflow.ellipsis,
          ),
        ),
        body: Center(
          child: listState.isLoading
              ? const CircularProgressIndicator()
              : const Text('Sipariş bulunamadı.'),
        ),
      );
    }

    return _ProducerOrderDetailContent(order: order);
  }
}

class _ProducerOrderDetailContent extends ConsumerWidget {
  const _ProducerOrderDetailContent({required this.order});

  final ProducerOrder order;

  String get _previewAsset => order.product.imageAssetPreferringColors(
        order.colorBreakdown.keys,
      );

  String get _previewColorLabel {
    for (final name in order.colorBreakdown.keys) {
      if (name.trim().isNotEmpty) return name.trim();
    }
    final variants = order.product.colorVariants;
    if (variants.isEmpty) return '';
    return variants.first.colorName;
  }

  void _openImagePreview(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      builder: (context) => _ProducerProductPreviewDialog(
        model: order.product,
        previewColorName: _previewColorLabel,
      ),
    );
  }

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Geri',
          onPressed: () => safePopDetail(context),
        ),
        title: Text(
          '#${order.code}',
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            tooltip: 'Excel indir',
            icon: const Icon(Icons.table_chart_outlined),
            onPressed: () async {
              await showProducerOrderExcelPreview(
                context,
                order,
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ResponsivePage(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              children: [
                  _HeroImageSection(
                    asset: _previewAsset,
                    colorLabel: _previewColorLabel,
                    onTap: () => _openImagePreview(context),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    order.product.name,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${order.product.code} · ${order.product.category}',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          order.buyerCompany,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      StatusBadge.order(order.status),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _MetaChip(
                        icon: Icons.palette_outlined,
                        text: order.summaryLine,
                      ),
                      _MetaChip(
                        icon: Icons.schedule_outlined,
                        text:
                            'Sipariş: ${formatOrderDateLong(order.orderedAt)}',
                      ),
                      _MetaChip(
                        icon: Icons.event_outlined,
                        text: 'Teslim: ${order.dueDate}',
                      ),
                      if (order.productionStage != null)
                        _MetaChip(
                          icon: Icons.precision_manufacturing_outlined,
                          text: 'Aşama: ${order.productionStage}',
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Builder(
                    builder: (context) {
                      final fromOrder = order.buyerNote?.trim() ?? '';
                      final t = fromOrder.isNotEmpty
                          ? fromOrder
                          : (ref.watch(buyerOrderNotesProvider)[order.code]
                                  ?.trim() ??
                              '');
                      final has = t.isNotEmpty;
                      return Card(
                        color: AppColors.surfaceMuted,
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.note_alt_outlined,
                                    size: 18,
                                    color: AppColors.navy.withValues(alpha: 0.75),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Sipariş notu',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(fontWeight: FontWeight.w900),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                has
                                    ? t
                                    : 'Henüz not yok. Sipariş oluştururken veya '
                                        'takip detayından ekleyebilirsiniz.',
                                style: TextStyle(
                                  height: 1.4,
                                  fontWeight:
                                      has ? FontWeight.w600 : FontWeight.w500,
                                  color: has
                                      ? AppColors.text
                                      : AppColors.textMuted,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  OutlinedButton.icon(
                    onPressed: () => openRequestThreadForOrder(
                      context,
                      ref,
                      orderNo: order.buyerOrderNo.isNotEmpty
                          ? order.buyerOrderNo
                          : order.code,
                    ),
                    icon: const Icon(Icons.history_edu_outlined),
                    label: const Text('Talepleri görüntüle'),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Renk ve adet',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 10),
                  ...order.colorBreakdown.entries.map(
                    (e) {
                      final ratios = order.colorSizeRatios[e.key];
                      final ratioText = ratios != null && ratios.isNotEmpty
                          ? ratios.entries
                              .map((r) => '${r.key}:${r.value}')
                              .join(' ')
                          : null;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: AppColors.surfaceMuted,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        e.key,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '${e.value} adet',
                                      style: const TextStyle(
                                        color: AppColors.textMuted,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                                if (ratioText != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    ratioText,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textMuted,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _PrimaryActionBar(
                order: order,
                onAction: (message) async {
                  _showSnack(context, message);
                  safePopDetail(context);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroImageSection extends StatelessWidget {
  const _HeroImageSection({
    required this.asset,
    required this.colorLabel,
    required this.onTap,
  });

  final String asset;
  final String colorLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceMuted,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: AspectRatio(
          aspectRatio: 1,
          child: Stack(
            fit: StackFit.expand,
            children: [
              catalogDisplayImage(asset, fit: BoxFit.cover),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.65),
                      ],
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 24, 12, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            colorLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.zoom_in_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppColors.textMuted),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrimaryActionBar extends ConsumerWidget {
  const _PrimaryActionBar({
    required this.order,
    required this.onAction,
  });

  final ProducerOrder order;
  final Future<void> Function(String message) onAction;

  Future<void> _run(
    BuildContext context,
    Future<void> Function() action,
    String successMessage,
  ) async {
    try {
      await action();
      await onAction(successMessage);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(producerOrdersProvider.notifier);
    switch (order.status) {
      case 'submitted':
        return FilledButton.icon(
          onPressed: () => _run(
            context,
            () => notifier.approve(order.code),
            '${order.code} onaylandı.',
          ),
          icon: const Icon(Icons.check_circle_outline, size: 20),
          label: const Text('Onayla'),
          style: AppButtonStyles.positive,
        );
      case 'approved':
        return FilledButton.icon(
          onPressed: () => _run(
            context,
            () => notifier.startProduction(order.code),
            '${order.code} üretime alındı.',
          ),
          icon: const Icon(Icons.play_arrow_rounded, size: 22),
          label: const Text('Üretime Al'),
          style: AppButtonStyles.progress,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

class _ProducerProductPreviewDialog extends StatelessWidget {
  const _ProducerProductPreviewDialog({
    required this.model,
    required this.previewColorName,
  });

  final ProductModel model;
  final String previewColorName;

  @override
  Widget build(BuildContext context) {
    final asset = model.imageAssetForColor(previewColorName);
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Stack(
        children: [
          Center(
            child: InteractiveViewer(
              minScale: 1,
              maxScale: 4,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: catalogDisplayImage(
                  asset,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          Positioned(
            top: 8,
            left: 8,
            right: 8,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        model.code,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        model.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        previewColorName,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Material(
                  color: Colors.black.withValues(alpha: 0.55),
                  shape: const CircleBorder(),
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                    tooltip: 'Kapat',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
