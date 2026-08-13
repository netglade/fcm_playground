# Telemetry Pipeline Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Give every send a `trace_id`, record events against it on both sides, and make `sent → received` latency computable per device.

**Architecture:** The API mints the `trace_id` and injects it into `data`, so no payload template changes. Events are a shared model; the API stores them behind a `TelemetryStore` interface whose production implementation is SQLite and whose test implementation is a plain list — so `melos run ci` never touches a native library. The app buffers events in Drift and flushes them to `POST /events`, deleting only on acknowledgement.

**Tech Stack:** Dart pub workspace, melos 8, fvm-pinned Flutter 3.44.8, DCM, `shelf`, `sqlite3` (API), `drift` + `build_runner` (app).

## Global Constraints

- **No `// ignore:` comments in hand-written code, ever.** Generated Drift files are excluded by path instead — see Task 10.
- **No `dart`/`flutter` on `PATH`.** Always `fvm dart` / `fvm flutter`.
- **The only gate is `fvm dart run melos run ci` from the repo root, judged by exit code 0.** Run `fvm dart run melos run format` *before* it. **Capture the status into a variable immediately** (`fvm dart run melos run ci; GATE=$?`) and branch on that — an `echo` in between swallows `$?` and has shipped a red commit on an earlier plan.
- **Commit messages via `git commit -F -` with a stdin heredoc.** Backticks in `-m` get command-substituted by bash; this has mangled a message already.
- **Fatal lints:** `prefer_initializing_formals` (fires even with a default — use `this._field`), `use_null_aware_elements`, `sort_pub_dependencies`, `avoid_print` (use `stdout.writeln`), `directives_ordering`, `unused_import`, `unnecessary_parenthesis`.
- **Fatal DCM:** `number-of-parameters: 5` (counts `super.key`), `source-lines-of-code: 50`, `prefer-match-file-name`, `prefer-single-widget-per-file`, `avoid-returning-widgets`, `always-remove-listener`, `avoid-unnecessary-type-casts`, `prefer-trailing-comma`.
- **`metrics-exclude` covers** `test/**`, `packages/fcm_gallery_shared/lib/src/message/**`, `packages/fcm_gallery_shared/lib/src/scenarios/**`, `apps/fcm_app/lib/sandbox/forms/**`. Nothing else — so `lib/ui/**` and `apps/fcm_api/lib/**` are subject to the 50-line limit.
- **All timestamps UTC.** A latency computed across a device on local time and a server on UTC is out by hours and reads as a delivery fault.
- **Baseline, measured:** `melos run ci` exit 0 — core 20, `fcm_gallery_shared` 193, `fcm_api` 41, `fcm_app` 313.
- **Branch:** cut a fresh one from `feature/fcm-message-contract-impl` at `43b1871`.

**VERIFIED PREREQUISITE, do not re-derive:** on this machine `DynamicLibrary.open('libsqlite3.so')` **fails** and `libsqlite3.so.0` **succeeds** — there is no bare `.so` symlink, because `libsqlite3-dev` is not installed. The `sqlite3` package's default Linux loader uses the bare name, so Task 5 **must** register an override. Task 4 exists so that no test ever depends on this.

---

## File Structure

```
packages/core/lib/src/push_message_parser.dart        MOD  trace_id reserved

packages/fcm_gallery_shared/lib/src/
  telemetry/telemetry_event.dart        NEW  TelemetryEvent
  telemetry/telemetry_event_type.dart   NEW  enum + wire names
  telemetry/latency_row.dart            NEW  what GET /latency returns
  send_message_response.dart            MOD  carries traceId

apps/fcm_api/lib/src/
  telemetry_store.dart                  NEW  interface + latency contract
  in_memory_telemetry_store.dart        NEW  used by every test
  sqlite_telemetry_store.dart           NEW  production, with the .so.0 override
  events_handler.dart                   NEW  POST /events, GET /latency
  api_router.dart                       MOD  the two routes
  send_message.dart                     MOD  mints trace_id, records 3 events
  server_config.dart                    MOD  database path

apps/fcm_app/lib/telemetry/
  device_identity.dart                  NEW  interface
  shared_preferences_device_identity.dart NEW UUID + label
  telemetry_buffer.dart                 NEW  interface
  drift_telemetry_buffer.dart           NEW  Drift implementation
  drift_telemetry_buffer.g.dart         GEN  committed, excluded from lints
  telemetry_reporter.dart               NEW  records + flushes
```

---

### Task 1: The shared event model

**Files:**
- Create: `packages/fcm_gallery_shared/lib/src/telemetry/telemetry_event_type.dart`
- Create: `packages/fcm_gallery_shared/lib/src/telemetry/telemetry_event.dart`
- Modify: `packages/fcm_gallery_shared/lib/fcm_gallery_shared.dart` (two exports; **verify the alphabetical position rather than trusting it** — a stated position was wrong once on the previous plan)
- Test: `packages/fcm_gallery_shared/test/telemetry/telemetry_event_test.dart`

**Interfaces:**
- Produces: `enum TelemetryEventType` with `String get wireName`; `class TelemetryEvent` with `traceId`, `type`, `at`, `deviceId`, `scenarioId`, `detail`, a `toJson`/`fromJson` pair and value equality.

`number-of-parameters: 5` counts every parameter, and `TelemetryEvent` has six — so it is **not** in `metrics-exclude` and a positional constructor would trip DCM. Use a single named constructor and add `packages/fcm_gallery_shared/lib/src/telemetry/**` to `metrics-exclude`, with a comment matching the two entries already there: it mirrors a wire format, so the field count is the shape of the data rather than a design smell.

- [ ] **Step 1: Write the failing test**

```dart
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:test/test.dart';

void main() {
  final event = TelemetryEvent(
    traceId: 'tr-1',
    type: TelemetryEventType.receivedFg,
    at: DateTime.utc(2026, 8, 13, 9, 30),
    deviceId: 'dev-1',
    scenarioId: 'a1_notification_only',
    detail: 'foreground',
  );

  test('round-trips through JSON', () {
    expect(TelemetryEvent.fromJson(event.toJson()), event);
  });

  test('writes snake_case keys, matching the rest of the wire format', () {
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
  });

  test('rejects an unknown type rather than guessing', () {
    expect(
      () => TelemetryEvent.fromJson({
        'trace_id': 'tr-1',
        'type': 'invented',
        'at': '2026-08-13T09:30:00Z',
        'device_id': '',
      }),
      throwsA(isA<FormatException>()),
    );
  });
}
```

