import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import '../config/theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('الإعدادات', style: Theme.of(context).textTheme.titleLarge),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(context, 'المظهر'),
            _buildSettingsCard(context, [
              _SettingItem(
                icon: Iconsax.moon,
                iconColor: AppTheme.accentPurple,
                title: 'الوضع الداكن',
                subtitle: 'تفعيل المظهر الداكن للتطبيق',
                trailing: Consumer<ThemeNotifier>(
                  builder: (context, theme, _) => Switch(
                    value: theme.themeMode == ThemeMode.dark,
                    onChanged: (_) => theme.toggleTheme(),
                    activeColor: AppTheme.accentPurple,
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 24),
            _buildSectionHeader(context, 'التحميل'),
            _buildSettingsCard(context, [
              _SettingItem(
                icon: Icons.high_quality_rounded,
                iconColor: AppTheme.accentBlue,
                title: 'الجودة الافتراضية',
                subtitle: 'اختر جودة التحميل المفضلة',
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.accentBlue.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('1080p', style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppTheme.accentBlue, fontWeight: FontWeight.w600,
                  )),
                ),
              ),
              const _SettingDivider(),
              _SettingItem(
                icon: Iconsax.folder,
                iconColor: AppTheme.accentCyan,
                title: 'مجلد التحميل',
                subtitle: 'VidGrab/Downloads',
                trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted, size: 20),
              ),
              const _SettingDivider(),
              _SettingItem(
                icon: Iconsax.wifi,
                iconColor: AppTheme.successGreen,
                title: 'التحميل عبر Wi-Fi فقط',
                subtitle: 'توفير بيانات الإنترنت',
                trailing: Switch(value: true, onChanged: (_) {}, activeColor: AppTheme.successGreen),
              ),
              const _SettingDivider(),
              _SettingItem(
                icon: Iconsax.notification,
                iconColor: AppTheme.warningOrange,
                title: 'إشعارات التحميل',
                subtitle: 'إشعار عند اكتمال التحميل',
                trailing: Switch(value: true, onChanged: (_) {}, activeColor: AppTheme.warningOrange),
              ),
            ]),
            const SizedBox(height: 24),
            _buildSectionHeader(context, 'عن التطبيق'),
            _buildSettingsCard(context, [
              _buildAppInfo(context),
              const SizedBox(height: 16),
              _SettingItem(
                icon: Iconsax.star,
                iconColor: AppTheme.warningOrange,
                title: 'قيّم التطبيق',
                subtitle: 'ساعدنا بالتقييم على المتجر',
                trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted, size: 20),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('قريباً على المتجر')));
                },
              ),
              const _SettingDivider(),
              _SettingItem(
                icon: Iconsax.share,
                iconColor: AppTheme.accentPink,
                title: 'مشاركة التطبيق',
                subtitle: 'أخبر أصدقائك عن VidGrab',
                trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted, size: 20),
              ),
              const _SettingDivider(),
              _SettingItem(
                icon: Icons.verified_user_rounded,
                iconColor: AppTheme.successGreen,
                title: 'سياسة الخصوصية',
                subtitle: 'كيف نحمي بياناتك',
                trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted, size: 20),
              ),
            ]),
            const SizedBox(height: 32),
            Center(
              child: Text('VidGrab v2.0.0', style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppTheme.textMuted,
              )),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(
        color: AppTheme.textSecondary, fontWeight: FontWeight.w600, letterSpacing: 0.5,
      )),
    );
  }

  Widget _buildSettingsCard(BuildContext context, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildAppInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.accentPurple.withOpacity(0.1), AppTheme.accentBlue.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(colors: [AppTheme.accentPurple, AppTheme.accentBlue]),
            ),
            child: const Icon(Icons.download_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('VidGrab', style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800, fontSize: 20,
                )),
                const SizedBox(height: 4),
                Text('الإصدار 2.0.0', style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: Theme.of(context).textTheme.labelSmall),
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

class _SettingDivider extends StatelessWidget {
  const _SettingDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 70),
      child: Divider(color: AppTheme.borderLight, height: 1),
    );
  }
}