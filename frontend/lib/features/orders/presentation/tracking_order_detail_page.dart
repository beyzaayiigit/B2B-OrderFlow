import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/llm/assist_api.dart';
import '../../requests/application/request_threads_notifier.dart';
import '../application/tracked_orders_notifier.dart';
import '../../catalog/application/catalog_list_provider.dart';
import '../../catalog/domain/product_model.dart';
import '../../../core/widgets/responsive_page.dart';
import '../../../shared/widgets/catalog_product_zoom.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../producer/domain/producer_order.dart';
import '../../producer/export/producer_order_excel_preview_sheet.dart';
import '../domain/order_color_palette.dart';
import '../domain/tracked_order.dart';
import 'order_status_timeline_card.dart';

/// Takip listesindeki renk adları için `CreateOrderPage` ile uyumlu tonlar.
Color _toneForColorName(String name) => toneForOrderColorName(name);

const _sizeDisplayOrder = ['S', 'M', 'L', 'XL', 'XXL'];

class TrackingOrderDetailPage extends ConsumerWidget {
  const TrackingOrderDetailPage({required this.order, super.key});

  final TrackedOrder order;

  ProductModel? _product(WidgetRef ref) {
    final catalog = ref.watch(catalogItemsProvider);
    for (final p in catalog) {
      if (p.code == order.productCode) return p;
    }
    return null;
  }

