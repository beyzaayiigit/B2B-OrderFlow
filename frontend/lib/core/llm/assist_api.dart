import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../config/app_env.dart';

/// LLM asistan servisinden dönen kullanıcıya gösterilebilir hata.
class AssistException implements Exception {
  AssistException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// TextileFlow FastAPI asistanına (Gemini) ince istemci.
/// Anahtar/servis yoksa [available] false olur ve UI butonları gizlenir.
class AssistApi {
  const AssistApi();

  bool get available => AppEnv.assistConfigured;

  /// Dağınık sipariş notunu üretici-dostu nota çevirir.
  Future<String> orderNote(String text) =>
      _post('/assist/order-note', {'text': text});

  /// Ham güncelleme talebini net bir talep metnine çevirir.
  Future<String> updateRequest(String text, {String? orderCode}) => _post(
        '/assist/update-request',
        {
          'text': text,
          if (orderCode != null && orderCode.trim().isNotEmpty)
            'order_code': orderCode.trim(),
        },
      );

  Future<String> _post(String path, Map<String, dynamic> body) async {
    final base = AppEnv.apiBaseUrl;
    if (base == null) {
      throw AssistException('Asistan servisi yapılandırılmamış.');
    }
    http.Response resp;
    try {
      resp = await http
          .post(
            Uri.parse('$base$path'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));
    } catch (_) {
      throw AssistException('Asistana ulaşılamadı. Servis çalışıyor mu?');
    }

    if (resp.statusCode == 200) {
      final data =
          jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
      final result = (data['result'] as String?)?.trim() ?? '';
      if (result.isEmpty) throw AssistException('Boş yanıt alındı.');
      return result;
    }
    if (resp.statusCode == 503) {
      throw AssistException('Asistan şu an kapalı (API anahtarı tanımlı değil).');
    }
    throw AssistException('Asistan hatası (HTTP ${resp.statusCode}).');
  }
}

final assistApiProvider = Provider<AssistApi>((ref) => const AssistApi());
