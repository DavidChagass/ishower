import 'package:flutter/material.dart';
import '../../models/station_model.dart';
import 'station_card.dart';

class StationGrid extends StatelessWidget {
  final List<Station> stations;

  const StationGrid({super.key, required this.stations});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: stations.length,
      itemBuilder: (context, index) {
        return StationCard(station: stations[index]);
      },
    );
  }
}
