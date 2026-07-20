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

data class Product(
    val id: Int,
    val name: String,
    val price: Double,
    val category: String
)

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ProductsScreen(
    onBackClick: () -> Unit
) {
    val products = listOf(
        Product(1, "Hamburguesa clásica", 75.0, "Hamburguesas"),
        Product(2, "Papas fritas", 40.0, "Complementos"),
        Product(3, "Refresco", 25.0, "Bebidas"),
        Product(4, "Pastel de chocolate", 45.0, "Postres")
    )

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text("Productos")
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

        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding),
            contentPadding = PaddingValues(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            items(
                items = products,
                key = { product -> product.id }
            ) { product ->
                ProductCard(product)
            }
        }
    }
}

@Composable
fun ProductCard(
    product: Product
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
                text = product.category,
                style = MaterialTheme.typography.bodyMedium
            )

            Text(
                text = "$${"%.2f".format(product.price)}",
                style = MaterialTheme.typography.titleLarge,
                modifier = Modifier.padding(top = 8.dp)
            )
        }
    }
}