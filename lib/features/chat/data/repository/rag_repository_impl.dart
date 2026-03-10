import 'package:flutter/foundation.dart';
import '../../domain/model/document_model.dart';
import '../../domain/repository/rag_repository.dart';

class RagRepositoryImpl implements RagRepository {
  final List<DocumentModel> _documents = [];

  @override
  Future<void> indexDocument(DocumentModel document) async {
    _documents.add(document);
  }

  @override
  Future<String> retrieveContext(String query) async {
    if (_documents.isEmpty) return "";

    // 1. Flatten all chunks from all documents into a simple list of strings.
    // This avoids copying full DocumentModel objects (with metadata and full content)
    // across isolate boundaries, which is likely causing the UI freeze.
    final List<String> allChunkTexts = _documents
        .expand((doc) => doc.chunks)
        .map((chunk) => chunk.text)
        .toList();

    if (allChunkTexts.isEmpty) return "";

    // Offload heavy text processing to an isolate to keep the UI thread smooth
    return await compute(_retrieveContextIsolate, {
      'query': query,
      'chunks': allChunkTexts,
    });
  }

  static String _retrieveContextIsolate(Map<String, dynamic> params) {
    final String query = params['query'];
    final List<String> chunks = params['chunks'];

    final queryWords = query
        .toLowerCase()
        .split(' ')
        .where((w) => w.length > 3)
        .toList();
    if (queryWords.isEmpty) return "";

    // List of pairs: [chunkText, score]
    List<MapEntry<String, int>> scores = [];

    for (var chunkText in chunks) {
      int score = 0;
      final lowercaseChunk = chunkText.toLowerCase();
      for (var word in queryWords) {
        if (lowercaseChunk.contains(word)) score++;
      }
      if (score > 0) {
        scores.add(MapEntry(chunkText, score));
      }
    }

    if (scores.isEmpty) return "";

    // Sort by score descending
    scores.sort((a, b) => b.value.compareTo(a.value));

    final topChunks = scores.take(3).map((e) => e.key).toList();

    return "Relevant context from documents:\n${topChunks.join("\n---\n")}";
  }

  @override
  List<DocumentModel> getIndexedDocuments() {
    return List.unmodifiable(_documents);
  }
}
