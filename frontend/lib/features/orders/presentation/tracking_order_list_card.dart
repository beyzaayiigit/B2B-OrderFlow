import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/llm/assist_api.dart';
import '../../catalog/application/catalog_list_provider.dart';
import '../../catalog/domain/product_model.dart';
import '../../producer/domain/producer_order.dart';
import '../../producer/export/producer_order_excel_preview_sheet.dart';
import '../../requests/application/request_threads_notifier.dart';
import '../../../shared/widgets/catalog_product_zoom.dart';
import '../../../shared/widgets/status_badge.dart';
import '../domain/tracked_order.dart';

/// Alıcı takip ve sevk edilenler listelerinde sipariş kartı.
class TrackingOrderCard extends ConsumerWidget {
  const TrackingOrderCard({required this.order, super.key});

  final TrackedOrder order;

  String _productLabel(WidgetRef ref, TrackedOrder o) {
    final catalog = ref.watch(catalogItemsProvider);
    for (final p in catalog) {
      if (p.code == o.productCode) {
        return '${p.code} · ${p.name}';
      }
    }
    return o.productCode;
  }

  ProductModel? _product(WidgetRef ref, TrackedOrder o) {
    final catalog = ref.watch(catalogItemsProvider);
    for (final p in catalog) {
      if (p.code == o.productCode) return p;
    }
    return null;
  }

  String? _previewColorName(TrackedOrder o) {
    if (o.lines.isEmpty) return null;
    return o.lines.first.colorName;
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
                        label: Text(
                          loading ? 'Düzenleniyor…' : 'AI ile düzenle',
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.navy,
                        ),
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
    final product = _product(ref, order);
    final previewColor = _previewColorName(order);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (product != null)
                  CatalogProductThumbnail(
                    asset: product.imageAssetPreferringColors(
                      previewColor != null ? [previewColor] : const [],
                    ),
                    previewColorName: previewColor,
                    title: product.name,
                    subtitle: product.code,
                  )
                else
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Icon(
                      Icons.inventory_2_outlined,
                      color: AppColors.navy.withValues(alpha: 0.5),
                    ),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '#${order.orderNo}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                      if (product != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          product.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          product.code,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                StatusBadge.order(order.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Sipariş tarihi: ${order.createdAtLabel}',
              style: const TextStyle(color: AppColors.textMuted),
            ),
            const SizedBox(height: 14),
            const Text(
              'Lojistik birimi',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
            Text(
              order.location,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.push(
                      '/tracking/order/${order.orderNo}',
                      extra: order,
                    ),
                    icon: const Icon(Icons.article_outlined, size: 18),
                    label: const Text('Detay'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () async {
                      final catalog = ref.read(catalogItemsProvider);
                      ProductModel? product;
                      for (final p in catalog) {
                        if (p.code == order.productCode) {
                          product = p;
                          break;
                        }
                      }
                      if (product == null) return;
                      final po = ProducerOrder.fromTrackedOrder(
                        order,
                        product: product,
                      );
                      if (!context.mounted) return;
                      await showProducerOrderExcelPreview(
                        context,
                        po,
                      );
                    },
                    icon: const Icon(Icons.table_chart_outlined, size: 18),
                    label: const Text('Excel İndir'),
                  ),
                ),
              ],
            ),
            if (order.status != 'shipped') ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
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

                      final threadId = await notifier.ensureThreadForOrder(
                        orderNo: order.orderNo,
                        productLabel: _productLabel(ref, order),
                        orderStatusKey: order.status,
                      );
                      await notifier.addBuyerRequest(threadId, body);
                      if (!context.mounted) return;
                      context.push('/requests/thread/$threadId');
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
                  icon: const Icon(Icons.edit_note_outlined, size: 18),
                  label: const Text('Güncelleme talebi'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
