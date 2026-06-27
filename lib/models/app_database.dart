import 'package:hive/hive.dart';

part 'app_database.g.dart';

@HiveType(typeId: 0)
class VideoInfoEntity extends HiveObject {
  @HiveField(0)
  String url;

  @HiveField(1)
  String platform;

  @HiveField(2)
  String title;

  @HiveField(3)
  String thumbnailUrl;

  @HiveField(4)
  String author;

  @HiveField(5)
  int durationSeconds;

  @HiveField(6)
  String description;

  @HiveField(7)
  DateTime fetchedAt;

  VideoInfoEntity({
    required this.url,
    required this.platform,
    required this.title,
    this.thumbnailUrl = '',
    this.author = '',
    this.durationSeconds = 0,
    this.description = '',
    DateTime? fetchedAt,
  }) : fetchedAt = fetchedAt ?? DateTime.now();
}

@HiveType(typeId: 1)
class DownloadTaskEntity extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String url;

  @HiveField(2)
  String title;

  @HiveField(3)
  String thumbnailUrl;

  @HiveField(4)
  String platform;

  @HiveField(5)
  String quality;

  @HiveField(6)
  String format;

  @HiveField(7)
  String filePath;

  @HiveField(8)
  int fileSizeBytes;

  @HiveField(9)
  int status; // 0=waiting, 1=fetching, 2=downloading, 3=completed, 4=failed, 5=paused, 6=cancelled

  @HiveField(10)
  double progress;

  @HiveField(11)
  DateTime createdAt;

  @HiveField(12)
  DateTime? completedAt;

  @HiveField(13)
  String folder; // category folder

  @HiveField(14)
  bool isSecret; // in secret folder

  @HiveField(15)
  bool isFavorite;

  @HiveField(16)
  int downloadSpeed; // bytes per second

  @HiveField(17)
  String? resumeKey; // for resumable downloads

  @HiveField(18)
  DateTime? scheduledAt; // for scheduled downloads

  @HiveField(19)
  int retryCount;

  DownloadTaskEntity({
    required this.id,
    required this.url,
    required this.title,
    this.thumbnailUrl = '',
    this.platform = '',
    this.quality = '',
    this.format = 'MP4',
    this.filePath = '',
    this.fileSizeBytes = 0,
    this.status = 0,
    this.progress = 0.0,
    DateTime? createdAt,
    this.completedAt,
    this.folder = 'عام',
    this.isSecret = false,
    this.isFavorite = false,
    this.downloadSpeed = 0,
    this.resumeKey,
    this.scheduledAt,
    this.retryCount = 0,
  }) : createdAt = createdAt ?? DateTime.now();
}

@HiveType(typeId: 2)
class ConversionTaskEntity extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String sourcePath;

  @HiveField(2)
  String outputPath;

  @HiveField(3)
  String fromFormat;

  @HiveField(4)
  String toFormat;

  @HiveField(5)
  int status; // 0=pending, 1=processing, 2=completed, 3=failed

  @HiveField(6)
  double progress;

  @HiveField(7)
  DateTime createdAt;

  @HiveField(8)
  Map<String, dynamic>? options; // trim start/end, audio bitrate, etc.

  ConversionTaskEntity({
    required this.id,
    required this.sourcePath,
    required this.outputPath,
    this.fromFormat = 'MP4',
    this.toFormat = 'MP3',
    this.status = 0,
    this.progress = 0.0,
    DateTime? createdAt,
    this.options,
  }) : createdAt = createdAt ?? DateTime.now();
}

@HiveType(typeId: 3)
class UserSettingsEntity extends HiveObject {
  @HiveField(0)
  String defaultQuality;

  @HiveField(1)
  String defaultFormat;

  @HiveField(2)
  String downloadFolder;

  @HiveField(3)
  bool wifiOnly;

  @HiveField(4)
  bool notificationsEnabled;

  @HiveField(5)
  bool isPro;

  @HiveField(6)
  DateTime? proExpiryDate;

  @HiveField(7)
  bool appLockEnabled;

  @HiveField(8)
  String lockType; // 'pin', 'biometric'

  @HiveField(9)
  String? pinCode;

  @HiveField(10)
  int maxParallelDownloads;

  @HiveField(11)
  bool hapticFeedback;

  @HiveField(12)
  bool soundEffects;

  @HiveField(13)
  String themeMode; // 'dark', 'light', 'system'

  @HiveField(14)
  int referralCount;

  @HiveField(15)
  String referralCode;

  @HiveField(16)
  List<String> referredUsers;

  @HiveField(17)
  int totalDownloads;

  @HiveField(18)
  int totalSizeDownloaded;

  @HiveField(19)
  bool onboardingCompleted;

  @HiveField(20)
  DateTime? firstLaunchDate;

  @HiveField(21)
  int adCounter;

  UserSettingsEntity({
    this.defaultQuality = '1080p',
    this.defaultFormat = 'MP4',
    this.downloadFolder = 'VidGrab/Downloads',
    this.wifiOnly = true,
    this.notificationsEnabled = true,
    this.isPro = false,
    this.proExpiryDate,
    this.appLockEnabled = false,
    this.lockType = 'biometric',
    this.pinCode,
    this.maxParallelDownloads = 1,
    this.hapticFeedback = true,
    this.soundEffects = true,
    this.themeMode = 'dark',
    this.referralCount = 0,
    this.referralCode = '',
    this.referredUsers = const [],
    this.totalDownloads = 0,
    this.totalSizeDownloaded = 0,
    this.onboardingCompleted = false,
    this.firstLaunchDate,
    this.adCounter = 0,
  });
}

@HiveType(typeId: 4)
class BrowserBookmarkEntity extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String url;

  @HiveField(2)
  String title;

  @HiveField(3)
  String faviconUrl;

  @HiveField(4)
  DateTime savedAt;

  BrowserBookmarkEntity({
    required this.id,
    required this.url,
    required this.title,
    this.faviconUrl = '',
    DateTime? savedAt,
  }) : savedAt = savedAt ?? DateTime.now();
}