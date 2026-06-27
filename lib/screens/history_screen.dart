import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:share_plus/share_plus.dart';
import '../config/theme.dart';
import '../services/advanced_download_manager.dart';
import '../models/app_database.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with TickerProviderStateMixin {
  String _searchQuery = '';
  String? _filterPlatform;
  int? _filterStatus;
  bool _showFilters = false;
  final Set<String> _selectedIds = {};
  bool _isSelectionMode = false;
  String _sortBy = 'newest'; // newest, oldest, largest, smallest, name

  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<DownloadTaskEntity> _getFilteredTasks(AdvancedDownloadManager manager) {
    var tasks = manager.searchTasks(
      _searchQuery,
      filterPlatform: _filterPlatform,
      filterStatus: _filterStatus,
    );

    // ترتيب
    switch (_sortBy) {
      case 'oldest':
        tasks.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case 'largest':
        tasks.sort((a, b) => b.fileSizeBytes.compareTo(a.fileSizeBytes));
        break;
      case 'smallest':
        tasks.sort((a, b) => a.fileSizeBytes.compareTo(b.fileSizeBytes));
        break;
      case 'name':
        tasks.sort((a, b) => a.title.compareTo(b.title));
        break;
      default: // newest
        tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    return tasks;
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) _isSelectionMode = false;
      } else {
        _selectedIds.add(id);
        _isSelectionMode = true;
      }
    });
  }

  void _selectAll(List<DownloadTaskEntity> tasks) {
    setState(() {
      _selectedIds.clear();
      for (final t in tasks) {
        _selectedIds.add(t.id);
      }
      _isSelectionMode = _selectedIds.isNotEmpty;
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedIds.clear();
      _isSelectionMode = false;
    });
  }

  void _deleteSelected(AdvancedDownloadManager manager) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('حذف التحديد', style: TextStyle(color: AppTheme.textPrimary)),
        content: Text('هل تريد حذف ${_selectedIds.length} عنصر؟', style: const TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حذف', style: TextStyle(color: AppTheme.errorRed))),
        ],
      ),
    );
    if (confirmed == true) {
      await manager.deleteMultiple(_selectedIds.toList());
      _clearSelection();
    }
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.secondaryDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.textMuted.withOpacity(0.3), borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            const Text('ترتيب حسب', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
            const SizedBox(height: 12),
            _sortOption(ctx, 'الأحدث', 'newest', Icons.access_time_rounded),
            _sortOption(ctx, 'الأقدم', 'oldest', Icons.history_rounded),
            _sortOption(ctx, 'الأكبر حجماً', 'largest', Icons.data_usage_rounded),
            _sortOption(ctx, 'الأصغر حجماً', 'smallest', Icons.data_usage_rounded),
            _sortOption(ctx, 'الاسم', 'name', Icons.sort_by_alpha_rounded),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _sortOption(BuildContext ctx, String label, String value, IconData icon) {
    final isSelected = _sortBy == value;
    return ListTile(
      leading: Icon(icon, color: isSelected ? AppTheme.accentPurple : AppTheme.textSecondary),
      title: Text(label, style: TextStyle(color: isSelected ? AppTheme.accentPurple : AppTheme.textPrimary, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400)),
      trailing: isSelected ? const Icon(Icons.check_rounded, color: AppTheme.accentPurple, size: 20) : null,
      onTap: () { setState(() => _sortBy = value); Navigator.pop(ctx); },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdvancedDownloadManager>(
      builder: (context, manager, _) {
        final tasks = _getFilteredTasks(manager);
        final platforms = manager.getUsedPlatforms();

        return Column(
          children: [
            // شريط البحث والفلاتر
            _buildSearchBar(manager, tasks.length, platforms),
            // الفلاتر الموسعة
            if (_showFilters) _buildFilterChips(manager, platforms),
            // شريط التحديد
            if (_isSelectionMode) _buildSelectionBar(manager),
            // القائمة
            Expanded(
              child: tasks.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                      itemCount: tasks.length,
                      itemBuilder: (context, index) {
                        final task = tasks[index];
                        return _buildTaskCard(context, task, manager)
                            .animate(delay: Duration(milliseconds: index * 60))
                            .fadeIn(duration: 300.ms).slideX(begin: 0.05, end: 0);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchBar(AdvancedDownloadManager manager, int resultCount, List<String> platforms) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.cardDark,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v),
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                textAlign: TextAlign.right,
                textDirection: TextDirection.ltr,
                decoration: InputDecoration(
                  hintText: 'ابحث في التحميلات...',
                  hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                  prefixIcon: _searchQuery.isNotEmpty
                      ? IconButton(icon: const Icon(Icons.close_rounded, size: 18, color: AppTheme.textMuted), onPressed: () { _searchController.clear(); setState(() => _searchQuery = ''); })
                      : null,
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (platforms.isNotEmpty)
                        IconButton(
                          icon: Icon(_showFilters ? Icons.filter_list_rounded : Icons.filter_list, size: 20, color: _showFilters ? AppTheme.accentPurple : AppTheme.textSecondary),
                          onPressed: () => setState(() => _showFilters = !_showFilters),
                        ),
                      const SizedBox(width: 4),
                    ],
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // زر الترتيب
          InkWell(
            onTap: _showSortOptions,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppTheme.cardDark, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.borderLight)),
              child: const Icon(Icons.sort_rounded, size: 20, color: AppTheme.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(AdvancedDownloadManager manager, List<String> platforms) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // فلتر الحالة
          _filterChip('الكل', _filterStatus == null, () => setState(() => _filterStatus = null)),
          _filterChip('مكتمل', _filterStatus == 3, () => setState(() => _filterStatus = _filterStatus == 3 ? null : 3)),
          _filterChip('جارٍ', _filterStatus == 2, () => setState(() => _filterStatus = _filterStatus == 2 ? null : 2)),
          _filterChip('فشل', _filterStatus == 4, () => setState(() => _filterStatus = _filterStatus == 4 ? null : 4)),
          _filterChip('مؤقت', _filterStatus == 5, () => setState(() => _filterStatus = _filterStatus == 5 ? null : 5)),
          const SizedBox(width: 8),
          // فلتر المنصة
          ...platforms.map((p) => _filterChip(p, _filterPlatform == p, () => setState(() => _filterPlatform = _filterPlatform == p ? null : p))),
        ],
      ),
    );
  }

  Widget _filterChip(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: FilterChip(
        label: Text(label, style: TextStyle(fontSize: 12, color: selected ? Colors.white : AppTheme.textSecondary, fontWeight: selected ? FontWeight.w600 : FontWeight.w400)),
        selected: selected,
        onSelected: (_) => onTap(),
        backgroundColor: AppTheme.cardDark,
        selectedColor: AppTheme.accentPurple,
        side: BorderSide(color: selected ? AppTheme.accentPurple : AppTheme.borderLight),
        showCheckmark: false,
        padding: EdgeInsets.zero,
        labelPadding: const EdgeInsets.symmetric(horizontal: 10),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  Widget _buildSelectionBar(AdvancedDownloadManager manager) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppTheme.accentPurple.withOpacity(0.1),
      child: Row(
        children: [
          Text('${_selectedIds.length} محدد', style: const TextStyle(color: AppTheme.accentPurple, fontWeight: FontWeight.w700, fontSize: 14)),
          const Spacer(),
          TextButton(onPressed: () => _selectAll(manager.searchTasks(_searchQuery, filterPlatform: _filterPlatform, filterStatus: _filterStatus)), child: const Text('تحديد الكل', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12))),
          TextButton(onPressed: _clearSelection, child: const Text('إلغاء', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12))),
          TextButton(
            onPressed: () => _deleteSelected(manager),
            child: Text('حذف (${_selectedIds.length})', style: const TextStyle(color: AppTheme.errorRed, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.cloud_remove, size: 80, color: AppTheme.textMuted.withOpacity(0.3)),
          const SizedBox(height: 24),
          Text(
            _searchQuery.isNotEmpty || _filterPlatform != null || _filterStatus != null
                ? 'لا توجد نتائج مطابقة'
                : 'لا توجد تحميلات بعد',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty || _filterPlatform != null || _filterStatus != null
                ? 'جرّب تغيير معايير البحث'
                : 'ابدأ بتنزيل فيديوهاتك المفضلة',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textMuted),
          ),
          if (_searchQuery.isNotEmpty || _filterPlatform != null || _filterStatus != null) ...[
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                  _filterPlatform = null;
                  _filterStatus = null;
                });
              },
              child: const Text('مسح الفلاتر', style: TextStyle(color: AppTheme.accentPurple, fontWeight: FontWeight.w600)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTaskCard(BuildContext context, DownloadTaskEntity task, AdvancedDownloadManager service) {
    final statusLabels = ['انتظار', 'جلب', 'تحميل', 'مكتمل', 'فشل', 'مؤقت', 'ملغي'];
    final statusColors = [AppTheme.textMuted, AppTheme.accentBlue, AppTheme.accentPurple, AppTheme.successGreen, AppTheme.errorRed, AppTheme.warningOrange, AppTheme.textMuted];
    final statusIcons = [Icons.schedule_rounded, Icons.search_rounded, Icons.downloading_rounded, Icons.check_circle_rounded, Icons.error_rounded, Icons.pause_circle_rounded, Icons.cancel_rounded];
    final statusIdx = task.status.clamp(0, 6);
    final isSelected = _selectedIds.contains(task.id);
    final speed = service.getTaskSpeed(task.id);
    final eta = service.getTaskETA(task.id);

    return Dismissible(
      key: ValueKey(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 24),
        decoration: BoxDecoration(
          color: AppTheme.errorRed.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_rounded, color: AppTheme.errorRed, size: 24),
            SizedBox(height: 4),
            Text('حذف', style: TextStyle(color: AppTheme.errorRed, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppTheme.cardDark,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('حذف التحميل', style: TextStyle(color: AppTheme.textPrimary)),
            content: Text(task.title, style: const TextStyle(color: AppTheme.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
              TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حذف', style: TextStyle(color: AppTheme.errorRed))),
            ],
          ),
        );
      },
      onDismissed: (_) => service.deleteTask(task.id),
      child: GestureDetector(
        onLongPress: () => _toggleSelection(task.id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.accentPurple.withOpacity(0.15) : AppTheme.cardDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isSelected ? AppTheme.accentPurple : AppTheme.borderLight, width: isSelected ? 1.5 : 1),
          ),
          child: Row(children: [
            // أيقونة المنصة
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(colors: _getGradient(task.platform)),
              ),
              child: const Icon(Icons.videocam_rounded, color: Colors.white70, size: 22),
            ),
            const SizedBox(width: 12),
            // المعلومات
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    if (task.isFavorite) const Padding(padding: EdgeInsets.only(left: 4), child: Icon(Icons.star_rounded, color: Color(0xFFFFD700), size: 14)),
                    Expanded(
                      child: Text(
                        task.title,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.textPrimary),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ]),
                  const SizedBox(height: 4),
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: statusColors[statusIdx].withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(statusIcons[statusIdx], color: statusColors[statusIdx], size: 10),
                        const SizedBox(width: 3),
                        Text(statusLabels[statusIdx], style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: statusColors[statusIdx])),
                      ]),
                    ),
                    const Text('  ', style: TextStyle(fontSize: 6)),
                    Text(task.platform, style: const TextStyle(color: AppTheme.accentPurple, fontSize: 11, fontWeight: FontWeight.w600)),
                    const Text('  ', style: TextStyle(color: AppTheme.textMuted, fontSize: 8)),
                    Text('${task.quality} • ${service.formatBytes(task.fileSizeBytes)}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                  ]),
                  const SizedBox(height: 8),
                  // شريط التقدم
                  Row(children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: task.status == 3 ? 1.0 : task.progress,
                          backgroundColor: AppTheme.borderLight,
                          valueColor: AlwaysStoppedAnimation(statusColors[statusIdx]),
                          minHeight: 3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // السرعة والـ ETA
                    if (task.status == 2 && speed > 0) ...[
                      Text(service.formatSpeed(speed), style: const TextStyle(fontSize: 10, color: AppTheme.accentCyan, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 6),
                      Text(eta, style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                    ] else if (task.status == 3) ...[
                      Text('${(task.progress * 100).toInt()}%', style: const TextStyle(fontSize: 10, color: AppTheme.successGreen, fontWeight: FontWeight.w600)),
                    ],
                  ]),
                ],
              ),
            ),
            // أزرار الإجراءات
            Column(children: [
              if (task.status == 2)
                _actionButton(Icons.pause_rounded, AppTheme.warningOrange, () => service.pauseDownload(task.id))
              else if (task.status == 5)
                _actionButton(Icons.play_arrow_rounded, AppTheme.successGreen, () => service.resumeDownload(task.id))
              else if (task.status == 4)
                _actionButton(Icons.refresh_rounded, AppTheme.accentBlue, () => service.retryDownload(task.id))
              else if (task.status == 3)
                _actionButton(Icons.share_rounded, AppTheme.accentPurple, () => Share.share(task.url)),
              const SizedBox(height: 6),
              _actionButton(Icons.close_rounded, AppTheme.textMuted.withOpacity(0.5), () => service.deleteTask(task.id)),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _actionButton(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 16),
      ),
    );
  }

  List<Color> _getGradient(String p) {
    switch (p.toLowerCase()) {
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
}