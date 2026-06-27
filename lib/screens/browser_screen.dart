import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter/services.dart';
import '../config/theme.dart';
import '../config/routes.dart';
import '../services/advanced_download_manager.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

class BrowserScreen extends StatefulWidget {
  const BrowserScreen({super.key});

  @override
  State<BrowserScreen> createState() => _BrowserScreenState();
}

class _BrowserScreenState extends State<BrowserScreen> with TickerProviderStateMixin {
  late WebViewController _controller;
  final TextEditingController _urlController = TextEditingController(text: 'https://www.google.com');
  final List<String> _history = [];
  final List<String> _bookmarks = [];
  int _currentIndex = -1;
  bool _isLoading = false;
  double _loadingProgress = 0;
  bool _showToolbar = true;

  // Social media shortcuts
  final List<Map<String, dynamic>> _socialShortcuts = [
    {'name': 'YouTube', 'url': 'https://m.youtube.com', 'icon': Icons.play_circle_filled_rounded, 'color': Color(0xFFFF0000)},
    {'name': 'Instagram', 'url': 'https://www.instagram.com', 'icon': Icons.camera_alt_rounded, 'color': Color(0xFFE4405F)},
    {'name': 'TikTok', 'url': 'https://www.tiktok.com', 'icon': Icons.music_note_rounded, 'color': Color(0xFF000000)},
    {'name': 'X', 'url': 'https://x.com', 'icon': Icons.alternate_email_rounded, 'color': Color(0xFF1DA1F2)},
    {'name': 'Facebook', 'url': 'https://m.facebook.com', 'icon': Icons.facebook_rounded, 'color': Color(0xFF1877F2)},
    {'name': 'Snapchat', 'url': 'https://www.snapchat.com', 'icon': Icons.flash_on_rounded, 'color': Color(0xFFFFFC00)},
  ];

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) => setState(() => _loadingProgress = progress / 100),
          onPageStarted: (_) => setState(() => _isLoading = true),
          onPageFinished: (url) {
            setState(() => _isLoading = false);
            _urlController.text = url;
          },
          onUrlChange: (change) {
            _urlController.text = change.url ?? '';
          },
        ),
      )
      ..setBackgroundColor(AppTheme.primaryDark)
      ..loadRequest(Uri.parse('https://www.google.com'));

    // Inject JS to detect video URLs
    _controller.runJavaScript('''
      window.addEventListener('load', function() {
        // Observe DOM for video elements
        const observer = new MutationObserver(function(mutations) {
          mutations.forEach(function(mutation) {
            mutation.addedNodes.forEach(function(node) {
              if (node.nodeName === 'VIDEO' || node.querySelector && node.querySelector('video')) {
                window.flutter_inappwebview?.callHandler('videoDetected');
              }
            });
          });
        });
        observer.observe(document.body, { childList: true, subtree: true });
      });
    ''');
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _goToUrl(String url) {
    if (!url.startsWith('http')) url = 'https://$url';
    _controller.loadRequest(Uri.parse(url));
    _history.add(url);
    _currentIndex = _history.length - 1;
    FocusScope.of(context).unfocus();
  }

  void _downloadCurrentPage() {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;

    // Detect platform from URL
    final manager = context.read<AdvancedDownloadManager>();
    // Navigate to download screen with URL
    Navigator.pushNamed(context, AppRoutes.download, arguments: {'url': url});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: WillPopScope(
        onWillPop: () async {
          if (_currentIndex > 0) {
            _controller.goBack();
            _currentIndex--;
            return false;
          }
          return true;
        },
        child: SafeArea(
          child: Column(
            children: [
              if (_showToolbar) _buildUrlBar(),
              if (_isLoading) _buildProgressBar(),
              if (_showToolbar) _buildSocialBar(),
              Expanded(child: WebViewWidget(controller: _controller)),
              if (_showToolbar) _buildBottomBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUrlBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
      decoration: BoxDecoration(
        color: AppTheme.secondaryDark,
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Row(
        children: [
          // Back
          _navButton(Icons.arrow_back_ios_new_rounded, () => _controller.goBack()),
          const SizedBox(width: 4),
          // Forward
          _navButton(Icons.arrow_forward_ios_rounded, () => _controller.goForward()),
          const SizedBox(width: 8),
          // URL field
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.cardDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: TextField(
                controller: _urlController,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                textDirection: TextDirection.ltr,
                onSubmitted: _goToUrl,
                decoration: InputDecoration(
                  prefixIcon: _urlController.text.startsWith('https')
                      ? const Icon(Icons.lock_rounded, size: 14, color: AppTheme.successGreen)
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  isDense: true,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Download button (the killer feature)
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(colors: [AppTheme.accentPurple, AppTheme.accentBlue]),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _downloadCurrentPage,
                child: const Center(
                  child: Icon(Icons.download_rounded, color: Colors.white, size: 18),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _navButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 16, color: AppTheme.textSecondary),
      ),
    );
  }

  Widget _buildProgressBar() {
    return LinearProgressIndicator(
      value: _loadingProgress,
      backgroundColor: Colors.transparent,
      valueColor: const AlwaysStoppedAnimation(AppTheme.accentPurple),
      minHeight: 2,
    );
  }

  Widget _buildSocialBar() {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _socialShortcuts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final social = _socialShortcuts[index];
          return InkWell(
            onTap: () => _goToUrl(social['url'] as String),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 56,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.cardDark,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(social['icon'] as IconData, color: social['color'] as Color, size: 20),
                  const SizedBox(height: 4),
                  Text(
                    social['name'] as String,
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 9, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.secondaryDark,
        border: Border(top: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _bottomItem(Iconsax.home, 'الرئيسية', () => Navigator.pushReplacementNamed(context, AppRoutes.home)),
          _bottomItem(Icons.language_rounded, 'المتصفح', () {}, isActive: true),
          _bottomItem(Iconsax.folder, 'المكتبة', () => Navigator.pushNamed(context, '/library')),
          _bottomItem(Iconsax.setting_2, 'الإعدادات', () => Navigator.pushNamed(context, AppRoutes.settings)),
        ],
      ),
    );
  }

  Widget _bottomItem(IconData icon, String label, VoidCallback onTap, {bool isActive = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 22, color: isActive ? AppTheme.accentPurple : AppTheme.textMuted),
          const SizedBox(height: 3),
          Text(label, style: TextStyle(
            fontSize: 10, fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isActive ? AppTheme.accentPurple : AppTheme.textMuted,
          )),
        ],
      ),
    );
  }
}