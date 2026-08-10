import '../models/table_model.dart';

/// Mesas de demostración para presentarle la app a un bar.
///
/// Igual que [demoBarCatalog] en `demo_catalog.dart`: son datos de
/// ejemplo, no vienen del backend, y usan ids negativos para nunca
/// chocar con un id real de la API. Todavía no está conectado a
/// ningún provider ni pantalla — se conecta junto con el modo
/// local/remoto.
final List<TableModel> demoTables = List.generate(
  10,
  (index) => TableModel(
    id: -(index + 1),
    number: index + 1,
    qrCode: 'MESA-${index + 1}',
  ),
);
