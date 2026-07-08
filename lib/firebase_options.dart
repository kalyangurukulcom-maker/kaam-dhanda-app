// firebase_options.dart — placeholder (replace with real flutterfire configure output)
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return android;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX',
    authDomain: 'kaam-dhanda-app.firebaseapp.com',
    projectId: 'kaam-dhanda-app',
    storageBucket: 'kaam-dhanda-app.appspot.com',
    messagingSenderId: '000000000000',
    appId: '1:000000000000:web:abcdef1234567890',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX',
    authDomain: 'kaam-dhanda-app.firebaseapp.com',
    projectId: 'kaam-dhanda-app',
    storageBucket: 'kaam-dhanda-app.appspot.com',
    messagingSenderId: '000000000000',
    appId: '1:000000000000:android:abcdef1234567890abcdef',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX',
    authDomain: 'kaam-dhanda-app.firebaseapp.com',
    projectId: 'kaam-dhanda-app',
    storageBucket: 'kaam-dhanda-app.appspot.com',
    messagingSenderId: '000000000000',
    appId: '1:000000000000:ios:abcdef1234567890abcdef',
    iosBundleId: 'com.kamdhanda.app',
  );
}
