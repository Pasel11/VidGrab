import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import '../config/theme.dart';
import '../config/routes.dart';
import '../services/platform_detector.dart';
import '../services/advanced_download_manager.dart';
import '../services/network_intelligence.dart';
import '../services/storage_manager.dart';
import '../services/video_api_service.dart';
import '../models/video_info.dart';
import '../widgets/quality_selector.dart';
import '../widgets/video_preview_card.dart';
import 'package:share_plus/share_plus.dart';

class DownloadScreen extends StatefulWidget {
  final String url;
  const DownloadScreen({super.key, required this.url});

  @override
  State<DownloadScreen> createState() => _DownloadScreenState();
}

class _DownloadScreenState extends State<DownloadScreen> with TickerProviderStateMixin {
  VideoInfo? _videoInfo;
  VideoQuality? _selectedQuality;
  bool _showQualities = false;
  late AnimationController _scaleController;
  bool _isFetching = false;
  String _errorMessage = '';
  final PlatformDetector _detector = PlatformDetector();
  UrlAnalysisResult? _analysis;
  VideoQualitySuggestion? _networkSuggestion;
  bool _hasEnoughSpace = true;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));

    // تحليل الرابط فوراً
    _analysis = _detector.analyzeUrl(widget.url);

    // فحص المساحة والشبكة
    _checkNetworkAndSpace();

    _fetchVideo();
  }

  Future<void> _checkNetworkAndSpace() async {
    try {
      final network = Provider.of<NetworkIntelligence>(context, listen: false);
      final storage = Provider.of<StorageManager>(context, listen: false);
      await storage.refreshStorageInfo();

      if (_videoInfo != null && _selectedQuality != null) {
        final requiredBytes = _selectedQuality!.fileSizeBytes;
        _hasEnoughSpace = await storage.hasEnoughSpace(requiredBytes);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  Future<void> _fetchVideo() async {
    setState(() => _isFetching = true);

    if (!_detector.isValidUrl(widget.url)) {
      setState(() { _isFetching = false; _errorMessage = 'الرابط غير صالح'; });
      if (mounted) _showErrorSnack(_errorMessage);
      return;
    }

    try {
      // ═══ استدعاء API الحقيقي ═══
      final apiService = VideoApiService();
      final info = await apiService.fetchVideoInfo(widget.url);

      if (info == null) {
        setState(() {
          _isFetching = false;
          _errorMessage = 'لم يتم العثور على فيديو في هذا الرابط';
        });
        if (mounted) _showErrorSnack(_errorMessage);
        return;
      }

      // اقتراح الجودة من الذكاء الشبكي
      if (_analysis?.isSupported == true && info.availableQualities.isNotEmpty) {
        try {
          final network = Provider.of<NetworkIntelligence>(context, listen: false);
          final bestQuality = info.availableQualities.firstWhere(
            (q) => !q.isAudioOnly,
            orElse: () => info.availableQualities.first,
          );
          _networkSuggestion = network.suggestQuality(bestQuality.fileSizeBytes);
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          _videoInfo = info;
          _selectedQuality = info.availableQualities.isNotEmpty
              ? info.availableQualities.first
              : null;
          _showQualities = info.availableQualities.isNotEmpty;
          _isFetching = false;
        });
        _scaleController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isFetching = false;
          _errorMessage = 'خطأ في جلب الفيديو: ${_extractErrorMessage(e)}';
        });
        _showErrorSnack(_errorMessage);
      }
    }
  }

  String _extractErrorMessage(dynamic error) {
    final msg = error.toString();
    if (msg.contains('404')) return 'الرابط غير صالح أو الفيديو محذوف';
    if (msg.contains('403')) return 'الفيديو محمي ولا يمكن تحميله';
    if (msg.contains('429')) return 'طلبات كثيرة، انتظر قليلاً';
    if (msg.contains('timeout')) return 'انتهت مهلة الاتصال';
    if (msg.contains('SocketException')) return 'لا يوجد اتصال بالإنترنت';
    return 'حدث خطأ غير متوقع';
  }

  String _generateTitle(VideoPlatform platform, Random rng) {
    final titles = {
      VideoPlatform.youtube: ['فيديو تعليمي مميز من يوتيوب', 'محتوى ترند - YouTube', 'فيديو فيروسي على يوتيوب', 'مراجعة شاملة وتجربة عملية'],
      VideoPlatform.instagram: ['ريلز انستقرام مميز', 'ستوري انستقرام حصري', 'بوست فيديو انستقرام ترند', 'محتوى مميز من انستقرام'],
      VideoPlatform.tiktok: ['فيديو تيك توك فيروسي', 'تحدي تيك توك رائع', 'تيك توك ترند عالمي', 'محتوى تيك توك مميز'],
      VideoPlatform.twitter: ['فيديو حصري من X', 'تغريدة فيديو تترند', 'محتوى X مميز', 'تغطية مباشرة من X'],
      VideoPlatform.facebook: ['فيديو فيسبوك مميز', 'ريلز فيسبوك ترند', 'محتوى حصري فيسبوك'],
      VideoPlatform.tiktok: ['فيديو تيك توك مميز', 'تيك توك فيروسي', 'تحدي تيك توك'],
      VideoPlatform.twitch: ['مقطع من بث مباشر Twitch', 'هايلايت من البث', 'أفضل لحظات البث المباشر'],
      VideoPlatform.soundcloud: ['مقطع صوتي مميز', 'بودكاست حصري', 'موسيقى أصلية'],
      VideoPlatform.telegram: ['فيديو من قناة تيليجرام', 'محتوى تيليجرام حصري'],
      VideoPlatform.unknown: ['فيديو من المنصة', 'محتوى مميز', 'فيديو جديد'],
    };
    final list = titles[platform] ?? titles[VideoPlatform.unknown]!;
    return list[rng.nextInt(list.length)];
  }

  List<VideoQuality> _getQualities(VideoPlatform platform, Random rng) {
    if (platform.isAudioPlatform) {
      return [
        VideoQuality(label: 'جودة عالية', resolution: '320kbps', format: 'MP3', fileSize: '${rng.nextInt(10) + 5} MB', downloadUrl: '', bitrate: 320),
        VideoQuality(label: 'جودة متوسطة', resolution: '192kbps', format: 'MP3', fileSize: '${rng.nextInt(6) + 3} MB', downloadUrl: '', bitrate: 192),
        VideoQuality(label: 'جودة منخفضة', resolution: '128kbps', format: 'MP3', fileSize: '${rng.nextInt(3) + 1} MB', downloadUrl: '', bitrate: 128),
      ];
    }

    if (platform == VideoPlatform.youtube) {
      return [
        VideoQuality(label: '4K Ultra HD', resolution: '2160p', format: 'MP4', fileSize: '${rng.nextInt(800) + 200} MB', downloadUrl: '', bitrate: 20000, isHDR: true),
        VideoQuality(label: 'Full HD', resolution: '1080p', format: 'MP4', fileSize: '${rng.nextInt(300) + 50} MB', downloadUrl: '', bitrate: 8000),
        VideoQuality(label: 'HD', resolution: '720p', format: 'MP4', fileSize: '${rng.nextInt(150) + 30} MB', downloadUrl: '', bitrate: 5000),
        VideoQuality(label: 'SD', resolution: '480p', format: 'MP4', fileSize: '${rng.nextInt(80) + 15} MB', downloadUrl: '', bitrate: 2500),
        VideoQuality(label: 'صوت فقط', resolution: '320kbps', format: 'MP3', fileSize: '${rng.nextInt(10) + 3} MB', downloadUrl: '', bitrate: 320, hasAudio: true),
      ];
    }

    return [
      VideoQuality(label: 'Full HD', resolution: '1080p', format: 'MP4', fileSize: '${rng.nextInt(300) + 40} MB', downloadUrl: '', bitrate: 8000),
      VideoQuality(label: 'HD', resolution: '720p', format: 'MP4', fileSize: '${rng.nextInt(120) + 20} MB', downloadUrl: '', bitrate: 5000),
      VideoQuality(label: 'SD', resolution: '480p', format: 'MP4', fileSize: '${rng.nextInt(60) + 10} MB', downloadUrl: '', bitrate: 2500),
      VideoQuality(label: 'صوت فقط', resolution: '320kbps', format: 'MP3', fileSize: '${rng.nextInt(8) + 2} MB', downloadUrl: '', bitrate: 320, hasAudio: true),
    ];
  }

  void _showErrorSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg), backgroundColor: AppTheme.errorRed, behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) Navigator.pop(context);
    });
  }

  void _download() {
    if (_videoInfo == null || _selectedQuality == null) return;

    final manager = Provider.of<AdvancedDownloadManager>(context, listen: false);

    manager.addDownload(
      url: widget.url,
      title: _videoInfo!.title,
      platform: _videoInfo!.platform.name,
      quality: _selectedQuality!.resolution,
      format: _selectedQuality!.format,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.check_circle_rounded, color: AppTheme.successGreen),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('تم بدء التحميل!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                Text(_videoInfo!.title, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ]),
        backgroundColor: AppTheme.cardDark, behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppTheme.cardDark, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.borderLight)),
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppTheme.textPrimary),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('تحميل الفيديو', style: Theme.of(context).textTheme.titleLarge),
        centerTitle: true,
        actions: [
          if (_analysis != null)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _analysis!.isSupported ? AppTheme.successGreen.withOpacity(0.15) : AppTheme.errorRed.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(_analysis!.isSupported ? Icons.check_circle_rounded : Icons.error_rounded,
                    color: _analysis!.isSupported ? AppTheme.successGreen : AppTheme.errorRed, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    _analysis!.isSupported ? _analysis!.platform.name : 'غير مدعوم',
                    style: TextStyle(color: _analysis!.isSupported ? AppTheme.successGreen : AppTheme.errorRed, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ]),
              ),
            ),
        ],
      ),
      body: _isFetching
          ? _buildLoadingState()
          : _videoInfo == null
              ? _buildErrorState()
              : _buildContent(),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.accentPurple.withOpacity(0.1),
            ),
            child: const Center(
              child: SizedBox(width: 50, height: 50, child: CircularProgressIndicator(color: AppTheme.accentPurple, strokeWidth: 3)),
            ),
          ).animate(onPlay: (c) => c.repeat()).scale(
            begin: const Offset(0.95, 0.95), end: const Offset(1.05, 1.05),
            duration: const Duration(milliseconds: 1500),
          ),
          const SizedBox(height: 24),
          Text('جارٍ جلب معلومات الفيديو...', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.textSecondary)),
          const SizedBox(height: 8),
          if (_analysis != null && _analysis!.isSupported)
            Text('منصة: ${_analysis!.platform.name}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.accentPurple)),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: AppTheme.errorRed.withOpacity(0.1), borderRadius: BorderRadius.circular(24)),
              child: const Icon(Icons.error_outline_rounded, size: 64, color: AppTheme.errorRed),
            ),
            const SizedBox(height: 24),
            Text('لم يتم العثور على الفيديو', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Text('تأكد من أن الرابط صحيح ويدعم التحميل', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary)),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: widget.url));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم نسخ الرابط', style: TextStyle(color: Colors.white)), backgroundColor: AppTheme.cardDark, behavior: SnackBarBehavior.floating),
                );
              },
              icon: const Icon(Icons.copy_rounded, size: 18),
              label: const Text('نسخ الرابط والمحاولة لاحقاً'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: ScaleTransition(
        scale: CurvedAnimation(parent: _scaleController, curve: Curves.easeOutBack),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            VideoPreviewCard(videoInfo: _videoInfo!),
            const SizedBox(height: 16),

            // اقتراح الذكاء الشبكي
            if (_networkSuggestion != null && _networkSuggestion!.isSuggested) ...[
              _buildNetworkSuggestion(),
              const SizedBox(height: 16),
            ],

            // تحذير المساحة
            if (!_hasEnoughSpace) ...[
              _buildSpaceWarning(),
              const SizedBox(height: 16),
            ],

            if (_showQualities) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('اختر الجودة', style: Theme.of(context).textTheme.titleMedium),
                  if (_analysis?.contentType != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: AppTheme.accentCyan.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                      child: Text(
                        _analysis!.contentType == 'reel' ? 'ريلز' :
                        _analysis!.contentType == 'story' ? 'ستوري' :
                        _analysis!.contentType == 'live' ? 'بث مباشر' :
                        _analysis!.contentType == 'audio' ? 'صوت' : 'فيديو',
                        style: const TextStyle(fontSize: 11, color: AppTheme.accentCyan, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              QualitySelector(
                qualities: _videoInfo!.availableQualities,
                selected: _selectedQuality,
                onSelected: (q) => setState(() => _selectedQuality = q),
                suggestedQuality: _networkSuggestion?.quality,
              ),
              const SizedBox(height: 28),
            ],
            _buildActionButtons(),
            const SizedBox(height: 20),
            // معلومات إضافية
            _buildAdditionalInfo(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildNetworkSuggestion() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.accentCyan.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.accentCyan.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_tethering_rounded, color: AppTheme.accentCyan, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Text('اقتراح ذكي: ', style: TextStyle(fontSize: 12, color: AppTheme.accentCyan, fontWeight: FontWeight.w700)),
                  Text(_networkSuggestion!.quality, style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
                ]),
                const SizedBox(height: 2),
                Text(_networkSuggestion!.reason, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
              ],
            ),
          ),
          if (_networkSuggestion!.estimatedTimeSeconds > 0)
            Text(_networkSuggestion!.estimatedTimeText, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
        ],
      ),
    );
  }

  Widget _buildSpaceWarning() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.warningOrange.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.warningOrange.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.storage_rounded, color: AppTheme.warningOrange, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('المساحة التخزينية منخفضة', style: TextStyle(fontSize: 12, color: AppTheme.warningOrange, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                const Text('قد لا تكون هناك مساحة كافية للتحميل. يُنصح بحذف بعض الملفات.', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalInfo() {
    if (_videoInfo == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppTheme.cardDark, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.borderLight)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('تفاصيل الفيديو', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
          const SizedBox(height: 12),
          _infoRow(Icons.videocam_rounded, 'المنصة', _videoInfo!.platform.name),
          if (_videoInfo!.author.isNotEmpty) _infoRow(Icons.person_rounded, 'الناشر', _videoInfo!.author),
          if (_videoInfo!.duration != null) _infoRow(Icons.schedule_rounded, 'المدة', _formatDuration(_videoInfo!.duration!)),
          if (_videoInfo!.viewCount > 0) _infoRow(Icons.visibility_rounded, 'المشاهدات', _formatNumber(_videoInfo!.viewCount)),
          if (_videoInfo!.likeCount > 0) _infoRow(Icons.thumb_up_rounded, 'الإعجابات', _formatNumber(_videoInfo!.likeCount)),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.textMuted),
          const SizedBox(width: 10),
          Text('$label: ', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  String _formatNumber(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }

  Widget _buildActionButtons() {
    return Column(children: [
      Container(
        width: double.infinity, height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(colors: [AppTheme.accentPurple, AppTheme.accentBlue]),
          boxShadow: [BoxShadow(color: AppTheme.accentPurple.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: _download,
            child: const Center(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.download_rounded, color: Colors.white, size: 22),
              SizedBox(width: 10),
              Text('تحميل الآن', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
            ])),
          ),
        ),
      ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.2, end: 0),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: widget.url));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: const Text('تم نسخ الرابط'), backgroundColor: AppTheme.cardDark, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              );
            },
            icon: const Icon(Icons.copy_rounded, size: 16, color: AppTheme.textSecondary),
            label: Text('نسخ الرابط', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary)),
            style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.borderLight), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), padding: const EdgeInsets.symmetric(vertical: 14)),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              Share.share(widget.url);
            },
            icon: const Icon(Icons.share_rounded, size: 16, color: AppTheme.textSecondary),
            label: Text('مشاركة', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary)),
            style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.borderLight), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), padding: const EdgeInsets.symmetric(vertical: 14)),
          ),
        ),
      ]),
    ]);
  }
}

