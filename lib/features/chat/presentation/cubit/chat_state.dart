import 'package:equatable/equatable.dart';

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

  const ChatMessageReceived({required this.messages, this.isTyping = false});

  @override
  List<Object?> get props => [messages, isTyping];
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
