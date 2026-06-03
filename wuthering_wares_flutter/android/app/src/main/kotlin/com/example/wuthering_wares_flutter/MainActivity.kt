package com.example.wuthering_wares_flutter

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.provider.OpenableColumns
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    private val channelName = "wuthering_wares/native"
    private val imageRequestCode = 4101
    private var channel: MethodChannel? = null
    private var initialLink: String? = null
    private var pendingImageResult: MethodChannel.Result? = null

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
                    "pickImage" -> {
                        if (pendingImageResult != null) {
                            result.success(null)
                        } else {
                            pendingImageResult = result
                            val picker = Intent(Intent.ACTION_GET_CONTENT).apply {
                                type = "image/*"
                                addCategory(Intent.CATEGORY_OPENABLE)
                            }
                            startActivityForResult(Intent.createChooser(picker, "Pilih gambar"), imageRequestCode)
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
                        if (key != null && value != null) prefs.edit().putString(key, value).apply()
                        result.success(null)
                    }
                    "remove" -> {
                        val key = call.arguments as? String
                        if (key != null) prefs.edit().remove(key).apply()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != imageRequestCode) return
        val result = pendingImageResult
        pendingImageResult = null
        if (resultCode != Activity.RESULT_OK || data?.data == null || result == null) {
            result?.success(null)
            return
        }
        try {
            result.success(copyToCache(data.data!!))
        } catch (_: Exception) {
            result.success(null)
        }
    }

    private fun copyToCache(uri: Uri): String {
        val mime = contentResolver.getType(uri) ?: "image/jpeg"
        val extension = when {
            mime.contains("png") -> ".png"
            mime.contains("gif") -> ".gif"
            mime.contains("webp") -> ".webp"
            else -> ".jpg"
        }
        val rawName = contentResolver.query(uri, null, null, null, null)?.use { cursor ->
            val index = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
            if (cursor.moveToFirst() && index >= 0) cursor.getString(index) else "image$extension"
        } ?: "image$extension"
        var cleanName = rawName.replace(Regex("[^A-Za-z0-9._-]"), "_")
        val allowed = Regex(".*\\.(jpg|jpeg|png|gif|webp)$", RegexOption.IGNORE_CASE)
        if (!allowed.matches(cleanName)) cleanName += extension
        val file = File(cacheDir, "picked_${System.currentTimeMillis()}_$cleanName")
        contentResolver.openInputStream(uri).use { input ->
            FileOutputStream(file).use { output -> input?.copyTo(output) }
        }
        return file.absolutePath
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        val uri = intent.dataString ?: return
        channel?.invokeMethod("deepLink", uri)
    }
}

