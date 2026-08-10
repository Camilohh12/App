# Endpoints de la API — ComandaPOS

Este documento registra el contrato entre el cliente Flutter y el backend
(Express + Prisma + MySQL). Se amplía en la Fase 10 con el resto de la
API; por ahora solo documenta lo agregado en la Fase 3 del cliente.

## Consumo de servicios web (cliente)

El cliente Flutter consume la API REST con **Dio** (`lib/services/api_client.dart`),
que cumple la misma función que Retrofit en Android nativo o Volley en
Java/Kotlin: cliente HTTP centralizado, interceptores para el token de
autenticación, tiempos de espera configurables y manejo tipado de
errores de red. Todos los servicios (`auth_service.dart`,
`product_service.dart`, `order_service.dart`, `table_service.dart`,
`payment_service.dart`, `report_service.dart`) pasan por este cliente
compartido en vez de configurar su propia conexión.

## Endpoints ya consumidos por el cliente

| Método y ruta | Servicio Flutter | Notas |
|---|---|---|
| `POST /api/auth/login` | `auth_service.dart` | Devuelve `{ token, user }` |
| `POST /api/auth/register` | `auth_service.dart` | Requiere admin autenticado |
| `GET /api/products` | `product_service.dart` | |
| `GET /api/categories` | `product_service.dart` | |
| `POST /api/products` | `product_service.dart` | Solo admin |
| `PUT /api/products/:id` | `product_service.dart` | Solo admin (activar/desactivar) |
| `PATCH /api/products/:id/stock` | `product_service.dart` | `stock` (valor exacto) o `delta` (sumar/restar) |
| `DELETE /api/products/:id` | `product_service.dart` | Solo admin; 409 si el producto tiene ventas |
| `GET /api/tables` | `table_service.dart` | |
| `POST /api/orders` | `order_service.dart` | Ocupa la mesa de forma atómica si `serviceType: dineIn` |
| `GET /api/orders` | `order_service.dart` | |
| `PATCH /api/orders/:id/status` | `order_service.dart` | Incluye `cancelled` (libera mesa, no descuenta stock) |
| `POST /api/payments` | `payment_service.dart` | Descuenta stock y libera mesa de forma atómica |
| `GET /api/reports/daily` | `report_service.dart` | |
| `GET /api/reports/summary?period=weekly\|monthly` | `report_service.dart` | |
| `GET /health` | `api_client.dart` (`checkHealth`) | Fuera del prefijo `/api`; badge de conexión del login |

## Pendiente de implementar en el backend

### `POST /api/orders/:id/items`

Agrega productos a una orden que ya existe (segunda ronda de una cuenta
abierta en mesa). El cliente Flutter ya está preparado para llamarlo
(`OrderService.addItemsToOrder`, usado desde "Agregar otra ronda" en
`OpenAccountScreen`), pero **el backend todavía no lo tiene**. Mientras
no exista, el cliente muestra un mensaje explicando que la función
requiere esta actualización del servidor, en vez de fallar sin
explicación o fingir que funcionó.

**Auth:** requiere token, roles `cashier`, `waiter` o `admin` (mismos
permisos que `POST /api/orders`).

**Request body:**

```json
{
  "items": [
    { "productId": 4, "quantity": 2, "note": "sin hielo" },
    { "productId": 7, "quantity": 1 }
  ]
}
```

**Comportamiento esperado:**

- La orden (`:id`) debe existir y estar en estado `pending`, `preparing`
  o `ready` (no `completed` ni `cancelled`) — devolver 409 si no.
- Por cada item, validar stock disponible igual que en
  `POST /api/orders` (no descontar inventario todavía; el descuento
  sigue ocurriendo solo al pagar, como ya hace `POST /api/payments`).
- Crea un `OrderDetail` nuevo por cada item del request (no fusiona
  cantidades con detalles existentes del mismo producto, para que cada
  ronda quede identificable en el historial).
- Recalcula `Order.total` sumando todos los `OrderDetail` (viejos +
  nuevos).
- Responde con la orden completa actualizada, mismo formato que
  `POST /api/orders` (incluye `details` con los productos anidados).

**Errores:**

- `404` — orden no encontrada.
- `409` — orden ya `completed` o `cancelled`.
- `400` — producto inexistente, inactivo, o sin stock suficiente.
