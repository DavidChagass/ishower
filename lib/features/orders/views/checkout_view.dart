import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/custom_primary_button.dart';
import '../../stations/models/station_model.dart';
import '../models/order_model.dart';
import '../services/order_service.dart';

class CheckoutView extends StatelessWidget {
  final Station station;

  const CheckoutView({super.key, required this.station});

  void _confirmReservation(BuildContext context) {
    final random = Random();
    final code = (100000 + random.nextInt(900000)).toString();

    final newOrder = OrderModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      station: station,
      qrCodeData: code,
      textCode: code,
      date: DateTime.now(),
    );

    OrderService().addOrder(newOrder);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reserva confirmada! Dirija-se ao caixa ou catraca.')),
    );
    Navigator.pop(context); 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirmar Reserva'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Resumo da Reserva', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[800]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(station.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(station.address, style: const TextStyle(color: AppColors.textSecondary)),
                  const Divider(height: 32, color: Colors.grey),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total a pagar', style: TextStyle(fontSize: 16)),
                      Text(
                        Formatters.formatCurrency(station.price), 
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary)
                      ),
                    ],
                  )
                ],
              ),
            ),
            const Spacer(),
            CustomPrimaryButton(
              text: 'Confirmar e Gerar Código',
              onPressed: () => _confirmReservation(context),
            )
          ],
        ),
      ),
    );
  }
}
