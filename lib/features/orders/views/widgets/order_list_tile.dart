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
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.shower, color: AppColors.primary),
        ),
        title: Text(
          order.station.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Data: ${Formatters.formatDate(order.date)}',
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              'Status: ${order.status.toUpperCase()}',
              style: const TextStyle(
                color: AppColors.statusAvailable,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.qr_code, color: AppColors.primary, size: 32),
          onPressed: () => QrCodeSheet.show(context, order),
        ),
      ),
    );
  }
}
