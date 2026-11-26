import java.io.FileInputStream
import java.util.Properties
import org.gradle.api.GradleException

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keyProperties = Properties()
val keyPropertiesFile = rootProject.file("key.properties")
if (keyPropertiesFile.exists()) {
    FileInputStream(keyPropertiesFile).use { keyProperties.load(it) }
}

fun signingValue(prop: String, env: String): String? =
    (keyProperties.getProperty(prop) ?: System.getenv(env))
        ?.trim()
        ?.takeIf { it.isNotEmpty() }

val releaseStoreFile = signingValue("storeFile", "COQUI_ANDROID_STORE_FILE")
val releaseStorePassword = signingValue("storePassword", "COQUI_ANDROID_STORE_PASSWORD")
val releaseKeyAlias = signingValue("keyAlias", "COQUI_ANDROID_KEY_ALIAS")
val releaseKeyPassword = signingValue("keyPassword", "COQUI_ANDROID_KEY_PASSWORD")
val hasReleaseSigning =
    releaseStoreFile != null &&
        releaseStorePassword != null &&
        releaseKeyAlias != null &&
        releaseKeyPassword != null

android {
    namespace = "dev.salimocasio.coqui"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "dev.salimocasio.coqui"
        // Flutter's default minSdk (24) is above what speech_to_text 7.5.0 asks for (21).
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        // The debug build is signed with the key in android/debug.keystore, the standard Android
        // debug key (alias androiddebugkey, password android). It is NOT a secret. It is in the repo
        // so that every debug build, on any machine, is signed with the same key and installs over the
        // last one (`adb install -r`). It is NEVER used for release builds.
        getByName("debug") {
            storeFile = rootProject.file("debug.keystore")
            storePassword = "android"
            keyAlias = "androiddebugkey"
            keyPassword = "android"
            storeType = "jks"
        }

        if (hasReleaseSigning) {
            create("release") {
                storeFile = rootProject.file(releaseStoreFile!!)
                storePassword = releaseStorePassword
                keyAlias = releaseKeyAlias
                keyPassword = releaseKeyPassword
            }
        }
    }

    buildTypes {
        debug {
            signingConfig = signingConfigs.getByName("debug")
        }
        release {
            signingConfig = if (hasReleaseSigning) {
                signingConfigs.getByName("release")
            } else {
                null
            }
        }
    }
}

gradle.taskGraph.whenReady {
    val wantsRelease = allTasks.any { task ->
        val n = task.name.lowercase()
        n.contains("release") &&
            (n.startsWith("assemble") ||
                n.startsWith("bundle") ||
                n.startsWith("package") ||
                n.startsWith("sign"))
    }
    if (wantsRelease && !hasReleaseSigning) {
        throw GradleException(
            "Android release signing is not configured. Provide coqui/app/android/key.properties " +
                "(storeFile, storePassword, keyAlias, keyPassword) or environment variables " +
                "COQUI_ANDROID_STORE_FILE, COQUI_ANDROID_STORE_PASSWORD, " +
                "COQUI_ANDROID_KEY_ALIAS, and COQUI_ANDROID_KEY_PASSWORD.",
        )
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
