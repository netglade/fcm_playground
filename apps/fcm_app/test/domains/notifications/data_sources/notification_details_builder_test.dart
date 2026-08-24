import 'package:core/core.dart';
import 'package:fcm_app/domains/notifications/data_sources/notification_details_builder.dart';
import 'package:fcm_app/domains/notifications/entities/notification_content.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  PushMessage message({Map<String, String> data = const {}}) => PushMessage(
    id: 'msg-1',
    title: 'Build failed',
    body: 'Retry or open?',
    sentAt: DateTime.utc(2026, 8, 24, 9),
    data: data,
  );

  group('buildNotificationDetails', () {
    test('puts the channel and its importance on the Android details', () {
      final details = buildNotificationDetails(message());

      expect(details.android?.channelId, notificationChannelId);
      expect(details.android?.importance, Importance.high);
      expect(details.android?.priority, Priority.high);
    });

    test('reports a swipe from the main isolate', () {
      final details = buildNotificationDetails(message());

      expect(
        details.android?.dismissIsolate,
        NotificationDismissedIsolate.main,
        reason:
            'without this a swipe is not reported at all, and the dismissed '
            'event depends on it',
      );
    });

    test('turns data.actions into Android actions that open the app', () {
      final details = buildNotificationDetails(
        message(data: const {'actions': 'retry:Retry|open:Open build'}),
      );

      final actions = details.android?.actions ?? const [];
      expect(actions.map((action) => action.id), ['retry', 'open']);
      expect(actions.map((action) => action.title), ['Retry', 'Open build']);
      expect(
        actions.every((action) => action.showsUserInterface),
        isTrue,
        reason:
            'every action in this cycle opens the app, which is what lets the '
            'press be observed in the main isolate and nowhere else',
      );
      expect(
        actions.every((action) => action.cancelNotification),
        isTrue,
        reason:
            'a notification still sitting in the tray after its button was '
            'pressed reads as a press that did nothing',
      );
    });

    test('carries no actions when the payload names none', () {
      final details = buildNotificationDetails(message());

      expect(details.android?.actions, isEmpty);
    });

    test('carries plain iOS details, because actions need a category', () {
      final details = buildNotificationDetails(
        message(data: const {'actions': 'retry:Retry'}),
      );

      expect(
        details.iOS,
        isNotNull,
        reason:
            'iOS action buttons come from a UNNotificationCategory registered '
            'at startup, so a per-message list cannot reach them',
      );
      expect(
        details.iOS?.categoryIdentifier,
        isNull,
        reason:
            'no category means no buttons — asserting isNotNull above would '
            'still pass if the builder started setting one',
      );
    });
  });
}
