import { Router } from "express";
import * as tableController from "../controllers/table.controller.js";

const router = Router();

router.get("/", tableController.getTables);

export default router;
