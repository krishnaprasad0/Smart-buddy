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

    // Simple keyword-based retrieval for browser offline MVP
    // We search all chunks and return the top 3 most relevant ones
    final queryWords = query
        .toLowerCase()
        .split(' ')
        .where((w) => w.length > 3)
        .toList();
    if (queryWords.isEmpty) return "";

    List<MapEntry<DocumentChunk, int>> scores = [];

    for (var doc in _documents) {
      for (var chunk in doc.chunks) {
        int score = 0;
        final chunkText = chunk.text.toLowerCase();
        for (var word in queryWords) {
          if (chunkText.contains(word)) score++;
        }
        if (score > 0) {
          scores.add(MapEntry(chunk, score));
        }
      }
    }

    scores.sort((a, b) => b.value.compareTo(a.value));

    final topChunks = scores.take(3).map((e) => e.key.text).toList();

    if (topChunks.isEmpty) return "";

    return "Relevant context from documents:\n${topChunks.join("\n---\n")}";
  }

  @override
  List<DocumentModel> getIndexedDocuments() {
    return List.unmodifiable(_documents);
  }
}
