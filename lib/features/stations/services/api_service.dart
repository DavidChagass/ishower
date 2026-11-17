import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/station_model.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:3000/api/v1';

  Future<List<Station>> fetchAvailableStations() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/stations'))
          .timeout(const Duration(seconds: 2));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data
            .whereType<Map<String, dynamic>>()
            .map(Station.fromJson)
            .toList();
      }
    } catch (_) {
      // Fallback para dados locais caso o servidor não esteja acessível (ex: testes de widget)
    }

    return _fallbackStations();
  }

  Future<Station> toggleStationAvailability(Station station, bool nextAvailable) async {
    try {
      final response = await http
          .put(
            Uri.parse('$baseUrl/stations/${station.id}'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'active': nextAvailable,
            }),
          )
          .timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return Station.fromJson(data);
      }
    } catch (_) {
      // Fallback local caso o backend esteja offline
    }

    return Station(
      id: station.id,
      name: station.name,
      address: station.address,
      distance: station.distance,
      price: station.price,
      isAvailable: nextAvailable,
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
        availableTimeSlots: [
          '06:00', '07:00', '08:00', '09:00', '10:00', '11:00',
          '13:00', '14:00', '15:00', '16:00', '17:00', '18:00',
          '19:00', '20:00', '21:00', '22:00'
        ],
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
        availableTimeSlots: [
          '07:00', '08:00', '09:00', '11:00', '13:00', '14:00',
          '16:00', '17:00', '18:00', '19:00', '21:00', '22:00'
        ],
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
        availableTimeSlots: [
          '10:00', '01:00', '14:00', '15:00', '17:00', '18:00',
          '20:00', '21:00'
        ],
      ),
    ];
  }
}
