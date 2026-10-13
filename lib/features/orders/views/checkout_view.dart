import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/custom_primary_button.dart';
import '../../stations/models/station_model.dart';
import '../models/order_model.dart';
import '../services/order_service.dart';
import 'widgets/qr_code_sheet.dart';

class CheckoutView extends StatefulWidget {
  final Station station;
  final String? scheduledTime;

  const CheckoutView({
    super.key,
    required this.station,
    this.scheduledTime,
  });

  @override
  State<CheckoutView> createState() => _CheckoutViewState();
}

class _CheckoutViewState extends State<CheckoutView> {
  late String _currentSchedule;

  @override
  void initState() {
    super.initState();
    _currentSchedule = widget.scheduledTime ?? 'Entrada Imediata';
  }

  void _confirmReservation(BuildContext context) {
    final random = Random();
    final code = (100000 + random.nextInt(900000)).toString();

    final newOrder = OrderModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      station: widget.station,
      qrCodeData: code,
      textCode: code,
      date: DateTime.now(),
      scheduledTime: _currentSchedule,
    );

    OrderService().addOrder(newOrder);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => QrCodeSheet(order: newOrder),
    ).then((_) {
      if (context.mounted) {
        Navigator.pop(context);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reserva confirmada! Dirija-se ao caixa ou catraca.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryBlue = isDark ? AppColors.buttonSky : AppColors.buttonBlue;
    final cardBg = isDark ? AppColors.cardBackground : AppColors.lightCard;
    final borderCol = isDark ? AppColors.border : AppColors.lightBorder;
    final textCol = isDark ? Colors.white : AppColors.lightTextPrimary;
    final textSub = isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;

    return Scaffold(
      backgroundColor: isDark ? AppColors.background : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Confirmar Reserva'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Resumo da Reserva', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textCol)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderCol),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.station.name, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: textCol)),
                  const SizedBox(height: 6),
                  Text(widget.station.address, style: TextStyle(color: textSub, fontSize: 13)),
                  Divider(height: 24, color: borderCol),

                  // Horário
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Horário:', style: TextStyle(fontSize: 14, color: textSub)),
                      Text(
                        _currentSchedule,
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: primaryBlue),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Regras: 25 min banho + limpeza
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Tempo de banho:', style: TextStyle(fontSize: 14, color: textSub)),
                      const Text(
                        '25 minutos limite',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.accentGold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Limpeza pós-uso:', style: TextStyle(fontSize: 14, color: textSub)),
                      Text(
                        '${widget.station.cleaningDuration} higienização',
                        style: TextStyle(fontSize: 13, color: textSub),
                      ),
                    ],
                  ),
                  Divider(height: 24, color: borderCol),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total a pagar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textCol)),
                      Text(
                        Formatters.formatCurrency(widget.station.price),
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: primaryBlue,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Spacer(),
            CustomPrimaryButton(
              height: 48,
              text: 'Confirmar e Gerar Código',
              icon: Icons.qr_code,
              onPressed: () => _confirmReservation(context),
            ),
          ],
        ),
      ),
    );
  }
}
