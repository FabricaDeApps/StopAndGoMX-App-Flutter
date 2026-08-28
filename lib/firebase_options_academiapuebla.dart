// Firebase configuration for the academiapuebla flavor.
// Values are sourced from the Firebase SDK configuration files downloaded for
// app.stopandgomx.academiapuebla.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions are not configured for web.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return ios;
      case TargetPlatform.windows:
        return android;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for Linux.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC_x2qNKjZl86Gu8Oii9_hgrf3G0fDpQoE',
    appId: '1:225171602574:android:f9285ba3cd6b7855cd9ddf',
    messagingSenderId: '225171602574',
    projectId: 'stopandgomx-4ab82',
    storageBucket: 'stopandgomx-4ab82.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDvoRZQPTIGubF45nOm9canlnl5VGy7VyY',
    appId: '1:225171602574:ios:c905c1b81c8a7637cd9ddf',
    messagingSenderId: '225171602574',
    projectId: 'stopandgomx-4ab82',
    storageBucket: 'stopandgomx-4ab82.firebasestorage.app',
    androidClientId:
        '225171602574-4r4a00qo56gaarc9drefl7lkge51brfa.apps.googleusercontent.com',
    iosClientId:
        '225171602574-8gt1eabhfo5jbbqkbjlqjfnu2an5otvp.apps.googleusercontent.com',
    iosBundleId: 'app.stopandgomx.academiapuebla',
  );
}
