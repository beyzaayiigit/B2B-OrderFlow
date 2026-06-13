/// DB `order_status` ↔ uygulama anahtarları (`StatusBadge.order`).
class OrderStatusMapper {
  OrderStatusMapper._();

  static String locationLabelFor(String status) {
    return switch (status) {
      'submitted' => 'Üretici — Onay bekliyor',
      'approved' => 'Üretici — Onaylandı',
      'in_production' => 'Üretimde',
      'shipped' => 'Sevk edildi',
      _ => 'Üretici',
    };
  }

  /// Zaman çizelgesi başlığı.
  static String timelineTitle(String status) {
    return switch (status) {
      'submitted' => 'Sipariş gönderildi',
      'approved' => 'Üretici onayladı',
      'in_production' => 'Üretime alındı',
      'shipped' => 'Sevk edildi',
      _ => 'Durum güncellendi',
    };
  }

  static const statusFlow = [
    'submitted',
    'approved',
    'in_production',
    'shipped',
  ];
}
