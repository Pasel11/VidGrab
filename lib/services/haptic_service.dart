import 'package:flutter/services.dart';

class HapticService {
  bool _enabled = true;

  void setEnabled(bool enabled) => _enabled = true;

  void lightImpact() {
    if (!_enabled) return;
    HapticFeedback.lightImpact();
  }

  void mediumImpact() {
    if (!_enabled) return;
    HapticFeedback.mediumImpact();
  }

  void heavyImpact() {
    if (!_enabled) return;
    HapticFeedback.heavyImpact();
  }

  void selectionClick() {
    if (!_enabled) return;
    HapticFeedback.selectionClick();
  }

  void vibrate({int durationMs = 100}) {
    if (!_enabled) return;
    HapticFeedback.vibrate();
  }

  void successFeedback() {
    if (!_enabled) return;
    HapticFeedback.heavyImpact();
  }

  void errorFeedback() {
    if (!_enabled) return;
    HapticFeedback.vibrate();
    HapticFeedback.heavyImpact();
  }

  void downloadProgressFeedback(double progress) {
    if (!_enabled) return;
    if ((progress * 100).toInt() % 25 == 0 && progress > 0) {
      HapticFeedback.selectionClick();
    }
  }
}