package com.example.learningflutter

import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import android.widget.Toast
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.universal_link_opener"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->
            if (call.method == "openLink") {
                val url = call.argument<String>("url")
                if (url != null) {
                    openLink(url)
                    result.success(null)
                } else {
                    result.error("INVALID_URL", "URL is null", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun openLink(url: String) {
        try {
            // Try to open in matching app
            val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url))
            startActivity(intent)
        } catch (e: ActivityNotFoundException) {
            // Fallback: Try to open in browser
            try {
                val browserIntent = Intent(Intent.ACTION_VIEW, Uri.parse(url))
                browserIntent.addCategory(Intent.CATEGORY_BROWSABLE)
                startActivity(browserIntent)
            } catch (ex: Exception) {
                Toast.makeText(this, "No app found to open this link", Toast.LENGTH_LONG).show()
            }
        }
    }
}
