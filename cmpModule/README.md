# Kotlin Multiplatform Library với Native Library Integration

Library module demo cách tích hợp native libraries (OkHttp cho Android, AFNetworking cho iOS) sử dụng expect/actual pattern trong Kotlin Multiplatform.

## 📋 Mục lục

- [Cấu trúc project](#cấu-trúc-project)
- [Thêm class mới với native integration](#thêm-class-mới-với-native-integration)
- [Build và publish library](#build-và-publish-library)
- [Sử dụng library](#sử-dụng-library)

---

## 🏗️ Cấu trúc project

```
library/
├── build.gradle.kts           # Cấu hình build với CocoaPods
├── src/
│   ├── commonMain/kotlin/     # Định nghĩa expect classes
│   ├── androidMain/kotlin/    # Implement cho Android
│   └── iosMain/kotlin/        # Implement cho iOS
```

---

## ➕ Thêm class mới với native integration

Ví dụ: Tạo class `Networking` với OkHttp (Android) và AFNetworking (iOS).

### Bước 1: Định nghĩa expect class trong `commonMain`

**File:** `src/commonMain/kotlin/Networking.kt`

```kotlin
package org.jetbrains.kotlinx.multiplatform.library.template

/**
 * Common interface cho networking functionality
 * Các platform sẽ implement với native libraries
 */
expect class Networking() {
    /**
     * Thực hiện HTTP GET request
     * @param url URL endpoint
     * @return Response body dạng string
     */
    suspend fun get(url: String): String
    
    /**
     * Thực hiện HTTP POST request
     * @param url URL endpoint
     * @param body Request body (JSON string)
     * @return Response body dạng string
     */
    suspend fun post(url: String, body: String): String
}
```

### Bước 2: Implement cho Android với OkHttp

**File:** `src/androidMain/kotlin/Networking.android.kt`

```kotlin
package org.jetbrains.kotlinx.multiplatform.library.template

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody

/**
 * Android implementation sử dụng OkHttp
 */
actual class Networking {
    private val client = OkHttpClient()
    
    actual suspend fun get(url: String): String = withContext(Dispatchers.IO) {
        val request = Request.Builder()
            .url(url)
            .build()
            
        client.newCall(request).execute().use { response ->
            response.body?.string() ?: ""
        }
    }
    
    actual suspend fun post(url: String, body: String): String = withContext(Dispatchers.IO) {
        val mediaType = "application/json; charset=utf-8".toMediaType()
        val requestBody = body.toRequestBody(mediaType)
        
        val request = Request.Builder()
            .url(url)
            .post(requestBody)
            .build()
            
        client.newCall(request).execute().use { response ->
            response.body?.string() ?: ""
        }
    }
}
```

**Thêm dependency trong `build.gradle.kts`:**

```kotlin
sourceSets {
    androidMain.dependencies {
        implementation("com.squareup.okhttp3:okhttp:4.12.0")
    }
}
```

### Bước 3: Implement cho iOS với AFNetworking

**File:** `src/iosMain/kotlin/Networking.ios.kt`

```kotlin
package org.jetbrains.kotlinx.multiplatform.library.template

import cocoapods.AFNetworking.*
import kotlinx.cinterop.*
import kotlinx.coroutines.suspendCancellableCoroutine
import platform.Foundation.*
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException

/**
 * iOS implementation sử dụng AFNetworking
 */
actual class Networking {
    private val manager = AFHTTPSessionManager()
    
    actual suspend fun get(url: String): String = suspendCancellableCoroutine { continuation ->
        manager.GET(
            url,
            parameters = null,
            headers = null,
            progress = null,
            success = { _, responseObject ->
                val data = responseObject as? NSData
                val response = data?.let { 
                    NSString.create(it, NSUTF8StringEncoding) as String 
                } ?: ""
                continuation.resume(response)
            },
            failure = { _, error ->
                continuation.resumeWithException(
                    Exception(error?.localizedDescription ?: "Unknown error")
                )
            }
        )
    }
    
    actual suspend fun post(url: String, body: String): String = suspendCancellableCoroutine { continuation ->
        val jsonData = body.toNSData()
        val parameters = NSJSONSerialization.JSONObjectWithData(
            jsonData, 
            0UL, 
            null
        )
        
        manager.POST(
            url,
            parameters = parameters,
            headers = null,
            progress = null,
            success = { _, responseObject ->
                val data = responseObject as? NSData
                val response = data?.let { 
                    NSString.create(it, NSUTF8StringEncoding) as String 
                } ?: ""
                continuation.resume(response)
            },
            failure = { _, error ->
                continuation.resumeWithException(
                    Exception(error?.localizedDescription ?: "Unknown error")
                )
            }
        )
    }
    
    private fun String.toNSData(): NSData {
        return this.encodeToByteArray().usePinned { pinned ->
            NSData.create(
                bytes = pinned.addressOf(0),
                length = this.length.toULong()
            )
        }
    }
}
```

**Cấu hình CocoaPods trong `build.gradle.kts`:**

```kotlin
kotlin {
    // Targets...
    iosX64()
    iosArm64()
    iosSimulatorArm64()
    
    // CocoaPods Integration
    cocoapods {
        summary = "Kotlin Multiplatform library with native iOS networking"
        homepage = "https://github.com/kotlin/multiplatform-library-template"
        version = "1.0.0"
        ios.deploymentTarget = "13.0"
        
        // Thêm AFNetworking pod
        pod("AFNetworking") {
            version = "~> 4.0"
        }
    }
}
```

### Bước 4: Cleanup và invalidate session

Nếu cần cleanup resources (ví dụ AFNetworking sessions), thêm method:

```kotlin
// Trong Networking.ios.kt
fun cleanup() {
    manager.invalidateSessionCancelingTasks(true, resetSession = false)
}
```

---

## 🔨 Build và publish library

### 1. Build library

```bash
# Build tất cả targets
./gradlew :library:build

# Build riêng từng target
./gradlew :library:compileKotlinIosArm64
./gradlew :library:compileKotlinAndroid
```

### 2. Publish to Maven Local

```bash
# Publish library to ~/.m2/repository
./gradlew :library:publishToMavenLocal
```

**Output:**
- Group: `io.github.kotlin`
- Artifact: `library`
- Version: `1.0.0`
- Location: `~/.m2/repository/io/github/kotlin/library/1.0.0/`

### 3. Verify publish

```bash
ls -la ~/.m2/repository/io/github/kotlin/library/1.0.0/
```

Files cần có:
- `library-1.0.0.module`
- `library-1.0.0.pom`
- `library-android-1.0.0.aar`
- `library-iosarm64-1.0.0.klib`
- `library-iossimulatorarm64-1.0.0.klib`
- Etc.

### 4. CocoaPods artifacts

CocoaPods plugin tự động generate:
- `library.podspec` - Pod specification
- Build frameworks trong `build/cocoapods/`

---

## 📦 Sử dụng library

### Trong consumer project (cmpModuleTest)

**1. Configure `settings.gradle.kts`:**

```kotlin
dependencyResolutionManagement {
    repositories {
        google()
        mavenCentral()
        mavenLocal() // Thêm Maven Local
    }
}
```

**2. Thêm dependency trong `build.gradle.kts`:**

```kotlin
kotlin {
    sourceSets {
        commonMain.dependencies {
            implementation("io.github.kotlin:library:1.0.0")
        }
        
        commonTest.dependencies {
            implementation("io.github.kotlin:library:1.0.0")
        }
    }
}
```

**3. Sử dụng trong code:**

```kotlin
import org.jetbrains.kotlinx.multiplatform.library.template.Networking

class MyViewModel {
    private val networking = Networking()
    
    suspend fun fetchData() {
        try {
            val response = networking.get("https://api.example.com/data")
            println("Response: $response")
        } catch (e: Exception) {
            println("Error: ${e.message}")
        }
    }
}
```

### Cho iOS projects với CocoaPods

**1. iOS app cũng cần CocoaPods plugin:**

```kotlin
// composeApp/build.gradle.kts
plugins {
    kotlin("multiplatform")
    kotlin("native.cocoapods")
}

kotlin {
    cocoapods {
        summary = "Compose Multiplatform App"
        homepage = "https://github.com/..."
        version = "1.0.0"
        ios.deploymentTarget = "13.0"
        
        // AFNetworking cần cho library dependency
        pod("AFNetworking") {
            version = "~> 4.0"
        }
    }
}
```

**2. Thêm gradle property:**

```properties
# gradle.properties
kotlin.apple.deprecated.allowUsingEmbedAndSignWithCocoaPodsDependencies=true
kotlin.apple.xcodeCompatibility.nowarn=true
```

**3. Run tests:**

```bash
# iOS Simulator tests
./gradlew :composeApp:iosSimulatorArm64Test

# Android tests  
./gradlew :composeApp:testDebugUnitTest
```

---

## 🧪 Testing

### Test example

**File:** `src/commonTest/kotlin/NetworkingTest.kt`

```kotlin
import org.jetbrains.kotlinx.multiplatform.library.template.Networking
import kotlin.test.Test
import kotlin.test.assertNotNull

class NetworkingTest {
    @Test
    fun testNetworkingInstance() {
        val networking = Networking()
        assertNotNull(networking)
    }
}
```

### Run tests

```bash
# All tests
./gradlew :library:allTests

# iOS tests
./gradlew :library:iosSimulatorArm64Test

# Android tests
./gradlew :library:testDebugUnitTest
```

---

## 🔍 Troubleshooting

### CocoaPods errors

**Issue:** `ld: framework 'AFNetworking' not found`

**Solution:**
```bash
# Clean và rebuild
./gradlew :library:clean
./gradlew :library:build

# Hoặc run pod install
./gradlew :library:podInstall
```

### Java version issues

**Issue:** `IllegalArgumentException: 25` (Java version không support)

**Solution:**
```bash
# Install Java 17
brew install openjdk@17

# Set JAVA_HOME
export JAVA_HOME=/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home
```

### Network timeout

**Issue:** CocoaPods CDN timeout

**Solution:** Đợi network ổn định hoặc retry:
```bash
./gradlew :library:build --refresh-dependencies
```

---

## 📚 Best Practices

1. **Version Control**: Commit `library.podspec` nhưng ignore `Pods/` folder
2. **Testing**: Luôn test trên cả iOS và Android trước khi publish
3. **Documentation**: Document expect/actual APIs rõ ràng
4. **Error Handling**: Wrap native exceptions thành Kotlin exceptions
5. **Coroutines**: Sử dụng `suspendCancellableCoroutine` cho iOS async operations
6. **Cleanup**: Implement cleanup methods nếu cần (sessions, resources)

---

## 📖 Resources

- [Kotlin Multiplatform Documentation](https://kotlinlang.org/docs/multiplatform.html)
- [CocoaPods Gradle Plugin](https://kotlinlang.org/docs/native-cocoapods.html)
- [OkHttp Documentation](https://square.github.io/okhttp/)
- [AFNetworking Documentation](https://github.com/AFNetworking/AFNetworking)

---

## ✅ Checklist khi thêm native integration mới

- [ ] Define expect class in `commonMain`
- [ ] Implement actual class for Android với native library
- [ ] Implement actual class for iOS với CocoaPods pod
- [ ] Add dependencies (OkHttp, etc.) in `build.gradle.kts`
- [ ] Configure `cocoapods {}` block với pod dependencies
- [ ] Write unit tests in `commonTest`
- [ ] Test trên cả Android và iOS
- [ ] Document APIs và usage examples
- [ ] Build và verify: `./gradlew :library:build`
- [ ] Publish to Maven Local: `./gradlew :library:publishToMavenLocal`
- [ ] Test integration trong consumer project

---

**Happy coding! 🚀**