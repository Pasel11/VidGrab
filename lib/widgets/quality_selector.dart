import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/theme.dart';
import '../models/video_info.dart';

class QualitySelector extends StatelessWidget {
  final List<VideoQuality> qualities;
  final VideoQuality? selected;
  final ValueChanged<VideoQuality> onSelected;
  final String? suggestedQuality; // اقتراح من الذكاء الشبكي

  const QualitySelector({
    super.key,
    required this.qualities,
    this.selected,
    required this.onSelected,
    this.suggestedQuality,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: qualities.asMap().entries.map((entry) {
        final index = entry.key;
        final quality = entry.value;
        final isSelected = quality == selected;
        final isAudio = quality.isAudioOnly || quality.format == 'MP3';
        final isSuggested = suggestedQuality != null &&
            quality.resolution.toLowerCase().contains(suggestedQuality!.toLowerCase());

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.accentPurple.withOpacity(0.1)
                  : AppTheme.cardDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? AppTheme.accentPurple : (isSuggested ? AppTheme.accentCyan.withOpacity(0.4) : AppTheme.borderLight),
                width: isSelected ? 2 : (isSuggested ? 1.5 : 1),
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => onSelected(quality),
                child: Row(
                  children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.accentPurple.withOpacity(0.2)
                            : (isSuggested ? AppTheme.accentCyan.withOpacity(0.1) : AppTheme.borderLight),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            isAudio ? Icons.audiotrack_rounded : Icons.high_quality_rounded,
                            color: isSelected ? AppTheme.accentPurple : (isSuggested ? AppTheme.accentCyan : AppTheme.textMuted),
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(quality.label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: isSelected ? AppTheme.accentPurple : AppTheme.textPrimary,
                              )),
                              if (isSuggested && !isSelected) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: AppTheme.accentCyan.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text('مقترح', style: TextStyle(fontSize: 9, color: AppTheme.accentCyan, fontWeight: FontWeight.w700)),
                                ),
                              ],
                              if (quality.isHDR) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFD700).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text('HDR', style: TextStyle(fontSize: 9, color: Color(0xFFFFD700), fontWeight: FontWeight.w800)),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Text(
                                '${quality.resolution}  •  ${quality.format}  •  ${quality.fileSize}',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              if (quality.bitrate > 0) ...[
                                const SizedBox(width: 8),
                                Text('${quality.bitrate}kbps', style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppTheme.accentPurple,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.check_rounded, color: Colors.white, size: 16),
                      )
                    else if (isSuggested)
                      const Icon(Icons.auto_awesome_rounded, color: AppTheme.accentCyan, size: 20),
                  ],
                ),
              ),
            ),
          ),
        ).animate(delay: Duration(milliseconds: index * 80)).fadeIn(duration: 300.ms);
      }).toList(),
    );
  }
}