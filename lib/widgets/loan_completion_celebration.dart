import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'dart:math';

class LoanCompletionCelebration extends StatefulWidget {
  final String loanName;
  final double totalPaid;
  final String currencySymbol;
  final int tenureMonths;
  final VoidCallback onDismiss;

  const LoanCompletionCelebration({
    super.key,
    required this.loanName,
    required this.totalPaid,
    required this.currencySymbol,
    required this.tenureMonths,
    required this.onDismiss,
  });

  @override
  State<LoanCompletionCelebration> createState() =>
      _LoanCompletionCelebrationState();
}

class _LoanCompletionCelebrationState extends State<LoanCompletionCelebration>
    with TickerProviderStateMixin {
  late ConfettiController _confettiCenter;
  late ConfettiController _confettiLeft;
  late ConfettiController _confettiRight;

  late AnimationController _scaleController;
  late AnimationController _slideController;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();

    _confettiCenter = ConfettiController(duration: const Duration(seconds: 6));
    _confettiLeft = ConfettiController(duration: const Duration(seconds: 5));
    _confettiRight = ConfettiController(duration: const Duration(seconds: 5));

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _scaleAnim = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );
    _fadeAnim = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeOut,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    // Start animations with slight delays for dramatic effect
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _scaleController.forward();
        _slideController.forward();
      }
    });
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _confettiCenter.play();
        _confettiLeft.play();
        _confettiRight.play();
      }
    });
  }

  @override
  void dispose() {
    _confettiCenter.dispose();
    _confettiLeft.dispose();
    _confettiRight.dispose();
    _scaleController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  String _formatYearsMonths(int months) {
    final years = months ~/ 12;
    final rem = months % 12;
    if (years == 0) return '$rem months';
    if (rem == 0) return '$years ${years == 1 ? 'year' : 'years'}';
    return '$years yr $rem mo';
  }

  String _formatAmount(double amount) {
    if (amount >= 10000000) return '${widget.currencySymbol}${(amount / 10000000).toStringAsFixed(2)} Cr';
    if (amount >= 100000) return '${widget.currencySymbol}${(amount / 100000).toStringAsFixed(2)} L';
    return '${widget.currencySymbol}${amount.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.6),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Dismiss tap area
          GestureDetector(onTap: widget.onDismiss),

          // Left confetti
          Align(
            alignment: Alignment.topLeft,
            child: ConfettiWidget(
              confettiController: _confettiLeft,
              blastDirection: -pi / 4,
              emissionFrequency: 0.08,
              numberOfParticles: 12,
              gravity: 0.3,
              colors: const [
                Color(0xFF6366F1), Color(0xFF10B981),
                Color(0xFFF59E0B), Color(0xFFEF4444),
                Color(0xFF3B82F6), Color(0xFFEC4899),
              ],
            ),
          ),

          // Right confetti
          Align(
            alignment: Alignment.topRight,
            child: ConfettiWidget(
              confettiController: _confettiRight,
              blastDirection: -3 * pi / 4,
              emissionFrequency: 0.08,
              numberOfParticles: 12,
              gravity: 0.3,
              colors: const [
                Color(0xFF8B5CF6), Color(0xFF06B6D4),
                Color(0xFFF97316), Color(0xFF84CC16),
                Color(0xFFEC4899), Color(0xFF6366F1),
              ],
            ),
          ),

          // Center confetti burst
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiCenter,
              blastDirectionality: BlastDirectionality.explosive,
              emissionFrequency: 0.04,
              numberOfParticles: 20,
              gravity: 0.25,
              shouldLoop: false,
              colors: const [
                Color(0xFF6366F1), Color(0xFF10B981),
                Color(0xFFF59E0B), Color(0xFFEF4444),
                Color(0xFF3B82F6), Color(0xFFEC4899),
                Color(0xFF8B5CF6), Color(0xFF06B6D4),
              ],
            ),
          ),

          // Main card
          FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: ScaleTransition(
                  scale: _scaleAnim,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6366F1).withValues(alpha: 0.25),
                          blurRadius: 40,
                          offset: const Offset(0, 16),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Top gradient banner
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                            ),
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(28),
                            ),
                          ),
                          child: Column(
                            children: [
                              // Trophy icon with glow
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.white.withValues(alpha: 0.3),
                                      blurRadius: 20,
                                      spreadRadius: 4,
                                    ),
                                  ],
                                ),
                                child: const Text(
                                  '🏆',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 40),
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Loan Completed! 🎉',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                widget.loanName,
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),

                        // Stats section
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              const Text(
                                'You did it! All EMIs cleared 💪',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF374151),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 20),

                              // Stats row
                              Row(
                                children: [
                                  _statTile(
                                    emoji: '💰',
                                    label: 'Total Paid',
                                    value: _formatAmount(widget.totalPaid),
                                    color: const Color(0xFF10B981),
                                  ),
                                  const SizedBox(width: 12),
                                  _statTile(
                                    emoji: '📅',
                                    label: 'Duration',
                                    value: _formatYearsMonths(widget.tenureMonths),
                                    color: const Color(0xFF6366F1),
                                  ),
                                  const SizedBox(width: 12),
                                  _statTile(
                                    emoji: '✅',
                                    label: 'EMIs Paid',
                                    value: '${widget.tenureMonths}',
                                    color: const Color(0xFFF59E0B),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 20),

                              // Motivational message
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: const Color(0xFF10B981).withValues(alpha: 0.2),
                                  ),
                                ),
                                child: const Row(
                                  children: [
                                    Text('🌟', style: TextStyle(fontSize: 20)),
                                    SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'Debt-free feels amazing! Keep up the great financial discipline.',
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          color: Color(0xFF065F46),
                                          fontWeight: FontWeight.w500,
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 20),

                              // Buttons
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: widget.onDismiss,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF6366F1),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: const Text(
                                    '🎊  Awesome, Thanks!',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
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
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statTile({
    required String emoji,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: color,
                letterSpacing: -0.3,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Show the celebration overlay
void showLoanCompletionCelebration({
  required BuildContext context,
  required String loanName,
  required double totalPaid,
  required String currencySymbol,
  required int tenureMonths,
}) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss',
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (ctx, _, __) => LoanCompletionCelebration(
      loanName: loanName,
      totalPaid: totalPaid,
      currencySymbol: currencySymbol,
      tenureMonths: tenureMonths,
      onDismiss: () => Navigator.of(ctx).pop(),
    ),
  );
}

