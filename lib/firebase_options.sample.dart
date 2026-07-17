// Template for lib/firebase_options.dart, which is gitignored since it's
// per-Firebase-project. CI copies this file verbatim so analyze/test/build
// have something to import; replace it locally with the real file generated
// by `flutterfire configure` (see README).
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
    apiKey: 'placeholder',
    appId: 'placeholder',
    messagingSenderId: 'placeholder',
    projectId: 'placeholder',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'placeholder',
    appId: 'placeholder',
    messagingSenderId: 'placeholder',
    projectId: 'placeholder',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'placeholder',
    appId: 'placeholder',
    messagingSenderId: 'placeholder',
    projectId: 'placeholder',
    iosBundleId: 'com.teamworkspace.teamWorkspace',
  );
}
