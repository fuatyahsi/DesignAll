plugins {
    id("com.android.application")
    id("kotlin-android")
    // Flutter Gradle Plugin, Android ve Kotlin pluginlerinden sonra uygulanmalıdır.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.design_all"
    compileSdk = 34 // Modern Android standartları için 34 idealdir

    sourceSets {
        getByName("main").java.srcDirs("src/main/kotlin")
    }

    defaultConfig {
        applicationId = "com.example.design_all"
        // AR özellikleri için minSdk en az 24 olmalıdır
        minSdk = 24 
        targetSdk = 34
        versionCode = 1
        versionName = "1.0.0"

        // Dexing hatasını çözen kritik ayar
        multiDexEnabled = true
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    buildTypes {
        release {
            // Debug anahtarıyla imzalanıyor (flutter run --release çalışması için)
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // MultiDex kütüphanesini ekliyoruz
    implementation("androidx.multidex:multidex:2.0.1")
}
