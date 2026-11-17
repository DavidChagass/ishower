import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/custom_primary_button.dart';
import '../services/order_service.dart';
import 'widgets/order_list_tile.dart';

class OrdersView extends StatefulWidget {
  final VoidCallback? onExploreStations;

  const OrdersView({super.key, this.onExploreStations});

  @override
  State<OrdersView> createState() => _OrdersViewState();
}

class _OrdersViewState extends State<OrdersView> {
  final OrderService _orderService = OrderService();

  @override
  void initState() {
    super.initState();
    _refreshOrders();
  }

  Future<void> _refreshOrders() async {
    await _orderService.fetchOrders();
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final orders = _orderService.orders;
    final canPop = Navigator.canPop(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryOrder = orders.isNotEmpty ? orders.first : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Pedidos & QR Code'),
        leading: canPop
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar pedidos',
            onPressed: _refreshOrders,
          ),
        ],
      ),
      body: orders.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.qr_code_2_rounded,
                      size: 56,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Nenhum pedido realizado ainda.',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                    const SizedBox(height: 20),
                    if (widget.onExploreStations != null)
                      CustomPrimaryButton(
                        height: 44,
                        text: 'Ver Chuveiros Próximos',
                        icon: Icons.shower,
                        onPressed: widget.onExploreStations,
                      ),
                  ],
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: _refreshOrders,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_orderService.isTestMockMode && primaryOrder != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surface : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.45),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.verified_outlined,
                                size: 18,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'QR Code Único do Cliente (${primaryOrder.status.toUpperCase()})',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            primaryOrder.station.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: QrImageView(
                              data: primaryOrder.qrCodeData,
                              version: QrVersions.auto,
                              size: 180.0,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            primaryOrder.textCode,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 6,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Horário: ${primaryOrder.scheduledTime ?? "Entrada Imediata"} · Total: ${Formatters.formatCurrency(primaryOrder.totalPrice)}',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          if (primaryOrder.extras.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Adicionais: ${primaryOrder.extras.join(", ")}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ...orders.map((order) => OrderListTile(order: order)),
                ],
              ),
            ),
    );
  }
}
