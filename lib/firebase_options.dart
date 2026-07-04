// ============================================================
// FIREBASE OPTIONS
// ============================================================
// Yeh file aapko FlutterFire CLI se generate karni hogi:
//
//   Step 1: Firebase CLI install karo
//     npm install -g firebase-tools
//
//   Step 2: FlutterFire CLI install karo
//     dart pub global activate flutterfire_cli
//
//   Step 3: Configure karo (project root mein)
//     flutterfire configure --project=kaam-dhanda-app
//
//   Yeh command automatically yeh file generate karega
//   aur android/app/google-services.json bhi add karega.
//
// YA manually karo:
//   Firebase Console → Project Settings → Your Apps
//   → Add Android App → package: com.kamdhanda.app
//   → Download google-services.json → android/app/ mein rakho
// ============================================================

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

  // ⚠️  REPLACE THESE VALUES with your actual Firebase config
  // Firebase Console → Project Settings → General → Your Apps

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'YOUR_ANDROID_API_KEY',           // replace karo
    appId: '1:YOUR_APP_ID:android:XXXXX',     // replace karo
    messagingSenderId: 'YOUR_SENDER_ID',       // replace karo
    projectId: 'kaam-dhanda-app',
    storageBucket: 'kaam-dhanda-app.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_IOS_API_KEY',
    appId: '1:YOUR_APP_ID:ios:XXXXX',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'kaam-dhanda-app',
    storageBucket: 'kaam-dhanda-app.appspot.com',
    iosBundleId: 'com.kamdhanda.app',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'YOUR_WEB_API_KEY',
    appId: '1:YOUR_APP_ID:web:XXXXX',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'kaam-dhanda-app',
    storageBucket: 'kaam-dhanda-app.appspot.com',
    authDomain: 'kaam-dhanda-app.firebaseapp.com',
  );
}
