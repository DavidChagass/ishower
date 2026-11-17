import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/custom_primary_button.dart';
import '../../auth/services/auth_service.dart';
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
  String _orderFilter = 'todos'; // 'todos' | 'ativo' | 'usado'
  List<Station> _stations = [];
  bool _loadingStations = false;

  @override
  void initState() {
    super.initState();
    _refreshData();
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
    final order = await _orderService.validateOrderAsync(rawInput);
    if (!mounted) return;
    setState(() => _isValidating = false);

    if (order != null) {
      _codeController.clear();
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
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
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    sourceLabel,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
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
              const SizedBox(height: 4),
              Text(
                'Código: ${order.textCode}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Horário: ${order.scheduledTime ?? "Entrada Imediata"} · Valor: ${Formatters.formatCurrency(order.totalPrice)}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              const Text('Adicionais solicitados:'),
              const SizedBox(height: 8),
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
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
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
        const SnackBar(
          content: Text('Código inválido, pertence a outro posto ou já foi utilizado.'),
          backgroundColor: Colors.red,
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
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Widget _buildScannerPage(BuildContext context) {
    final session = AuthService().currentSession;
    final isManager = session != null && !session.isSuperAdmin;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.admin_panel_settings,
            size: 72,
            color: AppColors.primary,
          ),
          const SizedBox(height: 16),
          Text(
            isManager ? 'Recepção do Posto' : 'Área do Administrador',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            isManager && session.stationName != null
                ? 'Escopo vinculado: ${session.stationName}'
                : 'Insira o código do pedido manualmente ou faça a leitura do QR Code do cliente para liberar o uso do chuveiro.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 36),
          TextField(
            controller: _codeController,
            decoration: const InputDecoration(
              labelText: 'Código do Pedido',
              hintText: 'Ex: 749281',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.password),
            ),
          ),
          const SizedBox(height: 16),
          CustomPrimaryButton(
            text: _isValidating ? 'Validando...' : 'Validar Código',
            onPressed: _isValidating ? null : () => _validateCode(_codeController.text),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _openScanner,
              icon: const Icon(Icons.qr_code_scanner, color: AppColors.primary),
              label: const Text(
                'Ler QR Code (Câmera)',
                style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                side: const BorderSide(color: AppColors.primary, width: 1.5),
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
      if (_orderFilter == 'ativo') return o.status.toLowerCase() == 'ativo';
      if (_orderFilter == 'usado') return o.status.toLowerCase() != 'ativo';
      return true;
    }).toList();

    final activeCount = allOrders.where((o) => o.status.toLowerCase() == 'ativo').length;
    final usedCount = allOrders.length - activeCount;

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
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Acompanhe todos os QR Codes gerados e validados na recepção.',
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
        Padding(
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
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final order = filtered[index];
                    final isAtivo = order.status.toLowerCase() == 'ativo';
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
                                    const Icon(Icons.qr_code, size: 18, color: AppColors.primary),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Código: ${order.textCode}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isAtivo
                                        ? Colors.green.withValues(alpha: 0.15)
                                        : Colors.grey.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    isAtivo ? 'ATIVO' : 'USADO',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isAtivo ? Colors.green : Colors.grey,
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
                                fontWeight: order.extras.isEmpty ? FontWeight.normal : FontWeight.bold,
                                color: order.extras.isEmpty ? Colors.grey : AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  onPressed: () => QrCodeSheet.show(context, order),
                                  icon: const Icon(Icons.visibility_outlined, size: 16),
                                  label: const Text('Ver QR Code'),
                                ),
                                if (isAtivo) ...[
                                  const SizedBox(width: 8),
                                  ElevatedButton.icon(
                                    onPressed: () => _validateCode(
                                      order.qrCodeData,
                                      sourceLabel: 'Validado na Lista de Reservas',
                                    ),
                                    icon: const Icon(Icons.check_circle_outline, size: 16),
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
      ],
    );
  }

  Widget _buildStationsAdminPage(BuildContext context) {
    final session = AuthService().currentSession;
    final isManager = session != null && !session.isSuperAdmin;

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
                      isManager ? 'Meu Posto Credenciado' : 'Gestão de Postos Credenciados',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isManager
                          ? 'Controle a disponibilidade operacional e serviços da sua unidade.'
                          : 'Controle a disponibilidade operacional e confira os serviços de cada unidade.',
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
              : ListView.builder(
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
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: st.isAvailable
                                        ? Colors.green.withValues(alpha: 0.15)
                                        : Colors.orange.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    st.isAvailable ? 'DISPONÍVEL' : 'INDISPONÍVEL',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: st.isAvailable ? Colors.green : Colors.orange,
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
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              st.services.isEmpty
                                  ? 'Adicionais: Padrão (Toalha, Sabonete)'
                                  : 'Adicionais: ${st.services.map((s) => "${s.name} (${Formatters.formatCurrency(s.price)})").join(", ")}',
                              style: const TextStyle(fontSize: 12, color: AppColors.primary),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${st.availableTimeSlots.length} faixas de horário',
                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                                ),
                                OutlinedButton.icon(
                                  onPressed: () => _toggleStationStatus(st),
                                  icon: Icon(
                                    st.isAvailable ? Icons.pause_circle_outline : Icons.play_circle_outline,
                                    size: 16,
                                  ),
                                  label: Text(
                                    st.isAvailable ? 'Pausar Atendimento' : 'Ativar Atendimento',
                                  ),
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
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: IndexedStack(
            index: _adminTabIndex,
            children: [
              _buildScannerPage(context),
              _buildOrdersAdminPage(context),
              _buildStationsAdminPage(context),
            ],
          ),
        ),
        NavigationBar(
          selectedIndex: _adminTabIndex,
          onDestinationSelected: (idx) => setState(() => _adminTabIndex = idx),
          height: 64,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.qr_code_scanner_outlined),
              selectedIcon: Icon(Icons.qr_code_scanner),
              label: 'Leitor QR',
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long),
              label: 'Reservas',
            ),
            NavigationDestination(
              icon: Icon(Icons.storefront_outlined),
              selectedIcon: Icon(Icons.storefront),
              label: 'Postos Admin',
            ),
          ],
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
