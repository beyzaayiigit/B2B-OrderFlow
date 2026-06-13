import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/responsive_page.dart';
import '../../../shared/search_prefix_match.dart';
import '../../../shared/widgets/catalog_display_image.dart';
import '../../../shared/widgets/list_pagination_controls.dart';
import '../application/catalog_list_provider.dart';
import '../domain/product_model.dart';

class CatalogPage extends ConsumerStatefulWidget {
  const CatalogPage({super.key});

  @override
  ConsumerState<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends ConsumerState<CatalogPage> {
  String _query = '';
  int _page = 0;

  List<ProductModel> _filtered(List<ProductModel> source) {
    return source
        .where((product) => matchesSearchPrefix(product.code, _query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final listState = ref.watch(catalogListProvider);
    final catalog = ref.watch(buyerCatalogItemsProvider);
    final results = _filtered(catalog);
    final pageItems = paginateSlice(
      results,
      _page,
      pageSize: catalogPageSize,
    );
    clampPageIfNeeded(
      currentPage: _page,
      totalCount: results.length,
      pageSize: catalogPageSize,
      onPageChanged: (p) => setState(() => _page = p),
    );

    if (listState.isLoading && catalog.isEmpty) {
      return const ResponsivePage(
        children: [
          Center(child: Padding(
            padding: EdgeInsets.all(32),
            child: CircularProgressIndicator(),
          )),
        ],
      );
    }

    if (listState.error != null && catalog.isEmpty) {
      return ResponsivePage(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(listState.error!),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () =>
                        ref.read(catalogListProvider.notifier).refresh(),
                    child: const Text('Yeniden dene'),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return ResponsivePage(
      children: [
        TextField(
          decoration: InputDecoration(
            hintText: 'Model kodu ara…',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _query.isEmpty
                ? null
                : IconButton(
                    onPressed: () {
                      setState(() {
                        _query = '';
                        _page = 0;
                      });
                    },
                    icon: const Icon(Icons.close),
                    tooltip: 'Aramayı temizle',
                  ),
          ),
          onChanged: (value) {
            setState(() {
              _query = value;
              _page = 0;
            });
          },
        ),
        const SizedBox(height: 16),
        if (results.isEmpty)
          const _EmptyResultsCard()
        else ...[
          for (final product in pageItems) ...[
            _ProductCard(product: product),
            const SizedBox(height: 14),
          ],
          ListPaginationControls(
            totalCount: results.length,
            currentPage: _page,
            pageSize: catalogPageSize,
            onPageChanged: (p) => setState(() => _page = p),
          ),
        ],
      ],
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
                'Bu koda uyan model yok. Aramayı değiştirin veya temizleyin.',
                style: TextStyle(color: AppColors.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product});

  final ProductModel product;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () => context.go('/orders/new', extra: product),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CatalogVariantGallery(variants: product.colorVariants),
              const SizedBox(height: 14),
              Text(
                product.code,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                product.name,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              _CategoryChip(category: product.category),
            ],
          ),
        ),
      ),
    );
  }
}

/// Kategoriye göre marka aksan rengiyle renklenen küçük etiket.
class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.category});

  final String category;

  static const _accents = [
    AppColors.secondary,
    AppColors.tertiary,
    AppColors.softBlue,
    AppColors.navy,
  ];

  @override
  Widget build(BuildContext context) {
    final color = _accents[category.hashCode.abs() % _accents.length];
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Text(
          category,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

/// Katalog kartında modele bağlı renk fotoğraflarını yan kaydırmalı galeride gösterir.
class _CatalogVariantGallery extends StatefulWidget {
  const _CatalogVariantGallery({required this.variants});

  final List<ProductColorVariant> variants;

  @override
  State<_CatalogVariantGallery> createState() =>
      _CatalogVariantGalleryState();
}

class _CatalogVariantGalleryState extends State<_CatalogVariantGallery> {
  late final PageController _pageController;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final variants = widget.variants;
    if (variants.isEmpty) {
      return AspectRatio(
        aspectRatio: 1.25,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: ColoredBox(
            color: AppColors.surfaceMuted,
            child: Icon(
              Icons.image_not_supported_outlined,
              color: AppColors.textMuted.withValues(alpha: 0.5),
              size: 40,
            ),
          ),
        ),
      );
    }

    final showPager = variants.length > 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AspectRatio(
          aspectRatio: 1.25,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: ColoredBox(
              color: AppColors.surfaceMuted,
              child: PageView.builder(
                controller: _pageController,
                itemCount: variants.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) {
                  return catalogDisplayImage(
                    variants[i].imageAsset,
                    fit: BoxFit.contain,
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (showPager)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Renk: ',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted.withValues(alpha: 0.85),
                ),
              ),
              Text(
                variants[_index].colorName,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${_index + 1}/${variants.length}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          )
        else
          Text(
            'Renk: ${variants.first.colorName}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
            ),
          ),
        if (showPager) ...[
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(variants.length, (i) {
              final active = i == _index;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: active ? 18 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: active ? AppColors.navy : AppColors.border,
                  ),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}
