allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// Force all third-party plugin subprojects (NOT :app) to use compileSdkVersion 36.
// We use afterEvaluate + BaseExtension.compileSdkVersion(Int) method (not property setter)
// to avoid "too late" lock. :app is excluded because it already has compileSdk = 36 directly.
subprojects {
    if (project.name != "app") {
        afterEvaluate {
            val androidExt = extensions.findByName("android")
            if (androidExt is com.android.build.gradle.BaseExtension) {
                val currentSdk = androidExt.compileSdkVersion
                    ?.removePrefix("android-")?.toIntOrNull() ?: 0
                if (currentSdk < 36) {
                    androidExt.compileSdkVersion(36)
                }
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
