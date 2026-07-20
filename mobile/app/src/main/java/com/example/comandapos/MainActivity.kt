package com.example.comandapos

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import com.example.comandapos.navigation.AppNavigation
import com.example.comandapos.ui.theme.ComandaPosTheme

class MainActivity : ComponentActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        setContent {
            ComandaPosTheme {
                AppNavigation()
            }
        }
    }
}