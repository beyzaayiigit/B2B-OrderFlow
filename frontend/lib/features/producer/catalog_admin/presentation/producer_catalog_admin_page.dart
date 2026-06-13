import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_button_styles.dart';
import '../../../../core/widgets/responsive_page.dart';
import '../../../../shared/search_prefix_match.dart';
import '../../../../shared/widgets/catalog_display_image.dart';
import '../../../../shared/widgets/list_pagination_controls.dart';
import '../../../catalog/application/catalog_list_provider.dart';
import '../../../catalog/domain/product_model.dart';
import '../application/catalog_storage_usage_provider.dart';
import 'catalog_storage_usage_bar.dart';

/// Üretici: ürün kataloğu (Supabase veya mock).
class ProducerCatalogAdminPage extends ConsumerStatefulWidget {
  const ProducerCatalogAdminPage({super.key});

  @override
  ConsumerState<ProducerCatalogAdminPage> createState() =>
      _ProducerCatalogAdminPageState();
}

class _ProducerCatalogAdminPageState extends ConsumerState<ProducerCatalogAdminPage> {
  static const _all = 'all';

  String _query = '';
  String _status = _all;
  final _pageByStatus = <String, int>{};

  int _pageFor(String statusKey) => _pageByStatus[statusKey] ?? 0;

  void _setPageFor(String statusKey, int page) {
    setState(() => _pageByStatus[statusKey] = page);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(catalogStorageUsageProvider.notifier).refresh();
    });
  }

  List<ProductModel> _filtered(List<ProductModel> all) {
    return all.where((p) {
      if (_status != _all && p.status != _status) return false;
      return matchesSearchPrefix(p.code, _query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final listState = ref.watch(catalogListProvider);
    final catalog = ref.watch(catalogItemsProvider);
    final rows = _filtered(catalog);
    final page = _pageFor(_status);
    final pageItems = paginateSlice(
      rows,
      page,
      pageSize: catalogPageSize,
    );
    clampPageIfNeeded(
      currentPage: page,
      totalCount: rows.length,
      pageSize: catalogPageSize,
      onPageChanged: (p) => _setPageFor(_status, p),
    );

    return ResponsivePage(
      children: [
        if (listState.isLoading && catalog.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
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
        Text(
          'Katalog',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Modelleri, renk varyantlarını ve görselleri yönetin. Alıcı yalnızca '
          '«Yayında» ürünleri kataloğunda görür; «Taslak» yalnızca sizde kalır.',
          style: TextStyle(color: AppColors.textMuted, height: 1.35),
        ),
        const SizedBox(height: 16),
        const CatalogStorageUsageBar(),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () => context.push('/producer/catalog-admin/new'),
          icon: const Icon(Icons.add_rounded, size: 22),
          label: const Text('Yeni ürün'),
        ),
        const SizedBox(height: 16),
        TextField(
          decoration: InputDecoration(
            hintText: 'Model kodu ara…',
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
          onChanged: (v) {
            setState(() => _query = v);
            _pageByStatus.clear();
          },
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _Chip(
                label: 'Tümü',
                selected: _status == _all,
                onTap: () => setState(() => _status = _all),
              ),
              _Chip(
                label: 'Taslak',
                selected: _status == 'Taslak',
                onTap: () => setState(() => _status = 'Taslak'),
              ),
              _Chip(
                label: 'Yayında',
                selected: _status == 'Yayında',
                onTap: () => setState(() => _status = 'Yayında'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (rows.isEmpty)
          const _EmptyAdminCard()
        else ...[
          for (final p in pageItems) ...[
            _AdminProductCard(
              product: p,
              onEdit: () => context.push(
                '/producer/catalog-admin/edit',
                extra: p,
              ),
              onDelete: () => _confirmDelete(context, p),
            ),
            const SizedBox(height: 12),
          ],
          ListPaginationControls(
            totalCount: rows.length,
            currentPage: page,
            pageSize: catalogPageSize,
            onPageChanged: (p) => _setPageFor(_status, p),
          ),
        ],
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context, ProductModel p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ürünü kaldır'),
        content: Text('«${p.code}» katalogdan silinsin mi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: AppButtonStyles.danger,
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      try {
        await ref.read(catalogListProvider.notifier).removeByCode(p.code);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('«${p.code}» kaldırıldı.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
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
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
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

class _AdminProductCard extends StatelessWidget {
  const _AdminProductCard({
    required this.product,
    required this.onEdit,
    required this.onDelete,
  });

  final ProductModel product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final thumb = product.primaryImageAsset;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 64,
                height: 64,
                child: ColoredBox(
                  color: AppColors.surfaceMuted,
                  child: catalogDisplayImage(
                    thumb,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.code,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${product.category} · ${product.colorVariants.length} renk',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _StatusPill(status: product.status),
                ],
              ),
            ),
            IconButton(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Düzenle',
            ),
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Sil',
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'Taslak' => AppColors.textMuted,
      'Yayında' => AppColors.success,
      _ => AppColors.success,
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Text(
          status,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ),
    );
  }
}

class _EmptyAdminCard extends StatelessWidget {
  const _EmptyAdminCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(Icons.inventory_2_outlined, color: AppColors.textMuted),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Bu filtreye uyan ürün yok. Aramayı veya durumu değiştirin.',
                style: TextStyle(color: AppColors.textMuted, height: 1.35),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
