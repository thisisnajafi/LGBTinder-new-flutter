package com.lgbtfinder

import android.app.NotificationManager
import android.content.ContentValues
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.provider.MediaStore
import android.util.Log
import android.view.WindowManager
import com.lgbtfinder.notification_launch.LaunchIntents
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileInputStream

class MainActivity : FlutterActivity() {
    private val screenshotChannel = "com.lgbtfinder/screenshot_protection"
    private val galleryChannel = "com.lgbtfinder/gallery_save"

    override fun onCreate(savedInstanceState: Bundle?) {
        LaunchIntents.capture(intent)
        super.onCreate(savedInstanceState)
    }

    override fun onNewIntent(intent: Intent) {
        LaunchIntents.capture(intent)
        setIntent(intent)
        super.onNewIntent(intent)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.lgbtfinder/full_screen_intent",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "canUseFullScreenIntent" -> {
                    val allowed = canUseFullScreenIntent()
                    Log.i(
                        "FSIGate",
                        "[FSIGate] canUseFullScreenIntent=$allowed sdk=${Build.VERSION.SDK_INT}",
                    )
                    result.success(allowed)
                }

                "openFullScreenIntentSettings" -> {
                    openFullScreenIntentSettings()
                    result.success(null)
                }

                else -> result.notImplemented()
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.lgbtfinder/incoming_call_alerts",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "ensure" -> {
                    IncomingCallChannel.ensure(this)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.lgbtfinder/callkit_killed")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "setListening" -> {
                        CallkitKilledAction.dartListening = call.arguments == true
                        Log.i(
                            "CallkitKilledAction",
                            "Dart listening=${CallkitKilledAction.dartListening}; only explicit Decline is persisted",
                        )
                        result.success(null)
                    }

                    "completed" -> result.success(null)

                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, screenshotChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "enable" -> {
                        window.setFlags(
                            WindowManager.LayoutParams.FLAG_SECURE,
                            WindowManager.LayoutParams.FLAG_SECURE,
                        )
                        result.success(null)
                    }

                    "disable" -> {
                        window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                        result.success(null)
                    }

                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, galleryChannel)
            .setMethodCallHandler { call, result ->
                if (call.method != "saveImage") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val path = call.argument<String>("path")
                if (path.isNullOrEmpty()) {
                    result.error("BAD_PATH", "Missing image path", null)
                    return@setMethodCallHandler
                }
                result.success(saveImageToGallery(path))
            }
    }

    private fun canUseFullScreenIntent(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.UPSIDE_DOWN_CAKE) return true
        val manager = getSystemService(NotificationManager::class.java) ?: return false
        return manager.canUseFullScreenIntent()
    }

    private fun openFullScreenIntentSettings() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.UPSIDE_DOWN_CAKE) return
        val settings = Intent(Settings.ACTION_MANAGE_APP_USE_FULL_SCREEN_INTENT).apply {
            data = Uri.parse("package:$packageName")
        }
        Log.i("FSIGate", "[FSIGate] open settings package:$packageName")
        startActivity(settings)
    }

    private fun saveImageToGallery(path: String): Boolean {
        val file = File(path)
        if (!file.exists()) return false
        val mime = when (file.extension.lowercase()) {
            "png" -> "image/png"
            "webp" -> "image/webp"
            "gif" -> "image/gif"
            else -> "image/jpeg"
        }
        val name = "lgbtfinder_${System.currentTimeMillis()}.${file.extension.ifEmpty { "jpg" }}"
        val values = ContentValues().apply {
            put(MediaStore.Images.Media.DISPLAY_NAME, name)
            put(MediaStore.Images.Media.MIME_TYPE, mime)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                put(MediaStore.Images.Media.RELATIVE_PATH, "Pictures/LGBTFinder")
                put(MediaStore.Images.Media.IS_PENDING, 1)
            }
        }
        val resolver = contentResolver
        val uri = resolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values)
            ?: return false
        return try {
            resolver.openOutputStream(uri)?.use { output ->
                FileInputStream(file).use { input -> input.copyTo(output) }
            } ?: return false
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                values.clear()
                values.put(MediaStore.Images.Media.IS_PENDING, 0)
                resolver.update(uri, values, null, null)
            }
            true
        } catch (_: Exception) {
            resolver.delete(uri, null, null)
            false
        }
    }
}
