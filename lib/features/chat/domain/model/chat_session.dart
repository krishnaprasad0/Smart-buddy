import 'package:equatable/equatable.dart';
import '../../presentation/cubit/chat_state.dart' show ChatMessage;

class ChatSession extends Equatable {
  final String id;
  final String title;
  final DateTime createdAt;
  final List<ChatMessage> messages;

  const ChatSession({
    required this.id,
    required this.title,
    required this.createdAt,
    this.messages = const [],
  });

  ChatSession copyWith({
    String? id,
    String? title,
    DateTime? createdAt,
    List<ChatMessage>? messages,
  }) {
    return ChatSession(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      messages: messages ?? this.messages,
    );
  }

  @override
  List<Object?> get props => [id, title, createdAt, messages];

  Map<String, dynamic> toMap() {
    return {'id': id, 'title': title, 'createdAt': createdAt.toIso8601String()};
  }

  factory ChatSession.fromMap(
    Map<String, dynamic> map, [
    List<ChatMessage> messages = const [],
  ]) {
    return ChatSession(
      id: map['id'] as String,
      title: map['title'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      messages: messages,
    );
  }
}
