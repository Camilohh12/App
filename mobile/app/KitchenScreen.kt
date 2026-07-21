package com.example.comandapos.screens

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.example.comandapos.data.Order
import com.example.comandapos.data.OrderRepository
import com.example.comandapos.data.OrderStatus

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun KitchenScreen(
    onBackClick: () -> Unit
) {
    val orders = OrderRepository.orders.filter { order ->
        order.status != OrderStatus.COMPLETED
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text("Pedidos de cocina")
                },
                navigationIcon = {
                    IconButton(
                        onClick = onBackClick
                    ) {
                        Text("←")
                    }
                }
            )
        }
    ) { innerPadding ->

        if (orders.isEmpty()) {
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(innerPadding)
                    .padding(24.dp),
                verticalArrangement = Arrangement.Center
            ) {
                Text(
                    text = "No hay pedidos pendientes",
                    style = MaterialTheme.typography.titleLarge
                )
            }
        } else {
            LazyColumn(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(innerPadding),
                contentPadding = PaddingValues(16.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                items(
                    items = orders,
                    key = { order -> order.id }
                ) { order ->
                    KitchenOrderCard(order)
                }
            }
        }
    }
}

@Composable
fun KitchenOrderCard(
    order: Order
) {
    Card(
        modifier = Modifier.fillMaxWidth()
    ) {
        Column(
            modifier = Modifier.padding(16.dp)
        ) {
            Text(
                text = "Orden #${order.id}",
                style = MaterialTheme.typography.titleLarge,
                fontWeight = FontWeight.Bold
            )

            Text(
                text = "Estado: ${statusText(order.status)}",
                modifier = Modifier.padding(top = 4.dp)
            )

            order.items.forEach { item ->
                Text(
                    text = "${item.quantity} x ${item.productName}",
                    modifier = Modifier.padding(top = 6.dp)
                )
            }

            Text(
                text = "Total: $${"%.2f".format(order.total)}",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold,
                modifier = Modifier.padding(top = 12.dp)
            )

            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(top = 12.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                when (order.status) {
                    OrderStatus.PENDING -> {
                        Button(
                            onClick = {
                                OrderRepository.updateStatus(
                                    orderId = order.id,
                                    newStatus = OrderStatus.PREPARING
                                )
                            },
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            Text("Preparar")
                        }
                    }

                    OrderStatus.PREPARING -> {
                        Button(
                            onClick = {
                                OrderRepository.updateStatus(
                                    orderId = order.id,
                                    newStatus = OrderStatus.READY
                                )
                            },
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            Text("Marcar listo")
                        }
                    }

                    OrderStatus.READY -> {
                        Button(
                            onClick = {
                                OrderRepository.updateStatus(
                                    orderId = order.id,
                                    newStatus = OrderStatus.COMPLETED
                                )
                            },
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            Text("Finalizar venta")
                        }
                    }

                    OrderStatus.COMPLETED -> Unit
                }
            }
        }
    }
}

fun statusText(
    status: OrderStatus
): String {
    return when (status) {
        OrderStatus.PENDING -> "Pendiente"
        OrderStatus.PREPARING -> "En preparación"
        OrderStatus.READY -> "Listo"
        OrderStatus.COMPLETED -> "Finalizada"
    }
}