- [ ] **Step 2: Run to verify it fails**

`fvm dart test packages/fcm_gallery_shared/test/telemetry/telemetry_event_test.dart` — FAIL, `TelemetryEvent` not found.

- [ ] **Step 3: Implement the enum**

```dart
/// One thing that happened to one message, on either side of the wire.
///
/// The nine values are the whole vocabulary of the telemetry pipeline. Two of
/// them — [dismissed] and the state qualifier on [opened] — cannot be produced
/// yet: they need a delete intent and three-state routing, which are `f6` and
/// `f3`–`f5` of the scenario catalogue's interaction work. They are declared
/// anyway so the wire format and the database schema do not change when that
/// work lands.
enum TelemetryEventType {
  /// The API accepted a send request.
  queued('queued'),

  /// FCM accepted the message, and returned a name for it.
  sent('sent'),

  /// FCM refused it. The error code goes in `detail`.
  sendFailed('send_failed'),

  /// Arrived while the app was in the foreground.
  receivedFg('received_fg'),

  /// Arrived while the app was backgrounded or killed.
  ///
  /// Only ever produced for a `data` payload: a notification-only push is drawn
  /// by the system and never wakes the background handler, so its absence here
  /// is correct rather than a missed event.
  receivedBg('received_bg'),

  /// A local notification was drawn for it.
  displayed('displayed'),

  /// The user tapped it. `detail` carries the app state, once that is known.
  opened('opened'),

  /// The user swiped it away without tapping.
  dismissed('dismissed'),

  /// The user said it never arrived. The only event a human asserts, and the
  /// only evidence available when the interesting answer is silence.
  notReceived('not_received');

  const TelemetryEventType(this.wireName);

  /// The string both sides agree on. Pinned by test to its literal, because a
  /// rename would otherwise show up only as telemetry that stops correlating.
  final String wireName;
}
```

- [ ] **Step 4: Implement the event**

Mirror the house style in `packages/fcm_gallery_shared/lib/src/message/` — const constructor, `factory fromJson`, `toJson` omitting absent fields via the null-aware map entry (`'k': ?v`), written-out `==` and `hashCode`. Force UTC in the constructor body is impossible in a const constructor, so make it non-const and normalise:

```dart
  TelemetryEvent({
    required this.traceId,
    required this.type,
    required DateTime at,
    required this.deviceId,
    this.scenarioId,
    this.detail,
  }) : at = at.toUtc();
```

`prefer_initializing_formals` does **not** fire here, because `at.toUtc()` is a transformation rather than a plain copy — that lint only objects to `this.x = x`.

- [ ] **Step 5: Verify and commit**

`fvm dart run melos run format`, then `fvm dart run melos run ci; GATE=$?`. Report the measured `fcm_gallery_shared` count (baseline 193).

```bash
git add packages analysis_options.yaml
git commit -F -   # feat(shared): add the telemetry event model
```

---

### Task 2: `trace_id` becomes a reserved data key

**Files:**
- Modify: `packages/core/lib/src/push_message_parser.dart`
- Modify: `packages/core/test/push_message_parser_test.dart`

**Interfaces:**
- Consumes: nothing.
- Produces: `PushMessageParser.reservedKeys` now `{'id', 'title', 'body', 'sentAt', 'trace_id'}`. `requiredKeys` is **unchanged**.

Reserved means "not copied into `PushMessage.data`", so the id stops appearing as an "extra data" row in the inbox and the detail page — it is plumbing, not payload. It must **not** join `requiredKeys`: a push sent by hand carries no trace id and must still reach the inbox.

- [ ] **Step 1: Write the failing test**

```dart
  test('keeps trace_id out of the data map, since it is plumbing', () {
    final message = parser.parse({
      'id': 'msg-1',
      'sentAt': '2026-08-13T09:30:00Z',
      'trace_id': 'tr-1',
      'event': 'sync',
    });

    expect(message.data, {'event': 'sync'});
    expect(message.data.containsKey('trace_id'), isFalse);
  });

  test('still parses a push with no trace_id at all', () {
    // A curl send by hand has none, and refusing it would make half this
    // project's testing impossible.
    expect(
      () => parser.parse({'id': 'msg-1', 'sentAt': '2026-08-13T09:30:00Z'}),
      returnsNormally,
    );
  });
```

- [ ] **Step 2–4: Run, implement, verify**

Add `'trace_id'` to `reservedKeys`. Run `fvm dart test packages/core`, then the full gate. Report the measured `core` count (baseline 20).

**Watch for a knock-on:** any existing test asserting the exact contents of `PushMessage.data` for a payload containing `trace_id` will change. Grep `grep -rn "trace_id" packages apps --include=*.dart` and check each.

- [ ] **Step 5: Commit** — `fix(core): treat trace_id as plumbing rather than payload`

---

### Task 3: The API mints `trace_id` and returns it

**Files:**
- Modify: `packages/fcm_gallery_shared/lib/src/send_message_response.dart`
- Modify: `apps/fcm_api/lib/src/send_message.dart`
- Modify: `apps/fcm_api/test/send_message_test.dart`, `apps/fcm_api/test/api_router_test.dart`
- Modify: `packages/fcm_gallery_shared/test/send_message_envelope_test.dart`
- Modify: `apps/fcm_app/lib/ui/send_result_card.dart` and its test, to show the trace id

**Interfaces:**
- Consumes: nothing from Task 1 yet — events come in Task 7.
- Produces: `SendMessageResponse({required messageId, required sentAt, required traceId})`; `sendMessage` takes a new `String Function() newTraceId` parameter so its tests assert exact values rather than matching a pattern, exactly as `now` already works.

The id is merged into the message's `data`, not set beside it:

```dart
  final traceId = newTraceId();
  final message = request.message.toJson();
  final data = {
    ...?message['data'] as Map<String, Object?>?,
    'trace_id': traceId,
  };

  final body = {
    'validate_only': request.validateOnly,
    'message': {...message, 'data': data, ...request.target.toJson()},
  };
```

**`sendMessage` already has 3 parameters and `number-of-parameters` is 5**, so adding one is fine — but the function is close to `source-lines-of-code: 50`. Measure it after the change; if it exceeds, extract the body-building above into a private helper rather than suppressing anything.

- [ ] **Step 1: Write the failing test**

