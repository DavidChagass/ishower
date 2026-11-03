import '../models/order_model.dart';

class OrderService {
  static final OrderService _instance = OrderService._internal();

  factory OrderService() {
    return _instance;
  }

  OrderService._internal();

  final List<OrderModel> _orders = [];

  List<OrderModel> get orders => List.unmodifiable(_orders);

  void addOrder(OrderModel order) {
    _orders.insert(0, order);
  }

  /// Valida um pedido pelo código de texto ou QRCode gerado e marca como utilizado.
  /// Retorna o pedido se for válido, ou null se não for encontrado ou já usado.
  OrderModel? validateOrder(String code) {
    try {
      final order = _orders.firstWhere((o) => o.textCode == code || o.qrCodeData == code);
      if (order.status == 'ativo') {
        order.status = 'usado';
        return order;
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
