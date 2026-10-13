import '../models/station_model.dart';

class ApiService {
  static const String baseUrl = 'https://sua-api.com/api';

  Future<List<Station>> fetchAvailableStations() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return [
      Station(
        id: '1',
        name: 'Posto Graal - BR 381',
        address: 'Rodovia Fernão Dias, Km 45',
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
        id: '2',
        name: 'Posto Ipiranga Rota 26',
        address: 'Av. Amazonas, 4500',
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
        id: '3',
        name: 'Posto Petrobras - Parada Certa',
        address: 'Anel Rodoviário, Km 12',
        distance: 8.2,
        price: 20.00,
        isAvailable: false,
        lat: -19.8967,
        lng: -43.9482,
        operatingHours: '06:00 - 22:00',
        maxShowerMinutes: 25,
        cleaningDuration: '25 - 40 min',
        availableTimeSlots: [
          '10:00', '11:00', '14:00', '15:00', '17:00', '18:00',
          '20:00', '21:00'
        ],
      ),
    ];
  }
}
