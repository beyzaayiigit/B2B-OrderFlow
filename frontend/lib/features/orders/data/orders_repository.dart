import '../../catalog/domain/product_model.dart';
import '../../producer/domain/producer_order.dart';
import '../domain/order_status_event.dart';
import '../domain/tracked_order.dart';

class OrderFailure implements Exception {
  const OrderFailure(this.message);
  final String message;
  @override
  String toString() => message;
}

class CreateOrderInput {
  const CreateOrderInput({
    required this.model,
    required this.dueAt,
    required this.lines,
    this.buyerNote,
  });

  final ProductModel model;
  final DateTime dueAt;
  final List<TrackedOrderLine> lines;
  final String? buyerNote;
}

class CreatedOrderResult {
  const CreatedOrderResult({
    required this.tracked,
    required this.producer,
  });

  final TrackedOrder tracked;
  final ProducerOrder producer;
}

abstract class OrdersRepository {
  Future<List<TrackedOrder>> fetchBuyerOrders();

  Future<List<ProducerOrder>> fetchProducerOrders();

  Future<CreatedOrderResult> createOrder(CreateOrderInput input);

  Future<String> allocateOrderCode();

  Future<void> updateOrderStatus({
    required String producerOrderNo,
    required String status,
    String? productionStage,
    String? locationLabel,
  });

  Future<void> updateProductionStage({
    required String producerOrderNo,
    required String stageUi,
  });

  Future<List<OrderStatusEvent>> fetchStatusEvents({
    required String buyerOrderNo,
    String? orderId,
  });
}
