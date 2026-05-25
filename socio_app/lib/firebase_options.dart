import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase app.
/// Generated with mock values to allow compiling and running local development.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'mock-api-key-socio-web',
    appId: '1:1234567890:web:mockappid',
    messagingSenderId: '1234567890',
    projectId: 'socio-ai-mock',
    authDomain: 'socio-ai-mock.firebaseapp.com',
    storageBucket: 'socio-ai-mock.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'mock-api-key-socio-android',
    appId: '1:1234567890:android:mockappid',
    messagingSenderId: '1234567890',
    projectId: 'socio-ai-mock',
    storageBucket: 'socio-ai-mock.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'mock-api-key-socio-ios',
    appId: '1:1234567890:ios:mockappid',
    messagingSenderId: '1234567890',
    projectId: 'socio-ai-mock',
    storageBucket: 'socio-ai-mock.appspot.com',
    iosBundleId: 'com.doppelganger.socio',
  );
}
