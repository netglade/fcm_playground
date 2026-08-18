plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "cz.netglade.fcm_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // flutter_local_notifications 10+ relies on library desugaring for its
        // backwards-compatible scheduling APIs, and the AAR metadata check fails
        // the build without it — even though this app only shows notifications
        // immediately and never schedules one.
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "cz.netglade.fcm_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        testInstrumentationRunner = "pl.leancode.patrol.PatrolJUnitRunner"
        // `clearPackageData` is intentionally NOT set here. It is only honoured by
        // Android Test Orchestrator, which this project does not add — plain
        // `AndroidJUnitRunner` (which `PatrolJUnitRunner` extends) ignores it, so
        // setting it would be dead configuration claiming an isolation this build
        // does not provide. The Orchestrator would give true per-test isolation, at
        // the cost of a fresh FCM token per test (up to ~45s each, and roughly 13
        // minutes across the suite) — and `integration_test/support/app_harness.dart`
        // already tears its own pipeline down between tests, which covers the leak
        // the Orchestrator would otherwise be needed for. App data, including the
        // FCM token and the telemetry buffer, persists across a target's tests as a
        // result, and the permission dialog is granted once per target rather than
        // once per test — see `_permissionDialogTimeout` in that same file.
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
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

dependencies {
    // The version flutter_local_notifications 22.3.0 documents for its
    // desugaring requirement. Its own android/build.gradle uses the same one.
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
