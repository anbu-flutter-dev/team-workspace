// PLACEHOLDER — replace by running `flutterfire configure` (see README).
// This file is gitignored; the real one is generated per-Firebase-project.
import 'package:firebase_core/firebase_core.dart';
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
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for this platform — run flutterfire configure.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: '',
    appId: '',
    messagingSenderId: '',
    projectId: '',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBh03d_HvA9UV8YqrGZfn9oJYZhr46Sumk',
    appId: '1:397344556239:android:ef3a9964d74f00a99b23ba',
    messagingSenderId: '397344556239',
    projectId: 'team-3362b',
    storageBucket: 'team-3362b.firebasestorage.app',
  );
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCY9xaY3gxSC1IgV2h9a--pFJ6myKo0ohI',
    appId: '1:397344556239:ios:3d2620c0b7c10ed79b23ba',
    messagingSenderId: '397344556239',
    projectId: 'team-3362b',
    storageBucket: 'team-3362b.firebasestorage.app',
    iosBundleId: 'com.teamworkspace.teamWorkspace',
  );
}
