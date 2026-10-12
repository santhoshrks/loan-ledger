import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_service.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _errorMessage;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _user != null;

  AuthProvider() {
    _listenToAuthState();
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

  void _listenToAuthState() {
    AuthService.authStateStream.listen((user) {
      _user = user;
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

      debugPrint('📝 Registration Step 1: Validating inputs');
      debugPrint('   Email: $email, Name: $displayName');

      debugPrint('📝 Registration Step 2: Calling AuthService.registerWithEmail');
      await AuthService.registerWithEmail(
        email: email,
        password: password,
        displayName: displayName,
      );

      debugPrint('📝 Registration Step 3: Sending verification email');
      await AuthService.sendEmailVerification();

      debugPrint('✅ Registration completed successfully');
      _isLoading = false;
      notifyListeners();
      return true;

    } on FirebaseAuthException catch (e) {
      debugPrint('❌ FirebaseAuthException: Code=${e.code}, Message=${e.message}');
      _errorMessage = _getErrorMessage(e.code);
      _isLoading = false;
      notifyListeners();
      return false;

    } catch (e) {
      debugPrint('❌ Unexpected Exception: Type=${e.runtimeType}, Message=$e');
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








