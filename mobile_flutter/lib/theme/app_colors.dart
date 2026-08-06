import 'package:flutter/material.dart';

/// Paleta del sistema de diseño oscuro de ComandaPOS (inspirado en
/// el mockup "QuickPOS"): fondo azul marino, tarjetas oscuras
/// elevadas, y acentos de color por función.
class AppColors {
  AppColors._();

  static const Color background = Color(0xFF0F172A);
  static const Color surface = Color(0xFF1E293B);
  static const Color surfaceHigh = Color(0xFF334155);
  static const Color border = Color(0xFF334155);

  static const Color primary = Color(0xFF3B82F6);
  static const Color secondary = Color(0xFF22C55E);
  static const Color tertiary = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color delivery = Color(0xFFA855F7);

  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);

  /// Color de acento asociado a cada tipo de servicio, usado tanto
  /// en el tablero de cocina como en insignias de mesa/para llevar.
  static const Color dineIn = primary;
  static const Color takeaway = tertiary;

  /// Paleta categórica para gráficos (Reportes), validada para modo
  /// oscuro con el validador de la skill de dataviz: separación CVD
  /// y contraste aprobados para las 3 primeras categorías visibles
  /// simultáneamente (torta/leyenda). Un 4to+ valor debe agruparse
  /// en "Otros" con [chartOther] en vez de generar un color nuevo.
  static const List<Color> chartCategorical = [
    Color(0xFF3987E5), // azul
    Color(0xFFD95926), // naranja
    Color(0xFF199E70), // aqua
  ];
  static const Color chartOther = Color(0xFF6B7280);
}
