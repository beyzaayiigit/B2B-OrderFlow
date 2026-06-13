import '../domain/request_thread.dart';

class RequestFailure implements Exception {
  const RequestFailure(this.message);
  final String message;
  @override
  String toString() => message;
}

abstract class RequestsRepository {
  Future<List<RequestThread>> fetchThreads();

  Future<String> ensureThread({
    required String buyerOrderNo,
    required String productLabel,
    required String orderStatusKey,
  });

  Future<void> addBuyerRequest(String threadId, String body);

  Future<void> producerApprove(String threadId, {String? note});

  Future<void> producerGeriBildirim(String threadId, String body);
}
