import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isPersistentLoggedIn = false;

  User? get user => _user ?? FirebaseAuth.instance.currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn =>
      _user != null ||
      FirebaseAuth.instance.currentUser != null ||
      _isPersistentLoggedIn;

  AuthProvider() {
    _listenToAuthState();
    _checkPrefsLogin();
    _debugFirebaseStatus();
  }

  void _debugFirebaseStatus() {
    try {
      final auth = FirebaseAuth.instance;
      debugPrint('🔍 Firebase Auth Status:');
      debugPrint('   Current User: ${auth.currentUser}');
      debugPrint('   App Configured: ✅');
    } catch (e) {
      debugPrint('🔍 Firebase Auth Status: ❌ Error - $e');
    }
  }

  Future<void> _checkPrefsLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isPersistentLoggedIn = prefs.getBool('is_user_logged_in') ?? false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error checking prefs login: $e');
    }
  }

  void _listenToAuthState() {
    AuthService.authStateStream.listen((user) async {
      _user = user;
      if (user != null) {
        _isPersistentLoggedIn = true;
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('is_user_logged_in', true);
        } catch (e) {
          debugPrint('Error saving login state: $e');
        }
      }
      notifyListeners();
    });
  }

  Future<bool> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await AuthService.registerWithEmail(
        email: email,
        password: password,
        displayName: displayName,
      );

      await AuthService.sendEmailVerification();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_user_logged_in', true);
      _isPersistentLoggedIn = true;

      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _getErrorMessage(e.code);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Error: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await AuthService.loginWithEmail(
        email: email,
        password: password,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_user_logged_in', true);
      _isPersistentLoggedIn = true;

      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _getErrorMessage(e.code);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Error: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> sendPasswordReset(String email) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await AuthService.sendPasswordResetEmail(email);

      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _getErrorMessage(e.code);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Error: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    try {
      _isLoading = true;
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_user_logged_in', false);
      _isPersistentLoggedIn = false;

      await AuthService.logout();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Logout failed: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  String _getErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many login attempts. Please try later.';
      case 'network-request-failed':
        return 'Network error. Check your internet connection.';
      case 'operation-not-allowed':
        return 'Email/Password auth is not enabled. Contact admin.';
      default:
        return 'Authentication failed. Error: $errorCode';
    }
  }
}
