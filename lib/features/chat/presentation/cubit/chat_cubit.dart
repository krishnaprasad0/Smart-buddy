import 'dart:async';
import 'dart:developer';

import 'package:uuid/uuid.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'chat_state.dart';
import '../../../../core/services/ai_service.dart';
import '../../../../core/services/database_service.dart';
import '../../domain/model/chat_session.dart';
import '../../domain/model/document_model.dart';
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

  StreamSubscription<String>? _aiSubscription;

  ChatCubit({
    required this.aiService,
    required this.ragRepository,
    required this.documentSource,
    required this.dbService, // Added
  }) : super(ChatInitial()) {
    // _addInitialMessage(); // Removed, replaced by session loading
    _init();
  }

  Future<void> _init() async {
    await loadSessions();
    await loadKnowledgeBase();
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

  Future<void> loadKnowledgeBase() async {
    try {
      final docMaps = await dbService.getDocuments();
      await ragRepository.clearDocuments();

      for (var map in docMaps) {
        final content = map['content'] as String;
        // Re-chunk on load for simplicity
        final chunks = documentSource.chunkText(content);
        final doc = DocumentModel(
          id: map['id'],
          name: map['name'],
          content: content,
          chunks: chunks,
        );
        await ragRepository.indexDocument(doc);
      }

      // Emit current state to refresh UI if needed
      if (state is ChatMessageReceived) {
        emit((state as ChatMessageReceived).copyWith());
      }
    } catch (e) {
      log("Error loading KB: $e");
    }
  }

  Future<void> uploadDocument() async {
    try {
      final document = await documentSource.pickAndParseDocument();
      if (document != null) {
        // 1. Save to DB
        await dbService.saveDocument(document.toMap());

        // 2. Index in memory
        await ragRepository.indexDocument(document);

        final statusMsg = ChatMessage(
          text:
              "Successfully indexed `${document.name}`. I can now answer questions based on its content!",
          isAi: true,
          timestamp: DateTime.now(),
        );

        if (state is ChatMessageReceived) {
          final s = state as ChatMessageReceived;
          final updated = List<ChatMessage>.from(s.messages)..add(statusMsg);
          emit(s.copyWith(messages: updated));
        }

        // Save status message to current session if it exists
        if (_currentSessionId != null) {
          await dbService.saveMessage(_currentSessionId!, statusMsg);
        }
      }
    } catch (e) {
      emit(ChatError("Failed to upload document: $e"));
    }
  }

  Future<void> deleteDocument(String id) async {
    try {
      await dbService.deleteDocument(id);
      await loadKnowledgeBase();
    } catch (e) {
      log("Error deleting document: $e");
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
        isGenerating: true,
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
          isGenerating: true,
          currentSessionId: _currentSessionId,
          allSessions: _allSessions,
        ),
      );

      _aiSubscription = aiStream.listen(
        (chunk) {
          currentAiResponse += chunk;
          messagesWithAiPlaceholder[messagesWithAiPlaceholder.length -
              1] = ChatMessage(
            text: currentAiResponse,
            isAi: true,
            timestamp: aiMsgTimestamp,
          );

          emit(
            ChatMessageReceived(
              messages: List.from(messagesWithAiPlaceholder),
              isTyping: currentAiResponse.isEmpty,
              isGenerating: true,
              currentSessionId: _currentSessionId,
              allSessions: _allSessions,
            ),
          );
        },
        onError: (e) {
          log("ChatCubit: Stream Error: $e");
          _handleFinish(
            updatedMessages,
            currentAiResponse,
            aiMsgTimestamp,
            stopwatch,
          );
        },
        onDone: () {
          _handleFinish(
            updatedMessages,
            currentAiResponse,
            aiMsgTimestamp,
            stopwatch,
          );
        },
        cancelOnError: true,
      );
    } catch (e) {
      log("ChatCubit: Catching AI Error: $e");
      if (e.toString().contains("BUSY")) {
        await aiService.reset();
      }
      emit(
        ChatError(
          "AI Error: ${e.toString().contains("BUSY") ? "Processor was busy. Resetting... Please try again." : e}",
        ),
      );
      emit(
        ChatMessageReceived(
          messages: updatedMessages,
          isTyping: false,
          currentSessionId: _currentSessionId,
          allSessions: _allSessions,
        ),
      );
    }
  }

  Future<void> _handleFinish(
    List<ChatMessage> updatedMessages,
    String finalResponse,
    DateTime timestamp,
    Stopwatch stopwatch,
  ) async {
    stopwatch.stop();
    final tokenCount = (finalResponse.length / 4).round();

    final aiMessage = ChatMessage(
      text: finalResponse,
      isAi: true,
      timestamp: timestamp,
      timeTaken: stopwatch.elapsed,
      tokenCount: tokenCount,
    );

    if (finalResponse.isNotEmpty) {
      await dbService.saveMessage(_currentSessionId!, aiMessage);
    }

    final finalMessages = List<ChatMessage>.from(updatedMessages)
      ..add(aiMessage);

    emit(
      ChatMessageReceived(
        messages: finalMessages,
        isTyping: false,
        isGenerating: false,
        currentSessionId: _currentSessionId,
        allSessions: _allSessions,
      ),
    );
    _aiSubscription = null;
  }

  Future<void> stopGeneration() async {
    if (_aiSubscription != null) {
      await _aiSubscription?.cancel();
      _aiSubscription = null;

      // Crucial: Await the reset to ensure the native inference engine is free
      await aiService.reset();

      // Emit state to stop UI loading indicator only AFTER reset is done
      if (state is ChatMessageReceived) {
        emit(
          (state as ChatMessageReceived).copyWith(
            isTyping: false,
            isGenerating: false,
          ),
        );
      }
    }
  }

  void clearChat() {
    if (_currentSessionId != null) {
      dbService.deleteSession(_currentSessionId!);
      createNewChat();
    }
  }
}
