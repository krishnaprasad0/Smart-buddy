import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

class VoiceService {
  static final VoiceService _instance = VoiceService._internal();
  factory VoiceService() => _instance;
  VoiceService._internal();

  final FlutterTts _tts = FlutterTts();
  final SpeechToText _stt = SpeechToText();

  final ValueNotifier<String?> currentPlayingText = ValueNotifier<String?>(
    null,
  );

  bool _isSttInitialized = false;

  Future<void> init() async {
    // Initialize TTS
    await _tts.setLanguage("en-US");
    await _tts.setPitch(1.0);
    await _tts.setSpeechRate(0.5);

    // Initialize STT
    _isSttInitialized = await _stt.initialize(
      onStatus: (status) => log('STT Status: $status'),
      onError: (error) => log('STT Error: $error'),
    );

    // TTS Handlers
    _tts.setStartHandler(() {
      log("TTS started");
    });

    _tts.setCompletionHandler(() {
      currentPlayingText.value = null;
      log("TTS completed");
    });

    _tts.setCancelHandler(() {
      currentPlayingText.value = null;
      log("TTS cancelled");
    });

    _tts.setErrorHandler((msg) {
      currentPlayingText.value = null;
      log("TTS error: $msg");
    });
  }

  // TTS Methods
  Future<void> speak(String text) async {
    if (text.isEmpty) return;
    if (currentPlayingText.value == text) {
      await stopSpeaking();
      return;
    }
    await stopSpeaking(); // Stop any current playback
    currentPlayingText.value = text;
    await _tts.speak(text);
  }

  Future<void> stopSpeaking() async {
    await _tts.stop();
    currentPlayingText.value = null;
  }

  // STT Methods
  Future<void> startListening(Function(String) onResult) async {
    if (!_isSttInitialized) {
      _isSttInitialized = await _stt.initialize();
    }

    if (_isSttInitialized) {
      await _stt.listen(
        onResult: (SpeechRecognitionResult result) {
          if (result.finalResult) {
            onResult(result.recognizedWords);
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
      );
    } else {
      log("STT could not be initialized.");
    }
  }

  Future<void> stopListening() async {
    await _stt.stop();
  }

  bool get isListening => _stt.isListening;
}
