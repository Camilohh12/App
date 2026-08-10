import { Router } from "express";
import * as categoryController from "../controllers/category.controller.js";
import { verifyToken } from "../middlewares/auth.middleware.js";

const router = Router();

router.get("/", categoryController.getCategories);
router.post("/", verifyToken, categoryController.createCategory);
router.put("/:id", verifyToken, categoryController.updateCategory);
router.delete("/:id", verifyToken, categoryController.deleteCategory);

export default router;
