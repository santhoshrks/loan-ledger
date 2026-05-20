import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';
import '../services/loan_storage_service.dart';
import '../services/notification_service.dart';

class OnboardingScreen extends StatefulWidget {
  final LoanStorageService? storageService;
  final NotificationService? notificationService;

  const OnboardingScreen({
    super.key,
    this.storageService,
    this.notificationService,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  final List<_OnboardPage> _pages = const [
    _OnboardPage(
      gradient: [Color(0xFF2563EB), Color(0xFF3B82F6)],
      iconData: Icons.account_balance_wallet_rounded,
      iconBg: Color(0x33FFFFFF),
      title: 'Track All Your\nEMIs in One Place',
      subtitle:
          'Never miss a payment again. Add all your loans — home, car, personal — and see everything at a glance.',
      badge: '🏦  Home · Car · Personal · Gold',
    ),
    _OnboardPage(
      gradient: [Color(0xFF7C3AED), Color(0xFF8B5CF6)],
      iconData: Icons.notifications_active_rounded,
      iconBg: Color(0x33FFFFFF),
      title: 'Smart Payment\nReminders',
      subtitle:
          'Get notified 7 days, 3 days, and 1 day before your EMI is due. No more late fees or penalties.',
      badge: '🔔  7 days · 3 days · 1 day alerts',
    ),
    _OnboardPage(
      gradient: [Color(0xFF059669), Color(0xFF10B981)],
      iconData: Icons.insights_rounded,
      iconBg: Color(0x33FFFFFF),
      title: 'Powerful\nLoan Analytics',
      subtitle:
          'See your debt payoff timeline, interest breakdown, and financial health score — all in one dashboard.',
      badge: '📊  Analytics · Health Score · AI Advisor',
    ),
    _OnboardPage(
      gradient: [Color(0xFFD97706), Color(0xFFF59E0B)],
      iconData: Icons.lock_rounded,
      iconBg: Color(0x33FFFFFF),
      title: 'Private &\nSecure',
      subtitle:
          'Your data stays on your device. No account needed. Backup & restore whenever you want.',
      badge: '🔒  100% Offline · No Sign-up',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);
    _animController.reset();
    _animController.forward();
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => HomeScreen(
          storageService: widget.storageService,
          notificationService: widget.notificationService,
        ),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final page = _pages[_currentPage];
    final isLast = _currentPage == _pages.length - 1;

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: page.gradient,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Skip button
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 12, right: 20),
                  child: TextButton(
                    onPressed: _finish,
                    child: const Text(
                      'Skip',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),

              // Page view
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  itemCount: _pages.length,
                  itemBuilder: (_, i) => _buildPage(_pages[i]),
                ),
              ),

              // Bottom controls
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 36),
                child: Column(
                  children: [
                    // Dots
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _pages.length,
                        (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _currentPage == i ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _currentPage == i
                                ? Colors.white
                                : Colors.white38,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    // CTA Button
                    SizedBox(
                      width: double.infinity,
                      child: GestureDetector(
                        onTap: () {
                          if (isLast) {
                            _finish();
                          } else {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeInOut,
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                isLast ? 'Get Started' : 'Continue',
                                style: TextStyle(
                                  color: page.gradient.first,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                isLast
                                    ? Icons.rocket_launch_rounded
                                    : Icons.arrow_forward_rounded,
                                color: page.gradient.first,
                                size: 18,
                              ),
                            ],
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
      ),
    );
  }

  Widget _buildPage(_OnboardPage page) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Big icon
              Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  color: page.iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  page.iconData,
                  size: 64,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 40),
              // Title
              Text(
                page.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1.15,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 16),
              // Subtitle
              Text(
                page.subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.white70,
                  height: 1.55,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 28),
              // Badge pill
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3), width: 1),
                ),
                child: Text(
                  page.badge,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardPage {
  final List<Color> gradient;
  final IconData iconData;
  final Color iconBg;
  final String title;
  final String subtitle;
  final String badge;

  const _OnboardPage({
    required this.gradient,
    required this.iconData,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.badge,
  });
}

