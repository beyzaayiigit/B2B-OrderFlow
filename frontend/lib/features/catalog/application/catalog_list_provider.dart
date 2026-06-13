import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/session_controller.dart';
import '../data/catalog_repository.dart';
import '../data/catalog_status_mapper.dart';
import '../domain/product_model.dart';
import '../../producer/catalog_admin/application/catalog_storage_usage_provider.dart';
import 'catalog_repository_provider.dart';

class CatalogListState {
  const CatalogListState({
    required this.items,
    required this.isLoading,
    this.error,
  });

  final List<ProductModel> items;
  final bool isLoading;
  final String? error;

  static const initial = CatalogListState(items: [], isLoading: true);

  CatalogListState copyWith({
    List<ProductModel>? items,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return CatalogListState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Uygulama genelinde katalog (Supabase).
class CatalogListNotifier extends Notifier<CatalogListState> {
  @override
  CatalogListState build() {
    ref.listen(sessionControllerProvider, (previous, next) {
      if (next.isAuthenticated &&
          previous?.isAuthenticated != true &&
          next.isLoaded) {
        Future.microtask(refresh);
      }
    });
    Future.microtask(refresh);
    return CatalogListState.initial;
  }

  Future<void> refresh() async {
    final repo = ref.read(catalogRepositoryProvider);
    if (repo == null) {
      state = const CatalogListState(
        items: [],
        isLoading: false,
        error: 'Sunucu bağlantısı kurulamadı.',
      );
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final items = await repo.fetchCatalog();
      state = CatalogListState(items: items, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e is CatalogFailure ? e.message : e.toString(),
      );
    }
  }

  Future<void> upsert(ProductModel product, {required bool isNew}) async {
    final repo = ref.read(catalogRepositoryProvider);
    if (repo == null) {
      throw const CatalogFailure('Sunucu bağlantısı kurulamadı.');
    }
    await repo.upsertProduct(product, isNew: isNew);
    await refresh();
    await ref.read(catalogStorageUsageProvider.notifier).refresh();
  }

  Future<void> removeByCode(String code) async {
    final repo = ref.read(catalogRepositoryProvider);
    if (repo == null) {
      throw const CatalogFailure('Sunucu bağlantısı kurulamadı.');
    }
    await repo.deleteByCode(code);
    await refresh();
    await ref.read(catalogStorageUsageProvider.notifier).refresh();
  }
}

final catalogListProvider =
    NotifierProvider<CatalogListNotifier, CatalogListState>(
  CatalogListNotifier.new,
);

/// Kolay erişim: yalnızca ürün listesi.
final catalogItemsProvider = Provider<List<ProductModel>>((ref) {
  return ref.watch(catalogListProvider).items;
});

/// Alıcı katalog filtresi (Taslak hariç = Yayında).
final buyerCatalogItemsProvider = Provider<List<ProductModel>>((ref) {
  return ref
      .watch(catalogItemsProvider)
      .where((p) => CatalogStatusMapper.isVisibleToBuyer(p.status))
      .toList();
});

class CatalogCategoriesState {
  const CatalogCategoriesState({
    required this.names,
    required this.isLoading,
    this.error,
  });

  final List<String> names;
  final bool isLoading;
  final String? error;

  static const initial = CatalogCategoriesState(names: [], isLoading: true);
}

class CatalogCategoriesNotifier extends Notifier<CatalogCategoriesState> {
  @override
  CatalogCategoriesState build() {
    ref.listen(sessionControllerProvider, (previous, next) {
      if (next.isAuthenticated &&
          previous?.isAuthenticated != true &&
          next.isLoaded) {
        Future.microtask(refresh);
      }
    });
    Future.microtask(refresh);
    return CatalogCategoriesState.initial;
  }

  Future<void> refresh() async {
    final repo = ref.read(catalogRepositoryProvider);
    if (repo == null) {
      state = const CatalogCategoriesState(
        names: [],
        isLoading: false,
        error: 'Sunucu bağlantısı kurulamadı.',
      );
      return;
    }

    state = const CatalogCategoriesState(names: [], isLoading: true);
    try {
      final names = await repo.fetchActiveCategoryNames();
      state = CatalogCategoriesState(names: names, isLoading: false);
    } catch (e) {
      state = CatalogCategoriesState(
        names: [],
        isLoading: false,
        error: e is CatalogFailure ? e.message : e.toString(),
      );
    }
  }
}

final catalogCategoriesProvider =
    NotifierProvider<CatalogCategoriesNotifier, CatalogCategoriesState>(
  CatalogCategoriesNotifier.new,
);
