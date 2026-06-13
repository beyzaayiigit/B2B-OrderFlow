import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_env.dart';

class SupabaseBootstrap {
  SupabaseBootstrap._();

  static bool _initialized = false;

  static bool get isInitialized => _initialized;

  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> init() async {
    if (_initialized || !AppEnv.supabaseConfigured) return;

    await Supabase.initialize(
      url: AppEnv.supabaseUrl!,
      anonKey: AppEnv.supabaseAnonKey!,
    );
    _initialized = true;

    if (kDebugMode) {
      debugPrint('SupabaseBootstrap: bağlantı hazır');
    }
  }
}
