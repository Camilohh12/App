/// Configuración global de la app.
///
/// `useLocalMode` distingue entre modo remoto (por defecto: todo se
/// consulta al backend real) y modo local (para demostrar el
/// catálogo de bar y las mesas de ejemplo sin depender de que el
/// backend esté disponible — útil si no hay WiFi/servidor a la mano
/// al mostrarle la app a un cliente).
///
/// Cambia el valor aquí manualmente para alternar entre ambos modos,
/// igual que la URL del backend en main.dart. Solo cubre productos y
/// mesas: login, órdenes y pagos necesitan un backend real porque
/// dependen de su lógica de negocio (validaciones, transacciones
/// atómicas) que no se reimplementa en el cliente.
class AppConfig {
  AppConfig._();

  static const bool useLocalMode = false;
}
