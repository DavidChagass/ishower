import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../models/order_model.dart';
import '../../stations/models/station_model.dart';
import '../../stations/services/api_service.dart';

class OrderService {
  static final OrderService _instance = OrderService._internal();

  factory OrderService() {
    return _instance;
  }

  static const String testOrderId = '44444444-4444-4444-8444-444444444444';
  static const String testOrderCode = '749281';
  static const String testOrderQrPayload =
      'ISHOWER:V1:44444444-4444-4444-8444-444444444444:749281';

  OrderService._internal() {
    _orders.add(_createSingleTestOrder());
  }

  final List<OrderModel> _orders = [];

  /// Quando ativo, mantém um único pedido e um único QR Code padronizado por aplicativo,
  /// permitindo que múltiplos dispositivos leiam o mesmo QR Code de forma independente.
  bool _isTestMockMode = true;

  bool get isTestMockMode => _isTestMockMode;

  static OrderModel _createSingleTestOrder() {
    return OrderModel(
      id: testOrderId,
      station: Station(
        id: '11111111-1111-4111-8111-111111111111',
        name: 'Posto Graal - BR 381',
        address: 'Rodovia Fernão Dias, Km 45 - Betim/MG',
        distance: 2.5,
        price: 15.00,
        isAvailable: true,
        lat: -19.9554,
        lng: -44.0445,
        operatingHours: '24 Horas',
      ),
      qrCodeData: testOrderQrPayload,
      textCode: testOrderCode,
      date: DateTime.now(),
      totalPrice: 22.00,
      extras: const ['Toalha', 'Sabonete'],
      scheduledTime: 'Hoje às 14:30',
      status: 'ativo',
    );
  }

  /// Ativa ou desativa o Modo de Teste (Pedido e QR Code Únicos) na seção do Administrador.
  /// Ao ativar (ou resetar), garante exatamente 1 único pedido válido ('749281') na aba de clientes.
  void setTestMockMode(bool enabled) {
    _isTestMockMode = enabled;
    if (enabled) {
      resetSingleTestOrder();
    }
  }

  /// Restaura o pedido único de teste para o estado 'ativo' neste aplicativo.
  OrderModel resetSingleTestOrder() {
    final singleOrder = _createSingleTestOrder();
    _orders
      ..clear()
      ..add(singleOrder);
    return singleOrder;
  }

  static String extractLookupCode(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '';
    if (trimmed.toUpperCase().startsWith('ISHOWER:')) {
      final parts = trimmed.split(':');
      if (parts.isNotEmpty && parts.last.trim().isNotEmpty) {
        return parts.last.trim();
      }
    }
    return trimmed;
  }

  List<OrderModel> get orders => List.unmodifiable(_orders);

