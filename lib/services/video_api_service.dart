import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/video_info.dart';
import 'platform_detector.dart';

/// خدمة جلب معلومات الفيديو الحقيقية من API
/// تدعم: Cobalt API + Backend yt-dlp
class VideoApiService {
  static const String _cobaltApiUrl = 'https://api.cobalt.tools/api/json';
  
  /// رابط الباكيند الخاص (عدّله لرابط سيرفرك)
  /// مثال: 'https://your-server.com/api'
  static String backendBaseUrl = '';

  final Dio _dio;
  final PlatformDetector _detector;

  VideoApiService({Dio? dio, PlatformDetector? detector})
      : _dio = dio ?? Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 30),
          headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
        )),
        _detector = detector ?? PlatformDetector();

  /// جلب معلومات الفيديو الحقيقية
  Future<VideoInfo?> fetchVideoInfo(String url) async {
    try {
      // محاولة الباكيند أولاً إذا تم تعيينه
      if (backendBaseUrl.isNotEmpty) {
        try {
          return await _fetchFromBackend(url);
        } catch (e) {
          debugPrint('[VideoAPI] Backend failed: $e, trying Cobalt...');
        }
      }

      // استخدام Cobalt API كـ fallback
      return await _fetchFromCobalt(url);
    } on DioException catch (e) {
      debugPrint('[VideoAPI] Network error: ${e.message}');
      throw Exception('خطأ في الاتصال بالخادم: ${e.message}');
    } catch (e) {
      debugPrint('[VideoAPI] Error: $e');
      rethrow;
    }
  }

  /// ─── Cobalt API (مجاني، بدون تسجيل) ───
  Future<VideoInfo?> _fetchFromCobalt(String url) async {
    final platform = _detector.detectPlatform(url);

    // جلب معلومات الفيديو
    final response = await _dio.post(
      _cobaltApiUrl,
      data: {
        'url': url,
        'vCodec': 'h264',
        'vQuality': '1080',
        'aFormat': 'mp3',
        'isAudioOnly': false,
        'filenamePattern': 'basic',
      },
      options: Options(
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    final data = response.data;

    // Cobalt يرجع رابط التحميل المباشر أو معلومات الفيديو
    if (data == null) throw Exception('لم يتم العثور على فيديو');

    // معالجة الاستجابة
    String? downloadUrl;
    String title = '';
    String thumbnail = '';
    String? audioUrl;

    if (data is Map<String, dynamic>) {
      downloadUrl = data['url'] as String?;
      audioUrl = data['audioUrl'] as String?;
      title = data['filename'] as String? ?? 
               data['title'] as String? ?? 
               'فيديو من ${platform.name}';
      thumbnail = '';
    }

    // إذا لم نحصل على عنوان، نستخدم عنوان عام
    if (title.isEmpty || title == 'NA') {
      title = 'فيديو من ${platform.name}';
    }

    // تحليل نوع المحتوى
    String contentType = 'video';
    if (_detector.analyzeUrl(url).isAudioOnly) {
      contentType = 'audio';
    }

    // بناء قائمة الجودات المتاحة
    final qualities = _buildQualities(
      downloadUrl: downloadUrl,
      audioUrl: audioUrl,
      platform: platform,
    );

    return VideoInfo(
      url: url,
      platform: platform,
      title: title,
      thumbnailUrl: thumbnail,
      author: '',
      contentType: contentType,
      availableQualities: qualities,
      description: 'فيديو من ${platform.name}',
    );
  }

  /// ─── Backend yt-dlp API ───
  Future<VideoInfo?> _fetchFromBackend(String url) async {
    final response = await _dio.post(
      '$backendBaseUrl/api/video-info',
      data: {'url': url},
    );

    final data = response.data as Map<String, dynamic>;
    final platform = _detector.detectPlatform(url);

    // تحليل الجودات من الباكيند
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
      // إذا لم توجد جودات، نستخدم رابط التحميل المباشر
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

  /// بناء قائمة الجودات
  List<VideoQuality> _buildQualities({
    String? downloadUrl,
    String? audioUrl,
    required VideoPlatform platform,
  }) {
    final qualities = <VideoQuality>[];

    // إذا لدينا رابط تحميل مباشر
    if (downloadUrl != null && downloadUrl.isNotEmpty) {
      qualities.addAll([
        VideoQuality(
          label: 'أعلى جودة',
          resolution: '1080p',
          format: 'MP4',
          fileSize: '~50 MB',
          downloadUrl: downloadUrl,
          hasAudio: true,
        ),
        VideoQuality(
          label: 'HD',
          resolution: '720p',
          format: 'MP4',
          fileSize: '~30 MB',
          downloadUrl: downloadUrl,
          hasAudio: true,
        ),
        VideoQuality(
          label: 'SD',
          resolution: '480p',
          format: 'MP4',
          fileSize: '~15 MB',
          downloadUrl: downloadUrl,
          hasAudio: true,
        ),
      ]);
    }

    // إذا لدينا رابط صوتي
    if (audioUrl != null && audioUrl.isNotEmpty) {
      qualities.add(VideoQuality(
        label: 'صوت فقط MP3',
        resolution: '320kbps',
        format: 'MP3',
        fileSize: '~5 MB',
        downloadUrl: audioUrl,
        hasAudio: true,
      ));
    }

    // إذا لم نحصل على أي روابط، نضيف جودات فارغة مع رسالة
    if (qualities.isEmpty) {
      // سيتم عرض رسالة للمستخدم بتحديد الجودة
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