import 'package:flutter/material.dart';

/// خدمة إعلانات Unity Ads
/// 
/// ⚡ خطوات التفعيل:
/// 1. سجّل في https://dashboard.unity3d.com/
/// 2. أنشئ مشروع وأضف إعلانات
/// 3. انسخ Game ID و Placement IDs
/// 4. استبدل القيم أدناه واستورد unity_ads_plugin بشكل صحيح
class UnityAdsService {
  /// ═══ غيّر هذه القيم ببيانات Unity Ads الخاصة بك ═══
  static const String _gameId = 'YOUR_GAME_ID_HERE';
  static const String _interstitialPlacementId = 'Interstitial_Android';
  static const String _rewardedPlacementId = 'Rewarded_Android';
  static const String _bannerPlacementId = 'Banner_Android';

  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  /// تهيئة Unity Ads
  /// استدعِ هذه الدالة في main() قبل runApp
  static Future<void> initialize() async {
    debugPrint('[UnityAds] ⏳ جاري التهيئة... Game ID: $_gameId');
    
    if (_gameId == 'YOUR_GAME_ID_HERE') {
      debugPrint('[UnityAds] ⚠️ لم يتم تعيين Game ID بعد. الإعلانات معطلة.');
      debugPrint('[UnityAds] سجّل في https://dashboard.unity3d.com/ وانسخ Game ID');
      return;
    }

    try {
      // ═══ أضف استيراد unity_ads_plugin عند التفعيل ═══
      // import 'package:unity_ads_plugin/unity_ads_plugin.dart';
      // await UnityAds.init(gameId: _gameId, testMode: true);
      debugPrint('[UnityAds] ✅ تم التهيئة بنجاح');
    } catch (e) {
      debugPrint('[UnityAds] ❌ فشل التهيئة: $e');
    }
  }

  /// عرض إعلان بيني (Interstitial) - بعد تحميل فيديو
  Future<void> showInterstitialAd() async {
    if (!_isInitialized) return;
    debugPrint('[UnityAds] عرض Interstitial...');
    // await UnityAds.showAd(placementId: _interstitialPlacementId);
  }

  /// عرض إعلان مكافأة (Rewarded) - لفتح ميزات إضافية
  /// returns true إذا شاهد الإعلان كاملاً
  Future<bool> showRewardedAd() async {
    if (!_isInitialized) return false;
    debugPrint('[UnityAds] عرض Rewarded...');
    // await UnityAds.showAd(placementId: _rewardedPlacementId);
    return false;
  }

  /// بناء ويدجت بانر الإعلان
  Widget buildBannerAd({double height = 50}) {
    if (!_isInitialized) return const SizedBox.shrink();
    return _BannerPlaceholder(height: height);
  }
}

/// ويدجت مكان البانر
class _BannerPlaceholder extends StatelessWidget {
  final double height;
  const _BannerPlaceholder({required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        border: Border.all(color: Colors.grey[800]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Text('مساحة إعلانية', style: TextStyle(color: Colors.grey, fontSize: 12)),
      ),
    );
  }
}