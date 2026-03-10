import 'package:flutter_bloc/flutter_bloc.dart';
import 'model_state.dart';
import '../../../../core/services/ai_service.dart';
import '../../../../core/services/local_storage_service.dart';

class ModelCubit extends Cubit<ModelState> {
  final AiService aiService;
  final LocalStorageService storageService;

  static const String _defaultModelName = "Gemma 2B";
  static const String _modelFileName = "gemma-1.1-2b-it-gpu-int4.bin";
  static const String _modelUrl =
      "https://ai-modle.s3.ap-south-2.amazonaws.com/gemma-1.1-2b-it-gpu-int4.bin";

  ModelCubit({required this.aiService, required this.storageService})
    : super(ModelInitial());

  Future<void> checkModelStatus() async {
    emit(ModelLoading());
    try {
      final isDownloaded = await storageService.isModelDownloaded(
        _modelFileName,
      );
      final isLoaded = isDownloaded && await aiService.isModelAvailable();

      emit(
        ModelStatusReady(
          isModelDownloaded: isDownloaded,
          isModelLoaded: isLoaded,
          selectedModel: isDownloaded ? _defaultModelName : 'None',
        ),
      );
    } catch (e) {
      emit(ModelError("Error checking model status: ${e.toString()}"));
    }
  }

  Future<void> loadModel() async {
    if (state is! ModelStatusReady) return;
    final currentState = state as ModelStatusReady;

    if (currentState.isModelLoaded) return;

    emit(ModelLoading());
    try {
      await aiService.initialize();
      emit(currentState.copyWith(isModelLoaded: true));
    } catch (e) {
      emit(ModelError("Failed to load model: ${e.toString()}"));
    }
  }

  Future<void> downloadModel() async {
    if (state is! ModelStatusReady) return;

    final currentState = state as ModelStatusReady;
    emit(currentState.copyWith(isDownloading: true, downloadProgress: 0.0));

    try {
      await storageService.downloadModel(
        url: _modelUrl,
        modelName: _modelFileName,
        onProgress: (progress) {
          emit(
            (state as ModelStatusReady).copyWith(downloadProgress: progress),
          );
        },
      );

      emit(
        ModelStatusReady(
          isModelDownloaded: true,
          selectedModel: _defaultModelName,
          isDownloading: false,
        ),
      );
    } catch (e) {
      print("ModelCubit: Download failed: $e");
      emit(ModelError("Download failed: ${e.toString()}"));
      // Don't call checkModelStatus() immediately, let the user see the error
    }
  }

  Future<void> deleteModel() async {
    try {
      await storageService.deleteModel(_modelFileName);
      await checkModelStatus();
    } catch (e) {
      emit(ModelError("Delete failed: ${e.toString()}"));
    }
  }

  Future<void> selectModel(String modelName) async {
    if (state is ModelStatusReady) {
      final currentState = state as ModelStatusReady;
      emit(currentState.copyWith(selectedModel: modelName));
    }
  }
}
