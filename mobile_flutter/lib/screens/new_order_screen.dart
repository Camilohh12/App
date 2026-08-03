import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/order.dart';
import '../models/product.dart';
import '../models/table_model.dart';
import '../providers/order_provider.dart';
import '../providers/product_provider.dart';
import '../providers/table_provider.dart';

class NewOrderScreen extends StatefulWidget {
  final ServiceType initialServiceType;
  final int? initialTableId;

  const NewOrderScreen({
    super.key,
    this.initialServiceType = ServiceType.takeaway,
    this.initialTableId,
  });

  @override
  State<NewOrderScreen> createState() => _NewOrderScreenState();
}

class _NewOrderScreenState extends State<NewOrderScreen> {
  final Map<int, int> quantities = {};
  final Map<int, TextEditingController> noteControllers = {};

  late ServiceType serviceType = widget.initialServiceType;
  late int? selectedTableId = widget.initialTableId;

  List<Product> get availableProducts {
    return context.read<ProductProvider>().availableProducts;
  }

  TextEditingController noteControllerFor(int productId) {
    return noteControllers.putIfAbsent(
      productId,
          () => TextEditingController(),
    );
  }

  @override
  void dispose() {
    for (final controller in noteControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  bool get canConfirm {
    if (total <= 0) return false;

    if (serviceType == ServiceType.dineIn) {
      return selectedTableId != null;
    }

    return true;
  }

  void selectServiceType(ServiceType type) {
    setState(() {
      serviceType = type;

      if (type == ServiceType.takeaway) {
        selectedTableId = null;
      }
    });
  }

  int getQuantity(int productId) {
    return quantities[productId] ?? 0;
  }

  void increaseQuantity(int productId) {
    setState(() {
      quantities[productId] = getQuantity(productId) + 1;
    });
  }

  void decreaseQuantity(int productId) {
    final currentQuantity = getQuantity(productId);

    if (currentQuantity <= 1) {
      setState(() {
        quantities.remove(productId);
      });
      return;
    }

    setState(() {
      quantities[productId] = currentQuantity - 1;
    });
  }

  double get total {
    return availableProducts.fold(0, (sum, product) {
      return sum + product.price * getQuantity(product.id);
    });
  }

  void confirmOrder() {
    final selectedItems = availableProducts
        .where((product) => getQuantity(product.id) > 0)
        .map((product) {
      final noteText = noteControllers[product.id]?.text.trim();

      return OrderItem(
        product: product,
        quantity: getQuantity(product.id),
        note: (noteText != null && noteText.isNotEmpty)
            ? noteText
            : null,
      );
    })
        .toList();

    if (selectedItems.isEmpty) {
      return;
    }

    final success = context.read<OrderProvider>().addOrder(
      selectedItems,
      serviceType: serviceType,
      tableId: selectedTableId,
      tableProvider: context.read<TableProvider>(),
    );

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No fue posible confirmar la orden. '
                'La mesa seleccionada ya no está disponible.',
          ),
        ),
      );
      return;
    }

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Orden enviada a cocina'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva orden'),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Total: \$${total.toStringAsFixed(2)}',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: canConfirm ? confirmOrder : null,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
                child: const Text('Confirmar orden'),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tipo de servicio',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                SegmentedButton<ServiceType>(
                  segments: const [
                    ButtonSegment(
                      value: ServiceType.dineIn,
                      label: Text('En mesa'),
                      icon: Icon(Icons.table_bar),
                    ),
                    ButtonSegment(
                      value: ServiceType.takeaway,
                      label: Text('Para llevar'),
                      icon: Icon(Icons.takeout_dining),
                    ),
                  ],
                  selected: {serviceType},
                  onSelectionChanged: (selection) {
                    selectServiceType(selection.first);
                  },
                ),
                if (serviceType == ServiceType.dineIn) ...[
                  const SizedBox(height: 12),
                  _TableSelector(
                    selectedTableId: selectedTableId,
                    onChanged: (tableId) {
                      setState(() {
                        selectedTableId = tableId;
                      });
                    },
                  ),
                ],
                const Divider(height: 24),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              itemCount: availableProducts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final product = availableProducts[index];
                final quantity = getQuantity(product.id);

                return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('\$${product.price.toStringAsFixed(2)}'),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton.filledTonal(
                        onPressed: quantity > 0
                            ? () => decreaseQuantity(product.id)
                            : null,
                        icon: const Icon(Icons.remove),
                      ),
                      Text(
                        quantity.toString(),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      IconButton.filled(
                        onPressed: () => increaseQuantity(product.id),
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                  if (quantity > 0) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: noteControllerFor(product.id),
                      decoration: const InputDecoration(
                        labelText: 'Observación (opcional)',
                        hintText: 'Ej. Sin cebolla',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TableSelector extends StatelessWidget {
  final int? selectedTableId;
  final ValueChanged<int?> onChanged;

  const _TableSelector({
    required this.selectedTableId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final availableTables =
        context.watch<TableProvider>().availableTables;

    if (availableTables.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Text('No hay mesas disponibles en este momento'),
        ),
      );
    }

    return DropdownButtonFormField<int>(
      initialValue: selectedTableId,
      decoration: const InputDecoration(
        labelText: 'Mesa',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.table_bar),
      ),
      items: availableTables
          .map(
            (TableModel table) => DropdownMenuItem(
          value: table.id,
          child: Text('Mesa ${table.number}'),
        ),
      )
          .toList(),
      onChanged: onChanged,
    );
  }
}