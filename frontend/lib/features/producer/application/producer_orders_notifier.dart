import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/session_controller.dart';
import '../../orders/application/orders_repository_provider.dart';
import '../../orders/application/tracked_orders_notifier.dart';
import '../../orders/data/orders_repository.dart';
import '../../requests/application/request_threads_notifier.dart';
import '../domain/producer_order.dart';

class ProducerOrdersState {
  const ProducerOrdersState({
    required this.items,
    required this.isLoading,
    this.error,
  });

  final List<ProducerOrder> items;
  final bool isLoading;
  final String? error;

  static const initial = ProducerOrdersState(items: [], isLoading: true);
}

final producerOrdersProvider =
    NotifierProvider<ProducerOrdersNotifier, ProducerOrdersState>(
  ProducerOrdersNotifier.new,
);

class ProducerOrdersNotifier extends Notifier<ProducerOrdersState> {
  @override
  ProducerOrdersState build() {
    ref.listen(sessionControllerProvider, (previous, next) {
      if (next.isAuthenticated &&
          previous?.isAuthenticated != true &&
          next.isLoaded) {
        Future.microtask(refresh);
      }
    });
    Future.microtask(refresh);
    return ProducerOrdersState.initial;
  }

  OrdersRepository get _repo {
    final repo = ref.read(ordersRepositoryProvider);
    if (repo == null) {
      throw const OrderFailure('Sunucu bağlantısı kurulamadı.');
    }
    return repo;
  }

  Future<void> refresh() async {
    final repo = ref.read(ordersRepositoryProvider);
    if (repo == null) {
      state = const ProducerOrdersState(
        items: [],
        isLoading: false,
        error: 'Sunucu bağlantısı kurulamadı.',
      );
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final items = await repo.fetchProducerOrders();
      state = ProducerOrdersState(items: items, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e is OrderFailure ? e.message : e.toString(),
      );
    }
  }

  ProducerOrder? orderByCode(String code) {
    for (final o in state.items) {
      if (o.code == code) return o;
    }
    return null;
  }

  Future<void> approve(String producerOrderNo) async {
    await _updateStatus(
      producerOrderNo: producerOrderNo,
      status: 'approved',
    );
  }

  Future<void> startProduction(String producerOrderNo) async {
    await _updateStatus(
      producerOrderNo: producerOrderNo,
      status: 'in_production',
      productionStage: 'cutting',
    );
  }

  Future<void> markShipped(String producerOrderNo) async {
    final order = orderByCode(producerOrderNo);
    if (order != null && order.buyerOrderNo.isNotEmpty) {
      await ref.read(requestThreadsProvider.notifier).refresh();
      final thread = ref
          .read(requestThreadsProvider.notifier)
          .threadByOrderNo(order.buyerOrderNo);
      if (thread != null && thread.hasOpenUpdateWorkflow) {
        throw const OrderFailure(
          'Bu siparişte kapanmamış güncelleme talebi var. '
          'Önce talebi onaylayın veya alıcı ile süreci tamamlayın.',
        );
      }
    }

    await _repo.updateOrderStatus(
      producerOrderNo: producerOrderNo,
      status: 'shipped',
    );
    await refresh();
    await ref.read(trackedOrdersProvider.notifier).refresh();
  }

  Future<void> updateProductionStage(
    String producerOrderNo,
    String stageUi,
  ) async {
    await _repo.updateProductionStage(
      producerOrderNo: producerOrderNo,
      stageUi: stageUi,
    );
    await refresh();
    await ref.read(trackedOrdersProvider.notifier).refresh();
  }

  Future<void> _updateStatus({
    required String producerOrderNo,
    required String status,
    String? productionStage,
  }) async {
    await _repo.updateOrderStatus(
      producerOrderNo: producerOrderNo,
      status: status,
      productionStage: productionStage,
    );
    await refresh();
    await ref.read(trackedOrdersProvider.notifier).refresh();
  }
}

extension _ProducerOrdersStateX on ProducerOrdersState {
  ProducerOrdersState copyWith({
    List<ProducerOrder>? items,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return ProducerOrdersState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}
