# Guion de demostración — cliente con bar

Este guion está pensado para mostrarle ComandaPOS a un dueño de bar real
por primera vez. Usa datos del catálogo de demostración (ver
`mobile_flutter/lib/data/demo_catalog.dart`) y requiere que el backend
esté corriendo y con el celular en la misma red WiFi que el PC (ver
comentario en `mobile_flutter/lib/main.dart`).

## Antes de empezar

- Backend levantado (`npm run dev` en `backend/`), MySQL corriendo (XAMPP).
- Verifica el badge de conexión en la pantalla de login: debe decir
  "Conectado al servidor".
- Ten a la mano las credenciales de admin (`admin@comandapos.com` / `1234`).
- Si quieres mostrar los roles de mesero y barra, créalos antes desde
  **Crear usuario** (menú de admin) — no vienen precargados en el
  backend, a diferencia de admin/cajero/cocina.

## Guion paso a paso

1. **Iniciar sesión** como cajero o mesero.
2. **Abrir Mesa 3**: en la pestaña Mesas, toca la mesa 3 (debe verse
   verde/"Disponible") → escribe el nombre del mesero → "Abrir mesa".
3. **Agregar productos** en la pantalla de Nueva comanda:
   - 4 cervezas (nacional o artesanal).
   - 2 mojitos.
   - 1 alitas.
4. **Agregar una observación**: en el mojito, toca "Agregar nota" →
   escribe "sin azúcar".
5. **Enviar la comanda** (botón "Confirmar orden").
6. **Mostrar barra y cocina**: entra como barra (o desde el acceso
   rápido "Barra" del admin) — debe verse "4 x Cerveza..." y "2 x
   Mojito" con la nota "sin azúcar" visible (ambos productos son de
   barra). Entra a Cocina — debe verse solo "1 x Alitas". Como la
   comanda tiene productos de las dos estaciones, cada tablero
   muestra un aviso de que "Marcar listo" afecta a toda la orden, no
   solo a lo suyo (el backend no rastrea el avance por estación
   todavía).
7. **Marcar productos listos**: desde Barra, "Preparar" → "Marcar
   listo" en la comanda. Repite en Cocina para las alitas.
8. **Agregar una segunda ronda**: vuelve a Mesas → toca la Mesa 3
   (ahora ocupada, ámbar) → "Agregar otra ronda".
   ⚠️ **Nota para quien da la demo:** esta función depende de un
   endpoint que el backend todavía no implementa
   (`POST /api/orders/:id/items`, documentado en `docs/endpoints.md`).
   Hoy muestra un mensaje explicando que falta esa actualización del
   servidor. El resto de la pantalla de Cuenta abierta (mesero,
   productos acumulados, total) sí funciona.
9. **Solicitar la cuenta**: botón "Solicitar cuenta" en la pantalla de
   Cuenta abierta.
10. **Cobrar**:
    - Ve a Cobro → toca la orden de la Mesa 3 → "Cobrar".
    - Elige "Efectivo".
    - Teclea un monto mayor al total (ej. si el total es $270, teclea
      $300).
    - Confirma → debe mostrar el cambio calculado ($30) y liberar la
      mesa.
11. **Mostrar el historial**: pestaña Historial → debe aparecer la
    venta recién hecha con mesa, mesero, productos, método de pago y
    cambio.
12. **Mostrar ventas e inventario**: pestaña Reportes → "Ventas de
    hoy" debe reflejar la venta; pestaña Inventario → el stock de
    cerveza/mojito/alitas debe haber bajado según lo vendido.

## Preguntas para hacerle al dueño del bar

- ¿Cuántas mesas tiene?
- ¿Cuántos empleados trabajan por turno?
- ¿Barra y cocina trabajan separadas, o la misma persona hace ambas?
- ¿Cómo manejan hoy las cuentas abiertas (varias rondas en una mesa)?
- ¿Dividen cuentas entre varios clientes en la misma mesa?
- ¿Cómo controlan el inventario actualmente?
- ¿Usan impresora de tickets?
- ¿Manejan propinas? ¿Cómo las registran hoy?
- ¿Necesitan un corte de caja por turno?
- ¿Tienen una sola sucursal o varias?
- ¿Qué problema tiene el sistema o el método que usan hoy?

## Qué NO mostrar como terminado

- **Dividir cuenta**: aparece en la pantalla de cobro como botón
  deshabilitado con la etiqueta "(próximamente)". No lo presentes como
  funcional.
- **Agregar segunda ronda**: como se explica en el paso 8, funciona en
  la interfaz pero necesita una actualización del backend para
  completarse de extremo a extremo.
- **Pagos mixtos** (parte efectivo, parte tarjeta): no implementado.
