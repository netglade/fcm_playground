import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

void main() {
  patrolTest('the Patrol runner reaches a Dart test', ($) async {
    // Asserts nothing about the app on purpose. Its whole job is to prove the
    // instrumentation, the Dart test bundle and patrol_cli agree with each other —
    // a failure here is a wiring failure, and folding an app assertion in would
    // make that ambiguous.
    expect(1, 1);
  });
}
