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
import io.github.trungnguyenthien.Networking

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
                        // Test với IP address để bypass DNS
                        val result = networking.get("http://142.250.185.46")
                        setResponse("IP Test Success! Length: ${result.length}")
                    } catch (e: Exception) {
                        setResponse("IP Test Error: ${e.message}\n\nEmulator không có internet. Vui lòng:\n1. Restart emulator\n2. Check WiFi/Network settings\n3. Try cold boot emulator")
                    } finally {
                        setLoading(false)
                    }
                }
            },
            enabled = !isLoading
        ) {
            Text("Test IP (bypass DNS)")
        }
        
        Button(
            onClick = {
                setLoading(true)
                scope.launch {
                    try {
                        // Test với Google trước để verify network
                        val result = networking.get("https://www.google.com")
                        setResponse("Google Success! Length: ${result.length}")
                    } catch (e: Exception) {
                        setResponse("Google Error: ${e.message}")
                    } finally {
                        setLoading(false)
                    }
                }
            },
            enabled = !isLoading
        ) {
            Text("Test Google (verify network)")
        }
        
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
