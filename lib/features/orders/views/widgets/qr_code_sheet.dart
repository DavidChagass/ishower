import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_primary_button.dart';
import '../../models/order_model.dart';

class QrCodeSheet extends StatelessWidget {
  final OrderModel order;

  const QrCodeSheet({super.key, required this.order});

  static void show(BuildContext context, OrderModel order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => QrCodeSheet(order: order),
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
          Text(
            'Seu Código de Acesso',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            order.station.name,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: QrImageView(
              data: order.qrCodeData,
              version: QrVersions.auto,
              size: 190.0,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Ou utilize o código numérico:',
            style: TextStyle(
              color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            order.textCode,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: 6,
              color: primaryBlue,
            ),
          ),
          const SizedBox(height: 6),
          // Destaque de 25 min de banho
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? Colors.black : AppColors.lightSurface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.accentGold.withValues(alpha: 0.6)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.timer_outlined, size: 14, color: AppColors.accentGold),
                SizedBox(width: 5),
                Text(
                  'Tempo de banho: 25 min (limite da catraca)',
                  style: TextStyle(fontSize: 11, color: AppColors.accentGold, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          CustomPrimaryButton(
            height: 46,
            text: 'Fechar',
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
