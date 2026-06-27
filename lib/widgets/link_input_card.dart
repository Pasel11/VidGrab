import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import '../config/theme.dart';
import '../config/routes.dart';
import '../services/download_service.dart';

class LinkInputCard extends StatefulWidget {
  final TextEditingController controller;

  const LinkInputCard({super.key, required this.controller});

  @override
  State<LinkInputCard> createState() => _LinkInputCardState();
}

class _LinkInputCardState extends State<LinkInputCard> {
  bool _isFocused = false;
  bool _hasUrl = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    final hasUrl = widget.controller.text.trim().isNotEmpty;
    if (hasUrl != _hasUrl) {
      setState(() => _hasUrl = hasUrl);
    }
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData('text/plain');
    if (data?.text != null && data!.text!.isNotEmpty) {
      widget.controller.text = data.text!;
    }
  }

  void _clearUrl() {
    widget.controller.clear();
    FocusScope.of(context).unfocus();
  }

  void _handleDownload() {
    final url = widget.controller.text.trim();
    if (url.isEmpty) return;

    final service = Provider.of<DownloadService>(context, listen: false);
    if (!service.isValidUrl(url)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('الرابط غير صالح. يرجى إدخال رابط صحيح.', style: TextStyle(color: Colors.white)),
          backgroundColor: AppTheme.errorRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    Navigator.pushNamed(context, AppRoutes.download, arguments: {'url': url});
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _isFocused ? AppTheme.accentPurple : AppTheme.borderLight,
            width: _isFocused ? 2 : 1,
          ),
          boxShadow: _isFocused
              ? [BoxShadow(color: AppTheme.accentPurple.withOpacity(0.15), blurRadius: 30, spreadRadius: 0)]
              : [],
        ),
        child: Column(
          children: [
            Focus(
              onFocusChange: (focused) => setState(() => _isFocused = focused),
              child: TextField(
                controller: widget.controller,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textPrimary, fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.right,
                textDirection: TextDirection.ltr,
                decoration: InputDecoration(
                  hintText: 'الصق رابط الفيديو هنا...',
                  hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textMuted),
                  prefixIcon: _hasUrl
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18, color: AppTheme.textMuted),
                          onPressed: _clearUrl,
                        )
                      : null,
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!_hasUrl)
                        IconButton(
                          icon: const Icon(Iconsax.copy, size: 20, color: AppTheme.textSecondary),
                          onPressed: _pasteFromClipboard,
                          tooltip: 'لصق من الحافظة',
                        ),
                      const SizedBox(width: 4),
                    ],
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                ),
                onSubmitted: (_) => _handleDownload(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: _hasUrl
                      ? const LinearGradient(colors: [AppTheme.accentPurple, AppTheme.accentBlue])
                      : null,
                  color: _hasUrl ? null : AppTheme.borderLight,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: _hasUrl ? _handleDownload : null,
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.download_rounded, size: 20,
                            color: _hasUrl ? Colors.white : AppTheme.textMuted),
                          const SizedBox(width: 10),
                          Text('تحميل الفيديو', style: TextStyle(
                            color: _hasUrl ? Colors.white : AppTheme.textMuted,
                            fontSize: 15, fontWeight: FontWeight.w700,
                          )),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1, end: 0);
  }
}