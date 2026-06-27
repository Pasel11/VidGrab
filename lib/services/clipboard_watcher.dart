import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'platform_detector.dart';
import '../models/video_info.dart';

/// خدمة مراقبة الحافظة الذكية
/// تكشف تلقائياً روابط الفيديو عند لصقها أو فتح التطبيق
class ClipboardWatcher extends ChangeNotifier {
  final PlatformDetector _detector = PlatformDetector();
  String? _lastDetectedUrl;
  String? _detectedPlatform;
  bool _hasNewUrl = false;
  Timer? _watchTimer;
  String _lastClipboardContent = '';
  bool _isWatching = false;

  String? get lastDetectedUrl => _lastDetectedUrl;
  String? get detectedPlatform => _detectedPlatform;
  bool get hasNewUrl => _hasNewUrl;

  /// فحص الحافظة مرة واحدة عند فتح التطبيق
  Future<bool> checkClipboardOnAppStart() async {
    try {
      final data = await Clipboard.getData('text/plain');
      if (data?.text != null && data!.text!.isNotEmpty) {
        final text = data.text!.trim();
        if (text != _lastClipboardContent && _detector.isSupportedPlatform(text)) {
          _lastClipboardContent = text;
          _lastDetectedUrl = text;
          _detectedPlatform = _detector.detectPlatform(text).name;
          _hasNewUrl = true;
          notifyListeners();
          return true;
        }
      }
    } catch (_) {}
    return false;
  }

  /// بدء مراقبة الحافظة بشكل دوري
  void startWatching({Duration interval = const Duration(seconds: 2)}) {
    if (_isWatching) return;
    _isWatching = true;
    _watchTimer?.cancel();
    _watchTimer = Timer.periodic(interval, (_) => _checkClipboard());
  }

  /// إيقاف المراقبة
  void stopWatching() {
    _isWatching = false;
    _watchTimer?.cancel();
    _watchTimer = null;
  }

  Future<void> _checkClipboard() async {
    try {
      final data = await Clipboard.getData('text/plain');
      if (data?.text == null || data!.text!.trim().isEmpty) return;
      final text = data.text!.trim();
      if (text == _lastClipboardContent) return;

      _lastClipboardContent = text;

      if (_detector.isSupportedPlatform(text)) {
        _lastDetectedUrl = text;
        _detectedPlatform = _detector.detectPlatform(text).name;
        _hasNewUrl = true;
        notifyListeners();
      }
    } catch (_) {}
  }

  /// إعادة تعيين حالة الرابط الجديد بعد عرضه
  void dismissUrl() {
    _hasNewUrl = false;
    notifyListeners();
  }

  /// مسح الرابط المكتشف
  void clearDetected() {
    _lastDetectedUrl = null;
    _detectedPlatform = null;
    _hasNewUrl = false;
    _lastClipboardContent = '';
    notifyListeners();
  }

  /// تحليل سريع للرابط
  Map<String, dynamic> analyzeUrl(String url) {
    final platform = _detector.detectPlatform(url);
    return {
      'isValid': _detector.isValidUrl(url),
      'isSupported': platform != VideoPlatform.unknown,
      'platform': platform.name,
      'platformColor': platform.brandColor,
      'url': url,
    };
  }

  @override
  void dispose() {
    stopWatching();
    super.dispose();
  }
}