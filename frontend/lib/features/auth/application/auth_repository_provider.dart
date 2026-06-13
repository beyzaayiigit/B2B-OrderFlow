import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/supabase_ready_provider.dart';
import '../data/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (!ref.watch(supabaseReadyProvider)) {
    throw StateError('Supabase yapılandırması eksik.');
  }
  return SupabaseAuthRepository();
});
