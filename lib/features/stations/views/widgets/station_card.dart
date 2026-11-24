import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../models/station_model.dart';
import '../../../orders/views/checkout_view.dart';
import 'station_details_sheet.dart';

class StationCard extends StatelessWidget {
  final Station station;

  const StationCard({super.key, required this.station});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryBlue = isDark ? AppColors.buttonSky : AppColors.primary;
    final textPrimary = isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final textSub = isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;

    return GestureDetector(
      onTap: () => StationDetailsSheet.show(context, station),
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: station.isAvailable
                ? primaryBlue.withValues(alpha: isDark ? 0.35 : 0.25)
                : (isDark ? AppColors.border : AppColors.lightBorder),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Icon Banner
            Container(
              height: 86,
              color: isDark ? AppColors.surface : AppColors.lightSurface,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.shower_rounded,
                    size: 42,
                    color: station.isAvailable ? primaryBlue : textSub,
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.cardBackground : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.accentGold.withValues(alpha: 0.7),
                          width: 0.9,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.timer_outlined,
                            size: 11,
                            color: AppColors.accentGold,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${station.maxShowerMinutes} min',
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
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

            // Bottom Details & CTA
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(11),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      station.name,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 13, color: textSub),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            '${station.distance} km · ${station.operatingHours}',
                            style: TextStyle(color: textSub, fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            Formatters.formatCurrency(station.price),
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: primaryBlue,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: station.isAvailable
                                ? AppColors.statusAvailableBackground
                                : AppColors.statusBusyBackground,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            station.isAvailable ? 'Livre' : 'Indisponível',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: station.isAvailable
                                  ? AppColors.statusAvailable
                                  : AppColors.statusBusy,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      width: double.infinity,
                      height: 34,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient:
                              station.isAvailable ? AppColors.buttonGradient : null,
                          color: station.isAvailable
                              ? null
                              : (isDark
                                  ? const Color(0xFF1E293B)
                                  : const Color(0xFFE2E8F0)),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(9),
                            onTap: station.isAvailable
                                ? () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            CheckoutView(station: station),
                                      ),
                                    );
                                  }
                                : null,
                            child: Center(
                              child: Text(
                                station.isAvailable ? 'Reservar' : 'Indisponível',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: station.isAvailable
                                      ? Colors.white
                                      : textSub,
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
