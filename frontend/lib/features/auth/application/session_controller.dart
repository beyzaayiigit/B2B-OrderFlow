import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/go_router_refresh.dart';
import '../../../core/config/app_env.dart';
import '../../../core/config/supabase_bootstrap.dart';
import '../../../core/push/fcm_service.dart';
import '../../../shared/types/user_role.dart';
import 'auth_repository_provider.dart';

class SessionState {
  const SessionState({
    required this.isLoaded,
    required this.role,
    required this.email,
    required this.rememberMe,
    this.fullName,
    this.title,
    this.companyName,
  });

  final bool isLoaded;
  final UserRole? role;
  final String? email;
  final bool rememberMe;
  final String? fullName;
  final String? title;
  final String? companyName;

  bool get isAuthenticated => role != null;

  SessionState copyWith({
    bool? isLoaded,
    UserRole? role,
    String? email,
    bool? rememberMe,
    String? fullName,
    String? title,
    String? companyName,
  }) {
    return SessionState(
      isLoaded: isLoaded ?? this.isLoaded,
      role: role,
      email: email,
      rememberMe: rememberMe ?? this.rememberMe,
      fullName: fullName ?? this.fullName,
      title: title ?? this.title,
      companyName: companyName ?? this.companyName,
    );
  }

  static const initial = SessionState(
    isLoaded: false,
    role: null,
    email: null,
    rememberMe: false,
  );
}

const _kRoleKey = 'session.role';
const _kEmailKey = 'session.email';
const _kRememberKey = 'session.rememberMe';

final sessionControllerProvider =
    NotifierProvider<SessionController, SessionState>(SessionController.new);

class SessionController extends Notifier<SessionState> {
  bool get _usesSupabase =>
      AppEnv.supabaseConfigured && SupabaseBootstrap.isInitialized;

  @override
  SessionState build() {
    _restore();
    return SessionState.initial;
  }

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final remember = prefs.getBool(_kRememberKey) ?? false;
      final repo = ref.read(authRepositoryProvider);

      if (_usesSupabase) {
        if (remember) {
          final restored = await repo
              .tryRestoreSession()
              .timeout(const Duration(seconds: 8), onTimeout: () => null);
          if (restored != null) {
            state = SessionState(
              isLoaded: true,
              role: restored.role,
              email: restored.email,
              rememberMe: true,
              fullName: restored.fullName,
              title: restored.title,
              companyName: restored.companyName,
            );
            FcmService.registerToken();
            goRouterRefresh.notify();
            return;
          }
        }
        state = SessionState(
          isLoaded: true,
          role: null,
          email: null,
          rememberMe: remember,
        );
        goRouterRefresh.notify();
        return;
      }

      final rawRole = prefs.getString(_kRoleKey);
      final email = prefs.getString(_kEmailKey);
      final role = (remember && rawRole != null) ? _decode(rawRole) : null;
      state = SessionState(
        isLoaded: true,
        role: role,
        email: role != null ? email : null,
        rememberMe: remember,
      );
      goRouterRefresh.notify();
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('SessionController._restore: $e\n$st');
      }
      state = const SessionState(
        isLoaded: true,
        role: null,
        email: null,
        rememberMe: false,
      );
      goRouterRefresh.notify();
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
    required bool rememberMe,
  }) async {
    final repo = ref.read(authRepositoryProvider);
    final result = await repo.signIn(email: email, password: password);

    state = SessionState(
      isLoaded: true,
      role: result.role,
      email: result.email,
      rememberMe: rememberMe,
      fullName: result.fullName,
      title: result.title,
      companyName: result.companyName,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kRememberKey, rememberMe);
    if (rememberMe && !_usesSupabase) {
      await prefs.setString(_kRoleKey, _encode(result.role));
      await prefs.setString(_kEmailKey, result.email);
    } else {
      await prefs.remove(_kRoleKey);
      await prefs.remove(_kEmailKey);
    }

    FcmService.registerToken();

    goRouterRefresh.notify();
  }

  Future<void> signOut() async {
    await FcmService.unregisterToken();

    final repo = ref.read(authRepositoryProvider);
    await repo.signOut();

    state = const SessionState(
      isLoaded: true,
      role: null,
      email: null,
      rememberMe: false,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kRoleKey);
    await prefs.remove(_kEmailKey);
    await prefs.remove(_kRememberKey);
    goRouterRefresh.notify();
  }

  String _encode(UserRole role) => switch (role) {
    UserRole.buyer => 'buyer',
    UserRole.producer => 'producer',
  };

  UserRole? _decode(String raw) => switch (raw) {
    'buyer' => UserRole.buyer,
    'producer' => UserRole.producer,
    _ => null,
  };
}
