import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/order.dart';
import '../models/product.dart';
import '../models/table_model.dart';
import '../providers/order_provider.dart';
import '../providers/product_provider.dart';
import '../providers/table_provider.dart';
import '../theme/app_colors.dart';

const _kAllCategories = 'Todos';

IconData _iconForCategory(String category) {
  final normalized = category.toLowerCase();

  if (normalized.contains('bebida') || normalized.contains('drink')) {
    return Icons.local_drink;
  }
  if (normalized.contains('postre') || normalized.contains('dessert')) {
    return Icons.icecream;
  }
  if (normalized.contains('hamburguesa') || normalized.contains('burger')) {
    return Icons.lunch_dining;
  }
  return Icons.fastfood;
}

class NewOrderScreen extends StatefulWidget {
  final ServiceType initialServiceType;
  final int? initialTableId;

  /// Cuando se define, la pantalla opera en "modo ronda": en vez de
  /// crear una orden nueva, agrega los productos elegidos a la orden
  /// [addToOrderId] ya existente (cuenta abierta de una mesa
  /// ocupada). Oculta el selector de tipo de servicio/mesa, que ya no
  /// aplica porque la mesa quedó fija desde que se abrió la cuenta.
  final int? addToOrderId;

  const NewOrderScreen({
    super.key,
    this.initialServiceType = ServiceType.takeaway,
    this.initialTableId,
    this.addToOrderId,
  });

  @override
  State<NewOrderScreen> createState() => _NewOrderScreenState();
}

class _NewOrderScreenState extends State<NewOrderScreen> {
  final Map<int, int> quantities = {};
  final Map<int, TextEditingController> noteControllers = {};

  late ServiceType serviceType = widget.initialServiceType;
  late int? selectedTableId = widget.initialTableId;

