import '../domain/tracked_order.dart';

/// [TrackedOrdersNotifier] her güncellediğinde doldurulur; eski `trackedOrderByCode` çağrıları için.
List<TrackedOrder> _snapshot = [];

void syncTrackedOrdersLookup(List<TrackedOrder> orders) {
  _snapshot = List<TrackedOrder>.from(orders);
}

TrackedOrder? trackedOrderByCode(String orderNo) {
  for (final o in _snapshot) {
    if (o.orderNo == orderNo) return o;
    final lp = o.producerOrderCode;
    if (lp != null && lp == orderNo) return o;
  }
  return null;
}
