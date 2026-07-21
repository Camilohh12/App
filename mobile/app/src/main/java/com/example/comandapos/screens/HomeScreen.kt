package com.example.comandapos.screens

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material3.Button
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.example.comandapos.components.SummaryCard
import com.example.comandapos.data.OrderRepository
import com.example.comandapos.data.OrderStatus

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun HomeScreen(
    onProductsClick: () -> Unit,
    onNewOrderClick: () -> Unit,
    onKitchenClick: () -> Unit,
    onHistoryClick: () -> Unit
) {
    val orders = OrderRepository.orders

    val pendingOrders = orders.count { order ->
        order.status != OrderStatus.COMPLETED
    }

    val completedSales = orders
        .filter { order ->
            order.status == OrderStatus.COMPLETED
        }
        .sumOf { order ->
            order.total
        }

    val availableProducts = 4
    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Column {
                        Text(
                            text = "ComandaPOS",
                            fontWeight = FontWeight.Bold
                        )

                        Text(
                            text = "Punto de venta para negocios de comida",
                            style = MaterialTheme.typography.bodySmall
                        )
                    }
                }
            )
        },
        floatingActionButton = {
            FloatingActionButton(
                    onClick = onNewOrderClick
            ) {
                Text("+")
            }
        }
    ) { innerPadding ->

        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding),
            contentPadding = PaddingValues(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            item {
                Text(
                    text = "Panel principal",
                    style = MaterialTheme.typography.headlineSmall,
                    fontWeight = FontWeight.Bold
                )
            }

            item {
                SummaryCard(
                    title = "Ventas del día",
                    value = "$${"%.2f".format(completedSales)}"
                )
            }

            item {
                SummaryCard(
                    title = "Órdenes pendientes",
                    value = pendingOrders.toString()
                )
            }

            item {
                SummaryCard(
                    title = "Productos disponibles",
                    value = availableProducts.toString()
                )
            }

            item {
                Button(
                    onClick = onProductsClick,
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Text("Ver productos")
                }
            }

            item {
                Button(
                    onClick = onKitchenClick,
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Text("Pedidos de cocina")
                }
            }

            item {
                Button(
                    onClick = onHistoryClick,
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Text("Historial de ventas")
                }
            }
        }
    }
}
