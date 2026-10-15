package com.lgbtfinder

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import android.util.Log
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant
import org.json.JSONArray
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicBoolean

/**
 * RT-013: Decline / timeout from flutter_callkit_incoming while the process
 * was killed never reaches the Dart event stream. The plugin receiver calls
 * [onCallkitAction] via reflection. This persists the action, then runs
 * [callkitBackgroundHandler] with the mirrored bearer token.
 */
object CallkitKilledAction {
    private const val TAG = "CallkitKilledAction"
    private const val CHANNEL = "com.lgbtfinder/callkit_killed"
    private const val PREFS = "FlutterSharedPreferences"
    private const val PENDING_KEY = "flutter.lgbtfinder_callkit_pending_actions"
    private const val TOKEN_KEY = "flutter.lgbtfinder_bg_auth_token"
    private const val ORIGIN_KEY = "flutter.lgbtfinder_bg_api_origin"
    private const val ENTRYPOINT_LIBRARY =
        "package:lgbtindernew/features/calls/data/services/callkit_pending_flusher.dart"
    private const val ENTRYPOINT = "callkitBackgroundHandler"

    @Volatile
    var dartListening: Boolean = false

    private val engineRunning = AtomicBoolean(false)
    private var engine: FlutterEngine? = null

    @JvmStatic
    fun onCallkitAction(receiver: BroadcastReceiver, context: Context, intent: Intent) {
        val action = intent.action ?: return
        val kind = kindFor(action)
        if (kind == null) {
            Log.i(TAG, "Ignoring $action (not an explicit Decline)")
            return
        }
        val callId = callIdFrom(intent) ?: return
        persist(context, callId, kind)
        if (dartListening) {
            Log.i(TAG, "Dart is listening; queued $kind $callId")
            return
        }
        if (!engineRunning.compareAndSet(false, true)) {
            Log.i(TAG, "Background handler already running; queued $kind $callId")
            return
        }

        val pendingResult = receiver.goAsync()
        val wakeLock = (context.getSystemService(Context.POWER_SERVICE) as PowerManager)
            .newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "lgbtinder:callkit")
        wakeLock.setReferenceCounted(false)
        wakeLock.acquire(20_000L)
        val appContext = context.applicationContext

