import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:test/test.dart';

/// The one event every test here is about, with a hook for changing exactly one
/// field.
///
/// The defaults are the single source of truth for that event, so a variant used
/// to prove `==` discriminates cannot silently drift away from the baseline it
/// is compared against.
TelemetryEvent eventWith({
  String traceId = 'tr-1',
  TelemetryEventType type = TelemetryEventType.receivedFg,
  DateTime? at,
  String deviceId = 'dev-1',
  String? scenarioId = 'a1_notification_only',
  String? detail = 'foreground',
}) => TelemetryEvent(
  traceId: traceId,
  type: type,
  at: at ?? DateTime.utc(2026, 8, 13, 9, 30),
  deviceId: deviceId,
  scenarioId: scenarioId,
  detail: detail,
);

void main() {
  final event = eventWith();

  test('round-trips through JSON', () {
    final decoded = TelemetryEvent.fromJson(event.toJson());

    expect(decoded, event);
    expect(decoded.hashCode, event.hashCode);

    // Field by field as well as by value equality: the equality below is what
    // makes the comparison above mean anything, so a field it forgot would
    // otherwise let a toJson that dropped that field still "round-trip".
    expect(decoded.traceId, 'tr-1');
    expect(decoded.type, TelemetryEventType.receivedFg);
    expect(decoded.at, DateTime.utc(2026, 8, 13, 9, 30));
    expect(decoded.at.isUtc, isTrue);
    expect(decoded.deviceId, 'dev-1');
    expect(decoded.scenarioId, 'a1_notification_only');
    expect(decoded.detail, 'foreground');
  });

  test('two events differing in exactly one field are not equal', () {
    // Directly what the round-trip above leans on. An `==` blind to `detail`
    // would make that test pass over a toJson that never wrote it.
    final variants = <String, TelemetryEvent>{
      'traceId': eventWith(traceId: 'tr-2'),
      'type': eventWith(type: TelemetryEventType.receivedBg),
      'at': eventWith(at: DateTime.utc(2026, 8, 13, 9, 31)),
      'deviceId': eventWith(deviceId: 'dev-2'),
      'scenarioId': eventWith(scenarioId: null),
      'detail': eventWith(detail: null),
    };

    for (final variant in variants.entries) {
      expect(variant.value, isNot(event), reason: variant.key);
    }
  });

  test('writes snake_case keys, matching the rest of the wire format', () {
    // The values, not only the names: a toJson writing `device_id` under
    // `trace_id` would satisfy a key-only assertion.
    expect(event.toJson(), {
      'trace_id': 'tr-1',
      'type': 'received_fg',
      'at': '2026-08-13T09:30:00.000Z',
      'device_id': 'dev-1',
      'scenario_id': 'a1_notification_only',
      'detail': 'foreground',
    });

    // Key *order* is not a wire requirement — both sides read by name. This is
    // the strictest way to say "exactly these six keys, no more and no fewer",
    // which is the part that matters.
    expect(event.toJson().keys, [
      'trace_id',
      'type',
      'at',
      'device_id',
      'scenario_id',
      'detail',
    ]);
  });

  test('every type has a distinct wire name, pinned to its literal', () {
    // Pinned to literals on purpose: both sides agree on these strings, and a
    // renamed enum value that silently changed the wire format would only show
    // up as telemetry that stops correlating.
    expect(
      {for (final t in TelemetryEventType.values) t: t.wireName},
      {
        TelemetryEventType.queued: 'queued',
        TelemetryEventType.sent: 'sent',
        TelemetryEventType.sendFailed: 'send_failed',
        TelemetryEventType.receivedFg: 'received_fg',
        TelemetryEventType.receivedBg: 'received_bg',
        TelemetryEventType.displayed: 'displayed',
        TelemetryEventType.opened: 'opened',
        TelemetryEventType.dismissed: 'dismissed',
        TelemetryEventType.notReceived: 'not_received',
      },
    );

    expect(
      TelemetryEventType.values.map((t) => t.wireName).toSet(),
      hasLength(TelemetryEventType.values.length),
      reason: 'two types sharing a wire name would be indistinguishable',
    );
  });

  test('keeps the timestamp in UTC, whatever it was given', () {
    // A device on local time and a server on UTC produce a latency out by hours,
    // which reads as a delivery fault rather than a bug here.
    final local = TelemetryEvent(
      traceId: 'tr-1',
      type: TelemetryEventType.sent,
      at: DateTime(2026, 8, 13, 9, 30),
      deviceId: '',
    );

    expect(local.at.isUtc, isTrue);
    expect(local.toJson()['at'], endsWith('Z'));

    // And it is the same INSTANT, not the same wall clock. Reinterpreting 09:30
    // local as 09:30 UTC satisfies both assertions above — measured: both are
    // isUtc, both serialise with Z, and they are two hours apart on a CEST
    // machine — which is exactly the error this field exists to prevent.
    //
    // Compared as epoch milliseconds because that states the invariant directly:
    // toUtc() changes the representation and preserves the instant, while a
    // wall-clock reinterpretation does the opposite.
    //
    // Inherent limit, stated rather than hidden: at offset zero the two are the
    // same value, so this cannot discriminate in a UTC environment. Nothing can —
    // the bug is unobservable there. The isUtc and Z assertions carry it instead.
    final input = DateTime(2026, 8, 13, 9, 30);
    expect(local.at.millisecondsSinceEpoch, input.millisecondsSinceEpoch);
  });

  test('omits the optional fields rather than writing null', () {
    final bare = TelemetryEvent(
      traceId: 'tr-1',
      type: TelemetryEventType.queued,
      at: DateTime.utc(2026),
      deviceId: '',
    );

    expect(bare.toJson().containsKey('scenario_id'), isFalse);
    expect(bare.toJson().containsKey('detail'), isFalse);

    // The required four are still there: an implementation that wrote nothing
    // at all would pass the two assertions above.
    expect(bare.toJson(), {
      'trace_id': 'tr-1',
      'type': 'queued',
      'at': '2026-01-01T00:00:00.000Z',
      'device_id': '',
    });
    expect(TelemetryEvent.fromJson(bare.toJson()), bare);
  });

  test('rejects an unknown type rather than guessing', () {
    const json = {
      'trace_id': 'tr-1',
      'type': 'invented',
      'at': '2026-08-13T09:30:00Z',
      'device_id': '',
    };

    expect(
      () => TelemetryEvent.fromJson(json),
      throwsA(
        isA<FormatException>().having(
          (e) => e.message,
          'message',
          allOf(contains('type'), contains('invented')),
        ),
      ),
    );

    // The control: the same body with a known type parses. Without it the
    // assertion above would be satisfied by a FormatException thrown for some
    // unrelated reason, and the type check could be missing entirely.
    expect(
      TelemetryEvent.fromJson({...json, 'type': 'sent'}).type,
      TelemetryEventType.sent,
    );
  });
}
