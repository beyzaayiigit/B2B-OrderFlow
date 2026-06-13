import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/application/session_controller.dart';
import '../../features/orders/application/tracked_orders_notifier.dart';
import '../../features/producer/application/producer_orders_notifier.dart';
import '../../features/requests/application/request_threads_notifier.dart';

/// Karşı panelden gelen push veya uygulama ön plana dönünce listeleri yeniler.
class RemoteDataSync {
  RemoteDataSync._();

  static Timer? _debounceTimer;
  static bool _refreshInFlight = false;

  static const _debounceDuration = Duration(milliseconds: 400);

  /// Ardışık olaylarda tek fetch için gecikmeli yenileme.
  static void scheduleRefresh(ProviderContainer container) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      unawaited(refreshAfterRemoteEvent(container));
    });
  }

  static Future<void> refreshAfterRemoteEvent(ProviderContainer container) async {
    final session = container.read(sessionControllerProvider);
    if (!session.isLoaded || !session.isAuthenticated) return;

    if (_refreshInFlight) return;
    _refreshInFlight = true;
    try {
      await Future.wait<void>([
        container.read(trackedOrdersProvider.notifier).refresh(),
        container.read(producerOrdersProvider.notifier).refresh(),
        container.read(requestThreadsProvider.notifier).refresh(),
      ]);
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('RemoteDataSync.refreshAfterRemoteEvent: $e\n$st');
      }
    } finally {
      _refreshInFlight = false;
    }
  }
}
