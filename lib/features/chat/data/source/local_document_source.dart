import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import '../../domain/model/document_model.dart';
import 'package:uuid/uuid.dart';

class LocalDocumentSource {
  Future<File?> _saveToPermanentStorage(String sourcePath, String name) async {
    final directory = await getApplicationDocumentsDirectory();
    final kbDir = Directory('${directory.path}/knowledge_base');
    if (!await kbDir.exists()) {
      await kbDir.create(recursive: true);
    }

    final destinationPath = '${kbDir.path}/${const Uuid().v4()}_$name';
    return await File(sourcePath).copy(destinationPath);
  }

  Future<DocumentModel?> pickAndParseDocument() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      final sourcePath = result.files.single.path!;
      final name = result.files.single.name;

      // Save to permanent storage
      final permanentFile = await _saveToPermanentStorage(sourcePath, name);
      if (permanentFile == null) return null;

      final String content = await _extractTextFromPdfPath(permanentFile.path);
      final chunks = chunkText(content);

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

  List<DocumentChunk> chunkText(String text, {int chunkSize = 1000}) {
    List<DocumentChunk> chunks = [];
    int index = 0;

    for (int i = 0; i < text.length; i += chunkSize) {
      int end = (i + chunkSize < text.length) ? i + chunkSize : text.length;
      chunks.add(DocumentChunk(text: text.substring(i, end), index: index++));
    }
    return chunks;
  }
}
