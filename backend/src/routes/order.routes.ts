import { Router } from "express";
import * as orderController from "../controllers/order.controller.js";
import { verifyToken } from "../middlewares/auth.middleware.js";

const router = Router();

router.use(verifyToken);

router.post("/", orderController.createOrder);
router.get("/", orderController.getOrders);
router.patch("/:id/status", orderController.updateOrderStatus);

export default router;
