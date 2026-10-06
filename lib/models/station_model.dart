class Station {
  final String id;
  final String name;
  final String address;
  final double distance;
  final double price;
  final bool isAvailable;
  final double lat;
  final double lng;

  Station({
    required this.id,
    required this.name,
    required this.address,
    required this.distance,
    required this.price,
    required this.isAvailable,
    required this.lat,
    required this.lng,
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
    );
  }
}
