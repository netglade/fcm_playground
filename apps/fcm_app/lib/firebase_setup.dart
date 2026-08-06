/// Marker written into the placeholder `firebase_options.dart` shipped with
/// this sample.
///
/// It lives here rather than in `firebase_options.dart` so that overwriting
/// that file with real `flutterfire configure` output does not delete the
/// check — once the generated file carries a real project id, the comparison in
/// `main.dart` simply stops matching.
const unconfiguredProjectId = 'replace-me-with-flutterfire-configure';

/// Shown in-app when Firebase has not been configured yet.
const firebaseSetupInstructions =
    'Firebase is not configured for this checkout, so no pushes can arrive.\n'
    'From apps/fcm_app run:\n'
    '  fvm dart pub global activate flutterfire_cli\n'
    '  fvm exec flutterfire configure\n'
    'That overwrites lib/firebase_options.dart with your project values.';
