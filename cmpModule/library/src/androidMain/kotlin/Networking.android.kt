package org.jetbrains.kotlinx.multiplatform.library.template

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import java.io.IOException

/**
 * Android implementation of Networking using OkHttp.
 */
actual class Networking actual constructor() {
    private val client = OkHttpClient()
    
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
