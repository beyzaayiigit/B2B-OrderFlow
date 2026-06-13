import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_bootstrap.dart';
import '../../../shared/order_date_labels.dart';
import '../../../shared/supabase_instant.dart';
import '../../catalog/data/catalog_status_mapper.dart';
import '../../catalog/domain/product_model.dart';
import '../../producer/domain/producer_order.dart';
import '../domain/order_status_event.dart';
import '../domain/buyer_order_note_limits.dart';
import '../domain/tracked_order.dart';
import 'order_status_mapper.dart';
import 'orders_repository.dart';
import 'production_stage_mapper.dart';

class SupabaseOrdersRepository implements OrdersRepository {
  SupabaseClient get _client => SupabaseBootstrap.client;

  static const _orderSelect = '''
id,
buyer_order_no,
producer_order_no,
status,
location_label,
ordered_at,
due_at,
buyer_note,
production_stage,
total_qty,
catalog_models (
  id,
  code,
  name,
  category,
  status,
  catalog_color_variants (id, color_name, image_url, sort_order)
),
order_lines (color_name, size, qty, color_total_qty),
buyer_company:companies!buyer_company_id (name),
ordered_by:profiles!created_by (full_name)
''';

  Future<Map<String, dynamic>> _profileRow() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw const OrderFailure('Oturum bulunamadı.');
    final row = await _client
        .from('profiles')
        .select('company_id, role')
        .eq('id', uid)
        .maybeSingle();
    if (row == null) throw const OrderFailure('Profil bulunamadı.');
    return row;
  }

  @override
  Future<String> allocateOrderCode() async {
    try {
      final result = await _client.rpc('next_order_code');
      final code = (result as String?)?.trim();
      if (code == null || code.isEmpty) {
        throw const OrderFailure('Sipariş numarası üretilemedi.');
      }
      return code;
    } on PostgrestException catch (e) {
      throw OrderFailure(e.message);
    } catch (e) {
      if (e is OrderFailure) rethrow;
      throw OrderFailure('Sipariş numarası üretilemedi: $e');
    }
  }

  @override
  Future<CreatedOrderResult> createOrder(CreateOrderInput input) async {
    try {
      final profile = await _profileRow();
      if (profile['role'] != 'buyer') {
        throw const OrderFailure('Yalnızca alıcı sipariş oluşturabilir.');
      }
      final buyerCompanyId = profile['company_id'] as String;
      final uid = _client.auth.currentUser!.id;

      final modelId = input.model.id;
      if (modelId == null || modelId.isEmpty) {
        throw const OrderFailure(
          'Model kimliği bulunamadı. Kataloğu yenileyip tekrar deneyin.',
        );
      }

      final modelRow = await _client
          .from('catalog_models')
          .select('producer_company_id, code, status')
          .eq('id', modelId)
          .maybeSingle();
      if (modelRow == null) {
        throw const OrderFailure('Seçilen model bulunamadı.');
      }
      if (modelRow['status'] != 'published') {
        throw const OrderFailure('Yalnızca yayında olan modellere sipariş verilebilir.');
      }

      final producerCompanyId = modelRow['producer_company_id'] as String;
      final orderCode = await allocateOrderCode();
      final totalQty = input.lines.fold<int>(
        0,
        (sum, line) => sum + line.lineTotal,
      );
      if (totalQty <= 0) {
        throw const OrderFailure('En az bir adet girin.');
      }

      final due = dateOnly(input.dueAt);
      if (isBuyerOrderNoteTooLong(input.buyerNote)) {
        throw OrderFailure(
          'Sipariş notu en fazla $kBuyerOrderNoteMaxLength karakter olabilir.',
        );
      }
      final note = normalizeBuyerOrderNote(input.buyerNote);

      final inserted = await _client
          .from('orders')
          .insert({
            'buyer_order_no': orderCode,
            'producer_order_no': orderCode,
            'buyer_company_id': buyerCompanyId,
            'producer_company_id': producerCompanyId,
            'model_id': modelId,
            'status': 'submitted',
            'location_label': OrderStatusMapper.locationLabelFor('submitted'),
            'total_qty': totalQty,
            'due_at': _dateIso(due),
            if (note != null && note.isNotEmpty) 'buyer_note': note,
            'created_by': uid,
          })
          .select('id')
          .single();

      final orderId = inserted['id'] as String;
      final lineRows = <Map<String, dynamic>>[];
      for (final line in input.lines) {
        for (final entry in line.sizeRatios.entries) {
          if (entry.value > 0) {
            lineRows.add({
              'order_id': orderId,
              'color_name': line.colorName.trim(),
              'size': entry.key,
              'qty': entry.value,
              'color_total_qty': line.totalQty,
            });
          }
        }
      }
      if (lineRows.isNotEmpty) {
        await _client.from('order_lines').insert(lineRows);
      }

      final rows = await _client
          .from('orders')
          .select(_orderSelect)
          .eq('id', orderId);
      final map = (rows as List<dynamic>).first as Map<String, dynamic>;

      return CreatedOrderResult(
        tracked: _mapTrackedOrder(map),
        producer: _mapProducerOrder(map),
      );
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        throw const OrderFailure('Bu sipariş numarası zaten kullanılıyor.');
      }
      throw OrderFailure(e.message);
    } catch (e) {
      if (e is OrderFailure) rethrow;
      throw OrderFailure('Sipariş kaydedilemedi: $e');
    }
  }

  @override
  Future<List<TrackedOrder>> fetchBuyerOrders() async {
    try {
      final profile = await _profileRow();
      if (profile['role'] != 'buyer') {
        throw const OrderFailure('Yalnızca alıcı sipariş listesi görüntüleyebilir.');
      }
      final rows = await _client
          .from('orders')
          .select(_orderSelect)
          .order('ordered_at', ascending: false);
      return (rows as List<dynamic>)
          .map((r) => _mapTrackedOrder(r as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw OrderFailure(e.message);
    } catch (e) {
      if (e is OrderFailure) rethrow;
      throw OrderFailure('Siparişler yüklenemedi: $e');
    }
  }

  @override
  Future<List<ProducerOrder>> fetchProducerOrders() async {
    try {
      final profile = await _profileRow();
      if (profile['role'] != 'producer') {
        throw const OrderFailure('Yalnızca üretici sipariş listesi görüntüleyebilir.');
      }
      final rows = await _client
          .from('orders')
          .select(_orderSelect)
          .order('ordered_at', ascending: false);
      return (rows as List<dynamic>)
          .map((r) => _mapProducerOrder(r as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw OrderFailure(e.message);
    } catch (e) {
      if (e is OrderFailure) rethrow;
      throw OrderFailure('Siparişler yüklenemedi: $e');
    }
  }

  @override
  Future<void> updateOrderStatus({
    required String producerOrderNo,
    required String status,
    String? productionStage,
    String? locationLabel,
  }) async {
    try {
      final profile = await _profileRow();
      if (profile['role'] != 'producer') {
        throw const OrderFailure('Yalnızca üretici sipariş güncelleyebilir.');
      }
      if (status == 'shipped') {
        await _assertCanMarkShipped(producerOrderNo.trim());
      }
      final patch = <String, dynamic>{
        'status': status,
        'location_label':
            locationLabel ?? OrderStatusMapper.locationLabelFor(status),
      };
      if (productionStage != null) {
        patch['production_stage'] = productionStage;
      } else if (status == 'in_production') {
        patch['production_stage'] = 'cutting';
      } else if (status == 'approved' || status == 'shipped') {
        patch['production_stage'] = null;
      }

      await _client
          .from('orders')
          .update(patch)
          .eq('producer_order_no', producerOrderNo.trim());
    } on PostgrestException catch (e) {
      throw OrderFailure(e.message);
    } catch (e) {
      if (e is OrderFailure) rethrow;
      throw OrderFailure('Güncelleme başarısız: $e');
    }
  }

  Future<void> _assertCanMarkShipped(String producerOrderNo) async {
    final order = await _client
        .from('orders')
        .select('id, status')
        .eq('producer_order_no', producerOrderNo)
        .maybeSingle();
    if (order == null) {
      throw OrderFailure('Sipariş bulunamadı: $producerOrderNo');
    }
    if (order['status'] != 'in_production') {
      throw const OrderFailure(
        'Yalnızca üretimdeki siparişler sevk edilebilir.',
      );
    }
    final orderId = order['id'] as String;
    final thread = await _client
        .from('order_update_threads')
        .select('id')
        .eq('order_id', orderId)
        .maybeSingle();
    if (thread == null) return;

    final entries = await _client
        .from('order_update_entries')
        .select('kind')
        .eq('thread_id', thread['id'] as String)
        .order('created_at', ascending: false)
        .limit(1);
    if (entries.isEmpty) return;

    final kind = entries.first['kind'] as String?;
    if (kind == 'buyer_request' || kind == 'producer_feedback') {
      throw const OrderFailure(
        'Bu siparişte kapanmamış güncelleme talebi var. '
        'Önce talebi onaylayın veya alıcı ile süreci tamamlayın.',
      );
    }
  }

  @override
  Future<void> updateProductionStage({
    required String producerOrderNo,
    required String stageUi,
  }) async {
    final dbStage = ProductionStageMapper.toDb(stageUi);
    if (dbStage == null) {
      throw OrderFailure('Geçersiz üretim aşaması: $stageUi');
    }
    await updateOrderStatus(
      producerOrderNo: producerOrderNo,
      status: 'in_production',
      productionStage: dbStage,
      locationLabel: 'Üretim — $stageUi',
    );
  }

  String? _orderedByNameFromRow(Map<String, dynamic> map) {
    final creator = map['ordered_by'];
    if (creator is Map<String, dynamic>) {
      final name = (creator['full_name'] as String?)?.trim();
      if (name != null && name.isNotEmpty) return name;
    }
    return null;
  }

  TrackedOrder _mapTrackedOrder(Map<String, dynamic> map) {
    final orderedAt = parseSupabaseInstant(map['ordered_at'] as String);
    final dueRaw = map['due_at'];
    final dueAt = dueRaw is String
        ? dateOnly(DateTime.parse(dueRaw))
        : dateOnly(orderedAt);

    return TrackedOrder(
      id: map['id'] as String?,
      orderNo: map['producer_order_no'] as String? ??
          map['buyer_order_no'] as String? ??
          '',
      status: map['status'] as String? ?? 'submitted',
      location: map['location_label'] as String? ??
          OrderStatusMapper.locationLabelFor(
            map['status'] as String? ?? 'submitted',
          ),
      createdAt: orderedAt,
      createdAtLabel: formatOrderDateTimeLabel(orderedAt),
      dueAt: dueAt,
      dueAtLabel: formatOrderDateLong(dueAt),
      productCode: _productFromRow(map['catalog_models']).code,
      lines: _mapLines(map['order_lines']),
      producerOrderCode: map['producer_order_no'] as String?,
      buyerNote: _trimNote(map['buyer_note'] as String?),
      orderedByName: _orderedByNameFromRow(map),
    );
  }

  String? _trimNote(String? raw) {
    final t = raw?.trim();
    if (t == null || t.isEmpty) return null;
    return t;
  }

  ProducerOrder _mapProducerOrder(Map<String, dynamic> map) {
    final orderedAt = parseSupabaseInstant(map['ordered_at'] as String);
    final dueRaw = map['due_at'];
    final dueAt = dueRaw is String
        ? dateOnly(DateTime.parse(dueRaw))
        : dateOnly(orderedAt);

    final buyer = map['buyer_company'];
    String buyerName = 'Alıcı';
    if (buyer is Map<String, dynamic>) {
      buyerName = (buyer['name'] as String?)?.trim() ?? buyerName;
    }

    final dbStage = map['production_stage'] as String?;

    final note = (map['buyer_note'] as String?)?.trim();

    return ProducerOrder(
      code: map['producer_order_no'] as String? ?? '',
      buyerOrderNo: map['buyer_order_no'] as String? ?? '',
      product: _productFromRow(map['catalog_models']),
      buyerCompany: buyerName,
      orderedByName: _orderedByNameFromRow(map),
      status: map['status'] as String? ?? 'submitted',
      colorBreakdown: _colorBreakdown(map['order_lines']),
      colorSizeRatios: _colorSizeRatios(map['order_lines']),
      orderedAt: orderedAt,
      dueAt: dueAt,
      dueDate: formatOrderDateLong(dueAt),
      productionStage: ProductionStageMapper.toUi(dbStage),
      buyerNote: note != null && note.isNotEmpty ? note : null,
    );
  }

  List<TrackedOrderLine> _mapLines(dynamic raw) {
    if (raw is! List) return const [];
    final ratiosByColor = <String, Map<String, int>>{};
    final totalByColor = <String, int>{};
    for (final row in raw) {
      final map = row as Map<String, dynamic>;
      final color = (map['color_name'] as String?)?.trim() ?? '';
      final size = (map['size'] as String?)?.trim() ?? '';
      final qty = map['qty'] as int? ?? 0;
      final colorTotal = map['color_total_qty'] as int? ?? 0;
      if (color.isEmpty || size.isEmpty || qty <= 0) continue;
      ratiosByColor.putIfAbsent(color, () => {})[size] = qty;
      totalByColor[color] = colorTotal;
    }
    return ratiosByColor.entries
        .map(
          (e) => TrackedOrderLine(
            colorName: e.key,
            sizeRatios: e.value,
            totalQty: totalByColor[e.key] ?? 0,
          ),
        )
        .toList();
  }

  Map<String, int> _colorBreakdown(dynamic raw) {
    final lines = _mapLines(raw);
    return {
      for (final line in lines) line.colorName: line.lineTotal,
    };
  }

  Map<String, Map<String, int>> _colorSizeRatios(dynamic raw) {
    final lines = _mapLines(raw);
    return {
      for (final line in lines) line.colorName: line.sizeRatios,
    };
  }

  ProductModel _productFromRow(dynamic raw) {
    if (raw is! Map<String, dynamic>) {
      return const ProductModel(
        code: '?',
        name: 'Model',
        category: '',
        status: 'Yayında',
        colorVariants: [],
      );
    }
    final category = raw['category'] as String? ?? '';
    final variantsRaw = raw['catalog_color_variants'];
    final variants = <ProductColorVariant>[];
    if (variantsRaw is List) {
      for (final v in variantsRaw) {
        final vm = v as Map<String, dynamic>;
        final url = (vm['image_url'] as String?)?.trim() ?? '';
        final colorName = vm['color_name'] as String? ?? '';
        variants.add(
          ProductColorVariant(
            id: vm['id'] as String?,
            colorName: colorName,
            imageAsset: url.isNotEmpty
                ? url
                : catalogPlaceholderAsset(category, colorName),
          ),
        );
      }
      variants.sort(
        (a, b) => (a.colorName).compareTo(b.colorName),
      );
    }

    return ProductModel(
      id: raw['id'] as String?,
      code: raw['code'] as String? ?? '',
      name: raw['name'] as String? ?? '',
      category: raw['category'] as String? ?? '',
      status: CatalogStatusMapper.toUi(raw['status'] as String? ?? 'draft'),
      colorVariants: variants,
    );
  }

  String _dateIso(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  @override
  Future<List<OrderStatusEvent>> fetchStatusEvents({
    required String buyerOrderNo,
    String? orderId,
  }) async {
    try {
      var resolvedId = orderId;
      if (resolvedId == null || resolvedId.isEmpty) {
        final row = await _client
            .from('orders')
            .select('id')
            .eq('buyer_order_no', buyerOrderNo.trim())
            .maybeSingle();
        if (row == null) return [];
        resolvedId = row['id'] as String;
      }

      final rows = await _client
          .from('order_status_events')
          .select('to_status, note, created_at')
          .eq('order_id', resolvedId)
          .order('created_at', ascending: true);

      final events = <OrderStatusEvent>[];
      final list = rows as List<dynamic>;
      for (var i = 0; i < list.length; i++) {
        final map = list[i] as Map<String, dynamic>;
        final status = map['to_status'] as String? ?? 'submitted';
        events.add(
          OrderStatusEvent(
            status: status,
            at: parseSupabaseInstant(map['created_at'] as String),
            note: map['note'] as String?,
            isLatest: i == list.length - 1,
          ),
        );
      }
      return events;
    } on PostgrestException catch (e) {
      throw OrderFailure(e.message);
    } catch (e) {
      if (e is OrderFailure) rethrow;
      throw OrderFailure('Durum geçmişi yüklenemedi: $e');
    }
  }

}
