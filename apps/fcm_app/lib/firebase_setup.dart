/// The Firebase project this app talks to.
///
/// Also recorded in `.firebaserc` at the repo root, which is what the `firebase`
/// CLI reads.
const firebaseProjectId = 'fcm-sandbox-770fa';

/// Marker for the placeholder credentials still present in
/// `firebase_options.dart`.
///
/// The project id is real, so it cannot be used to detect an unconfigured
/// checkout. The API key is the value that must come from Firebase itself, so it
/// carries the sentinel instead.
///
/// This lives here rather than in `firebase_options.dart` so that overwriting
/// that file with real `flutterfire configure` output does not delete the check
/// — once the generated file carries a real key, the comparison in `main.dart`
/// simply stops matching.
const unconfiguredApiKey = 'replace-me-with-flutterfire-configure';

/// Shown in-app while the credentials are still placeholders.
const firebaseSetupInstructions =
    'Firebase project "$firebaseProjectId" is set, but the API key, app id and '
    'sender id are still placeholders, so no pushes can arrive.\n'
    'Install the Firebase CLI and log in:\n'
    '  npm install -g firebase-tools && firebase login\n'
    'Then, from apps/fcm_app:\n'
    '  fvm dart pub global activate flutterfire_cli\n'
    '  fvm exec flutterfire configure --project=$firebaseProjectId\n'
    'That overwrites lib/firebase_options.dart with the real values.';
