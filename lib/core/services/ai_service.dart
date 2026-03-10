import 'dart:async';
import 'package:flutter/services.dart';
import 'local_storage_service.dart';

abstract class AiService {
  Future<bool> isModelAvailable();
  Future<void> initialize();
  Stream<String> promptStream(String prompt);
  Future<String> prompt(String prompt);
  Future<void> reset();
}

class AndroidAiService implements AiService {
  static const _methodChannel = MethodChannel(
    'com.example.smart_buddy/llm_method',
  );
  static const _eventChannel = EventChannel(
    'com.example.smart_buddy/llm_event',
  );

  final LocalStorageService _storageService = LocalStorageService();
  final String _modelFileName =
      "gemma-1.1-2b-it-gpu-int4.bin"; // Must match ModelCubit

  @override
  Future<bool> isModelAvailable() async {
    try {
      final bool available = await _methodChannel.invokeMethod(
        'isModelAvailable',
      );
      return available;
    } catch (e) {
      print("Error checking model availability: $e");
      return false;
    }
  }

  @override
  Future<void> initialize() async {
    try {
      final isDownloaded = await _storageService.isModelDownloaded(
        _modelFileName,
      );
      if (!isDownloaded) {
        throw Exception("Model file not found. Please download it first.");
      }

      final modelPath = await _storageService.getModelPath(_modelFileName);
      print("Initializing MediaPipe LLM with model at: $modelPath");

      await _methodChannel.invokeMethod('initialize', {'modelPath': modelPath});
    } catch (e) {
      print("Error initializing AI Service: $e");
      rethrow;
    }
  }

  @override
  Future<String> prompt(String prompt) async {
    final completer = Completer<String>();
    String totalResponse = "";

    promptStream(prompt).listen(
      (chunk) => totalResponse += chunk,
      onError: (e) => completer.completeError(e),
      onDone: () => completer.complete(totalResponse),
    );

    return completer.future;
  }

  @override
  Future<void> reset() async {
    try {
      await _methodChannel.invokeMethod('reset');
    } catch (e) {
      print("Error resetting AI Service: $e");
    }
  }

  @override
  Stream<String> promptStream(String prompt) {
    // We use a StreamController to wrap the static EventChannel
    // and trigger the inference specifically for this prompt.
    final controller = StreamController<String>();

    // 1. Subscribe to the EventChannel
    final subscription = _eventChannel.receiveBroadcastStream().listen(
      (data) {
        if (!controller.isClosed) {
          controller.add(data as String);
        }
      },
      onError: (e) {
        if (!controller.isClosed) {
          controller.addError(e);
        }
      },
      onDone: () {
        if (!controller.isClosed) {
          controller.close();
        }
      },
      cancelOnError: true,
    );

    // 2. Trigger the inference via MethodChannel
    _methodChannel
        .invokeMethod('generateResponse', {'prompt': prompt})
        .catchError((e) {
          if (!controller.isClosed) {
            controller.addError(e);
          }
        });

    // When the UI stops listening, cancel the native stream too
    controller.onCancel = () {
      subscription.cancel();
    };

    return controller.stream;
  }
}
