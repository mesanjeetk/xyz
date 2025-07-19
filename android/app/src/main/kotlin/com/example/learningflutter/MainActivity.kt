package com.example.learningflutter

import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.view.LayoutInflater
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.Toast
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.floating/widget"
    private var windowManager: WindowManager? = null
    private var overlayView: View? = null
    private var lastTouchTime = System.currentTimeMillis()

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
        if (overlayView != null) return

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

        val icon = overlayView!!.findViewById<ImageView>(R.id.floating_icon)
        val toolsPanel = overlayView!!.findViewById<LinearLayout>(R.id.tools_panel)

        var isToolsVisible = false
        val handler = Handler(Looper.getMainLooper())

        val idleRunnable = object : Runnable {
            override fun run() {
                if (System.currentTimeMillis() - lastTouchTime > 4000) {
                    icon.alpha = 0.3f
                }
                handler.postDelayed(this, 1000)
            }
        }
        handler.post(idleRunnable)

        icon.setOnClickListener {
            isToolsVisible = !isToolsVisible
            toolsPanel.visibility = if (isToolsVisible) View.VISIBLE else View.GONE
        }

        icon.setOnTouchListener(object : View.OnTouchListener {
            var lastX = 0
            var lastY = 0
            override fun onTouch(v: View, event: MotionEvent): Boolean {
                when (event.action) {
                    MotionEvent.ACTION_DOWN -> {
                        lastTouchTime = System.currentTimeMillis()
                        icon.alpha = 1f
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

        val tool1 = overlayView!!.findViewById<Button>(R.id.tool_1)
        val tool2 = overlayView!!.findViewById<Button>(R.id.tool_2)
        val closeBtn = overlayView!!.findViewById<Button>(R.id.close_button)

        tool1.setOnClickListener {
            Toast.makeText(this, "Tool 1 triggered", Toast.LENGTH_SHORT).show()
        }

        tool2.setOnClickListener {
            Toast.makeText(this, "Tool 2 triggered", Toast.LENGTH_SHORT).show()
        }

        closeBtn.setOnClickListener {
            removeFloatingWidget()
        }

        windowManager!!.addView(overlayView, params)
    }

    private fun removeFloatingWidget() {
        if (windowManager != null && overlayView != null) {
            windowManager!!.removeView(overlayView)
            overlayView = null
        }
    }
}
