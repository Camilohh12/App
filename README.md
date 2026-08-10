# ComandaPOS Bar

Aplicación cliente-servidor de punto de venta para bares: mesas,
comandas separadas por barra/cocina, cobro, inventario y reportes.

## Problema que resuelve

Los bares pequeños y medianos suelen operar con papel, WhatsApp o
memoria para tomar comandas y coordinar barra/cocina. Eso genera
errores de cobro, comandas perdidas y ningún dato real sobre qué se
vende más o cuándo reabastecer. ComandaPOS digitaliza ese flujo
completo con roles separados por función.

## Público objetivo

Dueños y encargados de bares pequeños/medianos que hoy no usan ningún
sistema, o usan uno que no separa barra de cocina ni da visibilidad
de inventario en tiempo real.

## Funcionalidades

- Mesas: apertura con mesero asignado, estado en vivo, código QR.
- Comandas: catálogo por categoría, observaciones por producto,
  separación automática barra/cocina.
- Cobro: efectivo (con cambio), tarjeta, transferencia; descuenta
  inventario y libera la mesa automáticamente.
- Inventario: alta de productos, ajuste de stock, activar/desactivar,
  alertas de stock bajo/agotado.
- Historial de ventas con filtros.
- Reportes: ventas del día, semanales/mensuales, por categoría, por
  método de pago, productos más vendidos, stock bajo.
- Sensor de cámara (QR de mesas) y sensor de GPS.
- Auto-refresco en segundo plano.

Ver `docs/alcance.md` para el detalle de qué queda fuera de esta
versión (y por qué).

## Roles

| Rol | Pantalla principal | Puede |
|---|---|---|
| Administrador | Panel completo | Todo: mesas, comandas, inventario, cobro, reportes, crear usuarios |
| Cajero | Dashboard de cajero | Crear comandas, cobrar, ver mesas e historial |
| Mesero | Dashboard de mesero | Abrir mesas, crear comandas, ver cuentas abiertas y comandas listas |
| Cocina | Tablero de cocina | Ver y avanzar el estado de los productos de cocina |
| Barra | Tablero de barra | Ver y avanzar el estado de los productos de barra (no cobra ni cancela) |

## Tecnologías

### Cliente (`mobile_flutter/`)
- Flutter / Dart, Material Design 3, tema oscuro centralizado
- Provider (gestión de estado)
- Dio (consumo de servicios REST — equivalente a Retrofit/Volley)
- `mobile_scanner` (sensor de cámara, QR de mesas)
- `geolocator` (sensor de GPS)
- `fl_chart` (gráficos de Reportes)

### Servidor (`backend/`)
- Node.js + Express + TypeScript
- Prisma ORM sobre MySQL
- JWT (`jsonwebtoken`) para autenticación, `bcrypt` para contraseñas

## Instalación

### Backend
```bash
cd backend
npm install
# configurar .env: DATABASE_URL, JWT_SECRET, JWT_EXPIRES_IN, PORT
npx prisma migrate dev
npx prisma db seed
npm run dev
```

### Cliente
```bash
cd mobile_flutter
flutter pub get
```
Antes de correr en un dispositivo físico, edita la IP del backend en
`lib/main.dart` (comentario junto a `ApiClient`) con la IP local de tu
PC (`ipconfig` → adaptador WiFi).
```bash
flutter run
```

## Usuarios de prueba

Sembrados por el backend (`backend/prisma/seed.ts`):

| Correo | Contraseña | Rol |
|---|---|---|
| admin@comandapos.com | 1234 | Administrador |
| cajero@comandapos.com | 1234 | Cajero |
| cocina@comandapos.com | 1234 | Cocina |

Los roles **Mesero** y **Barra** no vienen sembrados — créalos desde
**Crear usuario** (menú de administrador) con cualquier correo, ya
que el backend acepta cualquier valor de rol sin necesitar cambios.

## Estructura

```
ComandaPOS/
├── mobile_flutter/     Cliente Flutter (ver arquitectura.md)
├── backend/            Servidor Express + Prisma + MySQL
└── docs/               Documentación del proyecto (este índice)
    ├── historias_usuario.md
    ├── alcance.md
    ├── arquitectura.md
    ├── modelo_datos.md
    ├── endpoints.md
    ├── pruebas.md
    └── demo_cliente_bar.md
```

## Flujo de una venta (resumen)

Mesa disponible → abrir mesa (mesero opcional) → nueva comanda →
productos con observaciones → confirmar → aparece filtrada en
Barra/Cocina según cada producto → cada estación marca su avance →
"Solicitar cuenta" o cobrar directo desde Cobro → pago (con cambio si
es efectivo) → mesa se libera, stock se descuenta, venta aparece en
Historial y Reportes. Detalle completo en `docs/demo_cliente_bar.md`.

## Modo local

`mobile_flutter/lib/config/app_config.dart` tiene una bandera
`useLocalMode` (apagada por defecto) que hace que Productos y Mesas
se llenen con datos de demostración locales
(`lib/data/demo_catalog.dart`, `lib/data/demo_tables.dart`) en vez de
consultar el backend — útil para mostrar el catálogo sin depender de
que el servidor esté disponible. Login, órdenes y pagos siempre
requieren el backend real: ver `docs/alcance.md` para el porqué.

## API prevista / consumida

Ver `docs/endpoints.md` para el contrato completo, incluido un
endpoint que el cliente ya está listo para usar pero el backend
todavía no implementa.

## Sensor QR y GPS

- **Cámara**: pantalla "Escanear mesa" (`qr_scanner_screen.dart`) lee
  el QR físico de una mesa y abre su comanda o cuenta abierta.
- **GPS**: pantalla "Sensor de ubicación" (`sensors_screen.dart`)
  muestra latitud, longitud, precisión, altitud, velocidad y rumbo de
  la terminal.

## Funciones futuras

- Agregar segunda ronda a una cuenta abierta de extremo a extremo
  (falta el endpoint del backend, ya documentado).
- Dividir cuenta entre varios clientes.
- Pagos mixtos (efectivo + tarjeta en la misma venta).
- Estado "esperando pago" separado de "lista".
- Control de inventario por receta/mililitros para bebidas por copa.
- Impresión de tickets, propinas, corte de caja por turno,
  multi-sucursal (preguntas abiertas para el cliente, ver
  `docs/demo_cliente_bar.md`).

## Pendiente de verificar

- El color primario del tema (vino/borgoña, `#9D2449`) se eligió por
  código para no chocar con el ámbar ya usado en alertas de stock,
  pero no se pudo confirmar visualmente por una limitación del
  entorno de desarrollo usado en este trabajo (el panel de vista
  previa no compuso capturas). Revísalo en un dispositivo real antes
  de la demo.
- Capturas de pantalla del producto terminado (pendientes de tomar en
  dispositivo real).

## Integrantes y responsabilidades

_(Completa esta sección con tu equipo — se dejó en blanco a
propósito, igual que el documento Word de la rúbrica.)_

| Integrante | Responsabilidad |
|---|---|
| | |
| | |
