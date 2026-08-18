import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'support/app_harness.dart';

void main() {
  patrolTest('the app launches, grants notifications, and registers a token', (
    $,
  ) async {
    await launchApp($);

    // The token is the one precondition every scenario shares, so proving the
    // harness reaches it is proving the suite can start at all.
    expect($('Registration token').exists, isTrue);
  });
}
