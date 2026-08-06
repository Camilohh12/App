import { Router } from "express";
import * as reportController from "../controllers/report.controller.js";
import { verifyToken } from "../middlewares/auth.middleware.js";

const router = Router();

router.get("/daily", verifyToken, reportController.getDailyReport);
router.get("/summary", verifyToken, reportController.getSummaryReport);

export default router;
