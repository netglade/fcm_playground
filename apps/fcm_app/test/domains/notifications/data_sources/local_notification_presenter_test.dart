import 'package:fcm_app/domains/notifications/data_sources/local_notification_presenter.dart';
import 'package:fcm_app/domains/notifications/data_sources/shared_preferences_notification_group_store.dart';
import 'package:fcm_app/domains/push/entities/push_tap.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_local_notifications_platform_interface/flutter_local_notifications_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../../../fakes/fake_local_notifications_platform.dart';

void main() {
  // LocalNotificationPresenter's `groups` parameter now defaults to a
  // SharedPreferencesNotificationGroupStore, and that store's constructor
  // reaches for this platform eagerly — every group below constructs a
  // presenter, including the two that never touch the store at all.
  setUpAll(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  group('LocalNotificationPresenter.handleResponse', () {
    late LocalNotificationPresenter presenter;
    late List<String> dismissals;
    late List<PushTap> taps;
    late AppLifecycleState lifecycle;

    setUp(() {
      lifecycle = AppLifecycleState.resumed;
      presenter = LocalNotificationPresenter(lifecycleState: () => lifecycle);
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

    test(
      'a tap response puts a foreground PushTap on taps and nothing on dismissals',
      () async {
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
      },
    );

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

    test('a press on an action carries its id on the tap', () async {
      presenter.handleResponse(
        const NotificationResponse(
          notificationResponseType:
              NotificationResponseType.selectedNotification,
          payload: 'msg-1',
          actionId: 'retry',
        ),
      );
      await pumpEventQueue();

      expect(taps, [
        const PushTap('msg-1', OpenedFrom.foreground, actionId: 'retry'),
      ]);
    });

    test('a tap on the body carries no action id', () async {
      presenter.handleResponse(
        const NotificationResponse(
          notificationResponseType:
              NotificationResponseType.selectedNotification,
          payload: 'msg-1',
        ),
      );
      await pumpEventQueue();

      expect(taps.single.actionId, isNull);
    });

    test('a press while the app is not on screen reports background', () async {
      lifecycle = AppLifecycleState.paused;

      presenter.handleResponse(
        const NotificationResponse(
          notificationResponseType:
              NotificationResponseType.selectedNotification,
          payload: 'msg-1',
          actionId: 'retry',
        ),
      );
      await pumpEventQueue();

      expect(
        taps.single.from,
        OpenedFrom.background,
        reason:
            'this presenter no longer only draws foreground banners — the '
            'background isolate draws through the same builder, so the state '
            'has to be read rather than assumed',
      );
    });
  });

  group('LocalNotificationPresenter.handleLaunchDetails', () {
    late LocalNotificationPresenter presenter;
    late List<PushTap> taps;

    setUp(() {
      presenter = LocalNotificationPresenter(
        lifecycleState: () => AppLifecycleState.resumed,
      );
      taps = <PushTap>[];
      presenter.taps.listen(taps.add);
    });

    tearDown(() => presenter.dispose());

    NotificationAppLaunchDetails launch({String? actionId}) =>
        NotificationAppLaunchDetails(
          true,
          notificationResponse: NotificationResponse(
            notificationResponseType:
                NotificationResponseType.selectedNotification,
            payload: 'msg-1',
            actionId: actionId,
          ),
        );

    test('a press that launched the app reports killed', () async {
      presenter.handleLaunchDetails(launch(actionId: 'retry'));
      await pumpEventQueue();

      expect(taps, [
        const PushTap('msg-1', OpenedFrom.killed, actionId: 'retry'),
      ]);
    });

    test('a launch that no notification caused reports nothing', () async {
      presenter.handleLaunchDetails(const NotificationAppLaunchDetails(false));
      await pumpEventQueue();

      expect(taps, isEmpty);
    });

    test('null details report nothing', () async {
      presenter.handleLaunchDetails(null);
      await pumpEventQueue();

      expect(taps, isEmpty);
    });

    test(
      'the callback repeating the launching press reports it once',
      () async {
        presenter.handleLaunchDetails(launch(actionId: 'retry'));
        presenter.handleResponse(
          const NotificationResponse(
            notificationResponseType:
                NotificationResponseType.selectedNotification,
            payload: 'msg-1',
            actionId: 'retry',
          ),
        );
        await pumpEventQueue();

        expect(
          taps,
          hasLength(1),
          reason:
              'not reproducible on the pinned plugin version, but if a future '
              'version ever re-delivered the launching press through this '
              'callback too, two opens for one press would be a telemetry bug',
        );
      },
    );

    test(
      'a genuine second press of the same button is not swallowed',
      () async {
        presenter.handleLaunchDetails(launch(actionId: 'retry'));
        presenter.handleResponse(
          const NotificationResponse(
            notificationResponseType:
                NotificationResponseType.selectedNotification,
            payload: 'msg-1',
            actionId: 'retry',
          ),
        );
        presenter.handleResponse(
          const NotificationResponse(
            notificationResponseType:
                NotificationResponseType.selectedNotification,
            payload: 'msg-1',
            actionId: 'retry',
          ),
        );
        await pumpEventQueue();

        expect(
          taps.map((tap) => tap.from),
          [OpenedFrom.killed, OpenedFrom.foreground],
          reason:
              'the guard drops the first matching response, whenever it '
              'arrives, and nulls itself out — a second matching response is '
              'never checked against it and always reported',
        );
      },
    );

    test('a different press after the launch is reported', () async {
      presenter.handleLaunchDetails(launch(actionId: 'retry'));
      presenter.handleResponse(
        const NotificationResponse(
          notificationResponseType:
              NotificationResponseType.selectedNotification,
          payload: 'msg-1',
          actionId: 'open',
        ),
      );
      await pumpEventQueue();

      expect(taps.map((tap) => tap.actionId), ['retry', 'open']);
    });

    test(
      'a launching press survives being emitted before anyone subscribes',
      () async {
        // The setUp above subscribes before calling handleLaunchDetails, which
        // is the opposite of production: main.dart only subscribes after
        // configureDependencies (and so initialize(), and so
        // handleLaunchDetails) has already returned. This test drives that real
        // ordering directly, on a presenter of its own.
        final unsubscribedPresenter = LocalNotificationPresenter(
          lifecycleState: () => AppLifecycleState.resumed,
        );
        addTearDown(unsubscribedPresenter.dispose);

        unsubscribedPresenter.handleLaunchDetails(launch(actionId: 'retry'));
        final lateTaps = <PushTap>[];
        unsubscribedPresenter.taps.listen(lateTaps.add);
        await pumpEventQueue();

        expect(
          lateTaps,
          [const PushTap('msg-1', OpenedFrom.killed, actionId: 'retry')],
          reason:
              'a broadcast controller discards an event added before anyone '
              'listens, and this is exactly that gap: the stream must buffer '
              'so the launching press is not lost',
        );
      },
    );
  });

  group('LocalNotificationPresenter.clearAll', () {
    setUp(() {
      // clearAll reaches the real plugin's cancelAll(), which delegates to
      // this platform. `flutter test` never runs the plugin registrant that
      // would otherwise set it, so this fake stands in for it.
      FlutterLocalNotificationsPlatform.instance =
          FakeLocalNotificationsPlatform();
    });

    test('clearing cancels every notification and forgets the groups', () async {
      final groups = SharedPreferencesNotificationGroupStore();
      await groups.save({
        'builds': ['msg-1'],
      });
      final presenter = LocalNotificationPresenter(
        lifecycleState: () => AppLifecycleState.resumed,
        groups: groups,
      );

      await presenter.clearAll();

      expect(
        await groups.load(),
        isEmpty,
        reason:
            'a count that outlived the notifications it counted would make the '
            'next group notification claim a tally the tray does not show',
      );
    });
  });
}