  Future<List<OrderModel>> fetchOrders() async {
    // Em modo de teste (mockup por aplicativo), preserva o pedido único local
    // para que a aba de clientes exiba apenas o único pedido e o único QR Code.
    if (_isTestMockMode) {
      if (_orders.isEmpty) {
        _orders.add(_createSingleTestOrder());
      } else if (_orders.length > 1) {
        final currentTest = _orders.firstWhere(
          (o) => o.textCode == testOrderCode,
          orElse: _createSingleTestOrder,
        );
        _orders
          ..clear()
          ..add(currentTest);
      }
      return orders;
    }

    try {
      final response = await http
          .get(Uri.parse('${ApiService.baseUrl}/vouchers'))
          .timeout(const Duration(seconds: 2));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final fetched = data
            .whereType<Map<String, dynamic>>()
            .map(OrderModel.fromJson)
            .toList();
        _orders
          ..clear()
          ..addAll(fetched);
      }
    } catch (_) {
      // Mantém lista local caso o backend esteja indisponível
    }
    return orders;
  }

  void addOrder(OrderModel order) {
    if (_isTestMockMode) {
      _orders
        ..clear()
        ..add(order);
      return;
    }
    _orders.insert(0, order);
  }

  Future<OrderModel> createOrder({
    required Station station,
    required List<String> extras,
    required double totalPrice,
    required String scheduledTime,
  }) async {
    if (_isTestMockMode) {
      final single = OrderModel(
        id: testOrderId,
        station: station,
        qrCodeData: testOrderQrPayload,
        textCode: testOrderCode,
        date: DateTime.now(),
        totalPrice: totalPrice,
        extras: extras,
        scheduledTime: scheduledTime,
        status: 'ativo',
      );
      _orders
        ..clear()
        ..add(single);
      return single;
    }

    try {
      final response = await http
          .post(
            Uri.parse('${ApiService.baseUrl}/vouchers'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'station_id': station.id,
              'scheduled_time': scheduledTime,
              'extras': extras,
            }),
          )
          .timeout(const Duration(seconds: 3));

      if (response.statusCode == 201 || response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final created = OrderModel.fromJson(data);
        _orders.removeWhere((o) => o.id == created.id);
        _orders.insert(0, created);
        return created;
      }
    } catch (_) {
      // Fallback local caso servidor esteja offline
    }

    final random = Random();
    final code = (100000 + random.nextInt(900000)).toString();
    final fallbackId = DateTime.now().millisecondsSinceEpoch.toString();
    final fallbackOrder = OrderModel(
      id: fallbackId,
      station: station,
      qrCodeData: 'ISHOWER:V1:$fallbackId:$code',
      textCode: code,
      date: DateTime.now(),
      totalPrice: totalPrice,
      extras: extras,
      scheduledTime: scheduledTime,
    );
    addOrder(fallbackOrder);
    return fallbackOrder;
  }

  Future<OrderModel?> validateOrderAsync(String code) async {
    final rawTrimmed = code.trim();
    final cleanCode = extractLookupCode(rawTrimmed);
    if (cleanCode.isEmpty) return null;

    // Quando em Modo de Teste (ou ao ler o QR Code universal de teste '749281'),
    // valida localmente por aplicativo para que dois dispositivos diferentes possam
    // ler o mesmo QR Code de forma independente.
    if (_isTestMockMode || cleanCode == testOrderCode) {
      return validateOrder(rawTrimmed);
    }

    try {
      final response = await http
          .post(
            Uri.parse('${ApiService.baseUrl}/scan/voucher'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'code': rawTrimmed}),
          )
          .timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['voucher'] is Map<String, dynamic>) {
          final validated =
              OrderModel.fromJson(data['voucher'] as Map<String, dynamic>);
          final idx = _orders.indexWhere(
            (o) => o.id == validated.id || o.textCode == validated.textCode,
          );
          if (idx >= 0) {
            _orders[idx] = validated;
          } else {
            _orders.insert(0, validated);
          }
          return validated;
        }
      } else if (response.statusCode == 404 || response.statusCode == 409) {
        await fetchOrders();
        return null;
      }
    } catch (_) {
      // Fallback local caso servidor esteja offline
    }

    return validateOrder(cleanCode);
  }

  OrderModel? validateOrder(String code) {
    final lookup = extractLookupCode(code);
    try {
      final order = _orders.firstWhere(
        (o) =>
            o.textCode == lookup ||
            o.qrCodeData == code ||
            o.qrCodeData == lookup ||
            o.id == lookup,
      );
      if (order.status == 'ativo') {
        order.status = 'usado';
        return order;
      }
      return null;
    } catch (_) {
      // Caso este dispositivo tenha acabado de ler um QR Code ISHOWER:V1:... gerado em outro aparelho
      // e ainda não o tenha na lista local, cria e valida na memória deste aplicativo:
      if (lookup == testOrderCode ||
          code.trim().toUpperCase().startsWith('ISHOWER:V1:')) {
        final externalOrder = _createSingleTestOrder();
        externalOrder.status = 'usado';
        _orders.insert(0, externalOrder);
        return externalOrder;
      }
      return null;
    }
  }
}
