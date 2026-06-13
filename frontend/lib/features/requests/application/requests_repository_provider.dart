import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/supabase_ready_provider.dart';
import '../data/requests_repository.dart';
import '../data/supabase_requests_repository.dart';

final requestsRepositoryProvider = Provider<RequestsRepository?>((ref) {
  if (ref.watch(supabaseReadyProvider)) {
    return SupabaseRequestsRepository();
  }
  return null;
});

final requestsUsesSupabaseProvider = Provider<bool>((ref) {
  return ref.watch(requestsRepositoryProvider) != null;
});
