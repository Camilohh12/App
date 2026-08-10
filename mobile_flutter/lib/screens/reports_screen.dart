import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/order.dart';
import '../providers/order_provider.dart';
import '../providers/product_provider.dart';
import '../providers/table_provider.dart';
import '../services/api_client.dart';
import '../services/report_service.dart';
import '../theme/app_colors.dart';
import '../widgets/stat_card.dart';

/// Ventas completadas agrupadas por método de pago, en la misma
/// ventana de fechas que usa el reporte del backend para `period`
/// (últimos 7 o 30 días completos según `getSummaryReport` en
/// report.controller.ts). El backend no expone este desglose
/// todavía, así que se calcula aquí con las órdenes que ya tiene el
/// cliente cargadas.
Map<PaymentMethod, double> _paymentBreakdown(
  List<FoodOrder> completedOrders,
  String period,
) {
  final days = period == 'monthly' ? 30 : 7;
  final now = DateTime.now();
  final end = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
  final start = DateTime(
    now.year,
    now.month,
    now.day,
  ).subtract(Duration(days: days - 1));

  final result = <PaymentMethod, double>{};

  for (final order in completedOrders) {
    final completedAt = order.completedAt;
    final method = order.paymentMethod;
    if (completedAt == null || method == null) continue;
    if (completedAt.isBefore(start) || completedAt.isAfter(end)) continue;

    result[method] = (result[method] ?? 0) + order.total;
  }

  return result;
}

String paymentMethodLabel(PaymentMethod method) {
  switch (method) {
    case PaymentMethod.cash:
      return 'Efectivo';
    case PaymentMethod.card:
      return 'Tarjeta';
    case PaymentMethod.transfer:
      return 'Transferencia';
  }
}

Color paymentMethodColor(PaymentMethod method) {
  switch (method) {
    case PaymentMethod.cash:
      return AppColors.secondary;
    case PaymentMethod.card:
      return AppColors.primary;
    case PaymentMethod.transfer:
      return AppColors.delivery;
  }
}

