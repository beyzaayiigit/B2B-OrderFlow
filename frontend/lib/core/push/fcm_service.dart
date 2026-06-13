import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../config/app_env.dart';
import '../config/supabase_bootstrap.dart';

@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  if (kDebugMode) {
    debugPrint('FCM background: ${message.notification?.title}');
  }
}

class FcmService {
  FcmService._();

  static final _messaging = FirebaseMessaging.instance;
  static String? _currentToken;

  static String? get currentToken => _currentToken;

  /// Firebase + FCM baslatma. [AppBootstrap] icinde cagrilir.
  static Future<void> init() async {
    var firebaseReady = false;
    try {
      await Firebase.initializeApp();
      firebaseReady = true;
    } catch (e) {
      if (kDebugMode) debugPrint('FcmService: Firebase.initializeApp hata: $e');
    }

    // iOS izni Firebase basarisiz olsa bile istenmeli.
    if (Platform.isIOS) {
      try {
        final settings = await _messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
        if (kDebugMode) {
          debugPrint('FcmService: iOS izin durumu: ${settings.authorizationStatus}');
        }
        await _messaging.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
        await _waitForApnsToken();
      } catch (e) {
        if (kDebugMode) debugPrint('FcmService: iOS izin istegi hata: $e');
      }
    }

    if (!firebaseReady) return;

    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

    try {
      _currentToken = await _fetchFcmToken();
      if (kDebugMode) {
        debugPrint('FcmService: token alindi (${_currentToken?.substring(0, 12)}...)');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('FcmService: token alinamadi: $e');
    }

    _messaging.onTokenRefresh.listen((newToken) {
      _currentToken = newToken;
      _saveTokenToSupabase(newToken);
      if (kDebugMode) {
        debugPrint('FcmService: token yenilendi');
      }
    });
  }

  /// Giris yapildiginda token'i Supabase'e kaydet.
  static Future<void> registerToken() async {
    if (_currentToken == null) {
      _currentToken = await _fetchFcmToken();
    }
    if (_currentToken == null) return;
    await _saveTokenToSupabase(_currentToken!);
  }

  static Future<void> _waitForApnsToken() async {
    for (var i = 0; i < 10; i++) {
      final apns = await _messaging.getAPNSToken();
      if (apns != null) return;
      await Future<void>.delayed(const Duration(milliseconds: 400));
    }
  }

  static Future<String?> _fetchFcmToken() async {
    if (Platform.isIOS) {
      await _waitForApnsToken();
    }
    try {
      return await _messaging.getToken();
    } catch (e) {
      if (kDebugMode) debugPrint('FcmService: token alinamadi: $e');
      return null;
    }
  }

  /// Cikis yapildiginda token'i Supabase'den sil.
  static Future<void> unregisterToken() async {
    if (_currentToken == null) return;
    if (!SupabaseBootstrap.isInitialized) return;

    try {
      final userId = SupabaseBootstrap.client.auth.currentUser?.id;
      if (userId == null) return;

      await SupabaseBootstrap.client
          .from('device_tokens')
          .delete()
          .eq('user_id', userId)
          .eq('fcm_token', _currentToken!);

      if (kDebugMode) debugPrint('FcmService: token silindi');
    } catch (e) {
      if (kDebugMode) debugPrint('FcmService: token silinemedi: $e');
    }
  }

  static Future<void> _saveTokenToSupabase(String token) async {
    if (!AppEnv.supabaseConfigured || !SupabaseBootstrap.isInitialized) return;

    final userId = SupabaseBootstrap.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await SupabaseBootstrap.client
          .from('device_tokens')
          .delete()
          .eq('fcm_token', token)
          .neq('user_id', userId);

      await SupabaseBootstrap.client
          .from('device_tokens')
          .delete()
          .eq('user_id', userId)
          .neq('fcm_token', token);

      await SupabaseBootstrap.client.from('device_tokens').upsert(
        {
          'user_id': userId,
          'fcm_token': token,
          'platform': Platform.isIOS ? 'ios' : 'android',
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        },
        onConflict: 'user_id,fcm_token',
      );
      if (kDebugMode) debugPrint('FcmService: token kaydedildi');
    } catch (e) {
      if (kDebugMode) debugPrint('FcmService: token kaydedilemedi: $e');
    }
  }

  static void listenForeground({
    required void Function(RemoteMessage message) onMessage,
  }) {
    FirebaseMessaging.onMessage.listen(onMessage);
  }

  static void listenNotificationOpen({
    required void Function(RemoteMessage message) onOpen,
  }) {
    FirebaseMessaging.onMessageOpenedApp.listen(onOpen);
  }

  static Future<void> consumeInitialMessage({
    required void Function(RemoteMessage message) onOpen,
  }) async {
    final initial = await _messaging.getInitialMessage();
    if (initial != null) onOpen(initial);
  }
}
