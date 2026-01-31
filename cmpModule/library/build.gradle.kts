import com.android.build.api.dsl.androidLibrary
import org.jetbrains.kotlin.gradle.dsl.JvmTarget

plugins {
    alias(libs.plugins.kotlinMultiplatform)
    alias(libs.plugins.jetbrainsCompose)
    alias(libs.plugins.compose.compiler)
    alias(libs.plugins.android.kotlin.multiplatform.library)
    alias(libs.plugins.vanniktech.mavenPublish)
    kotlin("native.cocoapods")
}

group = "io.github.kotlin"
version = "1.0.0"

val myArtifactId = "library"
val myAndroidLibraryNamespace = "io.github.trungnguyenthien"

kotlin {
    androidLibrary {
        namespace = myAndroidLibraryNamespace
        compileSdk = libs.versions.android.compileSdk.get().toInt()
        minSdk = libs.versions.android.minSdk.get().toInt()

        withJava()
        withHostTestBuilder {}.configure {}
        withDeviceTestBuilder {
            sourceSetTreeName = "test"
        }

        compilations.configureEach {
            compileTaskProvider.configure {
                compilerOptions {
                    jvmTarget.set(JvmTarget.JVM_11)
                }
            }
        }
    }

    iosX64()
    iosArm64()
    iosSimulatorArm64()

    // CocoaPods Integration
    cocoapods {
        summary = "Kotlin Multiplatform library with native iOS networking"
        homepage = "https://github.com/kotlin/multiplatform-library-template"
        version = "1.0.0"
        ios.deploymentTarget = "13.0"
        
        pod("AFNetworking") {
            version = "~> 4.0"
        }
    }

    sourceSets {
        commonMain.dependencies {
            implementation(compose.runtime)
        }

        androidMain.dependencies {
            implementation("com.squareup.okhttp3:okhttp:4.12.0")
        }

        commonTest.dependencies {
            implementation(libs.kotlin.test)
        }
    }
}

mavenPublishing {
    coordinates(group.toString(), myArtifactId, version.toString())
    pom {
        name = "My library"
        description = "A library."
        inceptionYear = "2024"
        url = "https://github.com/kotlin/multiplatform-library-template/"
        licenses {
            license {
                name = "XXX"
                url = "YYY"
                distribution = "ZZZ"
            }
        }
    }
}