const _kPollInterval = Duration(seconds: 20);

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String period = 'weekly';
  bool isLoading = true;
  String? errorMessage;
  Map<String, dynamic>? report;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _load();
      // Órdenes activas, cuentas abiertas y stock bajo se leen de
      // estos providers directamente (no vienen en getSummaryReport).
      context.read<OrderProvider>().refresh();
      context.read<TableProvider>().refresh();
      context.read<ProductProvider>().refresh();
    });
    // Los reportes se agregan con menos frecuencia que las órdenes,
    // así que se refrescan solos con un intervalo más espaciado.
    _pollTimer = Timer.periodic(_kPollInterval, (_) {
      if (!mounted) return;
      _load();
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final service = ReportService(context.read<ApiClient>());
      final data = await service.getSummaryReport(period);

      if (!mounted) return;

      setState(() {
        report = data;
        isLoading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        errorMessage = error.message;
        isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        errorMessage = 'No fue posible conectar con el servidor';
        isLoading = false;
      });
    }
  }

  /// Agrupa categorías más allá de las 3 primeras en "Otros": la
  /// paleta categórica solo está validada (separación CVD) para 3
  /// colores visibles simultáneamente, como exige un gráfico de
  /// torta donde todas las porciones se comparan a la vez.
  List<Map<String, dynamic>> _groupCategories(List<dynamic> raw) {
    final list = raw.cast<Map<String, dynamic>>();
    if (list.length <= 3) return list;

    final top3 = list.take(3).toList();
    final rest = list.skip(3);

    final otherTotal = rest.fold<double>(
      0,
          (sum, c) => sum + (c['total'] as num).toDouble(),
    );
    final otherPercentage = rest.fold<double>(
      0,
          (sum, c) => sum + (c['percentage'] as num).toDouble(),
    );

    return [
      ...top3,
      {
        'category': 'Otros',
        'total': otherTotal,
        'percentage': otherPercentage,
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes'),
      ),
      body: RefreshIndicator(
        onRefresh: () => Future.wait([
          _load(),
          context.read<OrderProvider>().refresh(),
          context.read<TableProvider>().refresh(),
          context.read<ProductProvider>().refresh(),
        ]),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    final orderProvider = context.watch<OrderProvider>();
    final tableProvider = context.watch<TableProvider>();
    final productProvider = context.watch<ProductProvider>();
    final lowStockProducts = productProvider.lowStockProducts;
    if (isLoading && report == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null && report == null) {
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
              errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      );
    }

    final totalSales = (report?['totalSales'] as num?)?.toDouble() ?? 0;
    final orderCount = report?['orderCount'] as int? ?? 0;
    final averageTicket = orderCount > 0 ? totalSales / orderCount : 0.0;
    final dailyRevenue =
        (report?['dailyRevenue'] as List<dynamic>?) ?? const [];
    final categories = _groupCategories(
      (report?['categoryBreakdown'] as List<dynamic>?) ?? const [],
    );
    final topItems = (report?['topItems'] as List<dynamic>?) ?? const [];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Estado actual',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        HeroStatCard(
          label: 'Ventas de hoy',
          value: '\$${orderProvider.dailySales.toStringAsFixed(2)}',
          color: AppColors.secondary,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: StatCard(
                label: 'Órdenes activas',
                value: orderProvider.pendingOrders.toString(),
                icon: Icons.receipt_long,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                label: 'Cuentas abiertas',
                value: tableProvider.occupiedTables.length.toString(),
                icon: Icons.table_bar,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        StatCard(
          label: 'Productos con stock bajo',
          value: lowStockProducts.length.toString(),
          icon: Icons.warning_amber_rounded,
        ),
        if (lowStockProducts.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: lowStockProducts
                .map(
                  (product) => Chip(
                    label: Text(
                      '${product.name} (${product.stock})',
                      style: const TextStyle(fontSize: 12),
                    ),
                    backgroundColor: AppColors.tertiary.withValues(
                      alpha: 0.15,
                    ),
                    side: BorderSide.none,
                  ),
                )
                .toList(),
          ),
        ],
        const SizedBox(height: 24),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'weekly', label: Text('Semanal')),
            ButtonSegment(value: 'monthly', label: Text('Mensual')),
          ],
          selected: {period},
          onSelectionChanged: (selection) {
            setState(() => period = selection.first);
            _load();
          },
        ),
        const SizedBox(height: 16),
        HeroStatCard(
          label: 'Ventas totales',
          value: '\$${totalSales.toStringAsFixed(2)}',
          color: AppColors.primary,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: StatCard(
                label: 'Ticket promedio',
                value: '\$${averageTicket.toStringAsFixed(2)}',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                label: 'Transacciones',
                value: orderCount.toString(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'Ingresos diarios',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _RevenueBarChart(dailyRevenue: dailyRevenue),
        const SizedBox(height: 24),
        Text(
          'Ventas por categoría',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _CategoryBreakdown(categories: categories),
        const SizedBox(height: 24),
        Text(
          'Ventas por método de pago',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _PaymentMethodBreakdown(
          breakdown: _paymentBreakdown(orderProvider.completedOrders, period),
        ),
        const SizedBox(height: 24),
        Text(
          'Productos más vendidos',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (topItems.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: const Text(
              'No hay ventas en este período',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          )
        else
          ...topItems.map((raw) {
            final item = raw as Map<String, dynamic>;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['name'] as String,
                          style:
                          const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${item['quantity']} vendidos',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '\$${(item['totalRevenue'] as num).toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }
}

class _RevenueBarChart extends StatelessWidget {
  final List<dynamic> dailyRevenue;

  const _RevenueBarChart({required this.dailyRevenue});

  @override
  Widget build(BuildContext context) {
    if (dailyRevenue.isEmpty) {
      return Container(
        width: double.infinity,
        height: 160,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        alignment: Alignment.center,
        child: const Text(
          'No hay ventas en este período',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    final maxValue = dailyRevenue
        .map((d) => (d['total'] as num).toDouble())
        .reduce((a, b) => a > b ? a : b);

    return Container(
      width: double.infinity,
      height: 200,
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: BarChart(
        BarChartData(
          maxY: maxValue * 1.2,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= dailyRevenue.length) {
                    return const SizedBox.shrink();
                  }

                  final date = DateTime.parse(
                    dailyRevenue[index]['date'] as String,
                  );

                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      '${date.day}/${date.month}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => AppColors.surfaceHigh,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '\$${rod.toY.toStringAsFixed(2)}',
                  const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
          ),
          barGroups: [
            for (var i = 0; i < dailyRevenue.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: (dailyRevenue[i]['total'] as num).toDouble(),
                    color: AppColors.chartCategorical[0],
                    width: 14,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _PaymentMethodBreakdown extends StatelessWidget {
  final Map<PaymentMethod, double> breakdown;

  const _PaymentMethodBreakdown({required this.breakdown});

  @override
  Widget build(BuildContext context) {
    if (breakdown.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: const Text(
          'No hay ventas en este período',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    final total = breakdown.values.fold<double>(0, (sum, v) => sum + v);
    final entries = breakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: entries.map((entry) {
          final fraction = total > 0 ? entry.value / total : 0.0;
          final color = paymentMethodColor(entry.key);

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      paymentMethodLabel(entry.key),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '\$${entry.value.toStringAsFixed(2)} '
                      '(${(fraction * 100).toStringAsFixed(0)}%)',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: fraction,
                    minHeight: 8,
                    backgroundColor: AppColors.surfaceHigh,
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _CategoryBreakdown extends StatelessWidget {
  final List<Map<String, dynamic>> categories;

  const _CategoryBreakdown({required this.categories});

  Color _colorFor(int index) {
    if (index < AppColors.chartCategorical.length) {
      return AppColors.chartCategorical[index];
    }
    return AppColors.chartOther;
  }

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: const Text(
          'No hay ventas en este período',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            height: 110,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 28,
                sections: [
                  for (var i = 0; i < categories.length; i++)
                    PieChartSectionData(
                      value: (categories[i]['total'] as num).toDouble(),
                      color: _colorFor(i),
                      showTitle: false,
                      radius: 24,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < categories.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: _colorFor(i),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            categories[i]['category'] as String,
                            style: const TextStyle(fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${(categories[i]['percentage'] as num).toStringAsFixed(0)}%',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
