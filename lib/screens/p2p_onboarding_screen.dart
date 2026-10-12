import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';
import 'p2p_home_screen.dart';

const _kP2PPrefKey = 'p2p_onboarding_done';

/// Returns true if the user has already seen the P2P onboarding.
Future<bool> hasSeenP2POnboarding() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_kP2PPrefKey) ?? false;
}

/// Push the P2P flow — onboarding first-time, directly otherwise.
Future<void> openP2PFlow(BuildContext context, NotificationService? ns) async {
  final seen = await hasSeenP2POnboarding();
  if (!context.mounted) return;
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => seen
          ? P2PHomeScreen(notificationService: ns)
          : P2POnboardingScreen(notificationService: ns),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
class P2POnboardingScreen extends StatefulWidget {
  final NotificationService? notificationService;
  const P2POnboardingScreen({super.key, this.notificationService});

  @override
  State<P2POnboardingScreen> createState() => _P2POnboardingScreenState();
}

class _P2POnboardingScreenState extends State<P2POnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  static const _pages = [
    _P2PPage(
      gradient: [Color(0xFF2563EB), Color(0xFF3B82F6)],
      iconData: Icons.people_alt_rounded,
      title: 'Track Personal\nLoans Easily',
      subtitle:
          'Track money you lend to friends or borrow from family — no bank, no paperwork. Everything in one place.',
      badge: '💸  Lent · Borrowed · Settled',
    ),
    _P2PPage(
      gradient: [Color(0xFF7C3AED), Color(0xFF8B5CF6)],
      iconData: Icons.compare_arrows_rounded,
      title: 'Flat Interest\nor EMI — You Choose',
      subtitle:
          'Flat Interest: borrower pays interest monthly, principal returned later.\nEMI: fixed monthly repayment over a set period.',
      badge: '💰  Monthly Interest · EMI/Reducing',
    ),
    _P2PPage(
      gradient: [Color(0xFF059669), Color(0xFF10B981)],
      iconData: Icons.chat_rounded,
      title: 'WhatsApp Reminders\nin One Tap',
      subtitle:
          'Tap "Remind" to send a polished WhatsApp message — reminds friends to pay you, or informs your lender you\'re paying.',
      badge: '📲  Smart · Contextual · One-tap',
    ),
    _P2PPage(
      gradient: [Color(0xFFD97706), Color(0xFFF59E0B)],
      iconData: Icons.receipt_long_rounded,
      title: 'Full Payment\nHistory & Tracking',
      subtitle:
          'Every payment logged with date. See which months are paid or overdue. Edit or delete any entry anytime.',
      badge: '📋  History · Overdue · Edit & Delete',
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
    await prefs.setBool(_kP2PPrefKey, true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) =>
            P2PHomeScreen(notificationService: widget.notificationService),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
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
              // ── Skip ──────────────────────────────────────────────
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

              // ── Pages ─────────────────────────────────────────────
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  itemCount: _pages.length,
                  itemBuilder: (_, i) => _buildPage(_pages[i]),
                ),
              ),

              // ── Bottom controls ───────────────────────────────────
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
                                isLast ? 'Start Tracking' : 'Continue',
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

  Widget _buildPage(_P2PPage page) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(page.iconData, size: 64, color: Colors.white),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 1,
                  ),
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

class _P2PPage {
  final List<Color> gradient;
  final IconData iconData;
  final String title;
  final String subtitle;
  final String badge;

  const _P2PPage({
    required this.gradient,
    required this.iconData,
    required this.title,
    required this.subtitle,
    required this.badge,
  });
}
