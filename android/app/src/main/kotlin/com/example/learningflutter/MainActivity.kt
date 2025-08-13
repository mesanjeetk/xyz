package com.example.learningflutter

import android.Manifest
import android.content.ActivityNotFoundException
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import androidx.activity.result.contract.ActivityResultContracts
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.sanjeet.universalops/channel"
    private lateinit var channel: MethodChannel

    // Permission launcher for Android 13+ POST_NOTIFICATIONS
    private val notificationsPermissionLauncher =
        registerForActivityResult(ActivityResultContracts.RequestPermission()) { /* no-op */ }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)

        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "requestNotificationPermission" -> {
                    requestNotificationPermission()
                    result.success(null)
                }

                "openLink" -> {
                    val url = call.argument<String>("url")
                    val packageName = call.argument<String>("packageName")

                    if (url.isNullOrBlank()) {
                        result.error("INVALID_URL", "URL is null or blank", null)
                    } else {
                        openLink(url, packageName)
                        result.success(null)
                    }
                }

                "showNotification" -> {
                    val title = call.argument<String>("title") ?: "Title"
                    val text = call.argument<String>("text") ?: "Text"
                    val imageUrl = call.argument<String>("imageUrl") ?: ""
                    val intent = Intent(this, MyForegroundService::class.java).apply {
                        putExtra("title", title)
                        putExtra("text", text)
                        putExtra("imageUrl", imageUrl)
                    }
                    ContextCompat.startForegroundService(this, intent)
                    result.success(null)
                }

                "updateNotification" -> {
                    val intent = Intent(this, MyForegroundService::class.java).apply {
                        action = "ACTION_UPDATE"
                        putExtra("title", call.argument<String>("title"))
                        putExtra("text", call.argument<String>("text"))
                        putExtra("imageUrl", call.argument<String>("imageUrl"))
                    }
                    startService(intent)
                    result.success(null)
                }

                "stopNotification" -> {
                    val intent = Intent(this, MyForegroundService::class.java)
                    stopService(intent)
                    result.success(null)
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun requestNotificationPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            val granted = ContextCompat.checkSelfPermission(
                this, Manifest.permission.POST_NOTIFICATIONS
            ) == PackageManager.PERMISSION_GRANTED
            if (!granted) {
                notificationsPermissionLauncher.launch(Manifest.permission.POST_NOTIFICATIONS)
            }
        }
    }

    private fun openLink(url: String, packageName: String?) {
        try {
            val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url))
            if (!packageName.isNullOrEmpty()) {
                // Try to open in a specific app (e.g., YouTube); if missing, go to Play Store
                intent.setPackage(packageName)
            }
            startActivity(intent)
        } catch (e: ActivityNotFoundException) {
            if (!packageName.isNullOrEmpty()) {
                // App not installed → redirect to Play Store (app), else Play web
                try {
                    val playStoreIntent = Intent(Intent.ACTION_VIEW, Uri.parse("market://details?id=$packageName"))
                    startActivity(playStoreIntent)
                } catch (_: ActivityNotFoundException) {
                    val webIntent = Intent(Intent.ACTION_VIEW,
                        Uri.parse("https://play.google.com/store/apps/details?id=$packageName"))
                    startActivity(webIntent)
                }
            } else {
                // No package forced → open with browser as fallback (WhatsApp-style)
                val browserIntent = Intent(Intent.ACTION_VIEW, Uri.parse(url)).apply {
                    addCategory(Intent.CATEGORY_BROWSABLE)
                }
                startActivity(browserIntent)
            }
        }
    }
}
