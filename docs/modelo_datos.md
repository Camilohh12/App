# Modelo de datos

Base de datos relacional (MySQL, definida con Prisma ORM en
`backend/prisma/schema.prisma`). Seis entidades:

```
User ──1:N── Order ──N:1── Table
              │
              1:N
              │
         OrderDetail ──N:1── Product ──N:1── Category
```

## Entidades

### User
| Campo | Tipo | Notas |
|---|---|---|
| id | Int (PK) | autoincrement |
| name | String | |
| email | String | único |
| password | String | hash bcrypt |
| role | String | `admin`, `cashier`, `kitchen`, `waiter`, `bar` — columna libre, no enum de BD, así que agregar un rol nuevo del lado del cliente no requiere migración |

### Category
| Campo | Tipo | Notas |
|---|---|---|
| id | Int (PK) | |
| name | String | |

### Product
| Campo | Tipo | Notas |
|---|---|---|
| id | Int (PK) | |
| name | String | |
| price | Float | |
| stock | Int | nunca negativo (validado en backend) |
| active | Boolean | default true |
| categoryId | Int (FK) | → Category |

### Table
| Campo | Tipo | Notas |
|---|---|---|
| id | Int (PK) | |
| number | Int | único |
| status | String | `available`, `occupied` |
| qrCode | String | único, es el valor codificado en el QR físico |

### Order
| Campo | Tipo | Notas |
|---|---|---|
| id | Int (PK) | |
| date | DateTime | default now() |
| status | String | `pending`, `preparing`, `ready`, `completed`, `cancelled` |
| total | Float | |
| serviceType | String | `dineIn`, `takeaway` |
| paymentMethod | String? | `cash`, `card`, `transfer` |
| amountReceived | Float? | solo efectivo |
| change | Float? | solo efectivo |
| completedAt | DateTime? | |
| userId | Int (FK) | → User (quién la creó) |
| tableId | Int? (FK) | → Table (nulo si es para llevar) |

### OrderDetail
| Campo | Tipo | Notas |
|---|---|---|
| id | Int (PK) | |
| quantity | Int | |
| subtotal | Float | |
| note | String? | observación del producto (ej. "sin hielo") |
| orderId | Int (FK) | → Order |
| productId | Int (FK) | → Product |

## Campos que el cliente calcula o cachea, sin columna en la BD

Estos campos existen en los modelos de Flutter (`lib/models/`) pero
**no en el esquema de Prisma todavía**. Están documentados aquí para
que quede claro qué es dato real del servidor y qué es una
aproximación del cliente:

- `Product.preparationArea` (bar/cocina): se deriva del nombre de la
  categoría con una lista de palabras clave
  (`PreparationArea.fromCategoryName` en `product.dart`), porque no
  hay columna para esto todavía.
- `Product.description`, `Product.imageUrl`: el modelo los soporta
  (`fromJson` los lee si vienen), pero el backend no los tiene ni los
  envía hoy.
- `Table.waiterName`: se guarda en memoria dentro de `TableProvider`
  (no en la BD) y se vuelve a fusionar en cada `refresh()` para que
  sobreviva al auto-refresco. Se pierde si se cierra la app.
- `Table.currentOrderId`: campo reservado en el modelo, no se llena
  todavía (se resuelve cruzando `Order.tableId` en pantalla, no
  guardándolo en `Table`).

## Diferencia con el modelo "ideal" de la rúbrica

La sección 7 del encargo original describía un modelo más amplio
(`cancellationReason`, `awaitingPayment` como estado separado,
`waiterName` en la orden, `mixed` como método de pago). No se
implementó todo porque el backend no se modifica en este trabajo
(salvo documentación) y varias de esas piezas requieren columnas
nuevas o lógica de transacción nueva. Quedan como mejoras futuras del
backend, no del cliente.
