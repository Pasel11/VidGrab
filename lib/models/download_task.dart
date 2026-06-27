enum DownloadStatus {
  waiting,
  fetching,
  downloading,
  completed,
  failed,
  paused,
  cancelled,
}

class DownloadTask {
  final String id;
  final String url;
  final String title;
  final String thumbnailUrl;
  final String platform;
  final String quality;
  final String format;
  final String filePath;
  final int fileSize;
  final DownloadStatus status;
  final double progress;
  final DateTime createdAt;
  final DateTime? completedAt;

  DownloadTask({
    required this.id,
    required this.url,
    required this.title,
    this.thumbnailUrl = '',
    this.platform = '',
    this.quality = '',
    this.format = 'MP4',
    this.filePath = '',
    this.fileSize = 0,
    this.status = DownloadStatus.waiting,
    this.progress = 0.0,
    required this.createdAt,
    this.completedAt,
  });

  String get formattedSize {
    if (fileSize <= 0) return 'N/A';
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    if (fileSize < 1024 * 1024 * 1024) {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(fileSize / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  String get formattedDate {
    return '${createdAt.day}/${createdAt.month}/${createdAt.year} ${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
  }

  DownloadTask copyWith({
    DownloadStatus? status,
    double? progress,
    String? filePath,
    int? fileSize,
    DateTime? completedAt,
  }) {
    return DownloadTask(
      id: id,
      url: url,
      title: title,
      thumbnailUrl: thumbnailUrl,
      platform: platform,
      quality: quality,
      format: format,
      filePath: filePath ?? this.filePath,
      fileSize: fileSize ?? this.fileSize,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      createdAt: createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'url': url,
    'title': title,
    'thumbnailUrl': thumbnailUrl,
    'platform': platform,
    'quality': quality,
    'format': format,
    'filePath': filePath,
    'fileSize': fileSize,
    'status': status.index,
    'progress': progress,
    'createdAt': createdAt.millisecondsSinceEpoch,
    'completedAt': completedAt?.millisecondsSinceEpoch,
  };

  factory DownloadTask.fromMap(Map<String, dynamic> map) => DownloadTask(
    id: map['id'] as String,
    url: map['url'] as String,
    title: map['title'] as String,
    thumbnailUrl: map['thumbnailUrl'] as String? ?? '',
    platform: map['platform'] as String? ?? '',
    quality: map['quality'] as String? ?? '',
    format: map['format'] as String? ?? 'MP4',
    filePath: map['filePath'] as String? ?? '',
    fileSize: map['fileSize'] as int? ?? 0,
    status: DownloadStatus.values[map['status'] as int? ?? 0],
    progress: (map['progress'] as num?)?.toDouble() ?? 0.0,
    createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
    completedAt: map['completedAt'] != null
        ? DateTime.fromMillisecondsSinceEpoch(map['completedAt'] as int)
        : null,
  );
}