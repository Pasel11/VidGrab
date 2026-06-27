import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/app_database.dart';
import 'audio_effects_service.dart';
import 'haptic_service.dart';
import 'network_intelligence.dart';
import 'storage_manager.dart';

enum DownloadQueuePriority { low, normal, high }

/// مدير التحميل المتقدم مع تتبع السرعة الحقيقية والـ ETA
class AdvancedDownloadManager extends ChangeNotifier {
  static const String _tasksBoxName = 'download_tasks';
  static const String _settingsBoxName = 'user_settings';
  static const int _maxRetries = 3;
  static const int _speedWindowSize = 5; // متوسط السرعة على 5 ثواني

  final Dio _dio;
  final Uuid _uuid;
  final AudioEffectsService _audioService;
  final HapticService _hapticService;
  final FlutterLocalNotificationsPlugin _notifications;
  final NetworkIntelligence _networkIntelligence;
  final StorageManager _storageManager;

  Box<DownloadTaskEntity>? _tasksBox;
  Box<UserSettingsEntity>? _settingsBox;
  UserSettingsEntity? _settings;
  final Map<String, CancelToken> _cancelTokens = {};
  final Map<String, DownloadTaskEntity> _activeDownloads = {};
  final List<DownloadTaskEntity> _queue = [];
  ConnectivityResult? _currentConnection;
  StreamSubscription<ConnectivityResult>? _connectivitySub;
  Timer? _progressTimer;
  Timer? _scheduledCheckTimer;
  bool _isInitialized = false;

  // تتبع السرعة لكل مهمة
  final Map<String, _SpeedTracker> _speedTrackers = {};

  // الإحصائيات الذكية
  int _totalBytesToday = 0;
  DateTime _todayDate = DateTime.now();

  List<DownloadTaskEntity> get allTasks {
    final tasks = _tasksBox?.values.toList() ?? [];
    tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return tasks;
  }
  List<DownloadTaskEntity> get completedTasks => allTasks.where((t) => t.status == 3).toList();
  List<DownloadTaskEntity> get failedTasks => allTasks.where((t) => t.status == 4).toList();
  List<DownloadTaskEntity> get activeTasks => _activeDownloads.values.toList();
  List<DownloadTaskEntity> get queuedTasks => _queue;
  UserSettingsEntity? get settings => _settings;
  int get pendingCount => _queue.length + _activeDownloads.length;
  bool get isInitialized => _isInitialized;
  int get totalBytesToday => _totalBytesToday;
  String get totalBytesTodayText => formatBytes(_totalBytesToday);

  // سرعة التحميل الإجمالية
  int get totalDownloadSpeed {
    int total = 0;
    for (final tracker in _speedTrackers.values) {
      total += tracker.currentSpeed;
    }
    return total;
  }

  String get totalSpeedText => formatSpeed(totalDownloadSpeed);

  // الوقت المتبقي الإجمالي
  String get totalRemainingTime {
    int remainingBytes = 0;
    for (final task in _activeDownloads.values) {
      final tracker = _speedTrackers[task.id];
      if (tracker != null && tracker.currentSpeed > 0) {
        remainingBytes += ((1.0 - task.progress) * task.fileSizeBytes).toInt();
      }
    }
    if (totalDownloadSpeed <= 0) return '--:--';
    final seconds = (remainingBytes / totalDownloadSpeed).ceil();
    return _formatDuration(seconds);
  }

  AdvancedDownloadManager({
    Dio? dio,
    AudioEffectsService? audioService,
    HapticService? hapticService,
    FlutterLocalNotificationsPlugin? notifications,
    NetworkIntelligence? networkIntelligence,
    StorageManager? storageManager,
  })  : _dio = dio ?? Dio(BaseOptions(connectTimeout: const Duration(seconds: 30), receiveTimeout: const Duration(seconds: 300))),
        _uuid = const Uuid(),
        _audioService = audioService ?? AudioEffectsService(),
        _hapticService = hapticService ?? HapticService(),
        _notifications = notifications ?? FlutterLocalNotificationsPlugin(),
        _networkIntelligence = networkIntelligence ?? NetworkIntelligence(),
        _storageManager = storageManager ?? StorageManager();

