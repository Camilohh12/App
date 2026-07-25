import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/order.dart';
import '../providers/order_provider.dart';
import '../providers/product_provider.dart';

String paymentResultMessage(PaymentResult result) {
  switch (result) {
    case PaymentResult.success:
      return 'Pago registrado correctamente';
    case PaymentResult.orderNotReady:
      return 'La orden ya no está disponible para cobro';
    case PaymentResult.insufficientAmount:
      return 'El monto recibido es menor al total';
    case PaymentResult.insufficientStock:
      return 'No hay stock suficiente para completar la venta';
    case PaymentResult.alreadyProcessed:
      return 'Esta orden ya fue cobrada';
  }
}

class PaymentScreen extends StatelessWidget {
  const PaymentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final readyOrders = context.watch<OrderProvider>().readyOrders;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cobro de órdenes'),
      ),
      body: readyOrders.isEmpty
          ? const Center(
        child: Text(
          'No hay órdenes listas para cobrar',
          style: TextStyle(fontSize: 18),
        ),
      )
          : ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: readyOrders.length,
        separatorBuilder: (_, __) =>
        const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final order = readyOrders[index];

          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    'Orden #${order.id}',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...order.items.map(
                        (item) => Text(
                      '${item.quantity} x '
                          '${item.product.name}',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Total: \$${order.total.toStringAsFixed(2)}',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              PaymentDetailScreen(
                                order: order,
                              ),
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
      ),
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

  final amountController = TextEditingController();

  double get amountReceived {
    return double.tryParse(amountController.text) ?? 0;
  }

  double get change {
    if (selectedMethod != PaymentMethod.cash) {
      return 0;
    }

    final value = amountReceived - widget.order.total;

    return value > 0 ? value : 0;
  }

  @override
  void dispose() {
    amountController.dispose();
    super.dispose();
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

  void confirmPayment() {
    final amount = selectedMethod == PaymentMethod.cash
        ? amountReceived
        : widget.order.total;

    if (selectedMethod == PaymentMethod.cash &&
        amount < widget.order.total) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'El monto recibido es menor al total',
          ),
        ),
      );
      return;
    }

    final result = context.read<OrderProvider>().completePayment(
      orderId: widget.order.id,
      paymentMethod: selectedMethod,
      amountReceived: amount,
      productProvider: context.read<ProductProvider>(),
    );

    if (result != PaymentResult.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(paymentResultMessage(result)),
        ),
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
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  const Text('Total de la orden'),
                  const SizedBox(height: 6),
                  Text(
                    '\$${widget.order.total.toStringAsFixed(2)}',
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<PaymentMethod>(
            initialValue: selectedMethod,
            decoration: const InputDecoration(
              labelText: 'Método de pago',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.payment),
            ),
            items: PaymentMethod.values.map((method) {
              return DropdownMenuItem(
                value: method,
                child: Text(paymentMethodText(method)),
              );
            }).toList(),
            onChanged: (method) {
              if (method == null) return;

              setState(() {
                selectedMethod = method;

                if (method != PaymentMethod.cash) {
                  amountController.text =
                      widget.order.total.toStringAsFixed(2);
                } else {
                  amountController.clear();
                }
              });
            },
          ),
          const SizedBox(height: 16),
          if (selectedMethod == PaymentMethod.cash) ...[
            TextField(
              controller: amountController,
              keyboardType:
              const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (_) {
                setState(() {});
              },
              decoration: const InputDecoration(
                labelText: 'Monto recibido',
                prefixText: '\$',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Cambio',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '\$${change.toStringAsFixed(2)}',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge,
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: confirmPayment,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
            ),
            icon: const Icon(Icons.check_circle),
            label: const Text('Confirmar pago'),
          ),
        ],
      ),
    );
  }
}