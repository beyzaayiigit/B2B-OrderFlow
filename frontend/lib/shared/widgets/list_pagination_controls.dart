import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// Sipariş listeleri (üretim, sevk, takip).
const listPageSize = 10;

/// Katalog listeleri (alıcı + üretici).
const catalogPageSize = 5;

List<T> paginateSlice<T>(List<T> all, int page, {int pageSize = listPageSize}) {
  if (all.isEmpty) return const [];
  final start = page * pageSize;
  if (start >= all.length) return const [];
  final end = (start + pageSize).clamp(0, all.length);
  return all.sublist(start, end);
}

int pageCountFor(int totalCount, {int pageSize = listPageSize}) {
  if (totalCount <= 0) return 1;
  return (totalCount + pageSize - 1) ~/ pageSize;
}

void clampPageIfNeeded({
  required int currentPage,
  required int totalCount,
  required int pageSize,
  required void Function(int page) onPageChanged,
}) {
  final pages = pageCountFor(totalCount, pageSize: pageSize);
  if (currentPage >= pages && pages > 0) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      onPageChanged(pages - 1);
    });
  }
}

/// Liste altında sayfa geçişi; oklar lacivert kutu içinde.
class ListPaginationControls extends StatelessWidget {
  const ListPaginationControls({
    required this.totalCount,
    required this.currentPage,
    required this.onPageChanged,
    super.key,
    this.pageSize = listPageSize,
  });

  final int totalCount;
  final int currentPage;
  final ValueChanged<int> onPageChanged;
  final int pageSize;

  @override
  Widget build(BuildContext context) {
    final pages = pageCountFor(totalCount, pageSize: pageSize);
    if (totalCount <= pageSize) return const SizedBox.shrink();

    final canGoBack = currentPage > 0;
    final canGoForward = currentPage < pages - 1;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _PaginationNavBox(
            enabled: canGoBack,
            icon: Icons.chevron_left_rounded,
            onPressed: canGoBack
                ? () => onPageChanged(currentPage - 1)
                : null,
          ),
          const SizedBox(width: 16),
          Text(
            'Sayfa ${currentPage + 1} / $pages',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14,
              color: AppColors.navyDark,
            ),
          ),
          const SizedBox(width: 16),
          _PaginationNavBox(
            enabled: canGoForward,
            icon: Icons.chevron_right_rounded,
            onPressed: canGoForward
                ? () => onPageChanged(currentPage + 1)
                : null,
          ),
        ],
      ),
    );
  }
}

class _PaginationNavBox extends StatelessWidget {
  const _PaginationNavBox({
    required this.enabled,
    required this.icon,
    required this.onPressed,
  });

  final bool enabled;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: enabled ? AppColors.navyDark : AppColors.navyDark.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(
            icon,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }
}
