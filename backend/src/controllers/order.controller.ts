import { Response } from "express";
import prisma from "../config/prisma.js";
import { AuthRequest } from "../middlewares/auth.middleware.js";
import { HttpError } from "../utils/http-error.js";

const ORDER_INCLUDE = {
  details: { include: { product: true } },
  table: true,
  user: { select: { id: true, name: true, email: true, role: true } },
} as const;

interface OrderItemInput {
  productId: number;
  quantity: number;
  note?: string;
}

export const createOrder = async (req: AuthRequest, res: Response) => {
  try {
    const userId = req.user?.id;

    if (!userId) {
      return res.status(401).json({ message: "No autenticado" });
    }

    const { tableId, serviceType, items } = req.body as {
      tableId?: number;
      serviceType?: string;
      items?: OrderItemInput[];
    };

    if (!items || items.length === 0) {
      return res.status(400).json({
        message: "La orden debe tener al menos un producto",
      });
    }

    const normalizedServiceType =
      serviceType === "dineIn" ? "dineIn" : "takeaway";

    if (normalizedServiceType === "dineIn" && !tableId) {
      return res.status(400).json({
        message: "Debes seleccionar una mesa",
      });
    }

    const order = await prisma.$transaction(async (tx) => {
      if (normalizedServiceType === "dineIn") {
        const table = await tx.table.findUnique({
          where: { id: tableId! },
        });

        if (!table) {
          throw new HttpError(404, "La mesa no existe");
        }

        if (table.status !== "available") {
          throw new HttpError(409, "La mesa ya está ocupada");
        }
      }

      const productIds = [...new Set(items.map((item) => item.productId))];

      const products = await tx.product.findMany({
        where: { id: { in: productIds } },
      });

      if (products.length !== productIds.length) {
        throw new HttpError(400, "Uno o más productos no existen");
      }

      const productById = new Map(products.map((p) => [p.id, p]));

      let total = 0;

      const detailsData = items.map((item) => {
        const product = productById.get(item.productId)!;
        const subtotal = product.price * item.quantity;
        total += subtotal;

        return {
          productId: item.productId,
          quantity: item.quantity,
          subtotal,
          note: item.note ?? null,
        };
      });

      const createdOrder = await tx.order.create({
        data: {
          status: "pending",
          total,
          serviceType: normalizedServiceType,
          tableId: normalizedServiceType === "dineIn" ? tableId : null,
          userId,
          details: {
            create: detailsData,
          },
        },
        include: ORDER_INCLUDE,
      });

      if (normalizedServiceType === "dineIn") {
        await tx.table.update({
          where: { id: tableId! },
          data: { status: "occupied" },
        });
      }

      return createdOrder;
    });

    res.status(201).json(order);
  } catch (error) {
    if (error instanceof HttpError) {
      return res.status(error.status).json({ message: error.message });
    }

    console.error(error);

    res.status(500).json({
      message: "Error al crear la orden",
    });
  }
};

export const getOrders = async (req: AuthRequest, res: Response) => {
  try {
    const { status } = req.query;

    const orders = await prisma.order.findMany({
      where: status ? { status: String(status) } : undefined,
      include: ORDER_INCLUDE,
      orderBy: { date: "desc" },
    });

    res.json(orders);
  } catch (error) {
    console.error(error);

    res.status(500).json({
      message: "Error al obtener las órdenes",
    });
  }
};

const CANCELABLE_STATUSES = ["pending", "preparing"];
const UPDATABLE_STATUSES = ["preparing", "ready", "cancelled"];

export const updateOrderStatus = async (req: AuthRequest, res: Response) => {
  try {
    const id = Number(req.params.id);
    const { status } = req.body as { status?: string };

    if (!status || !UPDATABLE_STATUSES.includes(status)) {
      return res.status(400).json({
        message: "Estado inválido. Usa preparing, ready o cancelled",
      });
    }

    if (status === "cancelled" && req.user?.role !== "admin") {
      return res.status(403).json({
        message: "Solo un administrador puede cancelar órdenes",
      });
    }

    const order = await prisma.$transaction(async (tx) => {
      const existing = await tx.order.findUnique({ where: { id } });

      if (!existing) {
        throw new HttpError(404, "Orden no encontrada");
      }

      if (status === "cancelled" &&
          !CANCELABLE_STATUSES.includes(existing.status)) {
        throw new HttpError(
          409,
          "Solo se pueden cancelar órdenes pendientes o en preparación",
        );
      }

      if (status !== "cancelled" &&
          ["completed", "cancelled"].includes(existing.status)) {
        throw new HttpError(409, "La orden ya fue finalizada o cancelada");
      }

      const updated = await tx.order.update({
        where: { id },
        data: { status },
        include: ORDER_INCLUDE,
      });

      if (status === "cancelled" && existing.tableId) {
        await tx.table.update({
          where: { id: existing.tableId },
          data: { status: "available" },
        });
      }

      return updated;
    });

    res.json(order);
  } catch (error) {
    if (error instanceof HttpError) {
      return res.status(error.status).json({ message: error.message });
    }

    console.error(error);

    res.status(500).json({
      message: "Error al actualizar la orden",
    });
  }
};
