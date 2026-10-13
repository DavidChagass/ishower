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
}
