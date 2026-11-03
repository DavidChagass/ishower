import '../models/order_model.dart';
import '../../stations/models/station_model.dart';

class OrderService {
  static final OrderService _instance = OrderService._internal();

  factory OrderService() {
    return _instance;
  }

  OrderService._internal() {
    // Adiciona uma reserva de exemplo inicial para demonstração imediata do QR Code
    _orders.add(
      OrderModel(
        id: '1001',
        station: Station(
          id: '1',
          name: 'Posto Graal - BR 381',
          address: 'Rodovia Fernão Dias, Km 45 - Betim/MG',
          distance: 2.5,
          price: 15.00,
          isAvailable: true,
          lat: -19.9554,
          lng: -44.0445,
          operatingHours: '24 Horas',
        ),
        qrCodeData: 'ISHOWER-GRAAL-749281',
        textCode: '749281',
        date: DateTime.now(),
        totalPrice: 15.00,
        extras: const ['Toalha'],
        scheduledTime: 'Hoje às 14:30',
        status: 'ativo',
      ),
    );
  }

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
