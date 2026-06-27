import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/theme.dart';

class FeaturedSection extends StatelessWidget {
  const FeaturedSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text('لماذا VidGrab؟', style: Theme.of(context).textTheme.titleMedium),
          ),
          const SizedBox(height: 14),
          _FeatureCard(
            icon: Icons.bolt_rounded,
            iconColor: AppTheme.warningOrange,
            title: 'سرعة فائقة',
            description: 'تحميل سريع جداً بفضل تقنيات التحسين المتقدمة',
            gradient: [AppTheme.warningOrange.withOpacity(0.08), AppTheme.accentPink.withOpacity(0.03)],
          ),
          const SizedBox(height: 12),
          _FeatureCard(
            icon: Icons.shield_rounded,
            iconColor: AppTheme.successGreen,
            title: 'آمن وخاص',
            description: 'لا نخزن أي بيانات شخصية. خصوصيتك أولويتنا',
            gradient: [AppTheme.successGreen.withOpacity(0.08), AppTheme.accentCyan.withOpacity(0.03)],
          ),
          const SizedBox(height: 12),
          _FeatureCard(
            icon: Icons.hd_rounded,
            iconColor: AppTheme.accentPurple,
            title: 'جودة عالية',
            description: 'ادعم تحميل الفيديوهات بجودة تصل إلى 4K Ultra HD',
            gradient: [AppTheme.accentPurple.withOpacity(0.08), AppTheme.accentBlue.withOpacity(0.03)],
          ),
        ],
      ).animate().fadeIn(duration: 500.ms, delay: 400.ms).slideY(begin: 0.1, end: 0),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final List<Color> gradient;

  const _FeatureCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft, colors: gradient),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w700, fontSize: 15,
                )),
                const SizedBox(height: 4),
                Text(description, style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary, height: 1.4,
                )),
              ],
            ),
          ),
          Icon(Icons.chevron_left_rounded, color: AppTheme.textMuted, size: 20),
        ],
      ),
    );
  }
}