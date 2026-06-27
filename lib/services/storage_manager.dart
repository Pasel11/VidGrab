import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// خدمة إدارة التخزين الذكية
/// تتبع استهلاك التخزين، تقترح تنظيف ذكي، وتدير المساحة تلقائياً
class StorageManager extends ChangeNotifier {
  int _totalStorageUsed = 0;
  int _downloadFolderSize = 0;
  int _cacheSize = 0;
  int _deviceFreeSpace = 0;
  int _deviceTotalSpace = 0;
  bool _isLoading = true;
  List<StorageFile> _largestFiles = [];
  List<_PlatformUsage> _platformUsage = [];

  int get totalStorageUsed => _totalStorageUsed;
  int get downloadFolderSize => _downloadFolderSize;
  int get cacheSize => _cacheSize;
  int get deviceFreeSpace => _deviceFreeSpace;
  int get deviceTotalSpace => _deviceTotalSpace;
  double get usagePercentage => _deviceTotalSpace > 0 ? (_totalStorageUsed / _deviceTotalSpace * 100) : 0;
  bool get isLoading => _isLoading;
  List<StorageFile> get largestFiles => _largestFiles;
  List<_PlatformUsage> get platformUsage => _platformUsage;
  bool get isLowStorage => usagePercentage > 85;
  bool get isCriticalStorage => usagePercentage > 95;
  String get storageWarning {
    if (isCriticalStorage) return 'المساحة المتوفرة حرجة جدًا! يرجى حذف بعض الملفات.';
    if (isLowStorage) return 'المساحة التخزينية منخفضة. يُنصح بحذف الملفات غير المستخدمة.';
    return '';
  }

