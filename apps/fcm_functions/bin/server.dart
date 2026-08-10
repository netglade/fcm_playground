import 'package:fcm_functions/register_functions.dart';
import 'package:firebase_functions/firebase_functions.dart';

/// The path `firebase deploy` compiles and the container runs.
///
/// `bin/server.dart` is not configurable: the Firebase CLI looks for exactly
/// this file. Keep it a single call so everything worth reading lives in `lib/`.
Future<void> main() async {
  await runFunctions(registerFunctions);
}
