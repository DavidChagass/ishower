import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/custom_primary_button.dart';
import '../../models/order_model.dart';

class QrCodeSheet extends StatelessWidget {
  final OrderModel order;
  final VoidCallback? onCancel;

  const QrCodeSheet({
    super.key,
    required this.order,
    this.onCancel,
  });

  static void show(
    BuildContext context,
    OrderModel order, {
    VoidCallback? onCancel,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => QrCodeSheet(order: order, onCancel: onCancel),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryBlue = isDark ? AppColors.buttonSky : AppColors.primary;
    final textPrimary = isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final textSub = isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;

    final statusColor = order.isActive
        ? AppColors.statusAvailable
        : order.isCancelled
            ? AppColors.statusBusy
            : textSub;

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
            Text(
              'Seu Código de Acesso',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              order.station.name,
              style: TextStyle(fontSize: 13.5, color: textSub),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                order.status.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: statusColor,
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Always white background around QR Code for optical contrast
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
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
              style: TextStyle(color: textSub, fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              order.textCode,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: 6,
                color: primaryBlue,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surface : AppColors.lightSurface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.accentGold.withValues(alpha: 0.6),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.timer_outlined,
                    size: 14,
                    color: AppColors.accentGold,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Tempo de banho: ${order.station.maxShowerMinutes} min · ${Formatters.formatCurrency(order.totalPrice)}',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.accentGold,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            if (order.extras.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Adicionais: ${order.extras.join(", ")}',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: primaryBlue,
                ),
              ),
            ],
            const SizedBox(height: 18),
            if (order.isActive && onCancel != null) ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    onCancel!();
                  },
                  icon: const Icon(Icons.cancel_outlined, size: 17),
                  label: const Text('Cancelar Reserva e Estornar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.statusBusy,
                    side: const BorderSide(color: AppColors.statusBusy),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
            CustomPrimaryButton(
              height: 46,
              text: 'Fechar',
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}
