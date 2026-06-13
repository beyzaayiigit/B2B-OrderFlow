import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_bootstrap.dart';
import '../../../shared/types/user_role.dart';

/// Auth servislerinin geriye döndürdüğü minimum sonuç.
class AuthResult {
  const AuthResult({
    required this.email,
    required this.role,
    this.fullName,
    this.title,
    this.companyName,
  });

  final String email;
  final UserRole role;
  final String? fullName;
  final String? title;
  final String? companyName;
}

class AuthFailure implements Exception {
  const AuthFailure(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Giriş, çıkış ve oturum geri yükleme sözleşmesi.
abstract class AuthRepository {
  Future<AuthResult> signIn({
    required String email,
    required String password,
  });

  Future<void> signOut();

  /// Uygulama açılışında mevcut Supabase oturumu + profil.
  Future<AuthResult?> tryRestoreSession();

  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  });

}

void _validatePasswordChange(String newPassword, String confirmPassword) {
  if (newPassword.length < 6) {
    throw const AuthFailure('Yeni şifre en az 6 karakter olmalı.');
  }
  if (newPassword != confirmPassword) {
    throw const AuthFailure('Şifreler eşleşmiyor.');
  }
}

class SupabaseAuthRepository implements AuthRepository {
  SupabaseClient get _client => SupabaseBootstrap.client;

  @override
  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty || password.isEmpty) {
      throw const AuthFailure('E-posta ve şifre boş bırakılamaz.');
    }

    try {
      final response = await _client.auth.signInWithPassword(
        email: normalizedEmail,
        password: password,
      );
      final user = response.user;
      if (user == null) {
        throw const AuthFailure('Giriş başarısız.');
      }
      return _profileForUser(user.id, fallbackEmail: normalizedEmail);
    } on AuthException catch (e) {
      throw AuthFailure(_mapAuthError(e));
    } on AuthFailure {
      rethrow;
    } catch (e) {
      throw AuthFailure('Bağlantı hatası: $e');
    }
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  @override
  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    _validatePasswordChange(newPassword, confirmPassword);
    if (currentPassword.isEmpty) {
      throw const AuthFailure('Mevcut şifrenizi girin.');
    }
    if (currentPassword == newPassword) {
      throw const AuthFailure('Yeni şifre mevcut şifreden farklı olmalı.');
    }

    final email = _client.auth.currentUser?.email?.trim();
    if (email == null || email.isEmpty) {
      throw const AuthFailure('Oturum bulunamadı. Tekrar giriş yapın.');
    }

    try {
      final verify = await _client.auth.signInWithPassword(
        email: email,
        password: currentPassword,
      );
      if (verify.user == null) {
        throw const AuthFailure('Mevcut şifre hatalı.');
      }

      await _client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
    } on AuthException catch (e) {
      throw AuthFailure(_mapPasswordError(e));
    } catch (e) {
      if (e is AuthFailure) rethrow;
      throw AuthFailure('Şifre güncellenemedi: $e');
    }
  }

  String _mapPasswordError(AuthException e) {
    final msg = e.message.toLowerCase();
    if (msg.contains('reauth') ||
        msg.contains('session') ||
        msg.contains('not authorized')) {
      return 'Güvenlik nedeniyle mevcut şifrenizi doğru girmeniz gerekiyor.';
    }
    if (msg.contains('different') || msg.contains('same')) {
      return 'Yeni şifre mevcut şifreden farklı olmalı.';
    }
    if (msg.contains('weak') || msg.contains('strength')) {
      return 'Şifre çok zayıf. Daha uzun veya karmaşık bir şifre seçin.';
    }
    if (msg.contains('invalid') || msg.contains('credentials')) {
      return 'Mevcut şifre hatalı.';
    }
    return e.message;
  }

  @override
  Future<AuthResult?> tryRestoreSession() async {
    final session = _client.auth.currentSession;
    if (session == null) return null;

    final user = _client.auth.currentUser;
    if (user == null) return null;

    try {
      return await _profileForUser(
        user.id,
        fallbackEmail: user.email ?? '',
      );
    } on AuthFailure {
      await _client.auth.signOut();
      return null;
    }
  }

  Future<AuthResult> _profileForUser(
    String userId, {
    required String fallbackEmail,
  }) async {
    final row = await _client
        .from('profiles')
        .select('role, email, full_name, title, companies(name)')
        .eq('id', userId)
        .maybeSingle();

    if (row == null) {
      await _client.auth.signOut();
      throw const AuthFailure(
        'Hesabınız henüz tanımlanmadı. Yöneticinize başvurun.',
      );
    }

    final roleRaw = row['role'] as String?;
    final role = switch (roleRaw) {
      'buyer' => UserRole.buyer,
      'producer' => UserRole.producer,
      _ => null,
    };
    if (role == null) {
      await _client.auth.signOut();
      throw const AuthFailure('Profil rolü geçersiz.');
    }

    final profileEmail = (row['email'] as String?)?.trim();
    final email = (profileEmail != null && profileEmail.isNotEmpty)
        ? profileEmail.toLowerCase()
        : fallbackEmail.toLowerCase();

    final fullName = row['full_name'] as String?;
    final title = row['title'] as String?;
    final companiesData = row['companies'] as Map<String, dynamic>?;
    final companyName = companiesData?['name'] as String?;

    return AuthResult(
      email: email,
      role: role,
      fullName: fullName,
      title: title,
      companyName: companyName,
    );
  }

  String _mapAuthError(AuthException e) {
    final msg = e.message.toLowerCase();
    if (msg.contains('invalid') || msg.contains('credentials')) {
      return 'E-posta veya şifre hatalı.';
    }
    return e.message;
  }
}
