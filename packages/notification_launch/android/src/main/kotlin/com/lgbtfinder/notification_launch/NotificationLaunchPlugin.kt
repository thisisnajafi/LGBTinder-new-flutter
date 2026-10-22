package com.lgbtfinder.notification_launch

import android.app.Notification
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.util.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class NotificationLaunchPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private var channel: MethodChannel? = null
    private var appContext: Context? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        appContext = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, CHANNEL)
        channel?.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel?.setMethodCallHandler(null)
        channel = null
        appContext = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "bindTapIntent" -> {
                val context = appContext
                if (context == null) {
                    result.error("NO_CONTEXT", "Missing context", null)
                    return
                }
                val id = call.argument<Int>("id")
                val payload = call.argument<String>("payload")
                if (id == null || payload.isNullOrEmpty()) {
                    result.error("BAD_ARGS", "id and payload are required", null)
                    return
                }
                LaunchIntents.bindTapIntent(
                    context,
                    id,
                    call.argument<String>("tag"),
                    payload,
                )
                result.success(null)
            }

            "takePayload" -> result.success(LaunchIntents.takePayload())
            else -> result.notImplemented()
        }
    }

    companion object {
        const val CHANNEL = "com.lgbtfinder/notification_launch"
    }
}

/**
 * Content intent for a tray row posted while no Activity exists.
 *
 * The local-notifications plugin starts from the launcher intent, which keeps
 * CATEGORY_LAUNCHER and FLAG_ACTIVITY_RESET_TASK_IF_NEEDED. Android then
 * delivers a plain MAIN intent and the chat payload never reaches Dart.
 */
object LaunchIntents {
    private const val logTag = "LaunchRoute"
    const val selectAction = "SELECT_NOTIFICATION"
    private const val foregroundAction = "SELECT_FOREGROUND_NOTIFICATION"
    private const val payloadKey = "payload"
    private const val idKey = "notificationId"
    private const val tagKey = "notificationTag"

    @Volatile
    private var pendingPayload: String? = null

    fun capture(intent: Intent?) {
        if (intent == null) {
            Log.i(logTag, "[LaunchRoute] native intent missing")
            return
        }
        val payload = intent.getStringExtra(payloadKey)
        Log.i(
            logTag,
            "[LaunchRoute] native intent action=${intent.action} hasPayload=${!payload.isNullOrEmpty()}",
        )
        if (payload.isNullOrEmpty()) return
        if (intent.action != selectAction && intent.action != foregroundAction) return
        pendingPayload = payload
        Log.i(logTag, "[LaunchRoute] native capture stored")
    }

    fun takePayload(): String? {
        val value = pendingPayload
        pendingPayload = null
        if (!value.isNullOrEmpty()) {
            Log.i(logTag, "[LaunchRoute] native payload delivered")
        }
        return value
    }

    fun bindTapIntent(context: Context, id: Int, tag: String?, payload: String) {
        val pending = buildPendingIntent(context, id, tag, payload)
        if (pending == null) {
            Log.w(logTag, "[LaunchRoute] bind failed: no launch component")
            return
        }
        val manager = context.getSystemService(NotificationManager::class.java)
        if (manager == null) {
            Log.w(logTag, "[LaunchRoute] bind failed: no notification manager")
            return
        }
        val active = manager.activeNotifications
        val exact = active.filter { it.id == id && (tag.isNullOrEmpty() || it.tag == tag) }
        val chosen = if (exact.isNotEmpty()) exact else active.filter { it.id == id }
        if (chosen.isEmpty()) {
            Log.w(logTag, "[LaunchRoute] bind missed active notification id=$id tag=$tag")
            return
        }
        val code = requestCode(id, tag)
        for (item in chosen) {
            val rebuilt = Notification.Builder.recoverBuilder(context, item.notification)
                .setContentIntent(pending)
                .build()
            manager.notify(item.tag, item.id, rebuilt)
            Log.i(logTag, "[LaunchRoute] bind id=${item.id} tag=${item.tag} requestCode=$code")
        }
    }

    /** 32-bit mix. Must match [notificationLaunchRequestCode] in Dart. */
    fun requestCode(id: Int, tag: String?): Int {
        var code = id
        if (!tag.isNullOrEmpty()) {
            code = (code * 31) xor tag.length
            for (ch in tag) {
                code = (code * 31) + ch.code
            }
        }
        return code
    }

    private fun buildPendingIntent(
        context: Context,
        id: Int,
        tag: String?,
        payload: String,
    ): PendingIntent? {
        val component = context.packageManager
            .getLaunchIntentForPackage(context.packageName)
            ?.component
            ?: return null
        val intent = Intent().setComponent(component).apply {
            action = selectAction
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                Intent.FLAG_ACTIVITY_CLEAR_TOP or
                Intent.FLAG_ACTIVITY_SINGLE_TOP
            putExtra(payloadKey, payload)
            putExtra(idKey, id)
            if (!tag.isNullOrEmpty()) putExtra(tagKey, tag)
        }
        val flags = PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        return PendingIntent.getActivity(context, requestCode(id, tag), intent, flags)
    }
}
