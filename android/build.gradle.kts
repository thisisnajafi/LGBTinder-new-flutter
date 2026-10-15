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

// RT-016: flutter_callkit_incoming keeps one shared notification manager.
// Detach of the killed-app decline engine (or the FCM isolate) was clearing
// it while the main engine was still alive, so the next background invite
// broadcast posted nothing. Idempotent; pub get restores the plugin sources.
fun Project.patchCallkitBackgroundIncoming() {
    val config = file("../.dart_tool/package_config.json")
    if (!config.exists()) return
    val json = config.readText()
    val marker = "\"name\": \"flutter_callkit_incoming\""
    val nameAt = json.indexOf(marker)
    if (nameAt < 0) return
    val rootKey = "\"rootUri\": \""
    val rootAt = json.indexOf(rootKey, nameAt)
    if (rootAt < 0 || rootAt - nameAt > 200) return
    val uriStart = rootAt + rootKey.length
    val uriEnd = json.indexOf('"', uriStart)
    val rootUri = json.substring(uriStart, uriEnd)
    val rawPath = java.net.URI(rootUri).path ?: return
    val path = if (rawPath.length >= 3 && rawPath[0] == '/' && rawPath[2] == ':') {
        rawPath.substring(1)
    } else {
        rawPath
    }
    val pluginRoot = file("$path/android/src/main/kotlin/com/hiennv/flutter_callkit_incoming")
    val plugin = file("$pluginRoot/FlutterCallkitIncomingPlugin.kt")
    if (plugin.exists()) {
        var source = plugin.readText()
        if (!source.contains("RT-016")) {
            val initNeedle = """
                |            if (!::instance.isInitialized) {
                |                instance = FlutterCallkitIncomingPlugin()
                |                instance.callkitSoundPlayerManager = CallkitSoundPlayerManager(context)
                |                instance.callkitNotificationManager = CallkitNotificationManager(context, instance.callkitSoundPlayerManager)
                |                instance.context = context
                |            }
            """.trimMargin()
            val initHook = """
                |            if (!::instance.isInitialized) {
                |                instance = FlutterCallkitIncomingPlugin()
                |            }
                |            // RT-016: recreate the shared incoming UI if a secondary
                |            // engine detach cleared it.
                |            if (instance.callkitNotificationManager == null) {
                |                instance.callkitSoundPlayerManager = CallkitSoundPlayerManager(context)
                |                instance.callkitNotificationManager = CallkitNotificationManager(context, instance.callkitSoundPlayerManager)
                |            }
                |            if (instance.context == null) {
                |                instance.context = context
                |            }
            """.trimMargin()
            val detachNeedle = """
                |        methodChannels.remove(binding.binaryMessenger)?.setMethodCallHandler(null)
                |        eventChannels.remove(binding.binaryMessenger)?.setStreamHandler(null)
                |        instance.callkitSoundPlayerManager?.destroy()
                |        instance.callkitNotificationManager?.destroy()
                |        instance.callkitSoundPlayerManager = null
                |        instance.callkitNotificationManager = null
            """.trimMargin()
            val detachHook = """
                |        methodChannels.remove(binding.binaryMessenger)?.setMethodCallHandler(null)
                |        eventChannels.remove(binding.binaryMessenger)?.setStreamHandler(null)
                |        // RT-016: the main and FCM engines share this manager.
                |        if (methodChannels.isEmpty()) {
                |            instance.callkitSoundPlayerManager?.destroy()
                |            instance.callkitNotificationManager?.destroy()
                |            instance.callkitSoundPlayerManager = null
                |            instance.callkitNotificationManager = null
                |        }
            """.trimMargin()
            val activityNeedle = """
                |    override fun onDetachedFromActivity() {
                |        instance.context = null
                |        instance.activity = null
                |    }
            """.trimMargin()
            val activityHook = """
                |    override fun onDetachedFromActivity() {
                |        // RT-016: keep the application context so a background FCM
                |        // isolate can still broadcast the incoming call.
                |        instance.activity = null
                |    }
            """.trimMargin()
            if (!source.contains(initNeedle) || !source.contains(detachNeedle) || !source.contains(activityNeedle)) {
                logger.warn("RT-016: CallKit plugin shape changed; background incoming patch skipped")
            } else {
                source = source.replace(initNeedle, initHook)
                    .replace(detachNeedle, detachHook)
                    .replace(activityNeedle, activityHook)
                plugin.writeText(source)
                logger.lifecycle("RT-016: patched CallKit plugin ${plugin.path}")
            }
        }
    }
    val receiver = file("$pluginRoot/CallkitIncomingBroadcastReceiver.kt")
    if (receiver.exists()) {
        val source = receiver.readText()
        val needle = "callkitNotificationManager?.showIncomingNotification(data)"
        if (!source.contains("RT-016 incoming manager") && source.contains(needle)) {
            val hook = """
                |val incomingManager = callkitNotificationManager
                |                        ?: FlutterCallkitIncomingPlugin.getInstance()?.getCallkitNotificationManager()
                |                        ?: CallkitNotificationManager(context, CallkitSoundPlayerManager(context))
                |                    // RT-016 incoming manager
                |                    incomingManager.showIncomingNotification(data)
            """.trimMargin()
            receiver.writeText(source.replace(needle, hook))
            logger.lifecycle("RT-016: patched CallKit receiver ${receiver.path}")
        }
    }
}

patchCallkitBackgroundIncoming()

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
