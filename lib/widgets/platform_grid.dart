import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/theme.dart';
import '../models/video_info.dart';

class PlatformGrid extends StatelessWidget {
  final VoidCallback onPasteUrl;

  const PlatformGrid({super.key, required this.onPasteUrl});

  @override
  Widget build(BuildContext context) {
    final platforms = VideoPlatform.values.where((p) => p != VideoPlatform.unknown).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text('المنصات المدعومة', style: Theme.of(context).textTheme.titleMedium),
          ),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemCount: platforms.length,
            itemBuilder: (context, index) {
              return _PlatformItem(platform: platforms[index], onPasteUrl: onPasteUrl)
                  .animate(delay: Duration(milliseconds: index * 60))
                  .fadeIn(duration: 400.ms)
                  .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1));
            },
          ),
        ],
      ),
    );
  }
}

class _PlatformItem extends StatelessWidget {
  final VideoPlatform platform;
  final VoidCallback onPasteUrl;

  const _PlatformItem({required this.platform, required this.onPasteUrl});

  IconData get _icon {
    switch (platform) {
      case VideoPlatform.youtube: return Icons.play_circle_filled_rounded;
      case VideoPlatform.instagram: return Icons.camera_alt_rounded;
      case VideoPlatform.tiktok: return Icons.music_note_rounded;
      case VideoPlatform.twitter: return Icons.alternate_email_rounded;
      case VideoPlatform.facebook: return Icons.facebook_rounded;
      case VideoPlatform.snapchat: return Icons.flash_on_rounded;
      case VideoPlatform.pinterest: return Icons.push_pin_rounded;
      case VideoPlatform.linkedin: return Icons.business_center_rounded;
      case VideoPlatform.reddit: return Icons.forum_rounded;
      case VideoPlatform.tumblr: return Icons.article_rounded;
      case VideoPlatform.vimeo: return Icons.video_library_rounded;
      case VideoPlatform.dailymotion: return Icons.tv_rounded;
      case VideoPlatform.unknown: return Icons.language_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPasteUrl,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderLight),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: platform.brandColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_icon, color: platform.brandColor, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              platform.name,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppTheme.textSecondary, fontWeight: FontWeight.w600, fontSize: 10,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}