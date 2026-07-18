package com.saisurya.moneymanager

import android.content.Intent
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterFragmentActivity() {
    private val CHANNEL = "com.saisurya.moneymanager/widget_actions"
    private var initialAction: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.setFlags(WindowManager.LayoutParams.FLAG_SECURE, WindowManager.LayoutParams.FLAG_SECURE)
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
        
        // If the app is already running, send the action immediately to Flutter
        flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
            initialAction?.let { action ->
                MethodChannel(messenger, CHANNEL).invokeMethod("onWidgetAction", action)
                initialAction = null // Clear after sending
            }
        }
    }

    private fun handleIntent(intent: Intent?) {
        if (intent != null && intent.hasExtra("action_type")) {
            initialAction = intent.getStringExtra("action_type")
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getWidgetAction") {
                result.success(initialAction)
                initialAction = null // Consume the action
            } else {
                result.notImplemented()
            }
        }
    }
}
