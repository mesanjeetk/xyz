package com.example.learningflutter

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.widget.Toast

class NotificationActionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            "ACTION_PLAY", "ACTION_PAUSE" -> {
                MyForegroundService.lastInstance?.togglePlayPause()
                    ?: Toast.makeText(context, "Service not active", Toast.LENGTH_SHORT).show()
            }
            "ACTION_STOP" -> {
                MyForegroundService.lastInstance?.stopAndRemove()
                    ?: run {
                        // If service already dead, just inform
                        Toast.makeText(context, "Already stopped", Toast.LENGTH_SHORT).show()
                    }
            }
        }
    }
}
