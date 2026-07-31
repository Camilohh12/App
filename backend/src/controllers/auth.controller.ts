import { Request, Response } from "express";
import * as authService from "../services/auth.service.js";

export const register = async (req: Request, res: Response) => {
  try {
    const { name, email, password, role } = req.body;

    if (!name || !email || !password || !role) {
      return res.status(400).json({
        message: "Todos los campos son obligatorios",
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
    res.status(400).json({
      message: error instanceof Error ? error.message : "Error al registrar usuario",
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
    res.status(401).json({
      message: error instanceof Error ? error.message : "Credenciales incorrectas",
    });
  }
};