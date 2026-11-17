class StationServiceItem {
  final String id;
  final String name;
  final String description;
  final int priceCents;
  final bool active;

  const StationServiceItem({
    required this.id,
    required this.name,
    required this.description,
    required this.priceCents,
    this.active = true,
  });

  double get price => priceCents / 100.0;

  factory StationServiceItem.fromJson(Map<String, dynamic> json) {
    return StationServiceItem(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      priceCents: (json['price_cents'] as num?)?.toInt() ?? 0,
      active: (json['active'] as bool?) ?? true,
    );
  }
}

class Station {
  final String id;
  final String name;
  final String address;
  final double distance;
  final double price;
  final bool isAvailable;
  final double lat;
  final double lng;
  final String operatingHours;
  final int maxShowerMinutes;
  final String cleaningDuration;
  final List<String> availableTimeSlots;
  final List<StationServiceItem> services;

  Station({
    required this.id,
    required this.name,
    required this.address,
    required this.distance,
    required this.price,
    required this.isAvailable,
    required this.lat,
    required this.lng,
    this.operatingHours = '24 Horas',
    this.maxShowerMinutes = 25,
    this.cleaningDuration = '25 - 40 min',
    this.availableTimeSlots = const [
      '06:00', '07:00', '08:00', '09:00', '10:00', '11:00',
      '12:00', '13:00', '14:00', '15:00', '16:00', '17:00',
      '18:00', '19:00', '20:00', '21:00', '22:00'
    ],
    this.services = const [],
  });

  factory Station.fromJson(Map<String, dynamic> json) {
    final rawPrice = json['price'];
    final rawPriceCents = json['price_cents'];
    double parsedPrice = 15.0;
    if (rawPrice != null) {
      parsedPrice = (rawPrice as num).toDouble();
    } else if (rawPriceCents != null) {
      parsedPrice = (rawPriceCents as num).toDouble() / 100.0;
    }

    final rawServices = json['services'] as List<dynamic>?;
    final parsedServices = rawServices != null
        ? rawServices
            .whereType<Map<String, dynamic>>()
            .map(StationServiceItem.fromJson)
            .toList()
        : <StationServiceItem>[];

    return Station(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? json['trade_name'] ?? '').toString(),
      address: (json['address'] ?? '').toString(),
      distance: (json['distance'] as num?)?.toDouble() ?? 2.5,
      price: parsedPrice,
      isAvailable: (json['is_available'] ?? json['active'] ?? true) as bool,
      lat: (json['lat'] as num?)?.toDouble() ?? -19.9333,
      lng: (json['lng'] as num?)?.toDouble() ?? -43.9711,
      operatingHours: (json['operating_hours'] ?? '24 Horas').toString(),
      maxShowerMinutes: (json['max_shower_minutes'] as num?)?.toInt() ?? 25,
      cleaningDuration: (json['cleaning_duration'] ?? '25 - 40 min').toString(),
      availableTimeSlots: json['time_slots'] != null
          ? List<String>.from(json['time_slots'])
          : const [
              '06:00', '07:00', '08:00', '09:00', '10:00', '11:00',
              '12:00', '13:00', '14:00', '15:00', '16:00', '17:00',
              '18:00', '19:00', '20:00', '21:00', '22:00'
            ],
      services: parsedServices,
    );
  }
}
