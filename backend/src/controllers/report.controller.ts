import { Request, Response } from "express";
import prisma from "../config/prisma.js";

export const getDailyReport = async (_req: Request, res: Response) => {
  try {
    const startOfDay = new Date();
    startOfDay.setHours(0, 0, 0, 0);

    const endOfDay = new Date();
    endOfDay.setHours(23, 59, 59, 999);

    const orders = await prisma.order.findMany({
      where: {
        status: "completed",
        completedAt: {
          gte: startOfDay,
          lte: endOfDay,
        },
      },
    });

    const totalSales = orders.reduce(
      (sum, order) => sum + order.total,
      0,
    );

    res.json({
      date: startOfDay.toISOString().slice(0, 10),
      totalSales,
      orderCount: orders.length,
    });
  } catch (error) {
    console.error(error);

    res.status(500).json({
      message: "Error al generar el reporte",
    });
  }
};

export const getSummaryReport = async (req: Request, res: Response) => {
  try {
    const period = req.query.period === "monthly" ? "monthly" : "weekly";
    const days = period === "monthly" ? 30 : 7;

    const end = new Date();
    end.setHours(23, 59, 59, 999);

    const start = new Date();
    start.setDate(start.getDate() - (days - 1));
    start.setHours(0, 0, 0, 0);

    const orders = await prisma.order.findMany({
      where: {
        status: "completed",
        completedAt: { gte: start, lte: end },
      },
      include: {
        details: {
          include: {
            product: { include: { category: true } },
          },
        },
      },
    });

    const totalSales = orders.reduce((sum, order) => sum + order.total, 0);
    const orderCount = orders.length;

    const dailyMap = new Map<string, number>();

    for (const order of orders) {
      const key = order.completedAt!.toISOString().slice(0, 10);
      dailyMap.set(key, (dailyMap.get(key) ?? 0) + order.total);
    }

    const dailyRevenue = Array.from(dailyMap.entries())
      .map(([date, total]) => ({ date, total }))
      .sort((a, b) => a.date.localeCompare(b.date));

    const categoryMap = new Map<string, number>();
    const itemMap = new Map<
      number,
      { name: string; quantity: number; totalRevenue: number }
    >();

    for (const order of orders) {
      for (const detail of order.details) {
        const categoryName = detail.product.category.name;

        categoryMap.set(
          categoryName,
          (categoryMap.get(categoryName) ?? 0) + detail.subtotal,
        );

        const existingItem = itemMap.get(detail.productId);

        if (existingItem) {
          existingItem.quantity += detail.quantity;
          existingItem.totalRevenue += detail.subtotal;
        } else {
          itemMap.set(detail.productId, {
            name: detail.product.name,
            quantity: detail.quantity,
            totalRevenue: detail.subtotal,
          });
        }
      }
    }

    const categoryBreakdown = Array.from(categoryMap.entries())
      .map(([category, total]) => ({
        category,
        total,
        percentage: totalSales > 0 ? (total / totalSales) * 100 : 0,
      }))
      .sort((a, b) => b.total - a.total);

    const topItems = Array.from(itemMap.values())
      .sort((a, b) => b.totalRevenue - a.totalRevenue)
      .slice(0, 5);

    res.json({
      period,
      totalSales,
      orderCount,
      dailyRevenue,
      categoryBreakdown,
      topItems,
    });
  } catch (error) {
    console.error(error);

    res.status(500).json({
      message: "Error al generar el reporte",
    });
  }
};
