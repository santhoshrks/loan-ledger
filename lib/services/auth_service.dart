import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  static final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  /// Initialize Firebase
  static Future<void> initializeFirebase() async {
    try {
      await Firebase.initializeApp();
      debugPrint('✅ Firebase initialized successfully');
    } catch (e) {
      debugPrint('❌ Firebase initialization error: $e');
    }
  }

  /// Get current user
  static User? get currentUser => _firebaseAuth.currentUser;

  /// Check if user is logged in
  static bool get isUserLoggedIn => _firebaseAuth.currentUser != null;

  /// Get user ID token for backend
  static Future<String?> getIdToken() async {
    try {
      return await _firebaseAuth.currentUser?.getIdToken();
    } catch (e) {
      debugPrint('❌ Error getting ID token: $e');
      return null;
    }
  }

  /// Register with email and password
  static Future<UserCredential> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name
      await userCredential.user?.updateDisplayName(displayName);
      await userCredential.user?.reload();

      debugPrint('✅ User registered successfully: ${userCredential.user?.email}');
      return userCredential;
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Registration error: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  /// Login with email and password
  static Future<UserCredential> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      debugPrint('✅ User logged in: ${userCredential.user?.email}');
      return userCredential;
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Login error: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  /// Send verification email
  static Future<void> sendEmailVerification() async {
    try {
      await _firebaseAuth.currentUser?.sendEmailVerification();
      debugPrint('✅ Verification email sent');
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Error sending verification email: ${e.message}');
      rethrow;
    }
  }

  /// Check if email is verified
  static bool get isEmailVerified => _firebaseAuth.currentUser?.emailVerified ?? false;

  /// Send password reset email
  static Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      debugPrint('✅ Password reset email sent to: $email');
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Error sending password reset: ${e.message}');
      rethrow;
    }
  }

  /// Verify phone number and sign in
  static Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String verificationId, int? resendToken) onCodeSent,
    required Function(FirebaseAuthException error) onVerificationFailed,
    required Function(PhoneAuthCredential credential) onVerificationCompleted,
  }) async {
    try {
      await _firebaseAuth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: onVerificationCompleted,
        verificationFailed: onVerificationFailed,
        codeSent: (verificationId, resendToken) {
          debugPrint('✅ Verification code sent to: $phoneNumber');
          onCodeSent(verificationId, resendToken);
        },
        codeAutoRetrievalTimeout: (_) {},
      );
    } catch (e) {
      debugPrint('❌ Phone verification error: $e');
      rethrow;
    }
  }

  /// Sign in with phone credential
  static Future<UserCredential> signInWithPhoneCredential({
    required PhoneAuthCredential credential,
  }) async {
    try {
      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      debugPrint('✅ User signed in with phone: ${userCredential.user?.phoneNumber}');
      return userCredential;
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Phone sign-in error: ${e.message}');
      rethrow;
    }
  }

  /// Link phone credential to existing user
  static Future<UserCredential> linkPhoneCredential({
    required PhoneAuthCredential credential,
  }) async {
    try {
      final userCredential = await _firebaseAuth.currentUser!.linkWithCredential(credential);
      debugPrint('✅ Phone number linked to user');
      return userCredential;
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Phone linking error: ${e.message}');
      rethrow;
    }
  }

  /// Update user profile
  static Future<void> updateUserProfile({
    String? displayName,
    String? photoUrl,
  }) async {
    try {
      if (displayName != null) {
        await _firebaseAuth.currentUser?.updateDisplayName(displayName);
      }
      if (photoUrl != null) {
        await _firebaseAuth.currentUser?.updatePhotoURL(photoUrl);
      }
      await _firebaseAuth.currentUser?.reload();
      debugPrint('✅ User profile updated');
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Error updating profile: ${e.message}');
      rethrow;
    }
  }

  /// Logout
  static Future<void> logout() async {
    try {
      await _firebaseAuth.signOut();
      debugPrint('✅ User logged out');
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Logout error: ${e.message}');
      rethrow;
    }
  }

  /// Delete user account
  static Future<void> deleteUser() async {
    try {
      await _firebaseAuth.currentUser?.delete();
      debugPrint('✅ User account deleted');
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Error deleting account: ${e.message}');
      rethrow;
    }
  }

  /// Get auth state stream
  static Stream<User?> get authStateStream => _firebaseAuth.authStateChanges();

  /// Re-authenticate with email (for sensitive operations)
  static Future<void> reauthenticateWithEmail(String password) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user?.email != null) {
        final credential = EmailAuthProvider.credential(
          email: user!.email!,
          password: password,
        );
        await user.reauthenticateWithCredential(credential);
        debugPrint('✅ User re-authenticated');
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Re-authentication error: ${e.message}');
      rethrow;
    }
  }
}

