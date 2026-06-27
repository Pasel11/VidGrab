import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:confetti/confetti.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../services/advanced_download_manager.dart';

class ProScreen extends StatefulWidget {
  const ProScreen({super.key});

  @override
  State<ProScreen> createState() => _ProScreenState();
}

class _ProScreenState extends State<ProScreen> {
  late ConfettiController _confettiController;
  int _selectedPlan = 1; // 0=weekly, 1=monthly, 2=yearly
  final TextEditingController _referralController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _referralController.dispose();
    super.dispose();
  }

  void _showConfetti() => _confettiController.play();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 60),
                // Hero
                _buildHero(),
                const SizedBox(height: 32),
                // Plans
                _buildPlans(),
                const SizedBox(height: 32),
                // Features comparison
                _buildComparison(),
                const SizedBox(height: 32),
                // Referral
                _buildReferralSection(),
                const SizedBox(height: 100),
              ],
            ),
          ),
          // Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                AppTheme.accentPurple, AppTheme.accentBlue, AppTheme.accentPink,
                AppTheme.successGreen, AppTheme.warningOrange, Colors.white,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Container(
            width: 100, height: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                colors: [Color(0xFFFFD700), Color(0xFFFFA500), Color(0xFFFF6B35)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFD700).withOpacity(0.3),
                  blurRadius: 40, spreadRadius: 5,
                ),
              ],
            ),
            child: const Icon(Iconsax.crown, color: Colors.white, size: 48),
          ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
          const SizedBox(height: 20),
          Text('VidGrab Pro', style: Theme.of(context).textTheme.displayMedium?.copyWith(
            fontWeight: FontWeight.w900, fontSize: 32,
            background: Paint()..shader = const LinearGradient(
              colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
            ).createShader(const Rect.fromLTWH(0, 0, 250, 40)),
          )),
          const SizedBox(height: 8),
          Text('افتح الإمكانيات الكاملة', style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppTheme.textSecondary,
          )),
        ],
      ),
    );
  }

  Widget _buildPlans() {
    final plans = [
      _Plan('أسبوعي', '\$2.99', '/أسبوع', 'جرّب قبل الالتزام', ''),
      _Plan('شهري', '\$7.99', '/شهر', 'الأكثر شعبية', 'الأكثر شعبية'),
      _Plan('سنوي', '\$49.99', '/سنة', 'وفّر 48%', ''),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Text('اختر خطتك', style: Theme.of(context).textTheme.titleMedium),
          ),
          const SizedBox(height: 14),
          ...plans.asMap().entries.map((entry) {
            final index = entry.key;
            final plan = entry.value;
            final isSelected = index == _selectedPlan;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.accentPurple.withOpacity(0.08) : AppTheme.cardDark,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppTheme.accentPurple : AppTheme.borderLight,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => setState(() => _selectedPlan = index),
                  child: Row(
                    children: [
                      // Radio
                      Container(
                        width: 24, height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected ? AppTheme.accentPurple : Colors.transparent,
                          border: Border.all(
                            color: isSelected ? AppTheme.accentPurple : AppTheme.textMuted,
                            width: 2,
                          ),
                        ),
                        child: isSelected ? const Icon(Icons.check_rounded, color: Colors.white, size: 16) : null,
                      ),
                      const SizedBox(width: 16),
                      // Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(plan.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800, fontSize: 17,
                                )),
                                if (plan.badge.isNotEmpty) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppTheme.accentPurple,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(plan.badge, style: const TextStyle(
                                      color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700,
                                    )),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(plan.description, style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondary,
                            )),
                          ],
                        ),
                      ),
                      // Price
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(plan.price, style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: isSelected ? AppTheme.accentPurple : AppTheme.textPrimary,
                          )),
                          Text(plan.period, style: Theme.of(context).textTheme.labelSmall),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
          // Subscribe button
          Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFA500)]),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFD700).withOpacity(0.3),
                  blurRadius: 20, offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () async {
                  _showConfetti();
                  HapticFeedback.heavyImpact();
                  final days = [7, 30, 365][_selectedPlan];
                  await context.read<AdvancedDownloadManager>().activatePro(days: days);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('تم تفعيل Pro بنجاح! استمتع بجميع الميزات'),
                        backgroundColor: AppTheme.successGreen,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                child: const Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Iconsax.crown, color: Colors.white, size: 22),
                      SizedBox(width: 10),
                      Text('اشترك الآن', style: TextStyle(
                        color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800,
                      )),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparison() {
    final features = [
      _Feature('تحميل 4K Ultra HD', true, false),
      _Feature('تحويل الصيغ (MP3, WAV, AAC)', true, false),
      _Feature('قص وتحرير الفيديو', true, false),
      _Feature('تحميلات متوازية (5 معاً)', true, false),
      _Feature('المجلد السري', true, false),
      _Feature('المتصفح المدمج', true, false),
      _Feature('بدون إعلانات', true, false),
      _Feature('تخزين سحابي 5GB', true, false),
      _Feature('تحميل 1080p', true, true),
      _Feature('سجل التحميلات', true, true),
      _Feature('الإشعارات', true, true),
      _Feature('اختيار الجودة', true, true),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.borderLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('مقارنة المميزات', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text('اكتشف ما ستحصل عليه', style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
            )),
            const SizedBox(height: 18),
            // Header
            const Row(
              children: [
                Expanded(child: SizedBox()),
                SizedBox(width: 60, child: Text('مجاني', textAlign: TextAlign.center, style: TextStyle(
                  color: AppTheme.textMuted, fontWeight: FontWeight.w600, fontSize: 12,
                ))),
                SizedBox(width: 60, child: Text('Pro', textAlign: TextAlign.center, style: TextStyle(
                  color: AppTheme.accentPurple, fontWeight: FontWeight.w700, fontSize: 12,
                ))),
              ],
            ),
            const Divider(color: AppTheme.borderLight, height: 24),
            ...features.map((f) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(f.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  ),
                  SizedBox(
                    width: 60,
                    child: Center(
                      child: Icon(
                        f.free ? Icons.check_circle_rounded : Icons.close_rounded,
                        size: 20,
                        color: f.free ? AppTheme.successGreen : AppTheme.textMuted.withOpacity(0.3),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 60,
                    child: Center(
                      child: Icon(
                        Icons.check_circle_rounded,
                        size: 20,
                        color: AppTheme.accentPurple,
                      ),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildReferralSection() {
    final manager = context.read<AdvancedDownloadManager>();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.successGreen.withOpacity(0.1), AppTheme.accentCyan.withOpacity(0.05)],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.successGreen.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.successGreen.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Iconsax.gift, color: AppTheme.successGreen, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ادعُ أصدقائك واحصل على Pro مجاناً!', style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800, fontSize: 15,
                      )),
                      const SizedBox(height: 3),
                      Text('كل 3 دعوات = أسبوع Pro مجاناً', style: Theme.of(context).textTheme.labelSmall),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Referral code display
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.primaryDark,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('كود الإحالة الخاص بك:', style: TextStyle(
                          color: AppTheme.textMuted, fontSize: 11,
                        )),
                        const SizedBox(height: 4),
                        Text(
                          manager.referralLink,
                          style: const TextStyle(
                            color: AppTheme.accentCyan, fontSize: 14,
                            fontWeight: FontWeight.w700, letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Iconsax.copy, color: AppTheme.accentCyan, size: 20),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: manager.referralLink));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('تم نسخ رابط الإحالة!'),
                          backgroundColor: AppTheme.successGreen,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Iconsax.share, color: AppTheme.accentCyan, size: 20),
                    onPressed: () {
                      // Share referral link
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Redeem code
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _referralController,
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.ltr,
                    decoration: InputDecoration(
                      hintText: 'أدخل كود إحالة صديق',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      prefixIcon: const Icon(Iconsax.ticket, size: 18, color: AppTheme.textMuted),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    if (_referralController.text.isNotEmpty) {
                      context.read<AdvancedDownloadManager>().processReferral(_referralController.text);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.successGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('استبدال', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            // Stats
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _statItem('${manager.settings?.referralCount ?? 0}', 'إحالات ناجحة'),
                _statItem('${3 - (manager.settings?.referralCount ?? 0) % 3}', 'للحصول على Pro'),
                _statItem('${manager.settings?.totalDownloads ?? 0}', 'إجمالي التحميلات'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String value, String label) {
    return Column(
      children: [
        Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w900, color: AppTheme.successGreen,
        )),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

class _Plan {
  final String name;
  final String price;
  final String period;
  final String description;
  final String badge;

  const _Plan(this.name, this.price, this.period, this.description, this.badge);
}

class _Feature {
  final String name;
  final bool pro;
  final bool free;

  const _Feature(this.name, this.pro, this.free);
}