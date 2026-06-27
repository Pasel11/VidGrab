import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/video_info.dart';
import 'platform_detector.dart';

/// خدمة جلب معلومات الفيديو الحقيقية من APIs متعددة
/// تدعم: Cobalt API v7+ + Backend yt-dlp + APIs بديلة
class VideoApiService {
  /// قائمة خوادم Cobalt العامة (fallback)
  static const List<String> _cobaltInstances = [
    'https://api.cobalt.tools',
  ];

  /// رابط الباكيند الخاص (عدّله لرابط سيرفرك)
  /// مثال: 'https://your-server.com/api'
  static String backendBaseUrl = '';

  final Dio _dio;
  final PlatformDetector _detector;

  VideoApiService({Dio? dio, PlatformDetector? detector})
      : _dio = dio ?? Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 45),
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            'User-Agent': 'VidGrab/4.0 (Android)',
          },
        )),
        _detector = detector ?? PlatformDetector();

  /// جلب معلومات الفيديو الحقيقية - يجرب عدة APIs
  Future<VideoInfo?> fetchVideoInfo(String url) async {
    // محاولة الباكيند أولاً إذا تم تعيينه
    if (backendBaseUrl.isNotEmpty) {
      try {
        debugPrint('[VideoAPI] جاري المحاولة من الباكيند...');
        return await _fetchFromBackend(url);
      } catch (e) {
        debugPrint('[VideoAPI] Backend فشل: $e, جاري تجربة Cobalt...');
      }
    }

    // تجربة خوادم Cobalt بالترتيب
    for (final instance in _cobaltInstances) {
      try {
        debugPrint('[VideoAPI] جاري المحاولة من: $instance');
        final result = await _fetchFromCobalt(url, instance);
        if (result != null) return result;
      } catch (e) {
        debugPrint('[VideoAPI] $instance فشل: $e');
      }
    }

    throw Exception('لم يتم العثور على فيديو. تأكد أن الرابط صحيح وأن المنصة مدعومة.');
  }

  /// ─── Cobalt API v7+ ───
  Future<VideoInfo?> _fetchFromCobalt(String url, String instance) async {
    final platform = _detector.detectPlatform(url);
    final analysis = _detector.analyzeUrl(url);

    // تحديد جودة الفيديو
    String videoQuality = '1080';
    if (platform == VideoPlatform.youtube) {
      videoQuality = '1080';
    }

    // تحديد نوع التحميل
    String downloadMode = 'auto'; // auto | audio | mute
    bool isAudioOnly = analysis.isAudioOnly || platform.isAudioPlatform;
    if (isAudioOnly) {
      downloadMode = 'audio';
    }

    final requestBody = {
      'url': url,
      'videoQuality': videoQuality,
      'downloadMode': downloadMode,
      'audioFormat': 'mp3',
      'filenameStyle': 'basic',
    };

    debugPrint('[VideoAPI] طلب Cobalt: $requestBody');

    final response = await _dio.post(
      '$instance/',
      data: requestBody,
      options: Options(
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    debugPrint('[VideoAPI] استجابة Cobalt: ${response.statusCode} - ${response.data}');

    // فحص حالة الاستجابة
    if (response.statusCode == 429) {
      throw Exception('طلبات كثيرة، انتظر قليلاً');
    }

    if (response.statusCode == 400 || response.statusCode == 401) {
      // قد يحتاج API key - نحاول بدون
      final data = response.data;
      if (data is Map && data['error'] != null) {
        throw Exception('الخادم رفض الطلب: ${data['error']}');
      }
      throw Exception('الخادم رفض الطلب. حاول مرة أخرى.');
    }

    if (response.statusCode != 200) {
      throw Exception('خطأ في الخادم: ${response.statusCode}');
    }

    final data = response.data;
    if (data == null) throw Exception('لم يتم العثور على فيديو');

    return _parseCobaltResponse(data, url, platform, analysis);
  }

  /// تحليل استجابة Cobalt v7+
  VideoInfo? _parseCobaltResponse(
    dynamic data,
    String originalUrl,
    VideoPlatform platform,
    dynamic analysis,
  ) {
    String? downloadUrl;
    String? audioUrl;
    String title = '';
    String thumbnail = '';
    String? filename;

    if (data is! Map<String, dynamic>) {
      throw Exception('صيغة استجابة غير صحيحة');
    }

    final status = data['status'] as String?;

    // حالة الخطأ
    if (status == 'error') {
      final errorCode = data['error'] as? {
        'code': dynamic,
        'context': dynamic,
      };
      final code = errorCode?['code'] ?? 'unknown';
      debugPrint('[VideoAPI] Cobalt error: $code');
      
      if (code == 'content.video.unavailable') {
        throw Exception('الفيديو غير متاح أو محذوف');
      }
      if (code == 'content.post.unavailable') {
        throw Exception('المنشور غير متاح');
      }
      if (code == 'link.not_supported') {
        throw Exception('هذه المنصة غير مدعومة حالياً');
      }
      throw Exception('لم يتم العثور على فيديو في هذا الرابط');
    }

    // حالة picker (صور/فيديوهات متعددة)
    if (status == 'picker') {
      final picker = data['picker'] as List<dynamic>?;
      if (picker != null && picker.isNotEmpty) {
        final first = picker[0] as Map<String, dynamic>;
        downloadUrl = first['url'] as String?;
        if (downloadUrl == null && picker.length > 1) {
          downloadUrl = (picker[1] as Map<String, dynamic>)['url'] as String?;
        }
        filename = first['filename'] as String?;
      }
    }

    // حالة redirect أو tunnel (رابط مباشر)
    if (status == 'redirect' || status == 'tunnel') {
      downloadUrl = data['url'] as String?;
    }

    // استخراج المعلومات
    filename = filename ?? data['filename'] as String?;
    audioUrl = data['audio'] as String?;

    // بناء العنوان
    if (filename != null && filename.isNotEmpty && filename != 'NA') {
      // إزالة امتداد الملف من العنوان
      title = filename.replaceAll(RegExp(r'\.[^.]+$'), '');
    }
    if (title.isEmpty) {
      title = 'فيديو من ${platform.name}';
    }

    // استخراج الصورة المصغرة
    thumbnail = data['thumbnail'] as String? ?? '';

    // تحليل نوع المحتوى
    String contentType = analysis is UrlAnalysisResult ? analysis.contentType : 'video';
    if (isAudioOnlyPlatform(platform)) {
      contentType = 'audio';
    }

    // بناء قائمة الجودات
    final qualities = _buildQualities(
      downloadUrl: downloadUrl,
      audioUrl: audioUrl,
      platform: platform,
      cobaltData: data,
    );

    if (qualities.isEmpty) {
      throw Exception('لم يتم العثور على روابط تحميل صالحة');
    }

    return VideoInfo(
      url: originalUrl,
      platform: platform,
      title: title,
      thumbnailUrl: thumbnail,
      author: '',
      contentType: contentType,
      availableQualities: qualities,
      description: 'فيديو من ${platform.name}',
    );
  }

  bool isAudioOnlyPlatform(VideoPlatform platform) {
    return platform == VideoPlatform.soundcloud;
  }

  /// ─── Backend yt-dlp API ───
  Future<VideoInfo?> _fetchFromBackend(String url) async {
    final response = await _dio.post(
      '$backendBaseUrl/api/video-info',
      data: {'url': url},
    );

    final data = response.data as Map<String, dynamic>;
    final platform = _detector.detectPlatform(url);

    final formats = data['formats'] as List<dynamic>? ?? [];
    final qualities = formats.map((f) {
      final format = f as Map<String, dynamic>;
      return VideoQuality(
        label: format['label'] ?? format['format'] ?? '',
        resolution: format['resolution'] ?? format['height']?.toString() ?? '',
        format: format['ext'] ?? 'mp4',
        fileSize: format['filesize'] != null
            ? _formatBytes(format['filesize'] as int)
            : '',
        downloadUrl: format['url'] ?? '',
      );
    }).toList();

    if (qualities.isEmpty) {
      qualities.add(VideoQuality(
        label: 'أفضل جودة',
        resolution: '1080p',
        format: 'mp4',
        fileSize: data['filesize'] != null
            ? _formatBytes(data['filesize'] as int)
            : '',
        downloadUrl: data['downloadUrl'] ?? data['url'] ?? '',
      ));
    }

    return VideoInfo(
      url: url,
      platform: platform,
      title: data['title'] as String? ?? 'فيديو من ${platform.name}',
      thumbnailUrl: data['thumbnail'] as String? ?? '',
      author: data['uploader'] as String? ?? data['channel'] as String? ?? '',
      duration: data['duration'] != null
          ? Duration(seconds: data['duration'] as int)
          : null,
      contentType: _detector.analyzeUrl(url).contentType,
      viewCount: data['view_count'] as int? ?? 0,
      likeCount: data['like_count'] as int? ?? 0,
      availableQualities: qualities,
      description: data['description'] as String?,
    );
  }

  /// بناء قائمة الجودات من بيانات Cobalt
  List<VideoQuality> _buildQualities({
    String? downloadUrl,
    String? audioUrl,
    required VideoPlatform platform,
    Map<String, dynamic>? cobaltData,
  }) {
    final qualities = <VideoQuality>[];

    if (downloadUrl != null && downloadUrl.isNotEmpty) {
      // إذا كان هناك رابط تحميل فيديو
      if (platform == VideoPlatform.youtube) {
        // يوتيوب - عدة جودات (نستخدم نفس الرابط مع تسميات مختلفة)
        // Cobalt يرجع أفضل جودة متاحة بناءً على videoQuality المطلوب
        qualities.addAll([
          VideoQuality(
            label: 'أعلى جودة متاحة',
            resolution: '1080p',
            format: 'MP4',
            fileSize: '',
            downloadUrl: downloadUrl,
            hasAudio: true,
          ),
        ]);
      } else {
        // باقي المنصات
        qualities.addAll([
          VideoQuality(
            label: 'أعلى جودة',
            resolution: '1080p',
            format: 'MP4',
            fileSize: '',
            downloadUrl: downloadUrl,
            hasAudio: true,
          ),
        ]);
      }
    }

    // رابط الصوت
    if (audioUrl != null && audioUrl.isNotEmpty) {
      qualities.add(VideoQuality(
        label: 'صوت فقط MP3',
        resolution: '320kbps',
        format: 'MP3',
        fileSize: '',
        downloadUrl: audioUrl,
        hasAudio: true,
      ));
    }

    return qualities;
  }

  /// تحويل البايت إلى نص مقروء
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}