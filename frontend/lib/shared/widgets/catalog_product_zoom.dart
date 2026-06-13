import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import 'catalog_display_image.dart';

/// Katalog görseli küçük önizleme; tıklanınca [showCatalogProductZoom] açar.
class CatalogProductThumbnail extends StatelessWidget {
  const CatalogProductThumbnail({
    required this.asset,
    this.size = 56,
    this.borderRadius = 10,
    this.previewColorName,
    this.title,
    this.subtitle,
    super.key,
  });

  final String asset;
  final double size;
  final double borderRadius;
  final String? previewColorName;
  final String? title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showCatalogProductZoom(
        context,
        asset: asset,
        title: title,
        subtitle: previewColorName ?? subtitle,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: SizedBox(
              width: size,
              height: size,
              child: ColoredBox(
                color: AppColors.surfaceMuted,
                child: catalogDisplayImage(asset, fit: BoxFit.contain),
              ),
            ),
          ),
          Positioned(
            right: 2,
            bottom: 2,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                Icons.zoom_in,
                size: size <= 48 ? 10 : 12,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> showCatalogProductZoom(
  BuildContext context, {
  required String asset,
  String? title,
  String? subtitle,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) => _CatalogProductZoomDialog(
      asset: asset,
      title: title,
      subtitle: subtitle,
    ),
  );
}

class _CatalogProductZoomDialog extends StatelessWidget {
  const _CatalogProductZoomDialog({
    required this.asset,
    this.title,
    this.subtitle,
  });

  final String asset;
  final String? title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
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
          if (title != null || subtitle != null)
            Positioned(
              top: 8,
              left: 8,
              right: 48,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title != null)
                    Text(
                      title!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                ],
              ),
            ),
          Positioned(
            top: 4,
            right: 4,
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
