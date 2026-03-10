import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:animate_do/animate_do.dart';
import '../../../../core/theme/app_theme.dart';
import '../cubit/model_cubit.dart';
import '../cubit/model_state.dart';

class ModelPage extends StatelessWidget {
  const ModelPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: Colors.black.withOpacity(0.8),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'NEURAL HUB',
                style: TextStyle(
                  color: AppTheme.buddyTeal,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              centerTitle: true,
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 16.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FadeInLeft(
                    child: Text(
                      'Local Intelligence',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w300,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  FadeInLeft(
                    delay: const Duration(milliseconds: 200),
                    child: Text(
                      'Download and manage local LLMs for 100% offline document analysis.',
                      style: TextStyle(color: Colors.white54, fontSize: 14),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
          BlocBuilder<ModelCubit, ModelState>(
            builder: (context, state) {
              if (state is ModelLoading) {
                return const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: AppTheme.buddyTeal),
                  ),
                );
              }

              if (state is ModelStatusReady) {
                return SliverList(
                  delegate: SliverChildListDelegate([
                    _ModelCard(
                      title: 'Gemma 2B',
                      description:
                          'Optimal balance between speed and quality for document Q&A. Size: ~1.5GB',
                      icon: Icons.psychology,
                      isDownloaded: state.isModelDownloaded,
                      isLoaded: state.isModelLoaded,
                      isSelected: state.selectedModel == 'Gemma 2B',
                      isDownloading: state.isDownloading,
                      progress: state.downloadProgress,
                      onAction: () {
                        if (!state.isModelDownloaded) {
                          if (!state.isDownloading) {
                            context.read<ModelCubit>().downloadModel();
                          }
                        } else if (!state.isModelLoaded) {
                          context.read<ModelCubit>().loadModel();
                        } else {
                          context.read<ModelCubit>().selectModel('Gemma 2B');
                        }
                      },
                      onDelete: state.isModelDownloaded
                          ? () => _showDeleteConfirmation(context)
                          : null,
                    ),
                    const SizedBox(height: 16),
                    _ModelCard(
                      title: 'Llama 3 8B',
                      description:
                          'Advanced reasoning and complex instructions. Requires more RAM. Size: ~4.5GB',
                      icon: Icons.auto_awesome,
                      isDownloaded: false,
                      isLoaded: false,
                      isSelected: state.selectedModel == 'Llama 3 8B',
                      isDownloading: false,
                      isAvailable: false,
                      onAction: () {},
                    ),
                    const SizedBox(height: 16),
                    _ModelCard(
                      title: 'Mistral 7B',
                      description:
                          'High performance for creative tasks. Size: ~4.1GB',
                      icon: Icons.bubble_chart,
                      isDownloaded: false,
                      isLoaded: false,
                      isSelected: state.selectedModel == 'Mistral 7B',
                      isDownloading: false,
                      isAvailable: false,
                      onAction: () {},
                    ),
                    const SizedBox(height: 40),
                  ]),
                );
              }

              if (state is ModelError) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.redAccent,
                          size: 60,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          state.message,
                          style: const TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () =>
                              context.read<ModelCubit>().checkModelStatus(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return const SliverToBoxAdapter(child: SizedBox.shrink());
            },
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text(
          'Delete Model',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to delete the offline model files from your device? You will need to download them again to use offline AI.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<ModelCubit>().deleteModel();
              Navigator.pop(dialogContext);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModelCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final bool isDownloaded;
  final bool isLoaded;
  final bool isSelected;
  final bool isDownloading;
  final double progress;
  final bool isAvailable;
  final VoidCallback onAction;
  final VoidCallback? onDelete;

  const _ModelCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.isDownloaded,
    required this.isLoaded,
    required this.isSelected,
    this.isDownloading = false,
    this.progress = 0.0,
    this.isAvailable = true,
    required this.onAction,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: FadeInUp(
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.surfaceColor,
                AppTheme.surfaceColor.withOpacity(0.5),
              ],
            ),
            border: Border.all(
              color: isSelected ? AppTheme.buddyTeal : Colors.white10,
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Material(
              color: Colors.transparent,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.buddyTeal.withOpacity(0.1)
                                : Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            icon,
                            color: isSelected
                                ? AppTheme.buddyTeal
                                : Colors.white60,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              if (!isAvailable)
                                const Text(
                                  'COMNING SOON',
                                  style: TextStyle(
                                    color: Colors.orangeAccent,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (isLoaded)
                          const Icon(
                            Icons.bolt,
                            color: AppTheme.buddyTeal,
                            size: 24,
                          )
                        else if (isDownloaded)
                          const Icon(
                            Icons.download_done,
                            color: Colors.white30,
                            size: 24,
                          )
                        else if (isDownloading)
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              value: progress,
                              strokeWidth: 3,
                              color: AppTheme.buddyTeal,
                              backgroundColor: Colors.white10,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      description,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isAvailable && !isDownloading
                                ? onAction
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isSelected
                                  ? AppTheme.buddyTeal
                                  : isDownloaded
                                  ? Colors.white10
                                  : AppTheme.buddyGreen,
                              foregroundColor: isSelected
                                  ? Colors.black
                                  : Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              isDownloading
                                  ? 'Downloading ${(progress * 100).toInt()}%'
                                  : !isDownloaded
                                  ? 'Download Brain'
                                  : !isLoaded
                                  ? 'Load Brain'
                                  : 'Active',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        if (onDelete != null) ...[
                          const SizedBox(width: 12),
                          IconButton(
                            onPressed: onDelete,
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.white30,
                            ),
                            tooltip: 'Delete Model Data',
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
