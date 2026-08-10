import { Router } from "express";
import * as paymentController from "../controllers/payment.controller.js";
import { verifyToken } from "../middlewares/auth.middleware.js";

const router = Router();

router.post("/", verifyToken, paymentController.createPayment);

export default router;
