import "dotenv/config";
import bcrypt from "bcrypt";
import prisma from "../src/config/prisma.js";

async function main() {
  const password = await bcrypt.hash("1234", 10);

  await prisma.user.createMany({
    data: [
      {
        name: "Administrador",
        email: "admin@comandapos.com",
        password,
        role: "admin",
      },
      {
        name: "Cajero",
        email: "cajero@comandapos.com",
        password,
        role: "cashier",
      },
      {
        name: "Cocina",
        email: "cocina@comandapos.com",
        password,
        role: "kitchen",
      },
    ],
    skipDuplicates: true,
  });

  const categoryNames = [
    "Hamburguesas",
    "Complementos",
    "Bebidas",
    "Postres",
  ];

  for (const name of categoryNames) {
    await prisma.category.upsert({
      where: { id: categoryNames.indexOf(name) + 1 },
      update: {},
      create: { name },
    });
  }

  const categories = await prisma.category.findMany();
  const categoryIdByName = new Map(
    categories.map((category) => [category.name, category.id]),
  );

  const products: {
    name: string;
    price: number;
    stock: number;
    category: string;
  }[] = [
    {
      name: "Hamburguesa clásica",
      price: 75,
      stock: 15,
      category: "Hamburguesas",
    },
    {
      name: "Papas fritas",
      price: 40,
      stock: 20,
      category: "Complementos",
    },
    {
      name: "Refresco",
      price: 25,
      stock: 30,
      category: "Bebidas",
    },
    {
      name: "Pastel de chocolate",
      price: 45,
      stock: 8,
      category: "Postres",
    },
  ];

  for (const product of products) {
    const categoryId = categoryIdByName.get(product.category);

    if (!categoryId) continue;

    const existing = await prisma.product.findFirst({
      where: { name: product.name },
    });

    if (existing) continue;

    await prisma.product.create({
      data: {
        name: product.name,
        price: product.price,
        stock: product.stock,
        categoryId,
      },
    });
  }

  for (let number = 1; number <= 8; number += 1) {
    await prisma.table.upsert({
      where: { number },
      update: {},
      create: {
        number,
        status: "available",
        qrCode: `MESA-${number}`,
      },
    });
  }

  console.log("Seed completado");
}

main()
  .catch((error) => {
    console.error(error);
    process.exitCode = 1;
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
