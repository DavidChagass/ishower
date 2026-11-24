import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../auth/services/auth_service.dart';
import '../models/station_model.dart';

class ApiService {
  static const String _prefApiUrlKey = 'ishower_api_base_url_v1';
  static const String defaultBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000/api/v1',
  );

  static String _baseUrl = defaultBaseUrl;
  static String get baseUrl => _baseUrl;

  static final ValueNotifier<bool> isOfflineNotifier = ValueNotifier<bool>(false);

  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefApiUrlKey);
      if (saved != null && saved.trim().isNotEmpty) {
        _baseUrl = _normalizeBaseUrl(saved);
      }
    } catch (_) {
      // Ignore in test environments without plugin channel
    }
  }

  static String _normalizeBaseUrl(String raw) {
    var trimmed = raw.trim();
    if (trimmed.endsWith('/')) {
      trimmed = trimmed.substring(0, trimmed.length - 1);
    }
    if (!trimmed.endsWith('/api/v1')) {
      trimmed = '$trimmed/api/v1';
    }
    return trimmed;
  }

  static Future<void> setCustomBaseUrl(String rawUrl) async {
    final normalized = rawUrl.trim().isEmpty
        ? defaultBaseUrl
        : _normalizeBaseUrl(rawUrl);
    _baseUrl = normalized;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (rawUrl.trim().isEmpty) {
        await prefs.remove(_prefApiUrlKey);
      } else {
        await prefs.setString(_prefApiUrlKey, normalized);
      }
    } catch (_) {
      // Ignore in test environments
    }
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

  Future<List<Station>> fetchAvailableStations() async {
    final session = AuthService().currentSession;
    final scopedStationId =
        (session != null &&
                (session.role == 'PARTNER_MANAGER' ||
                    session.role == 'PARTNER_OPERATOR'))
            ? session.stationId
            : null;

    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/stations'),
            headers: _authHeaders(),
          )
          .timeout(const Duration(seconds: 2));

      if (response.statusCode == 200) {
        isOfflineNotifier.value = false;
        final List<dynamic> data = jsonDecode(response.body);
        final stations = data
            .whereType<Map<String, dynamic>>()
            .map(Station.fromJson)
            .toList();
        if (scopedStationId != null && scopedStationId.isNotEmpty) {
          return stations.where((s) => s.id == scopedStationId).toList();
        }
        return stations;
      }
    } catch (_) {
      isOfflineNotifier.value = true;
    }

    final fallback = _fallbackStations();
    if (scopedStationId != null && scopedStationId.isNotEmpty) {
      return fallback.where((s) => s.id == scopedStationId).toList();
    }
    return fallback;
  }

  Future<Station> toggleStationAvailability(
      Station station, bool nextAvailable) async {
    return updateStation(station, active: nextAvailable);
  }

  Future<Station> updateStation(
    Station station, {
    bool? active,
    double? price,
  }) async {
    final session = AuthService().currentSession;
    if (session != null && !session.canManageStations) {
      throw Exception('Você não possui permissão para alterar dados de postos.');
    }
    if (session != null &&
        session.isManager &&
        session.stationId != null &&
        session.stationId != station.id) {
      throw Exception(
          'Você só possui permissão para alterar o posto ao qual está vinculado.');
    }

    final payload = <String, dynamic>{};
    if (active != null) payload['active'] = active;
    if (price != null) payload['price_cents'] = (price * 100).round();

    try {
      final response = await http
          .put(
            Uri.parse('$baseUrl/stations/${station.id}'),
            headers: _authHeaders(jsonContentType: true),
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        isOfflineNotifier.value = false;
        final Map<String, dynamic> data = jsonDecode(response.body);
        return Station.fromJson(data);
      } else if (response.statusCode == 403) {
        throw Exception('Sem permissão para alterar este posto.');
      } else if (response.statusCode == 400) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception((body['error'] ?? 'Dados inválidos.').toString());
      }
    } catch (e) {
      if (e.toString().contains('permissão') ||
          e.toString().contains('Dados inválidos')) {
        rethrow;
      }
      isOfflineNotifier.value = true;
    }

    return Station(
      id: station.id,
      name: station.name,
      address: station.address,
      distance: station.distance,
      price: price ?? station.price,
      isAvailable: active ?? station.isAvailable,
      lat: station.lat,
      lng: station.lng,
      operatingHours: station.operatingHours,
      maxShowerMinutes: station.maxShowerMinutes,
      cleaningDuration: station.cleaningDuration,
      availableTimeSlots: station.availableTimeSlots,
      services: station.services,
    );
  }

  List<Station> _fallbackStations() {
    const defaultServices = [
      StationServiceItem(
        id: 'srv-toalha',
        name: 'Toalha',
        description: 'Toalha de banho higienizada',
        priceCents: 500,
      ),
      StationServiceItem(
        id: 'srv-sabonete',
        name: 'Sabonete',
        description: 'Sabonete individual',
        priceCents: 200,
      ),
    ];

    return [
      Station(
        id: '11111111-1111-4111-8111-111111111111',
        name: 'Posto Graal - BR 381',
        address: 'Rodovia Fernão Dias, Km 45 - Betim/MG',
        distance: 2.5,
        price: 15.00,
        isAvailable: true,
        lat: -19.9554,
        lng: -44.0445,
        operatingHours: '24 Horas',
        maxShowerMinutes: 25,
        cleaningDuration: '25 - 40 min',
        availableTimeSlots: const [
          '06:00', '07:00', '08:00', '09:00', '10:00', '11:00',
          '13:00', '14:00', '15:00', '16:00', '17:00', '18:00',
          '19:00', '20:00', '21:00', '22:00'
        ],
        services: defaultServices,
      ),
      Station(
        id: '22222222-2222-4222-8222-222222222222',
        name: 'Posto Ipiranga Rota 26',
        address: 'Av. Amazonas, 4500 - Contagem/MG',
        distance: 5.0,
        price: 12.50,
        isAvailable: true,
        lat: -19.9333,
        lng: -43.9711,
        operatingHours: '05:00 - 23:00',
        maxShowerMinutes: 25,
        cleaningDuration: '25 - 40 min',
        availableTimeSlots: const [
          '07:00', '08:00', '09:00', '11:00', '13:00', '14:00',
          '16:00', '17:00', '18:00', '19:00', '21:00', '22:00'
        ],
        services: defaultServices,
      ),
      Station(
        id: '33333333-3333-4333-8333-333333333333',
        name: 'Posto Petrobras - Parada Certa',
        address: 'Anel Rodoviário, Km 12 - Belo Horizonte/MG',
        distance: 8.2,
        price: 20.00,
        isAvailable: false,
        lat: -19.8967,
        lng: -43.9482,
        operatingHours: '06:00 - 22:00',
        maxShowerMinutes: 25,
        cleaningDuration: '25 - 40 min',
        availableTimeSlots: const [
          '09:00', '10:00', '14:00', '15:00', '17:00', '18:00',
          '20:00', '21:00'
        ],
        services: defaultServices,
      ),
    ];
  }
}
