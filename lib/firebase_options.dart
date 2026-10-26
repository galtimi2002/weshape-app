// Firebase settings of the "weshape-energy" project (console.firebase.google.com).
//
// These values are public by design: every web page that uses Firebase ships
// them to the browser. Access is controlled by Firebase Authentication and the
// project's authorised domains, not by keeping this file secret.
//
// Only the web app is registered so far. To add Android or iOS, register the
// app in the Firebase console and run `flutterfire configure`, which rewrites
// this file with every platform.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    throw UnsupportedError(
      'Firebase is only set up for the web so far. Register the Android/iOS app '
      'in the Firebase console and run `flutterfire configure`, or run with '
      '--dart-define=AUTH_MODE=demo.',
    );
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyD2Qye48NnpbU5u885cfYWvk0aQQF-DPJ8',
    appId: '1:1059747265341:web:67f905cd147f583127a354',
    messagingSenderId: '1059747265341',
    projectId: 'weshape-energy',
    // Our own domain: Render forwards /__/auth/* to Firebase (see render.yaml),
    // so the Google sign-in window names weshapeenergy.com.
    authDomain: 'weshapeenergy.com',
    storageBucket: 'weshape-energy.firebasestorage.app',
  );
}
