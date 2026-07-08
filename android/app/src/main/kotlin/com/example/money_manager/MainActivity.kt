package com.example.money_manager

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.google.adk.kt.runners.InMemoryRunner
import com.google.adk.kt.sessions.InMemorySessionService
import com.google.adk.kt.types.Content
import com.google.adk.kt.types.Part
import com.google.adk.kt.types.Role
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

class MainActivity: FlutterFragmentActivity() {
    private val CHANNEL = "com.example.money_manager/widget_actions"
    private val AGENT_CHANNEL = "com.example.money_manager/agent"
    private var initialAction: String? = null
    
    private val sessionService = InMemorySessionService()
    private val runner = InMemoryRunner(
        agent = FinanceAgent.rootAgent,
        sessionService = sessionService,
    )
    private val agentScope = CoroutineScope(Dispatchers.IO)

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
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

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, AGENT_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "sendMessage") {
                val prompt = call.arguments as? String
                if (prompt != null) {
                    agentScope.launch {
                        try {
                            var fullResponse = ""
                            runner.runAsync(
                                userId = "user-123",
                                sessionId = "session-123",
                                newMessage = Content(
                                    role = Role.USER,
                                    parts = listOf(Part(text = prompt)),
                                )
                            ).collect { event ->
                                val text = event.content?.parts?.firstOrNull()?.text
                                if (!text.isNullOrBlank()) {
                                    fullResponse += text
                                }
                            }
                            launch(Dispatchers.Main) {
                                result.success(fullResponse)
                            }
                        } catch (e: Exception) {
                            launch(Dispatchers.Main) {
                                result.error("AGENT_ERROR", e.message, null)
                            }
                        }
                    }
                } else {
                    result.error("INVALID_ARGUMENT", "Prompt must be a string", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}
