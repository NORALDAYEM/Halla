allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// ZIM 3.3 still invokes the removed Groovy jcenter() DSL during evaluation.
allprojects {
    for (handler in listOf(buildscript.repositories, repositories)) {
        (handler as org.gradle.api.plugins.ExtensionAware).extensions.extraProperties
            .set("jcenter", object : groovy.lang.Closure<Any>(handler) {
                @Suppress("unused")
                fun doCall(): Any = handler.mavenCentral()
            })
    }
}

// ZEGO's library modules declare API 31, below their resolved AndroidX requirements.
subprojects {
    if (name.startsWith("zego_")) {
        plugins.withId("com.android.library") {
            extensions.getByType<com.android.build.api.variant.LibraryAndroidComponentsExtension>()
                .finalizeDsl { android -> android.compileSdk = 37 }
        }
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

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
