import '../domain/product_model.dart';

class CatalogFailure implements Exception {
  const CatalogFailure(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Katalog listeleme ve üretici CRUD.
abstract class CatalogRepository {
  Future<List<ProductModel>> fetchCatalog();

  Future<List<String>> fetchActiveCategoryNames();

  Future<void> upsertProduct(ProductModel product, {required bool isNew});

  Future<void> deleteByCode(String code);
}
