package com.jetbrains.kmpapp.data

import kotlinx.serialization.json.Json
import kotlinx.serialization.decodeFromString
import org.jetbrains.kotlinx.multiplatform.library.template.Networking

interface MuseumApi {
    suspend fun getData(): List<MuseumObject>
}

class NetworkingMuseumApi(private val networking: Networking) : MuseumApi {
    companion object {
        private const val API_URL =
            "https://raw.githubusercontent.com/Kotlin/KMP-App-Template/main/list.json"
    }

    private val json = Json { 
        ignoreUnknownKeys = true
        isLenient = true
    }

    override suspend fun getData(): List<MuseumObject> {
        return try {
            val response = networking.get(API_URL)
            json.decodeFromString(response)
        } catch (e: Exception) {
            e.printStackTrace()
            emptyList()
        }
    }
}
