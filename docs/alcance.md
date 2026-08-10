# Alcance del proyecto

## Problema que resuelve

Los bares pequeños y medianos suelen operar con papel, WhatsApp o
memoria para tomar comandas, coordinar barra/cocina y cerrar cuentas.
Eso genera errores de cobro, pérdida de comandas, y ningún dato real
sobre qué se vende más o cuándo hay que reabastecer. ComandaPOS
digitaliza ese flujo completo: mesas → comanda → barra/cocina → cobro
→ historial e inventario, con roles separados por función.

## Público objetivo

Dueños y encargados de bares y restaurantes pequeños/medianos que hoy
no usan ningún sistema, o usan uno que no separa barra de cocina ni
da visibilidad de inventario en tiempo real.

## Qué incluye esta versión (demostrable)

- Roles: administrador, cajero, mesero, cocina, barra — cada uno con
  su propia pantalla y permisos.
- Mesas: apertura, mesero asignado, estado (disponible/ocupada),
  código QR para abrir/consultar desde el celular.
- Comandas: catálogo por categoría, observaciones por producto,
  separación automática de lo que le corresponde a barra vs. cocina.
- Cobro: efectivo (con cálculo de cambio), tarjeta, transferencia;
  descuento de inventario y liberación de mesa automáticos al cobrar.
- Inventario: alta de productos, ajuste de stock (incremento,
  decremento, o valor exacto), activar/desactivar, alertas de stock
  bajo/agotado.
- Historial de ventas con filtros.
- Reportes: ventas del día, semanales/mensuales, por categoría, por
  método de pago, productos más vendidos, stock bajo.
- Sensor de cámara (QR de mesas) y sensor de GPS (ubicación de la
  terminal).
- Auto-refresco en segundo plano (sin pull-to-refresh manual).

## Qué queda fuera de esta versión (a propósito)

- **Segunda ronda en cuenta abierta**: la interfaz existe
  (`OpenAccountScreen`, "Agregar otra ronda"), pero necesita un
  endpoint nuevo en el backend que todavía no se implementó (ver
  `endpoints.md`). No se avanzó más porque este proyecto no modifica
  el backend salvo documentación de contratos.
- **Dividir cuenta**: señalada en la interfaz como "próximamente",
  sin implementar, para no prometer algo que no funciona.
- **Pagos mixtos** (parte efectivo + parte tarjeta en la misma venta).
- **Estado "esperando pago" separado de "lista"**: hoy una comanda
  lista y una cuenta lista para cobrar comparten el mismo estado
  (`ready`); no se agregó un estado intermedio porque hubiera exigido
  tocar la lógica de transición de estados del backend.
- **Inventario por mililitros/receta** para bebidas por copa: se
  maneja por unidades (ej. "1 tequila por copa" descuenta 1 unidad),
  no por porcentaje de botella.
- **Impresión de tickets, propinas, corte de caja por turno, multi-
  sucursal**: no se pidieron para esta fase, quedan como preguntas
  para el cliente en `demo_cliente_bar.md`.
- **Modo local para login/órdenes/pagos**: el modo local
  (`AppConfig.useLocalMode`) solo cubre catálogo de productos y mesas
  de demostración; login y transacciones siempre requieren el backend
  real, porque replicar esa lógica de negocio en el cliente
  (validaciones, transacciones atómicas) es un proyecto aparte.

## Backend

El backend (Express + Prisma + MySQL) es funcional y fue desarrollado
en paralelo a este cliente. Este proyecto no modifica su código ni su
esquema — solo documenta, en `docs/endpoints.md`, un endpoint nuevo
que el cliente ya está listo para consumir en cuanto se implemente.
