import 'dart:typed_data';

import 'package:fcm_app/domains/push/push_message.dart';
import 'package:fcm_app/domains/notifications/notification_details_builder.dart';
import 'package:fcm_app/domains/notifications/notification_content.dart';
import 'package:fcm_app/domains/push/remote_message_payload.dart';
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

    test('gives an input action a text field and leaves the app closed', () {
      final details = buildNotificationDetails(
        message(data: const {'actions': 'reply:Reply:input'}),
      );

      final action = details.android!.actions!.single;
      expect(action.inputs, hasLength(1));
      expect(
        action.showsUserInterface,
        isFalse,
        reason:
            'answering without opening the app is the whole demonstration; '
            'showing UI would route the press to the main isolate instead',
      );
      expect(
        action.cancelNotification,
        isFalse,
        reason:
            'the notification has to survive the press so the background '
            'isolate can update it in place',
      );
    });

    test('keeps a plain action opening the app and cancelling', () {
      final details = buildNotificationDetails(
        message(data: const {'actions': 'open:Open build'}),
      );

      final action = details.android!.actions!.single;
      expect(action.inputs, isEmpty);
      expect(action.showsUserInterface, isTrue);
      expect(action.cancelNotification, isTrue);
    });

    test('carries both shapes in one notification', () {
      final details = buildNotificationDetails(
        message(data: const {'actions': 'reply:Reply:input|mute:Mute'}),
      );

      final actions = details.android!.actions!;
      expect(actions.map((action) => action.inputs.isNotEmpty), [true, false]);
      expect(actions.map((action) => action.showsUserInterface), [false, true]);
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

    test('makes a notification ongoing when the payload asks', () {
      final details = buildNotificationDetails(
        message(data: const {'ongoing': 'true'}),
      );

      expect(details.android?.ongoing, isTrue);
      expect(
        details.android?.autoCancel,
        isFalse,
        reason:
            'an ongoing notification that a tap silently removes is not '
            'ongoing, which is the property f7 exists to show',
      );
    });

    test('leaves an ordinary notification dismissable', () {
      final details = buildNotificationDetails(message());

      expect(details.android?.ongoing, isFalse);
    });

    test('treats any value other than true as not ongoing', () {
      final details = buildNotificationDetails(
        message(data: const {'ongoing': 'yes'}),
      );

      expect(
        details.android?.ongoing,
        isFalse,
        reason:
            'the Sandbox accepts any text; only the documented value turns a '
            'notification into one the user cannot swipe away',
      );
    });

    test('puts a notification in the group the payload names', () {
      final details = buildNotificationDetails(
        message(data: const {'group': 'builds'}),
      );

      expect(details.android?.groupKey, 'builds');
    });

    test('leaves groupKey null when the payload names no group', () {
      expect(buildNotificationDetails(message()).android?.groupKey, isNull);
    });

    test('asks for a full-screen intent when the payload does', () {
      final details = buildNotificationDetails(
        message(data: const {'full_screen': 'true'}),
      );

      expect(details.android?.fullScreenIntent, isTrue);
    });

    test('leaves an ordinary notification alone', () {
      expect(
        buildNotificationDetails(message()).android?.fullScreenIntent,
        isFalse,
      );
    });

    test('treats any value other than true as no request', () {
      expect(
        buildNotificationDetails(
          message(data: const {'full_screen': 'yes'}),
        ).android?.fullScreenIntent,
        isFalse,
        reason:
            'the Sandbox accepts any text; only the documented value asks to '
            'take over the screen',
      );
    });
  });

  group('the channel it draws through', () {
    PushMessage messageWith(Map<String, String> data) => PushMessage(
      id: 'id-1',
      title: 'Title',
      body: 'Body',
      sentAt: DateTime.utc(2026, 8, 26),
      data: data,
    );

    test('is the one the payload names', () {
      final details = buildNotificationDetails(
        messageWith({pushChannelKey: 'importance_low'}),
      );

      expect(details.android?.channelId, 'importance_low');
      expect(details.android?.importance, Importance.low);
    });

    test('falls back to the default for an unknown channel', () {
      final details = buildNotificationDetails(
        messageWith({pushChannelKey: 'no_such_channel'}),
      );

      // A channel the app never registered would draw nothing at all on
      // Android O+, so an unknown id must not be passed through.
      expect(details.android?.channelId, notificationChannelId);
    });

    test('falls back to the default when the payload names none', () {
      expect(
        buildNotificationDetails(messageWith({})).android?.channelId,
        notificationChannelId,
      );
    });

    test('sets the alarm category h2 asks for', () {
      final details = buildNotificationDetails(
        messageWith({pushChannelKey: 'alarms', pushCategoryKey: 'alarm'}),
      );

      expect(details.android?.category, AndroidNotificationCategory.alarm);
    });

    test('ignores a category it does not recognise', () {
      final details = buildNotificationDetails(
        messageWith({pushCategoryKey: 'not_a_category'}),
      );

      expect(details.android?.category, isNull);
    });
  });

  group('appearance', () {
    test('carries the default big text style through', () {
      final details = buildNotificationDetails(message());

      expect(details.android!.styleInformation, isA<BigTextStyleInformation>());
    });

    test('puts an inbox payload on styleInformation', () {
      final details = buildNotificationDetails(
        message(data: {'style': 'inbox', 'lines': 'one|two'}),
      );

      expect(details.android!.styleInformation, isA<InboxStyleInformation>());
    });

    test('puts a downloaded avatar on largeIcon, not on the style', () {
      final details = buildNotificationDetails(
        message(data: {'style': 'large_icon'}),
        largeIcon: Uint8List.fromList([1, 2]),
      );

      expect(details.android!.largeIcon, isA<ByteArrayAndroidBitmap>());
      expect(details.android!.styleInformation, isA<BigTextStyleInformation>());
    });

    test('spreads a progress payload over the three progress fields', () {
      final details = buildNotificationDetails(
        message(data: {'style': 'progress', 'progress': '40', 'max': '100'}),
      );

      expect(details.android!.showProgress, isTrue);
      expect(details.android!.progress, 40);
      expect(details.android!.maxProgress, 100);
    });

    // The bytes are the whole difference between a big picture and a plain
    // expandable notification, so the fallback is worth pinning here too.
    test('a big_picture with no bytes still draws, as big text', () {
      final details = buildNotificationDetails(
        message(data: {'style': 'big_picture'}),
      );

      expect(details.android!.styleInformation, isA<BigTextStyleInformation>());
      expect(details.android!.largeIcon, isNull);
    });
  });
}
