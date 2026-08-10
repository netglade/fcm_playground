import 'package:fcm_app/firebase_options.dart';
import 'package:fcm_app/firebase_setup.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the platform options point at the project in firebase_setup.dart', () {
    // Guards against `firebase_options.dart` and `firebaseProjectId` drifting
    // apart — either after a hand edit or after `flutterfire configure` is run
    // against the wrong project.
    //
    // Deliberately does not assert anything about apiKey: this must keep passing
    // once the real credentials are generated.
    expect(DefaultFirebaseOptions.currentPlatform.projectId, firebaseProjectId);
  });
}
