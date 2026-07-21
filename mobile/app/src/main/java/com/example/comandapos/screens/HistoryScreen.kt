package com.example.comandapos.screens

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
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
fun HistoryScreen(
    onBackClick: () -> Unit
) {
    val completedOrders = OrderRepository.orders.filter {
        it.status == OrderStatus.COMPLETED
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text("Historial de ventas")
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

        if (completedOrders.isEmpty()) {
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(innerPadding)
                    .padding(24.dp),
                verticalArrangement = Arrangement.Center
            ) {
                Text(
                    text = "No hay ventas finalizadas",
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
                    items = completedOrders,
                    key = { order -> order.id }
                ) { order ->
                    HistoryOrderCard(order)
                }
            }
        }
    }
}

@Composable
fun HistoryOrderCard(
    order: Order
) {
    Card(
        modifier = Modifier.fillMaxWidth()
    ) {
        Column(
            modifier = Modifier.padding(16.dp)
        ) {
            Text(
                text = "Venta #${order.id}",
                style = MaterialTheme.typography.titleLarge,
                fontWeight = FontWeight.Bold
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

            Text(
                text = "Estado: Finalizada",
                modifier = Modifier.padding(top = 4.dp)
            )
        }
    }
}