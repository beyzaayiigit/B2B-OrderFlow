import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../shared/widgets/catalog_display_image.dart';
import '../../catalog/application/catalog_list_provider.dart';
import '../application/request_threads_notifier.dart';

/// Talep listesi kartlarında model küçük resmi (64×64).
class RequestThreadModelThumbnail extends ConsumerWidget {
  const RequestThreadModelThumbnail({
    required this.productCode,
    super.key,
  });

  final String productCode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final code = productCode.trim();
    String? asset;
    if (code.isNotEmpty) {
      for (final model in ref.watch(catalogItemsProvider)) {
        if (model.code == code) {
          asset = model.imageAsset;
          break;
        }
      }
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 64,
        height: 64,
        color: AppColors.surfaceMuted,
        child: asset != null
            ? catalogDisplayImage(asset, fit: BoxFit.cover)
            : const Icon(
                Icons.checkroom_outlined,
                color: AppColors.textMuted,
                size: 28,
              ),
      ),
    );
  }
}

/// Siparişe bağlı güncelleme talebi thread'ini açar; yoksa bilgi mesajı gösterir.
Future<void> openRequestThreadForOrder(
  BuildContext context,
  WidgetRef ref, {
  required String orderNo,
}) async {
  final key = orderNo.trim();
  if (key.isEmpty) return;

  final threadId =
      ref.read(requestThreadsProvider.notifier).threadIdForOrder(key);
  if (!context.mounted) return;

  if (threadId != null) {
    await context.push('/requests/thread/$threadId');
    return;
  }

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      behavior: SnackBarBehavior.floating,
      content: Text('Bu sipariş için henüz güncelleme talebi yok.'),
    ),
  );
}
