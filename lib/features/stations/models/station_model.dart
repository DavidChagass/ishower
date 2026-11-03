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
  });

  factory Station.fromJson(Map<String, dynamic> json) {
    return Station(
      id: json['id'].toString(),
      name: json['name'],
      address: json['address'],
      distance: json['distance'].toDouble(),
      price: json['price'].toDouble(),
      isAvailable: json['is_available'],
      lat: json['lat'].toDouble(),
      lng: json['lng'].toDouble(),
      operatingHours: json['operating_hours'] ?? '24 Horas',
      maxShowerMinutes: json['max_shower_minutes'] ?? 25,
      cleaningDuration: json['cleaning_duration'] ?? '25 - 40 min',
      availableTimeSlots: json['time_slots'] != null
          ? List<String>.from(json['time_slots'])
          : const [
              '06:00', '07:00', '08:00', '09:00', '10:00', '11:00',
              '12:00', '13:00', '14:00', '15:00', '16:00', '17:00',
              '18:00', '19:00', '20:00', '21:00', '22:00'
            ],
    );
  }
}