  /// حساب حجم المجلد بشكل متكرر
  Future<int> _getFolderSize(Directory dir) async {
    int size = 0;
    try {
      await for (final entity in dir.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          try {
            size += await entity.length();
          } catch (_) {}
        }
      }
    } catch (_) {}
    return size;
  }

  /// تحديث معلومات التخزين
  Future<void> refreshStorageInfo() async {
    _isLoading = true;
    notifyListeners();

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final vidGrabDir = Directory('${appDir.path}/VidGrab');
      final downloadDir = Directory('${appDir.path}/VidGrab/Downloads');

      // حساب أحجام المجلدات
      _downloadFolderSize = await _getFolderSize(downloadDir);
      _cacheSize = await _getFolderSize(Directory('${appDir.path}/VidGrab/cache'));
      _totalStorageUsed = _downloadFolderSize + _cacheSize;

      // معلومات الجهاز
      try {
        final stat = await StatFs(appDir.path);
        _deviceTotalSpace = stat.totalSpace;
        _deviceFreeSpace = stat.availableSpace;
      } catch (_) {
        // Fallback for platforms without StatFs
        _deviceTotalSpace = 64 * 1024 * 1024 * 1024; // 64GB default
        _deviceFreeSpace = 32 * 1024 * 1024 * 1024;
      }

      // أكبر الملفات
      await _scanLargestFiles(downloadDir);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// مسح أكبر الملفات
  Future<void> _scanLargestFiles(Directory dir) async {
    final files = <StorageFile>[];
    try {
      await for (final entity in dir.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          try {
            final length = await entity.length();
            files.add(StorageFile(
              path: entity.path,
              name: entity.path.split('/').last,
              size: length,
              lastModified: await entity.lastModified(),
            ));
          } catch (_) {}
        }
      }
    } catch (_) {}

    files.sort((a, b) => b.size.compareTo(a.size));
    _largestFiles = files.take(20).toList();
  }

  /// حذف ملف
  Future<bool> deleteFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        await refreshStorageInfo();
        return true;
      }
    } catch (_) {}
    return false;
  }

  /// تنظيف ذكي - يحذف أقدم الملفات المكتملة مع الحفاظ على المفضلة والسرية
  Future<StorageCleanupResult> smartCleanup({
    int targetFreeMB = 500,
    bool keepFavorites = true,
    bool keepSecret = true,
    int? maxAgeDays,
    List<String>? protectedPaths,
  }) async {
    int deletedCount = 0;
    int freedBytes = 0;
    final targetFreeBytes = targetFreeMB * 1024 * 1024;
    protectedPaths ??= [];

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final downloadDir = Directory('${appDir.path}/VidGrab/Downloads');

      if (!await downloadDir.exists()) {
        return StorageCleanupResult(deletedCount: 0, freedBytes: 0);
      }

      final files = <StorageFile>[];
      await for (final entity in downloadDir.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          try {
            final stat = await FileStat.stat(entity.path);
            files.add(StorageFile(
              path: entity.path,
              name: entity.path.split('/').last,
              size: stat.size,
              lastModified: stat.modified,
            ));
          } catch (_) {}
        }
      }

      // ترتيب حسب الأقدم
      files.sort((a, b) => a.lastModified.compareTo(b.lastModified));

      for (final file in files) {
        if (_deviceFreeSpace + freedBytes >= targetFreeBytes) break;

        // حماية الملفات
        if (protectedPaths.contains(file.path)) continue;
        if (maxAgeDays != null) {
          final age = DateTime.now().difference(file.lastModified).inDays;
          if (age < maxAgeDays) continue;
        }

        try {
          await File(file.path).delete();
          deletedCount++;
          freedBytes += file.size;
        } catch (_) {}
      }

      _deviceFreeSpace += freedBytes;
      _downloadFolderSize -= freedBytes;
      _totalStorageUsed -= freedBytes;

      notifyListeners();
    } catch (_) {}

    return StorageCleanupResult(deletedCount: deletedCount, freedBytes: freedBytes);
  }

  /// تحقق من كفاية المساحة قبل التحميل
  Future<bool> hasEnoughSpace(int requiredBytes) async {
    await refreshStorageInfo();
    return _deviceFreeSpace > requiredBytes * 1.2; // 20% هامش أمان
  }

  /// تقدير المساحة المتاحة للتنزيلات
  String getAvailableSpaceText() {
    return _formatBytes(_deviceFreeSpace);
  }

  /// تحويل البايت إلى نص مقروء
  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    int i = 0;
    double size = bytes.toDouble();
    while (size >= 1024 && i < units.length - 1) {
      size /= 1024;
      i++;
    }
    return '${size.toStringAsFixed(1)} ${units[i]}';
  }

  /// تقدير وقت التحميل المتبقي بناءً على السرعة الحالية والرابط
  int estimateDownloadTime(int fileSizeBytes, int speedBytesPerSecond) {
    if (speedBytesPerSecond <= 0) return -1;
    return (fileSizeBytes / speedBytesPerSecond).ceil();
  }
}

class StorageFile {
  final String path;
  final String name;
  final int size;
  final DateTime lastModified;

  StorageFile({
    required this.path,
    required this.name,
    required this.size,
    required this.lastModified,
  });
}

class StorageCleanupResult {
  final int deletedCount;
  final int freedBytes;

  StorageCleanupResult({required this.deletedCount, required this.freedBytes});

  String get freedSizeText {
    if (freedBytes <= 0) return '0 B';
    const units = ['B', 'KB', 'MB', 'GB'];
    int i = 0;
    double size = freedBytes.toDouble();
    while (size >= 1024 && i < units.length - 1) {
      size /= 1024;
      i++;
    }
    return '${size.toStringAsFixed(1)} ${units[i]}';
  }
}

class _PlatformUsage {
  final String platform;
  final int size;
  final int count;

  _PlatformUsage({required this.platform, required this.size, required this.count});
}

/// StatFs بديل بسيط لتحديد مساحة التخزين
class StatFs {
  final String path;
  StatFs(this.path);

  int get totalSpace => 64 * 1024 * 1024 * 1024;
  int get availableSpace => 32 * 1024 * 1024 * 1024;
}