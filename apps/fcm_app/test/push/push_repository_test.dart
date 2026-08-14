import 'dart:async';

import 'package:fcm_app/push/push_repository.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fake_push_payload_store.dart';
import '../fake_push_source.dart';
import '../recording_notification_presenter.dart';
import '../telemetry/recording_push_telemetry.dart';
import '../telemetry/throwing_push_telemetry.dart';

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
  late PushRepository repository;

  setUp(() {
    source = FakePushSource();
    repository = PushRepository(source, store: FakePushPayloadStore())
      ..listen();
  });

  tearDown(() async {
    repository.dispose();
    await source.dispose();
  });

  test('starts empty', () {
    expect(repository.messages, isEmpty);
    expect(repository.rejections, isEmpty);
    expect(repository.setupError, isNull);
  });

  test('exposes a received message and notifies listeners', () async {
    var notifications = 0;
    final watching = repository.changes.listen((_) => notifications++);
    addTearDown(watching.cancel);

    source.emit(payload());
    await pumpEventQueue();

    expect(repository.messages.single.title, 'Hello');
    expect(notifications, 1);
  });

  test('orders messages newest first', () async {
    source
      ..emit(payload(id: 'msg-1', title: 'First'))
      ..emit(payload(id: 'msg-2', title: 'Second'));
    await pumpEventQueue();

    expect(repository.messages.map((m) => m.title), ['Second', 'First']);
  });

  test('drops a repeated message id', () async {
    source
      ..emit(payload(id: 'msg-1'))
      ..emit(payload(id: 'msg-1'));
    await pumpEventQueue();

    expect(repository.messages, hasLength(1));
  });

  test('records a malformed payload instead of throwing', () async {
    source.emit({'id': 'msg-1', 'title': 'No body or timestamp'});
    await pumpEventQueue();

    expect(repository.messages, isEmpty);
    expect(repository.rejections.single, contains('sentAt'));
  });

  test('refreshToken exposes the token', () async {
    await repository.refreshToken();

    expect(repository.token, 'fake-token');
  });

  test('refreshToken leaves the token null when the source fails', () async {
    final failing = FakePushSource(tokenThrows: true);
    final failingRepository = PushRepository(
      failing,
      store: FakePushPayloadStore(),
    );
    addTearDown(failingRepository.dispose);
    addTearDown(failing.dispose);

    await failingRepository.refreshToken();

    expect(failingRepository.token, isNull);
  });

  group('PushRepository.restore', () {
    test(
      'loads stored payloads newest first, as the inbox shows them',
      () async {
        final store = FakePushPayloadStore(
          inbox: [
            payload(id: 'newest'),
            payload(id: 'oldest'),
          ],
        );
        repository = PushRepository(source, store: store);

        await repository.restore();

        expect(repository.messages.map((message) => message.id), [
          'newest',
          'oldest',
        ]);
      },
    );

    test('drains what the background isolate left', () async {
      final store = FakePushPayloadStore(pending: [payload(id: 'background')]);
      repository = PushRepository(source, store: store);

      await repository.restore();

      expect(repository.messages.single.id, 'background');
      expect(store.pending, isEmpty);
    });

    test('keeps a payload once when it is both stored and pending', () async {
      final store = FakePushPayloadStore(
        inbox: [payload(id: 'msg-1')],
        pending: [payload(id: 'msg-1')],
      );
      repository = PushRepository(source, store: store);

      await repository.restore();

      expect(repository.messages, hasLength(1));
    });

    test(
      'persists the merged result, so the drained payload is not lost',
      () async {
        final store = FakePushPayloadStore(
          pending: [payload(id: 'background')],
        );
        repository = PushRepository(source, store: store);

        await repository.restore();

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
      repository = PushRepository(source, store: store);

      await repository.restore();

      expect(repository.messages, isEmpty);
      expect(repository.rejections, hasLength(1));
    });

    test('degrades to an empty inbox when storage fails', () async {
      repository = PushRepository(
        source,
        store: FakePushPayloadStore(loadThrows: true),
      );

      await repository.restore();

      expect(repository.messages, isEmpty);
      expect(repository.setupError, contains('could not be read'));
    });

    test(
      'leaves an existing setup error alone when storage also fails',
      () async {
        repository = PushRepository(
          source,
          store: FakePushPayloadStore(loadThrows: true),
          setupError: 'Firebase is not configured',
        );

        await repository.restore();

        expect(repository.setupError, 'Firebase is not configured');
      },
    );
  });

  group('PushRepository.drainPending', () {
    test('merges a payload that arrived while backgrounded', () async {
      // A fresh source: `source` from setUp is already listened to by the
      // repository built there, and payloads is single-subscription.
      source = FakePushSource();
      final store = FakePushPayloadStore();
      repository = PushRepository(source, store: store)..listen();
      await repository.restore();
      store.pending.add(payload(id: 'while-away'));

      await repository.drainPending();

      expect(repository.messages.single.id, 'while-away');
    });

    test('does not duplicate when drained twice', () async {
      final store = FakePushPayloadStore(pending: [payload(id: 'once')]);
      repository = PushRepository(source, store: store);

      await repository.drainPending();
      await repository.drainPending();

      expect(repository.messages, hasLength(1));
    });

    test('does not save when there was nothing pending', () async {
      final store = FakePushPayloadStore();
      repository = PushRepository(source, store: store);

      await repository.drainPending();

      expect(store.saves, 0);
    });
  });

  group('PushRepository persistence of live messages', () {
    test('persists a payload that arrives on the stream', () async {
      // A fresh source: `source` from setUp is already listened to by the
      // repository built there, and payloads is single-subscription.
      source = FakePushSource();
      final store = FakePushPayloadStore();
      repository = PushRepository(source, store: store)..listen();

      source.emit(payload(id: 'live'));
      await pumpEventQueue();

      expect(store.inbox.single['id'], 'live');
    });
  });

  group('PushRepository disposal', () {
    test('stops consuming the source, so a later payload is dropped', () async {
      // A fresh source: `source` from setUp is already listened to by the
      // repository built there, and payloads is single-subscription.
      source = FakePushSource();
      repository = PushRepository(source, store: FakePushPayloadStore())
        ..listen();

      repository.dispose();
      source.emit(payload(id: 'after-dispose'));
      await pumpEventQueue();

      expect(
        repository.messages,
        isEmpty,
        reason:
            'the app-scoped repository is the only subscriber to a '
            'single-subscription stream, so a subscription left running after '
            'disposal keeps ingesting into an object nothing can see again',
      );
    });
  });

  group('PushRepository cap', () {
    test(
      'keeps only the newest maxStoredMessages and drops the oldest',
      () async {
        // A fresh source: `source` from setUp is already listened to by the
        // repository built there, and payloads is single-subscription.
        source = FakePushSource();
        final store = FakePushPayloadStore();
        repository = PushRepository(source, store: store)..listen();

        for (
          var index = 0;
          index <= PushRepository.maxStoredMessages;
          index++
        ) {
          source.emit(payload(id: 'msg-$index'));
        }
        await pumpEventQueue();

        expect(
          repository.messages,
          hasLength(PushRepository.maxStoredMessages),
        );
        expect(
          repository.messages.first.id,
          'msg-${PushRepository.maxStoredMessages}',
        );
        expect(
          repository.messages.map((message) => message.id),
          isNot(contains('msg-0')),
        );
      },
    );

    test('persists the capped list, not the full history', () async {
      // A fresh source: `source` from setUp is already listened to by the
      // repository built there, and payloads is single-subscription.
      source = FakePushSource();
      final store = FakePushPayloadStore();
      repository = PushRepository(source, store: store)..listen();

      for (var index = 0; index <= PushRepository.maxStoredMessages; index++) {
        source.emit(payload(id: 'msg-$index'));
      }
      await pumpEventQueue();

      expect(store.inbox, hasLength(PushRepository.maxStoredMessages));
    });
  });

  group('PushRepository notifications', () {
    late RecordingNotificationPresenter presenter;

    setUp(() {
      presenter = RecordingNotificationPresenter();
    });

    tearDown(() async {
      await presenter.dispose();
    });

    test('shows a banner for a payload arriving on the stream', () async {
      // A fresh source: `source` from setUp is already listened to by the
      // repository built there, and payloads is single-subscription.
      source = FakePushSource();
      repository = PushRepository(
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
        repository = PushRepository(
          source,
          store: FakePushPayloadStore(inbox: [payload(id: 'old')]),
          presenter: presenter,
        );

        await repository.restore();

        expect(repository.messages, hasLength(1));
        expect(presenter.shown, isEmpty);
      },
    );

    test(
      'shows nothing for a drained payload, which FCM already showed',
      () async {
        repository = PushRepository(
          source,
          store: FakePushPayloadStore(pending: [payload(id: 'background')]),
          presenter: presenter,
        );

        await repository.drainPending();

        expect(repository.messages, hasLength(1));
        expect(presenter.shown, isEmpty);
      },
    );

    test('shows nothing for a payload that fails validation', () async {
      // A fresh source: `source` from setUp is already listened to by the
      // repository built there, and payloads is single-subscription.
      source = FakePushSource();
      repository = PushRepository(
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
      // repository built there, and payloads is single-subscription.
      source = FakePushSource();
      repository = PushRepository(
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

  group('PushRepository.requestOpen', () {
    test('resolves an id the inbox holds', () async {
      repository = PushRepository(
        source,
        store: FakePushPayloadStore(inbox: [payload(id: 'msg-1')]),
      );
      await repository.restore();

      repository.requestOpen('msg-1');

      expect(repository.hasPendingOpen, isTrue);
      expect(repository.pendingOpen?.id, 'msg-1');
    });

    test('stays outstanding but unresolved for an unknown id', () {
      repository = PushRepository(source, store: FakePushPayloadStore());

      repository.requestOpen('never-seen');

      expect(repository.hasPendingOpen, isTrue);
      expect(repository.pendingOpen, isNull);
    });

    test(
      'resolves once the message arrives, whatever the stream order',
      () async {
        // A fresh source: `source` from setUp is already listened to by the
        // repository built there, and payloads is single-subscription.
        source = FakePushSource();
        repository = PushRepository(source, store: FakePushPayloadStore())
          ..listen();

        repository.requestOpen('late');
        expect(repository.pendingOpen, isNull);
        source.emit(payload(id: 'late'));
        await pumpEventQueue();

        expect(repository.pendingOpen?.id, 'late');
      },
    );

    test('notifies listeners so the shell can react', () {
      repository = PushRepository(source, store: FakePushPayloadStore());
      var notifications = 0;
      final watching = repository.changes.listen((_) => notifications++);
      addTearDown(watching.cancel);

      repository.requestOpen('msg-1');

      expect(
        notifications,
        1,
        reason:
            'and inside the call, not a microtask later: the shell routes the '
            'tap from here',
      );
    });

    test('clears, so the shell does not navigate twice', () async {
      repository = PushRepository(
        source,
        store: FakePushPayloadStore(inbox: [payload(id: 'msg-1')]),
      );
      await repository.restore();
      repository.requestOpen('msg-1');

      repository.clearPendingOpen();

      expect(repository.hasPendingOpen, isFalse);
      expect(repository.pendingOpen, isNull);
    });
  });

  group('PushRepository telemetry', () {
    late RecordingPushTelemetry telemetry;

    setUp(() {
      telemetry = RecordingPushTelemetry();
      // A fresh source: `source` from the outer setUp is already listened to by
      // the repository built there, and payloads is single-subscription.
      source = FakePushSource();
    });

    test('records a foreground arrival against the trace id', () async {
      repository = PushRepository(
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
      repository = PushRepository(
        source,
        store: FakePushPayloadStore(),
        telemetry: telemetry,
      )..listen();

      source
        ..emit(payload(id: 'by-hand'))
        ..emit(payload(id: 'msg-2', traceId: 'tr-2'));
      await pumpEventQueue();

      expect(
        repository.messages,
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
      repository = PushRepository(
        source,
        store: FakePushPayloadStore(),
        telemetry: telemetry,
      )..listen();

      source.emit({'id': 'broken', 'trace_id': 'tr-1'});
      await pumpEventQueue();

      expect(repository.rejections, hasLength(1));
      expect(telemetry.types, [TelemetryEventType.receivedFg]);
    });

    test('records both deliveries of a repeated message id', () async {
      // FCM does not promise at-most-once delivery, and two deliveries are two
      // arrivals: the inbox collapses them because it shows messages, while the
      // matrix wants to know it happened. The server is idempotent on
      // (trace, type, device), so the second row costs nothing there.
      repository = PushRepository(
        source,
        store: FakePushPayloadStore(),
        telemetry: telemetry,
      )..listen();

      source
        ..emit(payload(id: 'twice', traceId: 'tr-1'))
        ..emit(payload(id: 'twice', traceId: 'tr-1'));
      await pumpEventQueue();

      expect(repository.messages, hasLength(1));
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
      repository = PushRepository(
        source,
        store: FakePushPayloadStore(
          inbox: [payload(id: 'old', traceId: 'tr-old')],
          pending: [payload(id: 'background', traceId: 'tr-bg')],
        ),
        telemetry: telemetry,
      );

      await repository.restore();

      expect(repository.messages, hasLength(2));
      expect(telemetry.recorded, isEmpty);
    });

    test('records displayed only after show() succeeds', () async {
      // Before it, a presenter that threw would report a notification that was
      // never drawn — and "displayed but not seen" is a conclusion someone would
      // then chase on the device.
      final drawing = Completer<void>();
      final presenter = RecordingNotificationPresenter(gate: drawing.future);
      addTearDown(presenter.dispose);
      repository = PushRepository(
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
      repository = PushRepository(
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
        repository.messages,
        hasLength(1),
        reason: 'and a failed banner still does not cost the message',
      );
    });

    test('records opened when a notification tap is handled', () async {
      repository = PushRepository(
        source,
        store: FakePushPayloadStore(),
        telemetry: telemetry,
      )..listen();
      source.emit(payload(traceId: 'tr-1', scenarioId: 'a1_notification_only'));
      await pumpEventQueue();

      repository.requestOpen('msg-1');
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
      repository = PushRepository(
        source,
        store: FakePushPayloadStore(),
        telemetry: failing,
      )..listen();

      source.emit(payload(traceId: 'tr-1'));
      await pumpEventQueue();
      repository.requestOpen('msg-1');
      await pumpEventQueue();

      expect(repository.messages.single.id, 'msg-1');
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
      repository = PushRepository(
        source,
        store: FakePushPayloadStore(
          pending: [payload(id: 'tapped', traceId: 'tr-1')],
        ),
        telemetry: telemetry,
      );

      repository.requestOpen('tapped');
      await pumpEventQueue();

      expect(
        telemetry.recorded,
        isEmpty,
        reason: 'no payload, no trace id yet',
      );

      await repository.drainPending();

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
      repository = PushRepository(
        source,
        store: FakePushPayloadStore(),
        telemetry: telemetry,
      )..listen();

      repository.requestOpen('never-seen');
      await pumpEventQueue();

      expect(repository.hasPendingOpen, isTrue);
      expect(telemetry.recorded, isEmpty);

      // A different message arriving does not resolve that tap, and tapping
      // this one does record — so the silence above is about the missing
      // payload rather than about a hook that never fires.
      source.emit(payload(id: 'msg-1', traceId: 'tr-1'));
      await pumpEventQueue();
      repository.requestOpen('msg-1');
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