  Future<void> init() async {
    if (_isInitialized) return;
    await Hive.openBox<DownloadTaskEntity>(_tasksBoxName);
    await Hive.openBox<UserSettingsEntity>(_settingsBoxName);
    _tasksBox = Hive.box<DownloadTaskEntity>(_tasksBoxName);
    _settingsBox = Hive.box<UserSettingsEntity>(_settingsBoxName);

    _settings = _settingsBox!.get('settings', defaultValue: UserSettingsEntity(
      referralCode: _generateReferralCode(),
      firstLaunchDate: DateTime.now(),
    ));

    _connectivitySub = Connectivity().onConnectivityChanged.listen((result) {
      _currentConnection = result;
      if (_settings?.wifiOnly == true && result != ConnectivityResult.wifi && result != ConnectivityResult.ethernet) {
        pauseAllDownloads(reason: 'لا يوجد اتصال Wi-Fi');
      }
      notifyListeners();
    });

    await _initNotifications();
    _isInitialized = true;
    notifyListeners();

    // استئناف التحميلات المعلقة
    final pending = allTasks.where((t) => t.status == 2 || t.status == 0).toList();
    for (final task in pending) {
      _queue.add(task);
    }
    _processQueue();

    // فحص التحميلات المجدولة كل دقيقة
    _scheduledCheckTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      checkScheduledDownloads();
    });

    // فحص اليوم
    _resetDailyStatsIfNeeded();
  }

  void _resetDailyStatsIfNeeded() {
    final now = DateTime.now();
    if (now.day != _todayDate.day || now.month != _todayDate.month || now.year != _todayDate.year) {
      _totalBytesToday = 0;
      _todayDate = now;
    }
  }

  Future<void> _initNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _notifications.initialize(const InitializationSettings(android: android, iOS: ios));
  }

  String _generateReferralCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    return List.generate(8, (_) => chars[Random().nextInt(chars.length)]).join();
  }

  // === DOWNLOAD OPERATIONS ===

  Future<DownloadTaskEntity> addDownload({
    required String url,
    required String title,
    required String platform,
    required String quality,
    required String format,
    String downloadUrl = '',
    String folder = 'عام',
    bool isSecret = false,
    DateTime? scheduledAt,
    DownloadQueuePriority priority = DownloadQueuePriority.normal,
  }) async {
    final task = DownloadTaskEntity(
      id: _uuid.v4(),
      url: url,
      title: title,
      platform: platform,
      quality: quality,
      format: format,
      folder: folder,
      isSecret: isSecret,
      scheduledAt: scheduledAt,
    );

    await _tasksBox!.put(task.id, task);

    if (scheduledAt != null) {
      // سيتم التقاطها بواسطة المجدول
    } else {
      // إدراج حسب الأولوية
      if (priority == DownloadQueuePriority.high) {
        _queue.insert(0, task);
      } else if (priority == DownloadQueuePriority.low) {
        _queue.add(task);
      } else {
        // إدراج بعد المهام العادية
        int insertIdx = _queue.length;
        for (int i = 0; i < _queue.length; i++) {
          if (_queue[i].status != 0) continue;
          insertIdx = i + 1;
        }
        _queue.insert(insertIdx, task);
      }
      _processQueue();
    }

    _audioService.playSound(SoundType.downloadStart);
    _hapticService.lightImpact();
    notifyListeners();
    return task;
  }

  /// تحميل دفعة - عدة فيديوهات دفعة واحدة
  Future<List<DownloadTaskEntity>> addBatchDownload(List<Map<String, dynamic>> items) async {
    final tasks = <DownloadTaskEntity>[];
    for (final item in items) {
      final task = await addDownload(
        url: item['url'] as String,
        title: item['title'] as String,
        platform: item['platform'] as String,
        quality: item['quality'] as String? ?? '1080p',
        format: item['format'] as String? ?? 'MP4',
      );
      tasks.add(task);
    }
    return tasks;
  }

  Future<void> _processQueue() async {
    if (_settings == null) return;
    final maxParallel = _settings!.isPro ? 5 : 1;
    while (_activeDownloads.length < maxParallel && _queue.isNotEmpty) {
      final task = _queue.removeAt(0);
      _activeDownloads[task.id] = task;
      _startDownload(task);
    }
  }

  Future<void> _startDownload(DownloadTaskEntity task) async {
    _updateTaskStatus(task.id, 2); // downloading
    final cancelToken = CancelToken();
    _cancelTokens[task.id] = cancelToken;

    // إنشاء متتبع سرعة جديد
    _speedTrackers[task.id] = _SpeedTracker();

    try {
      final dir = await _getDownloadDirectory();
      final filePath = '${dir.path}/${_sanitizeFileName(task.title)}.${task.format.toLowerCase()}';
      int receivedBytes = 0;

      // تحديث الإشعارات كل ثانية
      _progressTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        _updateProgressNotification(task);
        notifyListeners();
      });

      // Simulated download - في الإنتاج يُستبدل بتحميل Dio حقيقي:
      // await _dio.download(downloadUrl, filePath, onReceiveProgress: (received, total) {
      //   _handleProgressUpdate(task.id, received, total);
      // }, cancelToken: cancelToken);
      final totalBytes = (Random().nextInt(50000000) + 5000000);
      const totalSteps = 100;

      for (int i = 1; i <= totalSteps; i++) {
        if (cancelToken.isCancelled) break;
        await Future.delayed(const Duration(milliseconds: 80));
        receivedBytes = (i / totalSteps * totalBytes).toInt();
        _handleProgressUpdate(task.id, receivedBytes, totalBytes);

        if (i >= totalSteps) {
          await _completeDownload(task.id, filePath, totalBytes);
          break;
        }
      }
    } catch (e) {
      if (e is DioException && CancelToken.isCancel(e)) {
        _updateTaskStatus(task.id, 6); // cancelled
      } else {
        _handleDownloadError(task.id, e);
      }
    } finally {
      _progressTimer?.cancel();
      _cancelTokens.remove(task.id);
      _speedTrackers.remove(task.id);
      _activeDownloads.remove(task.id);
      _processQueue();
      notifyListeners();
    }
  }

  /// معالجة تحديث التقدم مع تتبع السرعة
  void _handleProgressUpdate(String taskId, int receivedBytes, int totalBytes) {
    final tracker = _speedTrackers[taskId];
    if (tracker != null) {
      tracker.addSample(receivedBytes);
    }

    final task = _tasksBox!.get(taskId);
    if (task != null) {
      final progress = totalBytes > 0 ? receivedBytes / totalBytes : 0.0;
      task.progress = progress;
      task.fileSizeBytes = totalBytes;
      task.downloadSpeed = tracker?.currentSpeed ?? 0;
      task.save();
    }

    // تحديث الإحصائيات اليومية
    final oldTask = _tasksBox!.get(taskId);
    final oldBytes = oldTask != null ? (oldTask.progress * oldTask.fileSizeBytes).toInt() : 0;
    final newBytes = (totalBytes > 0 ? receivedBytes / totalBytes : 0.0) * totalBytes;
    _totalBytesToday += (newBytes - oldBytes).toInt();
    _resetDailyStatsIfNeeded();

    notifyListeners();
  }

  /// إشعار التقدم المباشر
  Future<void> _updateProgressNotification(DownloadTaskEntity task) async {
    final tracker = _speedTrackers[task.id];
    if (tracker == null) return;

    final speed = formatSpeed(tracker.currentSpeed);
    final eta = tracker.getETA(task.fileSizeBytes, task.progress);
    final progress = (task.progress * 100).toInt();

    await _notifications.show(
      task.id.hashCode,
      'جارٍ التحميل... $progress%',
      '${task.title}\n$_speed | متبقي: $eta',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'download_progress', 'تقدم التحميل',
          importance: Importance.low,
          priority: Priority.low,
          showProgress: true,
          maxProgress: 100,
          progress: progress,
          ongoing: true,
          autoCancel: false,
          icon: '@mipmap/ic_launcher',
          indeterminate: false,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  Future<void> _completeDownload(String taskId, String filePath, int fileSize) async {
    final task = _tasksBox!.get(taskId);
    if (task == null) return;

    task.filePath = filePath;
    task.fileSizeBytes = fileSize;
    task.status = 3; // completed
    task.completedAt = DateTime.now();
    task.progress = 1.0;
    task.downloadSpeed = 0;
    await task.save();

    _settings!.totalDownloads++;
    _settings!.totalSizeDownloaded += fileSize;
    _settings!.adCounter++;
    await _settings!.save();

    _audioService.playSound(SoundType.downloadComplete);
    _hapticService.successFeedback();

    // إشعار الإكمال
    await _notifications.cancel(taskId.hashCode);
    await _notifications.show(
      taskId.hashCode,
      'تم التحميل بنجاح!',
      '${task.title}\n${formatBytes(fileSize)} | ${task.quality}',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'downloads', 'تنزيلات VidGrab',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          autoCancel: true,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );

    // تحديث مدير التخزين
    await _storageManager.refreshStorageInfo();
  }

  void _handleDownloadError(String taskId, dynamic error) {
    final task = _tasksBox!.get(taskId);
    if (task == null) return;
    if (task.retryCount < _maxRetries) {
      task.retryCount++;
      task.status = 0; // waiting
      task.save();
      _queue.add(task);

      // تأخير قبل إعادة المحاولة مع تراجع أسّي
      final delay = Duration(seconds: pow(2, task.retryCount).toInt());
      Future.delayed(delay, () => _processQueue());
    } else {
      task.status = 4; // failed
      task.save();
      _audioService.playSound(SoundType.error);
      _hapticService.errorFeedback();

      _notifications.show(
        taskId.hashCode,
        'فشل التحميل',
        '${task.title}\nتم تجربة $_maxRetries مرات بدون نجاح',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'download_errors', 'أخطاء التحميل',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
    }
    notifyListeners();
  }

  // === DOWNLOAD CONTROLS ===

  Future<void> pauseDownload(String taskId) async {
    _cancelTokens[taskId]?.cancel('User paused');
    _cancelTokens.remove(taskId);
    _speedTrackers.remove(taskId);
    _updateTaskStatus(taskId, 5); // paused
    notifyListeners();
  }

  Future<void> resumeDownload(String taskId) async {
    final task = _tasksBox!.get(taskId);
    if (task == null) return;
    task.status = 0;
    task.save();
    _queue.add(task);
    _processQueue();
    notifyListeners();
  }

  Future<void> cancelDownload(String taskId) async {
    _cancelTokens[taskId]?.cancel('User cancelled');
    _cancelTokens.remove(taskId);
    _speedTrackers.remove(taskId);
    _activeDownloads.remove(taskId);
    _queue.removeWhere((t) => t.id == taskId);
    _updateTaskStatus(taskId, 6); // cancelled
    _notifications.cancel(taskId.hashCode);
    notifyListeners();
  }

  Future<void> retryDownload(String taskId) async {
    final task = _tasksBox!.get(taskId);
    if (task == null) return;
    task.retryCount = 0;
    task.status = 0;
    task.progress = 0;
    task.save();
    _queue.add(task);
    _processQueue();
    notifyListeners();
  }

  Future<void> retryAllFailed() async {
    final failed = allTasks.where((t) => t.status == 4).toList();
    for (final task in failed) {
      await retryDownload(task.id);
    }
  }

  Future<void> pauseAllDownloads({String? reason}) async {
    for (final id in _activeDownloads.keys.toList()) {
      await pauseDownload(id);
    }
  }

  Future<void> resumeAllDownloads() async {
    final paused = allTasks.where((t) => t.status == 5).toList();
    for (final task in paused) {
      await resumeDownload(task.id);
    }
  }

  // === SPEED TRACKING ===

  /// الحصول على سرعة تحميل مهمة محددة
  int getTaskSpeed(String taskId) {
    return _speedTrackers[taskId]?.currentSpeed ?? 0;
  }

  /// الحصول على ETA لمهمة محددة
  String getTaskETA(String taskId) {
    final task = _tasksBox!.get(taskId);
    final tracker = _speedTrackers[taskId];
    if (task == null || tracker == null) return '--:--';
    return tracker.getETA(task.fileSizeBytes, task.progress);
  }

  // === SCHEDULING ===

  Future<void> scheduleDownload({
    required String url, required String title, required String platform,
    required String quality, String format = 'MP4', required DateTime scheduledTime,
  }) async {
    await addDownload(
      url: url, title: title, platform: platform,
      quality: quality, format: format, scheduledAt: scheduledTime,
    );
  }

  Future<void> checkScheduledDownloads() async {
    final now = DateTime.now();
    final scheduled = allTasks.where((t) =>
      t.scheduledAt != null && t.scheduledAt!.isBefore(now) && t.status == 0
    ).toList();
    for (final task in scheduled) {
      task.scheduledAt = null;
      await task.save();
      _queue.add(task);
    }
    if (scheduled.isNotEmpty) _processQueue();
  }

  // === FAVORITES & ORGANIZATION ===

  Future<void> toggleFavorite(String taskId) async {
    final task = _tasksBox!.get(taskId);
    if (task != null) {
      task.isFavorite = !task.isFavorite;
      await task.save();
      notifyListeners();
    }
  }

  Future<void> moveToFolder(String taskId, String folder) async {
    final task = _tasksBox!.get(taskId);
    if (task != null) {
      task.folder = folder;
      await task.save();
      notifyListeners();
    }
  }

  Future<void> toggleSecret(String taskId) async {
    if (!(_settings?.isPro ?? false)) return;
    final task = _tasksBox!.get(taskId);
    if (task != null) {
      task.isSecret = !task.isSecret;
      await task.save();
      notifyListeners();
    }
  }

  List<DownloadTaskEntity> getTasksByFolder(String folder) {
    return allTasks.where((t) => t.folder == folder).toList();
  }

  List<DownloadTaskEntity> getFavoriteTasks() {
    return allTasks.where((t) => t.isFavorite).toList();
  }

  List<DownloadTaskEntity> getSecretTasks() {
    return allTasks.where((t) => t.isSecret).toList();
  }

  List<DownloadTaskEntity> searchTasks(String query, {String? filterPlatform, int? filterStatus}) {
    var results = allTasks;
    if (query.isNotEmpty) {
      final q = query.toLowerCase();
      results = results.where((t) =>
        t.title.toLowerCase().contains(q) ||
        t.platform.toLowerCase().contains(q) ||
        t.url.toLowerCase().contains(q)
      ).toList();
    }
    if (filterPlatform != null && filterPlatform.isNotEmpty) {
      results = results.where((t) => t.platform.toLowerCase() == filterPlatform.toLowerCase()).toList();
    }
    if (filterStatus != null) {
      results = results.where((t) => t.status == filterStatus).toList();
    }
    return results;
  }

  /// الحصول على قائمة المنصات المستخدمة
  List<String> getUsedPlatforms() {
    final platforms = <String>{};
    for (final task in allTasks) {
      platforms.add(task.platform);
    }
    return platforms.toList()..sort();
  }

  /// الحصول على قائمة المجلدات
  List<String> getUsedFolders() {
    final folders = <String>{};
    for (final task in allTasks) {
      folders.add(task.folder);
    }
    return folders.toList()..sort();
  }

  Map<String, int> getDownloadStats() {
    final stats = <String, int>{};
    for (final task in allTasks) {
      stats[task.platform] = (stats[task.platform] ?? 0) + 1;
    }
    return stats;
  }

  /// إحصائيات مفصلة
  Map<String, dynamic> getDetailedStats() {
    final all = allTasks;
    final completed = all.where((t) => t.status == 3).toList();
    final failed = all.where((t) => t.status == 4).toList();
    final totalSize = completed.fold<int>(0, (sum, t) => sum + t.fileSizeBytes);

    return {
      'total': all.length,
      'completed': completed.length,
      'failed': failed.length,
      'inProgress': _activeDownloads.length + _queue.length,
      'paused': all.where((t) => t.status == 5).length,
      'totalSize': totalSize,
      'totalSizeText': formatBytes(totalSize),
      'todayBytes': _totalBytesToday,
      'todayBytesText': formatBytes(_totalBytesToday),
      'successRate': all.isNotEmpty ? (completed.length / all.length * 100).toStringAsFixed(1) : '0',
      'platforms': getDownloadStats(),
      'averageSize': completed.isNotEmpty ? totalSize ~/ completed.length : 0,
      'averageSizeText': completed.isNotEmpty ? formatBytes(totalSize ~/ completed.length) : '0 B',
    };
  }

  // === CLEANUP ===

  Future<void> deleteTask(String taskId) async {
    final task = _tasksBox!.get(taskId);
    if (task?.filePath.isNotEmpty ?? false) {
      final file = File(task!.filePath);
      if (await file.exists()) await file.delete();
    }
    await _tasksBox!.delete(taskId);
    _notifications.cancel(taskId.hashCode);
    notifyListeners();
  }

  /// حذف دفعة
  Future<void> deleteMultiple(List<String> taskIds) async {
    for (final id in taskIds) {
      await deleteTask(id);
    }
  }

  /// حذف المكتملة تلقائياً الأقدم من n يوم
  Future<int> autoCleanupOldCompleted({int olderThanDays = 30, bool keepFavorites = true}) async {
    final cutoff = DateTime.now().subtract(Duration(days: olderThanDays));
    final toDelete = allTasks.where((t) =>
      t.status == 3 &&
      t.completedAt != null &&
      t.completedAt!.isBefore(cutoff) &&
      (!keepFavorites || !t.isFavorite)
    ).toList();

    for (final task in toDelete) {
      await deleteTask(task.id);
    }
    return toDelete.length;
  }

  Future<void> clearCompleted() async {
    final completed = allTasks.where((t) => t.status == 3).toList();
    for (final task in completed) {
      await deleteTask(task.id);
    }
  }

  Future<void> clearAll() async {
    await _tasksBox!.clear();
    _queue.clear();
    _activeDownloads.clear();
    _cancelTokens.clear();
    _speedTrackers.clear();
    notifyListeners();
  }

  // === SETTINGS ===

  Future<void> updateSettings(UserSettingsEntity newSettings) async {
    _settings = newSettings;
    await _settingsBox!.put('settings', newSettings);
    notifyListeners();
  }

  // === PRO & REFERRAL ===

  Future<bool> activatePro({int days = 30}) async {
    if (_settings == null) return false;
    _settings!.isPro = true;
    _settings!.proExpiryDate = DateTime.now().add(Duration(days: days));
    _settings!.maxParallelDownloads = 5;
    await _settings!.save();
    notifyListeners();
    return true;
  }

  bool get isProActive {
    if (_settings?.isPro != true) return false;
    if (_settings!.proExpiryDate == null) return true;
    return DateTime.now().isBefore(_settings!.proExpiryDate!);
  }

  String get proDaysRemaining {
    if (!isProActive) return '0';
    final diff = _settings!.proExpiryDate!.difference(DateTime.now());
    return diff.inDays.toString();
  }

  Future<bool> processReferral(String code) async {
    if (code == _settings?.referralCode) return false;
    _settings!.referralCount++;
    _settings!.referredUsers = [..._settings!.referredUsers, code];
    if (_settings!.referralCount % 3 == 0) {
      await activatePro(days: 7);
    }
    await _settings!.save();
    notifyListeners();
    return true;
  }

  String get referralLink => 'https://vidgrab.app/ref/${_settings?.referralCode ?? ''}';

  // === HELPERS ===

  void _updateTaskStatus(String taskId, int status) {
    final task = _tasksBox!.get(taskId);
    if (task != null) {
      task.status = status;
      task.save();
    }
  }

  Future<Directory> _getDownloadDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final vidGrabDir = Directory('${appDir.path}/VidGrab/Downloads');
    if (!await vidGrabDir.exists()) await vidGrabDir.create(recursive: true);
    return vidGrabDir;
  }

  String _sanitizeFileName(String name) {
    return name.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_').replaceAll(RegExp(r'\s+'), '_');
  }

  String formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const units = ['B', 'KB', 'MB', 'GB'];
    int i = 0;
    double size = bytes.toDouble();
    while (size >= 1024 && i < units.length - 1) {
      size /= 1024;
      i++;
    }
    return '${size.toStringAsFixed(1)} ${units[i]}';
  }

  String formatSpeed(int bytesPerSecond) {
    return '${formatBytes(bytesPerSecond)}/s';
  }

  String _formatDuration(int seconds) {
    if (seconds <= 0) return 'فوري';
    if (seconds < 60) return '$seconds ث';
    if (seconds < 3600) {
      return '${seconds ~/ 60} د ${(seconds % 60).toString().padLeft(2, '0')} ث';
    }
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    return '$h س $m د';
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    _progressTimer?.cancel();
    _scheduledCheckTimer?.cancel();
    for (final token in _cancelTokens.values) {
      token.cancel('Service disposed');
    }
    _tasksBox?.close();
    _settingsBox?.close();
    super.dispose();
  }
}

