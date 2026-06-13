import 'package:flutter/material.dart';

import 'catalog_display_image_io.dart'
    if (dart.library.html) 'catalog_display_image_web.dart' as impl;

/// Katalog görseli: `assets/...`, `http(s)://...` veya (mobilde) galeri/kamera dosya yolu.
Widget catalogDisplayImage(
  String source, {
  BoxFit fit = BoxFit.cover,
  Alignment alignment = Alignment.center,
}) {
  return impl.buildCatalogDisplayImage(
    source,
    fit: fit,
    alignment: alignment,
  );
}
