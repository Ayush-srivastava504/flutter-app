package com.ayushstudio.clipforge

import android.content.ContentValues
import android.media.MediaRecorder
import android.os.Build
import android.os.Environment
import android.os.SystemClock
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * Hosts the voice-over recorder (`lib/services/voice_recorder.dart`): a tiny
 * MethodChannel around Android's own MediaRecorder (AAC in .m4a, mono,
 * 44.1 kHz, 128 kbit/s), so the app needs no extra recording package.
 * Nothing leaves the device — the file is written to the app's own storage.
 */
class MainActivity : FlutterActivity() {
    private var recorder: MediaRecorder? = null
    private var outputPath: String? = null
    private var startedAt = 0L

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "clipforge/recorder").setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "start" -> {
                        val path = call.argument<String>("path")
                        if (path == null) {
                            result.error("bad_args", "path is required", null)
                        } else {
                            startRecording(path)
                            result.success(true)
                        }
                    }
                    "stop" -> result.success(stopRecording())
                    "cancel" -> {
                        cancelRecording()
                        result.success(null)
                    }
                    // 0..32767, peak since the previous call.
                    "amplitude" -> result.success(recorder?.maxAmplitude ?: 0)
                    else -> result.notImplemented()
                }
            } catch (e: Exception) {
                releaseRecorder()
                result.error("recorder", e.message, null)
            }
        }
        // Audio Studio: put a rendered file in the phone's Music/ClipForge folder.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "clipforge/media").setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "saveAudio" -> {
                        val path = call.argument<String>("path")!!
                        val name = call.argument<String>("name")!!
                        val mime = call.argument<String>("mime")!!
                        result.success(saveAudio(path, name, mime))
                    }
                    else -> result.notImplemented()
                }
            } catch (e: Exception) {
                result.error("media", e.message, null)
            }
        }
    }

    /** Copies [path] into Music/Cliper; returns where it went. */
    private fun saveAudio(path: String, name: String, mime: String): String {
        val src = File(path)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val values = ContentValues().apply {
                put(MediaStore.Audio.Media.DISPLAY_NAME, name)
                put(MediaStore.Audio.Media.MIME_TYPE, mime)
                put(MediaStore.Audio.Media.RELATIVE_PATH, Environment.DIRECTORY_MUSIC + "/Cliper")
                put(MediaStore.Audio.Media.IS_PENDING, 1)
            }
            val resolver = contentResolver
            val uri = resolver.insert(MediaStore.Audio.Media.EXTERNAL_CONTENT_URI, values)
                ?: throw IllegalStateException("MediaStore refused the file")
            resolver.openOutputStream(uri)!!.use { out -> src.inputStream().use { it.copyTo(out) } }
            values.clear()
            values.put(MediaStore.Audio.Media.IS_PENDING, 0)
            resolver.update(uri, values, null, null)
            return "Music/Cliper/$name"
        }
        @Suppress("DEPRECATION")
        val dir = File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_MUSIC), "Cliper")
        dir.mkdirs()
        val dest = File(dir, name)
        src.copyTo(dest, overwrite = true)
        return dest.absolutePath
    }

    private fun startRecording(path: String) {
        releaseRecorder()
        File(path).parentFile?.mkdirs()
        val r = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) MediaRecorder(this) else @Suppress("DEPRECATION") MediaRecorder()
        r.setAudioSource(MediaRecorder.AudioSource.MIC)
        r.setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)
        r.setAudioEncoder(MediaRecorder.AudioEncoder.AAC)
        r.setAudioChannels(1)
        r.setAudioSamplingRate(44100)
        r.setAudioEncodingBitRate(128000)
        r.setOutputFile(path)
        r.prepare()
        r.start()
        recorder = r
        outputPath = path
        startedAt = SystemClock.elapsedRealtime()
    }

    /** Stops and returns the length in ms (0 if nothing was recorded). */
    private fun stopRecording(): Int {
        val r = recorder ?: return 0
        val ms = (SystemClock.elapsedRealtime() - startedAt).toInt()
        try {
            r.stop()
        } catch (e: RuntimeException) {
            // stop() throws when it is called too soon after start(): no audio was written.
            releaseRecorder()
            outputPath?.let { File(it).delete() }
            return 0
        }
        releaseRecorder()
        return ms
    }

    private fun cancelRecording() {
        try {
            recorder?.stop()
        } catch (_: RuntimeException) {
        }
        releaseRecorder()
        outputPath?.let { File(it).delete() }
    }

    private fun releaseRecorder() {
        recorder?.release()
        recorder = null
    }

    override fun onDestroy() {
        cancelRecording()
        super.onDestroy()
    }
}
