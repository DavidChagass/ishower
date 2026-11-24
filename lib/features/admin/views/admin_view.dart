import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/custom_primary_button.dart';
import '../../auth/services/auth_service.dart';
import '../../orders/models/order_model.dart';
import '../../orders/services/order_service.dart';
import '../../orders/views/widgets/qr_code_sheet.dart';
import '../../stations/models/station_model.dart';
import '../../stations/services/api_service.dart';

class AdminView extends StatefulWidget {
  final VoidCallback? onStationsChanged;

  const AdminView({super.key, this.onStationsChanged});

  @override
  State<AdminView> createState() => _AdminViewState();
}

class _AdminViewState extends State<AdminView> {
  final TextEditingController _codeController = TextEditingController();
  final OrderService _orderService = OrderService();
  final ApiService _apiService = ApiService();

  int _adminTabIndex = 0;
  bool _isValidating = false;
  String _orderFilter = 'todos'; // 'todos' | 'ativo' | 'usado' | 'cancelado'
  List<Station> _stations = [];
  bool _loadingStations = false;

  @override
  void initState() {
    super.initState();
    _orderService.ordersVersion.addListener(_onOrdersUpdated);
    _refreshData();
  }

  @override
  void dispose() {
    _orderService.ordersVersion.removeListener(_onOrdersUpdated);
    _codeController.dispose();
    super.dispose();
  }

  void _onOrdersUpdated() {
    if (mounted) setState(() {});
  }

  Future<void> _refreshData() async {
    setState(() => _loadingStations = true);
    await _orderService.fetchOrders();
    final stations = await _apiService.fetchAvailableStations();
    if (!mounted) return;
    setState(() {
      _stations = stations;
      _loadingStations = false;
    });
  }

  Future<void> _validateCode(String rawInput, {String? sourceLabel}) async {
    if (rawInput.trim().isEmpty || _isValidating) return;

    setState(() => _isValidating = true);
    final result = await _orderService.validateOrderDetailed(rawInput);
    if (!mounted) return;
    setState(() => _isValidating = false);

    final order = result.order;
    if (order != null) {
      _codeController.clear();
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: AppColors.statusAvailable),
              SizedBox(width: 8),
              Expanded(child: Text('Pedido Validado!')),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (sourceLabel != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    sourceLabel,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              Text(
                'Posto: ${order.station.name}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              if (order.driverName != null) ...[
                const SizedBox(height: 4),
                Text('Motorista: ${order.driverName}'),
              ],
              const SizedBox(height: 4),
              Text(
                'Código: ${order.textCode}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                'Horário: ${order.scheduledTime ?? "Entrada Imediata"} · Valor: ${Formatters.formatCurrency(order.totalPrice)}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 14),
              const Text('Adicionais solicitados:'),
              const SizedBox(height: 6),
              if (order.extras.isEmpty)
                const Text(
                  'Nenhum adicional.',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              if (order.extras.isNotEmpty)
                ...order.extras.map(
                  (extra) => Text(
                    '• $extra',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.errorMessage ??
                'Código inválido, pertence a outro posto ou já foi utilizado.',
          ),
          backgroundColor: AppColors.statusBusy,
        ),
      );
    }
  }

  Future<void> _confirmCancelOrder(OrderModel order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Cancelar pedido #${order.textCode}?'),
        content: Text(
          'A reserva no ${order.station.name} será cancelada e estornada ao motorista.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Voltar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusBusy,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancelar reserva'),
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
          content: Text('Reserva cancelada e valor estornado ao motorista.'),
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

  Future<void> _openScanner() async {
    final scannedCode = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => const ScannerPage(),
      ),
    );

    if (!mounted) return;

