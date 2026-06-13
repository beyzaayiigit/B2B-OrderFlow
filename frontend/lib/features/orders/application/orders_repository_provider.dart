import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/supabase_ready_provider.dart';
import '../data/orders_repository.dart';
import '../data/supabase_orders_repository.dart';

final ordersRepositoryProvider = Provider<OrdersRepository?>((ref) {
  if (ref.watch(supabaseReadyProvider)) {
    return SupabaseOrdersRepository();
  }
  return null;
});

final ordersUsesSupabaseProvider = Provider<bool>((ref) {
  return ref.watch(ordersRepositoryProvider) != null;
});