/// متتبع السرعة - يحسب السرعة الحالية والمتوسطة والـ ETA
class _SpeedTracker {
  final List<_SpeedSample> _samples = [];
  static const int _maxSamples = 10;

  int get currentSpeed {
    if (_samples.length < 2) return 0;
    final latest = _samples.last;
    final secondLatest = _samples[_samples.length - 2];
    final elapsed = latest.timestamp.difference(secondLatest.timestamp).inMilliseconds;
    if (elapsed <= 0) return 0;
    return ((latest.totalBytes - secondLatest.totalBytes) * 1000 ~/ elapsed);
  }

  int get averageSpeed {
    if (_samples.length < 2) return 0;
    final first = _samples.first;
    final last = _samples.last;
    final elapsed = last.timestamp.difference(first.timestamp).inSeconds;
    if (elapsed <= 0) return 0;
    return (last.totalBytes - first.totalBytes) ~/ elapsed;
  }

  void addSample(int totalBytes) {
    _samples.add(_SpeedSample(totalBytes, DateTime.now()));
    if (_samples.length > _maxSamples) {
      _samples.removeAt(0);
    }
  }

  String getETA(int totalFileSize, double currentProgress) {
    final speed = currentSpeed;
    if (speed <= 0 || totalFileSize <= 0) return '--:--';
    final remaining = (totalFileSize * (1.0 - currentProgress)).toInt();
    final seconds = (remaining / speed).ceil();
    if (seconds < 60) return '$seconds ث';
    if (seconds < 3600) return '${seconds ~/ 60} د ${(seconds % 60).toString().padLeft(2, '0')} ث';
    return '${seconds ~/ 3600} س ${(seconds % 3600) ~/ 60} د';
  }
}

class _SpeedSample {
  final int totalBytes;
  final DateTime timestamp;
  _SpeedSample(this.totalBytes, this.timestamp);
}