import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/theme.dart';

class StatsCards extends StatelessWidget {
  const StatsCards({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(child: _StatCard(
            icon: Icons.download_done_rounded,
            iconColor: AppTheme.successGreen,
            label: 'تم التحميل',
            value: '1,247',
            gradient: [AppTheme.successGreen.withOpacity(0.12), AppTheme.successGreen.withOpacity(0.04)],
          )),
          const SizedBox(width: 12),
          Expanded(child: _StatCard(
            icon: Icons.branding_watermark_rounded,
            iconColor: AppTheme.accentBlue,
            label: 'المنصات',
            value: '12+',
            gradient: [AppTheme.accentBlue.withOpacity(0.12), AppTheme.accentBlue.withOpacity(0.04)],
          )),
          const SizedBox(width: 12),
          Expanded(child: _StatCard(
            icon: Icons.speed_rounded,
            iconColor: AppTheme.accentPink,
            label: 'سرعة عالية',
            value: 'سريع',
            gradient: [AppTheme.accentPink.withOpacity(0.12), AppTheme.accentPink.withOpacity(0.04)],
          )),
        ],
      ).animate().fadeIn(duration: 600.ms, delay: 200.ms).slideY(begin: 0.15, end: 0),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final List<Color> gradient;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(height: 10),
          Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800, color: iconColor, fontSize: 20,
          )),
          const SizedBox(height: 2),
          Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppTheme.textSecondary,
          )),
        ],
      ),
    );
  }
}