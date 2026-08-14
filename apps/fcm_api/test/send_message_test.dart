import 'package:fcm_api/fcm_api.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:test/test.dart';

import 'fake_fcm_sender.dart';
import 'store_reading_fcm_sender.dart';
import 'throwing_telemetry_store.dart';

void main() {
  final sentAt = DateTime.utc(2026, 8, 11, 9, 12, 3);

  Future<SendOutcome> run(
    SendMessageRequest request, {
    FcmSender? sender,
    String traceId = 'tr-1',
    TelemetryStore? telemetry,
  }) => sendMessage(
    request,
    sender: sender ?? FakeFcmSender(),
    now: () => sentAt,
    newTraceId: () => traceId,
    telemetry: telemetry ?? InMemoryTelemetryStore(),
  );

  Map<String, Object?> messageIn(FakeFcmSender sender) =>
      sender.sent.single['message']! as Map<String, Object?>;

  Map<String, Object?> dataIn(FakeFcmSender sender) =>
      messageIn(sender)['data']! as Map<String, Object?>;

  SendMessageRequest request({
    SendTarget target = const TokenTarget('device-token'),
    bool validateOnly = false,
    FcmMessage message = const FcmMessage(
      notification: FcmNotification(title: 'Build finished'),
    ),
  }) => SendMessageRequest(
    target: target,
    message: message,
    validateOnly: validateOnly,
  );

  group('sendMessage', () {
    test(
      'reports the message name FCM assigned and its own send time',
      () async {
        final outcome = await run(request());

        final response = (outcome as SendSucceeded).response;
        expect(response.messageId, 'projects/p/messages/0:17');
        expect(response.sentAt, sentAt);
      },
    );

    test('injects the token into the message, which is the target', () async {
      final sender = FakeFcmSender();

      await run(request(), sender: sender);

      final message = sender.sent.single['message']! as Map<String, Object?>;
      expect(message['token'], 'device-token');
    });

    test('forwards the payload as written, adding only the trace id', () async {
      final sender = FakeFcmSender();

      await run(
        request(
          message: FcmMessage.fromJson({
            'data': {'event': 'sync'},
            'android': {'priority': 'HIGH'},
          }),
        ),
        sender: sender,
      );

      final message = messageIn(sender);
      expect(message['data'], {'event': 'sync', 'trace_id': 'tr-1'});
      expect(message['android'], {'priority': 'HIGH'});
      // The server used to invent these. It must not any more.
      expect(message.keys, isNot(contains('notification')));
      expect(dataIn(sender).keys, isNot(contains('id')));
    });

    test('injects a trace id into data, keeping the caller\'s keys', () async {
      final sender = FakeFcmSender();

      await run(
        request(message: const FcmMessage(data: {'event': 'sync'})),
        sender: sender,
      );

      // Compared as a whole map, so this fails if the caller's entry were
      // dropped, renamed or overwritten — not merely if two keys are present.
      expect(dataIn(sender), {'event': 'sync', 'trace_id': 'tr-1'});
      expect(
        dataIn(sender)['event'],
        'sync',
        reason: "the caller's own value must survive injection",
      );
    });

    test('injects it even when the message had no data block', () async {
      // Most of the 66 templates have none, so this is the common path.
      final sender = FakeFcmSender();

      await run(request(message: const FcmMessage()), sender: sender);

      expect(messageIn(sender)['data'], {'trace_id': 'tr-1'});
    });

    test('returns the trace id, so the sender can correlate', () async {
      final outcome = await run(request(message: const FcmMessage()));

      expect((outcome as SendSucceeded).response.traceId, 'tr-1');
    });

    test('the id it puts on the wire is the id it returns', () async {
      // Minting twice — once for the body, once for the response — would put one
      // id in FCM's data map and a different one in the caller's hand, and
      // nothing downstream would ever correlate.
      final sender = FakeFcmSender();
      var minted = 0;

      final outcome = await sendMessage(
        request(),
        sender: sender,
        now: () => sentAt,
        newTraceId: () => 'tr-${++minted}',
        telemetry: InMemoryTelemetryStore(),
      );

      expect(minted, 1, reason: 'minted exactly once per send');
      expect(
        dataIn(sender)['trace_id'],
        (outcome as SendSucceeded).response.traceId,
      );
    });

    test('leaves the caller\'s own data map alone', () async {
      // Verified: FcmMessage.toJson() builds a fresh outer map but passes `data`
      // through by reference, so `toJson()['data']` *is* the caller's map. A
      // careless `data['trace_id'] = id` would rewrite this one in place — and
      // for a mutable map that corrupts silently rather than throwing.
      final callerData = <String, String>{'event': 'sync'};

      await run(request(message: FcmMessage(data: callerData)));

      expect(
        callerData,
        equals(const {'event': 'sync'}),
        reason: 'injection must build a new map, not mutate this one',
      );
    });

    test('sends every catalogue template without disturbing it', () async {
      // The templates are const, and FcmMessage.fromJson copies `data` into an
      // unmodifiable map, so an in-place injection throws here rather than
      // corrupting the gallery for the rest of the process. Either failure mode
      // fails this test, which is the point. The injection really happens: every
      // template goes through sendMessage before it is re-checked.
      for (final scenario in scenarioGallery) {
        final raw = Map<String, Object?>.from(scenario.payloadTemplate);
        final message = FcmMessage.fromJson(raw);
        final sender = FakeFcmSender();

        await run(request(message: message), sender: sender);

        expect(dataIn(sender)['trace_id'], 'tr-1', reason: scenario.id);
        expect(message.toJson(), raw, reason: scenario.id);
        expect(FcmMessage.fromJson(raw).toJson(), raw, reason: scenario.id);
      }
    });

    test('forwards validate_only so FCM checks without delivering', () async {
      final sender = FakeFcmSender();

      await run(request(validateOnly: true), sender: sender);

      expect(sender.sent.single['validate_only'], isTrue);
    });

    test('sends validate_only as false by default', () async {
      final sender = FakeFcmSender();

      await run(request(), sender: sender);

      expect(sender.sent.single['validate_only'], isFalse);
    });

    test('forwards a topic as the delivery target', () async {
      final sender = FakeFcmSender();

      final outcome = await run(
        request(target: const TopicTarget('news'), message: const FcmMessage()),
        sender: sender,
      );

      expect(outcome, isA<SendSucceeded>());
      expect(sender.sent.single['message'], containsPair('topic', 'news'));
    });

    test('refuses all-devices with 501 rather than sending to one', () async {
      final sender = FakeFcmSender();

      final outcome = await run(
        request(target: const AllDevicesTarget()),
        sender: sender,
      );

      expect(outcome, isA<SendRejected>());
      expect((outcome as SendRejected).statusCode, 501);
      expect(outcome.error.field, 'all_devices');
      expect(sender.sent, isEmpty, reason: 'nothing may be sent');
    });

    test('a blank token is still a 400, now via the target reader', () {
      // The guard moved into SendTarget.readFrom; the guarantee did not move.
      expect(
        () => SendMessageRequest.fromJson({
          'token': '  ',
          'message': <String, Object?>{},
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('maps an unregistered token to 404 with wording of its own', () async {
      final sender = FakeFcmSender(
        failure: const FcmSendException(
          status: 'UNREGISTERED',
          message: 'Requested entity was not found.',
        ),
      );

      final outcome = await run(request(), sender: sender);

      expect((outcome as SendRejected).statusCode, 404);
      expect(outcome.error.message, contains('no longer valid'));
    });

    test('maps a rejected argument to 400', () async {
      final sender = FakeFcmSender(
        failure: const FcmSendException(
          status: 'INVALID_ARGUMENT',
          message: 'Invalid value at message.android.ttl.',
        ),
      );

      final outcome = await run(request(), sender: sender);

      expect((outcome as SendRejected).statusCode, 400);
      expect(outcome.error.message, contains('message.android.ttl'));
    });

    test('maps anything else to 502, carrying FCM\'s status', () async {
      final sender = FakeFcmSender(
        failure: const FcmSendException(
          status: 'QUOTA_EXCEEDED',
          message: 'Too many requests.',
        ),
      );

      final outcome = await run(request(), sender: sender);

      expect((outcome as SendRejected).statusCode, 502);
      expect(outcome.error.message, contains('QUOTA_EXCEEDED'));
    });

    group('telemetry', () {
      late InMemoryTelemetryStore store;

      setUp(() => store = InMemoryTelemetryStore());

      test('records queued then sent, in that order', () async {
        await run(request(), telemetry: store);

        expect((await store.all()).map((e) => e.type), [
          TelemetryEventType.queued,
          TelemetryEventType.sent,
        ]);
      });

      test('has queued stored before FCM is called at all', () async {
        // The order in `all()` cannot tell "queued before the send" from "both
        // recorded after it returned" — the store's order is the order it was
        // written in, and one clock reading stamps both, so neither the sequence
        // nor the timestamps distinguish those two implementations. What the
        // store holds at the moment the sender runs does, and that is the whole
        // point of `queued`: a request that never reached FCM has to be
        // distinguishable from one that was never made.
        final sender = StoreReadingFcmSender(store);

        await run(request(), sender: sender, telemetry: store);

        expect(sender.eventsWhenCalled.map((e) => e.type), [
          TelemetryEventType.queued,
        ]);
      });

      test('records the FCM message id on the sent event', () async {
        // What ties our trace to Google's own record of the send. Asserted
        // against a literal distinct from the fake's default, so a detail that
        // came from anywhere but FCM's answer — a constant, the trace id, an
        // empty string — fails here instead of matching by coincidence.
        await run(
          request(),
          sender: FakeFcmSender(messageId: 'projects/p/messages/0:99'),
          telemetry: store,
        );

        final events = await store.all();
        expect(events.last.detail, 'projects/p/messages/0:99');
        expect(
          events.first.detail,
          isNull,
          reason: 'queued knows nothing yet, so it claims nothing',
        );
      });

      test('records queued then send_failed, keeping the error code', () async {
        final sender = FakeFcmSender(
          failure: const FcmSendException(
            status: 'UNREGISTERED',
            message: 'Requested entity was not found.',
          ),
        );

        await run(request(), sender: sender, telemetry: store);

        final events = await store.all();
        expect(events.map((e) => e.type), [
          TelemetryEventType.queued,
          TelemetryEventType.sendFailed,
        ]);
        expect(events.last.detail, 'UNREGISTERED');
        expect(
          events.last.detail,
          isNot(contains('Requested entity')),
          reason: 'the code groups a hundred failures; the prose does not',
        );
      });

      test('all events carry the same trace id and an empty device', () async {
        await run(request(), traceId: 'tr-7', telemetry: store);

        final events = await store.all();
        // Length first: a `for` over an empty list asserts nothing at all.
        expect(events, hasLength(2));
        for (final event in events) {
          expect(event.traceId, 'tr-7');
          expect(
            event.deviceId,
            isEmpty,
            reason: 'server-side events have no device',
          );
          expect(event.at, sentAt);
          expect(event.at.isUtc, isTrue);
        }
      });

      test('a telemetry failure does not fail the send', () async {
        // This tool exists to send pushes. Failing one because the event store
        // was unavailable would be the wrong trade every time.
        final telemetry = ThrowingTelemetryStore();
        final sender = FakeFcmSender();

        final outcome = await run(
          request(),
          sender: sender,
          telemetry: telemetry,
        );

        // `isA<SendSucceeded>` alone would also pass for an implementation that
        // swallowed the store error and skipped the send, so the push itself and
        // the answer built from FCM's reply are checked too.
        expect(sender.sent, hasLength(1), reason: 'the push must still go out');
        final response = (outcome as SendSucceeded).response;
        expect(response.messageId, 'projects/p/messages/0:17');
        expect(response.traceId, 'tr-1');
        expect(
          telemetry.attempts.map((e) => e.type),
          [TelemetryEventType.queued, TelemetryEventType.sent],
          reason: 'a queued that threw must not stop sent being attempted',
        );
      });

      test('records nothing at all for a refused all-devices target', () async {
        // The 501 happens before anything is queued, so a queued event with no
        // matching sent or send_failed row would look like a message lost in
        // flight rather than one never accepted.
        await run(request(target: const AllDevicesTarget()), telemetry: store);

        expect(await store.all(), isEmpty);
      });
    });
  });
}
