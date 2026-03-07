import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:permission_handler/permission_handler.dart';

class LocalStorageService {
  final Dio _dio = Dio();

  Future<String> getModelPath(String modelName) async {
    final directory = await getApplicationDocumentsDirectory();
    return "${directory.path}/models/$modelName";
  }

  Future<bool> isModelDownloaded(String modelName) async {
    final path = await getModelPath(modelName);
    return File(path).existsSync();
  }

  Future<void> downloadModel({
    required String url,
    required String modelName,
    required Function(double progress) onProgress,
  }) async {
    var status = await Permission.storage.request();

    // On Android 13+ (API 33+), Permission.storage always returns denied for custom folders.
    // We request manageExternalStorage as a fallback.
    if (status.isDenied) {
      print(
        "Standard storage permission denied, requesting manageExternalStorage...",
      );
      status = await Permission.manageExternalStorage.request();
    }

    if (!status.isGranted) {
      print("Error: Storage permission denied (Status: $status)");
      throw Exception(
        "Storage permission required to download model. Please grant 'All Files Access' in settings.",
      );
    }

    final savePath = await getModelPath(modelName);
    print("Downloading model to: $savePath from $url");
    final file = File(savePath);

    if (!file.parent.existsSync()) {
      await file.parent.create(recursive: true);
    }

    try {
      await _dio.download(
        url,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            onProgress(received / total);
          }
        },
      );
      print("Download completed: $savePath");
    } on DioException catch (e) {
      print("Dio Error during download: ${e.message}");
      print("Status Code: ${e.response?.statusCode}");
      print("Data: ${e.response?.data}");
      throw Exception(
        "Network error (${e.response?.statusCode}): ${e.message}",
      );
    } catch (e) {
      print("Unexpected error during download: $e");
      rethrow;
    }
  }

  Future<void> deleteModel(String modelName) async {
    final path = await getModelPath(modelName);
    final file = File(path);
    if (file.existsSync()) {
      await file.delete();
    }
  }
}
