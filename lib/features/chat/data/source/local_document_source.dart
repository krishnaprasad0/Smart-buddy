import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../../domain/model/document_model.dart';
import 'package:uuid/uuid.dart';

class LocalDocumentSource {
  Future<DocumentModel?> pickAndParseDocument() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      final path = result.files.single.path!;
      final name = result.files.single.name;

      final String content = await _extractTextFromPdfPath(path);
      final chunks = _chunkText(content);

      return DocumentModel(
        id: const Uuid().v4(),
        name: name,
        content: content,
        chunks: chunks,
      );
    }
    return null;
  }

  Future<String> _extractTextFromPdfPath(String path) async {
    try {
      final File file = File(path);
      final Uint8List bytes = await file.readAsBytes();
      final PdfDocument document = PdfDocument(inputBytes: bytes);
      final String text = PdfTextExtractor(document).extractText();
      document.dispose();
      return text;
    } catch (e) {
      return "Error extracting text: $e";
    }
  }

  List<DocumentChunk> _chunkText(String text, {int chunkSize = 1000}) {
    List<DocumentChunk> chunks = [];
    int index = 0;

    for (int i = 0; i < text.length; i += chunkSize) {
      int end = (i + chunkSize < text.length) ? i + chunkSize : text.length;
      chunks.add(DocumentChunk(text: text.substring(i, end), index: index++));
    }
    return chunks;
  }
}
