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
    final primaryBlue = isDark ? AppColors.buttonSky : AppColors.primary;
    final textPrimary = isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final textSub = isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;

    return SingleChildScrollView(
      child: Padding(
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
                width: 38,
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
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: station.isAvailable
                        ? AppColors.statusAvailableBackground
                        : AppColors.statusBusyBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    station.isAvailable ? 'Livre' : 'Indisponível',
                    style: TextStyle(
                      color: station.isAvailable
                          ? AppColors.statusAvailable
                          : AppColors.statusBusy,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              station.address,
              style: TextStyle(color: textSub, fontSize: 13),
            ),
            const SizedBox(height: 14),

            if (!station.isAvailable) ...[
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: AppColors.statusBusyBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.statusBusy.withValues(alpha: 0.35),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.pause_circle_outline,
                      size: 18,
                      color: AppColors.statusBusy,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Este posto está temporariamente indisponível para novas reservas.',
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

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surface : AppColors.lightSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? AppColors.border : AppColors.lightBorder,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.timer_outlined,
                        size: 16,
                        color: AppColors.accentGold,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            text: 'Tempo limite de banho: ',
                            style: TextStyle(color: textSub, fontSize: 13),
                            children: [
                              TextSpan(
                                text: '${station.maxShowerMinutes} min',
                                style: const TextStyle(
                                  color: AppColors.accentGold,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.cleaning_services_outlined,
                        size: 16,
                        color: primaryBlue,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            text: 'Higienização pós-uso: ',
                            style: TextStyle(color: textSub, fontSize: 13),
                            children: [
                              TextSpan(
                                text: station.cleaningDuration,
                                style: TextStyle(
                                  color: primaryBlue,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            if (station.services.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Serviços adicionais disponíveis:',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: textSub,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: station.services
                    .where((s) => s.active)
                    .map(
                      (s) => Chip(
                        visualDensity: VisualDensity.compact,
                        label: Text(
                          '${s.name} (+${Formatters.formatCurrency(s.price)})',
                          style: const TextStyle(fontSize: 11.5),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],

            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  Formatters.formatCurrency(station.price),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: primaryBlue,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Funcionamento: ${station.operatingHours}',
                    textAlign: TextAlign.end,
                    style: TextStyle(color: textSub, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: CustomSecondaryButton(
                    text: 'Horários',
                    icon: Icons.schedule,
                    onPressed: station.isAvailable
                        ? () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    SchedulesView(initialStation: station),
                              ),
                            );
                          }
                        : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: CustomPrimaryButton(
                    text: station.isAvailable ? 'Reservar' : 'Indisponível',
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
      ),
    );
  }
}
