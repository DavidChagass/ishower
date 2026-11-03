import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/custom_primary_button.dart';
import '../../stations/models/station_model.dart';
import '../../stations/services/api_service.dart';
import '../../orders/views/checkout_view.dart';

class SchedulesView extends StatefulWidget {
  final Station? initialStation;

  const SchedulesView({super.key, this.initialStation});

  @override
  State<SchedulesView> createState() => _SchedulesViewState();
}

class _SchedulesViewState extends State<SchedulesView> {
  final ApiService _apiService = ApiService();
  List<Station> _stations = [];
  bool _isLoading = true;
  Station? _selectedStation;

  int _selectedDayIndex = 0;
  String? _selectedTimeSlot;

  final List<Map<String, String>> _days = [
    {'label': 'Hoje', 'date': '12/10'},
    {'label': 'Amanhã', 'date': '13/10'},
    {'label': 'Quarta', 'date': '14/10'},
    {'label': 'Quinta', 'date': '15/10'},
    {'label': 'Sexta', 'date': '16/10'},
    {'label': 'Sábado', 'date': '17/10'},
    {'label': 'Domingo', 'date': '18/10'},
  ];

  @override
  void initState() {
    super.initState();
    _loadStations();
  }

  Future<void> _loadStations() async {
    final list = await _apiService.fetchAvailableStations();
    if (mounted) {
      setState(() {
        _stations = list;
        _isLoading = false;
        if (widget.initialStation != null) {
          _selectedStation = list.firstWhere(
            (s) => s.id == widget.initialStation!.id,
            orElse: () => list.first,
          );
        } else if (list.isNotEmpty) {
          _selectedStation = list.first;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.canPop(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.background : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Horários de Banho'),
        leading: canPop
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              )
            : null,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _stations.isEmpty
              ? const Center(child: Text('Nenhum posto encontrado'))
              : _buildContent(isDark),
      bottomNavigationBar: _selectedStation != null ? _buildBottomBar(isDark) : null,
    );
  }

  Widget _buildContent(bool isDark) {
    final station = _selectedStation ?? _stations.first;
    final slots = station.availableTimeSlots;
    final primaryBlue = isDark ? AppColors.buttonSky : AppColors.buttonBlue;
    final cardBg = isDark ? AppColors.cardBackground : AppColors.lightCard;
    final borderCol = isDark ? AppColors.border : AppColors.lightBorder;
    final textColor = isDark ? Colors.white : AppColors.lightTextPrimary;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Seletor de Posto
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderCol),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<Station>(
                value: station,
                isExpanded: true,
                dropdownColor: cardBg,
                icon: Icon(Icons.arrow_drop_down, color: primaryBlue),
                items: _stations.map((s) {
                  return DropdownMenuItem<Station>(
                    value: s,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          s.name,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor),
                        ),
                        Text(
                          Formatters.formatCurrency(s.price),
                          style: TextStyle(
                            color: primaryBlue,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (newStation) {
                  if (newStation != null) {
                    setState(() {
                      _selectedStation = newStation;
                      _selectedTimeSlot = null;
                    });
                  }
                },
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Card de Regras de Tempo (25 min banho / 25 - 40 min limpeza) com contraste #FAB60A
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderCol),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.timer, color: AppColors.accentGold, size: 18),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Tempo limite de banho: 25 minutos',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.accentGold,
                        ),
                      ),
                    ),
                    Text(
                      station.operatingHours,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.cleaning_services_rounded, color: primaryBlue, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Intervalo de limpeza: ${station.cleaningDuration} para higienização entre banhos.',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Seletor de Dias
          Text(
            'Selecione o Dia',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _days.length,
              itemBuilder: (context, index) {
                final isSelected = _selectedDayIndex == index;
                final day = _days[index];

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDayIndex = index;
                    });
                  },
                  child: Container(
                    width: 72,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      gradient: isSelected ? AppColors.buttonGradient : null,
                      color: isSelected ? null : cardBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.buttonCyan
                            : borderCol,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          day['label']!,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : textColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          day['date']!,
                          style: TextStyle(
                            fontSize: 11,
                            color: isSelected ? AppColors.accentGold : (isDark ? AppColors.textSecondary : AppColors.lightTextSecondary),
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // Grade de Horários
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Horários Disponíveis (Ciclos de 1h)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primaryDark.withValues(alpha: isDark ? 0.3 : 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '25 min banho + limpeza',
                  style: TextStyle(fontSize: 10, color: primaryBlue, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 2.2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: slots.length,
            itemBuilder: (context, index) {
              final slot = slots[index];
              final isSelected = _selectedTimeSlot == slot;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedTimeSlot = slot;
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    gradient: isSelected ? AppColors.buttonGradient : null,
                    color: isSelected ? null : cardBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.buttonCyan
                          : borderCol,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          slot,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : textColor,
                          ),
                        ),
                        Text(
                          '25m banho',
                          style: TextStyle(
                            fontSize: 10,
                            color: isSelected ? AppColors.accentGold : (isDark ? AppColors.textSecondary : AppColors.lightTextSecondary),
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(bool isDark) {
    final station = _selectedStation ?? _stations.first;
    final dayLabel = _days[_selectedDayIndex]['label']!;
    final primaryBlue = isDark ? AppColors.buttonSky : AppColors.buttonBlue;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF181818) : AppColors.lightCard,
        border: Border(top: BorderSide(color: isDark ? AppColors.border : AppColors.lightBorder, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_selectedTimeSlot != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$dayLabel às $_selectedTimeSlot (25 min banho)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.lightTextPrimary,
                    ),
                  ),
                  Text(
                    Formatters.formatCurrency(station.price),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: primaryBlue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            CustomPrimaryButton(
              height: 44,
              text: _selectedTimeSlot != null
                  ? 'Confirmar para as $_selectedTimeSlot'
                  : 'Selecione um horário',
              icon: _selectedTimeSlot != null ? Icons.check : Icons.touch_app,
              onPressed: _selectedTimeSlot != null
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CheckoutView(
                            station: station,
                            scheduledTime: '$dayLabel às $_selectedTimeSlot',
                          ),
                        ),
                      );
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
