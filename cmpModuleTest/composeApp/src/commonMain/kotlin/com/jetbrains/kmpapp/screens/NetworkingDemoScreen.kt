package com.jetbrains.kmpapp

import androidx.compose.runtime.Composable
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.material3.Button
import androidx.compose.material3.Text
import androidx.compose.foundation.layout.*
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import kotlinx.coroutines.launch
import org.jetbrains.kotlinx.multiplatform.library.template.Networking

/**
 * Demo screen using Networking from library module
 */
@Composable
fun NetworkingDemoScreen() {
    val networking = remember { Networking() }
    val (response, setResponse) = remember { mutableStateOf("No request sent yet") }
    val (isLoading, setLoading) = remember { mutableStateOf(false) }
    val scope = rememberCoroutineScope()
    
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        Text("Networking Library Demo")
        
        Button(
            onClick = {
                setLoading(true)
                scope.launch {
                    try {
                        val result = networking.get("https://httpbin.org/get")
                        setResponse("GET Success:\n$result")
                    } catch (e: Exception) {
                        setResponse("GET Error: ${e.message}")
                    } finally {
                        setLoading(false)
                    }
                }
            },
            enabled = !isLoading
        ) {
            Text("Test GET Request")
        }
        
        Button(
            onClick = {
                setLoading(true)
                scope.launch {
                    try {
                        val result = networking.post(
                            "https://httpbin.org/post",
                            """{"demo": "test"}"""
                        )
                        setResponse("POST Success:\n$result")
                    } catch (e: Exception) {
                        setResponse("POST Error: ${e.message}")
                    } finally {
                        setLoading(false)
                    }
                }
            },
            enabled = !isLoading
        ) {
            Text("Test POST Request")
        }
        
        if (isLoading) {
            CircularProgressIndicator()
        }
        
        Text(
            text = response,
            modifier = Modifier.fillMaxWidth()
        )
    }
}
