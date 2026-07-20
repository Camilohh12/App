package com.example.comandapos.navigation

import androidx.compose.runtime.Composable
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import com.example.comandapos.screens.HomeScreen
import com.example.comandapos.screens.ProductsScreen

object Routes {
    const val HOME = "home"
    const val PRODUCTS = "products"
}

@Composable
fun AppNavigation() {
    val navController = rememberNavController()

    NavHost(
        navController = navController,
        startDestination = Routes.HOME
    ) {
        composable(Routes.HOME) {
            HomeScreen(
                onProductsClick = {
                    navController.navigate(Routes.PRODUCTS)
                }
            )
        }

        composable(Routes.PRODUCTS) {
            ProductsScreen(
                onBackClick = {
                    navController.popBackStack()
                }
            )
        }
    }
}