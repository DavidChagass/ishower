import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_primary_button.dart';
import '../models/order_model.dart';
import '../services/order_service.dart';
import 'widgets/order_list_tile.dart';

class OrdersView extends StatefulWidget {
  final VoidCallback? onExploreStations;
  final bool embedded;

  const OrdersView({
    super.key,
    this.onExploreStations,
    this.embedded = false,
  });

  @override
  State<OrdersView> createState() => _OrdersViewState();
}

class _OrdersViewState extends State<OrdersView> {
  final OrderService _orderService = OrderService();
  String _statusFilter = 'todos'; // 'todos' | 'ativo' | 'usado' | 'cancelado'

  @override
  void initState() {
    super.initState();
    _orderService.ordersVersion.addListener(_onOrdersUpdated);
    _refreshOrders();
  }

  @override
  void dispose() {
    _orderService.ordersVersion.removeListener(_onOrdersUpdated);
    super.dispose();
  }

  void _onOrdersUpdated() {
    if (mounted) setState(() {});
  }

  Future<void> _refreshOrders() async {
    await _orderService.fetchOrders();
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _confirmCancel(OrderModel order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Cancelar reserva #${order.textCode}?'),
        content: Text(
          'A reserva no ${order.station.name} será cancelada e o valor será estornado para sua carteira iShower.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Manter'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusBusy,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirmar cancelamento'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _orderService.cancelOrder(order);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reserva cancelada e valor estornado na carteira!'),
          backgroundColor: AppColors.statusAvailable,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.statusBusy,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final allOrders = _orderService.orders;
    final filtered = allOrders.where((o) {
      if (_statusFilter == 'todos') return true;
      return o.status.toLowerCase() == _statusFilter;
    }).toList();
    final canPop = Navigator.canPop(context);

    final content = Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
          child: Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ChoiceChip(
                        label: Text('Todos (${allOrders.length})'),
                        selected: _statusFilter == 'todos',
                        onSelected: (_) => setState(() => _statusFilter = 'todos'),
                      ),
                      const SizedBox(width: 6),
                      ChoiceChip(
                        label: const Text('Ativos'),
                        selected: _statusFilter == 'ativo',
                        onSelected: (_) => setState(() => _statusFilter = 'ativo'),
                      ),
                      const SizedBox(width: 6),
                      ChoiceChip(
                        label: const Text('Usados'),
                        selected: _statusFilter == 'usado',
                        onSelected: (_) => setState(() => _statusFilter = 'usado'),
                      ),
                      const SizedBox(width: 6),
                      ChoiceChip(
                        label: const Text('Cancelados'),
                        selected: _statusFilter == 'cancelado',
                        onSelected: (_) => setState(() => _statusFilter = 'cancelado'),
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Atualizar pedidos',
                onPressed: _refreshOrders,
              ),
            ],
          ),
        ),
        Expanded(
          child: filtered.isEmpty
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
                        const SizedBox(height: 14),
                        Text(
                          allOrders.isEmpty
                              ? 'Nenhum pedido realizado ainda.'
                              : 'Nenhuma reserva encontrada neste filtro.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.grey, fontSize: 15),
                        ),
                        const SizedBox(height: 18),
                        if (widget.onExploreStations != null && allOrders.isEmpty)
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
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final order = filtered[index];
                      return OrderListTile(
                        order: order,
                        onCancel: order.isActive ? () => _confirmCancel(order) : null,
                      );
                    },
                  ),
                ),
        ),
      ],
    );

    if (widget.embedded) {
      return content;
    }

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
      body: content,
    );
  }
}
