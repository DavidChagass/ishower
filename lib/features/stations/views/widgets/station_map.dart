import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/theme/app_colors.dart';
import '../../models/station_model.dart';
import 'station_details_sheet.dart';

class StationMap extends StatelessWidget {
  final List<Station> stations;

  const StationMap({super.key, required this.stations});

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: const MapOptions(
        initialCenter: LatLng(-19.9333, -43.9711),
        initialZoom: 12.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.ishower',
        ),
        MarkerLayer(
          markers: stations.map((station) {
            return Marker(
              point: LatLng(station.lat, station.lng),
              width: 50,
              height: 50,
              child: GestureDetector(
                onTap: () => StationDetailsSheet.show(context, station),
                child: Icon(
                  Icons.location_on,
                  size: 40,
                  color: station.isAvailable ? AppColors.primary : AppColors.statusBusy,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
