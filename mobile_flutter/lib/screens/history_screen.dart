import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/order.dart';
import '../providers/order_provider.dart';
import '../theme/app_colors.dart';

enum _DateFilter { today, yesterday, last7Days }

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final searchController = TextEditingController();
  _DateFilter dateFilter = _DateFilter.today;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
          (_) => context.read<OrderProvider>().refresh(),
    );
    searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  String paymentMethodText(PaymentMethod? method) {
    switch (method) {
      case PaymentMethod.cash:
        return 'Efectivo';
      case PaymentMethod.card:
        return 'Tarjeta';
      case PaymentMethod.transfer:
        return 'Transferencia';
      case null:
        return 'No registrado';
    }
  }

  IconData paymentMethodIcon(PaymentMethod? method) {
    switch (method) {
      case PaymentMethod.cash:
        return Icons.payments;
      case PaymentMethod.card:
        return Icons.credit_card;
      case PaymentMethod.transfer:
        return Icons.account_balance;
      case null:
        return Icons.receipt_long;
    }
  }

  String serviceText(FoodOrder order) {
    if (order.serviceType == ServiceType.takeaway) {
      return 'Para llevar';
    }

    return order.tableId != null
        ? 'Mesa ${order.tableId}'
        : 'En mesa';
  }

  String formatDate(DateTime? date) {
    if (date == null) return 'Sin fecha';

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    return '$day/$month/$year';
  }

  String formatTime(DateTime? date) {
    if (date == null) return '';

    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  List<FoodOrder> _applyFilters(List<FoodOrder> orders) {
    final now = DateTime.now();
    final query = searchController.text.trim();

    return orders.where((order) {
      final date = order.completedAt;
      if (date == null) return false;

      switch (dateFilter) {
        case _DateFilter.today:
          if (!_isSameDay(date, now)) return false;
          break;
        case _DateFilter.yesterday:
          final yesterday = now.subtract(const Duration(days: 1));
          if (!_isSameDay(date, yesterday)) return false;
          break;
        case _DateFilter.last7Days:
          if (now.difference(date).inDays > 7) return false;
          break;
      }

      if (query.isNotEmpty && !order.id.toString().contains(query)) {
        return false;
      }

      return true;
    }).toList()
      ..sort((a, b) => b.completedAt!.compareTo(a.completedAt!));
  }

  void _showOrderDetail(FoodOrder order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  'Venta #${order.id}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${formatDate(order.completedAt)} · '
                      '${formatTime(order.completedAt)} · '
                      '${serviceText(order)}',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const Divider(height: 24),
                ...order.items.map(
                      (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${item.quantity} x ${item.product.name}'),
                        if (item.note != null && item.note!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(left: 12, top: 2),
                            child: Text(
                              'Obs: ${item.note}',
                              style: const TextStyle(
                                fontStyle: FontStyle.italic,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 24),
                _DetailRow(
                  label: 'Total',
                  value: '\$${order.total.toStringAsFixed(2)}',
                  bold: true,
                ),
                _DetailRow(
                  label: 'Método de pago',
                  value: paymentMethodText(order.paymentMethod),
                ),
                if (order.paymentMethod == PaymentMethod.cash) ...[
                  _DetailRow(
                    label: 'Monto recibido',
                    value:
                    '\$${(order.amountReceived ?? 0).toStringAsFixed(2)}',
                  ),
                  _DetailRow(
                    label: 'Cambio',
                    value: '\$${(order.change ?? 0).toStringAsFixed(2)}',
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();
    final filteredOrders = _applyFilters(orderProvider.completedOrders);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de ventas'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              children: [
                TextField(
                  controller: searchController,
                  decoration: const InputDecoration(
                    hintText: 'Buscar por número de orden...',
                    prefixIcon: Icon(Icons.search),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 10),
                SegmentedButton<_DateFilter>(
                  segments: const [
                    ButtonSegment(
                      value: _DateFilter.today,
                      label: Text('Hoy'),
                    ),
                    ButtonSegment(
                      value: _DateFilter.yesterday,
                      label: Text('Ayer'),
                    ),
                    ButtonSegment(
                      value: _DateFilter.last7Days,
                      label: Text('7 días'),
                    ),
                  ],
                  selected: {dateFilter},
                  onSelectionChanged: (selection) {
                    setState(() => dateFilter = selection.first);
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => context.read<OrderProvider>().refresh(),
              child: _buildBody(orderProvider, filteredOrders),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
      OrderProvider orderProvider,
      List<FoodOrder> filteredOrders,
      ) {
    if (orderProvider.isLoading && orderProvider.completedOrders.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (orderProvider.errorMessage != null &&
        orderProvider.completedOrders.isEmpty) {
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
              orderProvider.errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      );
    }

    if (filteredOrders.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 120),
          Center(
            child: Text(
              'No hay ventas en este período',
              style: TextStyle(fontSize: 18),
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: filteredOrders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final order = filteredOrders[index];

        return Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _showOrderDetail(order),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor:
                    AppColors.secondary.withValues(alpha: 0.15),
                    child: Icon(
                      paymentMethodIcon(order.paymentMethod),
                      color: AppColors.secondary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Orden #${order.id}',
                          style:
                          const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${formatDate(order.completedAt)} · '
                              '${formatTime(order.completedAt)}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\$${order.total.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Completada',
                          style: TextStyle(
                            color: AppColors.secondary,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;

  const _DetailRow({
    required this.label,
    required this.value,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          Text(
            value,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
