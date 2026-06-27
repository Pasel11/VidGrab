import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../services/advanced_download_manager.dart';

class DownloadQueueIndicator extends StatelessWidget {
  const DownloadQueueIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AdvancedDownloadManager>(
      builder: (context, manager, _) {
        if (manager.activeTasks.isEmpty && manager.queuedTasks.isEmpty) {
          return const SizedBox.shrink();
        }

        final activeCount = manager.activeTasks.length;
        final queueCount = manager.queuedTasks.length;
        final progress = manager.activeTasks.isNotEmpty
            ? manager.activeTasks.first.progress
            : 0.0;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.accentPurple.withOpacity(0.12), AppTheme.accentBlue.withOpacity(0.06)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.accentPurple.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    // Animated progress circle
                    SizedBox(
                      width: 36, height: 36,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CircularProgressIndicator(
                            value: progress,
                            strokeWidth: 3,
                            backgroundColor: AppTheme.borderLight,
                            valueColor: const AlwaysStoppedAnimation(AppTheme.accentPurple),
                          ),
                          Center(
                            child: Text(
                              '${(progress * 100).toStringAsFixed(0)}%',
                              style: const TextStyle(
                                color: AppTheme.accentPurple, fontSize: 9, fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            manager.activeTasks.isNotEmpty
                                ? manager.activeTasks.first.title
                                : 'في الانتظار...',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 13,
                            ),
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.speed_rounded, size: 12, color: AppTheme.accentCyan),
                              const SizedBox(width: 4),
                              Text(
                                manager.formatSpeed(manager.activeTasks.isNotEmpty
                                    ? manager.activeTasks.first.downloadSpeed : 0),
                                style: const TextStyle(color: AppTheme.accentCyan, fontSize: 11, fontWeight: FontWeight.w600),
                              ),
                              if (queueCount > 0) ...[
                                const SizedBox(width: 12),
                                Text(
                                  '$queueCount في الانتظار',
                                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Pause all / Resume all
                    InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () {
                        if (manager.activeTasks.isNotEmpty) {
                          manager.pauseAllDownloads();
                        } else {
                          manager.resumeAllDownloads();
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.accentPurple.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          manager.activeTasks.isNotEmpty ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          color: AppTheme.accentPurple, size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.2);
      },
    );
  }
}