buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.google.gms:google-services:4.4.2")
    }
}

// RT-013: Decline/timeout broadcasts target the plugin receiver. Inject a
// reflection hook so a killed process can persist the action and start the
// Dart background isolate. Idempotent; pub get restores the original file
// and the next Gradle configuration writes the hook again.
// Runs before subprojects evaluationDependsOn(":app"), which needs Java 17.
fun Project.patchCallkitKilledHook() {
    val config = file("../.dart_tool/package_config.json")
    if (!config.exists()) {
        logger.warn("RT-013: package_config.json missing; CallKit decline hook not applied")
        return
    }
    val json = config.readText()
    val marker = "\"name\": \"flutter_callkit_incoming\""
    val nameAt = json.indexOf(marker)
    if (nameAt < 0) {
        logger.warn("RT-013: flutter_callkit_incoming not in package_config")
        return
    }
    val rootKey = "\"rootUri\": \""
    val rootAt = json.indexOf(rootKey, nameAt)
    if (rootAt < 0 || rootAt - nameAt > 200) {
        logger.warn("RT-013: flutter_callkit_incoming rootUri missing")
        return
    }
    val uriStart = rootAt + rootKey.length
    val uriEnd = json.indexOf('"', uriStart)
    val rootUri = json.substring(uriStart, uriEnd)
    val rawPath = java.net.URI(rootUri).path ?: return
    val path = if (rawPath.length >= 3 && rawPath[0] == '/' && rawPath[2] == ':') {
        rawPath.substring(1)
    } else {
        rawPath
    }
    val receiver = file(
        "$path/android/src/main/kotlin/com/hiennv/flutter_callkit_incoming/CallkitIncomingBroadcastReceiver.kt",
    )
    if (!receiver.exists()) {
        logger.warn("RT-013: CallKit receiver not found at ${receiver.path}")
        return
    }
    val source = receiver.readText()
    if (source.contains("com.lgbtfinder.CallkitKilledAction")) {
        return
    }
    val needle = "override fun onReceive(context: Context, intent: Intent) {"
    if (!source.contains(needle)) {
        logger.warn("RT-013: CallKit onReceive shape changed; hook not applied")
        return
    }
    val hook = """
        |override fun onReceive(context: Context, intent: Intent) {
        |        try {
        |            val killed = Class.forName("com.lgbtfinder.CallkitKilledAction")
        |            val hook = killed.getMethod(
        |                "onCallkitAction",
        |                android.content.BroadcastReceiver::class.java,
        |                android.content.Context::class.java,
        |                android.content.Intent::class.java
        |            )
        |            hook.invoke(null, this, context, intent)
        |        } catch (hookError: Throwable) {
        |            android.util.Log.w("CallkitIncomingReceiver", "RT-013 hook failed", hookError)
        |        }
    """.trimMargin()
    receiver.writeText(source.replace(needle, hook))
    logger.lifecycle("RT-013: patched CallKit decline hook into ${receiver.path}")
}

patchCallkitKilledHook()

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

// Legacy Flutter plugins ship their own AGP 7.x buildscript; force the app AGP instead.
subprojects {
    buildscript {
        repositories {
            google()
            mavenCentral()
        }
        configurations.classpath {
            resolutionStrategy {
                force("com.android.tools.build:gradle:8.11.1")
                force("org.jetbrains.kotlin:kotlin-gradle-plugin:2.2.20")
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
