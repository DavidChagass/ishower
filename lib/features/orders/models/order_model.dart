import '../../stations/models/station_model.dart';

class OrderModel {
  final String id;
  final Station station;
  final String qrCodeData;
  final String textCode;
  final DateTime date;
  final String status;

  OrderModel({
    required this.id,
    required this.station,
    required this.qrCodeData,
    required this.textCode,
    required this.date,
    this.status = 'ativo',
  });
}
