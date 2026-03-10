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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'content': content,
      'createdAt': DateTime.now().toIso8601String(),
    };
  }

  factory DocumentModel.fromMap(Map<String, dynamic> map) {
    // Note: chunks are reconstructed from content if they're not in DB separately
    // Or we re-chunk on load for simplicity if chunkSize is stable.
    return DocumentModel(
      id: map['id'],
      name: map['name'],
      content: map['content'],
      chunks: [], // Will be populated by re-chunking logic
    );
  }

  @override
  List<Object?> get props => [id, name, content, chunks];
}

class DocumentChunk extends Equatable {
  final String text;
  final int index;

  const DocumentChunk({required this.text, required this.index});

  factory DocumentChunk.fromText(String text, int index) {
    return DocumentChunk(text: text, index: index);
  }

  @override
  List<Object?> get props => [text, index];
}
