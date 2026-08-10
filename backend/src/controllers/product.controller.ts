import { Request, Response } from "express";
import { Prisma } from "@prisma/client";
import prisma from "../config/prisma.js";

export const getProducts = async (_req: Request, res: Response) => {
  try {
    const products = await prisma.product.findMany({
      include: {
        category: true,
      },
    });

    res.status(200).json(products);
  } catch (error) {
    console.error(error);

    res.status(500).json({
      message: "Error al obtener los productos",
    });
  }
};

export const getProductById = async (req: Request, res: Response) => {
  try {
    const id = Number(req.params.id);

    const product = await prisma.product.findUnique({
      where: { id },
      include: {
        category: true,
      },
    });

    if (!product) {
      return res.status(404).json({
        message: "Producto no encontrado",
      });
    }

    res.json(product);
  } catch (error) {
    console.error(error);

    res.status(500).json({
      message: "Error del servidor",
    });
  }
};

export const createProduct = async (req: Request, res: Response) => {
  try {
    const { name, price, stock, categoryId } = req.body;

    if (!name || price == null || stock == null || !categoryId) {
      return res.status(400).json({
        message: "Todos los campos son obligatorios",
      });
    }

    const product = await prisma.product.create({
      data: {
        name,
        price: Number(price),
        stock: Number(stock),
        categoryId: Number(categoryId),
      },
      include: { category: true },
    });

    res.status(201).json(product);
  } catch (error) {
    if (
      error instanceof Prisma.PrismaClientKnownRequestError &&
      error.code === "P2003"
    ) {
      return res.status(400).json({
        message: "La categoría seleccionada no existe",
      });
    }

    console.error(error);

    res.status(500).json({
      message: "Error al crear el producto",
    });
  }
};

export const updateProduct = async (req: Request, res: Response) => {
  try {
    const id = Number(req.params.id);
    const existing = await prisma.product.findUnique({ where: { id } });

    if (!existing) {
      return res.status(404).json({
        message: "Producto no encontrado",
      });
    }

    const { name, price, stock, categoryId, active } = req.body;

    const product = await prisma.product.update({
      where: { id },
      data: {
        name: name ?? existing.name,
        price: price != null ? Number(price) : existing.price,
        stock: stock != null ? Number(stock) : existing.stock,
        categoryId:
          categoryId != null ? Number(categoryId) : existing.categoryId,
        active: active != null ? Boolean(active) : existing.active,
      },
      include: { category: true },
    });

    res.json(product);
  } catch (error) {
    console.error(error);

    res.status(500).json({
      message: "Error al actualizar el producto",
    });
  }
};

export const updateStock = async (req: Request, res: Response) => {
  try {
    const id = Number(req.params.id);
    const { stock, delta } = req.body as {
      stock?: number;
      delta?: number;
    };

    if (stock == null && delta == null) {
      return res.status(400).json({
        message: "Debes enviar 'stock' (valor exacto) o 'delta' (ajuste)",
      });
    }

    const existing = await prisma.product.findUnique({ where: { id } });

    if (!existing) {
      return res.status(404).json({
        message: "Producto no encontrado",
      });
    }

    const newStock =
      stock != null ? Number(stock) : existing.stock + Number(delta);

    if (newStock < 0) {
      return res.status(400).json({
        message: "El stock no puede quedar negativo",
      });
    }

    const product = await prisma.product.update({
      where: { id },
      data: { stock: newStock },
      include: { category: true },
    });

    res.json(product);
  } catch (error) {
    console.error(error);

    res.status(500).json({
      message: "Error al ajustar el stock",
    });
  }
};

export const deleteProduct = async (req: Request, res: Response) => {
  try {
    const id = Number(req.params.id);

    await prisma.product.delete({
      where: { id },
    });

    res.json({
      message: "Producto eliminado correctamente",
    });
  } catch (error) {
    if (
      error instanceof Prisma.PrismaClientKnownRequestError &&
      error.code === "P2003"
    ) {
      return res.status(409).json({
        message:
          "No se puede eliminar: el producto tiene ventas registradas. " +
          "Desactívalo en su lugar.",
      });
    }

    if (
      error instanceof Prisma.PrismaClientKnownRequestError &&
      error.code === "P2025"
    ) {
      return res.status(404).json({
        message: "Producto no encontrado",
      });
    }

    console.error(error);

    res.status(500).json({
      message: "Error al eliminar el producto",
    });
  }
};