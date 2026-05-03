package com.example.tp0_n

import android.app.*
import android.content.Intent
import android.media.MediaPlayer
import android.os.IBinder
import androidx.core.app.NotificationCompat

class MusicService : Service() {

    private var player: MediaPlayer? = null

    private val songs = listOf(
        R.raw.song1,
        R.raw.song2
    )

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {

        createNotificationChannel()

        val index = intent?.getIntExtra("index", 0) ?: 0

        when (intent?.action) {
            "PLAY" -> playMusic(index)
            "PAUSE" -> pauseMusic()
        }

        return START_STICKY
    }

    private fun playMusic(index: Int) {

        if (player != null) {
            player!!.release()
        }

        player = MediaPlayer.create(this, songs[index])
        player!!.isLooping = true
        player!!.start()

        sendState("PLAY")

        startForeground(1, buildNotification("Playing 🎵"))
    }

    private fun pauseMusic() {
        player?.pause()
        sendState("PAUSE")

        startForeground(1, buildNotification("Paused ⏸"))
    }

    private fun sendState(state: String) {
        val intent = Intent("music_state")
        intent.putExtra("state", state)
        sendBroadcast(intent)
    }

    private fun buildNotification(text: String): Notification {

        val playIntent = Intent(this, MusicService::class.java).apply {
            action = "PLAY"
        }

        val pauseIntent = Intent(this, MusicService::class.java).apply {
            action = "PAUSE"
        }

        return NotificationCompat.Builder(this, "music_channel")
            .setContentTitle("Music Player")
            .setContentText(text)
            .setSmallIcon(android.R.drawable.ic_media_play)
            .setOngoing(true)

            .addAction(
                android.R.drawable.ic_media_play,
                "Play",
                PendingIntent.getService(this, 1, playIntent, PendingIntent.FLAG_IMMUTABLE)
            )

            .addAction(
                android.R.drawable.ic_media_pause,
                "Pause",
                PendingIntent.getService(this, 2, pauseIntent, PendingIntent.FLAG_IMMUTABLE)
            )

            .build()
    }

    private fun createNotificationChannel() {
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {

            val channel = NotificationChannel(
                "music_channel",
                "Music Player",
                NotificationManager.IMPORTANCE_LOW
            )

            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }
}