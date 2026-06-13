import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Android / iOS / masaüstü: asset, HTTP(S) URL veya cihazdaki dosya yolu.
Widget buildCatalogDisplayImage(
  String source, {
  BoxFit fit = BoxFit.cover,
  Alignment alignment = Alignment.center,
}) {
  if (source.startsWith('assets/')) {
    return Image.asset(
      source,
      fit: fit,
      alignment: alignment,
    );
  }
  if (source.startsWith('http://') || source.startsWith('https://')) {
    return CachedNetworkImage(
      imageUrl: source,
      fit: fit,
      alignment: alignment,
      placeholder: (_, _) => const Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      errorWidget: (_, _, _) => const _ImageErrorMini(),
    );
  }
  return Image.file(
    File(source),
    fit: fit,
    alignment: alignment,
    errorBuilder: (_, _, _) => const _ImageErrorMini(),
  );
}

class _ImageErrorMini extends StatelessWidget {
  const _ImageErrorMini();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(Icons.broken_image_outlined, color: Colors.black38),
    );
  }
}
