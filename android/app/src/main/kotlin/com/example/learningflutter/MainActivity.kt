package com.example.learningflutter

import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.view.LayoutInflater
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.TextView
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.floating/widget"
    private var windowManager: WindowManager? = null
    private var overlayView: View? = null
    private var clickCount = 0

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "showOverlay" -> {
                        if (Settings.canDrawOverlays(this)) {
                            showFloatingWidget()
                        } else {
                            val intent = Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION)
                            intent.data = android.net.Uri.parse("package:$packageName")
                            startActivity(intent)
                        }
                        result.success(null)
                    }

                    "closeOverlay" -> {
                        removeFloatingWidget()
                        result.success(null)
                    }

                    else -> result.notImplemented()
                }
            }
    }

    private fun showFloatingWidget() {
        if (overlayView != null) return // already showing

        windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
        overlayView = LayoutInflater.from(this).inflate(R.layout.floating_widget, null)

        val layoutFlag = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        else
            WindowManager.LayoutParams.TYPE_PHONE

        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            layoutFlag,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
            android.graphics.PixelFormat.TRANSLUCENT
        )

        params.x = 100
        params.y = 200

        val floatingButton = overlayView!!.findViewById<Button>(R.id.floating_button)
        val floatingText = overlayView!!.findViewById<TextView>(R.id.floating_text)
        val closeBtn = overlayView!!.findViewById<Button>(R.id.close_button)

        floatingButton.setOnClickListener {
            clickCount++
            floatingText.text = "Clicks: $clickCount"
        }

        closeBtn.setOnClickListener {
            removeFloatingWidget()
        }

        overlayView!!.setOnTouchListener(object : View.OnTouchListener {
            var lastX = 0
            var lastY = 0
            override fun onTouch(v: View, event: MotionEvent): Boolean {
                when (event.action) {
                    MotionEvent.ACTION_DOWN -> {
                        lastX = event.rawX.toInt()
                        lastY = event.rawY.toInt()
                        return true
                    }

                    MotionEvent.ACTION_MOVE -> {
                        val deltaX = event.rawX.toInt() - lastX
                        val deltaY = event.rawY.toInt() - lastY
                        params.x += deltaX
                        params.y += deltaY
                        windowManager!!.updateViewLayout(overlayView, params)
                        lastX = event.rawX.toInt()
                        lastY = event.rawY.toInt()
                        return true
                    }
                }
                return false
            }
        })

        windowManager!!.addView(overlayView, params)
    }

    private fun removeFloatingWidget() {
        if (windowManager != null && overlayView != null) {
            windowManager!!.removeView(overlayView)
            overlayView = null
        }
    }
}
