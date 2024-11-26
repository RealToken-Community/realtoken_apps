// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAYPFUnkGEH9SexDiXerWi5aj6EJFW3cBg',
    appId: '1:203512481394:android:aabe1e8dae6522499e64eb',
    messagingSenderId: '203512481394',
    projectId: 'realtoken-88d99',
    storageBucket: 'realtoken-88d99.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDiLmJaBqjgnYX8hbYCmeHNMNq6QfKeH1E',
    appId: '1:203512481394:ios:ab819e364326f6849e64eb',
    messagingSenderId: '203512481394',
    projectId: 'realtoken-88d99',
    storageBucket: 'realtoken-88d99.appspot.com',
    iosBundleId: 'com.example.realtApps',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDiLmJaBqjgnYX8hbYCmeHNMNq6QfKeH1E',
    appId: '1:203512481394:ios:ab819e364326f6849e64eb',
    messagingSenderId: '203512481394',
    projectId: 'realtoken-88d99',
    storageBucket: 'realtoken-88d99.appspot.com',
    iosBundleId: 'com.example.realtApps',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyD4M_W_2kF2IDX4guwq6g5ljselEsfjaeU',
    appId: '1:203512481394:web:9713955de571f7f59e64eb',
    messagingSenderId: '203512481394',
    projectId: 'realtoken-88d99',
    authDomain: 'realtoken-88d99.firebaseapp.com',
    storageBucket: 'realtoken-88d99.appspot.com',
    measurementId: 'G-FFZ5JXX644',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyD4M_W_2kF2IDX4guwq6g5ljselEsfjaeU',
    appId: '1:203512481394:web:acb31113c4397a9c9e64eb',
    messagingSenderId: '203512481394',
    projectId: 'realtoken-88d99',
    authDomain: 'realtoken-88d99.firebaseapp.com',
    storageBucket: 'realtoken-88d99.appspot.com',
    measurementId: 'G-5JHBXTPHV3',
  );
}