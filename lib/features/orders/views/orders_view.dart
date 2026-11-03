import 'package:flutter/material.dart';
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
  Widget build(BuildContext context) {
    final orders = _orderService.orders;
    final canPop = Navigator.canPop(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Pedidos & QR Code'),
        leading: canPop
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              )
            : null,
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
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                return OrderListTile(order: orders[index]);
              },
            ),
    );
  }
}
