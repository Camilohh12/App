import { Response } from "express";
import prisma from "../config/prisma.js";
import { AuthRequest } from "../middlewares/auth.middleware.js";
import { HttpError } from "../utils/http-error.js";

const PAYMENT_METHODS = ["cash", "card", "transfer"];

export const createPayment = async (req: AuthRequest, res: Response) => {
  try {
    const { orderId, paymentMethod, amountReceived } = req.body as {
      orderId?: number;
      paymentMethod?: string;
      amountReceived?: number;
    };

    if (!orderId || !paymentMethod) {
      return res.status(400).json({
        message: "orderId y paymentMethod son obligatorios",
      });
    }

    if (!PAYMENT_METHODS.includes(paymentMethod)) {
      return res.status(400).json({
        message: "Método de pago inválido",
      });
    }

    const order = await prisma.$transaction(async (tx) => {
      const existing = await tx.order.findUnique({
        where: { id: orderId },
        include: { details: true },
      });

      if (!existing) {
        throw new HttpError(404, "Orden no encontrada");
      }

      if (existing.status !== "ready") {
        throw new HttpError(409, "La orden no está lista para cobro");
      }

      const received =
        paymentMethod === "cash"
          ? Number(amountReceived ?? 0)
          : existing.total;

      if (paymentMethod === "cash" && received < existing.total) {
        throw new HttpError(400, "El monto recibido es menor al total");
      }

      // Agrupa cantidades por producto para no subestimar el stock
      // requerido cuando el mismo producto aparece en varios items.
      const quantityByProduct = new Map<number, number>();

      for (const detail of existing.details) {
        quantityByProduct.set(
          detail.productId,
          (quantityByProduct.get(detail.productId) ?? 0) + detail.quantity,
        );
      }

      const products = await tx.product.findMany({
        where: { id: { in: [...quantityByProduct.keys()] } },
      });

      for (const product of products) {
        const needed = quantityByProduct.get(product.id) ?? 0;

        if (product.stock < needed) {
          throw new HttpError(
            400,
            `Stock insuficiente para ${product.name}`,
          );
        }
      }

      for (const [productId, quantity] of quantityByProduct.entries()) {
        await tx.product.update({
          where: { id: productId },
          data: { stock: { decrement: quantity } },
        });
      }

      const change =
        paymentMethod === "cash" ? received - existing.total : 0;

      const updatedOrder = await tx.order.update({
        where: { id: orderId },
        data: {
          status: "completed",
          paymentMethod,
          amountReceived: received,
          change,
          completedAt: new Date(),
        },
        include: {
          details: { include: { product: true } },
          table: true,
          user: { select: { id: true, name: true, email: true, role: true } },
        },
      });

      if (existing.tableId) {
        await tx.table.update({
          where: { id: existing.tableId },
          data: { status: "available" },
        });
      }

      return updatedOrder;
    });

    res.status(201).json(order);
  } catch (error) {
    if (error instanceof HttpError) {
      return res.status(error.status).json({ message: error.message });
    }

    console.error(error);

    res.status(500).json({
      message: "Error al procesar el pago",
    });
  }
};
