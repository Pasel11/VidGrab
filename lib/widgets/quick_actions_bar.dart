import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../config/routes.dart';
import '../services/advanced_download_manager.dart';

class QuickActionsBar extends StatelessWidget {
  const QuickActionsBar({super.key});

  @override
  Widget build(BuildContext context) {
    final manager = context.read<AdvancedDownloadManager>();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _actionButton(
            context,
            icon: Icons.language_rounded,
            label: 'متصفح',
            color: AppTheme.accentBlue,
            onTap: () => Navigator.pushNamed(context, AppRoutes.browser),
          ),
          const SizedBox(width: 10),
          _actionButton(
            context,
            icon: Icons.swap_horiz_rounded,
            label: 'تحويل صيغة',
            color: AppTheme.accentPink,
            onTap: () {
              if (!manager.isProActive) {
                _showProDialog(context);
                return;
              }
              // Would open file picker in production
            },
            proOnly: true,
          ),
          const SizedBox(width: 10),
          _actionButton(
            context,
            icon: Iconsax.scissor,
            label: 'قص فيديو',
            color: AppTheme.warningOrange,
            onTap: () {
              if (!manager.isProActive) {
                _showProDialog(context);
                return;
              }
            },
            proOnly: true,
          ),
          const SizedBox(width: 10),
          _actionButton(
            context,
            icon: Iconsax.calendar,
            label: 'جدولة',
            color: AppTheme.successGreen,
            onTap: () => _showScheduleDialog(context),
          ),
          const SizedBox(width: 10),
          _actionButton(
            context,
            icon: Iconsax.crown,
            label: 'Pro',
            color: const Color(0xFFFFD700),
            onTap: () => Navigator.pushNamed(context, AppRoutes.pro),
            highlight: true,
          ),
        ],
      ).animate().fadeIn(duration: 500.ms, delay: 200.ms).slideX(begin: -0.1),
    );
  }

  Widget _actionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool proOnly = false,
    bool highlight = false,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: highlight
                  ? color.withOpacity(0.15)
                  : AppTheme.cardDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: highlight ? color : AppTheme.borderLight,
                width: highlight ? 1.5 : 1,
              ),
            ),
            child: Column(
              children: [
                Stack(
                  children: [
                    Icon(icon, color: color, size: 22),
                    if (proOnly)
                      Positioned(
                        top: -4, right: -6,
                        child: Icon(Iconsax.crown, color: const Color(0xFFFFD700), size: 10),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700, fontSize: 10,
                    color: highlight ? color : AppTheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showProDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFA500)]),
              ),
              child: const Icon(Iconsax.crown, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Text('ميزة Pro', style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
        content: Text('هذه الميزة متاحة فقط في النسخة Pro. قم بالترقية لفتحها.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('لاحقاً')),
          ElevatedButton(
            onPressed: () { Navigator.pop(ctx); Navigator.pushNamed(context, '/pro'); },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentPurple, foregroundColor: Colors.white),
            child: const Text('ترقية'),
          ),
        ],
      ),
    );
  }

  void _showScheduleDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.secondaryDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 40, height: 4, decoration: BoxDecoration(
                color: AppTheme.textMuted, borderRadius: BorderRadius.circular(2),
              )),
            ),
            const SizedBox(height: 20),
            Text('جدولة التحميل', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('اختر وقتاً لبدء التحميل تلقائياً', style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
            )),
            const SizedBox(height: 24),
            ...[
              _scheduleOption(ctx, Iconsax.sun_1, 'الآن', 'ابدأ فوراً', true),
              _scheduleOption(ctx, Iconsax.moon, 'اليوم 12:00 ص', 'منتصف الليل', false),
              _scheduleOption(ctx, Iconsax.wifi, 'عند توفر Wi-Fi', 'انتظر الاتصال', false),
              _scheduleOption(ctx, Iconsax.battery_charging, 'عند الشحن', 'توفير البطارية', false),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _scheduleOption(BuildContext ctx, IconData icon, String title, String subtitle, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        tileColor: isSelected ? AppTheme.accentPurple.withOpacity(0.1) : AppTheme.cardDark,
        selected: isSelected,
        leading: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.accentPurple : AppTheme.borderLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: isSelected ? Colors.white : AppTheme.textSecondary, size: 20),
        ),
        title: Text(title, style: TextStyle(
          fontWeight: FontWeight.w700, color: isSelected ? AppTheme.accentPurple : AppTheme.textPrimary,
        )),
        subtitle: Text(subtitle, style: Theme.of(ctx).textTheme.labelSmall),
        onTap: () => Navigator.pop(ctx),
      ),
    );
  }
}