  String selectedCategory = _kAllCategories;
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
          (_) => context.read<TableProvider>().refresh(),
    );
  }

  List<Product> get availableProducts {
    return context.read<ProductProvider>().availableProducts;
  }

  List<Product> get visibleProducts {
    if (selectedCategory == _kAllCategories) return availableProducts;

    return availableProducts
        .where((product) => product.category == selectedCategory)
        .toList();
  }

  List<String> get categories {
    final names = availableProducts.map((p) => p.category).toSet().toList()
      ..sort();
    return [_kAllCategories, ...names];
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
    if (isSubmitting) return false;
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

  int get itemCount {
    return quantities.values.fold(0, (sum, quantity) => sum + quantity);
  }

  Future<void> editNote(Product product) async {
    final controller = noteControllerFor(product.id);
    final draftController = TextEditingController(text: controller.text);

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Observación · ${product.name}'),
          content: TextField(
            controller: draftController,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Ej. Sin cebolla',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, draftController.text),
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );

    draftController.dispose();

    if (result != null) {
      setState(() => controller.text = result.trim());
    }
  }

  Future<void> confirmOrder() async {
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

    setState(() => isSubmitting = true);

    final orderProvider = context.read<OrderProvider>();
    final addToOrderId = widget.addToOrderId;

    final errorMessage = addToOrderId != null
        ? await orderProvider.addItemsToOrder(addToOrderId, selectedItems)
        : await orderProvider.addOrder(
            selectedItems,
            serviceType: serviceType,
            tableId: selectedTableId,
            tableProvider: context.read<TableProvider>(),
          );

    if (!mounted) return;

    if (errorMessage != null) {
      setState(() => isSubmitting = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
      return;
    }

    // Puede usarse como pantalla apilada (pop al terminar) o como
    // pestaña persistente del shell de navegación (sin nada que
    // "pop"; en ese caso solo se limpia el formulario).
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      setState(() {
        quantities.clear();
        for (final controller in noteControllers.values) {
          controller.clear();
        }
        serviceType = ServiceType.takeaway;
        selectedTableId = null;
        isSubmitting = false;
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          addToOrderId != null
              ? 'Productos agregados a la cuenta'
              : 'Orden enviada a cocina',
        ),
      ),
    );
  }

  String? get _tableSubtitle {
    if (serviceType != ServiceType.dineIn || selectedTableId == null) {
      return null;
    }

    final table = context.read<TableProvider>().findById(selectedTableId!);
    if (table == null) return null;

    final waiterName = table.waiterName;
    return waiterName == null
        ? 'Mesa ${table.number}'
        : 'Mesa ${table.number} · Mesero: $waiterName';
  }

  @override
  Widget build(BuildContext context) {
    final products = visibleProducts;
    final tableSubtitle = _tableSubtitle;
    final isAddingRound = widget.addToOrderId != null;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isAddingRound ? 'Agregar ronda' : 'Nueva orden',
              overflow: TextOverflow.ellipsis,
            ),
            if (tableSubtitle != null)
              Text(
                tableSubtitle,
                style: const TextStyle(fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$itemCount producto${itemCount == 1 ? '' : 's'}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '\$${total.toStringAsFixed(2)}',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FilledButton(
                  onPressed: canConfirm ? confirmOrder : null,
                  child: isSubmitting
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : Text(
                          isAddingRound
                              ? 'Agregar a la cuenta'
                              : 'Confirmar orden',
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          if (!isAddingRound)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  const SizedBox(height: 16),
                ],
              ),
            )
          else
            const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = category == selectedCategory;

                return ChoiceChip(
                  label: Text(category),
                  selected: isSelected,
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  onSelected: (_) {
                    setState(() => selectedCategory = category);
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: products.isEmpty
                ? const Center(
              child: Text(
                'No hay productos en esta categoría',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            )
                : GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              gridDelegate:
              const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 190,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.68,
              ),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                final quantity = getQuantity(product.id);
                final isLowStock = product.stock <= 5;
                final note = noteControllers[product.id]?.text.trim();

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor:
                              AppColors.primary.withValues(alpha: 0.15),
                              child: Icon(
                                _iconForCategory(product.category),
                                color: AppColors.primary,
                                size: 18,
                              ),
                            ),
                            const Spacer(),
                            if (isLowStock)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.tertiary.withValues(
                                    alpha: 0.2,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'Pocas',
                                  style: TextStyle(
                                    color: AppColors.tertiary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          product.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '\$${product.price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        if (quantity == 0)
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.tonalIcon(
                              onPressed: () => increaseQuantity(product.id),
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('Agregar'),
                              style: FilledButton.styleFrom(
                                minimumSize: const Size.fromHeight(36),
                                padding: EdgeInsets.zero,
                              ),
                            ),
                          )
                        else ...[
                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                            children: [
                              _StepperButton(
                                icon: Icons.remove,
                                onTap: () => decreaseQuantity(product.id),
                              ),
                              Text(
                                quantity.toString(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              _StepperButton(
                                icon: Icons.add,
                                onTap: () => increaseQuantity(product.id),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          InkWell(
                            onTap: () => editNote(product),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.edit_note,
                                  size: 16,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    (note == null || note.isEmpty)
                                        ? 'Agregar nota'
                                        : note,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
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

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _StepperButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16),
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
    final tableProvider = context.watch<TableProvider>();
    final availableTables = tableProvider.availableTables;

    if (tableProvider.isLoading && tableProvider.tables.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (availableTables.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Text('No hay mesas disponibles en este momento'),
        ),
      );
    }

    // La mesa elegida puede dejar de estar disponible entre que se
    // selecciona y que se reconstruye este widget (ej. justo al
    // confirmar la orden, la mesa pasa a "ocupada" y desaparece de
    // la lista antes de que se limpie la selección). Un
    // DropdownButtonFormField no admite un value que no exista en
    // sus items, así que se valida antes de pasarlo.
    final isSelectionStillValid =
    availableTables.any((table) => table.id == selectedTableId);

    if (!isSelectionStillValid && selectedTableId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => onChanged(null));
    }

    return DropdownButtonFormField<int>(
      initialValue: isSelectionStillValid ? selectedTableId : null,
      decoration: const InputDecoration(
        labelText: 'Mesa',
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