```dart
  test('injects a trace id into data, keeping the caller\'s keys', () async {
    await sendMessage(
      SendMessageRequest(
        target: const TokenTarget('abc'),
        message: FcmMessage(data: const {'event': 'sync'}),
      ),
      sender: sender,
      now: () => DateTime.utc(2026, 8, 13),
      newTraceId: () => 'tr-1',
    );

    final data =
        (sender.sent.single['message']! as Map)['data']! as Map;
    expect(data, {'event': 'sync', 'trace_id': 'tr-1'});
  });

  test('injects it even when the message had no data block', () async {
    // Most of the 66 templates have none, so this is the common path.
    await sendMessage(
      const SendMessageRequest(
        target: TokenTarget('abc'),
        message: FcmMessage(),
      ),
      sender: sender,
      now: () => DateTime.utc(2026, 8, 13),
      newTraceId: () => 'tr-1',
    );

    expect((sender.sent.single['message']! as Map)['data'], {
      'trace_id': 'tr-1',
    });
  });

  test('returns the trace id, so the sender can correlate', () async {
    final outcome = await sendMessage(
      const SendMessageRequest(
        target: TokenTarget('abc'),
        message: FcmMessage(),
      ),
      sender: sender,
      now: () => DateTime.utc(2026, 8, 13),
      newTraceId: () => 'tr-1',
    );

    expect((outcome as SendSucceeded).response.traceId, 'tr-1');
  });

  test('every catalogue template still round-trips after injection', () {
    // Injection happens on the way out, on a copy. If it mutated the template,
    // the const gallery would be corrupted for the rest of the process.
    for (final scenario in scenarioGallery) {
      final raw = Map<String, Object?>.from(scenario.payloadTemplate);
      expect(FcmMessage.fromJson(raw).toJson(), raw, reason: scenario.id);
    }
  });
```

That last test is the important one, and it is cheap: the templates are `const`, so a careless `message['data']!['trace_id'] = …` would mutate shared state and poison every later send in the same process.

- [ ] **Step 2–5: Run, implement, verify, commit** — `feat(api): mint a trace id for every send`

---

### Task 4: `TelemetryStore` and the in-memory implementation

The task that keeps `melos run ci` free of a native library. **Every test in this plan uses this implementation**; the SQLite one is exercised only by the running server and by a test that skips when the library is absent.

**Files:**
- Create: `apps/fcm_api/lib/src/telemetry_store.dart`
- Create: `apps/fcm_api/lib/src/in_memory_telemetry_store.dart`
- Create: `packages/fcm_gallery_shared/lib/src/telemetry/latency_row.dart`
- Modify: the barrels
- Test: `apps/fcm_api/test/in_memory_telemetry_store_test.dart`

**Interfaces:**
- Consumes: `TelemetryEvent` (Task 1).
- Produces:
  ```dart
  abstract interface class TelemetryStore {
    Future<void> record(List<TelemetryEvent> events);
    Future<List<LatencyRow>> latencies();
    Future<void> close();
  }
  ```
  and `LatencyRow({required traceId, required deviceId, required sentAt, required receivedAt, required scenarioId})` with `Duration get latency` and `bool get isSkewed => latency.isNegative`.

**Idempotency is on `(traceId, type, deviceId)`.** A flush that succeeds server-side but fails to be acknowledged is retried, and a duplicated `received_fg` would corrupt the one number this pipeline exists to produce.

**Latency pairs `sent` with the *first* `received_fg` or `received_bg` for that trace and device.** First, not last: a duplicate arrival is a real FCM behaviour and the interesting figure is time-to-first-delivery.

- [ ] **Step 1: Write the failing test**

```dart
  // Shared by the whole file. `sentAt` and `arrivalAt` build the two halves of a
  // latency pair so each test reads as the timeline it is about.
  late InMemoryTelemetryStore store;

  setUp(() => store = InMemoryTelemetryStore());

  TelemetryEvent sentAt(String trace, DateTime at) => TelemetryEvent(
    traceId: trace,
    type: TelemetryEventType.sent,
    at: at,
    deviceId: '',
  );

  TelemetryEvent arrivalAt(String trace, String device, DateTime at) =>
      TelemetryEvent(
        traceId: trace,
        type: TelemetryEventType.receivedFg,
        at: at,
        deviceId: device,
      );

  final event = TelemetryEvent(
    traceId: 'tr-1',
    type: TelemetryEventType.receivedFg,
    at: DateTime.utc(2026, 8, 13, 9, 30),
    deviceId: 'dev-1',
  );

  test('records events and reads them back', () async {
    await store.record([event]);

    expect(await store.all(), [event]);
  });

  test('ignores a duplicate of the same event from the same device', () async {
    // The retry case. Without this the latency is computed twice and any
    // average over it is wrong.
    await store.record([event]);
    await store.record([event]);

    expect(await store.count(), 1);
  });

  test('keeps the same event type from two different devices', () async {
    // The matrix's whole point: two phones receiving one broadcast are two
    // rows, not a duplicate.
    await store.record([
      event,
      TelemetryEvent(
        traceId: event.traceId,
        type: event.type,
        at: event.at,
        deviceId: 'other-device',
      ),
    ]);

    expect(await store.count(), 2);
  });

  test('pairs sent with the first arrival, per device', () async {
    await store.record([
      sentAt('tr-1', DateTime.utc(2026, 8, 13, 9, 0, 0)),
      arrivalAt('tr-1', 'fast', DateTime.utc(2026, 8, 13, 9, 0, 1)),
      arrivalAt('tr-1', 'slow', DateTime.utc(2026, 8, 13, 9, 4, 12)),
    ]);

    final rows = await store.latencies();

    expect(rows, hasLength(2));
    expect(
      rows.firstWhere((r) => r.deviceId == 'fast').latency,
      const Duration(seconds: 1),
    );
    expect(
      rows.firstWhere((r) => r.deviceId == 'slow').latency,
      const Duration(minutes: 4, seconds: 12),
    );
  });

  test('takes the earliest arrival when a message arrives twice', () async {
    await store.record([
      sentAt('tr-1', DateTime.utc(2026, 8, 13, 9, 0, 0)),
      arrivalAt('tr-1', 'dev', DateTime.utc(2026, 8, 13, 9, 0, 5)),
      arrivalAt('tr-1', 'dev', DateTime.utc(2026, 8, 13, 9, 0, 2)),
    ]);

    expect((await store.latencies()).single.latency, const Duration(seconds: 2));
  });

  test('reports a backwards clock as skew rather than as instant delivery', () {
    // Clamping this to zero would turn a measurement error into a false result,
    // and a "1ms on Xiaomi" would discredit every other number here.
    final row = LatencyRow(
      traceId: 'tr-1',
      deviceId: 'dev',
      sentAt: DateTime.utc(2026, 8, 13, 9, 0, 5),
      receivedAt: DateTime.utc(2026, 8, 13, 9, 0, 0),
      scenarioId: null,
    );

    expect(row.isSkewed, isTrue);
    expect(row.latency, const Duration(seconds: -5));
  });

  test('omits a trace with no arrival, rather than reporting it as zero', () async {
    // Not-delivered is a distinct state from delivered-instantly, and the
    // matrix must be able to tell them apart.
    await store.record([sentAt('tr-1', DateTime.utc(2026, 8, 13, 9))]);

    expect(await store.latencies(), isEmpty);
  });
```

