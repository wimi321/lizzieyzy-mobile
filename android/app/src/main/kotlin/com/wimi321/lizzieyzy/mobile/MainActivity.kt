package com.wimi321.lizzieyzy.mobile

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.CancellationSignal
import android.os.Handler
import android.os.Looper
import android.provider.OpenableColumns
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.io.Closeable
import java.io.File
import java.io.FileInputStream
import java.io.InputStream
import java.util.ArrayDeque
import java.util.Locale
import java.util.concurrent.ArrayBlockingQueue
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.Executors
import java.util.concurrent.Future
import java.util.concurrent.RejectedExecutionException
import java.util.concurrent.ThreadPoolExecutor
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.atomic.AtomicReference

class MainActivity : FlutterActivity(), EventChannel.StreamHandler {
    companion object {
        private const val METHOD_CHANNEL =
            "com.wimi321.lizzieyzy.mobile/inbound_kifu/methods"
        private const val EVENT_CHANNEL =
            "com.wimi321.lizzieyzy.mobile/inbound_kifu/events"
        private const val TAKE_INITIAL_METHOD = "takeInitialKifu"
        private const val MAX_INPUT_BYTES = 16 * 1024 * 1024
        private const val MAX_FILE_NAME_CHARACTERS = 255
        private const val MAX_PENDING_RUNTIME_BYTES = MAX_INPUT_BYTES
        private const val MAX_PENDING_RUNTIME_EVENTS = 8
        private const val READ_TIMEOUT_SECONDS = 10L
        private const val IO_WORKERS = 2
        private const val MAX_QUEUED_READS = 4
        private const val NATIVE_READ_ERROR = "unreadable"
    }

    private data class InboundPayload(
        val name: String?,
        val bytes: ByteArray?,
        val action: String?,
        val error: String?,
    ) {
        val byteCount: Int get() = bytes?.size ?: 0

        fun toChannelValue(): Map<String, Any> =
            if (error != null) {
                mapOf("error" to error)
            } else {
                mapOf(
                    "name" to checkNotNull(name),
                    "bytes" to checkNotNull(bytes),
                    "action" to checkNotNull(action),
                )
            }

        companion object {
            fun success(name: String, bytes: ByteArray, action: String) =
                InboundPayload(name, bytes, action, null)

            fun failure() = InboundPayload(null, null, null, NATIVE_READ_ERROR)
        }
    }

    private class ReadCancellation : Closeable {
        val providerSignal = CancellationSignal()
        private val activeInput = AtomicReference<Closeable?>()
        private val cancelled = AtomicBoolean(false)

        fun track(input: Closeable): Boolean {
            if (cancelled.get()) {
                runCatching { input.close() }
                return false
            }
            activeInput.set(input)
            if (cancelled.get()) {
                activeInput.getAndSet(null)?.let { runCatching { it.close() } }
                return false
            }
            return true
        }

        fun untrack(input: Closeable) {
            activeInput.compareAndSet(input, null)
        }

        override fun close() {
            if (!cancelled.compareAndSet(false, true)) return
            providerSignal.cancel()
            activeInput.getAndSet(null)?.let { runCatching { it.close() } }
        }
    }

    private data class ContentMetadata(val name: String?, val size: Long?)

