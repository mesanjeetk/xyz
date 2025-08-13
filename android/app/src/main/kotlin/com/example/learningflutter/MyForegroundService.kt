package com.example.learningflutter

import android.app.Service
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.os.IBinder
import java.net.URL
import kotlin.concurrent.thread

class MyForegroundService : Service() {

    // In-memory state (simple demo)
    private var title: String = "Title"
    private var text: String = "Text"
    private var imageUrl: String = ""
    private var largeIcon: Bitmap? = null
    private var isPlaying: Boolean = true

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        NotificationHelper.ensureChannel(this)

        when (intent?.action) {
            "ACTION_UPDATE" -> {
                intent.getStringExtra("title")?.let { title = it }
                intent.getStringExtra("text")?.let { text = it }
                intent.getStringExtra("imageUrl")?.let { imageUrl = it }
                refreshNotification(loadImageIfNeeded = true)
            }

            else -> { // First start
                title = intent?.getStringExtra("title") ?: "Title"
                text = intent?.getStringExtra("text") ?: "Text"
                imageUrl = intent?.getStringExtra("imageUrl") ?: ""
                refreshNotification(loadImageIfNeeded = true, startForegroundNow = true)
            }
        }

        return START_STICKY
    }

    private fun refreshNotification(loadImageIfNeeded: Boolean, startForegroundNow: Boolean = false) {
        if (loadImageIfNeeded && imageUrl.isNotBlank()) {
            thread {
                try {
                    URL(imageUrl).openStream().use { stream ->
                        largeIcon = BitmapFactory.decodeStream(stream)
                    }
                } catch (_: Exception) {
                    largeIcon = null
                }
                postNotification(startForegroundNow)
            }
        } else {
            postNotification(startForegroundNow)
        }
    }

    private fun postNotification(startForegroundNow: Boolean) {
        val notification = NotificationHelper.buildPersistent(
            context = this,
            title = title,
            text = text,
            largeIcon = largeIcon,
            isPlaying = isPlaying
        )
        if (startForegroundNow) {
            startForeground(NotificationHelper.NOTIFICATION_ID, notification)
        } else {
            val mgr = getSystemService(NOTIFICATION_SERVICE) as android.app.NotificationManager
            mgr.notify(NotificationHelper.NOTIFICATION_ID, notification)
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    fun togglePlayPause() {
        isPlaying = !isPlaying
        text = if (isPlaying) text.replace("Paused", "Now playing")
              else if (!text.contains("Paused")) "$text • Paused" else text
        postNotification(false)
    }

    fun stopAndRemove() {
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
    }

    companion object {
        // Simple access for receiver (same process)
        @Volatile var lastInstance: MyForegroundService? = null
    }

    override fun onCreate() {
        super.onCreate()
        lastInstance = this
    }

    override fun onDestroy() {
        lastInstance = null
        super.onDestroy()
    }
}