- [ ] **Step 2–5: Run, implement, verify, commit** — `feat(api): add the telemetry store and its latency contract`

---

### Task 5: The SQLite implementation

**Files:**
- Modify: `apps/fcm_api/pubspec.yaml` (`sqlite3`, kept alphabetical for `sort_pub_dependencies`)
- Create: `apps/fcm_api/lib/src/sqlite_telemetry_store.dart`
- Test: `apps/fcm_api/test/sqlite_telemetry_store_test.dart`

**THE LIBRARY NAME OVERRIDE IS MANDATORY AND VERIFIED.** On this machine `DynamicLibrary.open('libsqlite3.so')` fails and `libsqlite3.so.0` succeeds, because `libsqlite3-dev` is not installed and there is no bare symlink. The `sqlite3` package's default Linux loader uses the bare name, so without this the server dies at startup:

```dart
/// Points the `sqlite3` package at the versioned library name.
///
/// Verified on this machine: `libsqlite3.so` does not exist — that bare symlink
/// comes from `libsqlite3-dev`, which is not installed — while
/// `libsqlite3.so.0` loads. The package's default Linux loader tries the bare
/// name, so without this override opening a database fails at startup with a
/// message about a missing shared object rather than anything about SQLite.
void useSystemSqlite() {
  open.overrideFor(OperatingSystem.linux, () {
    for (final name in const ['libsqlite3.so', 'libsqlite3.so.0']) {
      try {
        return DynamicLibrary.open(name);
      } on Object {
        continue;
      }
    }
    throw StateError(
      'No SQLite library found. Install libsqlite3-0, or libsqlite3-dev for '
      'the unversioned name.',
    );
  });
}
```

Both names are tried, in that order, so a machine that *does* have the dev package is unaffected.

**The test must skip rather than fail where the library is absent**, or the gate becomes machine-dependent:

```dart
  bool get _hasSqlite {
    try {
      useSystemSqlite();
      sqlite3.openInMemory().dispose();

      return true;
    } on Object {
      return false;
    }
  }

  // A skip, not a failure: the in-memory store from Task 4 is what every other
  // test uses, so a machine without SQLite still verifies all the behaviour —
  // only the storage adapter goes unexercised, and it is the thinnest layer here.
  test('persists across reopening the same file', () async {
    // …
  }, skip: _hasSqlite ? null : 'no system SQLite library');
```

Assert the same behaviours Task 4 pins — idempotency, first-arrival pairing, skew — against the real database, plus one that only a file can show: **events survive closing and reopening**. Use a temporary directory, and delete it in `tearDown`.

- [ ] **Step 1–5: Test first, implement, verify, commit** — `feat(api): store telemetry in SQLite`

---

### Task 6: `POST /events` and `GET /latency`

**Files:**
- Create: `apps/fcm_api/lib/src/events_handler.dart`
- Modify: `apps/fcm_api/lib/src/api_router.dart`
- Test: `apps/fcm_api/test/events_handler_test.dart`, plus additions to `api_router_test.dart`

**Interfaces:**
- Consumes: `TelemetryStore`, `InMemoryTelemetryStore`, `TelemetryEvent`, `LatencyRow`.
- Produces: `ApiRouter({required sender, required now, required TelemetryStore telemetry})` — a new required parameter, so every existing `ApiRouter(...)` construction changes. Find them with `grep -rn 'ApiRouter(' apps --include=*.dart`.

`ApiRouter` will now have 3 constructor parameters against a limit of 5. Fine.

`POST /events` takes a **batch** — `{"events": [ … ]}` — because the client flushes a buffer, and one request per event would multiply the failure surface by the buffer size. It answers `200 {"recorded": n}`, where `n` counts events *newly* stored, so a client can tell a duplicate-suppressed retry from a lost one.

- [ ] **Step 1: Write the failing test**

```dart
  test('records a batch and reports how many were new', () async {
    final response = await post({'events': [eventJson('tr-1'), eventJson('tr-2')]});

    expect(response.statusCode, 200);
    expect(jsonDecode(await response.readAsString()), {'recorded': 2});
  });

  test('reports zero new on a replayed batch, without failing it', () async {
    // The retry path. A 4xx here would make a client that already succeeded
    // retry forever, and a silent 200 with no count would hide a lost flush.
    await post({'events': [eventJson('tr-1')]});

    final again = await post({'events': [eventJson('tr-1')]});

    expect(again.statusCode, 200);
    expect(jsonDecode(await again.readAsString()), {'recorded': 0});
  });

  test('answers 400 for a malformed event, naming the problem', () async {
    final response = await post({'events': [{'type': 'invented'}]});

    expect(response.statusCode, 400);
  });

  test('answers 400 when events is missing or not a list', () async {
    expect((await post({})).statusCode, 400);
    expect((await post({'events': 'nope'})).statusCode, 400);
  });

  test('accepts an event whose trace was never queued here', () async {
    // A curl send by hand produces no `queued` row. Refusing its arrival would
    // hide a real delivery, and the store has no foreign key for this reason.
    final response = await post({'events': [eventJson('never-seen')]});

    expect(response.statusCode, 200);
  });

  test('GET /latency returns one row per trace and device', () async {
    await post({'events': [sentJson('tr-1'), arrivalJson('tr-1', 'dev-a')]});

    final rows = jsonDecode(await (await get('/latency')).readAsString());

    expect(rows, hasLength(1));
    expect((rows as List).single['device_id'], 'dev-a');
  });

  test('a batch is all-or-nothing on a malformed member', () async {
    // Half-storing a batch would leave the client unable to say what to retry.
    await post({'events': [eventJson('tr-good'), {'type': 'invented'}]});

    expect(jsonDecode(await (await get('/latency')).readAsString()), isEmpty);
  });
```

