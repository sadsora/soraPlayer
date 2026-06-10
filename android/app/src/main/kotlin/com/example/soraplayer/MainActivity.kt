package com.example.soraplayer

import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setMaxRefreshRate()
    }

    private fun setMaxRefreshRate() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            val modes = display?.supportedModes ?: return
            if (modes.isEmpty()) return
            val bestMode = modes.maxByOrNull { it.refreshRate } ?: return
            window.attributes = window.attributes.apply {
                preferredDisplayModeId = bestMode.modeId
            }
        }
    }
}
