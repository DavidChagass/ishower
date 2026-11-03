import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/custom_primary_button.dart';
import '../../stations/models/station_model.dart';
import '../models/order_model.dart';
import '../services/order_service.dart';

class CheckoutView extends StatefulWidget {
  final Station station;

  const CheckoutView({super.key, required this.station});

  @override
  State<CheckoutView> createState() => _CheckoutViewState();
}

class _CheckoutViewState extends State<CheckoutView> {
  bool _wantsTowel = false;
  bool _wantsSoap = false;

  final double _towelPrice = 5.0;
  final double _soapPrice = 2.0;

  double get _totalPrice {
    double total = widget.station.price;
    if (_wantsTowel) total += _towelPrice;
    if (_wantsSoap) total += _soapPrice;
    return total;
  }

  void _confirmReservation(BuildContext context) {
    final random = Random();
    final code = (100000 + random.nextInt(900000)).toString();

    final List<String> extras = [];
    if (_wantsTowel) extras.add('Toalha');
    if (_wantsSoap) extras.add('Sabonete');

    final newOrder = OrderModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      station: widget.station,
      qrCodeData: code,
      textCode: code,
      date: DateTime.now(),
      totalPrice: _totalPrice,
      extras: extras,
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                  Text(widget.station.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(widget.station.address, style: const TextStyle(color: AppColors.textSecondary)),
                  const Divider(height: 24, color: Colors.grey),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Valor do Chuveiro', style: TextStyle(fontSize: 16)),
                      Text(
                        Formatters.formatCurrency(widget.station.price), 
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)
                      ),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text('Adicionais', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            CheckboxListTile(
              title: const Text('Toalha'),
              subtitle: Text('+ ${Formatters.formatCurrency(_towelPrice)}'),
              value: _wantsTowel,
              activeColor: AppColors.primary,
              onChanged: (val) => setState(() => _wantsTowel = val ?? false),
            ),
            CheckboxListTile(
              title: const Text('Sabonete'),
              subtitle: Text('+ ${Formatters.formatCurrency(_soapPrice)}'),
              value: _wantsSoap,
              activeColor: AppColors.primary,
              onChanged: (val) => setState(() => _wantsSoap = val ?? false),
            ),
            const SizedBox(height: 48),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total a pagar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(
                  Formatters.formatCurrency(_totalPrice), 
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primary)
                ),
              ],
            ),
            const SizedBox(height: 24),
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