That last one is a real decision, not a nicety: partial success is the worst outcome for a client holding a buffer, because it cannot tell which half to keep.

- [ ] **Step 2–5: Run, implement, verify, commit** — `feat(api): accept telemetry batches and report latency`

---

### Task 7: The API records `queued`, `sent` and `send_failed`

**Files:**
- Modify: `apps/fcm_api/lib/src/send_message.dart`
- Modify: `apps/fcm_api/test/send_message_test.dart`

**Interfaces:**
- Consumes: `TelemetryStore` (Task 4), the trace id from Task 3.
- Produces: `sendMessage` takes `required TelemetryStore telemetry`. **That makes 5 parameters against a limit of 5** — at the boundary, so do not add a sixth without restructuring.

Three events, with `deviceId: ''` because these happen server-side:

- `queued` at entry, timestamped before the FCM call.
- `sent` on success, with `detail` carrying FCM's `messageId`.
- `sendFailed` on failure, with `detail` carrying FCM's error code — the code, not the human message, because that is what groups a hundred failures into three causes.

**`queued` is recorded even when the send then fails**, so a request that never reached FCM is distinguishable from one never made. And recording must not be able to fail the send: wrap it so a store error is logged and swallowed. Losing a telemetry row is a nuisance; failing a push because telemetry was unavailable is a bug in a tool whose purpose is sending pushes.

- [ ] **Step 1: Write the failing test**

```dart
  test('records queued then sent, in that order', () async {
    await sendMessage(request, sender: sender, now: clock, newTraceId: () => 'tr-1', telemetry: store);

    expect(
      (await store.all()).map((e) => e.type),
      [TelemetryEventType.queued, TelemetryEventType.sent],
    );
  });

  test('records the FCM message id on the sent event', () async {
    // What ties our trace to Google's own record of the send.
    await sendMessage(
      request,
      sender: sender,
      now: clock,
      newTraceId: () => 'tr-1',
      telemetry: store,
    );

    final sent = (await store.all()).last;
    expect(sent.detail, sender.messageId);
  });

  test('records queued then send_failed, keeping the error code', () async {
    // The code rather than the message: it is what groups a hundred failures
    // into three causes.
    await sendMessage(
      request,
      sender: FakeFcmSender(failure: const FcmSendException('UNREGISTERED')),
      now: clock,
      newTraceId: () => 'tr-1',
      telemetry: store,
    );

    final events = await store.all();
    expect(events.map((e) => e.type), [
      TelemetryEventType.queued,
      TelemetryEventType.sendFailed,
    ]);
    expect(events.last.detail, 'UNREGISTERED');
  });

  test('all three carry the same trace id and an empty device', () async {
    await sendMessage(
      request,
      sender: sender,
      now: clock,
      newTraceId: () => 'tr-1',
      telemetry: store,
    );

    for (final event in await store.all()) {
      expect(event.traceId, 'tr-1');
      expect(event.deviceId, isEmpty, reason: 'server-side events have no device');
    }
  });

  test('a telemetry failure does not fail the send', () async {
    // This tool exists to send pushes. Failing one because the event store was
    // unavailable would be the wrong trade every time.
    final outcome = await sendMessage(
      request,
      sender: sender,
      now: clock,
      newTraceId: () => 'tr-1',
      telemetry: ThrowingTelemetryStore(),
    );

    expect(outcome, isA<SendSucceeded>());
  });

  test('records nothing at all for a refused all-devices target', () async {
    // The 501 happens before anything is queued, so a queued event with no
    // matching sent or failed row would look like a message lost in flight.
    await sendMessage(
      const SendMessageRequest(target: AllDevicesTarget(), message: FcmMessage()),
      sender: sender,
      now: clock,
      newTraceId: () => 'tr-1',
      telemetry: store,
    );

    expect(await store.all(), isEmpty);
  });
```

- [ ] **Step 2–5: Run, implement, verify, commit** — `feat(api): record the send side of the pipeline`

---

### Task 8: Wire the store into the server

**Files:**
- Modify: `apps/fcm_api/lib/src/server_config.dart`
- Modify: `apps/fcm_api/bin/server.dart`
- Modify: `apps/fcm_api/test/server_config_test.dart`
- Modify: `apps/fcm_api/README.md`

**Interfaces:**
- Consumes: `SqliteTelemetryStore`, `ServerConfig`.
- Produces: `ServerConfig` gains `String databasePath`, from `FCM_TELEMETRY_DB` or defaulting to `fcm-telemetry.sqlite` beside the service-account key — so the two files that must not be committed live together.

**A missing or unwritable database is a configuration failure, so it exits 64** with the reason, exactly as a bad key already does. A server that starts and then silently records nothing is worse than one that refuses to start.

Document in the API README that `/events` makes the loopback binding load-bearing: an unauthenticated *write* endpoint accumulating a queryable store is a different proposition from a stateless relay.

- [ ] **Step 1: Write the failing test**

```dart
  test('defaults the database beside the service-account key', () {
    final config = ServerConfig.fromEnvironment(
      {'GOOGLE_APPLICATION_CREDENTIALS': '/keys/sa.json'},
      readFile: (_) => validKeyJson,
    );

    expect(config.databasePath, '/keys/fcm-telemetry.sqlite');
  });

  test('takes an explicit database path', () {
    final config = ServerConfig.fromEnvironment(
      {
        'GOOGLE_APPLICATION_CREDENTIALS': '/keys/sa.json',
        'FCM_TELEMETRY_DB': '/var/lib/fcm/events.sqlite',
      },
      readFile: (_) => validKeyJson,
    );

    expect(config.databasePath, '/var/lib/fcm/events.sqlite');
  });

  test('rejects a blank explicit path rather than falling back', () {
    // Falling back would put the database somewhere the operator did not ask
    // for, and they would look for their data in the wrong place.
    expect(
      () => ServerConfig.fromEnvironment(
        {'GOOGLE_APPLICATION_CREDENTIALS': '/keys/sa.json', 'FCM_TELEMETRY_DB': '  '},
        readFile: (_) => validKeyJson,
      ),
      throwsA(isA<StateError>()),
    );
  });
```

