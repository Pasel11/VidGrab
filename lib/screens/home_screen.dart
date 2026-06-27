import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import '../config/theme.dart';
import '../config/routes.dart';
import '../services/advanced_download_manager.dart';
import '../services/clipboard_watcher.dart';
import '../services/network_intelligence.dart';
import '../services/storage_manager.dart';
import '../models/app_database.dart';
import '../widgets/link_input_card.dart';
import '../widgets/platform_grid.dart';
import '../widgets/featured_section.dart';
import '../widgets/stats_card.dart';
import '../widgets/quick_actions_bar.dart';
import '../widgets/download_queue_indicator.dart';
import '../widgets/clipboard_banner.dart';
import '../widgets/floating_progress_widget.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final TextEditingController _urlController = TextEditingController();
  final List<Widget> _screens = [];
  bool _showNetworkInfo = false;

  @override
  void initState() {
    super.initState();
    _screens.addAll([
      _buildHomeContent(),
      const HistoryScreen(),
      const SettingsScreen(),
    ]);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initServices();
    });
  }

  Future<void> _initServices() async {
    final manager = context.read<AdvancedDownloadManager>();
    manager.checkScheduledDownloads();

    // مراقبة الحافظة
    final clipboard = context.read<ClipboardWatcher>();
    await clipboard.checkClipboardOnAppStart();
    clipboard.startWatching();

    // تحديث معلومات الشبكة
    final network = context.read<NetworkIntelligence>();
    await network.init();

    // تحديث معلومات التخزين
    final storage = context.read<StorageManager>();
    await storage.refreshStorageInfo();

    setState(() {});
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Widget _buildHomeContent() {
    return Consumer<AdvancedDownloadManager>(
      builder: (context, manager, _) => Stack(
        children: [
          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildHeader(manager)),
                // بانر الحافظة الذكي
                SliverToBoxAdapter(child: ClipboardBanner(urlController: _urlController)),
                // Download queue indicator
                if (manager.activeTasks.isNotEmpty || manager.queuedTasks.isNotEmpty)
                  const SliverToBoxAdapter(child: DownloadQueueIndicator()),
                const SliverToBoxAdapter(child: SizedBox(height: 8)),
                // حقل الرابط
                SliverToBoxAdapter(child: LinkInputCard(controller: _urlController)),
                const SliverToBoxAdapter(child: SizedBox(height: 20)),
                // معلومة الشبكة السريعة
                Consumer<NetworkIntelligence>(
                  builder: (context, network, _) {
                    if (!network.isConnected) {
                      return SliverToBoxAdapter(child: _buildOfflineBanner());
                    }
                    return const SliverToBoxAdapter(child: SizedBox.shrink());
                  },
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 8)),
                // إجراءات سريعة
                const SliverToBoxAdapter(child: QuickActionsBar()),
                const SliverToBoxAdapter(child: SizedBox(height: 20)),
                // إحصائيات
                const SliverToBoxAdapter(child: StatsCards()),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
                // شبكة المنصات
                SliverToBoxAdapter(child: PlatformGrid(onPasteUrl: _handlePasteUrl)),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
                // القسم المميز
                const SliverToBoxAdapter(child: FeaturedSection()),
                // التحميلات الأخيرة
                if (manager.completedTasks.isNotEmpty) ...[
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                  SliverToBoxAdapter(child: _buildRecentDownloads(manager)),
                ],
                // إحصائيات التخزين
                Consumer<StorageManager>(
                  builder: (context, storage, _) {
                    if (storage.isLowStorage) {
                      return SliverToBoxAdapter(child: _buildStorageWarning(storage));
                    }
                    return const SliverToBoxAdapter(child: SizedBox.shrink());
                  },
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 140)),
              ],
            ),
          ),
          // شريط التقدم العائم
          const FloatingProgressWidget(),
        ],
      ),
    );
  }

  Widget _buildOfflineBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.errorRed.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.errorRed.withOpacity(0.2)),
      ),
      child: const Row(
        children: [
          Icon(Icons.wifi_off_rounded, color: AppTheme.errorRed, size: 18),
          SizedBox(width: 10),
          Text('لا يوجد اتصال بالإنترنت', style: TextStyle(color: AppTheme.errorRed, fontSize: 13, fontWeight: FontWeight.w600)),
          Spacer(),
          Text('التحميلات المتوقفة', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildStorageWarning(StorageManager storage) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.warningOrange.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.warningOrange.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.storage_rounded, color: AppTheme.warningOrange, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('المساحة التخزينية منخفضة', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.warningOrange)),
                const SizedBox(height: 4),
                Text(storage.storageWarning, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: storage.usagePercentage / 100,
                    backgroundColor: AppTheme.borderLight,
                    valueColor: const AlwaysStoppedAnimation(AppTheme.warningOrange),
                    minHeight: 4,
                  ),
                ),
                const SizedBox(height: 4),
                Text('${storage.usagePercentage.toStringAsFixed(1)}% مستخدم | متاح: ${storage.getAvailableSpaceText()}', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildHeader(AdvancedDownloadManager manager) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: const LinearGradient(
                        colors: [AppTheme.accentPurple, AppTheme.accentBlue],
                      ),
                    ),
                    child: const Icon(Icons.download_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Row(
                    children: [
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [AppTheme.accentPurple, AppTheme.accentCyan],
                        ).createShader(bounds),
                        child: const Text('VidGrab', style: TextStyle(
                          fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white,
                        )),
                      ),
                      // Pro badge
                      if (manager.isProActive) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFA500)]),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Iconsax.crown, color: Colors.white, size: 10),
                              SizedBox(width: 3),
                              Text('Pro', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text('الصق الرابط وحمّل أي فيديو فوراً',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary, fontSize: 13,
                ),
              ),
            ],
          ),
          Row(
            children: [
              // زر المتصفح
              _headerButton(Icons.language_rounded, 'المتصفح', () {
                Navigator.pushNamed(context, AppRoutes.browser);
              }),
              const SizedBox(width: 8),
              // زر المكتبة
              _headerButton(Iconsax.folder, 'المكتبة', () {
                Navigator.pushNamed(context, AppRoutes.library);
              }),
              const SizedBox(width: 8),
              // تبديل السمة
              Consumer<ThemeNotifier>(
                builder: (context, theme, _) => _headerButton(
                  theme.themeMode == ThemeMode.dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                  '',
                  () => theme.toggleTheme(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerButton(IconData icon, String tooltip, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.borderLight),
        ),
        child: Icon(icon, color: AppTheme.accentPurple, size: 20),
      ),
    );
  }

  Widget _buildRecentDownloads(AdvancedDownloadManager manager) {
    final recent = manager.completedTasks.take(5).toList();
    final stats = manager.getDetailedStats();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('التحميلات الأخيرة', style: Theme.of(context).textTheme.titleMedium),
              Row(
                children: [
                  // إحصائية سريعة
                  if (stats['todayBytes'] as int > 0) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: AppTheme.accentCyan.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                      child: Text('اليوم: ${stats['todayBytesText']}', style: const TextStyle(fontSize: 10, color: AppTheme.accentCyan, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 8),
                  ],
                  TextButton(
                    onPressed: () => setState(() => _currentIndex = 1),
                    child: Text('عرض الكل', style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppTheme.accentPurple, fontWeight: FontWeight.w700,
                    )),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...recent.asMap().entries.map((entry) {
            final task = entry.value;
            final speed = manager.getTaskSpeed(task.id);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  Navigator.pushNamed(context, AppRoutes.conversion, arguments: {
                    'task': task, 'filePath': task.filePath,
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.cardDark,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.borderLight),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(
                            colors: _getPlatformGradient(task.platform),
                          ),
                        ),
                        child: const Icon(Icons.videocam_rounded, color: Colors.white70, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                if (task.isFavorite) const Padding(
                                  padding: EdgeInsets.only(left: 4),
                                  child: Icon(Icons.star_rounded, color: Color(0xFFFFD700), size: 12),
                                ),
                                Expanded(
                                  child: Text(task.title, style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600, fontSize: 13,
                                  ), maxLines: 1, overflow: TextOverflow.ellipsis),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                Text(task.platform, style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: AppTheme.accentPurple, fontWeight: FontWeight.w600,
                                )),
                                const Text('  •  ', style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                                Text(task.quality, style: Theme.of(context).textTheme.labelSmall),
                                const Text('  •  ', style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                                Text(manager.formatBytes(task.fileSizeBytes), style: Theme.of(context).textTheme.labelSmall),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_left_rounded, color: AppTheme.textMuted, size: 20),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  List<Color> _getPlatformGradient(String platform) {
    switch (platform.toLowerCase()) {
      case 'youtube': return [const Color(0xFFFF0000), const Color(0xFFCC0000)];
      case 'instagram': return [const Color(0xFFE4405F), const Color(0xFFF77737)];
      case 'tiktok': return [const Color(0xFF25F4EE), const Color(0xFFFE2C55)];
      case 'facebook': return [const Color(0xFF1877F2), const Color(0xFF0C5DC7)];
      case 'twitter': case 'x (twitter)': return [const Color(0xFF1DA1F2), const Color(0xFF0D8BD9)];
      case 'twitch': return [const Color(0xFF9146FF), const Color(0xFF6441A5)];
      case 'soundcloud': return [const Color(0xFFFF5500), const Color(0xFFCC4400)];
      case 'telegram': return [const Color(0xFF0088CC), const Color(0xFF006699)];
      case 'whatsapp': return [const Color(0xFF25D366), const Color(0xFF128C7E)];
      default: return [AppTheme.accentPurple, AppTheme.accentBlue];
    }
  }

  void _handlePasteUrl() async {
    final data = await Clipboard.getData('text/plain');
    if (data?.text != null && data!.text!.isNotEmpty) {
      _urlController.text = data.text!;
    }
  }

  void _onTabTapped(int index) => setState(() => _currentIndex = index);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        decoration: BoxDecoration(
          color: AppTheme.secondaryDark,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
          ],
          border: Border.all(color: AppTheme.borderLight),
        ),
        child: NavigationBar(
          height: 64,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedIndex: _currentIndex,
          onDestinationSelected: _onTabTapped,
          indicatorColor: AppTheme.accentPurple.withOpacity(0.15),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            NavigationDestination(
              icon: Consumer<AdvancedDownloadManager>(
                builder: (context, manager, _) {
                  final count = manager.pendingCount;
                  return Badge(
                    isLabelVisible: count > 0,
                    label: Text(count.toString(), style: const TextStyle(fontSize: 8, color: Colors.white)),
                    backgroundColor: AppTheme.accentPurple,
                    child: const Icon(Iconsax.home_2, size: 24),
                  );
                },
              ),
              selectedIcon: const Icon(Iconsax.home_21, size: 24, color: AppTheme.accentPurple),
              label: 'الرئيسية',
            ),
            NavigationDestination(
              icon: Consumer<AdvancedDownloadManager>(
                builder: (context, manager, _) {
                  final failedCount = manager.failedTasks.length;
                  return Badge(
                    isLabelVisible: failedCount > 0,
                    label: Text(failedCount.toString(), style: const TextStyle(fontSize: 8, color: Colors.white)),
                    backgroundColor: AppTheme.errorRed,
                    child: const Icon(Iconsax.clock, size: 24),
                  );
                },
              ),
              selectedIcon: const Icon(Iconsax.clock1, size: 24, color: AppTheme.accentPurple),
              label: 'السجل',
            ),
            NavigationDestination(
              icon: const Icon(Iconsax.setting_2, size: 24),
              selectedIcon: const Icon(Iconsax.setting_21, size: 24, color: AppTheme.accentPurple),
              label: 'الإعدادات',
            ),
          ],
        ),
      ),
    );
  }
}