import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// `.env` dosyasından ortam değişkenleri (yalnızca anon key — service_role yok).
class AppEnv {
  AppEnv._();

  static bool _loaded = false;

  static Future<void> load() async {
    if (_loaded) return;
    try {
      await dotenv.load(fileName: '.env');
      _loaded = true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AppEnv: .env yüklenemedi: $e');
      }
    }
  }

  static String? get supabaseUrl => dotenv.maybeGet('SUPABASE_URL')?.trim();

  static String? get supabaseAnonKey =>
      dotenv.maybeGet('SUPABASE_ANON_KEY')?.trim();

  static bool get supabaseConfigured {
    final url = supabaseUrl;
    final key = supabaseAnonKey;
    return url != null &&
        url.isNotEmpty &&
        key != null &&
        key.isNotEmpty &&
        !url.contains('YOUR_PROJECT');
  }

  static int get storageQuotaBytes {
    final raw = dotenv.maybeGet('STORAGE_QUOTA_BYTES')?.trim();
    if (raw == null || raw.isEmpty) return 1073741824;
    return int.tryParse(raw) ?? 1073741824;
  }

  /// FastAPI asistan servisinin adresi (örn. http://localhost:8000).
  static String? get apiBaseUrl {
    final raw = dotenv.maybeGet('API_BASE_URL')?.trim();
    if (raw == null || raw.isEmpty) return null;
    return raw.endsWith('/') ? raw.substring(0, raw.length - 1) : raw;
  }

  /// LLM asistan butonları yalnızca API adresi tanımlıysa görünür.
  static bool get assistConfigured {
    final url = apiBaseUrl;
    return url != null && url.isNotEmpty;
  }
}
