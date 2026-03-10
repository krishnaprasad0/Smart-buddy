import '../../domain/model/document_model.dart';

abstract class RagRepository {
  Future<void> indexDocument(DocumentModel document);
  Future<void> clearDocuments();
  Future<String> retrieveContext(String query);
  List<DocumentModel> getIndexedDocuments();
}
