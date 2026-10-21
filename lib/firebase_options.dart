// Placeholder. Replace it by running, in this folder:
//
//   dart pub global activate flutterfire_cli
//   flutterfire configure --project=<your-firebase-project-id>
//
// That overwrites this file with the real keys. Until then the app runs in
// demo mode (the default), which never reads this file.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform => throw UnsupportedError(
        'Firebase is not configured yet. Run `flutterfire configure`, or build '
        'without --dart-define=AUTH_MODE=firebase to use demo mode.',
      );
}
