import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../../auth/services/auth_service.dart';
import '../models/order_model.dart';
import '../../stations/models/station_model.dart';
import '../../stations/services/api_service.dart';

class OrderService {
  static final OrderService _instance = OrderService._internal();

  factory OrderService() {
    return _instance;
  }

  OrderService._internal();

  final List<OrderModel> _orders = [];

  Map<String, String> _authHeaders({bool jsonContentType = false}) {
    final headers = <String, String>{};
    if (jsonContentType) {
      headers['Content-Type'] = 'application/json';
    }
    final token = AuthService().currentSession?.token ?? '';
    if (token.isNotEmpty && !token.startsWith('local-')) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
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

  List<OrderModel> get orders {
    final session = AuthService().currentSession;
    if (session != null &&
        (session.role == 'PARTNER_MANAGER' ||
            session.role == 'PARTNER_OPERATOR') &&
        session.stationId != null &&
        session.stationId!.isNotEmpty) {
      return List.unmodifiable(
        _orders.where((o) => o.station.id == session.stationId),
      );
    }
    return List.unmodifiable(_orders);
  }

  Future<List<OrderModel>> fetchOrders() async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiService.baseUrl}/vouchers'),
            headers: _authHeaders(),
          )
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
    _orders.insert(0, order);
  }

  Future<OrderModel> createOrder({
    required Station station,
    required List<String> extras,
    required double totalPrice,
    required String scheduledTime,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiService.baseUrl}/vouchers'),
            headers: _authHeaders(jsonContentType: true),
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

    try {
      final response = await http
          .post(
            Uri.parse('${ApiService.baseUrl}/scan/voucher'),
            headers: _authHeaders(jsonContentType: true),
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
      } else if (response.statusCode == 403 ||
          response.statusCode == 404 ||
          response.statusCode == 409) {
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
    final session = AuthService().currentSession;
    try {
      final order = _orders.firstWhere(
        (o) =>
            o.textCode == lookup ||
            o.qrCodeData == code ||
            o.qrCodeData == lookup ||
            o.id == lookup,
      );
      if (session != null &&
          (session.role == 'PARTNER_MANAGER' ||
              session.role == 'PARTNER_OPERATOR') &&
          session.stationId != null &&
          session.stationId != order.station.id) {
        return null;
      }
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
