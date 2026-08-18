import 'package:fcm_app/domains/notifications/data_sources/local_notification_presenter.dart';
import 'package:fcm_app/domains/push/entities/push_tap.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LocalNotificationPresenter.handleResponse', () {
    late LocalNotificationPresenter presenter;
    late List<String> dismissals;
    late List<PushTap> taps;

    setUp(() {
      presenter = LocalNotificationPresenter();
      dismissals = <String>[];
      taps = <PushTap>[];
      presenter.dismissals.listen(dismissals.add);
      presenter.taps.listen(taps.add);
    });

    tearDown(() => presenter.dispose());

    test(
      'a dismissed response puts the id on dismissals and nothing on taps',
      () async {
        presenter.handleResponse(
          const NotificationResponse(
            notificationResponseType:
                NotificationResponseType.notificationDismissed,
            payload: 'msg-1',
          ),
        );
        await pumpEventQueue();

        expect(dismissals, ['msg-1']);
        expect(
          taps,
          isEmpty,
          reason:
              'the plugin never reports a dismissal as a tap, and this branch '
              'must not undo that',
        );
      },
    );

    test('a tap response puts a foreground PushTap on taps and nothing on '
        'dismissals', () async {
      presenter.handleResponse(
        const NotificationResponse(
          notificationResponseType:
              NotificationResponseType.selectedNotification,
          payload: 'msg-1',
        ),
      );
      await pumpEventQueue();

      expect(taps, [const PushTap('msg-1', OpenedFrom.foreground)]);
      expect(
        dismissals,
        isEmpty,
        reason:
            'one press is one event: a tap must not also register as a '
            'dismissal',
      );
    });

    test('a response with no payload puts nothing on either stream', () async {
      presenter.handleResponse(
        const NotificationResponse(
          notificationResponseType:
              NotificationResponseType.selectedNotification,
        ),
      );
      presenter.handleResponse(
        const NotificationResponse(
          notificationResponseType:
              NotificationResponseType.notificationDismissed,
          payload: '',
        ),
      );
      await pumpEventQueue();

      expect(taps, isEmpty);
      expect(dismissals, isEmpty);
    });
  });
}
