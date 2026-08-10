# Arquitectura

## Visión general

Aplicación cliente-servidor orientada a servicios. El cliente móvil
(Flutter) no contiene lógica de negocio sensible (validación de
stock, transiciones de estado, cálculo de totales de venta) — toda
esa lógica vive en el backend, que es la única fuente de verdad. El
cliente consume esa lógica vía REST y refleja el estado real.

```
┌─────────────────────┐        HTTPS/JSON        ┌──────────────────────┐
│   Cliente Flutter    │ ────────────────────────▶│  Backend Express      │
│   (Android/iOS/Web)  │◀──────────────────────── │  + Prisma + MySQL     │
└─────────────────────┘                           └──────────────────────┘
```

## Cliente (Flutter)

### Capas

```
lib/
├── models/       Entidades + enums + fromJson/toJson (serialización manual,
│                 sin build_runner)
├── providers/    Estado de la app (Provider/ChangeNotifier). Un provider
│                 por dominio: Auth, Product, Order, Table
├── services/     Un archivo por recurso REST. Todos pasan por ApiClient
├── screens/      Una pantalla por caso de uso; los shells (Admin/Cajero)
│                 usan IndexedStack para navegación por pestañas persistente
├── widgets/      Componentes reutilizados entre pantallas (StatCard,
│                 ComandaCard)
├── theme/        Colores y ThemeData centralizados
├── data/         Catálogo y mesas de demostración (modo local)
└── config/       AppConfig.useLocalMode
```

### Flujo de una petición

`Screen` → lee el provider correspondiente con `context.read/watch` →
`Provider` llama a su `Service` → `Service` arma la ruta y el body →
`ApiClient` (Dio) agrega el token, aplica timeouts, envía la petición
→ traduce cualquier error a `ApiException` → `Provider` captura ese
error y expone un mensaje ya listo para mostrar en pantalla.

Los providers nunca mutan su lista local tras una escritura (crear
orden, cobrar, etc.): siempre vuelven a pedir el estado real al
backend con `refresh()`. Esto evita que la UI muestre un estado
"optimista" que luego resulte falso si el backend rechaza la
operación (ej. stock insuficiente).

### Estado y actualización en tiempo real

No hay WebSockets ni polling del lado del servidor. Los shells de
Admin y Cajero (`admin_shell_screen.dart`, `cashier_shell_screen.dart`)
corren un `Timer.periodic` que llama a `refresh()` en los providers
relevantes cada 8 segundos (Reportes usa 20s, por ser una consulta
más pesada). Es una solución deliberadamente simple: suficiente para
el tamaño de un bar, sin la complejidad de mantener una conexión
persistente.

### Multiplataforma

El mismo código Flutter compila a Android, iOS y Web. El sensor de
cámara (QR) y GPS dependen de plugins nativos (`mobile_scanner`,
`geolocator`) que se degradan según la plataforma (en Web piden
permiso del navegador en vez del sistema operativo).

## Servidor (Express + Prisma + MySQL)

Ver `backend/` — no se modificó como parte de este trabajo (regla del
proyecto), salvo la documentación de un contrato de API pendiente en
`docs/endpoints.md`. Responsabilidades: autenticación JWT, hash de
contraseñas (bcrypt), validación de stock, transiciones atómicas de
estado (ocupar/liberar mesa al crear/cobrar/cancelar una orden),
cálculo de reportes agregados.

## Por qué Provider y no Bloc/Riverpod/GetX

Decisión del proyecto, no técnica: se mantiene Provider en toda la
app por consistencia con el código ya existente antes de este
trabajo. Cambiar de gestor de estado a mitad de proyecto no aporta
valor a la demo y arriesga romper flujos ya probados.

## Por qué Dio y no seguir con `http`

La rúbrica de la práctica pide explícitamente Dio como equivalente de
Retrofit/Volley. La migración se limitó al interior de
`api_client.dart` (mismo contrato público hacia afuera) para no tener
que tocar los 6 servicios ni los 4 providers que ya funcionaban.
