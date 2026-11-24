import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/custom_primary_button.dart';
import '../../stations/models/station_model.dart';
import '../../stations/services/api_service.dart';
import '../../orders/views/checkout_view.dart';

class SchedulesView extends StatefulWidget {
  final Station? initialStation;
  final bool embedded;

  const SchedulesView({
    super.key,
    this.initialStation,
    this.embedded = false,
  });

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
  late final List<Map<String, String>> _days;

  static const _weekdayLabels = <int, String>{
    DateTime.monday: 'Segunda',
    DateTime.tuesday: 'Terça',
    DateTime.wednesday: 'Quarta',
    DateTime.thursday: 'Quinta',
    DateTime.friday: 'Sexta',
    DateTime.saturday: 'Sábado',
    DateTime.sunday: 'Domingo',
  };

  @override
  void initState() {
    super.initState();
    _days = _buildUpcomingDays();
    _loadStations();
  }

  List<Map<String, String>> _buildUpcomingDays() {
    final now = DateTime.now();
    return List.generate(7, (offset) {
      final date = now.add(Duration(days: offset));
      final dd = date.day.toString().padLeft(2, '0');
      final mm = date.month.toString().padLeft(2, '0');
      final label = offset == 0
          ? 'Hoje'
          : offset == 1
              ? 'Amanhã'
              : (_weekdayLabels[date.weekday] ?? 'Dia');
      return {'label': label, 'date': '$dd/$mm'};
    });
  }

  Future<void> _loadStations() async {
    final list = await _apiService.fetchAvailableStations();
    if (mounted) {
      setState(() {
        _stations = list;
        _isLoading = false;
        if (widget.initialStation != null && list.isNotEmpty) {
          _selectedStation = list.firstWhere(
            (s) => s.id == widget.initialStation!.id,
            orElse: () => list.first,
          );
        } else if (list.isNotEmpty) {
          _selectedStation = list.firstWhere(
            (s) => s.isAvailable,
            orElse: () => list.first,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.canPop(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bodyContent = _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _stations.isEmpty
            ? const Center(child: Text('Nenhum posto encontrado'))
            : Column(
                children: [
                  Expanded(child: _buildContent(isDark)),
                  if (_selectedStation != null) _buildBottomBar(isDark),
                ],
              );

    if (widget.embedded) {
      return bodyContent;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Horários de Banho'),
        leading: canPop
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              )
            : null,
      ),
      body: bodyContent,
    );
  }

  Widget _buildContent(bool isDark) {
    final station = _selectedStation ?? _stations.first;
    final slots = station.availableTimeSlots;
    final primaryBlue = isDark ? AppColors.buttonSky : AppColors.primary;
    final cardBg = isDark ? AppColors.cardBackground : AppColors.lightCard;
    final borderCol = isDark ? AppColors.border : AppColors.lightBorder;
    final textColor = isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final textSub = isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Station Selector
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
                      children: [
                        Expanded(
                          child: Text(
                            s.isAvailable ? s.name : '${s.name} (Indisponível)',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: s.isAvailable ? textColor : textSub,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          Formatters.formatCurrency(s.price),
                          style: TextStyle(
                            color: primaryBlue,
                            fontWeight: FontWeight.w700,
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

          if (!station.isAvailable) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.statusBusyBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.statusBusy.withValues(alpha: 0.4),
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.block_outlined,
                    size: 18,
                    color: AppColors.statusBusy,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Este posto está temporariamente indisponível para agendamentos. Selecione outra unidade.',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.statusBusy,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Shower Rules Card
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
                    const Icon(Icons.timer_outlined, color: AppColors.accentGold, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tempo limite de banho: ${station.maxShowerMinutes} minutos',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.accentGold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      station.operatingHours,
                      style: TextStyle(fontSize: 12, color: textSub),
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
                        style: TextStyle(fontSize: 12, color: textSub),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Day Selector
          Text(
            'Selecione o Dia',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textColor),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 62,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _days.length,
              itemBuilder: (context, index) {
                final isSelected = _selectedDayIndex == index;
                final day = _days[index];

                return GestureDetector(
                  onTap: () => setState(() => _selectedDayIndex = index),
                  child: Container(
                    width: 78,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      gradient: isSelected ? AppColors.buttonGradient : null,
                      color: isSelected ? null : cardBg,
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : borderCol,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          day['label']!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? Colors.white : textColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          day['date']!,
                          style: TextStyle(
                            fontSize: 11,
                            color: isSelected ? Colors.white.withValues(alpha: 0.9) : textSub,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
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

          // Time Slots Header
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Text(
                'Horários Disponíveis',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: primaryBlue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${station.maxShowerMinutes} min banho + limpeza',
                  style: TextStyle(
                    fontSize: 11,
                    color: primaryBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          LayoutBuilder(
            builder: (context, constraints) {
              final cols = constraints.maxWidth < 340
                  ? 2
                  : constraints.maxWidth < 600
                      ? 3
                      : 4;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cols,
                  mainAxisExtent: 54,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: slots.length,
                itemBuilder: (context, index) {
                  final slot = slots[index];
                  final isSelected = _selectedTimeSlot == slot && station.isAvailable;

                  return GestureDetector(
                    onTap: station.isAvailable
                        ? () => setState(() => _selectedTimeSlot = slot)
                        : null,
                    child: Opacity(
                      opacity: station.isAvailable ? 1.0 : 0.45,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: isSelected ? AppColors.buttonGradient : null,
                          color: isSelected ? null : cardBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : borderCol,
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
                                  fontWeight: FontWeight.w700,
                                  color: isSelected ? Colors.white : textColor,
                                ),
                              ),
                              Text(
                                '${station.maxShowerMinutes}m banho',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: isSelected
                                      ? Colors.white.withValues(alpha: 0.9)
                                      : textSub,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
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
    final dayDate = _days[_selectedDayIndex]['date']!;
    final primaryBlue = isDark ? AppColors.buttonSky : AppColors.primary;
    final canProceed = station.isAvailable && _selectedTimeSlot != null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardBackground : AppColors.lightCard,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.border : AppColors.lightBorder,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (canProceed) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '$dayLabel ($dayDate) às $_selectedTimeSlot · ${station.maxShowerMinutes} min',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    Formatters.formatCurrency(station.price),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: primaryBlue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            CustomPrimaryButton(
              height: 44,
              text: !station.isAvailable
                  ? 'Posto indisponível'
                  : (_selectedTimeSlot != null
                      ? 'Confirmar para as $_selectedTimeSlot'
                      : 'Selecione um horário'),
              icon: !station.isAvailable
                  ? Icons.block
                  : (_selectedTimeSlot != null ? Icons.check : Icons.touch_app),
              onPressed: canProceed
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CheckoutView(
                            station: station,
                            scheduledTime: '$dayLabel ($dayDate) às $_selectedTimeSlot',
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
