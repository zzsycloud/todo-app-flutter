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

// flutter_local_notifications 声明 compileSdk 35，本机只安装了 android-36，
// 这里把各插件子工程的 compileSdk 统一提升到 36，避免额外安装 SDK。
subprojects {
    val raiseCompileSdk = Action<Project> {
        val androidExtension = extensions.findByName("android") ?: return@Action
        runCatching {
            // 不同 AGP 版本 DSL 类型不同，用反射调用 setter 避免类加载冲突
            androidExtension.javaClass
                .getMethod("setCompileSdk", Integer::class.java)
                .invoke(androidExtension, 36)
        }
    }
    // :app 因 evaluationDependsOn 可能已提前完成评估，此时不能再注册 afterEvaluate
    if (state.executed) {
        raiseCompileSdk.execute(this)
    } else {
        afterEvaluate(raiseCompileSdk)
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
