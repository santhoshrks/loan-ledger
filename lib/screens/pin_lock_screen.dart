import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/security_service.dart';
import '../services/auth_provider.dart';
import '../services/haptic_service.dart';
import '../theme/app_theme.dart';

class PinLockScreen extends StatefulWidget {
  final VoidCallback onUnlocked;
  final String? customTitle;

  const PinLockScreen({
    super.key,
    required this.onUnlocked,
    this.customTitle,
  });

  @override
  State<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends State<PinLockScreen>
    with SingleTickerProviderStateMixin {
  final SecurityService _securityService = SecurityService();
  String _enteredPin = '';
  bool _isError = false;
  bool _canUseBiometrics = false;
  bool _isBiometricEnabled = false;
  bool _showForgotDialog = false;

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -12.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -12.0, end: 12.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 12.0, end: -8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.easeInOut,
    ));

    _checkBiometricsAndAuthenticate();
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  Future<void> _checkBiometricsAndAuthenticate() async {
    final available = await _securityService.isBiometricsAvailable();
    final enabled = await _securityService.isBiometricEnabled();

    if (mounted) {
      setState(() {
        _canUseBiometrics = available;
        _isBiometricEnabled = enabled;
      });
    }

    if (available && enabled) {
      // Trigger fingerprint automatically on start
      _authenticateBiometrics();
    }
  }

  Future<void> _authenticateBiometrics() async {
    final success = await _securityService.authenticateWithBiometrics(
      reason: 'Scan your fingerprint or face to unlock LoanLedger',
    );

    if (success && mounted) {
      HapticService.light();
      widget.onUnlocked();
    }
  }

  void _onKeyPress(String digit) {
    if (_enteredPin.length >= 4) return;

    HapticService.selection();

    setState(() {
      _isError = false;
      _enteredPin += digit;
    });

    if (_enteredPin.length == 4) {
      _verifyPin();
    }
  }

  void _onBackspace() {
    if (_enteredPin.isEmpty) return;
    HapticService.selection();
    setState(() {
      _isError = false;
      _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
    });
  }

  Future<void> _verifyPin() async {
    final isValid = await _securityService.verifyPin(_enteredPin);

    if (!mounted) return;

    if (isValid) {
      HapticService.light();
      widget.onUnlocked();
    } else {
      HapticService.error();
      _shakeController.forward(from: 0.0);
      setState(() {
        _isError = true;
      });

      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) {
        setState(() {
          _enteredPin = '';
          _isError = false;
        });
      }
    }
  }

  void _handleForgotPin() {
    setState(() {
      _showForgotDialog = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.bgDark : AppTheme.bgLight,
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(height: 12),

                  // Top Logo & Header
                  Column(
                    children: [
                      Container(
                        height: 72,
                        width: 72,
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryColor.withValues(alpha: 0.3),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.lock_outline_rounded,
                          size: 38,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        widget.customTitle ?? 'Unlock LoanLedger',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _isError
                            ? 'Incorrect PIN. Try again.'
                            : 'Enter your 4-digit PIN to continue',
                        style: TextStyle(
                          fontSize: 14,
                          color: _isError
                              ? AppTheme.statusError
                              : (isDark ? AppTheme.textLight : AppTheme.textMedium),
                          fontWeight: _isError ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),

                  // Animated PIN Dots Indicator
                  AnimatedBuilder(
                    animation: _shakeAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(_shakeAnimation.value, 0),
                        child: child,
                      );
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(4, (index) {
                        final isFilled = index < _enteredPin.length;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          margin: const EdgeInsets.symmetric(horizontal: 12),
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isError
                                ? AppTheme.statusError
                                : (isFilled
                                    ? primaryColor
                                    : (isDark
                                        ? Colors.white24
                                        : Colors.grey[300])),
                            boxShadow: isFilled && !_isError
                                ? [
                                    BoxShadow(
                                      color: primaryColor.withValues(alpha: 0.4),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : [],
                          ),
                        );
                      }),
                    ),
                  ),

                  // Numerical Keypad
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildKeyPadButton('1'),
                          _buildKeyPadButton('2'),
                          _buildKeyPadButton('3'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildKeyPadButton('4'),
                          _buildKeyPadButton('5'),
                          _buildKeyPadButton('6'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildKeyPadButton('7'),
                          _buildKeyPadButton('8'),
                          _buildKeyPadButton('9'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Biometric Action or Empty Spacer
                          _canUseBiometrics && _isBiometricEnabled
                              ? IconButton(
                                  iconSize: 32,
                                  icon: Icon(
                                    Icons.fingerprint_rounded,
                                    color: primaryColor,
                                  ),
                                  onPressed: _authenticateBiometrics,
                                )
                              : const SizedBox(width: 72, height: 72),
                          _buildKeyPadButton('0'),
                          IconButton(
                            iconSize: 28,
                            icon: Icon(
                              Icons.backspace_outlined,
                              color: isDark ? AppTheme.textLight : AppTheme.textMedium,
                            ),
                            onPressed: _onBackspace,
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Forgot PIN Link
                      TextButton(
                        onPressed: _handleForgotPin,
                        child: Text(
                          'Forgot PIN?',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Inline Reset Dialog Overlay
            if (_showForgotDialog)
              Positioned.fill(
                child: Container(
                  color: Colors.black54,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(24),
                  child: Material(
                    borderRadius: BorderRadius.circular(20),
                    color: isDark ? AppTheme.bgDarkCard : Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.lock_reset_rounded, size: 48, color: AppTheme.primaryColor),
                          const SizedBox(height: 16),
                          Text(
                            'Reset App PIN?',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'To reset your PIN, you will be signed out and need to log back in with your account credentials.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: isDark ? AppTheme.textLight : AppTheme.textMedium),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    setState(() {
                                      _showForgotDialog = false;
                                    });
                                  },
                                  child: const Text('Cancel'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () async {
                                    final authProvider = context.read<AuthProvider>();
                                    await _securityService.clearSecuritySettings();
                                    await authProvider.logout();
                                    widget.onUnlocked();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.statusError,
                                  ),
                                  child: const Text('Sign Out'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyPadButton(String digit) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onKeyPress(digit),
        borderRadius: BorderRadius.circular(36),
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark ? AppTheme.bgDarkCard : Colors.white,
            boxShadow: isDark ? [] : AppTheme.softShadow,
            border: Border.all(
              color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.05),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            digit,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppTheme.textDark,
            ),
          ),
        ),
      ),
    );
  }
}