- [ ] **Step 2–5: Run, implement, verify, commit** — `feat(api): give the server a telemetry database`

**Manual check this task owns:** start the server, `curl` a send, then
`curl -s http://127.0.0.1:8080/latency`. Report whether the `queued`/`sent` rows
appear. This is the first point at which the pipeline is observable, and it needs a
service-account key — so report it as unverified if you have none.

---

### Task 9: Device identity

**Files:**
- Create: `apps/fcm_app/lib/telemetry/device_identity.dart`
- Create: `apps/fcm_app/lib/telemetry/shared_preferences_device_identity.dart`
- Test: `apps/fcm_app/test/telemetry/device_identity_test.dart`

**Interfaces:**
- Produces: `abstract interface class DeviceIdentity { Future<String> id(); Future<String> label(); Future<void> setLabel(String label); }`

**Not Drift.** This is two scalar values, and the app already has the
`SharedPreferencesAsync` pattern in `SharedPreferencesPushPayloadStore` — a database
for two strings would be ceremony. Drift arrives in Task 10 for the event buffer,
which is a genuine append-and-flush queue.

**The id must not be the FCM token.** It rotates on reinstall and clear-data, which
would split one handset into several matrix columns — and `b6_token_refresh` exists
specifically to make that happen. Generate a UUID once and keep it.

Generate it without a new dependency: `DateTime.now().microsecondsSinceEpoch` plus
`Random.secure()` bytes, hex-encoded. A real UUID library would be a dependency for
a value only ever compared for equality.

- [ ] **Step 1: Write the failing test**

```dart
  test('generates an id once and keeps it', () async {
    final first = await identity.id();

    expect(await identity.id(), first);
  });

  test('a fresh install gets a different id', () async {
    // Two handsets must be two columns in the matrix.
    expect(await identity.id(), isNot(await other.id()));
  });

  test('survives a new instance over the same preferences', () async {
    // The id is only useful if it outlives a restart; otherwise every launch is
    // a new device and the matrix grows a column a day.
    final first = await identity.id();

    expect(await SharedPreferencesDeviceIdentity(preferences: prefs).id(), first);
  });

  test('starts with an empty label and keeps what is set', () async {
    // Empty rather than a guess: no automatic value is as useful as "Xiaomi 13"
    // typed by someone who knows which handset is on the desk.
    expect(await identity.label(), isEmpty);

    await identity.setLabel('Xiaomi 13');

    expect(await identity.label(), 'Xiaomi 13');
  });
```

- [ ] **Step 2–5: Run, implement, verify, commit** — `feat(app): give this install a stable identity`

---

### Task 10: Drift, and codegen enters the repo

**The infrastructure task, and the one most likely to break the gate.** Do it alone,
with nothing but the dependency and one trivial table, so a failure here is
unambiguous.

**Files:**
- Modify: `apps/fcm_app/pubspec.yaml` — `drift`, `drift_flutter`; dev: `build_runner`, `drift_dev`. **Alphabetical**, `sort_pub_dependencies` is fatal.
- Modify: root `pubspec.yaml` — a `generate` melos script
- Modify: `analysis_options.yaml` — exclude generated files
- Create: `apps/fcm_app/lib/telemetry/drift_telemetry_buffer.dart` (table + database only)
- Commit: `apps/fcm_app/lib/telemetry/drift_telemetry_buffer.g.dart`

**Three things must all be true or the gate breaks:**

1. **Generated files are committed.** `melos run ci` gains no codegen step, and a
   fresh clone builds without running `build_runner`. The cost is remembering to
   regenerate; the alternative is a gate that fails on a clean checkout.
2. **They are excluded from the analyzer and DCM by path**, because generated code
   will not satisfy this repo's fatal lints and `// ignore_for_file` is forbidden
   here. In `analysis_options.yaml`:
   ```yaml
   analyzer:
     exclude:
       - "**/*.g.dart"
   ```
   and add `**/*.g.dart` to `dart_code_metrics.metrics-exclude`.
3. **`format:check` must not fail on them.** `dart format` output and
   `build_runner` output can disagree. Verify: run codegen, then
   `fvm dart run melos run format:check`. If it fails, run
   `fvm dart run melos run format` and commit the formatted generated file — the
   formatter wins, since the gate runs it.

The melos script:

```yaml
    generate:
      description: Regenerate Drift's database code. Run after changing a table.
      run: fvm dart run build_runner build --delete-conflicting-outputs
      packageFilters:
        dependsOn: drift_dev
```

- [ ] **Step 1: Add the dependencies and the script; run codegen**

`fvm dart run melos bootstrap`, then `fvm dart run melos run generate`. Confirm
`drift_telemetry_buffer.g.dart` appears.

- [ ] **Step 2: Write a test that the database opens and round-trips one row**

Use Drift's in-memory `NativeDatabase.memory()`. **This needs the same native
SQLite the API does**, and `drift_flutter` bundles it for a device but not for the
Dart VM running tests. If `NativeDatabase.memory()` throws on a missing library,
apply the same override Task 5 uses and say so; if it still fails, **stop and report
it** — a Drift buffer that cannot be tested off-device is a design problem worth
raising rather than working around.

- [ ] **Step 3: Verify the gate, including format:check**

`fvm dart run melos run format`, then `fvm dart run melos run ci; GATE=$?`. Report
the measured `fcm_app` count (baseline 313) and confirm the generated file is both
committed and excluded.

- [ ] **Step 4: Commit** — `build(app): add Drift and a codegen step`

---

### Task 11: The event buffer

**Files:**
- Create: `apps/fcm_app/lib/telemetry/telemetry_buffer.dart` (interface)
- Modify: `apps/fcm_app/lib/telemetry/drift_telemetry_buffer.dart`
- Test: `apps/fcm_app/test/telemetry/telemetry_buffer_test.dart`

**Interfaces:**
- Produces:
  ```dart
  abstract interface class TelemetryBuffer {
    Future<void> add(TelemetryEvent event);
    Future<List<TelemetryEvent>> pending({int limit = 200});
    Future<void> forget(List<TelemetryEvent> events);
  }
  ```

`forget` rather than `clear`: events are deleted **only** once the API has
acknowledged them, and only the ones acknowledged. A blanket clear after a partial
flush loses whatever arrived in between.

The `limit` bounds a flush so a device that has been offline for a week does not
attempt one enormous request.

