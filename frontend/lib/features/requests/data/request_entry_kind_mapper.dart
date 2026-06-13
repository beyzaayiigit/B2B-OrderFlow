import '../domain/request_thread.dart';

class RequestEntryKindMapper {
  RequestEntryKindMapper._();

  static RequestEntryKind fromDb(String? value) {
    return switch (value) {
      'buyer_request' => RequestEntryKind.buyerRequest,
      'producer_approval' => RequestEntryKind.producerApproval,
      'producer_feedback' => RequestEntryKind.producerFeedback,
      _ => RequestEntryKind.buyerRequest,
    };
  }

  static String toDb(RequestEntryKind kind) {
    return switch (kind) {
      RequestEntryKind.buyerRequest => 'buyer_request',
      RequestEntryKind.producerApproval => 'producer_approval',
      RequestEntryKind.producerFeedback => 'producer_feedback',
    };
  }
}
