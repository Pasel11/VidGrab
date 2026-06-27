import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import '../config/theme.dart';
import '../config/routes.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _buttonController;

  final List<_OnboardingPage> _pages = [
    _OnboardingPage(
      icon: Icons.link_rounded,
      iconGradient: [AppTheme.accentPurple, AppTheme.accentBlue],
      title: 'الصق أي رابط...',
      subtitle: 'ونحن نتكفل بالباقي!',
      description: 'فقط انسخ رابط أي فيديو من أي منصة اجتماعية والصقه هنا. سنقوم بكل شيء تلقائياً - من كشف المنصة لاختيار الجودة المثالية.',
      illustration: '🔗',
    ),
    _OnboardingPage(
      icon: Icons.devices_rounded,
      iconGradient: [AppTheme.accentPink, AppTheme.warningOrange],
      title: '12+ منصة في مكان واحد',
      subtitle: 'كل ما تحتاجه في تطبيق واحد',
      description: 'YouTube, Instagram, TikTok, X, Facebook, Snapchat وغيرها الكثير. لم تعد بحاجة لتحميل عدة تطبيقات لتنزيل الفيديوهات.',
      illustration: '📱',
    ),
    _OnboardingPage(
      icon: Icons.auto_awesome_rounded,
      iconGradient: [AppTheme.successGreen, AppTheme.accentCyan],
      title: 'اختر الجودة التي تناسبك',
      subtitle: 'من 144p حتى 4K Ultra HD',
      description: 'اختر من بين عدة جودات بما فيها استخراج الصوت بجودة عالية. كما يمكنك قص الفيديو وتحويل الصيغ.',
      illustration: '🎬',
    ),
    _OnboardingPage(
      icon: Icons.verified_user_rounded,
      iconGradient: [AppTheme.accentCyan, AppTheme.accentPurple],
      title: 'سريع، آمن، وخاص',
      subtitle: 'خصوصيتك هي أولويتنا القصوى',
      description: 'تحميلات فائقة السرعة بدون إعلانات مزعجة. قفل التطبيق بالبصمة، ومجلد سري لحماية ملفاتك الحساسة.',
      illustration: '🔒',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _buttonController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
  }

  @override
  void dispose() {
    _pageController.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(duration: const Duration(milliseconds: 500), curve: Curves.easeOutCubic);
    } else {
      _completeOnboarding();
    }
  }

  void _skipOnboarding() => _completeOnboarding();

  void _completeOnboarding() {
    Navigator.pushReplacementNamed(context, AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      body: SafeArea(
        child: Stack(
          children: [
            // Background particles
            Positioned.fill(
              child: Opacity(
                opacity: 0.03,
                child: Image.network(
                  'https://picsum.photos/seed/vidgrab-bg/400/800',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),
            // Skip button
            Positioned(
              top: 16, left: 16, right: 16,
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _skipOnboarding,
                  child: Text('تخطي', style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textMuted, fontWeight: FontWeight.w600,
                  )),
                ),
              ),
            ),
            // Pages
            PageView.builder(
              controller: _pageController,
              itemCount: _pages.length,
              onPageChanged: (index) {
                setState(() => _currentPage = index);
                _buttonController.reset();
                _buttonController.forward();
              },
              itemBuilder: (context, index) => _buildPage(_pages[index]),
            ),
            // Bottom controls
            Positioned(
              bottom: 40, left: 24, right: 24,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Page indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pages.length, (index) {
                      final isActive = index == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isActive ? 32 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: isActive
                              ? AppTheme.accentPurple
                              : AppTheme.textMuted.withOpacity(0.3),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 32),
                  // Next button
                  ScaleTransition(
                    scale: CurvedAnimation(parent: _buttonController, curve: Curves.easeOutBack),
                    child: Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(
                          colors: _currentPage == _pages.length - 1
                              ? [AppTheme.successGreen, AppTheme.accentCyan]
                              : [AppTheme.accentPurple, AppTheme.accentBlue],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (_currentPage == _pages.length - 1 ? AppTheme.successGreen : AppTheme.accentPurple)
                                .withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: _nextPage,
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _currentPage == _pages.length - 1 ? 'ابدأ الآن!' : 'التالي',
                                  style: const TextStyle(
                                    color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  _currentPage == _pages.length - 1
                                      ? Icons.rocket_launch_rounded
                                      : Icons.arrow_back_rounded,
                                  color: Colors.white, size: 20,
                                ),
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
          ],
        ),
      ),
    );
  }

  Widget _buildPage(_OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 80, 32, 200),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated icon
          Container(
            width: 160, height: 160,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(48),
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: page.iconGradient,
              ),
              boxShadow: [
                BoxShadow(
                  color: page.iconGradient[0].withOpacity(0.3),
                  blurRadius: 40, spreadRadius: 5,
                ),
              ],
            ),
            child: Center(
              child: Text(page.illustration, style: const TextStyle(fontSize: 64)),
            ),
          ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
          const SizedBox(height: 40),
          // Title
          Text(
            page.title,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w900, fontSize: 28,
              background: Paint()
                ..shader = LinearGradient(colors: page.iconGradient)
                    .createShader(const Rect.fromLTWH(0, 0, 300, 40)),
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
          const SizedBox(height: 8),
          // Subtitle
          Text(
            page.subtitle,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.textSecondary, fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.15),
          const SizedBox(height: 20),
          // Description
          Text(
            page.description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textMuted, height: 1.8, fontSize: 15,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
        ],
      ),
    );
  }
}

class _OnboardingPage {
  final IconData icon;
  final List<Color> iconGradient;
  final String title;
  final String subtitle;
  final String description;
  final String illustration;

  const _OnboardingPage({
    required this.icon,
    required this.iconGradient,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.illustration,
  });
}