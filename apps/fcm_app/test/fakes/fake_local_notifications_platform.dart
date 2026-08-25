import 'package:flutter_local_notifications_platform_interface/flutter_local_notifications_platform_interface.dart';

/// A minimal stand-in for the platform channel `FlutterLocalNotificationsPlugin`
/// delegates to.
///
/// `flutter test` never runs the plugin registrant that would otherwise set
/// [FlutterLocalNotificationsPlatform.instance], so a test that reaches a real
/// method on the plugin needs one of these in its place. Extending rather than
/// mocking, because the platform's own constructor already registers the token
/// its `instance` setter checks before accepting a new value.
///
/// Only [cancelAll] has a body: every other method's default implementation
/// throws `UnimplementedError`, which is fine for a test that never calls it.
class FakeLocalNotificationsPlatform extends FlutterLocalNotificationsPlatform {
  @override
  Future<void> cancelAll() => Future<void>.value();
}
