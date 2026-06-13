import '../../catalog/domain/product_model.dart';
import '../../orders/domain/tracked_order.dart';

/// Üretici tarafında bir siparişi anlamak için gerekli minimum bilgi seti.
class ProducerOrder {
  const ProducerOrder({
    required this.code,
    this.buyerOrderNo = '',
    required this.product,
    required this.buyerCompany,
    this.orderedByName,
    required this.status,
    required this.colorBreakdown,
    required this.orderedAt,
    required this.dueAt,
    required this.dueDate,
    this.colorSizeRatios = const {},
    this.productionStage,
    this.buyerNote,
  });

  final String code;

  /// Alıcı sipariş no (SPRS-…); güncelleme talebi eşlemesi için.
  final String buyerOrderNo;

  final ProductModel product;
  final String buyerCompany;

  /// Siparişi oluşturan alıcı kullanıcının adı (Excel'de "Sipariş Veren").
  final String? orderedByName;

  final String status;

  /// Renk → toplam adet.
  final Map<String, int> colorBreakdown;

  /// Renk → (beden → oran). Excel export'ta gerçek oranları göstermek için.
  final Map<String, Map<String, int>> colorSizeRatios;

  /// Siparişin verildiği an (Excel'deki tarih alanı; teslim değil).
  final DateTime orderedAt;
  /// Teslim sıralama / filtre (API'den gelir).
  final DateTime dueAt;
  /// Ekranda gösterilen teslim metni (sunucu / yerelleştirme çıktısı).
  final String dueDate;
  final String? productionStage;
  final String? buyerNote;

  int get totalQuantity =>
      colorBreakdown.values.fold(0, (sum, value) => sum + value);

  int get totalColors => colorBreakdown.length;

  String get summaryLine => '$totalColors renk · $totalQuantity adet';

  String get colorListLine => colorBreakdown.entries
      .map((entry) => '${entry.key} ${entry.value}')
      .join(' · ');

  /// Alıcı tarafındaki `TrackedOrder` verisinden Excel export için dönüşüm.
  factory ProducerOrder.fromTrackedOrder(
    TrackedOrder tracked, {
    required ProductModel product,
    String buyerCompany = 'Alıcı',
    String? orderedByName,
  }) {
    final breakdown = <String, int>{};
    final ratios = <String, Map<String, int>>{};
    for (final line in tracked.lines) {
      breakdown[line.colorName] = line.totalQty;
      ratios[line.colorName] = line.sizeRatios;
    }
    return ProducerOrder(
      code: tracked.producerOrderCode ?? tracked.orderNo,
      buyerOrderNo: tracked.orderNo,
      product: product,
      buyerCompany: buyerCompany,
      orderedByName: orderedByName ?? tracked.orderedByName,
      status: tracked.status,
      colorBreakdown: breakdown,
      colorSizeRatios: ratios,
      orderedAt: tracked.createdAt,
      dueAt: tracked.dueAt,
      dueDate: tracked.dueAtLabel,
      buyerNote: tracked.buyerNote,
    );
  }
}