- [ ] **Step 1: Write the failing test**

```dart
  test('keeps events until they are forgotten', () async {
    await buffer.add(first);

    expect(await buffer.pending(), [first]);
    expect(await buffer.pending(), [first], reason: 'reading is not consuming');
  });

  test('forgets only what it is given', () async {
    // A blanket clear after a partial flush loses whatever arrived meanwhile,
    // and events that arrive during a flush are the common case.
    await buffer.add(first);
    await buffer.add(second);

    await buffer.forget([first]);

    expect(await buffer.pending(), [second]);
  });

  test('bounds a flush, so a week offline is not one huge request', () async {
    for (var i = 0; i < 250; i++) {
      await buffer.add(eventNumbered(i));
    }

    expect(await buffer.pending(limit: 200), hasLength(200));
  });

  test('returns events oldest first, so latency is computed in order', () async {
    await buffer.add(eventAt(DateTime.utc(2026, 8, 13, 9, 5)));
    await buffer.add(eventAt(DateTime.utc(2026, 8, 13, 9, 1)));

    expect(
      (await buffer.pending()).map((e) => e.at),
      [DateTime.utc(2026, 8, 13, 9, 1), DateTime.utc(2026, 8, 13, 9, 5)],
    );
  });

  test('round-trips every field, including a null scenario and detail', () async {
    // The nullable columns are where a hand-written mapper goes wrong, and a
    // dropped trace_id would make the event uncorrelatable.
  });
```

- [ ] **Step 2–5: Run codegen if the table changed, implement, verify, commit** — `feat(app): buffer telemetry events locally`

---

### Task 12: The reporter — record and flush

**Files:**
- Create: `apps/fcm_app/lib/telemetry/telemetry_reporter.dart`
- Test: `apps/fcm_app/test/telemetry/telemetry_reporter_test.dart`

**Interfaces:**
- Consumes: `TelemetryBuffer`, `DeviceIdentity`, an HTTP client.
- Produces: `TelemetryReporter({required buffer, required identity, required baseUrl, http.Client? client})` with `Future<void> record(TelemetryEventType type, {required String traceId, String? scenarioId, String? detail})` and `Future<void> flush()`.

`record` stamps the time and the device id so no caller has to remember either, and
**never throws** — a hook that can throw would take down the push handler it is
attached to.

**Flush policy:** on app resume, after each `record`, and never in the background
isolate. Events are forgotten only on a `200`.

- [ ] **Step 1: Write the failing test**

```dart
  test('stamps the device id and a UTC time', () async {
    // Stamped centrally so no hook has to remember either, and so a hook cannot
    // record a local-time event that reads as hours of latency.
    await reporter.record(TelemetryEventType.receivedFg, traceId: 'tr-1');

    final recorded = (await buffer.pending()).single;
    expect(recorded.deviceId, await identity.id());
    expect(recorded.at.isUtc, isTrue);
  });

  test('keeps events when the flush fails, and retries them later', () async {
    // The whole reason for a buffer. Silently dropping telemetry is worse than
    // sending it late, because the missing row looks like a missing delivery.
    client.failNext();
    await reporter.record(TelemetryEventType.receivedFg, traceId: 'tr-1');

    expect(await buffer.pending(), hasLength(1));

    client.succeed();
    await reporter.flush();

    expect(await buffer.pending(), isEmpty);
  });

  test('forgets events only on a 200', () async {
    client.respondWith(500);

    await reporter.flush();

    expect(await buffer.pending(), hasLength(1));
  });

  test('keeps an event that arrives during a flush', () async {
    // The race `forget(events)` exists to survive: a blanket clear would lose it.
  });

  test('never throws out of record, whatever the buffer does', () async {
    // record() is called from inside push handlers. A throw there would take
    // down delivery itself, which is a strictly worse outcome than lost telemetry.
    final reporter = TelemetryReporter(
      buffer: ThrowingBuffer(),
      identity: identity,
      baseUrl: 'http://127.0.0.1:8080',
      client: client,
    );

    await expectLater(
      reporter.record(TelemetryEventType.receivedFg, traceId: 'tr-1'),
      completes,
    );
  });

  test('does not flush when there is nothing pending', () async {
    await reporter.flush();

    expect(client.requests, isEmpty);
  });
```

- [ ] **Step 2–5: Run, implement, verify, commit** — `feat(app): record and flush telemetry`

---

### Task 13: The four hooks in the push pipeline

**Files:**
- Modify: `apps/fcm_app/lib/push/firebase_push_source.dart` (`receivedFg`, `receivedBg`)
- Modify: `apps/fcm_app/lib/notifications/local_notification_presenter.dart` (`displayed`)
- Modify: `apps/fcm_app/lib/push/push_inbox.dart` or the tap path (`opened`)
- Modify: `apps/fcm_app/lib/main.dart` (construct the reporter and pass it in)
- Modify: the corresponding tests

**The trace id comes from `data.trace_id` on the received message.** A push with no
trace id — one sent by hand — records nothing rather than inventing an id, because a
fabricated trace would appear in the matrix as a message nobody sent.

**`receivedBg` writes to the buffer and does not flush.** The background handler
runs in its own isolate and can be killed at any moment; a half-completed HTTP
request there loses the event it was trying to save.

**Every hook must be optional.** `PushInbox` already defaults its presenter to a
silent one; do the same for the reporter, so every existing test keeps working
without a fake and the diff stays additive.

- [ ] **Step 1: Write the failing test**

```dart
  test('records a foreground arrival against the trace id', () async {
    source.emit({
      'id': 'msg-1',
      'sentAt': '2026-08-13T09:30:00Z',
      'trace_id': 'tr-1',
    });
    await pumpEventQueue();

    expect(
      reporter.recorded.map((e) => (e.type, e.traceId)),
      [(TelemetryEventType.receivedFg, 'tr-1')],
    );
  });

  test('records nothing for a push with no trace id', () async {
    // A hand-made curl send has none. Inventing one would put a message nobody
    // sent into the matrix.
  });

  test('records a background arrival without flushing', () async {
    // The isolate can die mid-request, and the event would die with it.
    expect(reporter.flushes, isZero);
  });

  test('records displayed only after show() succeeds', () async {
    // Before it, a presenter that threw would report a notification that was
    // never drawn — and "displayed but not seen" is a conclusion someone would
    // then chase on the device.
  });

  test('records opened when a notification tap is handled', () async {
    source.emit({
      'id': 'msg-1',
      'sentAt': '2026-08-13T09:30:00Z',
      'trace_id': 'tr-1',
    });
    await pumpEventQueue();

    inbox.requestOpen('msg-1');
    await pumpEventQueue();

    expect(
      reporter.recorded.map((e) => e.type),
      contains(TelemetryEventType.opened),
    );
  });
```

