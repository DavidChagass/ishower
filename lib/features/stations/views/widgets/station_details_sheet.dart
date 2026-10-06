import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/custom_primary_button.dart';
import '../../models/station_model.dart';
import '../../../orders/views/checkout_view.dart';

class StationDetailsSheet extends StatelessWidget {
  final Station station;

  const StationDetailsSheet({super.key, required this.station});

  static void show(BuildContext context, Station station) {
    showModalBottomSheet(
      context: context,
      builder: (_) => StationDetailsSheet(station: station),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            station.name,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(station.address, style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                Formatters.formatCurrency(station.price),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: station.isAvailable
                      ? AppColors.statusAvailableBackground
                      : AppColors.statusBusyBackground,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  station.isAvailable ? 'Livre' : 'Ocupado',
                  style: TextStyle(
                    color: station.isAvailable ? AppColors.statusAvailable : AppColors.statusBusy,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          CustomPrimaryButton(
            text: 'Reservar Chuveiro',
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
        ],
      ),
    );
  }
}
