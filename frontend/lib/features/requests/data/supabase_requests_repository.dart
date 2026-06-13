import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_bootstrap.dart';
import '../../../shared/supabase_instant.dart';
import '../domain/request_thread.dart';
import 'request_entry_kind_mapper.dart';
import 'requests_repository.dart';

class SupabaseRequestsRepository implements RequestsRepository {
  SupabaseClient get _client => SupabaseBootstrap.client;

  static const _threadSelect = '''
id,
order_id,
updated_at,
orders!inner (
  buyer_order_no,
  status,
  catalog_models (code, name)
),
order_update_entries (
  id,
  kind,
  text,
  author_id,
  created_at
)
''';

  Future<Map<String, dynamic>> _profileRow() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw const RequestFailure('Oturum bulunamadı.');
    final row = await _client
        .from('profiles')
        .select('company_id, role')
        .eq('id', uid)
        .maybeSingle();
    if (row == null) throw const RequestFailure('Profil bulunamadı.');
    return row;
  }

  @override
  Future<List<RequestThread>> fetchThreads() async {
    try {
      final rows = await _client
          .from('order_update_threads')
          .select(_threadSelect)
          .order('updated_at', ascending: false);

      return (rows as List<dynamic>)
          .map((r) => _mapThread(r as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw RequestFailure(e.message);
    } catch (e) {
      if (e is RequestFailure) rethrow;
      throw RequestFailure('Talepler yüklenemedi: $e');
    }
  }

  @override
  Future<String> ensureThread({
    required String buyerOrderNo,
    required String productLabel,
    required String orderStatusKey,
  }) async {
    try {
      final profile = await _profileRow();
      if (profile['role'] != 'buyer') {
        throw const RequestFailure('Yalnızca alıcı talep başlatabilir.');
      }

      final order = await _client
          .from('orders')
          .select('id, status')
          .eq('buyer_order_no', buyerOrderNo.trim())
          .maybeSingle();
      if (order == null) {
        throw RequestFailure('Sipariş bulunamadı: $buyerOrderNo');
      }
      if ((order['status'] as String?) == 'shipped') {
        throw const RequestFailure(
          'Sevk edilen siparişler için güncelleme talebi açılamaz.',
        );
      }
      final orderId = order['id'] as String;

      final existing = await _client
          .from('order_update_threads')
          .select('id')
          .eq('order_id', orderId)
          .maybeSingle();
      if (existing != null) return existing['id'] as String;

      final inserted = await _client
          .from('order_update_threads')
          .insert({'order_id': orderId})
          .select('id')
          .single();
      return inserted['id'] as String;
    } on PostgrestException catch (e) {
      throw RequestFailure(e.message);
    } catch (e) {
      if (e is RequestFailure) rethrow;
      throw RequestFailure('Talep oluşturulamadı: $e');
    }
  }

  @override
  Future<void> addBuyerRequest(String threadId, String body) async {
    await _assertOrderNotShippedForThread(threadId);
    await _insertEntry(
      threadId: threadId,
      kind: 'buyer_request',
      text: body.trim(),
      roleCheck: 'buyer',
    );
  }

  @override
  Future<void> producerApprove(String threadId, {String? note}) async {
    final cleaned = note?.trim();
    await _insertEntry(
      threadId: threadId,
      kind: 'producer_approval',
      text: cleaned != null && cleaned.isNotEmpty ? cleaned : null,
      roleCheck: 'producer',
    );
  }

  @override
  Future<void> producerGeriBildirim(String threadId, String body) async {
    await _insertEntry(
      threadId: threadId,
      kind: 'producer_feedback',
      text: body.trim(),
      roleCheck: 'producer',
    );
  }

  Future<void> _assertOrderNotShippedForThread(String threadId) async {
    final row = await _client
        .from('order_update_threads')
        .select('orders!inner (status)')
        .eq('id', threadId)
        .maybeSingle();
    if (row == null) {
      throw const RequestFailure('Talep kaydı bulunamadı.');
    }
    final order = row['orders'] as Map<String, dynamic>?;
    if ((order?['status'] as String?) == 'shipped') {
      throw const RequestFailure(
        'Sevk edilen siparişler için güncelleme talebi gönderilemez.',
      );
    }
  }

  Future<void> _insertEntry({
    required String threadId,
    required String kind,
    required String? text,
    required String roleCheck,
  }) async {
    try {
      final profile = await _profileRow();
      if (profile['role'] != roleCheck) {
        throw RequestFailure(
          roleCheck == 'buyer'
              ? 'Yalnızca alıcı talep ekleyebilir.'
              : 'Yalnızca üretici yanıt verebilir.',
        );
      }
      final uid = _client.auth.currentUser!.id;
      if (text != null && text.isEmpty && kind != 'producer_approval') {
        throw const RequestFailure('Mesaj boş olamaz.');
      }

      await _client.from('order_update_entries').insert({
        'thread_id': threadId,
        'kind': kind,
        'text': text,
        'author_id': uid,
      });
    } on PostgrestException catch (e) {
      throw RequestFailure(e.message);
    } catch (e) {
      if (e is RequestFailure) rethrow;
      throw RequestFailure('Kayıt başarısız: $e');
    }
  }

  RequestThread _mapThread(Map<String, dynamic> map) {
    final order = map['orders'] as Map<String, dynamic>?;
    final buyerOrderNo = order?['buyer_order_no'] as String? ?? '';
    final status = order?['status'] as String? ?? 'submitted';

    final model = order?['catalog_models'];
    var productLabel = buyerOrderNo;
    var productCode = '';
    if (model is Map<String, dynamic>) {
      final code = model['code'] as String? ?? '';
      final name = model['name'] as String? ?? '';
      if (code.isNotEmpty) {
        productCode = code;
        productLabel = name.isNotEmpty ? '$code · $name' : code;
      }
    }

    final entriesRaw = map['order_update_entries'];
    final entries = <RequestEntry>[];
    if (entriesRaw is List) {
      for (final row in entriesRaw) {
        entries.add(_mapEntry(row as Map<String, dynamic>));
      }
    }

    final thread = RequestThread(
      id: map['id'] as String,
      orderNo: buyerOrderNo,
      productLabel: productLabel,
      productCode: productCode,
      orderStatusKey: status,
      entries: entries,
      unreadForProducer: false,
      unreadForBuyer: false,
    );

    return thread.copyWith(
      unreadForProducer: _unreadForProducer(thread),
      unreadForBuyer: _unreadForBuyer(thread),
    );
  }

  RequestEntry _mapEntry(Map<String, dynamic> map) {
    return RequestEntry(
      id: map['id'] as String,
      createdAt: parseSupabaseInstant(map['created_at'] as String),
      kind: RequestEntryKindMapper.fromDb(map['kind'] as String?),
      text: map['text'] as String?,
    );
  }

  bool _unreadForProducer(RequestThread thread) {
    final sorted = thread.sortedEntries;
    if (sorted.isEmpty) return false;
    return sorted.last.kind == RequestEntryKind.buyerRequest;
  }

  bool _unreadForBuyer(RequestThread thread) {
    final sorted = thread.sortedEntries;
    if (sorted.isEmpty) return false;
    final last = sorted.last.kind;
    return last == RequestEntryKind.producerApproval ||
        last == RequestEntryKind.producerFeedback;
  }
}
