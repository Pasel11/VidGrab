import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/video_info.dart';

/// خدمة الذكاء الشبكي
/// تراقب سرعة الاتصال وتقترح الجودة المثلى تلقائياً
class NetworkIntelligence extends ChangeNotifier {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult>? _connectivitySub;
  NetworkQuality _currentQuality = NetworkQuality.unknown;
  int _estimatedSpeedMbps = 0;
  int _latencyMs = 0;
  bool _isConnected = false;
  bool _isWifi = false;
  bool _isMetered = false;
  DateTime? _lastSpeedTest;
  Timer? _speedTestTimer;

  NetworkQuality get currentQuality => _currentQuality;
  int get estimatedSpeedMbps => _estimatedSpeedMbps;
  int get latencyMs => _latencyMs;
  bool get isConnected => _isConnected;
  bool get isWifi => _isWifi;
  bool get isMetered => _isMetered;
  DateTime? get lastSpeedTest => _lastSpeedTest;

  Future<void> init() async {
    final result = await _connectivity.checkConnectivity();
    _updateConnectionStatus(result);

    _connectivitySub = _connectivity.onConnectivityChanged.listen((result) {
      _updateConnectionStatus(result);
    });

    // اختبار سرعة أولي
    await runSpeedTest();

    // اختبار دوري كل 5 دقائق
    _speedTestTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      runSpeedTest();
    });
  }

  void _updateConnectionStatus(ConnectivityResult result) {
    _isConnected = result != ConnectivityResult.none;
    _isWifi = result == ConnectivityResult.wifi;
    _isMetered = result == ConnectivityResult.mobile;

    // تقدير أولي بناءً على نوع الاتصال
    if (!_isConnected) {
      _currentQuality = NetworkQuality.offline;
      _estimatedSpeedMbps = 0;
    } else if (_isWifi) {
      _currentQuality = NetworkQuality.excellent;
      _estimatedSpeedMbps = 50;
    } else if (_isMetered) {
      _currentQuality = NetworkQuality.good;
      _estimatedSpeedMbps = 15;
    } else {
      _currentQuality = NetworkQuality.moderate;
      _estimatedSpeedMbps = 10;
    }

    notifyListeners();
  }

  /// اختبار سرعة مبسط
  Future<SpeedTestResult> runSpeedTest() async {
    _lastSpeedTest = DateTime.now();

    // محاكاة اختبار السرعة - في الإنتاج يُستبدل بطلب حقيقي
    await Future.delayed(const Duration(seconds: 1));

    final rng = DateTime.now().millisecondsSinceEpoch % 100;

    if (!_isConnected) {
      _currentQuality = NetworkQuality.offline;
      _estimatedSpeedMbps = 0;
      _latencyMs = 0;
    } else if (rng < 15) {
      _currentQuality = NetworkQuality.poor;
      _estimatedSpeedMbps = 2 + (rng % 3);
      _latencyMs = 200 + (rng % 100);
    } else if (rng < 40) {
      _currentQuality = NetworkQuality.moderate;
      _estimatedSpeedMbps = 5 + (rng % 10);
      _latencyMs = 80 + (rng % 60);
    } else if (rng < 75) {
      _currentQuality = NetworkQuality.good;
      _estimatedSpeedMbps = 15 + (rng % 20);
      _latencyMs = 30 + (rng % 40);
    } else {
      _currentQuality = NetworkQuality.excellent;
      _estimatedSpeedMbps = 50 + (rng % 100);
      _latencyMs = 10 + (rng % 20);
    }

    notifyListeners();
    return SpeedTestResult(
      speedMbps: _estimatedSpeedMbps,
      latencyMs: _latencyMs,
      quality: _currentQuality,
      timestamp: _lastSpeedTest!,
    );
  }

  /// اقتراح الجودة المثلى بناءً على سرعة الشبكة
  VideoQualitySuggestion suggestQuality(int fileSizeMB) {
    if (!_isConnected) {
      return VideoQualitySuggestion(
        quality: '480p',
        reason: 'لا يوجد اتصال بالإنترنت',
        format: 'MP4',
        estimatedTimeSeconds: 0,
        canDownload: false,
      );
    }

    // حساب الوقت التقديري
    final estimatedSeconds = _estimatedSpeedMbps > 0
        ? (fileSizeMB * 8 / _estimatedSpeedMbps).round()
        : 0;

    if (_isMetered && fileSizeMB > 100) {
      return VideoQualitySuggestion(
        quality: '480p',
        reason: 'اتصال بيانات - يُنصح بجودة منخفضة لتوفير البيانات',
        format: 'MP4',
        estimatedTimeSeconds: estimatedSeconds,
        canDownload: true,
        isSuggested: true,
      );
    }

    if (_currentQuality == NetworkQuality.excellent || _currentQuality == NetworkQuality.good) {
      return VideoQualitySuggestion(
        quality: '1080p',
        reason: 'اتصال ممتاز - جودة Full HD متاحة',
        format: 'MP4',
        estimatedTimeSeconds: estimatedSeconds,
        canDownload: true,
        isSuggested: true,
      );
    }

    if (_currentQuality == NetworkQuality.moderate) {
      return VideoQualitySuggestion(
        quality: '720p',
        reason: 'اتصال متوسط - جودة HD هي الأنسب',
        format: 'MP4',
        estimatedTimeSeconds: estimatedSeconds,
        canDownload: true,
        isSuggested: true,
      );
    }

    return VideoQualitySuggestion(
      quality: '480p',
      reason: 'اتصال بطيء - جودة SD للتشغيل السلس',
      format: 'MP4',
      estimatedTimeSeconds: estimatedSeconds,
      canDownload: true,
      isSuggested: true,
    );
  }

  /// حساب الوقت المتبقي للتحميل
  String formatEstimatedTime(int remainingBytes, int speedBytesPerSecond) {
    if (speedBytesPerSecond <= 0) return '--:--';
    final seconds = (remainingBytes / speedBytesPerSecond).ceil();
    if (seconds < 60) return '$seconds ث';
    if (seconds < 3600) return '${seconds ~/ 60} د ${(seconds % 60).toString().padLeft(2, '0')} ث';
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    return '$hours س $minutes د';
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    _speedTestTimer?.cancel();
    super.dispose();
  }
}

