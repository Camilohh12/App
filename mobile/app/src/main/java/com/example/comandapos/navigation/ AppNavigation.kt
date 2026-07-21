package com.example.comandapos.navigation

import androidx.compose.runtime.Composable
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import com.example.comandapos.screens.HomeScreen
import com.example.comandapos.screens.KitchenScreen
import com.example.comandapos.screens.NewOrderScreen
import com.example.comandapos.screens.ProductsScreen
import com.example.comandapos.screens.HistoryScreen

object Routes {
    const val HOME = "home"
    const val PRODUCTS = "products"
    const val NEW_ORDER = "new_order"
    const val KITCHEN = "kitchen"
    const val HISTORY = "history"
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
                },
                onNewOrderClick = {
                    navController.navigate(Routes.NEW_ORDER)
                },
                onKitchenClick = {
                    navController.navigate(Routes.KITCHEN)
                },
                onHistoryClick = {
                    navController.navigate(Routes.HISTORY)
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

        composable(Routes.NEW_ORDER) {
            NewOrderScreen(
                onBackClick = {
                    navController.popBackStack()
                },
                onOrderConfirmed = {
                    navController.navigate(Routes.KITCHEN) {
                        popUpTo(Routes.HOME)
                    }
                }
            )
        }

        composable(Routes.KITCHEN) {
            KitchenScreen(
                onBackClick = {
                    navController.popBackStack()
                }
            )
        }
        composable(Routes.HISTORY) {
            HistoryScreen(
                onBackClick = {
                    navController.popBackStack()
                }
            )
        }
    }
}