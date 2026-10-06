import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/station_model.dart';

class ApiService {
  static const String baseUrl = 'https://sua-api.com/api';
  //DESCOMENTA AQUI PRA USAR A API :D
    // final response = await http.get(Uri.parse('$baseUrl/stations'));
    // if (response.statusCode == 200) {
    //   List data = json.decode(response.body);
    //   return data.map((e) => Station.fromJson(e)).toList();
    // } else {
    //   throw Exception('Falha ao carregar postos');
    // }
  Future<List<Station>> fetchAvailableStations() async {
    await Future.delayed(const Duration(seconds: 1));
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
      ),
    ];
  }
}
