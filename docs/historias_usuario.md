# Historias de usuario

Formato: Como [rol], quiero [acción], para [beneficio]. Todas las
historias listadas aquí están implementadas en la app actual, salvo
que se indique lo contrario.

## Administrador

1. Como administrador, quiero iniciar sesión con mi correo y
   contraseña, para acceder al panel según mi rol.
2. Como administrador, quiero ver mesas, comandas de barra/cocina,
   inventario, historial y reportes desde un mismo panel, para tener
   control completo del negocio.
3. Como administrador, quiero crear nuevos usuarios (cajero, mesero,
   cocina, barra u otro administrador), para dar acceso al personal
   sin depender de otra herramienta.
4. Como administrador, quiero cancelar una orden pendiente o en
   preparación, con confirmación previa, para corregir errores sin
   afectar el inventario ni las ventas.
5. Como administrador, quiero crear productos nuevos y ajustar su
   stock (sumar, restar, o fijar una cantidad exacta), para mantener
   el inventario actualizado.
6. Como administrador, quiero activar o desactivar un producto, para
   ocultarlo temporalmente de Nueva orden sin perder su historial de
   ventas.
7. Como administrador, quiero consultar reportes semanales o
   mensuales con ventas totales, ticket promedio, ingresos por día,
   ventas por categoría, ventas por método de pago y productos con
   stock bajo, para tomar decisiones de negocio.

## Cajero

8. Como cajero, quiero crear una nueva comanda eligiendo productos,
   tipo de servicio (en mesa o para llevar) y mesa, para enviarla a
   barra/cocina.
9. Como cajero, quiero escanear el código QR de una mesa, para abrir
   una nueva comanda o ver su cuenta abierta sin buscarla manualmente.
10. Como cajero, quiero cobrar una orden lista, eligiendo el método de
    pago y calculando el cambio en efectivo, para finalizar la venta.
11. Como cajero, quiero ver el mesero y la mesa de cada cuenta al
    momento de cobrar, para confirmar que estoy cobrando la cuenta
    correcta.

## Mesero

12. Como mesero, quiero abrir una mesa disponible y asignarle mi
    nombre, para que quede registrado quién la está atendiendo.
13. Como mesero, quiero consultar cuentas abiertas y comandas listas
    para servir, para saber a qué mesa llevar cada pedido.
14. Como mesero, quiero ver el total acumulado de una cuenta abierta,
    para informarle al cliente cuánto lleva antes de cobrar.

## Cocina

15. Como cocina, quiero ver únicamente los productos de cocina de
    cada comanda activa (no los de barra), con su mesa, hora de
    llegada y observaciones, para preparar solo lo que me corresponde.
16. Como cocina, quiero cambiar el estado de una comanda (pendiente →
    en preparación → lista), para coordinar la preparación con el
    resto del equipo.

## Barra

17. Como barra, quiero ver únicamente los productos de barra de cada
    comanda activa (bebidas, cócteles, etc.), para preparar solo lo
    que me corresponde, sin poder cobrar ni cancelar órdenes.

## Transversal (todos los roles operativos)

18. Como usuario de cualquier rol, quiero que las órdenes, mesas y
    productos se actualicen solos en segundo plano, para no depender
    de refrescar manualmente cada pantalla.
19. Como cajero o mesero, quiero consultar la ubicación GPS de la
    terminal, para registrar desde dónde se abrió la caja o el turno.

## Pendientes (no implementadas todavía)

- Como mesero, quiero agregar una segunda ronda a una cuenta ya
  abierta y que quede reflejada de inmediato en barra/cocina — la
  interfaz existe, pero depende de un endpoint del backend que aún no
  se implementa (`POST /api/orders/:id/items`, ver `endpoints.md`).
- Como cajero, quiero dividir una cuenta entre varios clientes de la
  misma mesa — señalada como mejora futura, sin implementar.
