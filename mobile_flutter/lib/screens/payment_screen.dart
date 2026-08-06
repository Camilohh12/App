import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/order.dart';
import '../providers/order_provider.dart';
import '../providers/product_provider.dart';
import '../providers/table_provider.dart';
import '../theme/app_colors.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
          (_) => context.read<OrderProvider>().refresh(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();
    final readyOrders = orderProvider.readyOrders;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cobro de órdenes'),
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<OrderProvider>().refresh(),
        child: _buildBody(orderProvider, readyOrders),
      ),
    );
  }

  Widget _buildBody(OrderProvider orderProvider, List<FoodOrder> readyOrders) {
    if (orderProvider.isLoading && readyOrders.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (orderProvider.errorMessage != null && readyOrders.isEmpty) {
      return _ErrorState(message: orderProvider.errorMessage!);
    }

    if (readyOrders.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 120),
          Center(
            child: Text(
              'No hay órdenes listas para cobrar',
              style: TextStyle(fontSize: 18),
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: readyOrders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final order = readyOrders[index];

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Orden #${order.id}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...order.items.map(
                      (item) => Text(
                    '${item.quantity} x ${item.product.name}',
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Total: \$${order.total.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PaymentDetailScreen(order: order),
                      ),
                    );
                  },
                  icon: const Icon(Icons.payments),
                  label: const Text('Cobrar'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;

  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 100),
        Icon(
          Icons.error_outline,
          size: 48,
          color: Theme.of(context).colorScheme.error,
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      ],
    );
  }
}

class PaymentDetailScreen extends StatefulWidget {
  final FoodOrder order;

  const PaymentDetailScreen({
    super.key,
    required this.order,
  });

  @override
  State<PaymentDetailScreen> createState() =>
      _PaymentDetailScreenState();
}

class _PaymentDetailScreenState
    extends State<PaymentDetailScreen> {
  PaymentMethod selectedMethod = PaymentMethod.cash;
  bool isProcessing = false;

  /// Monto en efectivo tecleado en centavos, ej. "1050" = $10.50.
  String cashCents = '0';

  double get amountReceived {
    if (selectedMethod != PaymentMethod.cash) {
      return widget.order.total;
    }

    return int.parse(cashCents) / 100;
  }

  double get change {
    if (selectedMethod != PaymentMethod.cash) {
      return 0;
    }

    return amountReceived - widget.order.total;
  }

  String paymentMethodText(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return 'Efectivo';
      case PaymentMethod.card:
        return 'Tarjeta';
      case PaymentMethod.transfer:
        return 'Transferencia';
    }
  }

  void tapDigit(String digit) {
    setState(() {
      final next = (cashCents == '0' ? '' : cashCents) + digit;
      // Máximo $999,999.99 para evitar desbordes de entrada.
      cashCents = next.length > 8 ? next.substring(0, 8) : next;
    });
  }

  void tapBackspace() {
    setState(() {
      cashCents = cashCents.length <= 1
          ? '0'
          : cashCents.substring(0, cashCents.length - 1);
    });
  }

  Future<void> confirmPayment() async {
    if (selectedMethod == PaymentMethod.cash &&
        amountReceived < widget.order.total) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'El monto recibido es menor al total',
          ),
        ),
      );
      return;
    }

    setState(() => isProcessing = true);

    final errorMessage =
    await context.read<OrderProvider>().completePayment(
      orderId: widget.order.id,
      paymentMethod: selectedMethod,
      amountReceived: amountReceived,
      productProvider: context.read<ProductProvider>(),
      tableProvider: context.read<TableProvider>(),
    );

    if (!mounted) return;

    if (errorMessage != null) {
      setState(() => isProcessing = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          selectedMethod == PaymentMethod.cash
              ? 'Pago registrado. Cambio: '
              '\$${change.toStringAsFixed(2)}'
              : 'Pago registrado correctamente',
        ),
      ),
    );

    Navigator.popUntil(
      context,
          (route) => route.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    final canConfirm = !isProcessing &&
        (selectedMethod != PaymentMethod.cash ||
            amountReceived >= widget.order.total);

    return Scaffold(
      appBar: AppBar(
        title: Text('Cobrar orden #${widget.order.id}'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total de la orden',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '\$${widget.order.total.toStringAsFixed(2)}',
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SegmentedButton<PaymentMethod>(
            segments: [
              ButtonSegment(
                value: PaymentMethod.cash,
                label: Text(paymentMethodText(PaymentMethod.cash)),
                icon: const Icon(Icons.payments),
              ),
              ButtonSegment(
                value: PaymentMethod.card,
                label: Text(paymentMethodText(PaymentMethod.card)),
                icon: const Icon(Icons.credit_card),
              ),
              ButtonSegment(
                value: PaymentMethod.transfer,
                label: Text(paymentMethodText(PaymentMethod.transfer)),
                icon: const Icon(Icons.account_balance),
              ),
            ],
            selected: {selectedMethod},
            onSelectionChanged: (selection) {
              setState(() {
                selectedMethod = selection.first;
                cashCents = '0';
              });
            },
          ),
          const SizedBox(height: 20),
          if (selectedMethod == PaymentMethod.cash) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  const Text(
                    'MONTO RECIBIDO',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '\$${amountReceived.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _Numpad(onDigit: tapDigit, onBackspace: tapBackspace),
            const SizedBox(height: 16),
          ],
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Cambio',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '\$${change.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: change < 0
                        ? AppColors.danger
                        : AppColors.secondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: canConfirm ? confirmPayment : null,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.secondary,
            ),
            icon: isProcessing
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
                : const Icon(Icons.check_circle),
            label: const Text('Finalizar pago'),
          ),
        ],
      ),
    );
  }
}

class _Numpad extends StatelessWidget {
  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;

  const _Numpad({required this.onDigit, required this.onBackspace});

  static const _keys = [
    '1', '2', '3',
    '4', '5', '6',
    '7', '8', '9',
    '', '0', '00',
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.6,
      children: _keys.map((key) {
        if (key.isEmpty) {
          return IconButton(
            onPressed: onBackspace,
            icon: const Icon(Icons.backspace_outlined),
          );
        }

        return Material(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => onDigit(key),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              alignment: Alignment.center,
              child: Text(
                key,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
