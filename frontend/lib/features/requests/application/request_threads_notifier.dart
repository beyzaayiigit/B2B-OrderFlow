import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/session_controller.dart';
import '../data/requests_repository.dart';
import '../domain/request_thread.dart';
import 'requests_repository_provider.dart';

class RequestThreadsState {
  const RequestThreadsState({
    required this.items,
    required this.isLoading,
    this.error,
  });

  final List<RequestThread> items;
  final bool isLoading;
  final String? error;

  static const initial = RequestThreadsState(items: [], isLoading: true);
}

final requestThreadsProvider =
    NotifierProvider<RequestThreadsNotifier, RequestThreadsState>(
  RequestThreadsNotifier.new,
);

class RequestThreadsNotifier extends Notifier<RequestThreadsState> {
  final Set<String> _producerRead = {};
  final Set<String> _buyerRead = {};

  @override
  RequestThreadsState build() {
    ref.listen(sessionControllerProvider, (previous, next) {
      if (next.isAuthenticated &&
          previous?.isAuthenticated != true &&
          next.isLoaded) {
        Future.microtask(refresh);
      }
    });
    Future.microtask(refresh);
    return RequestThreadsState.initial;
  }

  RequestsRepository get _repo {
    final repo = ref.read(requestsRepositoryProvider);
    if (repo == null) {
      throw const RequestFailure('Sunucu bağlantısı kurulamadı.');
    }
    return repo;
  }

  Future<void> refresh() async {
    final repo = ref.read(requestsRepositoryProvider);
    if (repo == null) {
      state = const RequestThreadsState(
        items: [],
        isLoading: false,
        error: 'Sunucu bağlantısı kurulamadı.',
      );
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final items = await repo.fetchThreads();
      state = RequestThreadsState(
        items: _applyReadFlags(items),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e is RequestFailure ? e.message : e.toString(),
      );
    }
  }

  List<RequestThread> _applyReadFlags(List<RequestThread> items) {
    return [
      for (final t in items)
        t.copyWith(
          unreadForProducer: t.unreadForProducer && !_producerRead.contains(t.id),
          unreadForBuyer: t.unreadForBuyer && !_buyerRead.contains(t.id),
        ),
    ];
  }

  RequestThread? threadById(String threadId) {
    for (final t in state.items) {
      if (t.id == threadId) return t;
    }
    return null;
  }

  RequestThread? threadByOrderNo(String orderNo) {
    for (final t in state.items) {
      if (t.orderNo == orderNo) return t;
    }
    return null;
  }

  String? threadIdForOrder(String orderNo) {
    for (final t in state.items) {
      if (t.orderNo == orderNo) return t.id;
    }
    return null;
  }

  Future<String> ensureThreadForOrder({
    required String orderNo,
    required String productLabel,
    required String orderStatusKey,
  }) async {
    if (orderStatusKey == 'shipped') {
      throw const RequestFailure(
        'Sevk edilen siparişler için güncelleme talebi açılamaz.',
      );
    }
    final existing = threadIdForOrder(orderNo);
    if (existing != null) return existing;

    final id = await _repo.ensureThread(
      buyerOrderNo: orderNo,
      productLabel: productLabel,
      orderStatusKey: orderStatusKey,
    );
    await refresh();
    return id;
  }

  Future<void> addBuyerRequest(String threadId, String body) async {
    final trimmed = body.trim();
    if (trimmed.isEmpty) return;

    final thread = threadById(threadId);
    if (thread != null && thread.isOrderShipped) {
      throw const RequestFailure(
        'Sevk edilen siparişler için güncelleme talebi gönderilemez.',
      );
    }

    await _repo.addBuyerRequest(threadId, trimmed);
    await refresh();
  }

  Future<void> producerApprove(String threadId, {String? note}) async {
    await _repo.producerApprove(threadId, note: note);
    await refresh();
  }

  Future<void> producerGeriBildirim(String threadId, String body) async {
    final trimmed = body.trim();
    if (trimmed.isEmpty) return;

    await _repo.producerGeriBildirim(threadId, trimmed);
    await refresh();
  }

  void markProducerRead(String threadId) {
    _producerRead.add(threadId);
    state = state.copyWith(
      items: [
        for (final t in state.items)
          if (t.id == threadId)
            t.copyWith(unreadForProducer: false)
          else
            t,
      ],
    );
  }

  void markBuyerRead(String threadId) {
    _buyerRead.add(threadId);
    state = state.copyWith(
      items: [
        for (final t in state.items)
          if (t.id == threadId)
            t.copyWith(unreadForBuyer: false)
          else
            t,
      ],
    );
  }
}

/// Üretici AppBar rozeti: okunmamış alıcı güncelleme talebi sayısı.
final producerRequestUnreadCountProvider = Provider<int>((ref) {
  return ref
      .watch(requestThreadsProvider)
      .items
      .where((t) => t.unreadForProducer)
      .length;
});

/// Alıcı AppBar rozeti: okunmamış üretici yanıtı / güncelleme sayısı.
final buyerRequestUnreadCountProvider = Provider<int>((ref) {
  return ref
      .watch(requestThreadsProvider)
      .items
      .where((t) => t.unreadForBuyer)
      .length;
});

extension _RequestThreadsStateX on RequestThreadsState {
  RequestThreadsState copyWith({
    List<RequestThread>? items,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return RequestThreadsState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}
