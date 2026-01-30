package org.jetbrains.kotlinx.multiplatform.library.template

import kotlinx.coroutines.suspendCancellableCoroutine
import kotlinx.cinterop.*
import platform.Foundation.*
import cocoapods.AFNetworking.*
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException

/**
 * iOS implementation of Networking using AFNetworking via CocoaPods.
 */
@OptIn(ExperimentalForeignApi::class)
actual class Networking actual constructor() {
    // AFHTTPSessionManager instance for making network requests
    private val manager = AFHTTPSessionManager()
    
    init {
        // Configure AFNetworking to accept JSON responses
        manager.responseSerializer = AFJSONResponseSerializer()
        manager.requestSerializer = AFJSONRequestSerializer()
    }
    
    actual suspend fun get(url: String): String = suspendCancellableCoroutine { continuation ->
        // Use AFHTTPSessionManager's GET method
        manager.GET(
            URLString = url,
            parameters = null,
            headers = null,
            progress = null,
            success = { task, responseObject ->
                // AFNetworking success callback
                val response = when (responseObject) {
                    is NSString -> responseObject as String
                    is NSDictionary, is NSArray -> {
                        // Convert JSON object to string
                        val jsonData = NSJSONSerialization.dataWithJSONObject(
                            responseObject!!,
                            options = 0u,
                            error = null
                        )
                        if (jsonData != null) {
                            NSString.create(jsonData, NSUTF8StringEncoding) as? String ?: "{}"
                        } else {
                            "{}"
                        }
                    }
                    else -> responseObject?.toString() ?: ""
                }
                continuation.resume(response)
            },
            failure = { task, error ->
                // AFNetworking failure callback
                continuation.resumeWithException(
                    NetworkException("GET request failed: ${error?.localizedDescription ?: "Unknown error"}")
                )
            }
        )
        
        // Handle coroutine cancellation
        continuation.invokeOnCancellation {
            manager.invalidateSessionCancelingTasks(true, resetSession = false)
        }
    }
    
    actual suspend fun post(url: String, body: String): String = suspendCancellableCoroutine { continuation ->
        // Parse JSON body string to parameters dictionary
        val bodyData = body.encodeToByteArray().toNSData()
        val parameters = NSJSONSerialization.JSONObjectWithData(
            bodyData,
            options = 0u,
            error = null
        )
        
        // Use AFHTTPSessionManager's POST method
        manager.POST(
            URLString = url,
            parameters = parameters,
            headers = null,
            progress = null,
            success = { task, responseObject ->
                // AFNetworking success callback
                val response = when (responseObject) {
                    is NSString -> responseObject as String
                    is NSDictionary, is NSArray -> {
                        // Convert JSON object to string
                        val jsonData = NSJSONSerialization.dataWithJSONObject(
                            responseObject!!,
                            options = 0u,
                            error = null
                        )
                        if (jsonData != null) {
                            NSString.create(jsonData, NSUTF8StringEncoding) as? String ?: "{}"
                        } else {
                            "{}"
                        }
                    }
                    else -> responseObject?.toString() ?: ""
                }
                continuation.resume(response)
            },
            failure = { task, error ->
                // AFNetworking failure callback
                continuation.resumeWithException(
                    NetworkException("POST request failed: ${error?.localizedDescription ?: "Unknown error"}")
                )
            }
        )
        
        // Handle coroutine cancellation
        continuation.invokeOnCancellation {
            manager.invalidateSessionCancelingTasks(true, resetSession = false)
        }
    }
}

class NetworkException(message: String, cause: Throwable? = null) : Exception(message, cause)

// Extension function to convert ByteArray to NSData
@OptIn(ExperimentalForeignApi::class)
private fun ByteArray.toNSData(): NSData {
    if (this.isEmpty()) {
        return NSData()
    }
    return this.usePinned { pinned ->
        NSData.create(
            bytes = pinned.addressOf(0),
            length = this.size.toULong()
        )
    }
}

