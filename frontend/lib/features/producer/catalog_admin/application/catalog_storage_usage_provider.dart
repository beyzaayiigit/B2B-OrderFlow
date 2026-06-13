import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/application/session_controller.dart';
import '../../../../core/config/app_env.dart';
import '../../../../core/config/supabase_ready_provider.dart';
import '../data/catalog_storage_service.dart';

final catalogStorageUsageProvider =
    AsyncNotifierProvider<CatalogStorageUsageNotifier, CatalogStorageUsage>(
  CatalogStorageUsageNotifier.new,
);

class CatalogStorageUsageNotifier extends AsyncNotifier<CatalogStorageUsage> {
  CatalogStorageUsage get _emptyUsage => CatalogStorageUsage(
        usedBytes: 0,
        quotaBytes: AppEnv.storageQuotaBytes,
      );

  @override
  Future<CatalogStorageUsage> build() async {
    ref.listen(sessionControllerProvider, (previous, next) {
      if (next.isLoaded &&
          (previous?.isAuthenticated != next.isAuthenticated ||
              previous?.email != next.email)) {
        Future.microtask(ref.invalidateSelf);
      }
    });

    if (!ref.watch(supabaseReadyProvider)) {
      return _emptyUsage;
    }

    final session = ref.watch(sessionControllerProvider);
    if (!session.isAuthenticated) {
      return _emptyUsage;
    }

    return CatalogStorageService().fetchUsage();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      if (!ref.read(supabaseReadyProvider)) return _emptyUsage;
      final session = ref.read(sessionControllerProvider);
      if (!session.isAuthenticated) return _emptyUsage;
      return CatalogStorageService().fetchUsage();
    });
  }
}
