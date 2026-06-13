/// Sipariş durum geçmişi satırı (`order_status_events` veya mock).
class OrderStatusEvent {
  const OrderStatusEvent({
    required this.status,
    required this.at,
    this.note,
    this.isLatest = false,
  });

  /// `StatusBadge.order` anahtarı: submitted, approved, …
  final String status;
  final DateTime at;
  final String? note;
  final bool isLatest;
}
