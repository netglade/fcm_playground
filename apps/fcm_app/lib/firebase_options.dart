// PLACEHOLDER — this file mirrors the shape of `flutterfire configure` output
// so that regenerating it is a straight overwrite. Every value below is fake;
// see firebase_setup.dart.
//
// DCM's file-name rule is waived because the real generated file uses this
// exact name and class name.
// ignore_for_file: prefer-match-file-name

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

import 'firebase_setup.dart';

/// Per-platform Firebase configuration.
class DefaultFirebaseOptions {
  const DefaultFirebaseOptions._();

  static FirebaseOptions get currentPlatform => switch (defaultTargetPlatform) {
    _ when kIsWeb => web,
    TargetPlatform.android => android,
    TargetPlatform.iOS => ios,
    _ => throw UnsupportedError(
      'DefaultFirebaseOptions are not configured for $defaultTargetPlatform.',
    ),
  };

  static const android = FirebaseOptions(
    apiKey: 'AIzaSyPLACEHOLDER-android-key',
    appId: '1:000000000000:android:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: unconfiguredProjectId,
  );

  static const ios = FirebaseOptions(
    apiKey: 'AIzaSyPLACEHOLDER-ios-key',
    appId: '1:000000000000:ios:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: unconfiguredProjectId,
    iosBundleId: 'cz.netglade.fcmApp',
  );

  static const web = FirebaseOptions(
    apiKey: 'AIzaSyPLACEHOLDER-web-key',
    appId: '1:000000000000:web:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: unconfiguredProjectId,
    authDomain: '$unconfiguredProjectId.firebaseapp.com',
  );
}
