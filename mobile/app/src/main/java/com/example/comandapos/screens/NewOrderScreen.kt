package com.example.comandapos.screens

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
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
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateMapOf
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import android.widget.Toast
import androidx.compose.ui.platform.LocalContext
import com.example.comandapos.data.Order
import com.example.comandapos.data.OrderItem
import com.example.comandapos.data.OrderRepository

data class OrderProduct(
    val id: Int,
    val name: String,
    val price: Double
)

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun NewOrderScreen(
    onBackClick: () -> Unit,
    onOrderConfirmed: () -> Unit
) {
    val products = listOf(
        OrderProduct(1, "Hamburguesa clásica", 75.0),
        OrderProduct(2, "Papas fritas", 40.0),
        OrderProduct(3, "Refresco", 25.0),
        OrderProduct(4, "Pastel de chocolate", 45.0)
    )
    val context = LocalContext.current

    val quantities = remember {
        mutableStateMapOf<Int, Int>()
    }

    val total by remember(quantities.toMap()) {
        androidx.compose.runtime.derivedStateOf {
            products.sumOf { product ->
                product.price * (quantities[product.id] ?: 0)
            }
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text("Nueva orden")
                },
                navigationIcon = {
                    IconButton(
                        onClick = onBackClick
                    ) {
                        Text("←")
                    }
                }
            )
        },
        bottomBar = {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(16.dp)
            ) {
                Text(
                    text = "Total: $${"%.2f".format(total)}",
                    style = MaterialTheme.typography.headlineSmall,
                    fontWeight = FontWeight.Bold
                )

                Button(
                    onClick = {
                        val selectedItems = products.mapNotNull { product ->
                            val quantity = quantities[product.id] ?: 0

                            if (quantity > 0) {
                                OrderItem(
                                    productId = product.id,
                                    productName = product.name,
                                    quantity = quantity,
                                    unitPrice = product.price
                                )
                            } else {
                                null
                            }
                        }

                        val newOrder = Order(
                            id = OrderRepository.orders.size + 1,
                            items = selectedItems,
                            total = total
                        )

                        OrderRepository.addOrder(newOrder)

                        Toast.makeText(
                            context,
                            "Orden enviada a cocina",
                            Toast.LENGTH_SHORT
                        ).show()

                        onOrderConfirmed()
                    }
                ) {
                    Text("Confirmar orden")
                }
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
                    text = "Selecciona los productos",
                    style = MaterialTheme.typography.titleLarge,
                    fontWeight = FontWeight.Bold
                )
            }

            items(
                items = products,
                key = { product -> product.id }
            ) { product ->

                val quantity = quantities[product.id] ?: 0

                OrderProductCard(
                    product = product,
                    quantity = quantity,
                    onIncrease = {
                        quantities[product.id] = quantity + 1
                    },
                    onDecrease = {
                        if (quantity > 1) {
                            quantities[product.id] = quantity - 1
                        } else {
                            quantities.remove(product.id)
                        }
                    }
                )
            }
        }
    }
}

@Composable
fun OrderProductCard(
    product: OrderProduct,
    quantity: Int,
    onIncrease: () -> Unit,
    onDecrease: () -> Unit
) {
    Card(
        modifier = Modifier.fillMaxWidth()
    ) {
        Column(
            modifier = Modifier.padding(16.dp)
        ) {
            Text(
                text = product.name,
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold
            )

            Text(
                text = "$${"%.2f".format(product.price)}",
                style = MaterialTheme.typography.bodyLarge,
                modifier = Modifier.padding(top = 4.dp)
            )

            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(top = 12.dp),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Button(
                    onClick = onDecrease,
                    enabled = quantity > 0
                ) {
                    Text("-")
                }

                Text(
                    text = quantity.toString(),
                    style = MaterialTheme.typography.titleLarge,
                    fontWeight = FontWeight.Bold
                )

                Button(
                    onClick = onIncrease
                ) {
                    Text("+")
                }
            }
        }
    }
}