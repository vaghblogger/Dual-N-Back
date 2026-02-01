package com.yourcompany.nback_pro

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.yourcompany.nback_pro/auth"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getDefaultWebClientId") {
                val id = resources.getIdentifier("default_web_client_id", "string", packageName)
                if (id != 0) {
                    result.success(resources.getString(id))
                } else {
                    result.success(null)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}
