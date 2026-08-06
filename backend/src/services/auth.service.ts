import prisma from "../config/prisma.js";
import bcrypt from "bcrypt";
import jwt, { SignOptions } from "jsonwebtoken";
import { HttpError } from "../utils/http-error.js";

export const registerUser = async (
  name: string,
  email: string,
  password: string,
  role: string
) => {

  const userExists = await prisma.user.findUnique({
    where: { email },
  });

  if (userExists) {
    throw new HttpError(409, "El correo ya está registrado");
  }

  const hashedPassword = await bcrypt.hash(password, 10);

  const user = await prisma.user.create({
    data: {
      name,
      email,
      password: hashedPassword,
      role,
    },
    select: {
      id: true,
      name: true,
      email: true,
      role: true,
    },
  });

  return user;
};

export const loginUser = async (
  email: string,
  password: string
) => {

  const user = await prisma.user.findUnique({
    where: { email },
  });

  if (!user) {
    throw new HttpError(401, "Credenciales incorrectas");
  }

  const validPassword = await bcrypt.compare(
    password,
    user.password
  );

  if (!validPassword) {
    throw new HttpError(401, "Credenciales incorrectas");
  }

  const secret = process.env.JWT_SECRET;
  const expiresIn = process.env.JWT_EXPIRES_IN;

  if (!secret) {
    throw new Error("JWT_SECRET no está definido");
  }

  const options: SignOptions = {
    expiresIn: (expiresIn ?? "1h") as SignOptions["expiresIn"],
  };

  const token = jwt.sign(
    {
      id: user.id,
      role: user.role,
    },
    secret,
    options
  );

  return {
    token,
    user: {
      id: user.id,
      name: user.name,
      email: user.email,
      role: user.role,
    },
  };
};