- [ ] **Step 2–5: Run, implement, verify, commit** — `feat(app): report what happens to a push`

---

### Task 14: The "it never arrived" button

**Files:**
- Create: `apps/fcm_app/lib/ui/not_received_button.dart`
- Modify: `apps/fcm_app/lib/ui/sandbox_view.dart` or `send_result_card.dart`
- Test: `apps/fcm_app/test/ui/not_received_button_test.dart`

The only event a human asserts, and the only evidence available when the
interesting answer is silence. It appears after a send, against that send's trace
id, and once pressed it says so rather than staying pressable — a second press would
record a second `not_received` for one message and inflate the count.

- [ ] **Step 1: Write the failing test**

```dart
  testWidgets('appears only after a send', (tester) async {
    // Before a send there is no trace id to report against, and a button that
    // records nothing is worse than no button.
    await pump(tester);
    expect(find.byType(NotReceivedButton), findsNothing);

    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(find.byType(NotReceivedButton), findsOne);
  });

  testWidgets('records not_received against the sent trace id', (tester) async {
    await pump(tester);
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(NotReceivedButton));
    await tester.pumpAndSettle();

    expect(reporter.recorded.single.type, TelemetryEventType.notReceived);
    expect(reporter.recorded.single.traceId, sender.sent.single.traceId);
  });

  testWidgets('cannot be pressed twice for one send', (tester) async {
    // Two rows for one message would inflate the only count a human produces.
    await tester.tap(find.byType(NotReceivedButton));
    await tester.pumpAndSettle();

    expect(
      tester.widget<TextButton>(find.byType(TextButton)).onPressed,
      isNull,
    );
    expect(reporter.recorded, hasLength(1));
  });
```

- [ ] **Step 2–5: Run, implement, verify, commit** — `feat(app): let the user report a push that never came`

---

### Task 15: Verify and document

- [ ] **Step 1: The gate and both builds**

`fvm dart run melos run ci; GATE=$?` — 0, with every package's count reported as
measured. From `apps/fcm_app`: `fvm flutter build apk --debug` and
`fvm flutter build web --release`.

**Drift on web is a real risk worth isolating:** `drift_flutter`'s native database
does not exist there. If the web build fails, report it — the fix is a conditional
database implementation, and that is a decision rather than a detail.

- [ ] **Step 2: Document**

In the root `README.md`, a **Telemetry** section: `trace_id` minted by the API and
injected into `data`; the nine events and which two are not yet capturable and why;
the `sent → received` latency and that a negative value means clock skew rather than
instant delivery; the device id and its label; and that events buffer locally and
survive a failed flush.

In `apps/fcm_api/README.md`: the two endpoints, the batch shape, the idempotency
key, and that `/events` makes the loopback binding load-bearing.

**Also a short "Independent confirmation" subsection**, because it is the one part of
the telemetry design that needs no code from us and is the only check on our own
numbers: FCM can export delivery data to BigQuery, where Google reports how many
messages it dropped and why — `DROPPED_DEVICE_INACTIVE`,
`DROPPED_TOO_MANY_MESSAGES`. Enabled in the Firebase console under Cloud Messaging,
not here. Document that it exists, what it answers that we cannot (whether a message
we never saw arrive was dropped by Google or by the handset), and that it is the
arbiter when our own telemetry and a tester disagree.

State the counts and build results as measured.

- [ ] **Step 3: Commit** — `docs: describe the telemetry pipeline`

- [ ] **Step 4: The verifications that need a human**

Neither can run here. Report each as verified or unverified; never assume.

1. **End to end on a device:** send a scenario, confirm `GET /latency` shows a row
   whose latency is plausible, then repeat with the app backgrounded and killed.
   The killed case is the one that matters and the one that needs `b3_killed`'s
   delayed send to arrange properly.
2. **Two devices, one send:** the point of the whole pipeline. Send to a topic both
   have subscribed to — which needs the targeting sub-project — or send twice by
   token, and confirm two rows with different latencies and different labels.

## Verification summary

| Task | Deliverable | Test |
| --- | --- | --- |
| 1 | `TelemetryEvent`, `TelemetryEventType` | JSON round-trip, wire names, forced UTC |
| 2 | `trace_id` reserved | absent from `data`, still optional |
| 3 | API mints and returns it | injected, templates unmutated |
| 4 | store + latency contract | idempotency, first-arrival, skew, not-delivered |
| 5 | SQLite implementation | same behaviours, plus reopening; skips without the library |
| 6 | `/events`, `/latency` | batch, replay, malformed, all-or-nothing |
| 7 | send-side events | order, error code, telemetry cannot fail a send |
| 8 | server wiring | default and explicit database path |
| 9 | device identity | stable, distinct, survives restart |
| 10 | Drift + codegen | gate stays green with generated files committed |
| 11 | buffer | forgets only what it is given, bounded, ordered |
| 12 | reporter | keeps on failure, forgets on 200, never throws |
| 13 | four hooks | no trace id means no event; background does not flush |
| 14 | not-received button | one press per send |
| 15 | docs, builds | gate 0, apk + web |

## Notes for the implementer

- **`melos run ci` must never need a native SQLite.** That is why Task 4 exists and
  why Task 5's test skips. If you find yourself making the gate depend on
  `libsqlite3`, stop — the in-memory store is the one every test should use.
- **Never let telemetry fail the thing it observes.** A store error must not fail a
  send, and a buffer error must not fail a push handler. Both have explicit tests.
- **`at` is UTC, always.** Assert `isUtc` wherever an event is constructed from
  outside.
- **A missing `trace_id` means record nothing.** Not a generated one — a fabricated
  trace shows up in the matrix as a message nobody sent, which is worse than a gap.
- **Assert `isA<int>()` beside any integer value, never instead of it.** Dart's
  `5.0 == 5` is `true`, so `expect(x, 5)` alone passes on a double. This bit the
  previous plan twice.
- **Generated files:** if you change a Drift table, run `fvm dart run melos run
  generate` and commit the result. A stale `.g.dart` fails in ways that look like a
  logic bug.
