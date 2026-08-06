import { Router } from "express";
import * as productController from "../controllers/product.controller.js";
import { requireRole, verifyToken } from "../middlewares/auth.middleware.js";

const router = Router();

router.get("/", productController.getProducts);
router.get("/:id", productController.getProductById);

// Gestión de inventario: solo administrador (igual que la pantalla
// de Inventario en la app, que ya es de acceso exclusivo admin).
router.post(
  "/",
  verifyToken,
  requireRole("admin"),
  productController.createProduct,
);
router.put(
  "/:id",
  verifyToken,
  requireRole("admin"),
  productController.updateProduct,
);
router.patch(
  "/:id/stock",
  verifyToken,
  requireRole("admin"),
  productController.updateStock,
);
router.delete(
  "/:id",
  verifyToken,
  requireRole("admin"),
  productController.deleteProduct,
);

export default router;