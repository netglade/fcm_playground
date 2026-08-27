import 'package:fcm_app/firebase_options.dart';
import 'package:fcm_app/firebase_setup.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a fresh checkout still ships the sentinel API key', () {
    // This public sample ships `firebase_options.dart` with placeholder
    // credentials, not a real project's, so there is nothing left to guard by
    // comparing its `projectId` against `firebaseProjectId` — they are meant to
    // differ until someone runs `flutterfire configure`. What still matters is
    // the actual invariant `service_locator.dart` relies on to reach the
    // "no push source" banner: the generated file's `apiKey` is the sentinel.
    // `service_locator_test.dart` exercises that gate with a hand-rolled
    // `FirebaseOptions`; this test checks the checked-in file itself has not
    // drifted back toward real values.
    expect(DefaultFirebaseOptions.currentPlatform.apiKey, unconfiguredApiKey);
  });
}
