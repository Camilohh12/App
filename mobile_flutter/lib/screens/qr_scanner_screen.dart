import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../models/order.dart';
import '../models/table_model.dart';
import '../providers/table_provider.dart';
import 'new_order_screen.dart';

/// Escanea el código QR de una mesa y abre una nueva orden con esa
/// mesa preseleccionada. Requiere permiso de cámara (ver
/// AndroidManifest.xml / Info.plist).
class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController controller = MobileScannerController();
  bool _processing = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _handleDetection(BarcodeCapture capture) {
    if (_processing) return;

    final code = capture.barcodes.isNotEmpty
        ? capture.barcodes.first.rawValue
        : null;

    if (code == null) return;

    setState(() => _processing = true);

    final table = context.read<TableProvider>().findByQrCode(code);

    if (table == null) {
      _showTemporaryError(
        'Este código QR no pertenece a ninguna mesa registrada',
      );
      return;
    }

    if (table.status == TableStatus.occupied) {
      _showTemporaryError('La mesa ${table.number} ya está ocupada');
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => NewOrderScreen(
          initialServiceType: ServiceType.dineIn,
          initialTableId: table.id,
        ),
      ),
    );
  }

  void _showTemporaryError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _processing = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear mesa'),
        actions: [
          IconButton(
            tooltip: 'Linterna',
            onPressed: () => controller.toggleTorch(),
            icon: const Icon(Icons.flash_on),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: _handleDetection,
            errorBuilder: (context, error) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.no_photography,
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No fue posible acceder a la cámara.\n'
                            'Verifica que el permiso de cámara esté '
                            'habilitado para ComandaPOS en los '
                            'ajustes del dispositivo.',
                        textAlign: TextAlign.center,
                      ),
                      if (error.errorDetails?.message != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          error.errorDetails!.message!,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
          const Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'Apunta la cámara al código QR de la mesa',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
