package com.example.learningflutter

import android.app.Service
import android.content.Intent
import android.graphics.PixelFormat
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.view.*
import android.view.View.OnTouchListener
import android.widget.Button
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.Toast

class FloatingWidgetService : Service() {

    private var windowManager: WindowManager? = null
    private var floatingView: View? = null
    private var isPanelVisible = false
    private var idleHandler: Handler = Handler()
    private var idleRunnable: Runnable? = null

    override fun onCreate() {
        super.onCreate()
        floatingView = LayoutInflater.from(this).inflate(R.layout.floating_widget, null)

        val layoutFlag = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        else
            WindowManager.LayoutParams.TYPE_PHONE

        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            layoutFlag,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
            PixelFormat.TRANSLUCENT
        )

        params.gravity = Gravity.TOP or Gravity.START
        params.x = 100
        params.y = 200

        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager
        if (floatingView?.parent == null) {
            windowManager?.addView(floatingView, params)
        }

        val floatingIcon = floatingView!!.findViewById<ImageView>(R.id.floating_icon)
        val toolPanel = floatingView!!.findViewById<LinearLayout>(R.id.tools_panel)

        floatingIcon.setOnClickListener {
            isPanelVisible = !isPanelVisible
            toolPanel.visibility = if (isPanelVisible) View.VISIBLE else View.GONE
        }

        floatingView!!.findViewById<Button>(R.id.tool_1).setOnClickListener {
            Toast.makeText(this, "Tool 1 clicked", Toast.LENGTH_SHORT).show()
        }

        floatingView!!.findViewById<Button>(R.id.tool_2).setOnClickListener {
            Toast.makeText(this, "Tool 2 clicked", Toast.LENGTH_SHORT).show()
        }

        floatingView!!.findViewById<Button>(R.id.close_button).setOnClickListener {
            stopSelf()
        }

        // Drag functionality + opacity management
        floatingView!!.setOnTouchListener(object : OnTouchListener {
            var lastX = 0
            var lastY = 0
            override fun onTouch(v: View, event: MotionEvent): Boolean {
                when (event.action) {
                    MotionEvent.ACTION_DOWN -> {
                        lastX = event.rawX.toInt()
                        lastY = event.rawY.toInt()
                        resetIdleTimer()
                        return true
                    }
                    MotionEvent.ACTION_MOVE -> {
                        val deltaX = event.rawX.toInt() - lastX
                        val deltaY = event.rawY.toInt() - lastY
                        params.x += deltaX
                        params.y += deltaY
                        windowManager?.updateViewLayout(floatingView, params)
                        lastX = event.rawX.toInt()
                        lastY = event.rawY.toInt()
                        resetIdleTimer()
                        return true
                    }
                }
                return false
            }
        })

        resetIdleTimer()
    }

    private fun resetIdleTimer() {
        floatingView?.alpha = 1.0f
        idleRunnable?.let { idleHandler.removeCallbacks(it) }
        idleRunnable = Runnable {
            floatingView?.alpha = 0.4f
        }
        idleHandler.postDelayed(idleRunnable!!, 4000)
    }

    override fun onDestroy() {
        super.onDestroy()
        floatingView?.let { windowManager?.removeView(it) }
        idleRunnable?.let { idleHandler.removeCallbacks(it) }
    }

    override fun onBind(intent: Intent?): IBinder? = null
}
