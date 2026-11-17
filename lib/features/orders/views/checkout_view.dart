import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/custom_primary_button.dart';
import '../../stations/models/station_model.dart';
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
  late List<StationServiceItem> _availableServices;
  final Set<String> _selectedServiceNames = {};
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _currentSchedule = widget.scheduledTime ?? 'Entrada Imediata';
    final activeServices = widget.station.services.where((s) => s.active).toList();
    if (activeServices.isNotEmpty) {
      _availableServices = activeServices;
    } else {
      _availableServices = const [
        StationServiceItem(
          id: 'default-towel',
          name: 'Toalha',
          description: 'Toalha de banho higienizada',
          priceCents: 500,
        ),
        StationServiceItem(
          id: 'default-soap',
          name: 'Sabonete',
          description: 'Sabonete individual',
          priceCents: 200,
        ),
      ];
    }
  }

  double get _totalPrice {
    double total = widget.station.price;
    for (final srv in _availableServices) {
      if (_selectedServiceNames.contains(srv.name)) {
        total += srv.price;
      }
    }
    return total;
  }

  Future<void> _confirmReservation(BuildContext context) async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    final List<String> extras = _availableServices
        .where((srv) => _selectedServiceNames.contains(srv.name))
        .map((srv) => srv.name)
        .toList();

    final newOrder = await OrderService().createOrder(
      station: widget.station,
      extras: extras,
      totalPrice: _totalPrice,
      scheduledTime: _currentSchedule,
    );

    if (!context.mounted) return;
    setState(() => _isSubmitting = false);

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
      body: SingleChildScrollView(
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

                  // Regras: tempo limite de banho + limpeza
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Tempo de banho:', style: TextStyle(fontSize: 14, color: textSub)),
                      Text(
                        '${widget.station.maxShowerMinutes} minutos limite',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.accentGold),
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
                      Text('Valor do Chuveiro', style: TextStyle(fontSize: 15, color: textSub)),
                      Text(
                        Formatters.formatCurrency(widget.station.price),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textCol,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text('Adicionais', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textCol)),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderCol),
              ),
              child: Column(
                children: [
                  for (int i = 0; i < _availableServices.length; i++) ...[
                    if (i > 0) Divider(height: 1, color: borderCol),
                    CheckboxListTile(
                      title: Text(
                        _availableServices[i].name,
                        style: TextStyle(color: textCol, fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(
                        _availableServices[i].description.isNotEmpty
                            ? '${_availableServices[i].description} · + ${Formatters.formatCurrency(_availableServices[i].price)}'
                            : '+ ${Formatters.formatCurrency(_availableServices[i].price)}',
                        style: TextStyle(color: primaryBlue),
                      ),
                      value: _selectedServiceNames.contains(_availableServices[i].name),
                      activeColor: primaryBlue,
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            _selectedServiceNames.add(_availableServices[i].name);
                          } else {
                            _selectedServiceNames.remove(_availableServices[i].name);
                          }
                        });
                      },
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total a pagar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textCol)),
                Text(
                  Formatters.formatCurrency(_totalPrice),
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: primaryBlue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            CustomPrimaryButton(
              height: 48,
              text: _isSubmitting ? 'Registrando Pedido...' : 'Confirmar e Gerar Código',
              icon: Icons.qr_code,
              onPressed: _isSubmitting ? null : () => _confirmReservation(context),
            ),
          ],
        ),
      ),
    );
  }
}
