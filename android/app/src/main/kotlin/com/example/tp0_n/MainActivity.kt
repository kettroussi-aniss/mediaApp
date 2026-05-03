package com.example.tp0_n

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent

class MainActivity : FlutterActivity() {

    private val CHANNEL = "music_service"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->

                when (call.method) {

                    "play" -> {
                        val index = call.argument<Int>("index") ?: 0

                        val intent = Intent(this, MusicService::class.java)
                        intent.action = "PLAY"
                        intent.putExtra("index", index)

                        startForegroundService(intent)
                        result.success(null)
                    }

                    "pause" -> {
                        val intent = Intent(this, MusicService::class.java)
                        intent.action = "PAUSE"

                        startForegroundService(intent)
                        result.success(null)
                    }

                    else -> result.notImplemented()
                }
            }
    }
}