import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/security_service.dart';
import '../services/auth_provider.dart';
import '../screens/pin_lock_screen.dart';

class AppSecurityWrapper extends StatefulWidget {
  final Widget child;

  const AppSecurityWrapper({
    super.key,
    required this.child,
  });

  @override
  State<AppSecurityWrapper> createState() => _AppSecurityWrapperState();
}

class _AppSecurityWrapperState extends State<AppSecurityWrapper>
    with WidgetsBindingObserver {
  final SecurityService _securityService = SecurityService();
  bool _isLocked = false;
  DateTime? _pausedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (SecurityService.isAuthenticatingBiometrics) return;

    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _pausedAt ??= DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      _checkLockStatusOnResume();
    }
  }

  Future<void> _checkLockStatusOnResume() async {
    if (SecurityService.isAuthenticatingBiometrics) return;

    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isLoggedIn) {
      if (mounted) {
        setState(() {
          _isLocked = false;
        });
      }
      _pausedAt = null;
      return;
    }

    final isPinEnabled = await _securityService.isPinEnabled();
    if (!isPinEnabled) {
      _pausedAt = null;
      return;
    }

    final timeoutSeconds = await _securityService.getAutoLockTimeout();

    if (_pausedAt != null && timeoutSeconds > 0) {
      final elapsed = DateTime.now().difference(_pausedAt!).inSeconds;
      if (elapsed < timeoutSeconds) {
        // Returned within grace period -> do not lock
        _pausedAt = null;
        return;
      }
    }

    _pausedAt = null;

    if (mounted) {
      setState(() {
        _isLocked = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      textDirection: TextDirection.ltr,
      children: [
        widget.child,
        if (_isLocked)
          Positioned.fill(
            child: Material(
              type: MaterialType.transparency,
              child: PinLockScreen(
                onUnlocked: () {
                  setState(() {
                    _isLocked = false;
                  });
                },
              ),
            ),
          ),
      ],
    );
  }
}
