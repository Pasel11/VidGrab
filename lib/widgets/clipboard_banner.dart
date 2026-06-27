import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import '../config/theme.dart';
import '../config/routes.dart';
import '../services/clipboard_watcher.dart';
import '../services/advanced_download_manager.dart';

/// بانر ذكي يظهر تلقائياً عند كشف رابط فيديو في الحافظة
class ClipboardBanner extends StatefulWidget {
  final TextEditingController urlController;

  const ClipboardBanner({super.key, required this.urlController});

  @override
  State<ClipboardBanner> createState() => _ClipboardBannerState();
}

class _ClipboardBannerState extends State<ClipboardBanner> {
  @override
  Widget build(BuildContext context) {
    return Consumer<ClipboardWatcher>(
      builder: (context, watcher, _) {
        if (!watcher.hasNewUrl || watcher.lastDetectedUrl == null) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.accentPurple.withOpacity(0.15),
                AppTheme.accentBlue.withOpacity(0.15),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.accentPurple.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.accentPurple.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Iconsax.clipboard_tick, color: AppTheme.accentPurple, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (watcher.detectedPlatform != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.accentPurple.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              watcher.detectedPlatform!,
                              style: const TextStyle(fontSize: 10, color: AppTheme.accentPurple, fontWeight: FontWeight.w700),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        const Expanded(
                          child: Text(
                            'تم كشف رابط فيديو في الحافظة!',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      watcher.lastDetectedUrl!,
                      style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textDirection: TextDirection.ltr,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // زر التحميل
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    widget.urlController.text = watcher.lastDetectedUrl!;
                    watcher.dismissUrl();
                    Navigator.pushNamed(context, AppRoutes.download, arguments: {'url': watcher.lastDetectedUrl!});
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [AppTheme.accentPurple, AppTheme.accentBlue]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.download_rounded, color: Colors.white, size: 16),
                        SizedBox(width: 6),
                        Text('تحميل', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // زر الإغلاق
              InkWell(
                onTap: () => watcher.dismissUrl(),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(Icons.close_rounded, size: 18, color: AppTheme.textMuted.withOpacity(0.6)),
                ),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2, end: 0);
      },
    );
  }
}