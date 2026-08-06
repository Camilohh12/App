import { Router } from "express";
import * as authController from "../controllers/auth.controller.js";
import { requireRole, verifyToken } from "../middlewares/auth.middleware.js";

const router = Router();

// Solo un administrador autenticado puede crear nuevos usuarios.
router.post(
  "/register",
  verifyToken,
  requireRole("admin"),
  authController.register,
);
router.post("/login", authController.login);

export default router;