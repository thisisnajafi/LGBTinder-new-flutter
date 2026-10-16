package com.lgbtfinder

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.media.AudioAttributes
import android.media.RingtoneManager
import android.os.Build

/**
 * CallKit's incoming channel. Importance is frozen after the first create, so
 * a channel left below HIGH is deleted and created again at MAX with a ringtone.
 */
object IncomingCallChannel {
    const val id = "callkit_incoming_channel_id"

    fun ensure(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = context.getSystemService(NotificationManager::class.java) ?: return
        val existing = manager.getNotificationChannel(id)
        if (existing != null && existing.importance < NotificationManager.IMPORTANCE_HIGH) {
            manager.deleteNotificationChannel(id)
        }
        val sound = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE)
        val attributes = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_NOTIFICATION_RINGTONE)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build()
        val channel = NotificationChannel(
            id,
            "Incoming Calls",
            NotificationManager.IMPORTANCE_MAX,
        ).apply {
            description = "Incoming voice and video calls"
            lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            enableVibration(true)
            vibrationPattern = longArrayOf(0, 1000, 500, 1000)
            setSound(sound, attributes)
        }
        manager.createNotificationChannel(channel)
    }
}
