import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/video_info.dart';
import '../models/download_task.dart';
import 'platform_detector.dart';

class DownloadService extends ChangeNotifier {
  final PlatformDetector _platformDetector = PlatformDetector();
  final List<DownloadTask> _downloadHistory = [];
  bool _isProcessing = false;
  DownloadTask? _currentTask;
  String _errorMessage = '';

  List<DownloadTask> get downloadHistory => _downloadHistory;
  bool get isProcessing => _isProcessing;
  DownloadTask? get currentTask => _currentTask;
  String get errorMessage => _errorMessage;

  VideoPlatform detectPlatform(String url) => _platformDetector.detectPlatform(url);
  bool isValidUrl(String url) => _platformDetector.isValidUrl(url);

  Future<VideoInfo?> fetchVideoInfo(String url) async {
    if (!_platformDetector.isValidUrl(url)) {
      _errorMessage = 'الرابط غير صالح، يرجى التحقق من الرابط والمحاولة مرة أخرى';
      notifyListeners();
      return null;
    }

    _isProcessing = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final platform = _platformDetector.detectPlatform(url);
      final info = await _fetchFromApi(url, platform);
      _isProcessing = false;
      notifyListeners();
      return info;
    } catch (e) {
      _isProcessing = false;
      _errorMessage = 'حدث خطأ أثناء جلب معلومات الفيديو. يرجى المحاولة مرة أخرى';
      notifyListeners();
      return null;
    }
  }

  Future<VideoInfo> _fetchFromApi(String url, VideoPlatform platform) async {
    // Simulated API call - Replace with real API endpoint
    await Future.delayed(const Duration(seconds: 2));

    // In production, call a real backend API like:
    // final response = await http.post(Uri.parse('https://your-api.com/api/fetch'),
    //   body: {'url': url}, headers: {'Content-Type': 'application/json'});
    // final data = jsonDecode(response.body);

    return VideoInfo(
      url: url,
      platform: platform,
      title: _generateTitle(platform),
      thumbnailUrl: 'https://picsum.photos/seed/${Random().nextInt(1000)}/400/225',
      author: '@${platform.name.toLowerCase()}_creator',
      duration: Duration(minutes: Random().nextInt(15) + 1, seconds: Random().nextInt(60)),
      availableQualities: _getQualitiesForPlatform(platform),
      description: 'فيديو من ${platform.name} - جودة عالية',
    );
  }

  String _generateTitle(VideoPlatform platform) {
    final titles = {
      VideoPlatform.youtube: ['فيديو رائع من يوتيوب', 'محتوى مميز - YouTube', 'فيديو ترند على يوتيوب'],
      VideoPlatform.instagram: ['ريلز انستقرام مميز', 'ستوري انستقرام', 'بوست فيديو انستقرام'],
      VideoPlatform.tiktok: ['فيديو تيك توك فيروسي', 'تيك توك ترند', 'تحدي تيك توك جديد'],
      VideoPlatform.twitter: ['فيديو من منصة X', 'تغريدة فيديو مميزة', 'محتوى X حصري'],
      VideoPlatform.facebook: ['فيديو فيسبوك', 'ريلز فيسبوك', 'محتوى فيسبوك مميز'],
      VideoPlatform.snapchat: ['سناب شات سبوتلايت', 'قصة سناب شات', 'محتوى سناب'],
      VideoPlatform.pinterest: ['بينتريست فيديو', 'فكرة بينتريست مميزة', 'دورة بينتريست'],
      VideoPlatform.linkedin: ['فيديو لينكد إن', 'محتوى مهني', 'عرض تقديمي'],
      VideoPlatform.reddit: ['فيديو ريديت', 'محتوى ريديت مميز', 'بوست ريديت'],
      VideoPlatform.tumblr: ['فيديو تامبلر', 'محتوى تامبلر', 'بوست تامبلر مميز'],
      VideoPlatform.vimeo: ['فيديو فيميو احترافي', 'فيلم قصير', 'محتوى فيميو'],
      VideoPlatform.dailymotion: ['فيديو ديلي موشن', 'محتوى ديلي موشن', 'بث مباشر'],
      VideoPlatform.unknown: ['فيديو من المنصة', 'محتوى مميز', 'فيديو جديد'],
    };
    final list = titles[platform] ?? titles[VideoPlatform.unknown]!;
    return list[Random().nextInt(list.length)];
  }

  List<VideoQuality> _getQualitiesForPlatform(VideoPlatform platform) {
    final qualities = <VideoQuality>[];
    final rng = Random();

    if (platform == VideoPlatform.youtube) {
      qualities.addAll([
        VideoQuality(label: '4K Ultra HD', resolution: '2160p', format: 'MP4', fileSize: '${rng.nextInt(800) + 200} MB', downloadUrl: ''),
        VideoQuality(label: 'Full HD', resolution: '1080p', format: 'MP4', fileSize: '${rng.nextInt(300) + 50} MB', downloadUrl: ''),
        VideoQuality(label: 'HD', resolution: '720p', format: 'MP4', fileSize: '${rng.nextInt(150) + 30} MB', downloadUrl: ''),
        VideoQuality(label: 'SD', resolution: '480p', format: 'MP4', fileSize: '${rng.nextInt(80) + 15} MB', downloadUrl: ''),
        VideoQuality(label: 'صوت فقط', resolution: '320kbps', format: 'MP3', fileSize: '${rng.nextInt(10) + 3} MB', downloadUrl: ''),
      ]);
    } else {
      qualities.addAll([
        VideoQuality(label: 'Full HD', resolution: '1080p', format: 'MP4', fileSize: '${rng.nextInt(300) + 40} MB', downloadUrl: ''),
        VideoQuality(label: 'HD', resolution: '720p', format: 'MP4', fileSize: '${rng.nextInt(120) + 20} MB', downloadUrl: ''),
        VideoQuality(label: 'SD', resolution: '480p', format: 'MP4', fileSize: '${rng.nextInt(60) + 10} MB', downloadUrl: ''),
        VideoQuality(label: 'صوت فقط', resolution: '320kbps', format: 'MP3', fileSize: '${rng.nextInt(8) + 2} MB', downloadUrl: ''),
      ]);
    }
    return qualities;
  }

  Future<void> startDownload(VideoInfo videoInfo, VideoQuality quality) async {
    final task = DownloadTask(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      url: videoInfo.url,
      title: videoInfo.title,
      thumbnailUrl: videoInfo.thumbnailUrl,
      platform: videoInfo.platform.name,
      quality: quality.resolution,
      format: quality.format,
      status: DownloadStatus.downloading,
      progress: 0.0,
      createdAt: DateTime.now(),
    );

    _currentTask = task;
    _downloadHistory.insert(0, task);
    notifyListeners();

    await _simulateDownload(task);
    await _saveHistory();
  }

  Future<void> _simulateDownload(DownloadTask task) async {
    const totalSteps = 50;
    for (int i = 1; i <= totalSteps; i++) {
      await Future.delayed(const Duration(milliseconds: 100));
      final progress = i / totalSteps;

      final index = _downloadHistory.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        _downloadHistory[index] = _downloadHistory[index].copyWith(
          progress: progress,
          status: progress >= 1.0 ? DownloadStatus.completed : DownloadStatus.downloading,
          completedAt: progress >= 1.0 ? DateTime.now() : null,
          fileSize: (progress * (Random().nextInt(50000000) + 5000000)).toInt(),
        );
        _currentTask = _downloadHistory[index];
        notifyListeners();
      }
    }
  }

  Future<void> deleteTask(String taskId) async {
    _downloadHistory.removeWhere((t) => t.id == taskId);
    if (_currentTask?.id == taskId) _currentTask = null;
    notifyListeners();
    await _saveHistory();
  }

  Future<void> clearHistory() async {
    _downloadHistory.clear();
    _currentTask = null;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('download_history');
  }

  Future<void> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('download_history');
    if (jsonStr != null) {
      final List<dynamic> jsonList = jsonDecode(jsonStr);
      _downloadHistory.clear();
      for (final item in jsonList) {
        _downloadHistory.add(DownloadTask.fromMap(item as Map<String, dynamic>));
      }
      notifyListeners();
    }
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _downloadHistory.map((t) => t.toMap()).toList();
    await prefs.setString('download_history', jsonEncode(jsonList));
  }

  void clearError() {
    _errorMessage = '';
    notifyListeners();
  }
}