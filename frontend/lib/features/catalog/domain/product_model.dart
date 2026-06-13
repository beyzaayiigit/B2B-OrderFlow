/// Storage'da görsel (image_url) yoksa kategoriye/renge göre markasız
/// demo yer tutucu görseli seçer. Gerçek yüklemeler image_url ile gelir.
String catalogPlaceholderAsset(String category, String colorName) {
  const base = 'assets/images/products';
  final c = category.toLowerCase();
  final color = colorName.toLowerCase();
  if (c.contains('polo')) {
    final dark =
        color.contains('siyah') || color.contains('black') ||
        color.contains('lacivert') || color.contains('antrasit') ||
        color.contains('füme') || color.contains('bordo');
    return dark ? '$base/polo_black.png' : '$base/polo_cream.png';
  }
  if (c.contains('sweat') ||
      c.contains('kapüş') ||
      c.contains('hood') ||
      c.contains('hırka')) {
    return '$base/hoodie_gray.png';
  }
  if (c.contains('tişört') ||
      c.contains('tisort') ||
      c.contains('t-shirt') ||
      c.contains('shirt') ||
      c.contains('tee')) {
    return '$base/tshirt_navy.png';
  }
  return '$base/polo_cream.png';
}

/// Katalogdaki tek bir renk / görsel çifti (aynı model kodu altında).
class ProductColorVariant {
  const ProductColorVariant({
    required this.colorName,
    required this.imageAsset,
    this.id,
  });

  final String? id;
  final String colorName;
  /// Asset yolu, yerel dosya, veya Storage public URL.
  final String imageAsset;
}

class ProductModel {
  const ProductModel({
    required this.code,
    required this.name,
    required this.category,
    required this.status,
    required this.colorVariants,
    this.id,
  });

  final String? id;

  /// Renk listesi boşsa kullanılacak yedek yol (crash önleme).
  static const fallbackImagePath = 'assets/images/products/polo_cream.png';
  static const _fallbackImage = fallbackImagePath;

  final String code;
  final String name;
  final String category;
  final String status;
  final List<ProductColorVariant> colorVariants;

  /// Geriye dönük uyumluluk veya “varsayılan” önizleme.
  String get imageAsset => primaryImageAsset;

  String get primaryImageAsset => colorVariants.isEmpty
      ? _fallbackImage
      : colorVariants.first.imageAsset;

  /// Tam renk adı eşleşmesi; yoksa katalogdaki ilk görsel.
  String imageAssetForColor(String colorName) {
    final target = colorName.trim();
    for (final v in colorVariants) {
      if (v.colorName == target) return v.imageAsset;
    }
    return primaryImageAsset;
  }

  /// Siparişteki renk sırasına göre ilk eşleşen fotoğraf (özet / onay diyaloğu).
  String imageAssetPreferringColors(Iterable<String> colorsInOrder) {
    for (final c in colorsInOrder) {
      final t = c.trim();
      for (final v in colorVariants) {
        if (v.colorName == t) return v.imageAsset;
      }
    }
    return primaryImageAsset;
  }
}