    if (scannedCode != null && scannedCode.trim().isNotEmpty) {
      final displayCode = OrderService.extractLookupCode(scannedCode);
      _codeController.text = displayCode;
      _validateCode(scannedCode, sourceLabel: 'Lido via Scanner de QR Code');
    }
  }

  Future<void> _toggleStationStatus(Station station) async {
    if (station.isAvailable) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Pausar ${station.name}?'),
          content: const Text(
            'Enquanto estiver indisponível, motoristas não poderão criar novas reservas neste posto.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.statusBusy,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Pausar atendimento'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    try {
      final updated = await _apiService.toggleStationAvailability(
        station,
        !station.isAvailable,
      );
      if (!mounted) return;
      setState(() {
        final idx = _stations.indexWhere((s) => s.id == station.id);
        if (idx >= 0) {
          _stations[idx] = updated;
        }
      });
      widget.onStationsChanged?.call();
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

  Future<void> _editStationPrice(Station station) async {
    final priceCtrl = TextEditingController(text: station.price.toStringAsFixed(2));
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Preço base · ${station.name}'),
        content: TextField(
          controller: priceCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Valor do banho (R\$)',
            prefixText: 'R\$ ',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Salvar preço'),
          ),
        ],
      ),
    );
    final raw = priceCtrl.text.replaceAll(',', '.').trim();
    priceCtrl.dispose();
    if (confirmed != true) return;

    final parsed = double.tryParse(raw);
    if (parsed == null || parsed < 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Informe um valor válido maior ou igual a zero.'),
          backgroundColor: AppColors.statusBusy,
        ),
      );
      return;
    }

    try {
      final updated = await _apiService.updateStation(station, price: parsed);
      if (!mounted) return;
      setState(() {
        final idx = _stations.indexWhere((s) => s.id == station.id);
        if (idx >= 0) {
          _stations[idx] = updated;
        }
      });
      widget.onStationsChanged?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Preço de ${station.name} atualizado para ${Formatters.formatCurrency(updated.price)}.',
          ),
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

  Widget _buildScannerPage(BuildContext context) {
    final session = AuthService().currentSession;
    final isScoped = session != null && !session.isSuperAdmin;
    final isOperator = session?.isOperator ?? false;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentBlue = isDark ? AppColors.buttonSky : AppColors.primary;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isOperator ? Icons.qr_code_scanner_rounded : Icons.admin_panel_settings,
            size: 68,
            color: accentBlue,
          ),
          const SizedBox(height: 16),
          Text(
            isScoped ? 'Recepção do Posto' : 'Área do Administrador',
            style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            isScoped && session.stationName != null
                ? 'Escopo vinculado: ${session.stationName}'
                : 'Insira o código do pedido manualmente ou faça a leitura do QR Code do cliente para liberar o uso do chuveiro.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _codeController,
            onSubmitted: (v) => _validateCode(v),
            decoration: const InputDecoration(
              labelText: 'Código do Pedido',
              hintText: 'Ex: 749281',
              prefixIcon: Icon(Icons.password),
            ),
          ),
          const SizedBox(height: 16),
          CustomPrimaryButton(
            text: _isValidating ? 'Validando...' : 'Validar Código',
            onPressed:
                _isValidating ? null : () => _validateCode(_codeController.text),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _openScanner,
              icon: Icon(Icons.qr_code_scanner, color: accentBlue),
              label: Text(
                'Ler QR Code (Câmera)',
                style: TextStyle(color: accentBlue, fontWeight: FontWeight.w700),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                side: BorderSide(color: accentBlue, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersAdminPage(BuildContext context) {
    final allOrders = _orderService.orders;
    final filtered = allOrders.where((o) {
      if (_orderFilter == 'todos') return true;
      return o.status.toLowerCase() == _orderFilter;
    }).toList();

    final activeCount = allOrders.where((o) => o.isActive).length;
    final usedCount =
        allOrders.where((o) => !o.isActive && !o.isCancelled).length;
    final cancelledCount = allOrders.where((o) => o.isCancelled).length;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentBlue = isDark ? AppColors.buttonSky : AppColors.primary;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reservas & Histórico de Leituras',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Acompanhe todos os QR Codes gerados, validados ou cancelados.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _refreshData,
                icon: const Icon(Icons.refresh),
                tooltip: 'Sincronizar reservas',
              ),
            ],
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              ChoiceChip(
                label: Text('Todos (${allOrders.length})'),
                selected: _orderFilter == 'todos',
                onSelected: (_) => setState(() => _orderFilter = 'todos'),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: Text('Ativos ($activeCount)'),
                selected: _orderFilter == 'ativo',
                onSelected: (_) => setState(() => _orderFilter = 'ativo'),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: Text('Usados ($usedCount)'),
                selected: _orderFilter == 'usado',
                onSelected: (_) => setState(() => _orderFilter = 'usado'),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: Text('Cancelados ($cancelledCount)'),
                selected: _orderFilter == 'cancelado',
                onSelected: (_) => setState(() => _orderFilter = 'cancelado'),
              ),
            ],
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? const Center(
                  child: Text(
                    'Nenhum pedido encontrado para este filtro.',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _refreshData,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final order = filtered[index];
                      final isAtivo = order.isActive;
                      final isCancelado = order.isCancelled;
                      final statusColor = isAtivo
                          ? AppColors.statusAvailable
                          : isCancelado
                              ? AppColors.statusBusy
                              : Colors.grey;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.qr_code, size: 18, color: accentBlue),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Código: ${order.textCode}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: statusColor.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      order.status.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: statusColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                order.station.name,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              if (order.driverName != null)
                                Text(
                                  'Motorista: ${order.driverName}',
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              Text(
                                'Horário: ${order.scheduledTime ?? "Entrada Imediata"} · Total: ${Formatters.formatCurrency(order.totalPrice)}',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                order.extras.isEmpty
                                    ? 'Adicionais: Nenhum adicional'
                                    : 'Adicionais: ${order.extras.join(", ")}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: order.extras.isEmpty
                                      ? FontWeight.normal
                                      : FontWeight.w700,
                                  color: order.extras.isEmpty ? Colors.grey : accentBlue,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                alignment: WrapAlignment.end,
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  TextButton.icon(
                                    onPressed: () => QrCodeSheet.show(context, order),
                                    icon: const Icon(Icons.visibility_outlined, size: 16),
                                    label: const Text('Ver QR Code'),
                                  ),
                                  if (isAtivo) ...[
                                    TextButton(
                                      onPressed: () => _confirmCancelOrder(order),
                                      style: TextButton.styleFrom(
                                        foregroundColor: AppColors.statusBusy,
                                      ),
                                      child: const Text('Cancelar'),
                                    ),
                                    ElevatedButton.icon(
                                      onPressed: () => _validateCode(
                                        order.qrCodeData,
                                        sourceLabel: 'Validado na Lista de Reservas',
                                      ),
                                      icon: const Icon(
                                        Icons.check_circle_outline,
                                        size: 16,
                                      ),
                                      label: const Text('Validar QR'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildStationsAdminPage(BuildContext context) {
    final session = AuthService().currentSession;
    final isManager = session != null && !session.isSuperAdmin;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentBlue = isDark ? AppColors.buttonSky : AppColors.primary;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isManager
                          ? 'Meu Posto Credenciado'
                          : 'Gestão de Postos Credenciados',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isManager
                          ? 'Controle a disponibilidade, preço e serviços da sua unidade.'
                          : 'Controle a disponibilidade operacional, preços e serviços da rede.',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _refreshData,
                icon: const Icon(Icons.refresh),
                tooltip: 'Atualizar postos',
              ),
            ],
          ),
        ),
        Expanded(
          child: _loadingStations
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _refreshData,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _stations.length,
                    itemBuilder: (context, index) {
                      final st = _stations[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      st.name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: st.isAvailable
                                          ? AppColors.statusAvailableBackground
                                          : AppColors.statusCleaningBackground,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      st.isAvailable ? 'DISPONÍVEL' : 'INDISPONÍVEL',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: st.isAvailable
                                            ? AppColors.statusAvailable
                                            : AppColors.accentGold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                st.address,
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Banho Base: ${Formatters.formatCurrency(st.price)} · Funcionamento: ${st.operatingHours}',
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                st.services.isEmpty
                                    ? 'Adicionais: Padrão (Toalha, Sabonete)'
                                    : 'Adicionais: ${st.services.map((s) => "${s.name} (${Formatters.formatCurrency(s.price)})").join(", ")}',
                                style: TextStyle(fontSize: 12, color: accentBlue),
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                alignment: WrapAlignment.spaceBetween,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  Text(
                                    '${st.availableTimeSlots.length} faixas · ${st.maxShowerMinutes} min',
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      OutlinedButton.icon(
                                        onPressed: () => _editStationPrice(st),
                                        icon: const Icon(Icons.attach_money, size: 16),
                                        label: const Text('Preço'),
                                      ),
                                      OutlinedButton.icon(
                                        onPressed: () => _toggleStationStatus(st),
                                        icon: Icon(
                                          st.isAvailable
                                              ? Icons.pause_circle_outline
                                              : Icons.play_circle_outline,
                                          size: 16,
                                        ),
                                        label: Text(
                                          st.isAvailable
                                              ? 'Pausar Atendimento'
                                              : 'Ativar Atendimento',
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = AuthService().currentSession;
    final canManageStations = session?.canManageStations ?? false;

    final pages = <Widget>[
      _buildScannerPage(context),
      _buildOrdersAdminPage(context),
      if (canManageStations) _buildStationsAdminPage(context),
    ];

    final destinations = <NavigationDestination>[
      const NavigationDestination(
        icon: Icon(Icons.qr_code_scanner_outlined),
        selectedIcon: Icon(Icons.qr_code_scanner),
        label: 'Leitor QR',
      ),
      const NavigationDestination(
        icon: Icon(Icons.receipt_long_outlined),
        selectedIcon: Icon(Icons.receipt_long),
        label: 'Reservas',
      ),
      if (canManageStations)
        const NavigationDestination(
          icon: Icon(Icons.storefront_outlined),
          selectedIcon: Icon(Icons.storefront),
          label: 'Postos Admin',
        ),
    ];

    final safeIndex = _adminTabIndex >= pages.length ? 0 : _adminTabIndex;

    return Column(
      children: [
        Expanded(
          child: IndexedStack(
            index: safeIndex,
            children: pages,
          ),
        ),
        NavigationBar(
          selectedIndex: safeIndex,
          onDestinationSelected: (idx) => setState(() => _adminTabIndex = idx),
          height: 64,
          destinations: destinations,
        ),
      ],
    );
  }
}

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  late MobileScannerController controller;
  bool _hasPopped = false;

  @override
  void initState() {
    super.initState();
    controller = MobileScannerController();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _completeScan(String code) {
    if (_hasPopped) return;
    _hasPopped = true;
    Navigator.pop(context, code);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ler QR Code'),
        actions: [
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: controller,
              builder: (context, state, child) {
                switch (state.torchState) {
                  case TorchState.off:
                    return const Icon(Icons.flash_off, color: Colors.grey);
                  case TorchState.on:
                    return const Icon(Icons.flash_on, color: Colors.yellow);
                  case TorchState.unavailable:
                    return const Icon(Icons.flash_off, color: Colors.red);
                  case TorchState.auto:
                    return const Icon(Icons.flash_auto, color: Colors.blue);
                }
              },
            ),
            onPressed: () => controller.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch),
            onPressed: () => controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                final String? code = barcodes.first.rawValue;
                if (code != null && code.trim().isNotEmpty) {
                  _completeScan(code);
                }
              }
            },
          ),
          Center(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primary, width: 3),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
