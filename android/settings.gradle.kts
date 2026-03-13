pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    // AR kütüphanesi için en stabil AGP sürümü:
    id("com.android.application") version "7.4.2" apply false
    // Flutter 3.24 ile uyumlu Kotlin sürümü:
    id("org.jetbrains.kotlin.android") version "1.9.22" apply false
}

include(":app")
