/// Zaman çizgisi satır türü: alıcı talebi ve üretici yanıtı (onay / geri bildirim).
enum RequestEntryKind {
  /// Alıcının siparişe ilişkin metin talebi
  buyerRequest,
  /// Üretici: talebi kabul / onay (mesaj zorunlu değil)
  producerApproval,
  /// Üretici: metinli geri bildirim
  producerFeedback,
}

class RequestEntry {
  const RequestEntry({
    required this.id,
    required this.createdAt,
    required this.kind,
    this.text,
  });

  final String id;
  final DateTime createdAt;
  final RequestEntryKind kind;
  /// `buyerRequest` ve `producerFeedback` için dolu; `producerApproval` isteğe bağlı açıklama.
  final String? text;
}

class RequestThread {
  const RequestThread({
    required this.id,
    required this.orderNo,
    required this.productLabel,
    this.productCode = '',
    required this.orderStatusKey,
    required this.entries,
    required this.unreadForProducer,
    required this.unreadForBuyer,
  });

  final String id;
  final String orderNo;
  final String productLabel;
  /// Katalog eşlemesi için model kodu (`MD-…`).
  final String productCode;
  final String orderStatusKey;
  final List<RequestEntry> entries;
  /// Üreticinin okumadığı yeni alıcı talebi
  final bool unreadForProducer;
  /// Alıcının okumadığı yeni üretici yanıtı (onay veya geri bildirim)
  final bool unreadForBuyer;

  /// Kronolojik sıra (tarih).
  List<RequestEntry> get sortedEntries {
    final list = List<RequestEntry>.from(entries);
    list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return list;
  }

  /// Son kayıt alıcı talebi → üretici henüz onay/geri bildirim vermedi.
  bool get hasPendingBuyerRequest =>
      sortedEntries.isNotEmpty &&
      sortedEntries.last.kind == RequestEntryKind.buyerRequest;

  bool get lastIsProducerFeedback =>
      sortedEntries.isNotEmpty &&
      sortedEntries.last.kind == RequestEntryKind.producerFeedback;

  bool get isOrderShipped => orderStatusKey == 'shipped';

  /// Üretici onayı ile kapanmadıkça sevk yapılamaz (bekleyen talep veya geri bildirim).
  bool get hasOpenUpdateWorkflow {
    final sorted = sortedEntries;
    if (sorted.isEmpty) return false;
    final last = sorted.last.kind;
    return last == RequestEntryKind.buyerRequest ||
        last == RequestEntryKind.producerFeedback;
  }

  String get lastPreview {
    if (entries.isEmpty) return 'Henüz güncelleme talebi yok';
    final e = sortedEntries.last;
    switch (e.kind) {
      case RequestEntryKind.buyerRequest:
        final t = (e.text ?? '').trim();
        if (t.isEmpty) return 'Talep';
        return t.length <= 72 ? t : '${t.substring(0, 69)}…';
      case RequestEntryKind.producerApproval:
        if ((e.text ?? '').trim().isNotEmpty) {
          final t = e.text!.trim();
          return 'Üretici: Onay — ${t.length <= 40 ? t : '${t.substring(0, 37)}…'}';
        }
        return 'Üretici: Talep onaylandı';
      case RequestEntryKind.producerFeedback:
        final t = (e.text ?? '').trim();
        if (t.isEmpty) return 'Üretici: Geri bildirim';
        return 'Üretici: ${t.length <= 56 ? t : '${t.substring(0, 53)}…'}';
    }
  }

  DateTime? get lastActivityAt =>
      entries.isEmpty ? null : entries.map((e) => e.createdAt).reduce(
            (a, b) => a.isAfter(b) ? a : b,
          );

  RequestThread copyWith({
    String? id,
    String? orderNo,
    String? productLabel,
    String? productCode,
    String? orderStatusKey,
    List<RequestEntry>? entries,
    bool? unreadForProducer,
    bool? unreadForBuyer,
  }) {
    return RequestThread(
      id: id ?? this.id,
      orderNo: orderNo ?? this.orderNo,
      productLabel: productLabel ?? this.productLabel,
      productCode: productCode ?? this.productCode,
      orderStatusKey: orderStatusKey ?? this.orderStatusKey,
      entries: entries ?? this.entries,
      unreadForProducer: unreadForProducer ?? this.unreadForProducer,
      unreadForBuyer: unreadForBuyer ?? this.unreadForBuyer,
    );
  }
}
