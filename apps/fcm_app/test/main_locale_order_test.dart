import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards the one thing that made the UI isolate register channels in English
/// forever on a fresh install: `restoreIsolateLocale()` running after
/// `configureDependencies()` rather than before it.
///
/// `configureDependencies()` builds `LocalNotificationPresenter`, whose
/// `initialize()` calls `registerNotificationChannels`, which reads channel
/// copy through `t` — and a channel's name and description are frozen the
/// moment Android first creates it (see `notification_channels.dart`). So the
/// locale has to be restored before `configureDependencies()` runs, not merely
/// before the first frame.
///
/// `main()` itself is not unit-testable here: it calls `Firebase.initializeApp`
/// and `runApp`, neither of which this suite can drive. Reading the source and
/// asserting the call order is the honest substitute — it fails the moment
/// someone moves `restoreIsolateLocale()` back below `configureDependencies()`,
/// which is exactly the regression this guards against.
void main() {
  test(
    "main() restores the isolate's locale before it configures dependencies",
    () {
      final source = File('lib/main.dart').readAsStringSync();

      final restoreCall = source.indexOf('await restoreIsolateLocale();');
      final configureCall = source.indexOf('await configureDependencies(');

      expect(
        restoreCall,
        isNonNegative,
        reason: 'main() no longer calls restoreIsolateLocale() at all',
      );
      expect(
        configureCall,
        isNonNegative,
        reason: 'main() no longer calls configureDependencies() at all',
      );
      expect(
        restoreCall,
        lessThan(configureCall),
        reason:
            'configureDependencies() builds LocalNotificationPresenter, whose '
            'initialize() registers every channel and freezes its name and '
            'description at that moment — restoreIsolateLocale() must run '
            'first or a fresh install gets English channel names forever',
      );
    },
  );
}
