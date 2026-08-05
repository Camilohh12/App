import prisma from "../config/prisma.js";
import { EstadoMesa, EstadoPedido } from "@prisma/client";

interface ProductRequest {
  productId: number;
  quantity: number;
}

interface CreateOrderDTO {
  mesaId: number;
  products: ProductRequest[];
}

export const validateOrder = async (
  userId: number,
  data: CreateOrderDTO
) => {
  // Buscar la mesa
  const table = await prisma.mesa.findUnique({
    where: {
      id: data.mesaId,
    },
  });

  if (!table) {
    throw new Error("La mesa no existe");
  }

  // Verificar estado: no tomar orden en mesa reservada
  if (table.status === EstadoMesa.RESERVADA) {
    throw new Error("La mesa está reservada");
  }

  // Opcional: impedir crear una orden si ya existe una orden abierta
  const openOrder = await prisma.order.findFirst({
    where: {
      mesaId: data.mesaId,
      status: {
        in: [
          EstadoPedido.PENDIENTE,
          EstadoPedido.PREPARANDO,
          EstadoPedido.LISTO,
        ],
      },
    },
  });

  if (openOrder) {
    throw new Error("La mesa ya tiene una orden abierta");
  }

  // Validar que el pedido contenga al menos un producto
  if (!data.products || data.products.length === 0) {
    throw new Error("El pedido debe contener al menos un producto");
  }

  const ids = data.products.map((p) => p.productId);
  const uniqueIds = new Set(ids);

  if (ids.length !== uniqueIds.size) {
    throw new Error("Hay productos repetidos en el pedido");
  }

  // Variables
  let total = 0;
  const details: { productId: number; quantity: number; subtotal: number }[] = [];

  // Recorrer productos
  for (const item of data.products) {
    if (item.quantity <= 0) {
      throw new Error("La cantidad debe ser mayor que cero");
    }

    // Buscar el producto
    const product = await prisma.product.findUnique({
      where: { id: item.productId },
    });

    // Validar
    if (!product) {
      throw new Error(`Producto ${item.productId} no existe`);
    }

    // Revisar inventario
    if (product.stock < item.quantity) {
      throw new Error(`${product.name} no tiene suficiente stock`);
    }

    // Calcular subtotal
    const subtotal = product.price * item.quantity;
    total += subtotal;

    // Guardar detalle
    details.push({
      productId: product.id,
      quantity: item.quantity,
      subtotal,
    });
  }

  // Regresar el resumen (aún no guardamos nada)
  return {
    userId,
    table,
    details,
    total,
  };
};

export const createOrder = async (
  userId: number,
  data: CreateOrderDTO
) => {
  // Reutilizamos toda la validación
  const orderData = await validateOrder(userId, data);

  return await prisma.$transaction(async (tx) => {

    // 1. Crear el pedido
    const order = await tx.order.create({
      data: {
        userId,
        mesaId: data.mesaId,
        total: orderData.total,
      },
    });

    // 2. Crear detalles
    for (const detail of orderData.details) {
      await tx.orderDetail.create({
        data: {
          orderId: order.id,
          productId: detail.productId,
          quantity: detail.quantity,
          subtotal: detail.subtotal,
        },
      });
    }

    // 3. Cambiar estado de la mesa
    await tx.mesa.update({
      where: {
        id: data.mesaId,
      },
      data: {
        status: EstadoMesa.OCUPADA,
      },
    });

    // 4. Descontar inventario
    for (const detail of orderData.details) {
      await tx.product.update({
        where: {
          id: detail.productId,
        },
        data: {
          stock: {
            decrement: detail.quantity,
          },
        },
      });
    }

    return order;
  });
};