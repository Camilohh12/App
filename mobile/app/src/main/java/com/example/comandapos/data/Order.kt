package com.example.comandapos.data

data class OrderItem(
    val productId: Int,
    val productName: String,
    val quantity: Int,
    val unitPrice: Double
) {
    val subtotal: Double
        get() = quantity * unitPrice
}

data class Order(
    val id: Int,
    val items: List<OrderItem>,
    val total: Double,
    val status: OrderStatus = OrderStatus.PENDING
)

enum class OrderStatus {
    PENDING,
    PREPARING,
    READY,
    COMPLETED
}
