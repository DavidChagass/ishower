import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../auth/services/auth_service.dart';
import '../models/order_model.dart';
import '../../stations/models/station_model.dart';
import '../../stations/services/api_service.dart';

class OrderValidationResult {
  final OrderModel? order;
  final String? errorMessage;

  const OrderValidationResult({this.order, this.errorMessage});
  bool get isSuccess => order != null;
}

class OrderService {
  static final OrderService _instance = OrderService._internal();

  factory OrderService() {
    return _instance;
  }

  OrderService._internal();

  final List<OrderModel> _orders = [];
  final ValueNotifier<int> ordersVersion = ValueNotifier<int>(0);

  void _notifyChanged() {
    ordersVersion.value++;
  }

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
        ApiService.isOfflineNotifier.value = false;
        final List<dynamic> data = jsonDecode(response.body);
        final fetched = data
            .whereType<Map<String, dynamic>>()
            .map(OrderModel.fromJson)
            .toList();
        _orders
          ..clear()
          ..addAll(fetched);
        _notifyChanged();
      }
    } catch (_) {
      ApiService.isOfflineNotifier.value = true;
    }
    return orders;
  }

  void clearLocalOrders() {
    _orders.clear();
    _notifyChanged();
  }

  void addOrder(OrderModel order) {
    _orders.insert(0, order);
    _notifyChanged();
  }

  Future<OrderModel> createOrder({
    required Station station,
    required List<String> extras,
    required double totalPrice,
    required String scheduledTime,
    String paymentMethod = 'wallet',
  }) async {
    if (!station.isAvailable) {
      throw Exception('Este posto está temporariamente indisponível para reservas.');
    }

    final session = AuthService().currentSession;
    if (paymentMethod == 'wallet' &&
        session != null &&
        session.isDriver &&
        session.balance < totalPrice) {
      throw Exception(
          'Saldo insuficiente na carteira. Faça uma recarga PIX na aba Carteira ou selecione PIX Instantâneo.');
    }

    try {
      final response = await http
          .post(
            Uri.parse('${ApiService.baseUrl}/vouchers'),
            headers: _authHeaders(jsonContentType: true),
            body: jsonEncode({
              'station_id': station.id,
              'scheduled_time': scheduledTime,
              'extras': extras,
              'payment_method': paymentMethod,
            }),
          )
          .timeout(const Duration(seconds: 3));

      if (response.statusCode == 201 || response.statusCode == 200) {
        ApiService.isOfflineNotifier.value = false;
        final Map<String, dynamic> data = jsonDecode(response.body);
        final created = OrderModel.fromJson(data);
        _orders.removeWhere((o) => o.id == created.id);
        _orders.insert(0, created);
        _notifyChanged();
        await AuthService().refreshSession(notifyWallet: true);
        return created;
      } else if (response.statusCode == 402) {
        throw Exception(
            'Saldo insuficiente na carteira iShower. Faça uma recarga PIX na aba Carteira.');
      } else if (response.statusCode == 409) {
        throw Exception(
            'Este posto está temporariamente indisponível para reservas.');
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw Exception('Sessão expirada ou sem permissão para reservar.');
      }
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('Saldo insuficiente') ||
          msg.contains('indisponível') ||
          msg.contains('permissão')) {
        rethrow;
      }
      ApiService.isOfflineNotifier.value = true;
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
      driverName: session?.name,
    );
    addOrder(fallbackOrder);
    if (paymentMethod == 'wallet') {
      AuthService().recordLocalUsage(totalPrice, code);
    }
    return fallbackOrder;
  }

  Future<OrderModel> cancelOrder(OrderModel target) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiService.baseUrl}/vouchers/${target.id}/cancel'),
            headers: _authHeaders(jsonContentType: true),
          )
          .timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        ApiService.isOfflineNotifier.value = false;
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final updated = OrderModel.fromJson(data);
        final idx = _orders.indexWhere((o) => o.id == updated.id);
        if (idx >= 0) {
          _orders[idx] = updated;
        }
        _notifyChanged();
        await AuthService().refreshSession(notifyWallet: true);
        return updated;
      } else if (response.statusCode == 403) {
        throw Exception('Você não possui permissão para cancelar esta reserva.');
      } else if (response.statusCode == 409) {
        throw Exception('Apenas reservas ativas podem ser canceladas.');
      }
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('permissão') || msg.contains('reservas ativas')) {
        rethrow;
      }
      ApiService.isOfflineNotifier.value = true;
    }

    target.status = 'cancelado';
    AuthService().recordLocalRefund(target.totalPrice, target.textCode);
    _notifyChanged();
    return target;
  }

  Future<OrderValidationResult> validateOrderDetailed(String code) async {
    final rawTrimmed = code.trim();
    final cleanCode = extractLookupCode(rawTrimmed);
    if (cleanCode.isEmpty) {
      return const OrderValidationResult(
        errorMessage: 'Informe um código de 6 dígitos ou escaneie um QR Code.',
      );
    }

    try {
      final response = await http
          .post(
            Uri.parse('${ApiService.baseUrl}/scan/voucher'),
            headers: _authHeaders(jsonContentType: true),
            body: jsonEncode({'code': rawTrimmed}),
          )
          .timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        ApiService.isOfflineNotifier.value = false;
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
          _notifyChanged();
          return OrderValidationResult(order: validated);
        }
      } else if (response.statusCode == 403) {
        return const OrderValidationResult(
          errorMessage: 'Acesso negado: este voucher pertence a outro posto.',
        );
      } else if (response.statusCode == 404) {
        return const OrderValidationResult(
          errorMessage: 'Código não encontrado na base de reservas.',
        );
      } else if (response.statusCode == 409) {
        await fetchOrders();
        return const OrderValidationResult(
          errorMessage: 'Este voucher já foi utilizado ou cancelado anteriormente.',
        );
      } else if (response.statusCode == 401) {
        return const OrderValidationResult(
          errorMessage: 'Sessão expirada. Faça login novamente.',
        );
      }
    } catch (_) {
      ApiService.isOfflineNotifier.value = true;
    }

    final local = validateOrder(cleanCode);
    if (local != null) {
      _notifyChanged();
      return OrderValidationResult(order: local);
    }
    return const OrderValidationResult(
      errorMessage: 'Código inválido, pertence a outro posto ou já foi utilizado.',
    );
  }

  Future<OrderModel?> validateOrderAsync(String code) async {
    final result = await validateOrderDetailed(code);
    return result.order;
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
