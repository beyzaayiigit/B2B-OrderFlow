import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/buyer_order_note_limits.dart';

/// Alıcı sipariş notları (bellek içi önbellek; asıl kayıt Supabase sipariş alanında).
final buyerOrderNotesProvider =
    NotifierProvider<BuyerOrderNotesNotifier, Map<String, String>>(
  BuyerOrderNotesNotifier.new,
);

class BuyerOrderNotesNotifier extends Notifier<Map<String, String>> {
  @override
  Map<String, String> build() => {};

  /// Sipariş kodu (`SPRS-…`) için kayıtlı not (boşsa `null`).
  String? noteForProducerOrder(String producerOrderCode) {
    final v = state[producerOrderCode];
    if (v == null) return null;
    final t = v.trim();
    return t.isEmpty ? null : t;
  }

  /// Sipariş kodu (`SPRS-…`) ile eşlenen notu yazar / siler.
  void upsertForTrackedOrder({
    required String trackedOrderNo,
    String? producerOrderCode,
    required String rawText,
  }) {
    final trimmed = normalizeBuyerOrderNote(rawText) ?? '';
    final next = Map<String, String>.from(state);
    void removeBoth() {
      next.remove(trackedOrderNo);
      final code = producerOrderCode?.trim();
      if (code != null && code.isNotEmpty) next.remove(code);
    }

    if (trimmed.isEmpty) {
      removeBoth();
    } else {
      next[trackedOrderNo] = trimmed;
      final code = producerOrderCode?.trim();
      if (code != null && code.isNotEmpty) {
        next[code] = trimmed;
      }
    }
    state = next;
  }
}
