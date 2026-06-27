import 'package:flutter/services.dart';

enum SoundType { downloadStart, downloadComplete, error, copy, tap, success, notification }

class AudioEffectsService {
  bool _enabled = true;

  void setEnabled(bool enabled) => _enabled = enabled;

  Future<void> playSound(SoundType type) async {
    if (!_enabled) return;
    try {
      HapticFeedback.lightImpact();
    } catch (_) {}
  }

  Future<void> playDownloadProgress(double progress) async {
    if (!_enabled || progress < 1.0) return;
    await playSound(SoundType.downloadComplete);
  }

  void dispose() {}
}
