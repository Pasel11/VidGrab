import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import '../config/theme.dart';
import '../config/routes.dart';
import '../services/advanced_download_manager.dart';
import 'package:share_plus/share_plus.dart';

/// شريط التقدم العائم - يظهر عند وجود تحميلات نشطة
/// يمكن سحبه وإغلاقه ويعرض الإحصائيات
class FloatingProgressWidget extends StatefulWidget {
  const FloatingProgressWidget({super.key});

  @override
  State<FloatingProgressWidget> createState() => _FloatingProgressWidgetState();
}

class _FloatingProgressWidgetState extends State<FloatingProgressWidget>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _controller;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _expandAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdvancedDownloadManager>(
      builder: (context, manager, _) {
        final activeCount = manager.activeTasks.length + manager.queuedTasks.length;
        if (activeCount == 0) return const SizedBox.shrink();

        return Positioned(
          bottom: 100,
          left: 16,
          right: 16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // البطاقة الموسعة
              if (_isExpanded) ...[
                SizeTransition(
                  sizeFactor: _expandAnimation,
                  child: _buildExpandedCard(manager),
                ),
                const SizedBox(height: 8),
              ],
              // الشريط المضغوط
              _buildCompactBar(manager, activeCount),
            ],
          ),
        ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.3, end: 0);
      },
    );
  }

  Widget _buildCompactBar(AdvancedDownloadManager manager, int activeCount) {
    // حساب إجمالي التقدم
    double totalProgress = 0;
    int count = 0;
    for (final task in manager.activeTasks) {
      totalProgress += task.progress;
      count++;
    }

    final avgProgress = count > 0 ? totalProgress / count : 0.0;

    return GestureDetector(
      onTap: _toggleExpand,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.secondaryDark,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.accentPurple.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: AppTheme.accentPurple.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            // متحرك دائري
            SizedBox(
              width: 36, height: 36,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: avgProgress,
                    strokeWidth: 3,
                    backgroundColor: AppTheme.borderLight,
                    valueColor: const AlwaysStoppedAnimation(AppTheme.accentPurple),
                  ),
                  Center(
                    child: Text(
                      '${(avgProgress * 100).toInt()}%',
                      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // النص
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$activeCount تحميل${activeCount > 1 ? 'ات' : ''} جارٍ',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.speed_rounded, size: 12, color: AppTheme.accentCyan),
                      const SizedBox(width: 4),
                      Text(manager.totalSpeedText, style: const TextStyle(fontSize: 11, color: AppTheme.accentCyan, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 12),
                      const Icon(Icons.schedule_rounded, size: 12, color: AppTheme.textMuted),
                      const SizedBox(width: 4),
                      Text(manager.totalRemainingTime, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                    ],
                  ),
                ],
              ),
            ),
            // أزرار
            if (activeCount > 0)
              _miniButton(
                manager.activeTasks.isNotEmpty ? Icons.pause_rounded : Icons.play_arrow_rounded,
                AppTheme.warningOrange,
                () => manager.activeTasks.isNotEmpty ? manager.pauseAllDownloads() : manager.resumeAllDownloads(),
              ),
            const SizedBox(width: 6),
            _miniButton(Iconsax.close_circle, AppTheme.textMuted, () {
              // لا يغلق - فقط يخفي التفاصيل
              if (_isExpanded) _toggleExpand();
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedCard(AdvancedDownloadManager manager) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.secondaryDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // العنوان
          Row(
            children: [
              const Icon(Icons.downloading_rounded, color: AppTheme.accentPurple, size: 20),
              const SizedBox(width: 8),
              const Text('التحميلات النشطة', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
              const Spacer(),
              Text(manager.totalSpeedText, style: const TextStyle(fontSize: 12, color: AppTheme.accentCyan, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          // قائمة التحميلات النشطة
          ...manager.activeTasks.map((task) => _buildActiveTaskItem(manager, task)),
          if (manager.queuedTasks.isNotEmpty) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.schedule_rounded, size: 14, color: AppTheme.textMuted),
                  const SizedBox(width: 6),
                  Text('${manager.queuedTasks.length} في الانتظار', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          // إحصائيات سريعة
          _buildQuickStats(manager),
        ],
      ),
    );
  }

  Widget _buildActiveTaskItem(AdvancedDownloadManager manager, dynamic task) {
    final speed = manager.getTaskSpeed(task.id);
    final eta = manager.getTaskETA(task.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: AppTheme.cardDark, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  task.title,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
              ),
              Text('${(task.progress * 100).toInt()}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.accentPurple)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: task.progress,
                    backgroundColor: AppTheme.borderLight,
                    valueColor: const AlwaysStoppedAnimation(AppTheme.accentPurple),
                    minHeight: 4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(task.platform, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
              if (speed > 0)
                Text('${manager.formatSpeed(speed)} | متبقي: $eta', style: const TextStyle(fontSize: 10, color: AppTheme.accentCyan, fontWeight: FontWeight.w500)),
              Text(manager.formatBytes(task.fileSizeBytes), style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(AdvancedDownloadManager manager) {
    final stats = manager.getDetailedStats();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _statItem(Icons.check_circle_rounded, '${stats['completed']}', 'مكتمل', AppTheme.successGreen),
        _statItem(Icons.downloading_rounded, '${stats['inProgress']}', 'جارٍ', AppTheme.accentPurple),
        _statItem(Icons.error_rounded, '${stats['failed']}', 'فشل', AppTheme.errorRed),
        _statItem(Icons.data_usage_rounded, stats['todayBytesText'] as String, 'اليوم', AppTheme.accentCyan),
      ],
    );
  }

  Widget _statItem(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
        Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
      ],
    );
  }

  Widget _miniButton(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }
}