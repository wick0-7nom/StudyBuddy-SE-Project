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

// 🟢 file_picker সহ সব থার্ড-পার্টি প্লাগইনে বাধ্যতামূলকভাবে SDK 36 ফোর্স করার ওয়াটারপ্রুফ কোড
subprojects {
    val overrideSdk = Action<Project> {
        val android = extensions.findByName("android")
        if (android != null) {
            val methods = android.javaClass.methods
            for (method in methods) {
                if (method.name == "setCompileSdk" || method.name == "setCompileSdkVersion" || method.name == "compileSdkVersion") {
                    try {
                        method.invoke(android, 36)
                    } catch (_: Exception) {}
                }
            }
        }
    }

    if (state.executed) {
        overrideSdk.execute(this)
    } else {
        afterEvaluate {
            overrideSdk.execute(this)
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}