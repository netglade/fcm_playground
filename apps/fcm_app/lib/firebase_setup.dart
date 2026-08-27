/// Placeholder project name, matching `.firebaserc` at the repo root — the
/// `firebase` CLI reads that file for its own default `--project`. Nothing in
/// the running app reads this constant any more (the in-app banner no longer
/// names a project either); it exists only so `.firebaserc`'s value has a
/// Dart-side mirror for `service_locator_test.dart`'s fixture to use.
///
/// `flutterfire configure` does not read or write this or `.firebaserc` — it
/// asks which project interactively — so update both by hand only if you
/// plan to drive the `firebase` CLI directly against your own project.
const firebaseProjectId = 'your-project-id';

/// Marker for the placeholder credentials this public sample ships in
/// `firebase_options.dart`. Every field there — `apiKey`, `appId`,
/// `messagingSenderId`, `projectId` and the rest — is an obvious placeholder
/// rather than a real project's values; this constant is what `apiKey` carries,
/// and the only field `service_locator.dart` actually checks.
///
/// It lives here rather than in the generated file so that overwriting that file
/// with real `flutterfire configure` output does not delete the check.
const unconfiguredApiKey = 'replace-me-with-flutterfire-configure';

/// Shown in-app while the credentials are still placeholders.
const firebaseSetupInstructions =
    'No Firebase project is configured, so no pushes can arrive.\n'
    'Create a Firebase project of your own at console.firebase.google.com, '
    'then install the Firebase CLI and log in:\n'
    '  npm install -g firebase-tools && firebase login\n'
    'Then, from apps/fcm_app:\n'
    '  fvm dart pub global activate flutterfire_cli\n'
    '  fvm exec flutterfire configure\n'
    "That overwrites lib/firebase_options.dart with your project's real "
    'values — see README.md for the full walkthrough.';
