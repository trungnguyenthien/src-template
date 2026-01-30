package org.jetbrains.kotlinx.multiplatform.library.template

/**
 * Expected Networking class that will have platform-specific implementations.
 * Android will use OkHttp, iOS will use AFNetworking.
 */
expect class Networking() {
    /**
     * Perform a GET request to the specified URL.
     * @param url The URL to fetch
     * @return The response body as a String
     */
    suspend fun get(url: String): String
    
    /**
     * Perform a POST request to the specified URL.
     * @param url The URL to post to
     * @param body The request body
     * @return The response body as a String
     */
    suspend fun post(url: String, body: String): String
}
