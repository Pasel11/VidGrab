import '../models/video_info.dart';

/// كاشف المنصات المتقدم - يدعم 20+ منصة بتحليل ذكي للروابط
class PlatformDetector {
  static final Map<String, VideoPlatform> _domainMap = {
    // YouTube
    'youtube.com': VideoPlatform.youtube,
    'youtu.be': VideoPlatform.youtube,
    'youtube-nocookie.com': VideoPlatform.youtube,
    'm.youtube.com': VideoPlatform.youtube,
    'yt.be': VideoPlatform.youtube,
    'youtube.com': VideoPlatform.youtube,
    'youtubei.googleapis.com': VideoPlatform.youtube,
    // Instagram
    'instagram.com': VideoPlatform.instagram,
    'instagr.am': VideoPlatform.instagram,
    'www.instagram.com': VideoPlatform.instagram,
    'help.instagram.com': VideoPlatform.instagram,
    // TikTok
    'tiktok.com': VideoPlatform.tiktok,
    'vm.tiktok.com': VideoPlatform.tiktok,
    'm.tiktok.com': VideoPlatform.tiktok,
    'vt.tiktok.com': VideoPlatform.tiktok,
    // X (Twitter)
    'x.com': VideoPlatform.twitter,
    'twitter.com': VideoPlatform.twitter,
    't.co': VideoPlatform.twitter,
    'mobile.twitter.com': VideoPlatform.twitter,
    'c.twimg.com': VideoPlatform.twitter,
    // Facebook
    'facebook.com': VideoPlatform.facebook,
    'fb.watch': VideoPlatform.facebook,
    'fb.com': VideoPlatform.facebook,
    'm.facebook.com': VideoPlatform.facebook,
    'web.facebook.com': VideoPlatform.facebook,
    'video.facebook.com': VideoPlatform.facebook,
    'fbcdn.net': VideoPlatform.facebook,
    // Snapchat
    'snapchat.com': VideoPlatform.snapchat,
    't.snapchat.com': VideoPlatform.snapchat,
    'story.snapchat.com': VideoPlatform.snapchat,
    // Pinterest
    'pinterest.com': VideoPlatform.pinterest,
    'pin.it': VideoPlatform.pinterest,
    'www.pinterest.com': VideoPlatform.pinterest,
    // LinkedIn
    'linkedin.com': VideoPlatform.linkedin,
    'www.linkedin.com': VideoPlatform.linkedin,
    // Reddit
    'reddit.com': VideoPlatform.reddit,
    'www.reddit.com': VideoPlatform.reddit,
    'old.reddit.com': VideoPlatform.reddit,
    'redd.it': VideoPlatform.reddit,
    'v.redd.it': VideoPlatform.reddit,
    // Tumblr
    'tumblr.com': VideoPlatform.tumblr,
    'www.tumblr.com': VideoPlatform.tumblr,
    'at.tumblr.com': VideoPlatform.tumblr,
    // Vimeo
    'vimeo.com': VideoPlatform.vimeo,
    'player.vimeo.com': VideoPlatform.vimeo,
    // Dailymotion
    'dailymotion.com': VideoPlatform.dailymotion,
    'dai.ly': VideoPlatform.dailymotion,
    'www.dailymotion.com': VideoPlatform.dailymotion,
    // منصات إضافية
    'twitch.tv': VideoPlatform.twitch,
    'www.twitch.tv': VideoPlatform.twitch,
    'clips.twitch.tv': VideoPlatform.twitch,
    'soundcloud.com': VideoPlatform.soundcloud,
    'm.soundcloud.com': VideoPlatform.soundcloud,
    'on.soundcloud.com': VideoPlatform.soundcloud,
    'whatsapp.com': VideoPlatform.whatsapp,
    'wa.me': VideoPlatform.whatsapp,
    'telegram.org': VideoPlatform.telegram,
    't.me': VideoPlatform.telegram,
    'likee.video': VideoPlatform.likee,
    'like.video': VideoPlatform.likee,
    'l.likee.video': VideoPlatform.likee,
    'rumble.com': VideoPlatform.rumble,
    'bilibili.com': VideoPlatform.bilibili,
    'm.bilibili.com': VideoPlatform.bilibili,
    'b23.tv': VideoPlatform.bilibili,
    'streamable.com': VideoPlatform.streamable,
  };

  /// أنماط إضافية للكشف عن الروابط المختصرة
  static final List<RegExp> _urlPatterns = [
    RegExp(r'https?://(www\.)?youtu\.be/[a-zA-Z0-9_-]+'),
    RegExp(r'https?://(www\.)?youtube\.com/(watch|shorts|embed|live)/[a-zA-Z0-9_?=&-]+'),
    RegExp(r'https?://(www\.)?instagram\.com/(p|reel|reels|tv|stories)/[a-zA-Z0-9_/-]+'),
    RegExp(r'https?://(vm\.)?tiktok\.com/[a-zA-Z0-9]+'),
    RegExp(r'https?://(www\.)?tiktok\.com/@[^/]+/video/\d+'),
    RegExp(r'https?://(x\.com|twitter\.com)/[^/]+/status/\d+'),
    RegExp(r'https?://(www\.)?facebook\.com/[^/]+/(videos|posts|reel)/\d+'),
    RegExp(r'https?://fb\.watch/[a-zA-Z0-9]+'),
    RegExp(r'https?://t\.me/[a-zA-Z0-9_]+/\d+'),
    RegExp(r'https?://v\.redd\.it/[a-zA-Z0-9]+'),
  ];

