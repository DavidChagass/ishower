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
      builder: (_) => QrCodeSheet(order: order),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Seu Código de Acesso',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: QrImageView(
              data: order.qrCodeData,
              version: QrVersions.auto,
              size: 200.0,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Ou utilize o código numérico:',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            order.textCode,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: 8,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          CustomPrimaryButton(
            text: 'Fechar',
            onPressed: () => Navigator.pop(context),
          )
        ],
      ),
    );
  }
}
