package com.example.learningflutter

import android.app.Service
import android.content.Context
import android.content.Intent
import android.graphics.PixelFormat
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.provider.Settings
import android.view.*
import android.view.animation.DecelerateInterpolator
import android.widget.*
import androidx.core.content.getSystemService

class FloatingWidgetService : Service() {
    private var wm: WindowManager? = null
    private lateinit var floatingView: View
    private lateinit var params: WindowManager.LayoutParams
    private val handler = Handler(Looper.getMainLooper())
    private var idleRunnable: Runnable? = null
    private var isToolOpen = false

    override fun onCreate() {
        super.onCreate()
        wm = getSystemService(Context.WINDOW_SERVICE) as WindowManager
        floatingView = LayoutInflater.from(this).inflate(R.layout.floating_widget, null)

        val layoutFlag = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        else WindowManager.LayoutParams.TYPE_PHONE

        params = WindowManager.LayoutParams(
            WRAP_CONTENT, WRAP_CONTENT,
            layoutFlag, WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.TOP or Gravity.START
            x = 200; y = 300
        }

        wm?.addView(floatingView, params)

        setupInteractions()
        scheduleIdleFade()
    }

    private fun setupInteractions() {
        val icon = floatingView.findViewById<ImageView>(R.id.floating_icon)
        val toolPanel = floatingView.findViewById<LinearLayout>(R.id.tools_panel)
        val clipboardBtn = floatingView.findViewById<Button>(R.id.tool_clipboard)
        val brightnessBtn = floatingView.findViewById<Button>(R.id.tool_brightness)
        val closeBtn = floatingView.findViewById<Button>(R.id.close_button)

        // Clipboard history tool
        clipboardBtn.setOnClickListener {
            val cb = getSystemService<ClipboardManager>()
            val txt = cb?.primaryClip?.getItemAt(0)?.text ?: "Nothing copied"
            Toast.makeText(this, txt, Toast.LENGTH_SHORT).show()
        }

        // Toggle brightness tool
        brightnessBtn.setOnClickListener {
            try {
                val sb = Settings.System.getInt(contentResolver, Settings.System.SCREEN_BRIGHTNESS)
                val mode = if (sb < 128) 255 else 64
                Settings.System.putInt(contentResolver, Settings.System.SCREEN_BRIGHTNESS, mode)
                Toast.makeText(this, "Brightness set to $mode", Toast.LENGTH_SHORT).show()
            } catch (_: Exception) {
                Toast.makeText(this, "Cannot change brightness", Toast.LENGTH_SHORT).show()
            }
        }

        closeBtn.setOnClickListener { stopSelf() }

        icon.setOnClickListener {
            isToolOpen = !isToolOpen
            val targetVis = if (isToolOpen) View.VISIBLE else View.GONE
            toolPanel.animate()
                .alpha(if (isToolOpen) 1f else 0f)
                .setDuration(300)
                .withStartAction { toolPanel.visibility = View.VISIBLE }
                .withEndAction { if (!isToolOpen) toolPanel.visibility = View.GONE }
                .start()
        }

        icon.setOnTouchListener(object : View.OnTouchListener {
            var lastX = 0
            var lastY = 0
            var dragging = false

            override fun onTouch(v: View, e: MotionEvent): Boolean {
                when (e.action) {
                    MotionEvent.ACTION_DOWN -> {
                        handler.removeCallbacks(idleRunnable!!)
                        lastX = e.rawX.toInt()
                        lastY = e.rawY.toInt()
                        dragging = false
                    }
                    MotionEvent.ACTION_MOVE -> {
                        val dx = e.rawX.toInt() - lastX
                        val dy = e.rawY.toInt() - lastY
                        if (dx != 0 || dy != 0) dragging = true
                        params.x += dx; params.y += dy
                        wm?.updateViewLayout(floatingView, params)
                        lastX = e.rawX.toInt(); lastY = e.rawY.toInt()
                    }
                    MotionEvent.ACTION_UP -> {
                        if (!dragging) return v.performClick()
                        snapToEdge()
                        scheduleIdleFade()
                    }
                }
                return true
            }
        })
    }

    private fun scheduleIdleFade() {
        floatingView.alpha = 1f
        idleRunnable?.let { handler.removeCallbacks(it) }
        idleRunnable = Runnable { floatingView.alpha = 0.4f }
        handler.postDelayed(idleRunnable!!, 3000)
    }

    private fun snapToEdge() {
        val display = wm!!.defaultDisplay
        val size = Point().apply { display.getSize(this) }
        val targetX = if (params.x + 60 > size.x / 2) size.x - 60 else 0
        ValueAnimator.ofInt(params.x, targetX).apply {
            duration = 300
            interpolator = DecelerateInterpolator()
            addUpdateListener {
                params.x = it.animatedValue as Int
                wm?.updateViewLayout(floatingView, params)
            }
        }.start()
    }

    override fun onDestroy() {
        super.onDestroy()
        idleRunnable?.let { handler.removeCallbacks(it) }
        wm?.removeView(floatingView)
    }

    override fun onBind(intent: Intent?): IBinder? = null
}
