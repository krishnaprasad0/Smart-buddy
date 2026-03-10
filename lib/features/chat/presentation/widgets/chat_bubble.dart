import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/voice_service.dart';

class ChatBubble extends StatelessWidget {
  final String message;
  final bool isAi;
  final bool isTyping;
  final Duration? timeTaken;
  final int? tokenCount;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isAi,
    this.isTyping = false,
    this.timeTaken,
    this.tokenCount,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Align(
          alignment: isAi ? Alignment.centerLeft : Alignment.centerRight,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            child: PhysicalShape(
              clipper: ChatBubbleClipper(isAi: isAi),
              elevation: 2,
              color: Colors.transparent,
              shadowColor: Colors.black45,
              child: Container(
                padding: EdgeInsets.fromLTRB(
                  isAi ? 20 : 12,
                  12,
                  isAi ? 12 : 20,
                  12,
                ),
                decoration: BoxDecoration(
                  color: isAi ? AppTheme.surfaceColor : AppTheme.buddyGreen,
                  borderRadius: BorderRadius.circular(20),
                  border: isAi
                      ? Border.all(color: Colors.white.withOpacity(0.05))
                      : null,
                ),
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    isTyping
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.buddyTeal,
                            ),
                          )
                        : isAi
                        ? MarkdownBody(
                            data: message,
                            styleSheet: MarkdownStyleSheet(
                              p: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                              ),
                              strong: const TextStyle(
                                color: AppTheme.buddyTeal,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        : Text(
                            message,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                            ),
                          ),
                    if (isAi &&
                        !isTyping &&
                        (timeTaken != null || tokenCount != null))
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (timeTaken != null)
                              MetricTag(
                                icon: Icons.timer_outlined,
                                label:
                                    '${(timeTaken!.inMilliseconds / 1000).toStringAsFixed(1)}s',
                              ),
                            if (timeTaken != null && tokenCount != null)
                              const SizedBox(width: 8),
                            if (tokenCount != null)
                              MetricTag(
                                icon: Icons.token_outlined,
                                label: '$tokenCount tokens',
                              ),
                            const SizedBox(width: 8),
                            ValueListenableBuilder<String?>(
                              valueListenable:
                                  VoiceService().currentPlayingText,
                              builder: (context, playingText, _) {
                                final isPlaying = playingText == message;
                                return IconButton(
                                  iconSize: 14,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  icon: Icon(
                                    isPlaying
                                        ? Icons.stop_circle_rounded
                                        : Icons.volume_up_rounded,
                                    color: isPlaying
                                        ? Colors.redAccent
                                        : AppTheme.buddyTeal,
                                  ),
                                  onPressed: () =>
                                      VoiceService().speak(message),
                                  tooltip: isPlaying ? 'Stop' : 'Read aloud',
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class ChatBubbleClipper extends CustomClipper<Path> {
  final bool isAi;

  ChatBubbleClipper({required this.isAi});

  @override
  Path getClip(Size size) {
    var path = Path();
    double radius = 20.0;
    double tailWidth = 10.0;

    if (isAi) {
      // AI Bubble (Tail bottom-left)
      path.moveTo(tailWidth, radius);
      path.lineTo(tailWidth, size.height - radius);
      // Tail part
      path.quadraticBezierTo(tailWidth, size.height, 0, size.height);
      path.quadraticBezierTo(
        tailWidth,
        size.height,
        tailWidth + 10,
        size.height,
      );

      path.lineTo(size.width - radius, size.height);
      path.quadraticBezierTo(
        size.width,
        size.height,
        size.width,
        size.height - radius,
      );
      path.lineTo(size.width, radius);
      path.quadraticBezierTo(size.width, 0, size.width - radius, 0);
      path.lineTo(tailWidth + radius, 0);
      path.quadraticBezierTo(tailWidth, 0, tailWidth, radius);
      path.close();
    } else {
      // User Bubble (Tail bottom-right)
      path.moveTo(radius, 0);
      path.lineTo(size.width - radius - tailWidth, 0);
      path.quadraticBezierTo(
        size.width - tailWidth,
        0,
        size.width - tailWidth,
        radius,
      );
      path.lineTo(size.width - tailWidth, size.height - radius);

      // Tail part
      path.quadraticBezierTo(
        size.width - tailWidth,
        size.height,
        size.width,
        size.height,
      );
      path.quadraticBezierTo(
        size.width - tailWidth,
        size.height,
        size.width - tailWidth - 10,
        size.height,
      );

      path.lineTo(radius, size.height);
      path.quadraticBezierTo(0, size.height, 0, size.height - radius);
      path.lineTo(0, radius);
      path.quadraticBezierTo(0, 0, radius, 0);
      path.close();
    }
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class MetricTag extends StatelessWidget {
  final IconData icon;
  final String label;

  const MetricTag({super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: AppTheme.buddyTeal.withOpacity(0.7)),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: Colors.white.withOpacity(0.5),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
