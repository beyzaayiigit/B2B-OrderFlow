/// Alıcı sipariş takip listesi + detay ekranında kullanılan, backend ile
/// birebir eşlenebilecek sade model.
class TrackedOrderLine {
  const TrackedOrderLine({
    required this.colorName,
    required this.sizeRatios,
    required this.totalQty,
  });

  final String colorName;

  /// Beden → oran (seri poşetindeki dağılım oranı, ör. S:1, M:2, L:2, XL:1, XXL:1).
  final Map<String, int> sizeRatios;

  /// Bu renk için toplam sipariş adedi.
  final int totalQty;

  /// Bir seri poşetindeki toplam parça (oranların toplamı).
  int get ratioSum => sizeRatios.values.fold(0, (s, r) => s + r);

  /// Kaç seri oluşacağı.
  int get seriesCount => ratioSum > 0 ? totalQty ~/ ratioSum : 0;

  /// Renk satırının toplam adedi (toplam adet olarak totalQty kullanılır).
  int get lineTotal => totalQty;

  List<String> get sortedSizes => sizeRatios.keys.toList()..sort();
}

class TrackedOrder {
  const TrackedOrder({
    this.id,
    required this.orderNo,
    required this.status,
    required this.location,
    required this.createdAt,
    required this.createdAtLabel,
    required this.dueAt,
    required this.dueAtLabel,
    required this.productCode,
    required this.lines,
    /// Mock eşleme: aynı iş için üreticiden gelen sipariş kodu (`SPRS-…`).
    this.producerOrderCode,
    this.buyerNote,
    this.orderedByName,
  });

  final String? id;
  final String orderNo;
  /// `StatusBadge.order` ile uyumlu anahtarlar.
  final String status;
  final String location;
  /// Sıralama ve filtreler için; [createdAtLabel] yalnızca gösterim.
  final DateTime createdAt;
  final String createdAtLabel;
  /// Alıcının belirlediği teslim (gün bazında).
  final DateTime dueAt;
  final String dueAtLabel;
  final String productCode;
  final List<TrackedOrderLine> lines;
  final String? producerOrderCode;
  final String? buyerNote;

  /// Siparişi oluşturan alıcı kullanıcının adı.
  final String? orderedByName;

  int get totalQuantity =>
      lines.fold(0, (sum, line) => sum + line.lineTotal);

  int get colorCount => lines.length;
}
