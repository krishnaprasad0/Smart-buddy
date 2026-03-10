import 'package:equatable/equatable.dart';

abstract class ModelState extends Equatable {
  const ModelState();

  @override
  List<Object?> get props => [];
}

class ModelInitial extends ModelState {}

class ModelLoading extends ModelState {}

class ModelStatusReady extends ModelState {
  final bool isModelDownloaded;
  final bool isModelLoaded;
  final String selectedModel;
  final double downloadProgress;
  final bool isDownloading;

  const ModelStatusReady({
    required this.isModelDownloaded,
    this.isModelLoaded = false,
    required this.selectedModel,
    this.downloadProgress = 0.0,
    this.isDownloading = false,
  });

  ModelStatusReady copyWith({
    bool? isModelDownloaded,
    bool? isModelLoaded,
    String? selectedModel,
    double? downloadProgress,
    bool? isDownloading,
  }) {
    return ModelStatusReady(
      isModelDownloaded: isModelDownloaded ?? this.isModelDownloaded,
      isModelLoaded: isModelLoaded ?? this.isModelLoaded,
      selectedModel: selectedModel ?? this.selectedModel,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      isDownloading: isDownloading ?? this.isDownloading,
    );
  }

  @override
  List<Object?> get props => [
    isModelDownloaded,
    isModelLoaded,
    selectedModel,
    downloadProgress,
    isDownloading,
  ];
}

class ModelError extends ModelState {
  final String message;

  const ModelError(this.message);

  @override
  List<Object?> get props => [message];
}
