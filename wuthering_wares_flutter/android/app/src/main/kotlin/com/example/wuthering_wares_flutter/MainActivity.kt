package com.example.wuthering_wares_flutter

import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "wuthering_wares/native"
    private var channel: MethodChannel? = null
    private var initialLink: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        initialLink = intent?.dataString
        val prefs = getSharedPreferences("auth", MODE_PRIVATE)

        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).also { methodChannel ->
            methodChannel.setMethodCallHandler { call, result ->
                when (call.method) {
                    "initialLink" -> result.success(initialLink)
                    "openUrl" -> {
                        val url = call.arguments as? String
                        if (url.isNullOrBlank()) {
                            result.success(false)
                        } else {
                            try {
                                startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(url)))
                                result.success(true)
                            } catch (_: Exception) {
                                result.success(false)
                            }
                        }
                    }
                    "getString" -> {
                        val key = call.arguments as? String
                        result.success(if (key == null) null else prefs.getString(key, null))
                    }
                    "setString" -> {
                        val args = call.arguments as? Map<*, *>
                        val key = args?.get("key") as? String
                        val value = args?.get("value") as? String
                        if (key != null && value != null) {
                            prefs.edit().putString(key, value).apply()
                        }
                        result.success(null)
                    }
                    "remove" -> {
                        val key = call.arguments as? String
                        if (key != null) {
                            prefs.edit().remove(key).apply()
                        }
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        val uri = intent.dataString ?: return
        channel?.invokeMethod("deepLink", uri)
    }
}
