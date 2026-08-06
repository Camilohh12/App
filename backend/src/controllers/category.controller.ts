import { Request, Response } from "express";
import prisma from "../config/prisma.js";

export const getCategories = async (_req: Request, res: Response) => {
  try {
    const categories = await prisma.category.findMany({
      orderBy: { name: "asc" },
    });

    res.status(200).json(categories);
  } catch (error) {
    console.error(error);

    res.status(500).json({
      message: "Error al obtener las categorías",
    });
  }
};

export const createCategory = async (req: Request, res: Response) => {
  try {
    const { name } = req.body;

    if (!name) {
      return res.status(400).json({
        message: "El nombre es obligatorio",
      });
    }

    const category = await prisma.category.create({
      data: { name },
    });

    res.status(201).json(category);
  } catch (error) {
    console.error(error);

    res.status(500).json({
      message: "Error al crear la categoría",
    });
  }
};

export const updateCategory = async (req: Request, res: Response) => {
  try {
    const id = Number(req.params.id);
    const { name } = req.body;

    const category = await prisma.category.update({
      where: { id },
      data: { name },
    });

    res.json(category);
  } catch (error) {
    console.error(error);

    res.status(500).json({
      message: "Error al actualizar la categoría",
    });
  }
};

export const deleteCategory = async (req: Request, res: Response) => {
  try {
    const id = Number(req.params.id);

    await prisma.category.delete({
      where: { id },
    });

    res.json({
      message: "Categoría eliminada correctamente",
    });
  } catch (error) {
    console.error(error);

    res.status(500).json({
      message: "Error al eliminar la categoría",
    });
  }
};
