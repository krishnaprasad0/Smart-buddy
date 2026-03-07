import 'package:equatable/equatable.dart';

class DocumentModel extends Equatable {
  final String id;
  final String name;
  final String content;
  final List<DocumentChunk> chunks;

  const DocumentModel({
    required this.id,
    required this.name,
    required this.content,
    required this.chunks,
  });

  @override
  List<Object?> get props => [id, name, content, chunks];
}

class DocumentChunk extends Equatable {
  final String text;
  final int index;

  const DocumentChunk({required this.text, required this.index});

  @override
  List<Object?> get props => [text, index];
}
