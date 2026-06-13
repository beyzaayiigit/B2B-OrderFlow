import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/order_status_event.dart';
import '../domain/tracked_order.dart';
import 'orders_repository_provider.dart';

final orderStatusTimelineProvider = FutureProvider.autoDispose
    .family<List<OrderStatusEvent>, TrackedOrder>((ref, order) async {
  final repo = ref.watch(ordersRepositoryProvider);
  if (repo == null) {
    return [];
  }
  return repo.fetchStatusEvents(
    buyerOrderNo: order.orderNo,
    orderId: order.id,
  );
});
