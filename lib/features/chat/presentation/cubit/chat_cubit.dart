import 'dart:developer';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'chat_state.dart';
import '../../../../core/services/ai_service.dart';
import '../../domain/repository/rag_repository.dart';
import '../../data/source/local_document_source.dart';

class ChatCubit extends Cubit<ChatState> {
  final AiService aiService;
  final RagRepository ragRepository;
  final LocalDocumentSource documentSource;

  final List<ChatMessage> _messages = [];

  ChatCubit({
    required this.aiService,
    required this.ragRepository,
    required this.documentSource,
  }) : super(ChatInitial()) {
    _addInitialMessage();
  }

  void _addInitialMessage() {
    _messages.add(
      ChatMessage(
        text:
            "Hello! I am **Smart Buddy**, your offline AI assistant. Upload a document and ask me anything about it!",
        isAi: true,
        timestamp: DateTime.now(),
      ),
    );
    emit(ChatMessageReceived(messages: List.from(_messages)));
  }

  Future<void> uploadDocument() async {
    try {
      final document = await documentSource.pickAndParseDocument();
      if (document != null) {
        await ragRepository.indexDocument(document);
        _messages.add(
          ChatMessage(
            text:
                "Successfully indexed `${document.name}`. I can now answer questions based on its content!",
            isAi: true,
            timestamp: DateTime.now(),
          ),
        );
        emit(ChatMessageReceived(messages: List.from(_messages)));
      }
    } catch (e) {
      emit(ChatError("Failed to upload document: $e"));
      emit(ChatMessageReceived(messages: List.from(_messages)));
    }
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMessage = ChatMessage(
      text: text,
      isAi: false,
      timestamp: DateTime.now(),
    );
    _messages.add(userMessage);
    emit(ChatMessageReceived(messages: List.from(_messages), isTyping: true));

    try {
      // 0. Check if AI Service is available (initialized)
      final isAvailable = await aiService.isModelAvailable();
      if (!isAvailable) {
        emit(
          ChatError(
            "Model not loaded. Please go to Neural Hub and LOAD the brain first!",
          ),
        );
        emit(
          ChatMessageReceived(messages: List.from(_messages), isTyping: false),
        );
        return;
      }

      // 1. Retrieve context from RAG Repository
      final context = await ragRepository.retrieveContext(text);

      // 2. Construct Augmented Prompt with Identity
      String systemPrompt =
          "You are Smart Buddy, a friendly and helpful offline AI assistant. You can handle both general conversation and document-based questions. Keep your responses concise and natural by default.";
      String augmentedPrompt = "$systemPrompt\n\nUser Question: $text";

      if (context.isNotEmpty) {
        augmentedPrompt =
            "$systemPrompt\n\nContext from documents:\n$context\n\n"
            "Task: Answer the user's question. If the provided context contains relevant information, use it to give an accurate answer. "
            "If the context is not relevant (e.g., the user is just saying hello or asking a general question), respond naturally as Smart Buddy without forcing the context into the answer.\n\n"
            "User Question: $text";
      }

      // 3. Call AI Service
      final stopwatch = Stopwatch()..start();
      final aiStream = aiService.promptStream(augmentedPrompt);

      String currentAiResponse = "";
      final aiMsgTimestamp = DateTime.now();

      // Add an initial empty message for the AI
      _messages.add(
        ChatMessage(text: "", isAi: true, timestamp: aiMsgTimestamp),
      );

      await for (final chunk in aiStream) {
        // MediaPipe 0.10.29 generateResponseAsync sends DELTAS (not cumulative)
        currentAiResponse += chunk;

        // Update the last message (the one we just added) with the new text
        _messages[_messages.length - 1] = ChatMessage(
          text: currentAiResponse,
          isAi: true,
          timestamp: aiMsgTimestamp,
        );

        // Hide typing indicator once we have content
        emit(
          ChatMessageReceived(
            messages: List.from(_messages),
            isTyping: currentAiResponse.isEmpty,
          ),
        );
      }

      stopwatch.stop();
      // Final update with metrics
      // Rough estimation: 1 token approx 4 chars
      final tokenCount = (currentAiResponse.length / 4).round();

      _messages[_messages.length - 1] = ChatMessage(
        text: currentAiResponse,
        isAi: true,
        timestamp: aiMsgTimestamp,
        timeTaken: stopwatch.elapsed,
        tokenCount: tokenCount,
      );

      emit(
        ChatMessageReceived(messages: List.from(_messages), isTyping: false),
      );
    } catch (e) {
      log("ChatCubit: Catching AI Error: $e");
      await aiService.reset();
      emit(ChatError("AI Error: $e"));
      emit(
        ChatMessageReceived(messages: List.from(_messages), isTyping: false),
      );
    }
  }

  void clearChat() {
    _messages.clear();
    _addInitialMessage();
  }
}
