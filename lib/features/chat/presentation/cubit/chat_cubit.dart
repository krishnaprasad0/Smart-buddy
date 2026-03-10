import 'dart:developer';

import 'package:uuid/uuid.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'chat_state.dart';
import '../../../../core/services/ai_service.dart';
import '../../../../core/services/database_service.dart';
import '../../domain/model/chat_session.dart';
import '../../domain/repository/rag_repository.dart';
import '../../data/source/local_document_source.dart';

class ChatCubit extends Cubit<ChatState> {
  final AiService aiService;
  final RagRepository ragRepository;
  final LocalDocumentSource documentSource;
  final DatabaseService dbService; // Added
  final _uuid = const Uuid(); // Added

  String? _currentSessionId; // Added
  List<ChatSession> _allSessions = []; // Added

  // The _messages list is now managed by the database for sessions,
  // but still used by uploadDocument for temporary messages.
  // This might need refactoring if uploadDocument should also save to DB.
  final List<ChatMessage> _messages = [];

  ChatCubit({
    required this.aiService,
    required this.ragRepository,
    required this.documentSource,
    required this.dbService, // Added
  }) : super(ChatInitial()) {
    // _addInitialMessage(); // Removed, replaced by session loading
    loadSessions(); // Added
  }

  // Removed _addInitialMessage as session handling now dictates initial state

  Future<void> loadSessions() async {
    _allSessions = await dbService.getSessions();
    if (_allSessions.isEmpty) {
      await createNewChat();
    } else {
      await loadChatSession(_allSessions.first.id);
    }
  }

  Future<void> createNewChat() async {
    final sessionId = _uuid.v4();
    final newSession = ChatSession(
      id: sessionId,
      title: "New Chat ${DateTime.now().hour}:${DateTime.now().minute}",
      createdAt: DateTime.now(),
    );
    await dbService.saveSession(newSession);
    _allSessions = await dbService.getSessions();
    _currentSessionId = sessionId;
    emit(
      ChatMessageReceived(
        messages: const [],
        currentSessionId: _currentSessionId,
        allSessions: _allSessions,
      ),
    );
  }

  Future<void> loadChatSession(String sessionId) async {
    final messages = await dbService.getMessages(sessionId);
    _currentSessionId = sessionId;
    emit(
      ChatMessageReceived(
        messages: messages,
        currentSessionId: _currentSessionId,
        allSessions: _allSessions,
      ),
    );
  }

  Future<void> deleteSession(String sessionId) async {
    await dbService.deleteSession(sessionId);
    await loadSessions();
  }

  Future<void> uploadDocument() async {
    try {
      final document = await documentSource.pickAndParseDocument();
      if (document != null) {
        await ragRepository.indexDocument(document);
        // This message is currently not saved to DB, only to _messages list.
        // This might need refactoring to align with session-based message storage.
        _messages.add(
          ChatMessage(
            text:
                "Successfully indexed `${document.name}`. I can now answer questions based on its content!",
            isAi: true,
            timestamp: DateTime.now(),
          ),
        );
        // Emitting the temporary _messages list, not the session messages.
        // This is a potential inconsistency that might need addressing.
        emit(ChatMessageReceived(messages: List.from(_messages)));
      }
    } catch (e) {
      emit(ChatError("Failed to upload document: $e"));
      emit(ChatMessageReceived(messages: List.from(_messages)));
    }
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    if (_currentSessionId == null) {
      await createNewChat();
    }

    final userMessage = ChatMessage(
      text: text,
      isAi: false,
      timestamp: DateTime.now(),
    );

    final currentMessages = state is ChatMessageReceived
        ? (state as ChatMessageReceived).messages
        : <ChatMessage>[];

    // If this is the first message in the session, update the title
    if (currentMessages.isEmpty && _currentSessionId != null) {
      final title = text.length > 30 ? "${text.substring(0, 27)}..." : text;
      await dbService.updateSessionTitle(_currentSessionId!, title);
      _allSessions = await dbService.getSessions();
    }

    final updatedMessages = List<ChatMessage>.from(currentMessages)
      ..add(userMessage);

    await dbService.saveMessage(_currentSessionId!, userMessage);

    emit(
      ChatMessageReceived(
        messages: updatedMessages,
        isTyping: true,
        currentSessionId: _currentSessionId,
        allSessions: _allSessions,
      ),
    );

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
          ChatMessageReceived(
            messages: updatedMessages, // Use updatedMessages here
            isTyping: false,
            currentSessionId: _currentSessionId,
            allSessions: _allSessions,
          ),
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

      // Add an initial empty message for the AI to the UI state
      final aiPlaceholderMessage = ChatMessage(
        text: "",
        isAi: true,
        timestamp: aiMsgTimestamp,
      );
      List<ChatMessage> messagesWithAiPlaceholder = List.from(updatedMessages)
        ..add(aiPlaceholderMessage);

      emit(
        ChatMessageReceived(
          messages: messagesWithAiPlaceholder,
          isTyping: true,
          currentSessionId: _currentSessionId,
          allSessions: _allSessions,
        ),
      );

      await for (final chunk in aiStream) {
        currentAiResponse += chunk;

        // Update the last message (the AI placeholder) with the new text
        messagesWithAiPlaceholder[messagesWithAiPlaceholder.length -
            1] = ChatMessage(
          text: currentAiResponse,
          isAi: true,
          timestamp: aiMsgTimestamp,
        );

        emit(
          ChatMessageReceived(
            messages: List.from(messagesWithAiPlaceholder), // Emit a copy
            isTyping: currentAiResponse.isEmpty,
            currentSessionId: _currentSessionId,
            allSessions: _allSessions,
          ),
        );
      }

      stopwatch.stop();
      // Final update with metrics
      final tokenCount = (currentAiResponse.length / 4).round();

      final aiMessage = ChatMessage(
        text: currentAiResponse,
        isAi: true,
        timestamp: aiMsgTimestamp,
        timeTaken: stopwatch.elapsed,
        tokenCount: tokenCount,
      );

      await dbService.saveMessage(_currentSessionId!, aiMessage);

      final finalMessages = List<ChatMessage>.from(updatedMessages)
        ..add(aiMessage);

      emit(
        ChatMessageReceived(
          messages: finalMessages,
          isTyping: false,
          currentSessionId: _currentSessionId,
          allSessions: _allSessions,
        ),
      );
    } catch (e) {
      log("ChatCubit: Catching AI Error: $e");
      await aiService.reset();
      emit(ChatError("AI Error: $e"));
      emit(
        ChatMessageReceived(
          messages: updatedMessages, // Use updatedMessages here
          isTyping: false,
          currentSessionId: _currentSessionId,
          allSessions: _allSessions,
        ),
      );
    }
  }

  void clearChat() {
    if (_currentSessionId != null) {
      dbService.deleteSession(_currentSessionId!);
      createNewChat();
    }
  }
}
