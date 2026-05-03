package com.example.tp0_n

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

class MainActivity : FlutterActivity() {

    private val CHANNEL = "music_service"
    private val EVENT_CHANNEL = "music_state"
    private val activityScope = CoroutineScope(Dispatchers.Main)

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->

                when (call.method) {

                    "play" -> {
                        val index = call.argument<Int>("index") ?: 0

                        val intent = Intent(this, MusicService::class.java)
                        intent.action = MusicService.ACTION_PLAY
                        intent.putExtra("index", index)

                        startMusicService(intent)
                        result.success(null)
                    }

                    "pause" -> {
                        val intent = Intent(this, MusicService::class.java)
                        intent.action = MusicService.ACTION_PAUSE

                        startMusicService(intent)
                        result.success(null)
                    }

                    "next" -> {
                        val intent = Intent(this, MusicService::class.java)
                        intent.action = MusicService.ACTION_NEXT

                        startMusicService(intent)
                        result.success(null)
                    }

                    "previous" -> {
                        val intent = Intent(this, MusicService::class.java)
                        intent.action = MusicService.ACTION_PREVIOUS

                        startMusicService(intent)
                        result.success(null)
                    }

                    "getSongs" -> {
                        activityScope.launch {
                            try {
                                val songs = MusicService.getSongs(this@MainActivity)
                                result.success(songs)
                            } catch (e: Exception) {
                                result.error("GET_SONGS_ERROR", e.message, null)
                            }
                        }
                    }

                    "seekTo" -> {
                        val position = call.argument<Int>("position") ?: 0

                        val intent = Intent(this, MusicService::class.java)
                        intent.action = MusicService.ACTION_SEEK
                        intent.putExtra("position", position)

                        startMusicService(intent)
                        result.success(null)
                    }

                    else -> result.notImplemented()
                }
            }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                private var receiver: BroadcastReceiver? = null

                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    receiver = object : BroadcastReceiver() {
                        override fun onReceive(context: Context?, intent: Intent?) {
                            val data = mapOf(
                                "state" to (intent?.getStringExtra("state") ?: ""),
                                "index" to (intent?.getIntExtra("index", 0) ?: 0),
                                "position" to (intent?.getIntExtra("position", 0) ?: 0),
                                "duration" to (intent?.getIntExtra("duration", 0) ?: 0)
                            )
                            events?.success(data)
                        }
                    }

                    val filter = IntentFilter(EVENT_CHANNEL)
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        registerReceiver(receiver, filter, Context.RECEIVER_NOT_EXPORTED)
                    } else {
                        registerReceiver(receiver, filter)
                    }
                }

                override fun onCancel(arguments: Any?) {
                    receiver?.let { unregisterReceiver(it) }
                    receiver = null
                }
            })
    }

    private fun startMusicService(intent: Intent) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
    }
}
