import 'package:flutter/material.dart';

class EmptyLoansState extends StatefulWidget {
  final VoidCallback onAddLoan;

  const EmptyLoansState({super.key, required this.onAddLoan});

  @override
  State<EmptyLoansState> createState() => _EmptyLoansStateState();
}

class _EmptyLoansStateState extends State<EmptyLoansState>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _floatAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _floatAnim = Tween<double>(begin: -8, end: 8).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
          parent: _controller,
          curve: const Interval(0, 0.3, curve: Curves.easeOut)),
    );
    // Trigger once
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Floating illustration
              AnimatedBuilder(
                animation: _floatAnim,
                builder: (_, child) => Transform.translate(
                  offset: Offset(0, _floatAnim.value),
                  child: child,
                ),
                child: _buildIllustration(),
              ),
              const SizedBox(height: 32),
              // Title
              const Text(
                'No loans added yet',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Add your first EMI loan to start\ntracking payments & get reminders.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 32),
              // CTA Button
              GestureDetector(
                onTap: widget.onAddLoan,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32, vertical: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Add Your First Loan',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Hint chips
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: const [
                  _HintChip('🏠 Home Loan'),
                  _HintChip('🚗 Car Loan'),
                  _HintChip('👤 Personal'),
                  _HintChip('🎓 Education'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIllustration() {
    return SizedBox(
      width: 200,
      height: 180,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background circle
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withValues(alpha: 0.07),
              shape: BoxShape.circle,
            ),
          ),
          // Inner circle
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
          ),
          // Main icon
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2563EB), Color(0xFF6366F1)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.account_balance_wallet_rounded,
              color: Colors.white,
              size: 40,
            ),
          ),
          // Floating mini cards
          Positioned(
            top: 8,
            right: 12,
            child: _floatingChip(Icons.home_rounded, const Color(0xFF10B981)),
          ),
          Positioned(
            bottom: 12,
            left: 8,
            child: _floatingChip(
                Icons.directions_car_rounded, const Color(0xFFF59E0B)),
          ),
          Positioned(
            top: 30,
            left: 0,
            child: _floatingChip(Icons.school_rounded, const Color(0xFF8B5CF6)),
          ),
        ],
      ),
    );
  }

  Widget _floatingChip(IconData icon, Color color) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Icon(icon, color: color, size: 18),
    );
  }
}

class _HintChip extends StatelessWidget {
  final String label;
  const _HintChip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF2563EB).withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: const Color(0xFF2563EB).withValues(alpha: 0.15), width: 1),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF2563EB),
        ),
      ),
    );
  }
}

