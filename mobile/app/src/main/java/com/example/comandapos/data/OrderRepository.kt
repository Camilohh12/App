package com.example.comandapos.data

import androidx.compose.runtime.mutableStateListOf

object OrderRepository {

    private val _orders = mutableStateListOf<Order>()

    val orders: List<Order>
        get() = _orders

    fun addOrder(order: Order) {
        _orders.add(order)
    }

    fun updateStatus(
        orderId: Int,
        newStatus: OrderStatus
    ) {
        val index = _orders.indexOfFirst { it.id == orderId }

        if (index != -1) {
            _orders[index] = _orders[index].copy(
                status = newStatus
            )
        }
    }
}