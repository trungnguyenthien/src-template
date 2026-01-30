package com.jetbrains.kmpapp

import org.jetbrains.kotlinx.multiplatform.library.template.Networking
import kotlin.test.Test
import kotlin.test.assertNotNull

/**
 * Integration tests for Networking - commented out because they require network and iOS framework linking
 * To enable these tests:
 * 1. Ensure network connection is available
 * 2. Configure CocoaPods in test project for iOS targets
 */
class NetworkingIntegrationTest {
    
    @Test
    fun testNetworkingAvailable() {
        // Basic test that library is accessible
        val networking = Networking()
        assertNotNull(networking)
    }
    
    // Uncomment when network is available and CocoaPods is configured
    /*
    @Test
    fun testRealGetRequest() = runBlocking {
        val networking = Networking()
        
        try {
            val response = networking.get("https://httpbin.org/get")
            assertNotNull(response, "Response should not be null")
            println("GET Response: $response")
        } catch (e: Exception) {
            println("GET request failed: ${e.message}")
        }
    }
    
    @Test
    fun testRealPostRequest() = runBlocking {
        val networking = Networking()
        
        try {
            val requestBody = """{"test": "data"}"""
            val response = networking.post("https://httpbin.org/post", requestBody)
            assertNotNull(response, "Response should not be null")
            println("POST Response: $response")
        } catch (e: Exception) {
            println("POST request failed: ${e.message}")
        }
    }
    */
}
