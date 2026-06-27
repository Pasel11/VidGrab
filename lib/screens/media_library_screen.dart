import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import '../config/theme.dart';
import '../services/advanced_download_manager.dart';
import '../models/app_database.dart';

class MediaLibraryScreen extends StatefulWidget {
  const MediaLibraryScreen({super.key});

  @override
  State<MediaLibraryScreen> createState() => _MediaLibraryScreenState();
}

class _MediaLibraryScreenState extends State<MediaLibraryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  String _selectedFolder = 'الكل';
  String _sortBy = 'date'; // date, size, name, platform
  bool _showFavoritesOnly = false;

  final List<String> _folders = [
    'الكل', 'عام', 'تعليم', 'ترفيه', 'رياضة', 'موسيقى', 'أخبار', 'تقنية',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<DownloadTaskEntity> _getFilteredTasks() {
    final manager = context.read<AdvancedDownloadManager>();
    List<DownloadTaskEntity> tasks = manager.completedTasks;

    if (_showFavoritesOnly) {
      tasks = tasks.where((t) => t.isFavorite).toList();
    }

    if (_selectedFolder != 'الكل') {
      tasks = tasks.where((t) => t.folder == _selectedFolder).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      tasks = tasks.where((t) =>
        t.title.toLowerCase().contains(query) ||
        t.platform.toLowerCase().contains(query)
      ).toList();
    }

    switch (_sortBy) {
      case 'size':
        tasks.sort((a, b) => b.fileSizeBytes.compareTo(a.fileSizeBytes));
        break;
      case 'name':
        tasks.sort((a, b) => a.title.compareTo(b.title));
        break;
      case 'platform':
        tasks.sort((a, b) => a.platform.compareTo(b.platform));
        break;
      default: // date
        tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    return tasks;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('مكتبة الوسائط', style: Theme.of(context).textTheme.titleLarge),
        centerTitle: true,
        actions: [
          Consumer<AdvancedDownloadManager>(
            builder: (context, manager, _) => PopupMenuButton<String>(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.cardDark, borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderLight),
                ),
                child: const Icon(Icons.sort_rounded, size: 18, color: AppTheme.textPrimary),
              ),
              onSelected: (value) => setState(() => _sortBy = value),
              itemBuilder: (_) => [
                _popupItem('التاريخ', 'date', Icons.calendar_today_rounded),
                _popupItem('الحجم', 'size', Icons.storage_rounded),
                _popupItem('الاسم', 'name', Icons.sort_by_alpha_rounded),
                _popupItem('المنصة', 'platform', Icons.public_rounded),
              ],
            ),
          ),
          const SizedBox(width: 4),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.accentPurple,
          indicatorSize: TabBarIndicatorSize.label,
          labelColor: AppTheme.accentPurple,
          unselectedLabelColor: AppTheme.textMuted,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: const [
            Tab(text: 'الكل'),
            Tab(text: 'المفضلة'),
            Tab(text: 'مجلدات'),
            Tab(text: 'سري'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              onChanged: (q) => setState(() => _searchQuery = q),
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              decoration: InputDecoration(
                hintText: 'ابحث في مكتبتك...',
                prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textMuted, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18, color: AppTheme.textMuted),
                        onPressed: () => setState(() => _searchQuery = ''),
                      )
                    : null,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ),
          // Folder chips (for folder tab)
          if (_tabController.index == 2)
            SizedBox(
              height: 48,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _folders.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final folder = _folders[index];
                  final isSelected = _selectedFolder == folder;
                  return FilterChip(
                    selected: isSelected,
                    label: Text(folder),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppTheme.textSecondary,
                      fontSize: 12, fontWeight: FontWeight.w600,
                    ),
                    backgroundColor: AppTheme.cardDark,
                    selectedColor: AppTheme.accentPurple,
                    checkmarkColor: Colors.white,
                    side: BorderSide(color: isSelected ? AppTheme.accentPurple : AppTheme.borderLight),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    onSelected: (_) => setState(() => _selectedFolder = folder),
                  );
                },
              ),
            ),
          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMediaGrid(context, _getFilteredTasks()),
                _buildMediaGrid(context, context.read<AdvancedDownloadManager>().getFavoriteTasks()),
                _buildMediaGrid(context, _getFilteredTasks()),
                _buildSecretFolder(context),
              ],
            ),
          ),
        ],
      ),
      // FAB for new folder
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showNewFolderDialog(context),
        backgroundColor: AppTheme.accentPurple,
        icon: const Icon(Icons.create_new_folder_rounded, color: Colors.white),
        label: const Text('مجلد جديد', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildMediaGrid(BuildContext context, List<DownloadTaskEntity> tasks) {
    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.video_remove, size: 70, color: AppTheme.textMuted.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text('لا توجد ملفات', style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.textSecondary,
            )),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.72,
      ),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        return _MediaCard(task: tasks[index], index: index);
      },
    );
  }

  Widget _buildSecretFolder(BuildContext context) {
    final manager = context.read<AdvancedDownloadManager>();
    if (!manager.isProActive) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(colors: [AppTheme.accentPurple.withOpacity(0.2), AppTheme.accentPink.withOpacity(0.1)]),
              ),
              child: const Icon(Iconsax.lock_circle, size: 40, color: AppTheme.accentPurple),
            ),
            const SizedBox(height: 20),
            Text('المجلد السري', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('ترقية إلى Pro لفتح المجلد السري', style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/pro'),
              icon: const Icon(Iconsax.crown, color: Colors.white),
              label: const Text('ترقية إلى Pro'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      );
    }

    return _buildMediaGrid(context, manager.getSecretTasks());
  }

  void _showNewFolderDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('مجلد جديد', style: Theme.of(context).textTheme.titleMedium),
        content: TextField(
          controller: controller,
          textAlign: TextAlign.right,
          decoration: const InputDecoration(hintText: 'اسم المجلد'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                setState(() {
                  if (!_folders.contains(controller.text)) {
                    _folders.add(controller.text);
                  }
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('إنشاء', style: TextStyle(color: AppTheme.accentPurple, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _popupItem(String label, String value, IconData icon) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.textSecondary),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }
}

class _MediaCard extends StatelessWidget {
  final DownloadTaskEntity task;
  final int index;

  const _MediaCard({required this.task, required this.index});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => _showMediaOptions(context),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.borderLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _getPlatformGradient(task.platform),
                    ),
                  ),
                  child: Stack(
                    children: [
                      Center(child: Icon(Icons.videocam_rounded, color: Colors.white.withOpacity(0.5), size: 36)),
                      if (task.isFavorite)
                        const Positioned(top: 8, right: 8, child: Icon(Icons.star_rounded, color: AppTheme.warningOrange, size: 18)),
                      if (task.isSecret)
                        const Positioned(top: 8, left: 8, child: Icon(Icons.lock_rounded, color: Colors.white54, size: 16)),
                      Positioned(
                        bottom: 8, left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            task.format,
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700, fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(task.quality, style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppTheme.accentPurple, fontWeight: FontWeight.w600,
                        )),
                        const Spacer(),
                        Text(
                          _formatSize(task.fileSizeBytes),
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate(delay: Duration(milliseconds: index * 60)).fadeIn(duration: 300.ms).scale(begin: const Offset(0.9, 0.9));
  }

  List<Color> _getPlatformGradient(String platform) {
    switch (platform.toLowerCase()) {
      case 'youtube': return [const Color(0xFFFF0000), const Color(0xFFCC0000)];
      case 'instagram': return [const Color(0xFFE4405F), const Color(0xFFF77737)];
      case 'tiktok': return [const Color(0xFF25F4EE), const Color(0xFFFE2C55)];
      default: return [AppTheme.accentPurple, AppTheme.accentBlue];
    }
  }

  String _formatSize(int bytes) {
    if (bytes <= 0) return 'N/A';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  void _showMediaOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.secondaryDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(
                color: AppTheme.textMuted, borderRadius: BorderRadius.circular(2),
              )),
              const SizedBox(height: 16),
              Text(task.title, style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center, maxLines: 2),
              const SizedBox(height: 20),
              _optionTile(ctx, Icons.play_circle_rounded, AppTheme.accentPurple, 'تشغيل', () {}),
              _optionTile(ctx, Iconsax.share, AppTheme.accentBlue, 'مشاركة', () {}),
              _optionTile(ctx, Icons.swap_horiz_rounded, AppTheme.successGreen, 'تحويل صيغة', () {}),
              _optionTile(ctx, Iconsax.scissor, AppTheme.warningOrange, 'قص الفيديو', () {}),
              _optionTile(ctx, task.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                AppTheme.warningOrange, task.isFavorite ? 'إزالة من المفضلة' : 'إضافة للمفضلة', () {}),
              _optionTile(ctx, Iconsax.folder, AppTheme.accentCyan, 'نقل إلى مجلد', () {}),
              _optionTile(ctx, Iconsax.copy, AppTheme.textSecondary, 'نسخ الرابط', () {}),
              _optionTile(ctx, Icons.delete_outline_rounded, AppTheme.errorRed, 'حذف', () {
                Navigator.pop(ctx);
                context.read<AdvancedDownloadManager>().deleteTask(task.id);
              }),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _optionTile(BuildContext ctx, IconData icon, Color color, String label, VoidCallback onTap) {
    return ListTile(
      leading: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}