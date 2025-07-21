package com.example.learningflutter

import android.annotation.SuppressLint
import android.app.Activity
import android.content.Context
import android.content.Intent
import android.graphics.PixelFormat
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.util.Log
import android.view.*
import android.widget.Toast
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    
    private val CHANNEL = "com.example.overlay/channel"
    private val OVERLAY_CHANNEL = "com.example.overlay/overlay_channel"
    private val OVERLAY_PERMISSION_REQUEST_CODE = 1001
    
    private lateinit var methodChannel: MethodChannel
    private lateinit var overlayMethodChannel: MethodChannel
    private var overlayManager: OverlayManager? = null
    
    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Setup main method channel
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel.setMethodCallHandler { call, result ->
            handleMethodCall(call, result)
        }
        
        // Setup overlay method channel
        overlayMethodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, OVERLAY_CHANNEL)
        overlayMethodChannel.setMethodCallHandler { call, result ->
            handleOverlayMethodCall(call, result)
        }
        
        overlayManager = OverlayManager(this, flutterEngine)
    }
    
    private fun handleMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "hasOverlayPermission" -> {
                result.success(hasOverlayPermission())
            }
            "requestOverlayPermission" -> {
                requestOverlayPermission()
                result.success(null)
            }
            "showOverlay" -> {
                if (hasOverlayPermission()) {
                    overlayManager?.showOverlay()
                    methodChannel.invokeMethod("updateOverlayStatus", true)
                    result.success(true)
                } else {
                    result.error("NO_PERMISSION", "Overlay permission not granted", null)
                }
            }
            "hideOverlay" -> {
                overlayManager?.hideOverlay()
                methodChannel.invokeMethod("updateOverlayStatus", false)
                result.success(true)
            }
            "updateOverlay" -> {
                val args = call.arguments as? Map<String, Any>
                overlayManager?.updateOverlayContent(args)
                result.success(true)
            }
            else -> {
                result.notImplemented()
            }
        }
    }
    
    private fun handleOverlayMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "closeOverlay" -> {
                overlayManager?.hideOverlay()
                methodChannel.invokeMethod("updateOverlayStatus", false)
                result.success(true)
            }
            "onDrag" -> {
                val args = call.arguments as? Map<String, Any>
                val x = args?.get("x") as? Double ?: 0.0
                val y = args?.get("y") as? Double ?: 0.0
                overlayManager?.updateOverlayPosition(x.toFloat(), y.toFloat())
                result.success(true)
            }
            else -> {
                result.notImplemented()
            }
        }
    }
    
    private fun hasOverlayPermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            Settings.canDrawOverlays(this)
        } else {
            true
        }
    }
    
    private fun requestOverlayPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !Settings.canDrawOverlays(this)) {
            Toast.makeText(this, "Please grant 'Display over other apps' permission", Toast.LENGTH_LONG).show()
            val intent = Intent(
                Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                Uri.parse("package:$packageName")
            )
            startActivityForResult(intent, OVERLAY_PERMISSION_REQUEST_CODE)
        }
    }
    
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == OVERLAY_PERMISSION_REQUEST_CODE) {
            if (hasOverlayPermission()) {
                Toast.makeText(this, "Permission granted! You can now show the overlay.", Toast.LENGTH_SHORT).show()
                overlayManager?.showOverlay()
                methodChannel.invokeMethod("updateOverlayStatus", true)
            } else {
                Toast.makeText(this, "Permission denied. Cannot show overlay.", Toast.LENGTH_SHORT).show()
            }
        }
    }
    
    override fun onDestroy() {
        super.onDestroy()
        overlayManager?.hideOverlay()
    }
}

