import { Request, Response } from "express";
import prisma from "../config/prisma.js";

export const getTables = async (_req: Request, res: Response) => {
  try {
    const tables = await prisma.table.findMany({
      orderBy: { number: "asc" },
    });

    res.status(200).json(tables);
  } catch (error) {
    console.error(error);

    res.status(500).json({
      message: "Error al obtener las mesas",
    });
  }
};
