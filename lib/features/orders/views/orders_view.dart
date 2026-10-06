import 'package:flutter/material.dart';
import '../services/order_service.dart';
import 'widgets/order_list_tile.dart';

class OrdersView extends StatefulWidget {
  const OrdersView({super.key});

  @override
  State<OrdersView> createState() => _OrdersViewState();
}

class _OrdersViewState extends State<OrdersView> {
  final OrderService _orderService = OrderService();

  @override
  Widget build(BuildContext context) {
    final orders = _orderService.orders;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Pedidos'),
      ),
      body: orders.isEmpty
          ? const Center(
              child: Text(
                'Nenhum pedido realizado ainda.',
                style: TextStyle(color: Colors.grey, fontSize: 16),
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
