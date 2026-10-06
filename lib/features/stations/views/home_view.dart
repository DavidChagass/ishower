import 'package:flutter/material.dart';
import '../models/station_model.dart';
import '../services/api_service.dart';
import 'widgets/station_grid.dart';
import 'widgets/station_map.dart';
import '../../orders/views/orders_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final ApiService _apiService = ApiService();
  late Future<List<Station>> _stationsFuture;

  bool _showMap = false;

  @override
  void initState() {
    super.initState();
    _stationsFuture = _apiService.fetchAvailableStations();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chuveiros Próximos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.confirmation_num_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OrdersView()),
              );
            },
          ),
          IconButton(
            icon: Icon(_showMap ? Icons.grid_view : Icons.map),
            onPressed: () {
              setState(() {
                _showMap = !_showMap;
              });
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Station>>(
        future: _stationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }

          final stations = snapshot.data ?? [];

          return _showMap 
              ? StationMap(stations: stations) 
              : StationGrid(stations: stations);
        },
      ),
    );
  }
}
