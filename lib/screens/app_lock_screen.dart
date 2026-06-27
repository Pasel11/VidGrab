import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../services/advanced_download_manager.dart';
import '../services/app_lock_service.dart';
import '../services/haptic_service.dart';

class AppLockScreen extends StatefulWidget {
  const AppLockScreen({super.key});

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen> with TickerProviderStateMixin {
  final List<String> _pin = [];
  final int _pinLength = 4;
  bool _isError = false;
  String _lockType = 'biometric';
  late AnimationController _errorController;
  final HapticService _haptic = HapticService();

  @override
  void initState() {
    super.initState();
    _errorController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _checkLockType();
  }

  Future<void> _checkLockType() async {
    final lockService = Provider.of<AppLockService>(context, listen: false);
    final hasPin = await lockService.hasPin();
    if (!hasPin) {
      // First time setup - navigate to setup
      Navigator.pushReplacementNamed(context, '/lock-setup');
      return;
    }
    setState(() => _lockType = 'pin');
    if (_lockType == 'biometric' && lockService.biometricAvailable) {
      _tryBiometric();
    }
  }

  Future<void> _tryBiometric() async {
    final lockService = Provider.of<AppLockService>(context, listen: false);
    final success = await lockService.authenticateWithBiometric();
    if (!success && mounted) {
      setState(() => _lockType = 'pin');
    }
  }

  void _addDigit(String digit) {
    if (_pin.length >= _pinLength) return;
    _haptic.selectionClick();
    setState(() {
      _pin.add(digit);
      _isError = false;
    });
    if (_pin.length == _pinLength) {
      _verifyPin();
    }
  }

  void _removeDigit() {
    if (_pin.isEmpty) return;
    _haptic.lightImpact();
    setState(() => _pin.removeLast());
  }

  Future<void> _verifyPin() async {
    final lockService = Provider.of<AppLockService>(context, listen: false);
    final pin = _pin.join();
    final isValid = await lockService.authenticateWithPin(pin);
    if (isValid) {
      _haptic.successFeedback();
    } else {
      _haptic.errorFeedback();
      setState(() => _isError = true);
      _errorController.forward().then((_) => _errorController.reverse());
      await Future.delayed(const Duration(milliseconds: 500));
      setState(() => _pin.clear());
    }
  }

  @override
  void dispose() {
    _errorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 80),
            // Lock icon
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 100, height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                gradient: LinearGradient(
                  colors: _isError
                      ? [AppTheme.errorRed, AppTheme.errorRed.withOpacity(0.6)]
                      : [AppTheme.accentPurple, AppTheme.accentBlue],
                ),
                boxShadow: [
                  BoxShadow(
                    color: (_isError ? AppTheme.errorRed : AppTheme.accentPurple).withOpacity(0.3),
                    blurRadius: 30, spreadRadius: 3,
                  ),
                ],
              ),
              child: const Icon(Iconsax.lock, color: Colors.white, size: 44),
            ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
              begin: const Offset(1, 1), end: const Offset(1.03, 1.03),
              duration: const Duration(milliseconds: 2000),
            ),
            const SizedBox(height: 24),
            Text('أدخل رمز PIN', style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: 8),
            Text(
              _isError ? 'رمز خاطئ، حاول مرة أخرى' : 'فتح VidGrab',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: _isError ? AppTheme.errorRed : AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 40),
            // PIN dots
            _PinAnimatedWidget(
              listenable: _errorController,
              builder: (context, child) => Transform.translate(
                offset: Offset(_errorController.value * 10, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_pinLength, (index) {
                    final filled = index < _pin.length;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      width: 18, height: 18,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: filled
                            ? (_isError ? AppTheme.errorRed : AppTheme.accentPurple)
                            : AppTheme.borderLight,
                        boxShadow: filled ? [
                          BoxShadow(
                            color: (_isError ? AppTheme.errorRed : AppTheme.accentPurple).withOpacity(0.3),
                            blurRadius: 12,
                          ),
                        ] : null,
                      ),
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(height: 50),
            // Keypad
            Expanded(
              child: GridView.count(
                shrinkWrap: true,
                crossAxisCount: 3,
                childAspectRatio: 1.8,
                padding: const EdgeInsets.symmetric(horizontal: 50),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                children: [
                  ...List.generate(9, (i) => _keyButton('${i + 1}')),
                  _keyButton('', icon: Icons.fingerprint_rounded, onTap: _tryBiometric),
                  _keyButton('0'),
                  _keyButton('', icon: Icons.backspace_rounded, onTap: _removeDigit),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _keyButton(String digit, {IconData? icon, VoidCallback? onTap}) {
    return InkWell(
      onTap: icon != null ? onTap : () => _addDigit(digit),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.borderLight),
        ),
        child: Center(
          child: icon != null
              ? Icon(icon, color: AppTheme.accentPurple, size: 28)
              : Text(digit, style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700, fontSize: 26,
              )),
        ),
      ),
    );
  }
}

class _PinAnimatedWidget extends AnimatedWidget {
  final Widget Function(BuildContext, Widget?) builder;

  const _PinAnimatedWidget({super.key, required super.listenable, required this.builder});

  @override
  Widget build(BuildContext context) => builder(context, null);
}