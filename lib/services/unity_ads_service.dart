import 'package:flutter/material.dart';
import 'package:unity_ads_plugin/unity_ads_plugin.dart';

/// خدمة إعلانات Unity Ads
/// 
/// ⚡ خطوات التفعيل:
/// 1. سجّل في https://dashboard.unity3d.com/
/// 2. أنشئ مشروع وأضف إعلانات
/// 3. انسخ Game ID و Placement IDs
/// 4. استبدل القيم أدناه
class UnityAdsService {
  /// ═══ غيّر هذه القيم ببيانات Unity Ads الخاصة بك ═══
  static const String _gameId = 'YOUR_GAME_ID_HERE';
  
  // أنواع الإعلانات
  static const String _interstitialPlacementId = 'Interstitial_Android';
  static const String _rewardedPlacementId = 'Rewarded_Android';
  static const String _bannerPlacementId = 'Banner_Android';

  bool _isInitialized = false;
  bool _isAdReady = false;

  bool get isInitialized => _isInitialized;
  bool get isAdReady => _isAdReady;

  /// تهيئة Unity Ads
  /// استدعِ هذه الدالة في main() قبل runApp
  static Future<void> initialize() async {
    try {
      await UnityAdsInit(
        gameId: _gameId,
        testMode: true, // غيّر لـ false عند النشر
        onComplete: () {
          debugPrint('[UnityAds] ✅ تم التهيئة بنجاح');
        },
        onFailed: (error) {
          debugPrint('[UnityAds] ❌ فشل التهيئة: $error');
        },
      );
    } catch (e) {
      debugPrint('[UnityAds] خطأ في التهيئة: $e');
    }
  }

  /// عرض إعلان بيني (Interstitial)
  /// يُعرض بعد تحميل فيديو مثلاً
  Future<void> showInterstitialAd() async {
    if (!_isInitialized) {
      debugPrint('[UnityAds] لم يتم التهيئة بعد');
      return;
    }

    try {
      await UnityAds.show(
        placementId: _interstitialPlacementId,
        onComplete: () => debugPrint('[UnityAds] Interstitial مكتمل'),
        onFailed: (e) => debugPrint('[UnityAds] Interstitial فشل: $e'),
        onSkipped: () => debugPrint('[UnityAds] Interstitial تم تخطيه'),
        onStart: () => debugPrint('[UnityAds] Interstitial بدأ'),
      );
    } catch (e) {
      debugPrint('[UnityAds] خطأ في عرض Interstitial: $e');
    }
  }

  /// عرض إعلان مكافأة (Rewarded)
  /// يُعرض للمستخدم مقابل ميزة إضافية
  /// returns true إذا شاهد الإعلان كاملاً
  Future<bool> showRewardedAd() async {
    if (!_isInitialized) {
      debugPrint('[UnityAds] لم يتم التهيئة بعد');
      return false;
    }

    bool completed = false;
    try {
      await UnityAds.show(
        placementId: _rewardedPlacementId,
        onComplete: () {
          completed = true;
          debugPrint('[UnityAds] Rewarded مكتمل - منح المكافأة');
        },
        onFailed: (e) => debugPrint('[UnityAds] Rewarded فشل: $e'),
        onSkipped: () => debugPrint('[UnityAds] Rewarded تم تخطيه'),
        onStart: () => debugPrint('[UnityAds] Rewarded بدأ'),
      );
    } catch (e) {
      debugPrint('[UnityAds] خطأ في عرض Rewarded: $e');
    }
    return completed;
  }

  /// تحميل إعلان البانر (Banner)
  /// يمكن وضعه في ويدجت الشاشة
  Widget buildBannerAd({double height = 50}) {
    if (!_isInitialized) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: height,
      width: double.infinity,
      child: UnityBannerAd(
        placementId: _bannerPlacementId,
        onComplete: () => debugPrint('[UnityAds] Banner تم التحميل'),
        onFailed: (e) => debugPrint('[UnityAds] Banner فشل: $e'),
        onClick: () => debugPrint('[UnityAds] Banner تم النقر'),
      ),
    );
  }
}

/// ويدجت إعلان البانر البسيط
class UnityBannerAd extends StatefulWidget {
  final String placementId;
  final VoidCallback? onComplete;
  final Function(String)? onFailed;
  final VoidCallback? onClick;

  const UnityBannerAd({
    super.key,
    required this.placementId,
    this.onComplete,
    this.onFailed,
    this.onClick,
  });

  @override
  State<UnityBannerAd> createState() => _UnityBannerAdState();
}

class _UnityBannerAdState extends State<UnityBannerAd> {
  @override
  Widget build(BuildContext context) {
    // في الإصدار النهائي، استبدل هذا بـ Unity Ads Banner View
    // حالياً يعرض مساحة فارغة مكان الإعلان
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        border: Border.all(color: Colors.grey[800]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Text(
          'مساحة إعلانية',
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ),
    );
  }
}