  Future<String?> _askRequestMessage(
    BuildContext context,
    WidgetRef ref,
    String orderNo,
  ) async {
    final controller = TextEditingController();
    final assistAvailable = ref.read(assistApiProvider).available;
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        var loading = false;
        return StatefulBuilder(
          builder: (context, setLocal) {
            Future<void> runAssist() async {
              final raw = controller.text.trim();
              if (raw.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Önce kısa da olsa talebinizi yazın.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }
              setLocal(() => loading = true);
              try {
                final r = await ref
                    .read(assistApiProvider)
                    .updateRequest(raw, orderCode: orderNo);
                controller.text = r;
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString()),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } finally {
                setLocal(() => loading = false);
              }
            }

            return AlertDialog(
              title: const Text('Güncelleme talebi'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: controller,
                    autofocus: true,
                    minLines: 3,
                    maxLines: 6,
                    decoration: const InputDecoration(
                      hintText: 'Talep mesajınızı yazın...',
                    ),
                  ),
                  if (assistAvailable)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: loading ? null : runAssist,
                        icon: loading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.auto_awesome, size: 18),
                        label: Text(loading ? 'Düzenleniyor…' : 'AI ile düzenle'),
                        style:
                            TextButton.styleFrom(foregroundColor: AppColors.navy),
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Vazgeç'),
                ),
                FilledButton(
                  onPressed: () =>
                      Navigator.of(context).pop(controller.text.trim()),
                  child: const Text('Gönder'),
                ),
              ],
            );
          },
        );
      },
    );
    final text = result?.trim();
    if (text == null || text.isEmpty) return null;
    return text;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final model = _product(ref);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '#${order.orderNo}',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: ResponsivePage(
          children: [
            if (model != null)
              _ProductSummaryCard(
                model: model,
                previewColorName: order.lines.isEmpty
                    ? null
                    : order.lines.first.colorName,
              ),
            if (model == null) _UnknownProductCard(code: order.productCode),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Durum',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        StatusBadge.order(order.status),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _InfoRow(
                      label: 'Sipariş tarihi',
                      value: order.createdAtLabel,
                    ),
                    const SizedBox(height: 8),
                    _InfoRow(
                      label: 'Teslim',
                      value: order.dueAtLabel,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            OrderStatusTimelineCard(order: order),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Lojistik birimi',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      order.location,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _BuyerOrderNoteDisplay(order: order),
            const SizedBox(height: 20),
            Text(
              'Sipariş içeriği',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _MiniStat(
                    label: 'Renk',
                    value: '${order.colorCount}',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MiniStat(
                    label: 'Toplam adet',
                    value: '${order.totalQuantity}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (final line in order.lines) ...[
              _LineCard(line: line),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 8),
            Consumer(
              builder: (context, ref, _) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (order.status != 'shipped') ...[
                      OutlinedButton.icon(
                        onPressed: () async {
                          final productLabel = model != null
                              ? '${model.code} · ${model.name}'
                              : order.productCode;
                          try {
                            final notifier =
                                ref.read(requestThreadsProvider.notifier);
                            final existingId =
                                notifier.threadIdForOrder(order.orderNo);
                            if (existingId != null) {
                              if (!context.mounted) return;
                              context.push('/requests/thread/$existingId');
                              return;
                            }

                            final body = await _askRequestMessage(
                              context,
                              ref,
                              order.orderNo,
                            );
                            if (body == null) return;

                            final id = await notifier.ensureThreadForOrder(
                              orderNo: order.orderNo,
                              productLabel: productLabel,
                              orderStatusKey: order.status,
                            );
                            await notifier.addBuyerRequest(id, body);
                            if (!context.mounted) return;
                            context.push('/requests/thread/$id');
                          } catch (e) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(e.toString()),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.edit_note_outlined),
                        label: const Text('Güncelleme talebi'),
                      ),
                      const SizedBox(height: 10),
                    ],
                    FilledButton.icon(
                      onPressed: model == null
                          ? null
                          : () async {
                              final po = ProducerOrder.fromTrackedOrder(
                                order,
                                product: model,
                              );
                              if (!context.mounted) return;
                              await showProducerOrderExcelPreview(
                                context,
                                po,
                              );
                            },
                      icon: const Icon(Icons.table_chart_outlined),
                      label: Text(
                        order.status == 'shipped'
                            ? 'Excel indir'
                            : 'Excel İndir',
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// GoRouter kökünde [ProviderScope.containerOf] yerine [ref.watch] ile takip listesinden çözüm.
/// Liste satırından [GoRouterState.extra] ile [TrackedOrder] geçirilirse önce o kullanılır.
class TrackingOrderDetailLoader extends ConsumerWidget {
  const TrackingOrderDetailLoader({required this.orderNoOrCode, super.key});

  final String orderNoOrCode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(trackedOrdersProvider).items;
    TrackedOrder? found;
    for (final o in orders) {
      if (o.orderNo == orderNoOrCode) {
        found = o;
        break;
      }
      final lp = o.producerOrderCode;
      if (lp != null && lp == orderNoOrCode) {
        found = o;
        break;
      }
    }
    if (found == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Sipariş')),
        body: const Center(child: Text('Sipariş bulunamadı.')),
      );
    }
    return TrackingOrderDetailPage(order: found);
  }
}

class _ProductSummaryCard extends StatelessWidget {
  const _ProductSummaryCard({
    required this.model,
    this.previewColorName,
  });

  final ProductModel model;
  final String? previewColorName;

  @override
  Widget build(BuildContext context) {
    final asset = previewColorName != null
        ? model.imageAssetForColor(previewColorName!)
        : model.imageAsset;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CatalogProductThumbnail(
              asset: asset,
              size: 64,
              borderRadius: 12,
              previewColorName: previewColorName,
              title: model.name,
              subtitle: model.code,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    model.code,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    model.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    model.category,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UnknownProductCard extends StatelessWidget {
  const _UnknownProductCard({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.inventory_2_outlined, color: AppColors.navy.withValues(alpha: 0.6)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Ürün: $code (katalogda eşleşmedi)',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BuyerOrderNoteDisplay extends ConsumerWidget {
  const _BuyerOrderNoteDisplay({required this.order});

  final TrackedOrder order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = (order.buyerNote ?? '').trim();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sipariş notu',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              'Not, siparişi oluştururken bir kez kaydedilir; üretici ve Excel özeti '
              'ile aynı metni gösterir.',
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 12),
            DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: SizedBox(
                  width: double.infinity,
                  child: text.isEmpty
                      ? const Text(
                          'Bu sipariş için not girilmedi.',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontStyle: FontStyle.italic,
                          ),
                        )
                      : SelectableText(
                          text,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LineCard extends StatelessWidget {
  const _LineCard({required this.line});

  final TrackedOrderLine line;

  @override
  Widget build(BuildContext context) {
    final tone = _toneForColorName(line.colorName);
    final sizes = _sizesInDisplayOrder(line.sizeRatios);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _ColorSwatch(color: tone),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  line.colorName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
              ),
              Text(
                '${line.lineTotal} adet',
                style: const TextStyle(
                  color: AppColors.navy,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final size in sizes)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    '$size: ${line.sizeRatios[size] ?? 0}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          if (line.ratioSum > 0 && line.totalQty > 0) ...[
            const SizedBox(height: 8),
            Text(
              '${line.seriesCount} seri x ${line.ratioSum} adet/seri',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.navy,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

List<String> _sizesInDisplayOrder(Map<String, int> ratios) {
  final out = <String>[];
  for (final s in _sizeDisplayOrder) {
    if ((ratios[s] ?? 0) > 0) out.add(s);
  }
  for (final k in ratios.keys) {
    if (!out.contains(k) && (ratios[k] ?? 0) > 0) out.add(k);
  }
  return out;
}

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.border),
      ),
    );
  }
}
