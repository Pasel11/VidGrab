import 'package:flutter/material.dart';
enum VideoPlatform {
  youtube('YouTube', 'assets/icons/youtube.svg', 'https://www.youtube.com', Color(0xFFFF0000)),
  instagram('Instagram', 'assets/icons/instagram.svg', 'https://www.instagram.com', Color(0xFFE4405F)),
  tiktok('TikTok', 'assets/icons/tiktok.svg', 'https://www.tiktok.com', Color(0xFF000000)),
  twitter('X (Twitter)', 'assets/icons/twitter.svg', 'https://www.x.com', Color(0xFF1DA1F2)),
  facebook('Facebook', 'assets/icons/facebook.svg', 'https://www.facebook.com', Color(0xFF1877F2)),
  snapchat('Snapchat', 'assets/icons/snapchat.svg', 'https://www.snapchat.com', Color(0xFFFFFC00)),
  pinterest('Pinterest', 'assets/icons/pinterest.svg', 'https://www.pinterest.com', Color(0xFFBD081C)),
  linkedin('LinkedIn', 'assets/icons/linkedin.svg', 'https://www.linkedin.com', Color(0xFF0A66C2)),
  reddit('Reddit', 'assets/icons/reddit.svg', 'https://www.reddit.com', Color(0xFFFF4500)),
  tumblr('Tumblr', 'assets/icons/tumblr.svg', 'https://www.tumblr.com', Color(0xFF35465C)),
  vimeo('Vimeo', 'assets/icons/vimeo.svg', 'https://www.vimeo.com', Color(0xFF1AB7EA)),
  dailymotion('Dailymotion', 'assets/icons/dailymotion.svg', 'https://www.dailymotion.com', Color(0xFF00AAFF)),
  twitch('Twitch', 'assets/icons/twitch.svg', 'https://www.twitch.tv', Color(0xFF9146FF)),
  soundcloud('SoundCloud', 'assets/icons/soundcloud.svg', 'https://www.soundcloud.com', Color(0xFFFF5500)),
  whatsapp('WhatsApp', 'assets/icons/whatsapp.svg', 'https://www.whatsapp.com', Color(0xFF25D366)),
  telegram('Telegram', 'assets/icons/telegram.svg', 'https://telegram.org', Color(0xFF0088CC)),
  likee('Likee', 'assets/icons/likee.svg', 'https://likee.video', Color(0xFFEE1D52)),
  rumble('Rumble', 'assets/icons/rumble.svg', 'https://rumble.com', Color(0xFF85C742)),
  bilibili('Bilibili', 'assets/icons/bilibili.svg', 'https://bilibili.com', Color(0xFF00A1D6)),
  streamable('Streamable', 'assets/icons/streamable.svg', 'https://streamable.com', Color(0xFF0ABEF0)),
  unknown('Unknown', '', '', Color(0xFF64748B));

  final String name;
  final String iconPath;
  final String baseUrl;
  final Color brandColor;

  const VideoPlatform(this.name, this.iconPath, this.baseUrl, this.brandColor);

  /// أيقونة Material كبديل لـ SVG
  IconData get materialIcon {
    switch (this) {
      case VideoPlatform.youtube: return Icons.play_circle_filled;
      case VideoPlatform.instagram: return Icons.camera_alt_rounded;
      case VideoPlatform.tiktok: return Icons.music_note_rounded;
      case VideoPlatform.twitter: return Icons.alternate_email_rounded;
      case VideoPlatform.facebook: return Icons.facebook_rounded;
      case VideoPlatform.snapchat: return Icons.flash_on_rounded;
      case VideoPlatform.pinterest: return Icons.push_pin_rounded;
      case VideoPlatform.linkedin: return Icons.work_rounded;
      case VideoPlatform.reddit: return Icons.forum_rounded;
      case VideoPlatform.tumblr: return Icons.article_rounded;
      case VideoPlatform.vimeo: return Icons.videocam_rounded;
      case VideoPlatform.dailymotion: return Icons.video_library_rounded;
      case VideoPlatform.twitch: return Icons.live_tv_rounded;
      case VideoPlatform.soundcloud: return Icons.headphones_rounded;
      case VideoPlatform.whatsapp: return Icons.chat_rounded;
      case VideoPlatform.telegram: return Icons.send_rounded;
      case VideoPlatform.likee: return Icons.star_rounded;
      case VideoPlatform.rumble: return Icons.videocam_rounded;
      case VideoPlatform.bilibili: return Icons.tv_rounded;
      case VideoPlatform.streamable: return Icons.play_circle_outline_rounded;
      case VideoPlatform.unknown: return Icons.video_file_rounded;
    }
  }

