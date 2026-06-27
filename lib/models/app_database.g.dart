// GENERATED CODE - DO NOT MODIFY BY HAND
part of 'app_database.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class VideoInfoEntityAdapter extends TypeAdapter<VideoInfoEntity> {
  @override
  final int typeId = 0;

  @override
  VideoInfoEntity read(BinaryReader reader) {
    return VideoInfoEntity(
      url: reader.read(),
      platform: reader.read(),
      title: reader.read(),
      thumbnailUrl: reader.read(),
      author: reader.read(),
      durationSeconds: reader.read(),
      description: reader.read(),
      fetchedAt: reader.read(),
    );
  }

  @override
  void write(BinaryWriter writer, VideoInfoEntity obj) {
    writer.write(obj.url);
    writer.write(obj.platform);
    writer.write(obj.title);
    writer.write(obj.thumbnailUrl);
    writer.write(obj.author);
    writer.write(obj.durationSeconds);
    writer.write(obj.description);
    writer.write(obj.fetchedAt);
  }
}

class DownloadTaskEntityAdapter extends TypeAdapter<DownloadTaskEntity> {
  @override
  final int typeId = 1;

  @override
  DownloadTaskEntity read(BinaryReader reader) {
    return DownloadTaskEntity(
      id: reader.read(),
      url: reader.read(),
      title: reader.read(),
      thumbnailUrl: reader.read(),
      platform: reader.read(),
      quality: reader.read(),
      format: reader.read(),
      filePath: reader.read(),
      fileSizeBytes: reader.read(),
      status: reader.read(),
      progress: reader.read(),
      createdAt: reader.read(),
      completedAt: reader.read(),
      folder: reader.read(),
      isSecret: reader.read(),
      isFavorite: reader.read(),
      downloadSpeed: reader.read(),
      resumeKey: reader.read(),
      scheduledAt: reader.read(),
      retryCount: reader.read(),
    );
  }

  @override
  void write(BinaryWriter writer, DownloadTaskEntity obj) {
    writer.write(obj.id);
    writer.write(obj.url);
    writer.write(obj.title);
    writer.write(obj.thumbnailUrl);
    writer.write(obj.platform);
    writer.write(obj.quality);
    writer.write(obj.format);
    writer.write(obj.filePath);
    writer.write(obj.fileSizeBytes);
    writer.write(obj.status);
    writer.write(obj.progress);
    writer.write(obj.createdAt);
    writer.write(obj.completedAt);
    writer.write(obj.folder);
    writer.write(obj.isSecret);
    writer.write(obj.isFavorite);
    writer.write(obj.downloadSpeed);
    writer.write(obj.resumeKey);
    writer.write(obj.scheduledAt);
    writer.write(obj.retryCount);
  }
}

class ConversionTaskEntityAdapter extends TypeAdapter<ConversionTaskEntity> {
  @override
  final int typeId = 2;

  @override
  ConversionTaskEntity read(BinaryReader reader) {
    return ConversionTaskEntity(
      id: reader.read(),
      sourcePath: reader.read(),
      outputPath: reader.read(),
      fromFormat: reader.read(),
      toFormat: reader.read(),
      status: reader.read(),
      progress: reader.read(),
      createdAt: reader.read(),
      options: reader.read(),
    );
  }

  @override
  void write(BinaryWriter writer, ConversionTaskEntity obj) {
    writer.write(obj.id);
    writer.write(obj.sourcePath);
    writer.write(obj.outputPath);
    writer.write(obj.fromFormat);
    writer.write(obj.toFormat);
    writer.write(obj.status);
    writer.write(obj.progress);
    writer.write(obj.createdAt);
    writer.write(obj.options);
  }
}

class UserSettingsEntityAdapter extends TypeAdapter<UserSettingsEntity> {
  @override
  final int typeId = 3;

  @override
  UserSettingsEntity read(BinaryReader reader) {
    return UserSettingsEntity(
      defaultQuality: reader.read(),
      defaultFormat: reader.read(),
      downloadFolder: reader.read(),
      wifiOnly: reader.read(),
      notificationsEnabled: reader.read(),
      isPro: reader.read(),
      proExpiryDate: reader.read(),
      appLockEnabled: reader.read(),
      lockType: reader.read(),
      pinCode: reader.read(),
      maxParallelDownloads: reader.read(),
      hapticFeedback: reader.read(),
      soundEffects: reader.read(),
      themeMode: reader.read(),
      referralCount: reader.read(),
      referralCode: reader.read(),
      referredUsers: reader.read(),
      totalDownloads: reader.read(),
      totalSizeDownloaded: reader.read(),
      onboardingCompleted: reader.read(),
      firstLaunchDate: reader.read(),
      adCounter: reader.read(),
    );
  }

  @override
  void write(BinaryWriter writer, UserSettingsEntity obj) {
    writer.write(obj.defaultQuality);
    writer.write(obj.defaultFormat);
    writer.write(obj.downloadFolder);
    writer.write(obj.wifiOnly);
    writer.write(obj.notificationsEnabled);
    writer.write(obj.isPro);
    writer.write(obj.proExpiryDate);
    writer.write(obj.appLockEnabled);
    writer.write(obj.lockType);
    writer.write(obj.pinCode);
    writer.write(obj.maxParallelDownloads);
    writer.write(obj.hapticFeedback);
    writer.write(obj.soundEffects);
    writer.write(obj.themeMode);
    writer.write(obj.referralCount);
    writer.write(obj.referralCode);
    writer.write(obj.referredUsers);
    writer.write(obj.totalDownloads);
    writer.write(obj.totalSizeDownloaded);
    writer.write(obj.onboardingCompleted);
    writer.write(obj.firstLaunchDate);
    writer.write(obj.adCounter);
  }
}

class BrowserBookmarkEntityAdapter extends TypeAdapter<BrowserBookmarkEntity> {
  @override
  final int typeId = 4;

  @override
  BrowserBookmarkEntity read(BinaryReader reader) {
    return BrowserBookmarkEntity(
      id: reader.read(),
      url: reader.read(),
      title: reader.read(),
      faviconUrl: reader.read(),
      savedAt: reader.read(),
    );
  }

  @override
  void write(BinaryWriter writer, BrowserBookmarkEntity obj) {
    writer.write(obj.id);
    writer.write(obj.url);
    writer.write(obj.title);
    writer.write(obj.faviconUrl);
    writer.write(obj.savedAt);
  }
}