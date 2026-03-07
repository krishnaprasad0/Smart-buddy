package com.example.smart_buddy

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel
import com.google.mediapipe.tasks.genai.llminference.LlmInference
import com.google.mediapipe.tasks.genai.llminference.ProgressListener
import java.io.File

import android.util.Log

class MainActivity : FlutterActivity() {
    private val TAG = "SmartBuddy_Llm"
    private val METHOD_CHANNEL = "com.example.smart_buddy/llm_method"
    private val EVENT_CHANNEL = "com.example.smart_buddy/llm_event"
    private var llmInference: LlmInference? = null
    private var eventSink: EventChannel.EventSink? = null
    private var isProcessing = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "initialize" -> {
                    val modelPath = call.argument<String>("modelPath")
                    Log.i(TAG, "Initializing MediaPipe LLM (Main Thread). Path: $modelPath")
                    
                    if (modelPath != null) {
                        val file = File(modelPath)
                        if (!file.exists()) {
                            Log.e(TAG, "Model file not found: $modelPath")
                            result.error("FILE_NOT_FOUND", "Model file not found", null)
                            return@setMethodCallHandler
                        }

                        try {
                            val options = LlmInference.LlmInferenceOptions.builder()
                                .setModelPath(modelPath)
                                .setMaxTokens(4096)
                                .setPreferredBackend(LlmInference.Backend.GPU)
                                .build()
                            llmInference = LlmInference.createFromOptions(context, options)
                            Log.i(TAG, "LlmInference: Init Success (GPU Enabled)")
                            result.success(true)
                        } catch (e: Exception) {
                            Log.e(TAG, "LlmInference: Init Failed: ${e.message}")
                            result.error("INIT_FAILED", e.message, null)
                        }
                    } else {
                        result.error("INVALID_ARGUMENT", "Model path is null", null)
                    }
                }
                "reset" -> {
                    try {
                        llmInference?.close()
                        llmInference = null
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("RESET_FAILED", e.message, null)
                    }
                }
                "isModelAvailable" -> {
                    result.success(llmInference != null)
                }
                "generateResponse" -> {
                    val prompt = call.argument<String>("prompt")
                    if (prompt != null && llmInference != null) {
                        if (isProcessing) {
                            Log.w(TAG, "Inference already in progress. Rejecting.")
                            result.error("BUSY", "Inference already in progress", null)
                            return@setMethodCallHandler
                        }

                        if (eventSink == null) {
                            Log.e(TAG, "EventSink is null! Stream not initialized yet.")
                            result.error("STREAM_NOT_READY", "EventChannel sink is not ready", null)
                            return@setMethodCallHandler
                        }
                        
                        isProcessing = true
                        Thread {
                            try {
                                Log.d(TAG, "Calling generateResponseAsync for: $prompt")
                                val future = llmInference?.generateResponseAsync(prompt) { partialResult: String?, done: Boolean ->
                                    runOnUiThread {
                                        if (!partialResult.isNullOrBlank()) {
                                            eventSink?.success(partialResult)
                                        }
                                        if (done) {
                                            Log.d(TAG, "Inference Stream Done")
                                            isProcessing = false
                                            eventSink?.endOfStream()
                                        }
                                    }
                                }
                                
                                future?.addListener({
                                    try {
                                        future.get()
                                    } catch (e: Exception) {
                                        Log.e(TAG, "Inference Future Error: ${e.message}")
                                        runOnUiThread {
                                            isProcessing = false
                                            eventSink?.error("INFERENCE_ERROR", e.message ?: "Unknown native error", null)
                                            eventSink?.endOfStream()
                                        }
                                    }
                                }, { it.run() })

                            } catch (e: Exception) {
                                Log.e(TAG, "Inference Error: ${e.message}")
                                runOnUiThread { 
                                    isProcessing = false
                                    eventSink?.error("INFERENCE_ERROR", e.message, null)
                                    eventSink?.endOfStream()
                                }
                            }
                        }.start()
                        result.success(null)
                    } else {
                        result.error("NOT_READY", "Prompt is null or model not initialized", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, sink: EventChannel.EventSink?) {
                    Log.d(TAG, "EventChannel: onListen")
                    eventSink = sink
                }

                override fun onCancel(arguments: Any?) {
                    Log.d(TAG, "EventChannel: onCancel")
                    eventSink = null
                }
            }
        )
    }
}
