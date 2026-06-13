import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/supabase_ready_provider.dart';
import '../data/catalog_repository.dart';
import '../data/supabase_catalog_repository.dart';

final catalogRepositoryProvider = Provider<CatalogRepository?>((ref) {
  if (ref.watch(supabaseReadyProvider)) {
    return SupabaseCatalogRepository();
  }
  return null;
});

final catalogUsesSupabaseProvider = Provider<bool>((ref) {
  return ref.watch(catalogRepositoryProvider) != null;
});
