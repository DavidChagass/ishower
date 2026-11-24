import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../models/station_model.dart';
import 'station_details_sheet.dart';

class StationMap extends StatefulWidget {
  final List<Station> stations;

  const StationMap({super.key, required this.stations});

  @override
  State<StationMap> createState() => _StationMapState();
}

class _StationMapState extends State<StationMap> {
  final MapController _mapController = MapController();
  double _currentZoom = 12.0;

  LatLng get _defaultCenter {
    if (widget.stations.isNotEmpty) {
      return LatLng(widget.stations.first.lat, widget.stations.first.lng);
    }
    return const LatLng(-19.9333, -43.9711);
  }

  void _zoomBy(double delta) {
    final next = (_currentZoom + delta).clamp(5.0, 18.0);
    setState(() => _currentZoom = next);
    _mapController.move(_mapController.camera.center, next);
  }

  void _recenter() {
    setState(() => _currentZoom = 12.0);
    _mapController.move(_defaultCenter, 12.0);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.cardBackground : Colors.white;

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _defaultCenter,
            initialZoom: _currentZoom,
            onPositionChanged: (pos, _) {
              _currentZoom = pos.zoom;
            },
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.ishower',
            ),
            MarkerLayer(
              markers: widget.stations.map((station) {
                final pinColor = station.isAvailable
                    ? AppColors.primary
                    : AppColors.statusBusy;
                return Marker(
                  point: LatLng(station.lat, station.lng),
                  width: 112,
                  height: 68,
                  child: GestureDetector(
                    onTap: () => StationDetailsSheet.show(context, station),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: pinColor,
                            borderRadius: BorderRadius.circular(999),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.22),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            Formatters.formatCurrency(station.price),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.location_on,
                          size: 36,
                          color: pinColor,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),

        // Availability Legend Pill
        Positioned(
          top: 12,
          left: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: cardBg.withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 10,
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, size: 10, color: AppColors.primary),
                SizedBox(width: 5),
                Text('Disponível', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                SizedBox(width: 12),
                Icon(Icons.circle, size: 10, color: AppColors.statusBusy),
                SizedBox(width: 5),
                Text('Indisponível', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),

        // Zoom & Recenter Controls
        Positioned(
          right: 12,
          bottom: 18,
          child: Column(
            children: [
              FloatingActionButton.small(
                heroTag: 'map_zoom_in',
                backgroundColor: cardBg,
                foregroundColor: AppColors.primary,
                onPressed: () => _zoomBy(1.0),
                child: const Icon(Icons.add),
              ),
              const SizedBox(height: 8),
              FloatingActionButton.small(
                heroTag: 'map_zoom_out',
                backgroundColor: cardBg,
                foregroundColor: AppColors.primary,
                onPressed: () => _zoomBy(-1.0),
                child: const Icon(Icons.remove),
              ),
              const SizedBox(height: 8),
              FloatingActionButton.small(
                heroTag: 'map_recenter',
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                onPressed: _recenter,
                child: const Icon(Icons.my_location),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
