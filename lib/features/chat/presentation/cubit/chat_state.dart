import 'package:equatable/equatable.dart';
import '../../domain/model/chat_session.dart';

abstract class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object?> get props => [];
}

class ChatInitial extends ChatState {}

class ChatLoading extends ChatState {}

class ChatMessageReceived extends ChatState {
  final List<ChatMessage> messages;
  final bool isTyping;
  final bool isGenerating;
  final String? currentSessionId;
  final List<ChatSession> allSessions;

  const ChatMessageReceived({
    required this.messages,
    this.isTyping = false,
    this.isGenerating = false,
    this.currentSessionId,
    this.allSessions = const [],
  });

  @override
  List<Object?> get props => [
    messages,
    isTyping,
    isGenerating,
    currentSessionId,
    allSessions,
  ];

  ChatMessageReceived copyWith({
    List<ChatMessage>? messages,
    bool? isTyping,
    bool? isGenerating,
    String? currentSessionId,
    List<ChatSession>? allSessions,
  }) {
    return ChatMessageReceived(
      messages: messages ?? this.messages,
      isTyping: isTyping ?? this.isTyping,
      isGenerating: isGenerating ?? this.isGenerating,
      currentSessionId: currentSessionId ?? this.currentSessionId,
      allSessions: allSessions ?? this.allSessions,
    );
  }
}

class ChatError extends ChatState {
  final String message;

  const ChatError(this.message);

  @override
  List<Object?> get props => [message];
}

class ChatMessage extends Equatable {
  final String text;
  final bool isAi;
  final DateTime timestamp;
  final Duration? timeTaken;
  final int? tokenCount;

  const ChatMessage({
    required this.text,
    required this.isAi,
    required this.timestamp,
    this.timeTaken,
    this.tokenCount,
  });

  @override
  List<Object?> get props => [text, isAi, timestamp, timeTaken, tokenCount];
}
