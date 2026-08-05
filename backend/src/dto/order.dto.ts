export interface CreateOrderDTO {

    mesaId:number;

    products:{

        productId:number;

        quantity:number;

    }[];

}