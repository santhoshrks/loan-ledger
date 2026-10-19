import 'package:flutter/material.dart';
import '../services/security_service.dart';
import '../services/haptic_service.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import 'p2p_home_screen.dart';

class PinSetupScreen extends StatefulWidget {
  final NotificationService? notificationService;
  final VoidCallback? onComplete;

  const PinSetupScreen({
    super.key,
    this.notificationService,
    this.onComplete,
  });

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  final SecurityService _securityService = SecurityService();

  String _firstPin = '';
  String _confirmPin = '';
  bool _isConfirmingStep = false;
  bool _isError = false;
  String _errorMessage = '';
  bool _canUseBiometrics = false;
  bool _enableBiometrics = true;

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
  }

  Future<void> _checkBiometricAvailability() async {
    final available = await _securityService.isBiometricsAvailable();
    if (mounted) {
      setState(() {
        _canUseBiometrics = available;
      });
    }
  }

  void _onDigitPressed(String digit) {
    if (_isConfirmingStep) {
      if (_confirmPin.length >= 4) return;
      HapticService.selection();
      setState(() {
        _isError = false;
        _confirmPin += digit;
      });

      if (_confirmPin.length == 4) {
        _processPinCompletion();
      }
    } else {
      if (_firstPin.length >= 4) return;
      HapticService.selection();
      setState(() {
        _isError = false;
        _firstPin += digit;
      });

      if (_firstPin.length == 4) {
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) {
            setState(() {
              _isConfirmingStep = true;
            });
          }
        });
      }
    }
  }

  void _onBackspacePressed() {
    HapticService.selection();
    setState(() {
      _isError = false;
      if (_isConfirmingStep) {
        if (_confirmPin.isNotEmpty) {
          _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
        }
      } else {
        if (_firstPin.isNotEmpty) {
          _firstPin = _firstPin.substring(0, _firstPin.length - 1);
        }
      }
    });
  }

  Future<void> _processPinCompletion() async {
    if (_firstPin != _confirmPin) {
      HapticService.error();
      setState(() {
        _isError = true;
        _errorMessage = 'PINs do not match. Please try again.';
        _confirmPin = '';
      });
      return;
    }

    // Save PIN
    await _securityService.setPin(_confirmPin);

    // Save Biometrics preference
    if (_canUseBiometrics) {
      await _securityService.setBiometricEnabled(_enableBiometrics);
    }

    if (!mounted) return;

    HapticService.light();

    if (widget.onComplete != null) {
      widget.onComplete!();
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => P2PHomeScreen(
            notificationService: widget.notificationService,
          ),
        ),
      );
    }
  }

  void _handleSkip() async {
    await _securityService.setFirstLoginCompleted(true);
    if (!mounted) return;

    if (widget.onComplete != null) {
      widget.onComplete!();
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => P2PHomeScreen(
            notificationService: widget.notificationService,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    final currentPin = _isConfirmingStep ? _confirmPin : _firstPin;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.bgDark : AppTheme.bgLight,
      appBar: AppBar(
        title: const Text('Security Setup'),
        actions: [
          TextButton(
            onPressed: _handleSkip,
            child: const Text('Skip'),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Title Header
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
                    child: Icon(
                      _isConfirmingStep ? Icons.lock_clock_rounded : Icons.security_rounded,
                      size: 38,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _isConfirmingStep ? 'Confirm Your 4-Digit PIN' : 'Set Up App PIN Lock',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isError
                        ? _errorMessage
                        : (_isConfirmingStep
                            ? 'Re-enter your PIN to confirm'
                            : 'Secure LoanLedger with a quick 4-digit PIN'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: _isError
                          ? AppTheme.statusError
                          : (isDark ? AppTheme.textLight : AppTheme.textMedium),
                    ),
                  ),
                ],
              ),

              // PIN Indicator Dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  final isFilled = index < currentPin.length;
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
                              : (isDark ? Colors.white24 : Colors.grey[300])),
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

              // Biometric Checkbox if available
              if (_canUseBiometrics && _isConfirmingStep)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.bgDarkCard : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.05),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.fingerprint_rounded, color: primaryColor),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Enable Fingerprint / Face Unlock',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white : AppTheme.textDark,
                          ),
                        ),
                      ),
                      Switch(
                        value: _enableBiometrics,
                        activeTrackColor: primaryColor,
                        onChanged: (val) {
                          setState(() {
                            _enableBiometrics = val;
                          });
                        },
                      ),
                    ],
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
                      const SizedBox(width: 72, height: 72),
                      _buildKeyPadButton('0'),
                      IconButton(
                        iconSize: 28,
                        icon: Icon(
                          Icons.backspace_outlined,
                          color: isDark ? AppTheme.textLight : AppTheme.textMedium,
                        ),
                        onPressed: _onBackspacePressed,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeyPadButton(String digit) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onDigitPressed(digit),
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
