import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../models/station_model.dart';
import '../services/api_service.dart';
import 'widgets/station_grid.dart';
import 'widgets/station_map.dart';
import '../../schedules/views/schedules_view.dart';
import '../../orders/views/orders_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final ApiService _apiService = ApiService();
  late Future<List<Station>> _stationsFuture;

  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _stationsFuture = _apiService.fetchAvailableStations();
  }

  void _navigateToTab(int index) {
    setState(() {
      _currentTabIndex = index;
    });
  }

  String _getTitle() {
    switch (_currentTabIndex) {
      case 0:
        return 'Chuveiros Próximos';
      case 1:
        return 'Mapa de Chuveiros';
      case 2:
        return 'Horários de Banho';
      case 3:
        return 'Meus QR Codes';
      default:
        return 'iShower';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitle()),
        actions: [
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              color: isDark ? AppColors.buttonCyan : AppColors.buttonBlue,
            ),
            tooltip: isDark ? 'Ativar Modo Claro' : 'Ativar Modo Escuro',
            onPressed: AppTheme.toggleTheme,
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

          return IndexedStack(
            index: _currentTabIndex,
            children: [
              StationGrid(stations: stations),
              StationMap(stations: stations),
              const SchedulesView(),
              OrdersView(
                onExploreStations: () => _navigateToTab(0),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentTabIndex,
        onDestinationSelected: _navigateToTab,
        height: 64,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.shower_outlined),
            selectedIcon: Icon(Icons.shower),
            label: 'Chuveiros',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Mapa',
          ),
          NavigationDestination(
            icon: Icon(Icons.schedule_outlined),
            selectedIcon: Icon(Icons.schedule),
            label: 'Horários',
          ),
          NavigationDestination(
            icon: Icon(Icons.qr_code_outlined),
            selectedIcon: Icon(Icons.qr_code),
            label: 'Ver QR Code',
          ),
        ],
      ),
    );
  }
}
