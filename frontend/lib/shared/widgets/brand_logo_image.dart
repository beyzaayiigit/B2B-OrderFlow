import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// Logo dosyası yoksa çökmez; metin/ikon yedek gösterir.
class BrandLogoImage extends StatelessWidget {
  const BrandLogoImage({
    super.key,
    required this.assetPath,
    this.height = 48,
    this.maxWidth = 320,
    this.fallbackLabel,
  });

  final String assetPath;
  final double height;
  final double maxWidth;
  final String? fallbackLabel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: height,
          maxWidth: maxWidth,
        ),
        child: Image.asset(
          assetPath,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return _LogoFallback(
              label: fallbackLabel ?? 'B2B',
              height: height,
            );
          },
        ),
      ),
    );
  }
}

class _LogoFallback extends StatelessWidget {
  const _LogoFallback({required this.label, required this.height});

  final String label;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.storefront_outlined,
          size: height * 0.7,
          color: AppColors.navy,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: AppColors.navy,
          ),
        ),
      ],
    );
  }
}
