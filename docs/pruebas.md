# Pruebas

## Automatizadas (cliente Flutter)

```bash
cd mobile_flutter
flutter analyze   # análisis estático — debe salir sin errores
flutter test      # pruebas unitarias y de widget
```

17 pruebas en total:

- `test/widget_test.dart` — smoke test: la app arranca y muestra el
  login.
- `test/models/product_test.dart` — deriva de `PreparationArea` por
  categoría (bar/cocina), `copyWith`, ida y vuelta `toJson`/`fromJson`.
- `test/models/order_test.dart` — cálculo de subtotal/total,
  serialización de `OrderItem` hacia el backend, interpretación de
  `FoodOrder.fromJson`.
- `test/providers/order_provider_test.dart` — incluye una prueba de
  regresión específica: `dailySales` solo debe sumar órdenes
  completadas **hoy**, no de cualquier día (fue un bug real,
  encontrado probando en un celular físico, ya corregido). También
  verifica que `activeOrders` excluya órdenes completadas/canceladas.
- `test/providers/product_provider_test.dart` — `availableProducts`
  excluye inactivos/agotados; `lowStockProducts` detecta ≤ 5 unidades.

Los providers se prueban con un servicio "falso" que extiende la
clase real de servicio y sobreescribe el método de red (`getOrders`,
`getProducts`) para devolver datos fijos, sin tocar la red ni agregar
ninguna librería de mocking. No se pudo usar `implements` porque los
servicios reales guardan su `ApiClient` en un campo privado (privado
a su propio archivo), así que `extends` + `@override` fue la única
forma de hacerlo sin modificar el código de producción.

## Por qué no hay más pruebas de provider

`AuthProvider` y las escrituras de `OrderProvider`/`ProductProvider`
(crear orden, cobrar, ajustar stock) dependen de validaciones reales
del backend (credenciales, stock, transiciones de estado). Probarlas
de verdad requeriría un backend de prueba o una librería de mocking
HTTP (ej. `http_mock_adapter` para Dio), que no se agregó para
mantener las dependencias al mínimo. Quedan cubiertas por las pruebas
manuales de este documento.

## Manuales (requieren backend real + dispositivo)

Repetir en un dispositivo Android físico (o emulador) con el backend
corriendo, antes de cualquier demo:

| Flujo | Pasos mínimos |
|---|---|
| Login y roles | Entrar con cada uno de los 5 roles, verificar que cada uno llega a su pantalla correcta |
| Mesas | Abrir mesa con mesero → verificar que aparece ocupada con total acumulado |
| Comanda | Crear orden con productos de barra y cocina mezclados → verificar que cada tablero solo muestra lo suyo |
| QR | Escanear mesa disponible → abre Nueva orden; escanear mesa ocupada → abre Cuenta abierta; escanear código inválido → mensaje de error |
| Cobro | Cobrar en efectivo con monto insuficiente (debe rechazar), luego con monto correcto (debe calcular cambio, liberar mesa) |
| Inventario | Ajustar stock a un valor exacto, activar/desactivar un producto |
| Reportes | Verificar que "Ventas de hoy" y "Cuentas abiertas" cambian en tiempo real tras una venta |
| Sensores | Cámara (QR) y GPS (pantalla Sensor de ubicación) piden permiso y funcionan |
| Auto-refresco | Dejar la app abierta sin tocarla; verificar que una orden creada desde otro dispositivo aparece sola en ~8s |

Ver `demo_cliente_bar.md` para el guion completo de demostración.

## Limitación del entorno de desarrollo de este trabajo

Durante este proyecto no fue posible tomar capturas de pantalla reales
del panel de vista previa del entorno (falla de composición conocida
del navegador integrado), así que la verificación visual final
(colores, overflow) se hizo por lectura de código y análisis estático,
no por inspección visual directa. Se recomienda una revisión visual
rápida en dispositivo real antes de la demo — ver
`README.md` sección "Pendiente de verificar".
