package com.example.learningflutter

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.app/launcher"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "openUrl") {
                val url = call.argument<String>("url")
                if (url != null) {
                    openUrl(url)
                    result.success(true)
                } else {
                    result.error("INVALID_URL", "URL is null or empty", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun openUrl(url: String) {
        val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url))
        // Ensure it opens in app if possible
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        try {
            startActivity(intent)
        } catch (e: Exception) {
            // fallback to Chrome if app not installed
            val fallbackIntent = Intent(Intent.ACTION_VIEW, Uri.parse(url))
            fallbackIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(fallbackIntent)
        }
    }
}
