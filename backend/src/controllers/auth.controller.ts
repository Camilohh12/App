import { Request, Response } from "express";
import * as authService from "../services/auth.service.js";
import { HttpError } from "../utils/http-error.js";

const VALID_ROLES = ["admin", "cashier", "kitchen"];

export const register = async (req: Request, res: Response) => {
  try {
    const { name, email, password, role } = req.body;

    if (!name || !email || !password || !role) {
      return res.status(400).json({
        message: "Todos los campos son obligatorios",
      });
    }

    if (!VALID_ROLES.includes(role)) {
      return res.status(400).json({
        message: "Rol inválido. Usa admin, cashier o kitchen",
      });
    }

    const user = await authService.registerUser(
      name,
      email,
      password,
      role
    );

    res.status(201).json(user);
  } catch (error) {
    if (error instanceof HttpError) {
      return res.status(error.status).json({ message: error.message });
    }

    // Cualquier otro error (ej. base de datos inalcanzable) no debe
    // filtrar detalles internos al cliente.
    console.error(error);

    res.status(500).json({
      message: "Error del servidor. Intenta más tarde.",
    });
  }
};

export const login = async (req: Request, res: Response) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({
        message: "Correo y contraseña son obligatorios",
      });
    }

    const result = await authService.loginUser(email, password);

    res.json(result);
  } catch (error) {
    if (error instanceof HttpError) {
      return res.status(error.status).json({ message: error.message });
    }

    // Cualquier otro error (ej. base de datos inalcanzable) no debe
    // filtrar detalles internos al cliente.
    console.error(error);

    res.status(500).json({
      message: "Error del servidor. Intenta más tarde.",
    });
  }
};