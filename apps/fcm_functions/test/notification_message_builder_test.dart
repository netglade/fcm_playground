import 'package:fcm_functions/notification_message_builder.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:firebase_admin_sdk/messaging.dart';
import 'package:test/test.dart';

const _builder = NotificationMessageBuilder();

final _sentAt = DateTime.utc(2026, 8, 10, 9, 30);

TokenMessage _build(NotificationDraft draft) => _builder.build(
  draft: draft,
  token: 'device-token',
  payloadId: 'sandbox-1',
  sentAt: _sentAt,
);

const _visible = NotificationDraft(
  event: NotificationEvent.buildFinished,
  title: 'Build finished',
  body: 'Release 1.0.0 is ready.',
  data: {'deepLink': '/builds/42'},
);

void main() {
  group('NotificationMessageBuilder', () {
    test('targets the token it was given', () {
      expect(_build(_visible).token, 'device-token');
    });

    test('writes the four keys PushMessageParser requires, plus the event', () {
      expect(_build(_visible).data, {
        'deepLink': '/builds/42',
        'id': 'sandbox-1',
        'title': 'Build finished',
        'body': 'Release 1.0.0 is ready.',
        'sentAt': '2026-08-10T09:30:00.000Z',
        'event': 'build_finished',
      });
    });

    test(
      'reserved keys win over caller data, even though the validator should have rejected the collision first',
      () {
        final draft = _visible.copyWith(data: const {'id': 'not-this'});

        expect(_build(draft).data?['id'], 'sandbox-1');
      },
    );

    test('a visible draft gets a notification block', () {
      final notification = _build(_visible).notification;

      expect(notification?.title, 'Build finished');
      expect(notification?.body, 'Release 1.0.0 is ready.');
    });

    test('a visible draft needs no APNs override', () {
      expect(_build(_visible).apns, isNull);
    });

    test('a silent draft carries no notification block', () {
      final silent = _visible.copyWith(
        delivery: const NotificationDelivery(asNotification: false),
      );

      expect(_build(silent).notification, isNull);
    });

    test(
      'a silent draft sets APNs content-available so iOS wakes the app instead of dropping the push',
      () {
        final silent = _visible.copyWith(
          delivery: const NotificationDelivery(asNotification: false),
        );

        expect(_build(silent).apns?.payload?.aps.contentAvailable, isTrue);
      },
    );

    test('high priority maps to the Android high priority', () {
      expect(_build(_visible).android?.priority, AndroidConfigPriority.high);
    });

    test('normal priority maps to the Android normal priority', () {
      final draft = _visible.copyWith(
        delivery: const NotificationDelivery(
          priority: NotificationPriority.normal,
        ),
      );

      expect(_build(draft).android?.priority, AndroidConfigPriority.normal);
    });

    test('sentAt is normalised to UTC before it is written', () {
      final message = _builder.build(
        draft: _visible,
        token: 'device-token',
        payloadId: 'sandbox-1',
        sentAt: _sentAt.toLocal(),
      );

      expect(message.data?['sentAt'], '2026-08-10T09:30:00.000Z');
    });
  });
}
