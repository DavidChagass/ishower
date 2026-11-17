import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/models/user_session.dart';
import '../../auth/services/auth_service.dart';
import '../models/station_model.dart';
import '../services/api_service.dart';
import 'widgets/station_grid.dart';
import 'widgets/station_map.dart';
import '../../admin/views/admin_view.dart';
import '../../schedules/views/schedules_view.dart';
import '../../orders/views/orders_view.dart';

class HomeView extends StatefulWidget {
  final UserSession? session;

  const HomeView({super.key, this.session});

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

  void _reloadStations() {
    setState(() {
      _stationsFuture = _apiService.fetchAvailableStations();
    });
  }

  String _getTitle(bool isStaff) {
    if (isStaff) return 'Administração';
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
    final activeSession = widget.session ?? AuthService().currentSession;
    final isStaff = activeSession?.isStaff ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_getTitle(isStaff)),
            if (activeSession != null)
              Text(
                '${activeSession.name} (${activeSession.roleLabel})',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              color: isDark ? AppColors.buttonCyan : AppColors.buttonBlue,
            ),
            tooltip: isDark ? 'Ativar Modo Claro' : 'Ativar Modo Escuro',
            onPressed: AppTheme.toggleTheme,
          ),
          if (activeSession != null)
            IconButton(
              icon: const Icon(Icons.logout_outlined),
              tooltip: 'Sair da conta',
              onPressed: () => AuthService().logout(),
            ),
        ],
      ),
      body: isStaff
          ? AdminView(onStationsChanged: _reloadStations)
          : FutureBuilder<List<Station>>(
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
      bottomNavigationBar: isStaff
          ? null
          : NavigationBar(
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
