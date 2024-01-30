// File generated by FlutterFire CLI.
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kDebugMode, kIsWeb;

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
      if (kDebugMode) {
        return webDebug;
      } else {
        return web;
      }
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyC_KA6vsQgeITS7RHC4cZ2HGq38tH01Ldw',
    appId: '1:1072675133464:web:028c4265fd0cb512d40b6d',
    messagingSenderId: '1072675133464',
    projectId: 'fluttersolarsystem',
    authDomain: 'fluttersolarsystem.firebaseapp.com',
    storageBucket: 'fluttersolarsystem.appspot.com',
    databaseURL: 'https://fluttersolarsystem-default-rtdb.europe-west1.firebasedatabase.app'
  );

  static const FirebaseOptions webDebug = FirebaseOptions(
      apiKey: 'AIzaSyC_KA6vsQgeITS7RHC4cZ2HGq38tH01Ldw',
      appId: '1:1072675133464:web:028c4265fd0cb512d40b6d',
      messagingSenderId: '1072675133464',
      projectId: 'fluttersolarsystem',
      authDomain: 'fluttersolarsystem.firebaseapp.com',
      storageBucket: 'fluttersolarsystem.appspot.com',
      databaseURL: 'http://127.0.0.1:9000'
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAvCIz3K1n-cycFzQeyniIsKuUwvlWcZ0Y',
    appId: '1:1072675133464:android:303a2427614e3f3ad40b6d',
    messagingSenderId: '1072675133464',
    projectId: 'fluttersolarsystem',
    storageBucket: 'fluttersolarsystem.appspot.com',
    databaseURL: 'https://fluttersolarsystem-default-rtdb.europe-west1.firebasedatabase.app'
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyD95d88pr93KPsWn8rkAac31pqs4iWtsPI',
    appId: '1:1072675133464:ios:aae2c99686ad2e8dd40b6d',
    messagingSenderId: '1072675133464',
    projectId: 'fluttersolarsystem',
    storageBucket: 'fluttersolarsystem.appspot.com',
    iosBundleId: 'com.dmilicic.solarsystem.solarSystem',
    databaseURL: 'https://fluttersolarsystem-default-rtdb.europe-west1.firebasedatabase.app'
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyD95d88pr93KPsWn8rkAac31pqs4iWtsPI',
    appId: '1:1072675133464:ios:9e9abaaceb7b4048d40b6d',
    messagingSenderId: '1072675133464',
    projectId: 'fluttersolarsystem',
    storageBucket: 'fluttersolarsystem.appspot.com',
    iosBundleId: 'com.dmilicic.solarsystem.solarSystem.RunnerTests',
    databaseURL: 'https://fluttersolarsystem-default-rtdb.europe-west1.firebasedatabase.app'
  );
}
