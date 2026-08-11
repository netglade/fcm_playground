import 'package:fcm_app/push/push_inbox.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_push_payload_store.dart';
import 'fake_push_source.dart';
import 'recording_notification_presenter.dart';

Map<String, Object?> payload({String id = 'msg-1', String title = 'Hello'}) => {
  'id': id,
  'title': title,
  'body': 'A message body.',
  'sentAt': '2026-08-06T09:30:00Z',
};

void main() {
  late FakePushSource source;
  late PushInbox inbox;

  setUp(() {
    source = FakePushSource();
    inbox = PushInbox(source, store: FakePushPayloadStore())..listen();
  });

  tearDown(() async {
    inbox.dispose();
    await source.dispose();
  });

  test('starts empty', () {
    expect(inbox.messages, isEmpty);
    expect(inbox.rejections, isEmpty);
    expect(inbox.setupError, isNull);
  });

  test('exposes a received message and notifies listeners', () async {
    var notifications = 0;
    inbox.addListener(() => notifications++);

    source.emit(payload());
    await pumpEventQueue();

    expect(inbox.messages.single.title, 'Hello');
    expect(notifications, 1);
  });

  test('orders messages newest first', () async {
    source
      ..emit(payload(id: 'msg-1', title: 'First'))
      ..emit(payload(id: 'msg-2', title: 'Second'));
    await pumpEventQueue();

    expect(inbox.messages.map((m) => m.title), ['Second', 'First']);
  });

  test('drops a repeated message id', () async {
    source
      ..emit(payload(id: 'msg-1'))
      ..emit(payload(id: 'msg-1'));
    await pumpEventQueue();

    expect(inbox.messages, hasLength(1));
  });

  test('records a malformed payload instead of throwing', () async {
    source.emit({'id': 'msg-1', 'title': 'No body or timestamp'});
    await pumpEventQueue();

    expect(inbox.messages, isEmpty);
    expect(inbox.rejections.single, contains('body'));
  });

  test('refreshToken exposes the token', () async {
    await inbox.refreshToken();

    expect(inbox.token, 'fake-token');
  });

  test('refreshToken leaves the token null when the source fails', () async {
    final failing = FakePushSource(tokenThrows: true);
    final failingInbox = PushInbox(failing, store: FakePushPayloadStore());
    addTearDown(failingInbox.dispose);
    addTearDown(failing.dispose);

    await failingInbox.refreshToken();

    expect(failingInbox.token, isNull);
  });

  group('PushInbox.restore', () {
    test(
      'loads stored payloads newest first, as the inbox shows them',
      () async {
        final store = FakePushPayloadStore(
          inbox: [
            payload(id: 'newest'),
            payload(id: 'oldest'),
          ],
        );
        inbox = PushInbox(source, store: store);

        await inbox.restore();

        expect(inbox.messages.map((message) => message.id), [
          'newest',
          'oldest',
        ]);
      },
    );

    test('drains what the background isolate left', () async {
      final store = FakePushPayloadStore(pending: [payload(id: 'background')]);
      inbox = PushInbox(source, store: store);

      await inbox.restore();

      expect(inbox.messages.single.id, 'background');
      expect(store.pending, isEmpty);
    });

    test('keeps a payload once when it is both stored and pending', () async {
      final store = FakePushPayloadStore(
        inbox: [payload(id: 'msg-1')],
        pending: [payload(id: 'msg-1')],
      );
      inbox = PushInbox(source, store: store);

      await inbox.restore();

      expect(inbox.messages, hasLength(1));
    });

    test(
      'persists the merged result, so the drained payload is not lost',
      () async {
        final store = FakePushPayloadStore(
          pending: [payload(id: 'background')],
        );
        inbox = PushInbox(source, store: store);

        await inbox.restore();

        expect(store.saves, 1);
        expect(store.inbox.single['id'], 'background');
      },
    );

    test('counts a malformed stored payload as a rejection', () async {
      final store = FakePushPayloadStore(
        inbox: [
          {'id': 'broken'},
        ],
      );
      inbox = PushInbox(source, store: store);

      await inbox.restore();

      expect(inbox.messages, isEmpty);
      expect(inbox.rejections, hasLength(1));
    });

    test('degrades to an empty inbox when storage fails', () async {
      inbox = PushInbox(source, store: FakePushPayloadStore(loadThrows: true));

      await inbox.restore();

      expect(inbox.messages, isEmpty);
      expect(inbox.setupError, contains('could not be read'));
    });

    test(
      'leaves an existing setup error alone when storage also fails',
      () async {
        inbox = PushInbox(
          source,
          store: FakePushPayloadStore(loadThrows: true),
          setupError: 'Firebase is not configured',
        );

        await inbox.restore();

        expect(inbox.setupError, 'Firebase is not configured');
      },
    );
  });

  group('PushInbox.drainPending', () {
    test('merges a payload that arrived while backgrounded', () async {
      final store = FakePushPayloadStore();
      inbox = PushInbox(source, store: store)..listen();
      await inbox.restore();
      store.pending.add(payload(id: 'while-away'));

      await inbox.drainPending();

      expect(inbox.messages.single.id, 'while-away');
    });

    test('does not duplicate when drained twice', () async {
      final store = FakePushPayloadStore(pending: [payload(id: 'once')]);
      inbox = PushInbox(source, store: store);

      await inbox.drainPending();
      await inbox.drainPending();

      expect(inbox.messages, hasLength(1));
    });

    test('does not save when there was nothing pending', () async {
      final store = FakePushPayloadStore();
      inbox = PushInbox(source, store: store);

      await inbox.drainPending();

      expect(store.saves, 0);
    });
  });

  group('PushInbox persistence of live messages', () {
    test('persists a payload that arrives on the stream', () async {
      final store = FakePushPayloadStore();
      inbox = PushInbox(source, store: store)..listen();

      source.emit(payload(id: 'live'));
      await pumpEventQueue();

      expect(store.inbox.single['id'], 'live');
    });
  });

  group('PushInbox cap', () {
    test(
      'keeps only the newest maxStoredMessages and drops the oldest',
      () async {
        final store = FakePushPayloadStore();
        inbox = PushInbox(source, store: store)..listen();

        for (var index = 0; index <= PushInbox.maxStoredMessages; index++) {
          source.emit(payload(id: 'msg-$index'));
        }
        await pumpEventQueue();

        expect(inbox.messages, hasLength(PushInbox.maxStoredMessages));
        expect(inbox.messages.first.id, 'msg-${PushInbox.maxStoredMessages}');
        expect(
          inbox.messages.map((message) => message.id),
          isNot(contains('msg-0')),
        );
      },
    );

    test('persists the capped list, not the full history', () async {
      final store = FakePushPayloadStore();
      inbox = PushInbox(source, store: store)..listen();

      for (var index = 0; index <= PushInbox.maxStoredMessages; index++) {
        source.emit(payload(id: 'msg-$index'));
      }
      await pumpEventQueue();

      expect(store.inbox, hasLength(PushInbox.maxStoredMessages));
    });
  });

  group('PushInbox notifications', () {
    late RecordingNotificationPresenter presenter;

    setUp(() {
      presenter = RecordingNotificationPresenter();
    });

    tearDown(() async {
      await presenter.dispose();
    });

    test('shows a banner for a payload arriving on the stream', () async {
      inbox = PushInbox(
        source,
        store: FakePushPayloadStore(),
        presenter: presenter,
      )..listen();

      source.emit(payload(id: 'live'));
      await pumpEventQueue();

      expect(presenter.shown.single.id, 'live');
    });

    test(
      'shows nothing for a restored payload, which FCM already showed',
      () async {
        inbox = PushInbox(
          source,
          store: FakePushPayloadStore(inbox: [payload(id: 'old')]),
          presenter: presenter,
        );

        await inbox.restore();

        expect(inbox.messages, hasLength(1));
        expect(presenter.shown, isEmpty);
      },
    );

    test(
      'shows nothing for a drained payload, which FCM already showed',
      () async {
        inbox = PushInbox(
          source,
          store: FakePushPayloadStore(pending: [payload(id: 'background')]),
          presenter: presenter,
        );

        await inbox.drainPending();

        expect(inbox.messages, hasLength(1));
        expect(presenter.shown, isEmpty);
      },
    );

    test('shows nothing for a payload that fails validation', () async {
      inbox = PushInbox(
        source,
        store: FakePushPayloadStore(),
        presenter: presenter,
      )..listen();

      source.emit({'id': 'broken'});
      await pumpEventQueue();

      expect(presenter.shown, isEmpty);
    });

    test('shows a repeated id once, matching the inbox', () async {
      inbox = PushInbox(
        source,
        store: FakePushPayloadStore(),
        presenter: presenter,
      )..listen();

      source.emit(payload(id: 'twice'));
      source.emit(payload(id: 'twice'));
      await pumpEventQueue();

      expect(presenter.shown, hasLength(1));
    });
  });
}