  /// لون متدرج للخلفية
  List<Color> get gradient {
    switch (this) {
      case VideoPlatform.youtube: return [const Color(0xFFFF0000), const Color(0xFFCC0000)];
      case VideoPlatform.instagram: return [const Color(0xFFE4405F), const Color(0xFFF77737)];
      case VideoPlatform.tiktok: return [const Color(0xFF25F4EE), const Color(0xFFFE2C55)];
      case VideoPlatform.twitter: return [const Color(0xFF1DA1F2), const Color(0xFF0D8BD9)];
      case VideoPlatform.facebook: return [const Color(0xFF1877F2), const Color(0xFF0C5DC7)];
      case VideoPlatform.snapchat: return [const Color(0xFFFFFC00), const Color(0xFFFFCD00)];
      case VideoPlatform.pinterest: return [const Color(0xFFBD081C), const Color(0xFFE60023)];
      case VideoPlatform.linkedin: return [const Color(0xFF0A66C2), const Color(0xFF004182)];
      case VideoPlatform.reddit: return [const Color(0xFFFF4500), const Color(0xFFFF6A33)];
      case VideoPlatform.tumblr: return [const Color(0xFF35465C), const Color(0xFF32506D)];
      case VideoPlatform.vimeo: return [const Color(0xFF1AB7EA), const Color(0xFF00ADEF)];
      case VideoPlatform.dailymotion: return [const Color(0xFF00AAFF), const Color(0xFF0066CC)];
      case VideoPlatform.twitch: return [const Color(0xFF9146FF), const Color(0xFF6441A5)];
      case VideoPlatform.soundcloud: return [const Color(0xFFFF5500), const Color(0xFFCC4400)];
      case VideoPlatform.whatsapp: return [const Color(0xFF25D366), const Color(0xFF128C7E)];
      case VideoPlatform.telegram: return [const Color(0xFF0088CC), const Color(0xFF006699)];
      case VideoPlatform.likee: return [const Color(0xFFEE1D52), const Color(0xFFFF004F)];
      case VideoPlatform.rumble: return [const Color(0xFF85C742), const Color(0xFF6BA030)];
      case VideoPlatform.bilibili: return [const Color(0xFF00A1D6), const Color(0xFFFB7299)];
      case VideoPlatform.streamable: return [const Color(0xFF0ABEF0), const Color(0xFF0890C0)];
      case VideoPlatform.unknown: return [const Color(0xFF64748B), const Color(0xFF475569)];
    }
  }

  /// ما إذا كانت المنصة تدعم الصوت فقط
  bool get isAudioPlatform => this == VideoPlatform.soundcloud;

  /// ما إذا كانت المنصة تدعم البث المباشر
  bool get supportsLive => this == VideoPlatform.twitch || this == VideoPlatform.youtube || this == VideoPlatform.facebook;
}

class VideoInfo {
  final String url;
  final VideoPlatform platform;
  final String title;
  final String thumbnailUrl;
  final String author;
  final Duration? duration;
  final List<VideoQuality> availableQualities;
  final String? description;
  final String contentType; // video, audio, image, story, reel, live
  final int viewCount;
  final int likeCount;

  VideoInfo({
    required this.url,
    required this.platform,
    required this.title,
    this.thumbnailUrl = '',
    this.author = '',
    this.duration,
    this.availableQualities = const [],
    this.description,
    this.contentType = 'video',
    this.viewCount = 0,
    this.likeCount = 0,
  });
}

class VideoQuality {
  final String label;
  final String resolution;
  final String format;
  final String fileSize;
  final String downloadUrl;
  final int bitrate; // kbps
  final bool isHDR;
  final bool hasAudio;

  VideoQuality({
    required this.label,
    required this.resolution,
    required this.format,
    required this.fileSize,
    required this.downloadUrl,
    this.bitrate = 0,
    this.isHDR = false,
    this.hasAudio = true,
  });

  /// تحليل حجم الملف من النص
  int get fileSizeBytes {
    final match = RegExp(r'(\d+(?:\.\d+)?)\s*(B|KB|MB|GB)').firstMatch(fileSize.toUpperCase());
    if (match == null) return 0;
    final value = double.parse(match.group(1)!);
    switch (match.group(2)) {
      case 'GB': return (value * 1024 * 1024 * 1024).toInt();
      case 'MB': return (value * 1024 * 1024).toInt();
      case 'KB': return (value * 1024).toInt();
      default: return value.toInt();
    }
  }

  bool get isAudioOnly => format.toUpperCase() == 'MP3' || format.toUpperCase() == 'AAC' || format.toUpperCase() == 'WAV' || format.toUpperCase() == 'OGG';
}