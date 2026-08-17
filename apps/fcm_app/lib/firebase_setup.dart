/// The Firebase project this app talks to.
///
/// Also recorded in `.firebaserc` at the repo root, which is what the `firebase`
/// CLI reads.
const firebaseProjectId = 'fcm-sandbox-770fa';

/// Marker for the placeholder credentials still in `firebase_options.dart`. The
/// project id is real, so the API key carries the sentinel instead.
///
/// It lives here rather than in the generated file so that overwriting that file
/// with real `flutterfire configure` output does not delete the check.
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
