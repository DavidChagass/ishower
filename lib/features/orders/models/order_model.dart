import '../../stations/models/station_model.dart';

class OrderModel {
  final String id;
  final Station station;
  final String qrCodeData;
  final String textCode;
  final DateTime date;
  final List<String> extras;
  final double totalPrice;
  String status;
  final String? scheduledTime; // Ex: '14:30' ou 'Entrada Imediata'
  final DateTime? scheduledDate;

  OrderModel({
    required this.id,
    required this.station,
    required this.qrCodeData,
    required this.textCode,
    required this.date,
    required this.totalPrice,
    this.extras = const [],
    this.status = 'ativo',
    this.scheduledTime = 'Entrada Imediata',
    this.scheduledDate,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final rawStatus = (json['status'] ?? 'PENDING').toString().toUpperCase();
    final mappedStatus = (rawStatus == 'PENDING' || rawStatus == 'ATIVO') ? 'ativo' : 'usado';

    final rawTotalPrice = json['total_price'];
    final rawTotalCents = json['total_amount_cents'];
    double parsedTotal = 15.0;
    if (rawTotalPrice != null) {
      parsedTotal = (rawTotalPrice as num).toDouble();
    } else if (rawTotalCents != null) {
      parsedTotal = (rawTotalCents as num).toDouble() / 100.0;
    }

    List<String> parsedExtras = [];
    if (json['extras'] is List) {
      parsedExtras = List<String>.from(json['extras']);
    } else if (json['items'] is List) {
      parsedExtras = (json['items'] as List)
          .whereType<Map<String, dynamic>>()
          .map((it) => (it['service_name'] ?? '').toString())
          .where((s) => s.isNotEmpty)
          .toList();
    }

    final textCode = (json['text_code'] ?? json['id'] ?? '').toString();
    final qrCodeData = (json['qr_code_data'] ?? textCode).toString();

    return OrderModel(
      id: (json['id'] ?? '').toString(),
      station: Station.fromJson(json['station'] as Map<String, dynamic>? ?? {}),
      qrCodeData: qrCodeData,
      textCode: textCode,
      date: DateTime.tryParse((json['generated_at'] ?? '').toString()) ?? DateTime.now(),
      totalPrice: parsedTotal,
      extras: parsedExtras,
      status: mappedStatus,
      scheduledTime: (json['scheduled_time'] ?? 'Entrada Imediata').toString(),
    );
  }
}
