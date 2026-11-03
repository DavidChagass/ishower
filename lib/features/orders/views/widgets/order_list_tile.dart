import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../models/order_model.dart';
import 'qr_code_sheet.dart';

class OrderListTile extends StatelessWidget {
  final OrderModel order;

  const OrderListTile({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryBlue = isDark ? AppColors.buttonSky : AppColors.buttonBlue;
    final isAtivo = order.status.toLowerCase() == 'ativo';

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      color: isDark ? AppColors.cardBackground : AppColors.lightCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isDark ? AppColors.border : AppColors.lightBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryDark.withValues(alpha: isDark ? 0.2 : 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.shower, color: primaryBlue, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.station.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: isDark ? Colors.white : AppColors.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Horário: ${order.scheduledTime ?? Formatters.formatDate(order.date)}',
                        style: TextStyle(
                          color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Total: ${Formatters.formatCurrency(order.totalPrice)}',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: primaryBlue,
                        ),
                      ),
                      if (order.extras.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Adicionais: ${order.extras.join(", ")}',
                          style: TextStyle(
                            color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isAtivo
                        ? AppColors.statusAvailableBackground
                        : Colors.red.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    order.status.toUpperCase(),
                    style: TextStyle(
                      color: isAtivo ? AppColors.statusAvailable : Colors.redAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            Divider(height: 20, color: isDark ? AppColors.border : AppColors.lightBorder),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.timer_outlined, size: 14, color: AppColors.accentGold),
                    SizedBox(width: 4),
                    Text(
                      'Limite: 25 min de banho',
                      style: TextStyle(fontSize: 12, color: AppColors.accentGold, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                SizedBox(
                  height: 34,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: AppColors.buttonGradient,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.buttonCyan.withValues(alpha: 0.6),
                        width: 0.8,
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => QrCodeSheet.show(context, order),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.qr_code, size: 16, color: Colors.white),
                              SizedBox(width: 6),
                              Text(
                                'Ver QR Code',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
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
