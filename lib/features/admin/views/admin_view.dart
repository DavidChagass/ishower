import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_primary_button.dart';
import '../../orders/services/order_service.dart';

class AdminView extends StatefulWidget {
  const AdminView({super.key});

  @override
  State<AdminView> createState() => _AdminViewState();
}

class _AdminViewState extends State<AdminView> {
  final TextEditingController _codeController = TextEditingController();
  final OrderService _orderService = OrderService();

  void _validateCode(String code) {
    if (code.isEmpty) return;
    
    final order = _orderService.validateOrder(code);
    if (order != null) {
      _codeController.clear();
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('Pedido Validado!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Código: ${order.textCode}', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              const Text('Adicionais solicitados:'),
              const SizedBox(height: 8),
              if (order.extras.isEmpty)
                const Text('Nenhum adicional.', style: TextStyle(fontStyle: FontStyle.italic)),
              if (order.extras.isNotEmpty)
                ...order.extras.map((extra) => Text('• $extra', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary))),
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
          content: Text('Código inválido, não encontrado ou já utilizado.'),
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

    if (scannedCode != null) {
      _codeController.text = scannedCode;
      _validateCode(scannedCode);
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.admin_panel_settings,
            size: 80,
            color: AppColors.primary,
          ),
          const SizedBox(height: 24),
          const Text(
            'Área do Administrador',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text(
            'Insira o código do pedido manualmente ou faça a leitura do QR Code do cliente para liberar o uso do chuveiro.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 48),
          TextField(
            controller: _codeController,
            decoration: const InputDecoration(
              labelText: 'Código do Pedido',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.password),
            ),
          ),
          const SizedBox(height: 16),
          CustomPrimaryButton(
            text: 'Validar Código',
            onPressed: () => _validateCode(_codeController.text),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: _openScanner,
            icon: const Icon(Icons.qr_code_scanner, color: AppColors.primary),
            label: const Text('Ler QR Code (Câmera)', style: TextStyle(color: AppColors.primary)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              side: const BorderSide(color: AppColors.primary),
            ),
          ),
        ],
      ),
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
      body: MobileScanner(
        controller: controller,
        onDetect: (capture) {
          final List<Barcode> barcodes = capture.barcodes;
          if (barcodes.isNotEmpty) {
            final String? code = barcodes.first.rawValue;
            if (code != null) {
              Navigator.pop(context, code);
            }
          }
        },
      ),
    );
  }
}
