import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/category.dart';
import '../providers/product_provider.dart';
import '../theme/app_colors.dart';

class CreateProductScreen extends StatefulWidget {
  const CreateProductScreen({super.key});

  @override
  State<CreateProductScreen> createState() => _CreateProductScreenState();
}

class _CreateProductScreenState extends State<CreateProductScreen> {
  final nameController = TextEditingController();
  final priceController = TextEditingController();
  final stockController = TextEditingController(text: '0');

  bool isLoadingCategories = true;
  String? categoriesError;
  List<Category> categories = [];
  int? selectedCategoryId;

  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCategories());
  }

  @override
  void dispose() {
    nameController.dispose();
    priceController.dispose();
    stockController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() {
      isLoadingCategories = true;
      categoriesError = null;
    });

    try {
      final loaded = await context.read<ProductProvider>().loadCategories();

      if (!mounted) return;

      setState(() {
        categories = loaded;
        selectedCategoryId = loaded.isNotEmpty ? loaded.first.id : null;
        isLoadingCategories = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        categoriesError = 'No fue posible cargar las categorías';
        isLoadingCategories = false;
      });
    }
  }

  Future<void> _createProduct() async {
    final name = nameController.text.trim();
    final price = double.tryParse(priceController.text);
    final stock = int.tryParse(stockController.text);

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un nombre')),
      );
      return;
    }

    if (price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un precio válido')),
      );
      return;
    }

    if (stock == null || stock < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un stock inicial válido')),
      );
      return;
    }

    if (selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una categoría')),
      );
      return;
    }

    setState(() => isSubmitting = true);

    final errorMessage = await context.read<ProductProvider>().createProduct(
      name: name,
      price: price,
      stock: stock,
      categoryId: selectedCategoryId!,
    );

    if (!mounted) return;

    setState(() => isSubmitting = false);

    if (errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
      return;
    }

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Producto "$name" creado')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear producto'),
      ),
      body: isLoadingCategories
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Nombre',
              prefixIcon: Icon(Icons.fastfood),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: priceController,
            keyboardType:
            const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Precio',
              prefixText: '\$',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: stockController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Stock inicial',
              prefixIcon: Icon(Icons.inventory_2_outlined),
            ),
          ),
          const SizedBox(height: 16),
          if (categoriesError != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.danger.withValues(alpha: 0.4),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    categoriesError!,
                    style: const TextStyle(color: AppColors.danger),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _loadCategories,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            )
          else if (categories.isEmpty)
            const Text(
              'No hay categorías registradas todavía.',
              style: TextStyle(color: AppColors.textSecondary),
            )
          else
            DropdownButtonFormField<int>(
              initialValue: selectedCategoryId,
              decoration: const InputDecoration(
                labelText: 'Categoría',
                prefixIcon: Icon(Icons.category_outlined),
              ),
              items: categories.map((category) {
                return DropdownMenuItem(
                  value: category.id,
                  child: Text(category.name),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => selectedCategoryId = value);
              },
            ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed:
            (isSubmitting || categories.isEmpty) ? null : _createProduct,
            icon: isSubmitting
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
                : const Icon(Icons.add),
            label: const Text('Crear producto'),
          ),
        ],
      ),
    );
  }
}
