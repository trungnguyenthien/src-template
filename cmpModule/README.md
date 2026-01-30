# Kotlin Multiplatform Library Template

Template để tạo Kotlin Multiplatform library với khả năng tích hợp native libraries từ Android và iOS. 

> **Note:** `Networking` class là một sample implementation để demo cách sử dụng expect/actual pattern với native libraries (OkHttp + AFNetworking).

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

### Bước 1: Định nghĩa expect class trong `commonMain`

**File:** `src/commonMain/kotlin/YourClass.kt`

```kotlin
package org.jetbrains.kotlinx.multiplatform.library.template

expect class YourClass() {
    suspend fun yourMethod(param: String): String
}
```

### Bước 2: Implement cho Android với native library

**File:** `src/androidMain/kotlin/YourClass.android.kt`

```kotlin
package org.jetbrains.kotlinx.multiplatform.library.template

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
// Import your native library here

actual class YourClass {
    actual suspend fun yourMethod(param: String): String = withContext(Dispatchers.IO) {
        // Implementation using Android native library
        // Example: OkHttp, Room, etc.
        return@withContext "result"
    }
}
```

**Thêm dependency trong `build.gradle.kts`:**

```kotlin
sourceSets {
    androidMain.dependencies {
        implementation("your.library:artifact:version")
    }
}
```

### Bước 3: Implement cho iOS với CocoaPods

**File:** `src/iosMain/kotlin/YourClass.ios.kt`

```kotlin
package org.jetbrains.kotlinx.multiplatform.library.template

import cocoapods.YourPod.*
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException

actual class YourClass {
    actual suspend fun yourMethod(param: String): String = suspendCancellableCoroutine { continuation ->
        // Implementation using iOS CocoaPods library
        continuation.resume("result")
    }
}
```

**Cấu hình CocoaPods trong `build.gradle.kts`:**

```kotlin
kotlin {
    iosX64()
    iosArm64()
    iosSimulatorArm64()
    
    cocoapods {
        summary = "Your library description"
        homepage = "https://github.com/your-repo"
        version = "1.0.0"
        ios.deploymentTarget = "13.0"
        
        // Thêm CocoaPods dependency
        pod("YourPodName") {
            version = "~> 1.0"
        }
    }
}
```

---

## 📦 Sample: Networking Class

Template này có sẵn class `Networking` demo cách integrate OkHttp (Android) và AFNetworking (iOS).

### Common Interface

```kotlin
expect class Networking() {
    suspend fun get(url: String): String
}
```

### Android Implementation

```kotlin
actual class Networking {
    private val client = OkHttpClient()
    
    actual suspend fun get(url: String): String = withContext(Dispatchers.IO) {
        val request = Request.Builder().url(url).build()
        client.newCall(request).execute().use { response ->
            response.body?.string() ?: ""
        }
    }
}
```

### iOS Implementation

```kotlin
actual class Networking {
    private val manager = AFHTTPSessionManager()
    
    actual suspend fun get(url: String): String = suspendCancellableCoroutine { continuation ->
        manager.GET(url, parameters = null, headers = null, progress = null,
            success = { _, responseObject ->
                val response = (responseObject as? NSData)?.let { 
                    NSString.create(it, NSUTF8StringEncoding) as String 
                } ?: ""
                continuation.resume(response)
            },
            failure = { _, error ->
                continuation.resumeWithException(Exception(error?.localizedDescription))
            }
        )
    }
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
./gradlew :library:publishToMavenLocal
```

**Published artifacts:**
- Group: `io.github.kotlin`
- Artifact: `library`
- Version: `1.0.0`
- Location: `~/.m2/repository/io/github/kotlin/library/1.0.0/`

### 3. Verify publish

```bash
ls -la ~/.m2/repository/io/github/kotlin/library/1.0.0/
```

Expected files:
- `library-1.0.0.module`
- `library-1.0.0.pom`
- `library-android-1.0.0.aar`
- `library-iosarm64-1.0.0.klib`
- `library-iossimulatorarm64-1.0.0.klib`

---

## 📦 Sử dụng library

### Trong consumer project

**1. Configure `settings.gradle.kts`:**

```kotlin
dependencyResolutionManagement {
    repositories {
        google()
        mavenCentral()
        mavenLocal() // Add for local development
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
    }
}
```

**3. Sử dụng trong code:**

```kotlin
import org.jetbrains.kotlinx.multiplatform.library.template.Networking

suspend fun example() {
    val networking = Networking()
    val response = networking.get("https://api.example.com/data")
    println(response)
}
```

### Cho iOS projects với CocoaPods dependencies

**Thêm CocoaPods plugin:**

```kotlin
plugins {
    kotlin("multiplatform")
    kotlin("native.cocoapods")
}

kotlin {
    cocoapods {
        summary = "Your app"
        version = "1.0.0"
        ios.deploymentTarget = "13.0"
        
        // Cần add pods mà library sử dụng
        pod("AFNetworking") { version = "~> 4.0" }
    }
}
```

**gradle.properties:**

```properties
kotlin.apple.deprecated.allowUsingEmbedAndSignWithCocoaPodsDependencies=true
kotlin.apple.xcodeCompatibility.nowarn=true
```

---

## 🧪 Testing

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

```bash
# Clean và rebuild
./gradlew :library:clean
./gradlew :library:build
```

### Java version issues

Cần Java 17:

```bash
brew install openjdk@17
export JAVA_HOME=/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home
```

---

## 📚 Best Practices

1. **Naming**: Sử dụng expect/actual pattern cho platform-specific code
2. **Error Handling**: Wrap native exceptions thành Kotlin exceptions  
3. **Coroutines**: Dùng `suspendCancellableCoroutine` cho iOS async operations
4. **Testing**: Test trên cả iOS và Android
5. **Documentation**: Document APIs rõ ràng
6. **Cleanup**: Implement cleanup nếu cần (sessions, resources)

---

## ✅ Checklist tạo library mới

- [ ] Clone template này
- [ ] Đổi package name trong `build.gradle.kts`
- [ ] Define expect classes in `commonMain`
- [ ] Implement actual classes cho Android
- [ ] Implement actual classes cho iOS với CocoaPods
- [ ] Add dependencies (native libraries)
- [ ] Configure `cocoapods {}` block
- [ ] Write tests in `commonTest`
- [ ] Build: `./gradlew :library:build`
- [ ] Publish: `./gradlew :library:publishToMavenLocal`
- [ ] Test trong consumer project

---

## 📖 Resources

- [Kotlin Multiplatform Docs](https://kotlinlang.org/docs/multiplatform.html)
- [CocoaPods Gradle Plugin](https://kotlinlang.org/docs/native-cocoapods.html)
- [expect/actual Pattern](https://kotlinlang.org/docs/multiplatform-connect-to-apis.html)

---

**Happy coding! 🚀**