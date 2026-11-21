
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Firebase is not configured for web.');
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'Firebase is configured only for Android and iOS.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAYd_WxxFrZhc05-TI2kfFTMFoPVUiScjw',
    appId: '1:154148078475:android:34b6269e5e141436d2658e',
    messagingSenderId: '154148078475',
    projectId: 'se7ety-55d05',
    storageBucket: 'se7ety-55d05.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCfu6TF8a--Vkw5_o36yKDVuRvq-opu2sY',
    appId: '1:154148078475:ios:ae099cbf66414a33d2658e',
    messagingSenderId: '154148078475',
    projectId: 'se7ety-55d05',
    storageBucket: 'se7ety-55d05.firebasestorage.app',
    iosBundleId: 'com.se7ety.app',
  );
}
