import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/custom_primary_button.dart';
import '../../models/station_model.dart';
import '../../../orders/views/checkout_view.dart';
import '../../../schedules/views/schedules_view.dart';

class StationDetailsSheet extends StatelessWidget {
  final Station station;

  const StationDetailsSheet({super.key, required this.station});

  static void show(BuildContext context, Station station) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => StationDetailsSheet(station: station),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryBlue = isDark ? AppColors.buttonSky : AppColors.buttonBlue;

    return Padding(
      padding: EdgeInsets.only(
        left: 20.0,
        right: 20.0,
        top: 16.0,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24.0,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[700] : Colors.grey[350],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  station.name,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.lightTextPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: station.isAvailable
                      ? AppColors.statusAvailableBackground
                      : AppColors.statusBusyBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  station.isAvailable ? 'Livre' : 'Ocupado',
                  style: TextStyle(
                    color: station.isAvailable ? AppColors.statusAvailable : AppColors.statusBusy,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            station.address,
            style: TextStyle(
              color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),

          // Card com Regras de Banho (25 min) e Limpeza (25 - 40 min)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF242424) : AppColors.lightSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? AppColors.border : AppColors.lightBorder),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.timer_outlined, size: 16, color: AppColors.accentGold),
                    const SizedBox(width: 8),
                    Text(
                      'Tempo limite de banho: ',
                      style: TextStyle(
                        color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const Text('25 min', style: TextStyle(color: AppColors.accentGold, fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.cleaning_services_outlined, size: 16, color: primaryBlue),
                    const SizedBox(width: 8),
                    Text(
                      'Higienização pós-uso: ',
                      style: TextStyle(
                        color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
                        fontSize: 13,
                      ),
                    ),
                    Text(station.cleaningDuration, style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                Formatters.formatCurrency(station.price),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: primaryBlue,
                ),
              ),
              Text(
                'Funcionamento: ${station.operatingHours}',
                style: TextStyle(
                  color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Botões de Ação com novas cores vibrantes
          Row(
            children: [
              Expanded(
                child: CustomSecondaryButton(
                  text: 'Horários',
                  icon: Icons.schedule,
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SchedulesView(initialStation: station),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: CustomPrimaryButton(
                  text: 'Reservar',
                  icon: Icons.shower,
                  onPressed: station.isAvailable
                      ? () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CheckoutView(station: station),
                            ),
                          );
                        }
                      : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