    private val ioExecutor = ThreadPoolExecutor(
        IO_WORKERS,
        IO_WORKERS,
        0L,
        TimeUnit.MILLISECONDS,
        ArrayBlockingQueue(MAX_QUEUED_READS),
        ThreadPoolExecutor.AbortPolicy(),
    )
    private val timeoutExecutor = Executors.newSingleThreadScheduledExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())
    private val initialLock = Any()
    private var initialScheduled = false
    private var initialTakeCalled = false
    private var initialPayload: InboundPayload? = null
    private var methodChannel: MethodChannel? = null
    private var eventChannel: EventChannel? = null
    private var eventSink: EventChannel.EventSink? = null
    private val pendingRuntime = ArrayDeque<InboundPayload>()
    private var pendingRuntimeBytes = 0
    private val activeCancellations = ConcurrentHashMap.newKeySet<ReadCancellation>()
    @Volatile private var destroyed = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        methodChannel = MethodChannel(messenger, METHOD_CHANNEL).also { channel ->
            channel.setMethodCallHandler { call, result ->
                if (call.method != TAKE_INITIAL_METHOD) {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                takeInitial(result)
            }
        }
        eventChannel = EventChannel(messenger, EVENT_CHANNEL).also { channel ->
            channel.setStreamHandler(this)
        }
        val shouldScheduleInitial = synchronized(initialLock) {
            if (!initialScheduled) {
                initialScheduled = true
                true
            } else {
                false
            }
        }
        if (shouldScheduleInitial) scheduleRead(intent, initial = true)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        scheduleRead(intent, initial = false)
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        eventSink = events
        while (pendingRuntime.isNotEmpty()) {
            val payload = pendingRuntime.removeFirst()
            pendingRuntimeBytes -= payload.byteCount
            events.success(payload.toChannelValue())
        }
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    override fun onDestroy() {
        methodChannel?.setMethodCallHandler(null)
        eventChannel?.setStreamHandler(null)
        eventSink = null
        pendingRuntime.clear()
        pendingRuntimeBytes = 0
        destroyed = true
        activeCancellations.forEach(ReadCancellation::close)
        activeCancellations.clear()
        ioExecutor.shutdownNow()
        timeoutExecutor.shutdownNow()
        super.onDestroy()
    }

    private fun takeInitial(result: MethodChannel.Result) {
        val payload = synchronized(initialLock) {
            initialTakeCalled = true
            val current = initialPayload
            initialPayload = null
            current
        }
        result.success(payload?.toChannelValue())
    }

    private fun scheduleRead(intent: Intent?, initial: Boolean) {
        if (destroyed || inboundAction(intent) == null) return
        val cancellation = ReadCancellation()
        val completed = AtomicBoolean(false)
        activeCancellations.add(cancellation)
        lateinit var future: Future<*>
        try {
            future = ioExecutor.submit {
                val payload = readIntent(intent, cancellation)
                activeCancellations.remove(cancellation)
                if (completed.compareAndSet(false, true)) {
                    postReadResult(payload, initial)
                }
            }
        } catch (_: RejectedExecutionException) {
            activeCancellations.remove(cancellation)
            cancellation.close()
            postReadResult(InboundPayload.failure(), initial)
            return
        }
        timeoutExecutor.schedule(
            {
                if (completed.compareAndSet(false, true)) {
                    activeCancellations.remove(cancellation)
                    cancellation.close()
                    future.cancel(true)
                    postReadResult(InboundPayload.failure(), initial)
                }
            },
            READ_TIMEOUT_SECONDS,
            TimeUnit.SECONDS,
        )
    }

    private fun postReadResult(payload: InboundPayload?, initial: Boolean) {
        if (destroyed) return
        mainHandler.post {
            if (destroyed || payload == null) return@post
            if (!initial) {
                deliverRuntime(payload)
                return@post
            }
            val deliverAsRuntime = synchronized(initialLock) {
                if (initialTakeCalled) {
                    true
                } else {
                    initialPayload = payload
                    false
                }
            }
            if (deliverAsRuntime) deliverRuntime(payload)
        }
    }

    private fun deliverRuntime(payload: InboundPayload) {
        val sink = eventSink
        if (sink != null) {
            sink.success(payload.toChannelValue())
            return
        }
        while (
            pendingRuntime.isNotEmpty() &&
            (pendingRuntime.size >= MAX_PENDING_RUNTIME_EVENTS ||
                pendingRuntimeBytes + payload.byteCount > MAX_PENDING_RUNTIME_BYTES)
        ) {
            pendingRuntimeBytes -= pendingRuntime.removeFirst().byteCount
        }
        if (payload.byteCount <= MAX_PENDING_RUNTIME_BYTES) {
            pendingRuntime.addLast(payload)
            pendingRuntimeBytes += payload.byteCount
        }
    }

    private fun inboundAction(intent: Intent?): String? =
        when (intent?.action) {
            Intent.ACTION_VIEW -> "view"
            Intent.ACTION_SEND -> "send"
            else -> null
        }

    private fun readIntent(
        intent: Intent?,
        cancellation: ReadCancellation,
    ): InboundPayload? {
        val safeIntent = intent ?: return null
        val action = inboundAction(safeIntent) ?: return null
        val uri = when (safeIntent.action) {
            Intent.ACTION_VIEW -> safeIntent.data
            Intent.ACTION_SEND -> streamUri(safeIntent) ?: safeIntent.clipData?.let { clipData ->
                if (clipData.itemCount == 1) clipData.getItemAt(0).uri else null
            }
            else -> null
        } ?: return InboundPayload.failure()
        return readUri(uri, action, cancellation) ?: InboundPayload.failure()
    }

    @Suppress("DEPRECATION")
    private fun streamUri(intent: Intent): Uri? =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            intent.getParcelableExtra(Intent.EXTRA_STREAM, Uri::class.java)
        } else {
            intent.getParcelableExtra(Intent.EXTRA_STREAM)
        }

    private fun readUri(
        uri: Uri,
        action: String,
        cancellation: ReadCancellation,
    ): InboundPayload? {
        val scheme = uri.scheme?.lowercase(Locale.ROOT) ?: return null
        if (scheme != "content" && scheme != "file") return null

        val metadata = if (scheme == "content") {
            queryMetadata(uri, cancellation)
        } else {
            null
        }
        val file = if (scheme == "file") {
            val path = uri.path ?: return null
            runCatching { File(path).canonicalFile }.getOrNull()?.takeIf { it.isFile }
                ?: return null
        } else {
            null
        }
        val candidateName = metadata?.name ?: file?.name ?: uri.lastPathSegment ?: return null
        val safeName = validateFileName(candidateName) ?: return null
        val declaredSize = metadata?.size ?: file?.length()
        if (declaredSize != null && (declaredSize <= 0 || declaredSize > MAX_INPUT_BYTES)) {
            return null
        }

        val bytes = when (scheme) {
            "content" -> runCatching {
                contentResolver.openAssetFileDescriptor(
                    uri,
                    "r",
                    cancellation.providerSignal,
                )?.use { descriptor ->
                    descriptor.createInputStream().use inputUse@{ input ->
                        if (!cancellation.track(input)) return@inputUse null
                        try {
                            readBounded(input, declaredSize)
                        } finally {
                            cancellation.untrack(input)
                        }
                    }
                }
            }.getOrNull()
            "file" -> runCatching {
                FileInputStream(file!!).use inputUse@{ input ->
                    if (!cancellation.track(input)) return@inputUse null
                    try {
                        readBounded(input, declaredSize)
                    } finally {
                        cancellation.untrack(input)
                    }
                }
            }.getOrNull()
            else -> null
        } ?: return null
        if (bytes.isEmpty()) return null

        return InboundPayload.success(name = safeName, bytes = bytes, action = action)
    }

    private fun queryMetadata(
        uri: Uri,
        cancellation: ReadCancellation,
    ): ContentMetadata? = runCatching {
        contentResolver.query(
            uri,
            arrayOf(OpenableColumns.DISPLAY_NAME, OpenableColumns.SIZE),
            null,
            null,
            null,
            cancellation.providerSignal,
        )?.use { cursor ->
            if (!cursor.moveToFirst()) return@use null
            val nameIndex = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
            val sizeIndex = cursor.getColumnIndex(OpenableColumns.SIZE)
            val name = if (nameIndex >= 0 && !cursor.isNull(nameIndex)) {
                cursor.getString(nameIndex)
            } else {
                null
            }
            val size = if (sizeIndex >= 0 && !cursor.isNull(sizeIndex)) {
                cursor.getLong(sizeIndex).takeIf { it >= 0 }
            } else {
                null
            }
            ContentMetadata(name = name, size = size)
        }
    }.getOrNull()

    private fun validateFileName(candidate: String): String? {
        if (
            candidate.isEmpty() ||
            candidate.length > MAX_FILE_NAME_CHARACTERS ||
            candidate == "." ||
            candidate == ".." ||
            candidate.contains('/') ||
            candidate.contains('\\') ||
            candidate.any { it.code < 0x20 }
        ) {
            return null
        }
        val extension = candidate.substringAfterLast('.', "").lowercase(Locale.ROOT)
        if (extension != "sgf" && extension != "gib") return null
        return candidate
    }

    private fun readBounded(input: InputStream, declaredSize: Long?): ByteArray? {
        if (declaredSize != null && (declaredSize <= 0 || declaredSize > MAX_INPUT_BYTES)) {
            return null
        }
        val initialCapacity = declaredSize
            ?.coerceAtMost(MAX_INPUT_BYTES.toLong())
            ?.toInt()
            ?: 8192
        val output = ByteArrayOutputStream(initialCapacity)
        val buffer = ByteArray(8192)
        var total = 0
        while (true) {
            if (Thread.currentThread().isInterrupted) return null
            val count = input.read(buffer)
            if (count < 0) break
            if (count == 0) {
                val single = input.read()
                if (single < 0) break
                if (total + 1 > MAX_INPUT_BYTES) return null
                output.write(single)
                total++
                continue
            }
            if (total + count > MAX_INPUT_BYTES) return null
            output.write(buffer, 0, count)
            total += count
        }
        return output.toByteArray()
    }

}
