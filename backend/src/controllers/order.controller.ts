import { Request, Response } from "express";
import { createOrder as createOrderService } from "../services/order.service.js";
import { AuthRequest } from "../middlewares/auth.middleware.js";

export const createOrder = async(
    req:AuthRequest,
    res:Response
)=>{

    try{

        const order = await createOrderService(
            req.user!.id,
            req.body
        );

        res.status(201).json(order);

    }catch(error){

        res.status(400).json({

            message:(error as Error).message

        });

    }

}