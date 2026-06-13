import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/session_controller.dart';
import '../data/orders_repository.dart';
import '../data/tracked_order_lookup.dart';
import '../domain/tracked_order.dart';
import 'orders_repository_provider.dart';

class TrackedOrdersState {
  const TrackedOrdersState({
    required this.items,
    required this.isLoading,
    this.error,
  });

  final List<TrackedOrder> items;
  final bool isLoading;
  final String? error;

  static const initial = TrackedOrdersState(items: [], isLoading: true);
}

final trackedOrdersProvider =
    NotifierProvider<TrackedOrdersNotifier, TrackedOrdersState>(
  TrackedOrdersNotifier.new,
);

/// Alıcı sipariş listesi (Supabase).
class TrackedOrdersNotifier extends Notifier<TrackedOrdersState> {
  @override
  TrackedOrdersState build() {
    ref.listen(sessionControllerProvider, (previous, next) {
      if (next.isAuthenticated &&
          previous?.isAuthenticated != true &&
          next.isLoaded) {
        Future.microtask(refresh);
      }
    });
    Future.microtask(refresh);
    return TrackedOrdersState.initial;
  }

  Future<void> refresh() async {
    final repo = ref.read(ordersRepositoryProvider);
    if (repo == null) {
      state = const TrackedOrdersState(
        items: [],
        isLoading: false,
        error: 'Sunucu bağlantısı kurulamadı.',
      );
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final items = await repo.fetchBuyerOrders();
      state = TrackedOrdersState(items: items, isLoading: false);
      syncTrackedOrdersLookup(items);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e is OrderFailure ? e.message : e.toString(),
      );
    }
  }

  TrackedOrder? orderByNo(String orderNo) {
    for (final o in state.items) {
      if (o.orderNo == orderNo) return o;
      final lp = o.producerOrderCode;
      if (lp != null && lp == orderNo) return o;
    }
    return null;
  }
}

extension on TrackedOrdersState {
  TrackedOrdersState copyWith({
    List<TrackedOrder>? items,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return TrackedOrdersState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}
