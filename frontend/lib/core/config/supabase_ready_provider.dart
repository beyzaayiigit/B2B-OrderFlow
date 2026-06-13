import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_env.dart';
import 'supabase_bootstrap.dart';

/// Supabase init tamamlandı mı (Riverpod yeniden hesaplar).
final supabaseReadyProvider = Provider<bool>((ref) {
  return AppEnv.supabaseConfigured && SupabaseBootstrap.isInitialized;
});
