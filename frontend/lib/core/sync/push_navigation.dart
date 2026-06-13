import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../shared/types/user_role.dart';

/// FCM `data` alanından hedef rota (yoksa `null`).
String? pushTargetRoute(RemoteMessage message, UserRole? role) {
  final data = message.data;
  final threadId = (data['thread_id'] ?? '').toString().trim();
  if (threadId.isNotEmpty) {
    return '/requests/thread/${Uri.encodeComponent(threadId)}';
  }

  final kind = (data['kind'] ?? '').toString();
  if (kind.startsWith('buyer_') || kind.startsWith('producer_')) {
    return '/requests';
  }

  final orderCode = (data['order_code'] ?? '').toString().trim();
  if (orderCode.isNotEmpty) {
    if (role == UserRole.producer) {
      return '/producer/incoming/${Uri.encodeComponent(orderCode)}';
    }
    return '/tracking/order/${Uri.encodeComponent(orderCode)}';
  }

  return null;
}

bool _isShellTabLocation(String location) {
  return location == '/catalog' ||
      location.startsWith('/orders/new') ||
      location == '/tracking' ||
      location == '/buyer/shipped' ||
      location == '/producer/shipped' ||
      location.startsWith('/producer/catalog-admin');
}

/// Bildirimden detaya gider; alt sekme yığınını korur (`push`, `go` değil).
void navigatePushTarget(String targetRoute) {
  final location = appRouter.state.matchedLocation;
  if (!_isShellTabLocation(location)) {
    appRouter.go('/catalog');
  }
  if (appRouter.state.matchedLocation == targetRoute) return;
  appRouter.push(targetRoute);
}

/// Detay ekranından güvenli çıkış (bildirim `go` ile açıldıysa `pop` patlamasın).
void safePopDetail(BuildContext context, {String fallback = '/catalog'}) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go(fallback);
  }
}