// Overlay Manager Class
class OverlayManager(
    private val context: Context,
    private val flutterEngine: FlutterEngine
) {
    private val TAG = "OverlayManager"
    private val windowManager: WindowManager = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
    private var overlayView: View? = null
    private var layoutParams: WindowManager.LayoutParams? = null
    
    // Touch handling variables
    private var initialX = 0
    private var initialY = 0
    private var initialTouchX = 0f
    private var initialTouchY = 0f
    
    @SuppressLint("ClickableViewAccessibility")
    fun showOverlay() {
        try {
            if (overlayView != null) {
                hideOverlay()
            }
            
            // Create Flutter view for overlay
            val flutterView = io.flutter.embedding.android.FlutterView(context)
            val dartExecutor = flutterEngine.dartExecutor
            
            // Execute overlay entry point
            dartExecutor.executeDartEntrypoint(
                io.flutter.view.FlutterMain.findAppBundlePath(),
                "overlayMain"
            )
            
            overlayView = flutterView
            
            // Configure window layout parameters
            val type = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            } else {
                @Suppress("DEPRECATION")
                WindowManager.LayoutParams.TYPE_PHONE
            }
            
            layoutParams = WindowManager.LayoutParams(
                WindowManager.LayoutParams.WRAP_CONTENT,
                WindowManager.LayoutParams.WRAP_CONTENT,
                type,
                WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                        WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                        WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL,
                PixelFormat.TRANSLUCENT
            ).apply {
                gravity = Gravity.TOP or Gravity.START
                x = 100
                y = 100
                width = dpToPx(150)
                height = dpToPx(100)
            }
            
            // Add touch listener for drag functionality
            overlayView?.setOnTouchListener { view, event ->
                when (event.action) {
                    MotionEvent.ACTION_DOWN -> {
                        initialX = layoutParams?.x ?: 0
                        initialY = layoutParams?.y ?: 0
                        initialTouchX = event.rawX
                        initialTouchY = event.rawY
                        true
                    }
                    MotionEvent.ACTION_MOVE -> {
                        val newX = (initialX + (event.rawX - initialTouchX)).toInt()
                        val newY = (initialY + (event.rawY - initialTouchY)).toInt()
                        
                        // Update layout parameters
                        layoutParams?.x = newX
                        layoutParams?.y = newY
                        
                        // Update view layout
                        try {
                            windowManager.updateViewLayout(overlayView, layoutParams)
                        } catch (e: Exception) {
                            Log.e(TAG, "Error updating view layout: ${e.message}")
                        }
                        true
                    }
                    MotionEvent.ACTION_UP -> {
                        // Snap to edges if desired
                        snapToEdge()
                        true
                    }
                    else -> false
                }
            }
            
            // Add overlay to window
            windowManager.addView(overlayView, layoutParams)
            Log.d(TAG, "Overlay shown successfully")
            
        } catch (e: Exception) {
            Log.e(TAG, "Error showing overlay: ${e.message}")
        }
    }
    
    fun hideOverlay() {
        try {
            overlayView?.let {
                windowManager.removeView(it)
                overlayView = null
                layoutParams = null
                Log.d(TAG, "Overlay hidden successfully")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error hiding overlay: ${e.message}")
        }
    }
    
    fun updateOverlayContent(args: Map<String, Any>?) {
        // This would be handled by the Flutter overlay widget through method channel
        args?.let {
            val methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, 
                "com.example.overlay/overlay_channel")
            methodChannel.invokeMethod("updateContent", it)
        }
    }
    
    fun updateOverlayPosition(x: Float, y: Float) {
        layoutParams?.let { params ->
            params.x = x.toInt()
            params.y = y.toInt()
            overlayView?.let { view ->
                try {
                    windowManager.updateViewLayout(view, params)
                } catch (e: Exception) {
                    Log.e(TAG, "Error updating overlay position: ${e.message}")
                }
            }
        }
    }
    
    private fun snapToEdge() {
        layoutParams?.let { params ->
            val displayMetrics = context.resources.displayMetrics
            val screenWidth = displayMetrics.widthPixels
            val screenHeight = displayMetrics.heightPixels
            val viewWidth = params.width
            val viewHeight = params.height
            
            // Snap to left or right edge
            if (params.x < screenWidth / 2) {
                // Snap to left edge
                params.x = 0
            } else {
                // Snap to right edge
                params.x = screenWidth - viewWidth
            }
            
            // Keep within screen bounds vertically
            if (params.y < 0) {
                params.y = 0
            } else if (params.y > screenHeight - viewHeight) {
                params.y = screenHeight - viewHeight
            }
            
            overlayView?.let { view ->
                try {
                    windowManager.updateViewLayout(view, params)
                } catch (e: Exception) {
                    Log.e(TAG, "Error snapping to edge: ${e.message}")
                }
            }
        }
    }
    
    private fun dpToPx(dp: Int): Int {
        val density = context.resources.displayMetrics.density
        return (dp * density).toInt()
    }
}
