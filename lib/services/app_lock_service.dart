import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AppLockService extends ChangeNotifier {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  bool _isLocked = true;
  bool _biometricAvailable = false;
  bool _isInitialized = false;

  bool get isLocked => _isLocked;
  bool get biometricAvailable => _biometricAvailable;
  bool get isInitialized => _isInitialized;

  Future<void> init() async {
    _biometricAvailable = await _checkBiometric();
    _isInitialized = true;
    notifyListeners();
  }

  Future<bool> _checkBiometric() async {
    try {
      return await _localAuth.canCheckBiometrics || await _localAuth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (_) {
      return [];
    }
  }

  Future<bool> authenticateWithBiometric() async {
    try {
      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'افتح VidGrab',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
      if (didAuthenticate) {
        _isLocked = false;
        notifyListeners();
      }
      return didAuthenticate;
    } catch (e) {
      debugPrint('Biometric auth error: $e');
      return false;
    }
  }

  Future<bool> authenticateWithPin(String pin) async {
    final storedPin = await _secureStorage.read(key: 'app_pin');
    if (storedPin == null) return false;
    final isValid = storedPin == pin;
    if (isValid) {
      _isLocked = false;
      notifyListeners();
    }
    return isValid;
  }

  Future<void> setPin(String pin) async {
    await _secureStorage.write(key: 'app_pin', value: pin);
  }

  Future<bool> verifyPinForChange(String oldPin) async {
    final storedPin = await _secureStorage.read(key: 'app_pin');
    return storedPin == oldPin;
  }

  Future<void> removePin() async {
    await _secureStorage.delete(key: 'app_pin');
  }

  Future<bool> hasPin() async {
    final pin = await _secureStorage.read(key: 'app_pin');
    return pin != null;
  }

  void lock() {
    _isLocked = true;
    notifyListeners();
  }

  void unlock() {
    _isLocked = false;
    notifyListeners();
  }
}