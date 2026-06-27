import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../services/media_conversion_service.dart';
import '../services/advanced_download_manager.dart';
import '../models/app_database.dart';

class ConversionScreen extends StatefulWidget {
  final DownloadTaskEntity? task;
  final String? filePath;

  const ConversionScreen({super.key, this.task, this.filePath});

  @override
  State<ConversionScreen> createState() => _ConversionScreenState();
}

class _ConversionScreenState extends State<ConversionScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  String _outputFormat = 'MP3';
  int _bitrate = 320;
  double _trimStart = 0.0;
  double _trimEnd = 1.0;
  bool _isConverting = false;

  final List<Map<String, String>> _audioFormats = [
    {'format': 'MP3', 'desc': 'الأكثر توافقاً', 'size': '~5 MB'},
    {'format': 'WAV', 'desc': 'جودة بلا خسارة', 'size': '~50 MB'},
    {'format': 'AAC', 'desc': 'جودة عالية', 'size': '~6 MB'},
    {'format': 'OGG', 'desc': 'مفتوح المصدر', 'size': '~4 MB'},
    {'format': 'FLAC', 'desc': 'ضغط بلا خسارة', 'size': '~35 MB'},
    {'format': 'M4A', 'desc': 'Apple', 'size': '~5 MB'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('تحويل وقص', style: Theme.of(context).textTheme.titleLarge),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.accentPurple,
          labelColor: AppTheme.accentPurple,
          unselectedLabelColor: AppTheme.textMuted,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: const [
            Tab(text: 'استخراج صوت'),
            Tab(text: 'قص فيديو'),
            Tab(text: 'ضغط'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAudioExtractionTab(),
          _buildTrimTab(),
          _buildCompressTab(),
        ],
      ),
    );
  }

  // === AUDIO EXTRACTION TAB ===
  Widget _buildAudioExtractionTab() {
    return Consumer<MediaConversionService>(
      builder: (context, converter, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Source file info
              _buildSourceInfo(),
              const SizedBox(height: 24),
              // Format selection
              Text('اختر صيغة الصوت', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10,
                  childAspectRatio: 1.2,
                ),
                itemCount: _audioFormats.length,
                itemBuilder: (context, index) {
                  final format = _audioFormats[index];
                  final isSelected = _outputFormat == format['format'];
                  return _formatCard(format, isSelected, () {
                    setState(() => _outputFormat = format['format']!);
                  });
                },
              ),
              const SizedBox(height: 24),
              // Bitrate slider
              Text('جودة الصوت: ${_bitrate}kbps', style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              )),
              const SizedBox(height: 12),
              Slider(
                value: _bitrate.toDouble(),
                min: 64, max: 320, divisions: 4,
                activeColor: AppTheme.accentPurple,
                onChanged: (v) => setState(() => _bitrate = v.toInt()),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('64kbps', style: Theme.of(context).textTheme.labelSmall),
                  Text('128kbps', style: Theme.of(context).textTheme.labelSmall),
                  Text('192kbps', style: Theme.of(context).textTheme.labelSmall),
                  Text('256kbps', style: Theme.of(context).textTheme.labelSmall),
                  Text('320kbps', style: Theme.of(context).textTheme.labelSmall),
                ],
              ),
              const SizedBox(height: 32),
              // Convert button
              if (converter.isProcessing)
                _buildProgressIndicator(converter)
              else
                _buildConvertButton(
                  label: 'استخراج الصوت إلى $_outputFormat',
                  icon: Icons.music_note_rounded,
                  color: AppTheme.accentPink,
                  onTap: () async {
                    final manager = context.read<AdvancedDownloadManager>();
                    if (!manager.isProActive) {
                      _showProRequired(context);
                      return;
                    }
                    await converter.convertToAudio(
                      videoPath: widget.filePath ?? '',
                      outputFormat: _outputFormat.toLowerCase(),
                      bitrate: _bitrate,
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  // === TRIM TAB ===
  Widget _buildTrimTab() {
    return Consumer<MediaConversionService>(
      builder: (context, converter, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Video preview
              Container(
                height: 220,
                decoration: BoxDecoration(
                  color: AppTheme.cardDark,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.borderLight),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.videocam_rounded, size: 48, color: AppTheme.textMuted),
                      SizedBox(height: 12),
                      Text('معاينة الفيديو', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Trim range slider
              Text('اختر النطاق الزمني', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              RangeSlider(
                values: RangeValues(_trimStart, _trimEnd),
                min: 0, max: 1,
                activeColor: AppTheme.accentPurple,
                onChanged: (values) => setState(() {
                  _trimStart = values.start;
                  _trimEnd = values.end;
                }),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_formatTrimTime(_trimStart), style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.accentPurple, fontWeight: FontWeight.w700,
                  )),
                  Text('المدة: ${_formatTrimTime(_trimEnd - _trimStart)}', style: Theme.of(context).textTheme.bodySmall),
                  Text(_formatTrimTime(_trimEnd), style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.accentPurple, fontWeight: FontWeight.w700,
                  )),
                ],
              ),
              const SizedBox(height: 32),
              // Quick presets
              Text('قص سريع', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 12),
              Row(
                children: [
                  _presetChip('أول 15 ثانية', 0, 15/180, () => setState(() { _trimStart = 0; _trimEnd = 15/180; })),
                  const SizedBox(width: 8),
                  _presetChip('آخر 30 ثانية', 150/180, 1, () => setState(() { _trimStart = 150/180; _trimEnd = 1; })),
                  const SizedBox(width: 8),
                  _presetChip('النصف الأول', 0, 0.5, () => setState(() { _trimStart = 0; _trimEnd = 0.5; })),
                ],
              ),
              const SizedBox(height: 32),
              if (converter.isProcessing)
                _buildProgressIndicator(converter)
              else
                _buildConvertButton(
                  label: 'قص الفيديو',
                  icon: Iconsax.scissor,
                  color: AppTheme.warningOrange,
                  onTap: () async {
                    final manager = context.read<AdvancedDownloadManager>();
                    if (!manager.isProActive) {
                      _showProRequired(context);
                      return;
                    }
                    await converter.trimVideo(
                      videoPath: widget.filePath ?? '',
                      startTime: Duration(seconds: (_trimStart * 180).toInt()),
                      endTime: Duration(seconds: (_trimEnd * 180).toInt()),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  // === COMPRESS TAB ===
  Widget _buildCompressTab() {
    return Consumer<MediaConversionService>(
      builder: (context, converter, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSourceInfo(),
              const SizedBox(height: 24),
              Text('مستوى الضغط', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),
              ...[
                _compressOption('ضغط خفيف', 'جودة عالية، حجم أصغر قليلاً', '70%', AppTheme.successGreen),
                _compressOption('ضغط متوسط', 'توازن بين الجودة والحجم', '50%', AppTheme.warningOrange),
                _compressOption('ضغط عالي', 'أصغر حجم ممكن', '25%', AppTheme.errorRed),
              ],
              const SizedBox(height: 32),
              if (converter.isProcessing)
                _buildProgressIndicator(converter)
              else
                _buildConvertButton(
                  label: 'ضغط الفيديو',
                  icon: Icons.minimize_rounded,
                  color: AppTheme.accentCyan,
                  onTap: () async {
                    final manager = context.read<AdvancedDownloadManager>();
                    if (!manager.isProActive) {
                      _showProRequired(context);
                      return;
                    }
                    await converter.compressVideo(videoPath: widget.filePath ?? '');
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSourceInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Row(
        children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: const LinearGradient(colors: [AppTheme.accentPurple, AppTheme.accentBlue]),
            ),
            child: const Icon(Icons.videocam_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.task?.title ?? 'فيديو محمّل',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.task?.quality ?? "1080p"} • ${widget.task?.format ?? "MP4"} • ${widget.task != null ? _formatSize(widget.task!.fileSizeBytes) : "N/A"}',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _formatCard(Map<String, String> format, bool isSelected, VoidCallback onTap) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.accentPurple.withOpacity(0.12) : AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? AppTheme.accentPurple : AppTheme.borderLight,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(format['format']!, style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: isSelected ? AppTheme.accentPurple : AppTheme.textPrimary,
              )),
              const SizedBox(height: 2),
              Text(format['desc']!, style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 9)),
              Text(format['size']!, style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppTheme.accentCyan, fontWeight: FontWeight.w600, fontSize: 10,
              )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _presetChip(String label, double start, double end, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.cardDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderLight),
          ),
          child: Center(
            child: Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
            )),
          ),
        ),
      ),
    );
  }

  Widget _compressOption(String title, String desc, String size, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderLight),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.compress_rounded, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(desc, style: Theme.of(context).textTheme.labelSmall),
                ],
              ),
            ),
            Text(size, style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900, color: color,
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(MediaConversionService converter) {
    return Column(
      children: [
        Center(
          child: SizedBox(
            width: 120, height: 120,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: converter.currentProgress,
                  strokeWidth: 8,
                  backgroundColor: AppTheme.borderLight,
                  valueColor: const AlwaysStoppedAnimation(AppTheme.accentPurple),
                ),
                Center(
                  child: Text(
                    '${(converter.currentProgress * 100).toStringAsFixed(0)}%',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900, color: AppTheme.accentPurple,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(converter.currentOperation, style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppTheme.textSecondary,
        )),
      ],
    );
  }

  Widget _buildConvertButton({
    required String label, required IconData icon, required Color color, required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity, height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(colors: [color, color.withOpacity(0.8)]),
        boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 22),
                const SizedBox(width: 10),
                Text(label, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTrimTime(double value) {
    final totalSeconds = (value * 180).toInt(); // assuming 3 min video
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatSize(int bytes) {
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  void _showProRequired(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFA500)]),
              ),
              child: const Icon(Iconsax.crown, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            Text('ميزة Pro', style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
        content: Text(
          'هذه الميزة متاحة فقط للمشتركين في VidGrab Pro. قم بالترقية لفتح جميع الميزات المتقدمة.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('لاحقاً')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushNamed(context, '/pro');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentPurple, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('ترقية الآن'),
          ),
        ],
      ),
    );
  }
}