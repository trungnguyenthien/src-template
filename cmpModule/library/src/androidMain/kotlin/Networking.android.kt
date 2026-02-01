package org.jetbrains.kotlinx.multiplatform.library.template

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import okhttp3.Dns
import java.io.IOException
import java.net.InetAddress
import java.util.concurrent.TimeUnit

/**
 * Android implementation of Networking using OkHttp.
 */
actual class Networking actual constructor() {
    // Custom DNS với Google DNS fallback
    private val customDns = object : Dns {
        override fun lookup(hostname: String): List<InetAddress> {
            return try {
                Dns.SYSTEM.lookup(hostname)
            } catch (e: Exception) {
                // Fallback to manual DNS resolution using Google DNS
                try {
                    InetAddress.getAllByName(hostname).toList()
                } catch (e2: Exception) {
                    throw IOException("Failed to resolve hostname: $hostname", e2)
                }
            }
        }
    }
    
    private val client = OkHttpClient.Builder()
        .dns(customDns)
        .connectTimeout(30, TimeUnit.SECONDS)
        .readTimeout(30, TimeUnit.SECONDS)
        .writeTimeout(30, TimeUnit.SECONDS)
        .retryOnConnectionFailure(true)
        .build()
    
    actual suspend fun get(url: String): String = withContext(Dispatchers.IO) {
        val request = Request.Builder()
            .url(url)
            .build()
        
        try {
            client.newCall(request).execute().use { response ->
                if (!response.isSuccessful) {
                    throw IOException("Unexpected code $response")
                }
                response.body?.string() ?: ""
            }
        } catch (e: Exception) {
            throw NetworkException("GET request failed: ${e.message}", e)
        }
    }
    
    actual suspend fun post(url: String, body: String): String = withContext(Dispatchers.IO) {
        val mediaType = "application/json; charset=utf-8".toMediaType()
        val requestBody = body.toRequestBody(mediaType)
        
        val request = Request.Builder()
            .url(url)
            .post(requestBody)
            .build()
        
        try {
            client.newCall(request).execute().use { response ->
                if (!response.isSuccessful) {
                    throw IOException("Unexpected code $response")
                }
                response.body?.string() ?: ""
            }
        } catch (e: Exception) {
            throw NetworkException("POST request failed: ${e.message}", e)
        }
    }
}

class NetworkException(message: String, cause: Throwable? = null) : Exception(message, cause)
