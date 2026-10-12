import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb;

/// Manual Firebase options for LoanLedger.
/// Generated from the current `android/app/google-services.json` values.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Firebase options are not configured for web yet.');
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBNdrhFIO9mGsDxCC14wW6IQAgvZOexj9M',
    appId: '1:1079818272807:android:9a0463c87ec52a4e7c8e02',
    messagingSenderId: '1079818272807',
    projectId: 'loanledger-2f360',
    storageBucket: 'loanledger-2f360.firebasestorage.app',
  );
}