  /// كشف المنصة من الرابط
  VideoPlatform detectPlatform(String url) {
    if (url.isEmpty) return VideoPlatform.unknown;
    try {
      final uri = Uri.parse(url);
      final host = uri.host.toLowerCase();

      // تطابق مباشر مع الخريطة
      for (final entry in _domainMap.entries) {
        if (host == entry.key || host.endsWith('.${entry.key}')) {
          return entry.value;
        }
      }

      // كشف بناءً على الأنماط
      for (final pattern in _urlPatterns) {
        if (pattern.hasMatch(url)) {
          // تحديد المنصة من النمط
          if (url.contains('youtu') || url.contains('youtube')) return VideoPlatform.youtube;
          if (url.contains('instagram') || url.contains('instagr')) return VideoPlatform.instagram;
          if (url.contains('tiktok')) return VideoPlatform.tiktok;
          if (url.contains('twitter') || url.contains('x.com') || url.contains('/status/')) return VideoPlatform.twitter;
          if (url.contains('facebook') || url.contains('fb.watch') || url.contains('fbcdn')) return VideoPlatform.facebook;
          if (url.contains('reddit') || url.contains('redd.it')) return VideoPlatform.reddit;
          if (url.contains('telegram') || url.contains('t.me')) return VideoPlatform.telegram;
        }
      }
    } catch (_) {}
    return VideoPlatform.unknown;
  }

  /// التحقق من صلاحية الرابط
  bool isValidUrl(String url) {
    if (url.isEmpty) return false;
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https') && uri.host.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// هل المنصة مدعومة؟
  bool isSupportedPlatform(String url) {
    return detectPlatform(url) != VideoPlatform.unknown;
  }

  /// تحليل شامل للرابط - يُرجع معلومات مفصلة
  UrlAnalysisResult analyzeUrl(String url) {
    final platform = detectPlatform(url);
    final isValid = isValidUrl(url);
    String? videoId;
    String contentType = 'video'; // video, audio, image, story, reel, live

    try {
      final uri = Uri.parse(url);
      final path = uri.path.toLowerCase();

      // استخراج معرف الفيديو
      if (url.contains('youtu')) {
        if (url.contains('youtu.be/')) {
          videoId = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : null;
        } else if (url.contains('watch')) {
          videoId = uri.queryParameters['v'];
        } else if (url.contains('shorts/') || url.contains('live/')) {
          videoId = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : null;
        }
      } else if (url.contains('instagram')) {
        if (path.contains('/reel')) contentType = 'reel';
        else if (path.contains('/stories')) contentType = 'story';
        else if (path.contains('/tv')) contentType = 'igtv';
      } else if (url.contains('tiktok')) {
        if (path.contains('/video/')) contentType = 'video';
      } else if (url.contains('facebook')) {
        if (path.contains('/reel')) contentType = 'reel';
        else if (path.contains('/live')) contentType = 'live';
        else if (path.contains('/videos')) contentType = 'video';
      } else if (url.contains('twitch')) {
        if (path.contains('/clip')) contentType = 'clip';
        else if (path.contains('/videos')) contentType = 'video';
        else contentType = 'live';
      } else if (url.contains('soundcloud')) {
        contentType = 'audio';
      }
    } catch (_) {}

    return UrlAnalysisResult(
      url: url,
      isValid: isValid,
      platform: platform,
      videoId: videoId,
      contentType: contentType,
      isSupported: platform != VideoPlatform.unknown,
      isShortForm: contentType == 'reel' || contentType == 'story' || platform == VideoPlatform.tiktok,
      isLive: contentType == 'live',
      isAudioOnly: contentType == 'audio' || platform == VideoPlatform.soundcloud,
    );
  }

  /// استخراج جميع الروابط من نص
  List<String> extractUrls(String text) {
    final urlRegExp = RegExp(
      r'https?://[^\s<>"{}|\\^`\[\]]+',
      caseSensitive: false,
    );
    return urlRegExp.allMatches(text).map((m) => m.group(0)!).toList();
  }
}

/// نتيجة تحليل الرابط
class UrlAnalysisResult {
  final String url;
  final bool isValid;
  final VideoPlatform platform;
  final String? videoId;
  final String contentType;
  final bool isSupported;
  final bool isShortForm;
  final bool isLive;
  final bool isAudioOnly;

  UrlAnalysisResult({
    required this.url,
    required this.isValid,
    required this.platform,
    this.videoId,
    required this.contentType,
    required this.isSupported,
    required this.isShortForm,
    required this.isLive,
    required this.isAudioOnly,
  });
}