enum NetworkQuality {
  offline('غير متصل', 0),
  poor('ضعيف', 1),
  moderate('متوسط', 2),
  good('جيد', 3),
  excellent('ممتاز', 4),
  unknown('غير معروف', -1);

  final String label;
  final int level;
  const NetworkQuality(this.label, this.level);
}

class SpeedTestResult {
  final int speedMbps;
  final int latencyMs;
  final NetworkQuality quality;
  final DateTime timestamp;

  SpeedTestResult({
    required this.speedMbps,
    required this.latencyMs,
    required this.quality,
    required this.timestamp,
  });
}

class VideoQualitySuggestion {
  final String quality;
  final String reason;
  final String format;
  final int estimatedTimeSeconds;
  final bool canDownload;
  final bool isSuggested;

  VideoQualitySuggestion({
    required this.quality,
    required this.reason,
    required this.format,
    required this.estimatedTimeSeconds,
    required this.canDownload,
    this.isSuggested = false,
  });

  String get estimatedTimeText {
    if (estimatedTimeSeconds <= 0) return 'فوري';
    if (estimatedTimeSeconds < 60) return '$estimatedTimeSeconds ثانية';
    if (estimatedTimeSeconds < 3600) {
      final m = estimatedTimeSeconds ~/ 60;
      final s = estimatedTimeSeconds % 60;
      return '$m د $s ث';
    }
    final h = estimatedTimeSeconds ~/ 3600;
    final m = (estimatedTimeSeconds % 3600) ~/ 60;
    return '$h س $m د';
  }
}