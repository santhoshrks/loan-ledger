import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecurityService {
  static const String _keyPin = 'app_security_pin';
  static const String _keyPinEnabled = 'app_security_pin_enabled';
  static const String _keyBiometricEnabled = 'app_security_biometric_enabled';
  static const String _keyHasCompletedFirstLogin = 'app_security_first_login_done';
  static const String _keyAutoLockTimeout = 'app_security_autolock_timeout';

  static bool isAuthenticatingBiometrics = false;

  final LocalAuthentication _localAuth = LocalAuthentication();

  /// Check if device supports biometrics (Fingerprint / Face ID)
  Future<bool> isBiometricsAvailable() async {
    try {
      final canAuthenticateWithBiometrics = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return canAuthenticateWithBiometrics && isDeviceSupported;
    } on PlatformException catch (e) {
      debugPrint('🔑 Biometrics check error: $e');
      return false;
    } catch (e) {
      debugPrint('🔑 Biometrics check exception: $e');
      return false;
    }
  }

  /// Get list of available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      debugPrint('🔑 Error getting biometrics: $e');
      return [];
    }
  }

  /// Trigger Biometric (Fingerprint/Face) Authentication
  Future<bool> authenticateWithBiometrics({
    String reason = 'Authenticate to access LoanLedger',
  }) async {
    try {
      final available = await isBiometricsAvailable();
      if (!available) return false;

      isAuthenticatingBiometrics = true;

      final result = await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
          useErrorDialogs: true,
        ),
      );

      return result;
    } on PlatformException catch (e) {
      debugPrint('🔑 Biometric auth failed: $e');
      return false;
    } catch (e) {
      debugPrint('🔑 Biometric auth exception: $e');
      return false;
    } finally {
      // Delay resetting flag slightly so app resume event passes
      Future.delayed(const Duration(milliseconds: 1000), () {
        isAuthenticatingBiometrics = false;
      });
    }
  }

  /// Get Auto-Lock Timeout in seconds (60 = 1 min default, 300 = 5 min, 0 = Immediately)
  Future<int> getAutoLockTimeout() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyAutoLockTimeout) ?? 60;
  }

  /// Set Auto-Lock Timeout in seconds
  Future<void> setAutoLockTimeout(int seconds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyAutoLockTimeout, seconds);
  }

  /// Check if a PIN is stored
  Future<bool> isPinSet() async {
    final prefs = await SharedPreferences.getInstance();
    final pin = prefs.getString(_keyPin);
    return pin != null && pin.length >= 4;
  }

  /// Check if PIN lock is enabled
  Future<bool> isPinEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    final pinSet = await isPinSet();
    if (!pinSet) return false;
    return prefs.getBool(_keyPinEnabled) ?? true;
  }

  /// Set PIN lock state
  Future<void> setPinEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyPinEnabled, enabled);
  }

  /// Check if Biometric lock is enabled
  Future<bool> isBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyBiometricEnabled) ?? false;
  }

  /// Set Biometric lock state
  Future<void> setBiometricEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyBiometricEnabled, enabled);
  }

  /// Check if user completed 1st time login flow
  Future<bool> hasCompletedFirstLogin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyHasCompletedFirstLogin) ?? false;
  }

  /// Mark 1st time login as completed
  Future<void> setFirstLoginCompleted(bool completed) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyHasCompletedFirstLogin, completed);
  }

  /// Save new PIN
  Future<bool> setPin(String pin) async {
    if (pin.length < 4) return false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPin, pin);
    await prefs.setBool(_keyPinEnabled, true);
    await prefs.setBool(_keyHasCompletedFirstLogin, true);
    return true;
  }

  /// Verify entered PIN against stored PIN
  Future<bool> verifyPin(String enteredPin) async {
    final prefs = await SharedPreferences.getInstance();
    final storedPin = prefs.getString(_keyPin);
    return storedPin == enteredPin;
  }

  /// Clear PIN and security settings
  Future<void> clearSecuritySettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyPin);
    await prefs.remove(_keyPinEnabled);
    await prefs.remove(_keyBiometricEnabled);
    await prefs.remove(_keyHasCompletedFirstLogin);
    await prefs.remove(_keyAutoLockTimeout);
  }
}
