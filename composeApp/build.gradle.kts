import org.jetbrains.kotlin.gradle.dsl.JvmTarget

plugins {
    alias(libs.plugins.kotlinMultiplatform)
}

kotlin {
    // Remove Android target, iOS only
    listOf(
        iosArm64(),
        iosSimulatorArm64()
    ).forEach { iosTarget ->
        iosTarget.binaries.framework {
            baseName = "SharedLedController"
            isStatic = true
        }
    }
    
    sourceSets {
        commonMain.dependencies {
            // No Compose dependencies needed for business logic only
        }
        commonTest.dependencies {
            implementation(libs.kotlin.test)
        }
    }
}
