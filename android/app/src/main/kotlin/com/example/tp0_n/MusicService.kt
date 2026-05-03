package com.example.tp0_n

import android.app.*
import android.content.ContentUris
import android.content.Context
import android.content.Intent
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.media.MediaPlayer
import android.net.Uri
import android.os.Build
import android.os.IBinder
import android.provider.MediaStore
import androidx.core.app.NotificationCompat
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlin.math.sqrt

class MusicService : Service(), SensorEventListener {

    private var player: MediaPlayer? = null
    private var currentIndex = 0
    private var isPlaying = false
    private var sensorManager: SensorManager? = null
    private var lastShakeTime = 0L

    private val shakeThreshold = 12f
    private val shakeDebounceMs = 1000L

    private val songs = listOf(
        R.raw.song1,
        R.raw.song2
    )

    companion object {
        const val ACTION_PLAY = "PLAY"
        const val ACTION_PAUSE = "PAUSE"
        const val ACTION_NEXT = "NEXT"
        const val ACTION_PREVIOUS = "PREVIOUS"

        private const val CHANNEL_ID = "music_channel"
        private const val NOTIFICATION_ID = 1

        data class SongInfo(
            val name: String,
            val uri: String
        )

        private var phoneSongs: List<SongInfo> = emptyList()

        suspend fun getSongs(context: Context): List<String> = withContext(Dispatchers.IO) {
            val audioUri: Uri =
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    MediaStore.Audio.Media.getContentUri(MediaStore.VOLUME_EXTERNAL)
                } else {
                    MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
                }

            val projection = arrayOf(
                MediaStore.Audio.Media._ID,
                MediaStore.Audio.Media.DISPLAY_NAME
            )

            val selection =
                "${MediaStore.Audio.Media.IS_MUSIC} != 0 AND ${MediaStore.Audio.Media.MIME_TYPE} = ?"
            val selectionArgs = arrayOf("audio/mpeg")
            val sortOrder = "${MediaStore.Audio.Media.DISPLAY_NAME} ASC"
            val scannedSongs = mutableListOf<SongInfo>()

            val cursor = context.contentResolver.query(
                audioUri,
                projection,
                selection,
                selectionArgs,
                sortOrder
            )

            cursor?.use {
                val idColumn = it.getColumnIndexOrThrow(MediaStore.Audio.Media._ID)
                val nameColumn = it.getColumnIndexOrThrow(MediaStore.Audio.Media.DISPLAY_NAME)

                while (it.moveToNext()) {
                    val id = it.getLong(idColumn)
                    val name = it.getString(nameColumn) ?: "Unknown.mp3"
                    val uri = ContentUris.withAppendedId(audioUri, id).toString()

                    scannedSongs.add(SongInfo(name, uri))
                }
            }

            phoneSongs = scannedSongs
            scannedSongs.map { it.name }
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        registerShakeDetector()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {

        val index = intent?.getIntExtra("index", currentIndex) ?: currentIndex

        when (intent?.action) {
            ACTION_PLAY -> playMusic(index)
            ACTION_PAUSE -> pauseMusic()
            ACTION_NEXT -> nextMusic()
            ACTION_PREVIOUS -> previousMusic()
        }

        return START_STICKY
    }

    private fun playMusic(index: Int) {
        val totalSongs = if (phoneSongs.isNotEmpty()) phoneSongs.size else songs.size
        if (totalSongs == 0) return

        currentIndex = index.coerceIn(0, totalSongs - 1)

        if (player != null) {
            player!!.release()
        }

        player = if (phoneSongs.isNotEmpty()) {
            MediaPlayer().apply {
                setDataSource(this@MusicService, Uri.parse(phoneSongs[currentIndex].uri))
                isLooping = true
                prepare()
            }
        } else {
            MediaPlayer.create(this, songs[currentIndex]).apply {
                isLooping = true
            }
        }

        player?.start()
        isPlaying = true

        sendState("PLAY")

        startForeground(NOTIFICATION_ID, buildNotification("Playing"))
    }

    private fun pauseMusic() {
        player?.pause()
        isPlaying = false
        sendState("PAUSE")

        startForeground(NOTIFICATION_ID, buildNotification("Paused"))
    }

    private fun nextMusic() {
        val totalSongs = if (phoneSongs.isNotEmpty()) phoneSongs.size else songs.size
        if (totalSongs == 0) return
        playMusic((currentIndex + 1) % totalSongs)
    }

    private fun previousMusic() {
        val totalSongs = if (phoneSongs.isNotEmpty()) phoneSongs.size else songs.size
        if (totalSongs == 0) return
        playMusic((currentIndex - 1 + totalSongs) % totalSongs)
    }

    private fun sendState(state: String) {
        val intent = Intent("music_state")
        intent.putExtra("state", state)
        intent.putExtra("index", currentIndex)
        sendBroadcast(intent)
    }

    private fun buildNotification(text: String): Notification {

        val playIntent = Intent(this, MusicService::class.java).apply {
            action = ACTION_PLAY
            putExtra("index", currentIndex)
        }

        val pauseIntent = Intent(this, MusicService::class.java).apply {
            action = ACTION_PAUSE
        }

        val nextIntent = Intent(this, MusicService::class.java).apply {
            action = ACTION_NEXT
        }

        val previousIntent = Intent(this, MusicService::class.java).apply {
            action = ACTION_PREVIOUS
        }
        val pendingIntentFlags = PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Music Player")
            .setContentText(text)
            .setSmallIcon(android.R.drawable.ic_media_play)
            .setOngoing(true)
            .setOnlyAlertOnce(true)

            .addAction(
                android.R.drawable.ic_media_previous,
                "Previous",
                PendingIntent.getService(this, 3, previousIntent, pendingIntentFlags)
            )

            .addAction(
                if (isPlaying) android.R.drawable.ic_media_pause else android.R.drawable.ic_media_play,
                if (isPlaying) "Pause" else "Play",
                PendingIntent.getService(
                    this,
                    1,
                    if (isPlaying) pauseIntent else playIntent,
                    pendingIntentFlags
                )
            )

            .addAction(
                android.R.drawable.ic_media_next,
                "Next",
                PendingIntent.getService(this, 2, nextIntent, pendingIntentFlags)
            )

            .build()
    }

    private fun createNotificationChannel() {
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {

            val channel = NotificationChannel(
                CHANNEL_ID,
                "Music Player",
                NotificationManager.IMPORTANCE_LOW
            )

            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }

    private fun registerShakeDetector() {
        sensorManager = getSystemService(SENSOR_SERVICE) as SensorManager
        val accelerometer = sensorManager?.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)
        if (accelerometer != null) {
            sensorManager?.registerListener(this, accelerometer, SensorManager.SENSOR_DELAY_NORMAL)
        }
    }

    override fun onSensorChanged(event: SensorEvent?) {
        if (event?.sensor?.type != Sensor.TYPE_ACCELEROMETER) return

        val x = event.values[0]
        val y = event.values[1]
        val z = event.values[2]
        val acceleration = sqrt(x * x + y * y + z * z)
        val now = System.currentTimeMillis()

        if (acceleration > shakeThreshold && now - lastShakeTime > shakeDebounceMs) {
            lastShakeTime = now

            if (isPlaying) {
                pauseMusic()
            } else {
                playMusic(currentIndex)
            }
        }
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) = Unit

    override fun onDestroy() {
        sensorManager?.unregisterListener(this)
        player?.release()
        player = null
        super.onDestroy()
    }
}
