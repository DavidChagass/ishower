import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/custom_primary_button.dart';
import '../../auth/services/auth_service.dart';
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
  String _paymentMethod = 'wallet'; // 'wallet' | 'pix'
  String? _errorMessage;

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
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final List<String> extras = _availableServices
        .where((srv) => _selectedServiceNames.contains(srv.name))
        .map((srv) => srv.name)
        .toList();

    try {
      final newOrder = await OrderService().createOrder(
        station: widget.station,
        extras: extras,
        totalPrice: _totalPrice,
        scheduledTime: _currentSchedule,
        paymentMethod: _paymentMethod,
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
        const SnackBar(
          content: Text('Reserva confirmada! Dirija-se ao caixa ou catraca.'),
          backgroundColor: AppColors.statusAvailable,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '');
      setState(() {
        _isSubmitting = false;
        _errorMessage = msg;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: AppColors.statusBusy,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryBlue = isDark ? AppColors.buttonSky : AppColors.primary;
    final cardBg = isDark ? AppColors.cardBackground : AppColors.lightCard;
    final borderCol = isDark ? AppColors.border : AppColors.lightBorder;
    final textCol = isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final textSub = isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;
    final walletBalance = AuthService().currentSession?.balance ?? 150.0;
    final insufficientWallet = _paymentMethod == 'wallet' && walletBalance < _totalPrice;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirmar Reserva'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_errorMessage != null) ...[
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.statusBusyBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.statusBusy.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(
                    color: AppColors.statusBusy,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            Text(
              'Resumo da Reserva',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: textCol),
            ),
            const SizedBox(height: 14),
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
                  Text(
                    widget.station.name,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: textCol,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.station.address,
                    style: TextStyle(color: textSub, fontSize: 13),
                  ),
                  Divider(height: 24, color: borderCol),
                  _summaryRow('Horário:', _currentSchedule, textSub, primaryBlue, bold: true),
                  const SizedBox(height: 8),
                  _summaryRow(
                    'Tempo de banho:',
                    '${widget.station.maxShowerMinutes} minutos limite',
                    textSub,
                    AppColors.accentGold,
                    bold: true,
                  ),
                  const SizedBox(height: 8),
                  _summaryRow(
                    'Limpeza pós-uso:',
                    '${widget.station.cleaningDuration} higienização',
                    textSub,
                    textSub,
                  ),
                  Divider(height: 24, color: borderCol),
                  _summaryRow(
                    'Valor do Chuveiro',
                    Formatters.formatCurrency(widget.station.price),
                    textSub,
                    textCol,
                    bold: true,
                    valueSize: 16,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Text(
              'Adicionais',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: textCol),
            ),
            const SizedBox(height: 10),
            Material(
              color: cardBg,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: borderCol),
              ),
              child: Column(
                children: [
                  for (int i = 0; i < _availableServices.length; i++) ...[
                    if (i > 0) Divider(height: 1, color: borderCol),
                    CheckboxListTile(
                      title: Text(
                        _availableServices[i].name,
                        style: TextStyle(color: textCol, fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        _availableServices[i].description.isNotEmpty
                            ? '${_availableServices[i].description} · + ${Formatters.formatCurrency(_availableServices[i].price)}'
                            : '+ ${Formatters.formatCurrency(_availableServices[i].price)}',
                        style: TextStyle(color: primaryBlue, fontSize: 12.5),
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
            const SizedBox(height: 20),
            Text(
              'Forma de Pagamento (Simulação)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textCol),
            ),
            const SizedBox(height: 10),
            Material(
              color: cardBg,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: borderCol),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => setState(() => _paymentMethod = 'wallet'),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                        child: Row(
                          children: [
                            Icon(
                              _paymentMethod == 'wallet'
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_off,
                              color: primaryBlue,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Saldo Carteira iShower',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: textCol,
                                    ),
                                  ),
                                  Text(
                                    'Disponível: ${Formatters.formatCurrency(walletBalance)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: insufficientWallet
                                          ? AppColors.statusBusy
                                          : textSub,
                                      fontWeight: insufficientWallet
                                          ? FontWeight.w700
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Divider(height: 8, color: borderCol),
                    InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => setState(() => _paymentMethod = 'pix'),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                        child: Row(
                          children: [
                            Icon(
                              _paymentMethod == 'pix'
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_off,
                              color: primaryBlue,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'PIX Instantâneo (Mockup)',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: textCol,
                                    ),
                                  ),
                                  Text(
                                    'Aprovação imediata para geração do QR Code',
                                    style: TextStyle(fontSize: 12, color: textSub),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 22),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total a pagar',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: textCol,
                  ),
                ),
                Text(
                  Formatters.formatCurrency(_totalPrice),
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: primaryBlue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            CustomPrimaryButton(
              height: 48,
              text: _isSubmitting
                  ? 'Registrando Pedido...'
                  : 'Confirmar e Gerar Código',
              icon: Icons.qr_code,
              onPressed: _isSubmitting ? null : () => _confirmReservation(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(
    String label,
    String value,
    Color labelColor,
    Color valueColor, {
    bool bold = false,
    double valueSize = 14,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: labelColor)),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: valueSize,
              fontWeight: bold ? FontWeight.w700 : FontWeight.normal,
              color: valueColor,
            ),
          ),
        ),
      ],
    );
  }
}
