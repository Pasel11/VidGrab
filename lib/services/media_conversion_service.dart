import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

enum ConversionType { toMp3, toWav, toAac, trim, extractAudio, compress }

class MediaConversionService extends ChangeNotifier {
  final Uuid _uuid = const Uuid();
  bool _isProcessing = false;
  double _currentProgress = 0.0;
  String _currentOperation = '';

  bool get isProcessing => _isProcessing;
  double get currentProgress => _currentProgress;
  String get currentOperation => _currentOperation;

  Future<String?> convertToAudio({
    required String videoPath,
    String outputFormat = 'mp3',
    int bitrate = 320,
    Function(double)? onProgress,
  }) async {
    _isProcessing = true;
    _currentOperation = 'تحويل إلى $outputFormat';
    notifyListeners();

    try {
      final dir = await getTemporaryDirectory();
      final outputPath = '${dir.path}/converted_${_uuid.v4()}.$outputFormat';

      // In production, use FFmpeg:
      // await FFmpegKit.execute('-i "$videoPath" -vn -ab ${bitrate}k "$outputPath"');
      // Simulate conversion progress
      for (int i = 1; i <= 100; i++) {
        await Future.delayed(const Duration(milliseconds: 60));
        _currentProgress = i / 100;
        onProgress?.call(_currentProgress);
        notifyListeners();
      }

      // Create a dummy output file for demo
      final file = File(outputPath);
      await file.writeAsBytes(List.generate(1024, (_) => 0));

      _isProcessing = false;
      _currentProgress = 0.0;
      notifyListeners();
      return outputPath;
    } catch (e) {
      _isProcessing = false;
      _currentProgress = 0.0;
      notifyListeners();
      debugPrint('Conversion error: $e');
      return null;
    }
  }

  Future<String?> trimVideo({
    required String videoPath,
    required Duration startTime,
    required Duration endTime,
    Function(double)? onProgress,
  }) async {
    _isProcessing = true;
    _currentOperation = 'قص الفيديو';
    notifyListeners();

    try {
      final dir = await getTemporaryDirectory();
      final outputPath = '${dir.path}/trimmed_${_uuid.v4()}.mp4';

      // In production:
      // final start = startTime.inSeconds.toString();
      // final duration = (endTime - startTime).inSeconds.toString();
      // await FFmpegKit.execute('-i "$videoPath" -ss $start -t $duration -c copy "$outputPath"');

      for (int i = 1; i <= 100; i++) {
        await Future.delayed(const Duration(milliseconds: 50));
        _currentProgress = i / 100;
        onProgress?.call(_currentProgress);
        notifyListeners();
      }

      final file = File(outputPath);
      await file.writeAsBytes(List.generate(2048, (_) => 0));

      _isProcessing = false;
      _currentProgress = 0.0;
      notifyListeners();
      return outputPath;
    } catch (e) {
      _isProcessing = false;
      _currentProgress = 0.0;
      notifyListeners();
      return null;
    }
  }

  Future<String?> compressVideo({
    required String videoPath,
    int targetSizeMB = 50,
    Function(double)? onProgress,
  }) async {
    _isProcessing = true;
    _currentOperation = 'ضغط الفيديو';
    notifyListeners();

    try {
      final dir = await getTemporaryDirectory();
      final outputPath = '${dir.path}/compressed_${_uuid.v4()}.mp4';

      // In production, use FFmpeg with CRF/target bitrate
      for (int i = 1; i <= 100; i++) {
        await Future.delayed(const Duration(milliseconds: 40));
        _currentProgress = i / 100;
        onProgress?.call(_currentProgress);
        notifyListeners();
      }

      final file = File(outputPath);
      await file.writeAsBytes(List.generate(2048, (_) => 0));

      _isProcessing = false;
      _currentProgress = 0.0;
      notifyListeners();
      return outputPath;
    } catch (e) {
      _isProcessing = false;
      _currentProgress = 0.0;
      notifyListeners();
      return null;
    }
  }

  Future<Map<String, String>> getVideoMetadata(String videoPath) async {
    // In production, use FFprobe:
    // final session = await FFprobeKit.execute('-i "$videoPath" -show_format -show_streams');
    return {
      'duration': '00:03:45',
      'resolution': '1920x1080',
      'format': 'mp4',
      'size': '45.2 MB',
      'bitrate': '8500 kbps',
      'codec': 'H.264',
      'fps': '30',
    };
  }
}