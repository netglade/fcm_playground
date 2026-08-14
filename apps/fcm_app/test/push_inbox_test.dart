import 'dart:async';

import 'package:fcm_app/push/push_inbox.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_push_payload_store.dart';
import 'fake_push_source.dart';
import 'recording_notification_presenter.dart';
import 'telemetry/recording_push_telemetry.dart';
import 'telemetry/throwing_push_telemetry.dart';

/// A received payload, optionally carrying the keys the send API injects.
///
/// `trace_id` and `scenario_id` sit at the top level rather than under a `data`
/// map because that is where they arrive: `remoteMessageToPayload` spreads FCM's
/// `data` over the envelope-derived keys.
Map<String, Object?> payload({
  String id = 'msg-1',
  String title = 'Hello',
  String? traceId,
  String? scenarioId,
}) => {
  'id': id,
  'title': title,
  'body': 'A message body.',
  'sentAt': '2026-08-06T09:30:00Z',
  'trace_id': ?traceId,
  'scenario_id': ?scenarioId,
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
    expect(inbox.rejections.single, contains('sentAt'));
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
      // A fresh source: `source` from setUp is already listened to by the
      // inbox built there, and payloads is single-subscription.
      source = FakePushSource();
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
      // A fresh source: `source` from setUp is already listened to by the
      // inbox built there, and payloads is single-subscription.
      source = FakePushSource();
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
        // A fresh source: `source` from setUp is already listened to by the
        // inbox built there, and payloads is single-subscription.
        source = FakePushSource();
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
      // A fresh source: `source` from setUp is already listened to by the
      // inbox built there, and payloads is single-subscription.
      source = FakePushSource();
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
      // A fresh source: `source` from setUp is already listened to by the
      // inbox built there, and payloads is single-subscription.
      source = FakePushSource();
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
      // A fresh source: `source` from setUp is already listened to by the
      // inbox built there, and payloads is single-subscription.
      source = FakePushSource();
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
      // A fresh source: `source` from setUp is already listened to by the
      // inbox built there, and payloads is single-subscription.
      source = FakePushSource();
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

  group('PushInbox.requestOpen', () {
    test('resolves an id the inbox holds', () async {
      inbox = PushInbox(
        source,
        store: FakePushPayloadStore(inbox: [payload(id: 'msg-1')]),
      );
      await inbox.restore();

      inbox.requestOpen('msg-1');

      expect(inbox.hasPendingOpen, isTrue);
      expect(inbox.pendingOpen?.id, 'msg-1');
    });

    test('stays outstanding but unresolved for an unknown id', () {
      inbox = PushInbox(source, store: FakePushPayloadStore());

      inbox.requestOpen('never-seen');

      expect(inbox.hasPendingOpen, isTrue);
      expect(inbox.pendingOpen, isNull);
    });

    test(
      'resolves once the message arrives, whatever the stream order',
      () async {
        // A fresh source: `source` from setUp is already listened to by the
        // inbox built there, and payloads is single-subscription.
        source = FakePushSource();
        inbox = PushInbox(source, store: FakePushPayloadStore())..listen();

        inbox.requestOpen('late');
        expect(inbox.pendingOpen, isNull);
        source.emit(payload(id: 'late'));
        await pumpEventQueue();

        expect(inbox.pendingOpen?.id, 'late');
      },
    );

    test('notifies listeners so the shell can react', () {
      inbox = PushInbox(source, store: FakePushPayloadStore());
      var notifications = 0;
      inbox.addListener(() => notifications++);

      inbox.requestOpen('msg-1');

      expect(notifications, 1);
    });

    test('clears, so the shell does not navigate twice', () async {
      inbox = PushInbox(
        source,
        store: FakePushPayloadStore(inbox: [payload(id: 'msg-1')]),
      );
      await inbox.restore();
      inbox.requestOpen('msg-1');

      inbox.clearPendingOpen();

      expect(inbox.hasPendingOpen, isFalse);
      expect(inbox.pendingOpen, isNull);
    });
  });

  group('PushInbox telemetry', () {
    late RecordingPushTelemetry telemetry;

    setUp(() {
      telemetry = RecordingPushTelemetry();
      // A fresh source: `source` from the outer setUp is already listened to by
      // the inbox built there, and payloads is single-subscription.
      source = FakePushSource();
    });

    test('records a foreground arrival against the trace id', () async {
      inbox = PushInbox(
        source,
        store: FakePushPayloadStore(),
        telemetry: telemetry,
      )..listen();

      source.emit(payload(traceId: 'tr-1', scenarioId: 'a1_notification_only'));
      await pumpEventQueue();

      expect(telemetry.recorded.first.type, TelemetryEventType.receivedFg);
      expect(telemetry.recorded.first.traceId, 'tr-1');
      expect(
        telemetry.recorded.first.scenarioId,
        'a1_notification_only',
        reason: 'the scenario axis of the matrix comes off the payload',
      );
      expect(
        telemetry.recordedAtFlush.first,
        greaterThanOrEqualTo(1),
        reason:
            'the foreground knows it is safe to send, and the flush happened '
            'after the arrival was recorded rather than before it',
      );
    });

    test('records nothing for a push with no trace id', () async {
      // A hand-made `curl` send has none. Inventing one would put a message
      // nobody sent into the matrix.
      inbox = PushInbox(
        source,
        store: FakePushPayloadStore(),
        telemetry: telemetry,
      )..listen();

      source
        ..emit(payload(id: 'by-hand'))
        ..emit(payload(id: 'msg-2', traceId: 'tr-2'));
      await pumpEventQueue();

      expect(
        inbox.messages,
        hasLength(2),
        reason: 'both pushes arrived; only one of them is traceable',
      );
      expect(
        telemetry.recorded.map((event) => event.traceId),
        everyElement('tr-2'),
      );
      expect(
        telemetry.types,
        contains(TelemetryEventType.receivedFg),
        reason:
            'something was recorded, so the untraced push was skipped for want '
            'of an id rather than by a hook that never fires',
      );
    });

    test('records the arrival of a payload that fails validation', () async {
      // It arrived. A push the parser rejects is exactly the kind the matrix is
      // wanted for, and its trace id is readable whether the rest of it parses.
      inbox = PushInbox(
        source,
        store: FakePushPayloadStore(),
        telemetry: telemetry,
      )..listen();

      source.emit({'id': 'broken', 'trace_id': 'tr-1'});
      await pumpEventQueue();

      expect(inbox.rejections, hasLength(1));
      expect(telemetry.types, [TelemetryEventType.receivedFg]);
    });

    test('records both deliveries of a repeated message id', () async {
      // FCM does not promise at-most-once delivery, and two deliveries are two
      // arrivals: the inbox collapses them because it shows messages, while the
      // matrix wants to know it happened. The server is idempotent on
      // (trace, type, device), so the second row costs nothing there.
      inbox = PushInbox(
        source,
        store: FakePushPayloadStore(),
        telemetry: telemetry,
      )..listen();

      source
        ..emit(payload(id: 'twice', traceId: 'tr-1'))
        ..emit(payload(id: 'twice', traceId: 'tr-1'));
      await pumpEventQueue();

      expect(inbox.messages, hasLength(1));
      expect(
        telemetry.types.where((type) => type == TelemetryEventType.receivedFg),
        hasLength(2),
      );
    });

    test('records no arrival for a restored payload', () async {
      // Restored pushes arrived earlier — the background handler recorded them
      // as `received_bg` at the time. Recording them again on the next launch
      // would report an arrival that is really a database read, and every
      // restart would add one.
      inbox = PushInbox(
        source,
        store: FakePushPayloadStore(
          inbox: [payload(id: 'old', traceId: 'tr-old')],
          pending: [payload(id: 'background', traceId: 'tr-bg')],
        ),
        telemetry: telemetry,
      );

      await inbox.restore();

      expect(inbox.messages, hasLength(2));
      expect(telemetry.recorded, isEmpty);
    });

    test('records displayed only after show() succeeds', () async {
      // Before it, a presenter that threw would report a notification that was
      // never drawn — and "displayed but not seen" is a conclusion someone would
      // then chase on the device.
      final drawing = Completer<void>();
      final presenter = RecordingNotificationPresenter(gate: drawing.future);
      addTearDown(presenter.dispose);
      inbox = PushInbox(
        source,
        store: FakePushPayloadStore(),
        presenter: presenter,
        telemetry: telemetry,
      )..listen();

      source.emit(payload(traceId: 'tr-1'));
      await pumpEventQueue();

      expect(
        presenter.shown,
        hasLength(1),
        reason: 'show() was called and has not returned yet',
      );
      expect(
        telemetry.types,
        [TelemetryEventType.receivedFg],
        reason:
            'nothing is drawn until show() completes, so nothing is claimed',
      );

      drawing.complete();
      await pumpEventQueue();

      expect(telemetry.types, [
        TelemetryEventType.receivedFg,
        TelemetryEventType.displayed,
      ]);
      expect(telemetry.recorded.last.traceId, 'tr-1');
    });

    test('records no displayed when show() throws', () async {
      final presenter = RecordingNotificationPresenter(failing: true);
      addTearDown(presenter.dispose);
      inbox = PushInbox(
        source,
        store: FakePushPayloadStore(),
        presenter: presenter,
        telemetry: telemetry,
      )..listen();

      source.emit(payload(traceId: 'tr-1'));
      await pumpEventQueue();

      expect(
        presenter.shown,
        hasLength(1),
        reason:
            'a banner was attempted, so the absence below is the failure and '
            'not a pipeline that never got that far',
      );
      expect(telemetry.types, [TelemetryEventType.receivedFg]);
      expect(
        inbox.messages,
        hasLength(1),
        reason: 'and a failed banner still does not cost the message',
      );
    });

    test('records opened when a notification tap is handled', () async {
      inbox = PushInbox(
        source,
        store: FakePushPayloadStore(),
        telemetry: telemetry,
      )..listen();
      source.emit(payload(traceId: 'tr-1', scenarioId: 'a1_notification_only'));
      await pumpEventQueue();

      inbox.requestOpen('msg-1');
      await pumpEventQueue();

      final opens = telemetry.recorded
          .where((event) => event.type == TelemetryEventType.opened)
          .toList();
      expect(opens, hasLength(1));
      expect(
        opens.single.traceId,
        'tr-1',
        reason: 'the tap resolves to the payload the inbox kept',
      );
      expect(opens.single.scenarioId, 'a1_notification_only');
    });

    test('delivers the push even when the reporter fails', () async {
      // The hooks are called fire-and-forget from the stream handler, so a
      // throw would arrive as an unhandled asynchronous error on the delivery
      // path — which this test fails on. Telemetry must never cost the thing it
      // observes.
      final failing = ThrowingPushTelemetry();
      inbox = PushInbox(
        source,
        store: FakePushPayloadStore(),
        telemetry: failing,
      )..listen();

      source.emit(payload(traceId: 'tr-1'));
      await pumpEventQueue();
      inbox.requestOpen('msg-1');
      await pumpEventQueue();

      expect(inbox.messages.single.id, 'msg-1');
      expect(
        failing.attempted,
        containsAll([TelemetryEventType.receivedFg, TelemetryEventType.opened]),
        reason: 'the hooks did fire, so the failures above were real ones',
      );
    });

    test('records the open once the tapped payload is drained', () async {
      // The ordinary Android path, and the one the trace id makes awkward: FCM
      // reports a tap on a tray entry it drew itself as the app resumes, while
      // the payload it refers to is still in the queue the background isolate
      // appended to. There is nothing to read a trace id from until it is
      // drained — so the open waits for its payload rather than being dropped or
      // recorded against an invented id.
      inbox = PushInbox(
        source,
        store: FakePushPayloadStore(
          pending: [payload(id: 'tapped', traceId: 'tr-1')],
        ),
        telemetry: telemetry,
      );

      inbox.requestOpen('tapped');
      await pumpEventQueue();

      expect(
        telemetry.recorded,
        isEmpty,
        reason: 'no payload, no trace id yet',
      );

      await inbox.drainPending();

      expect(
        telemetry.types,
        [TelemetryEventType.opened],
        reason:
            'exactly one open: the deferred tap, and not a second one for the '
            'same press',
      );
      expect(telemetry.recorded.single.traceId, 'tr-1');
    });

    test('records no open for a tap on a message that never arrives', () async {
      // The trace id lives on the payload, so a tap the inbox cannot resolve has
      // nothing to record against — and a fabricated id is worse than a gap.
      inbox = PushInbox(
        source,
        store: FakePushPayloadStore(),
        telemetry: telemetry,
      )..listen();

      inbox.requestOpen('never-seen');
      await pumpEventQueue();

      expect(inbox.hasPendingOpen, isTrue);
      expect(telemetry.recorded, isEmpty);

      // A different message arriving does not resolve that tap, and tapping
      // this one does record — so the silence above is about the missing
      // payload rather than about a hook that never fires.
      source.emit(payload(id: 'msg-1', traceId: 'tr-1'));
      await pumpEventQueue();
      inbox.requestOpen('msg-1');
      await pumpEventQueue();

      expect(
        telemetry.recorded
            .where((event) => event.type == TelemetryEventType.opened)
            .map((event) => event.traceId),
        ['tr-1'],
      );
    });
  });
}
