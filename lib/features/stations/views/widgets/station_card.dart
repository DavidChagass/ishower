import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../models/station_model.dart';
import '../../../orders/views/checkout_view.dart';
import '../../../schedules/views/schedules_view.dart';
import 'station_details_sheet.dart';

class StationCard extends StatelessWidget {
  final Station station;

  const StationCard({super.key, required this.station});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryBlue = isDark ? AppColors.buttonSky : AppColors.buttonBlue;

    return GestureDetector(
      onTap: () => StationDetailsSheet.show(context, station),
      child: Card(
        color: isDark ? AppColors.cardBackground : AppColors.lightCard,
        elevation: isDark ? 4 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isDark
                ? (station.isAvailable ? AppColors.primary.withValues(alpha: 0.3) : AppColors.border)
                : (station.isAvailable ? AppColors.buttonSky.withValues(alpha: 0.4) : AppColors.lightBorder),
            width: 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top: Ícone de Chuveiro com badge de 25 min em #FAB60A
            Expanded(
              flex: 5,
              child: Container(
                color: isDark ? Colors.grey[900] : AppColors.lightSurface,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      Icons.shower,
                      size: 46,
                      color: station.isAvailable ? primaryBlue : Colors.grey[500],
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.black.withValues(alpha: 0.75) : Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.accentGold, width: 0.9),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.timer_outlined, size: 10, color: AppColors.accentGold),
                            SizedBox(width: 3),
                            Text(
                              '25 min',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.accentGold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom: Informações e Botão Vibrante
            Expanded(
              flex: 6,
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      station.name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.lightTextPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 12,
                          color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${station.distance} km',
                          style: TextStyle(
                            color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
                            fontSize: 11,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: station.isAvailable ? AppColors.statusAvailable : AppColors.statusBusy,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          Formatters.formatCurrency(station.price),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: primaryBlue,
                          ),
                        ),
                        Text(
                          station.isAvailable ? 'Livre' : 'Ocupado',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: station.isAvailable ? AppColors.statusAvailable : AppColors.statusBusy,
                          ),
                        ),
                      ],
                    ),

                    // Botão com cores vivas (#006DFA / #00BBFA)
                    SizedBox(
                      width: double.infinity,
                      height: 32,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: station.isAvailable ? AppColors.buttonGradient : null,
                          color: station.isAvailable ? null : (isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE2E8F0)),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: station.isAvailable ? AppColors.buttonCyan.withValues(alpha: 0.6) : Colors.transparent,
                            width: 0.8,
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: station.isAvailable
                                ? () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => CheckoutView(station: station),
                                      ),
                                    );
                                  }
                                : () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => SchedulesView(initialStation: station),
                                      ),
                                    );
                                  },
                            child: Center(
                              child: Text(
                                station.isAvailable ? 'Reservar' : 'Horários',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: station.isAvailable ? Colors.white : Colors.grey,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