        Thread {
            val latch = CountDownLatch(1)
            try {
                startEngine(appContext, latch)
                latch.await(12, TimeUnit.SECONDS)
                if (readPending(appContext).length() > 0) {
                    Log.w(TAG, "Isolate left pending actions; HTTP fallback")
                    postPending(appContext)
                }
            } catch (error: Throwable) {
                Log.e(TAG, "Background decline failed", error)
                try {
                    postPending(appContext)
                } catch (fallback: Throwable) {
                    Log.e(TAG, "HTTP fallback failed", fallback)
                }
            } finally {
                stopEngine()
                engineRunning.set(false)
                if (wakeLock.isHeld) wakeLock.release()
                pendingResult.finish()
            }
        }.start()
    }

    /**
     * Only the Decline button (notification action or in-call activity).
     * Timeout, ended, dismiss, and notification removal must not be stored.
     * [endCall] on an unanswered row used to broadcast DECLINE; the Gradle
     * RT-019 patch sends ENDED for that path instead.
     */
    private fun kindFor(action: String): String? {
        return if (action.endsWith("ACTION_CALL_DECLINE")) "decline" else null
    }

    private fun callIdFrom(intent: Intent): String? {
        val data = intent.extras?.getBundle("EXTRA_CALLKIT_INCOMING_DATA") ?: return null
        val id = data.getString("EXTRA_CALLKIT_ID")?.trim().orEmpty()
        if (id.matches(Regex("^[0-9]+$"))) return id
        val extra = data.getSerializable("EXTRA_CALLKIT_EXTRA")
        if (extra is Map<*, *>) {
            val fromExtra = (extra["call_id"] ?: extra["callId"])?.toString()?.trim().orEmpty()
            if (fromExtra.matches(Regex("^[0-9]+$"))) return fromExtra
        }
        return null
    }

    private fun prefs(context: Context): SharedPreferences {
        return context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
    }

    private fun persist(context: Context, callId: String, kind: String) {
        val current = readPending(context)
        val next = JSONArray()
        var replaced = false
        for (index in 0 until current.length()) {
            val row = current.optJSONObject(index) ?: continue
            if (row.optString("callId") != callId) {
                next.put(row)
                continue
            }
            next.put(declineRow(callId))
            replaced = true
        }
        if (!replaced) {
            next.put(declineRow(callId))
        }
        prefs(context).edit().putString(PENDING_KEY, next.toString()).commit()
        Log.i(TAG, "Persisted explicit $kind $callId")
    }

    private fun declineRow(callId: String): JSONObject {
        return JSONObject()
            .put("callId", callId)
            .put("kind", "decline")
            .put("at", System.currentTimeMillis())
    }

    private fun readPending(context: Context): JSONArray {
        val raw = prefs(context).getString(PENDING_KEY, null) ?: return JSONArray()
        return try {
            JSONArray(raw)
        } catch (_: Throwable) {
            JSONArray()
        }
    }

    private fun startEngine(context: Context, latch: CountDownLatch) {
        Handler(Looper.getMainLooper()).post {
            try {
                val loader = FlutterInjector.instance().flutterLoader()
                loader.startInitialization(context)
                loader.ensureInitializationComplete(context, null)
                val created = FlutterEngine(context)
                engine = created
                GeneratedPluginRegistrant.registerWith(created)
                MethodChannel(created.dartExecutor.binaryMessenger, CHANNEL)
                    .setMethodCallHandler { call, result ->
                        if (call.method == "completed") {
                            result.success(null)
                            latch.countDown()
                        } else {
                            result.notImplemented()
                        }
                    }
                created.dartExecutor.executeDartEntrypoint(
                    DartExecutor.DartEntrypoint(
                        loader.findAppBundlePath(),
                        ENTRYPOINT_LIBRARY,
                        ENTRYPOINT,
                    ),
                )
            } catch (error: Throwable) {
                Log.e(TAG, "Flutter isolate failed to start", error)
                latch.countDown()
            }
        }
    }

    private fun stopEngine() {
        val current = engine
        engine = null
        if (current == null) return
        Handler(Looper.getMainLooper()).post {
            try {
                current.destroy()
            } catch (error: Throwable) {
                Log.w(TAG, "Engine destroy failed", error)
            }
        }
    }

    private fun postPending(context: Context) {
        val store = prefs(context)
        val token = store.getString(TOKEN_KEY, null)?.trim().orEmpty()
        val origin = store.getString(ORIGIN_KEY, null)?.trim()?.trimEnd('/').orEmpty()
        if (token.isEmpty() || origin.isEmpty()) {
            Log.w(TAG, "Missing mirrored auth token; pending stays for next start")
            return
        }
        val pending = readPending(context)
        val remaining = JSONArray()
        for (index in 0 until pending.length()) {
            val row = pending.optJSONObject(index) ?: continue
            val callId = row.optString("callId")
            val kind = row.optString("kind")
            val recordedAt = row.optLong("at", 0L)
            if (kind != "decline") {
                Log.i(TAG, "Dropping stored $kind $callId (not an explicit Decline)")
                continue
            }
            if (recordedAt <= 0L || System.currentTimeMillis() - recordedAt > 60_000L) {
                Log.i(TAG, "Dropping stale decline $callId ageMs=${if (recordedAt <= 0L) -1 else System.currentTimeMillis() - recordedAt}")
                continue
            }
            val path = when (kind) {
                "decline" -> "/api/calls/$callId/reject"
                "timeout" -> "/api/calls/$callId/end"
                else -> null
            }
            if (path == null || !callId.matches(Regex("^[0-9]+$"))) {
                remaining.put(row)
                continue
            }
            val reason = if (kind == "timeout") "CallKit timeout" else "User rejected the call"
            val status = postJson("$origin$path", token, "{\"reason\":\"$reason\"}")
            Log.i(TAG, "Fallback $kind $callId -> $status")
            if (!shouldDrop(status)) remaining.put(row)
        }
        val editor = store.edit()
        if (remaining.length() == 0) editor.remove(PENDING_KEY) else editor.putString(PENDING_KEY, remaining.toString())
        editor.commit()
    }

    private fun postJson(url: String, token: String, body: String): Int {
        val connection = (URL(url).openConnection() as HttpURLConnection).apply {
            requestMethod = "POST"
            connectTimeout = 8_000
            readTimeout = 12_000
            doOutput = true
            setRequestProperty("Authorization", "Bearer $token")
            setRequestProperty("Accept", "application/json")
            setRequestProperty("Content-Type", "application/json")
        }
        return try {
            connection.outputStream.use { it.write(body.toByteArray(Charsets.UTF_8)) }
            connection.responseCode
        } finally {
            connection.disconnect()
        }
    }

    private fun shouldDrop(status: Int): Boolean {
        if (status in 200..299) return true
        return status == 400 || status == 403 || status == 404 || status == 409 || status == 422
    }
}
