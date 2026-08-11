# Notification Display Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make a received push behave like a notification and not only an inbox row — a banner while the app is in use, a heads-up tray entry while it is away, an inbox that survives a restart, and a tap that lands on a message detail page.

**Architecture:** `apps/fcm_app` gains two seams alongside the existing `PushSource` one: a `PushPayloadStore` over `SharedPreferencesAsync` with a separate append-only key for the background isolate, and a `NotificationPresenter` over `flutter_local_notifications`. `PushInbox` grows persistence (`restore`, `drainPending`, a 100-message cap) and one navigation hook (`requestOpen`/`pendingOpen`); `AppShell` listens to that hook and pushes a new `MessageDetailPage`, which an inbox row also opens. No other package changes.

**Tech Stack:** Dart 3.12.2 (fvm-pinned), Flutter 3.44.8, `shared_preferences ^2.5.5`, `shared_preferences_platform_interface ^2.4.2` (dev), `flutter_local_notifications ^22.3.0`, melos 8, DCM.

**Spec:** `docs/superpowers/specs/2026-08-11-notification-display-design.md`

**Branch:** `feature/notification-display`, off `main` at `03dad2f`.

## Global Constraints

Every task's requirements implicitly include this section.

- **Run everything through `fvm`.** There is no `dart` on PATH. `fvm dart pub get` from the repo root; `fvm flutter test <path>` from inside `apps/fcm_app`.
- **`fvm dart run melos run ci` from the repo root is the gate.** It runs format:check, analyze, dcm, then every test suite. Check its **exit code**; it must exit 0 before any commit. Running analyze and dcm separately is not sufficient — that is how an unformatted file slipped through twice in the previous plan.
- If format:check complains, run `fvm dart run melos run format` from the repo root rather than hand-wrapping lines.
- **Baseline before Task 1:** `apps/fcm_app` has 49 tests; `core` 20, `fcm_gallery_shared` 41, `fcm_api` 44. A bare `fvm flutter test` is reliable — its live reporter overwrites one status line while suites run concurrently, which can look like skipped files, but the final `+N` is authoritative.
- **Fatal lints** (`--fatal-infos --fatal-warnings`): `prefer_single_quotes`, `require_trailing_commas`, `sort_pub_dependencies` (dependencies strictly alphabetical), `prefer_final_locals`, `prefer_final_in_for_each`, `always_declare_return_types`, `unnecessary_parenthesis`, `unawaited_futures`, `use_super_parameters`, `cancel_subscriptions`, `close_sinks`, **`prefer_initializing_formals`** (never write `: _field = param`; use `required this._field` — the public parameter name drops the underscore, so call sites still read `Foo(field: …)`. An initializer list *is* correct when the value is not a plain copy, e.g. `_x = x ?? Default()`), and `avoid_print` (use `debugPrint`).
- **Analyzer strictness:** `strict-casts`, `strict-inference`, `strict-raw-types` all on. No raw `Map`/`List` in a type position.
- **Fatal DCM metrics:** `source-lines-of-code: 50` per function, `number-of-parameters: 5` (**counts named parameters and `super.key`**), `maximum-nesting-level: 5`, `cyclomatic-complexity: 15`. Excluded under `test/**`.
- **Fatal DCM rules:** `prefer-match-file-name` (a file's name must match its first public **type**, snake_case; a file of only top-level functions has no type to match and is fine — `lib/sandbox/http_notification_sender.dart` and `packages/fcm_gallery_shared/lib/src/json_field.dart` are the existing precedents), `prefer-single-widget-per-file` (one *widget* class per file; a private `State` class beside its `StatefulWidget` is fine), `avoid-returning-widgets` (**no `Widget _buildFoo()` methods** — build inline, or extract a widget class), `always-remove-listener`, `use-setstate-synchronously`, `avoid-unused-parameters` (name a deliberately unused parameter `_`), `newline-before-return`, `prefer-trailing-comma`, `no-empty-block`, `prefer-correct-type-name`, `avoid-collection-methods-with-unrelated-types`.
- **Doc comments on every public declaration**, including getters, top-level constants and sealed-class variants. Say *why*, not *what*. `packages/core/lib/src/push_message.dart`, `apps/fcm_app/lib/push/push_source.dart` and `apps/fcm_app/lib/sandbox/sandbox_controller.dart` are the reference for the voice.
- **No `// ignore:` comments.** There are none in this repository and a review will reject one. If a lint fires, fix the code it points at.
- **`SharedPreferencesAsync`, never the legacy `SharedPreferences`.** The legacy API caches per isolate and the background message handler runs in its own engine instance, so a cached UI-side snapshot would never see what the background isolate appended and every untapped background push would be silently lost. This is the single most important correctness constraint in this plan.
- **Test naming:** descriptive sentences, `group` per unit. Match `apps/fcm_app/test/push_inbox_test.dart`.
- **Commit style:** Conventional Commits, scope `app` (`feat(app):`, `refactor(app):`, `docs:`).

## File Structure

**New — `apps/fcm_app/lib/push/`**

| File | Responsibility |
| --- | --- |
| `remote_message_payload.dart` | `remoteMessageToPayload()` — the one flattening both isolates use |
| `push_payload_store.dart` | `PushPayloadStore` interface |
| `shared_preferences_push_payload_store.dart` | Its `SharedPreferencesAsync` implementation |

**New — `apps/fcm_app/lib/notifications/`**

| File | Responsibility |
| --- | --- |
| `notification_presenter.dart` | `NotificationPresenter` interface |
| `notification_content.dart` | Pure: `PushMessage` → notification id, channel, title, body |
| `local_notification_presenter.dart` | `flutter_local_notifications` implementation |
| `silent_notification_presenter.dart` | No-op, for tests and the failure path |

**New — `apps/fcm_app/lib/ui/`**

| File | Responsibility |
| --- | --- |
| `message_detail_page.dart` | `MessageDetailPage` — one message in full, its own `Scaffold` |

**Modified**

| File | Change |
| --- | --- |
| `lib/push/firebase_push_source.dart` | Uses the shared flattening; adds `taps` from `onMessageOpenedApp`; sets iOS foreground presentation options |
| `lib/push/push_source.dart` | Gains `Stream<String> get taps` |
| `lib/push/disabled_push_source.dart` | `taps` returns an empty stream |
| `lib/push/push_inbox.dart` | Store, `restore`, `drainPending`, the `notify` rule, `requestOpen`/`pendingOpen`/`clearPendingOpen` |
| `lib/ui/message_tile.dart` | Gains `onTap` |
| `lib/ui/inbox_view.dart` | Pushes the detail page on a row tap |
| `lib/ui/app_shell.dart` | Listens for `pendingOpen`; drains pending on resume |
| `lib/main.dart` | Builds the store and presenter, wires both tap streams, calls `restore()` |
| `android/app/src/main/AndroidManifest.xml` | `default_notification_channel_id` meta-data |
| `pubspec.yaml` | Two dependencies and one dev dependency |
| `README.md` | A "Notifications" section and an updated verification list |

**Test doubles** — `test/fake_push_payload_store.dart` (in-memory `PushPayloadStore`) and `test/recording_notification_presenter.dart` (records `show` calls, emits taps on demand). `test/fake_push_source.dart` gains `emitTap`.

**Why `notification_content.dart` is split out:** `flutter_local_notifications` offers no seam to intercept a `show` call, so the plugin-facing implementation cannot be unit-tested. Keeping the *decisions* — the integer notification id, the channel, which text goes where — in a pure file means the only untested code is three plugin calls with no branching.

---

### Task 1: Extract the payload flattening

A pure refactor, done first because both isolates need the result.

**Files:**
- Create: `apps/fcm_app/lib/push/remote_message_payload.dart`
- Modify: `apps/fcm_app/lib/push/firebase_push_source.dart`
- Test: `apps/fcm_app/test/remote_message_payload_test.dart`

**Interfaces:**
- Consumes: nothing.
- Produces: `Map<String, Object?> remoteMessageToPayload(RemoteMessage message)` — the flat map `PushMessageParser` expects.

- [ ] **Step 1: Write the failing test**

`apps/fcm_app/test/remote_message_payload_test.dart`:

```dart
import 'package:fcm_app/push/remote_message_payload.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('remoteMessageToPayload', () {
    test('takes the title and body from the notification block', () {
      final payload = remoteMessageToPayload(
        const RemoteMessage(
          messageId: 'msg-1',
          notification: RemoteNotification(
            title: 'Build finished',
            body: 'Release 1.0.0 is ready.',
          ),
        ),
      );

      expect(payload['id'], 'msg-1');
      expect(payload['title'], 'Build finished');
      expect(payload['body'], 'Release 1.0.0 is ready.');
    });

    test('lets the data map win, so a data-only push is fully supported', () {
      final payload = remoteMessageToPayload(
        const RemoteMessage(
          messageId: 'from-fcm',
          data: {'id': 'from-data', 'title': 'Data title'},
          notification: RemoteNotification(title: 'Notification title'),
        ),
      );

      expect(payload['id'], 'from-data');
      expect(payload['title'], 'Data title');
    });

    test('passes extra data keys through untouched', () {
      final payload = remoteMessageToPayload(
        const RemoteMessage(data: {'deepLink': '/builds/42'}),
      );

      expect(payload['deepLink'], '/builds/42');
    });

    test('normalises sentTime to a UTC ISO-8601 string', () {
      final payload = remoteMessageToPayload(
        RemoteMessage(sentTime: DateTime.utc(2026, 8, 11, 9, 30)),
      );

      expect(payload['sentAt'], '2026-08-11T09:30:00.000Z');
    });

    test('falls back to now when the message carries no sentTime', () {
      final before = DateTime.now().toUtc();

      final payload = remoteMessageToPayload(const RemoteMessage());

      final sentAt = DateTime.parse(payload['sentAt']! as String);
      expect(sentAt.isBefore(before), isFalse);
      expect(sentAt.isUtc, isTrue);
    });

    test('substitutes blanks rather than nulls, so the parser names the field', () {
      final payload = remoteMessageToPayload(const RemoteMessage());

      expect(payload['id'], '');
      expect(payload['title'], '');
      expect(payload['body'], '');
    });
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run from `apps/fcm_app`: `fvm flutter test test/remote_message_payload_test.dart`
Expected: FAIL — `Target of URI doesn't exist: 'package:fcm_app/push/remote_message_payload.dart'`.

- [ ] **Step 3: Write the function**

`apps/fcm_app/lib/push/remote_message_payload.dart`:

```dart
import 'package:firebase_messaging/firebase_messaging.dart';

/// Flattens a [RemoteMessage] into the flat map `PushMessageParser` expects.
///
/// A top-level function rather than a method on the source, because the
/// background isolate needs exactly this mapping too — and a second copy of it
/// would let the foreground and background paths drift apart.
///
/// The notification block supplies defaults; anything in `data` wins, since a
/// data-only push is the case worth supporting well. Missing fields become
/// blanks rather than nulls, so the parser rejects them by name instead of
/// throwing on a null.
Map<String, Object?> remoteMessageToPayload(RemoteMessage message) => {
  'id': message.messageId ?? '',
  'title': message.notification?.title ?? '',
  'body': message.notification?.body ?? '',
  'sentAt': (message.sentTime ?? DateTime.now()).toUtc().toIso8601String(),
  ...message.data,
};
```

- [ ] **Step 4: Use it from `FirebasePushSource`**

In `apps/fcm_app/lib/push/firebase_push_source.dart`, add the import
`import 'remote_message_payload.dart';`, change `_emit` to:

```dart
  void _emit(RemoteMessage message) =>
      _controller.add(remoteMessageToPayload(message));
```

and **delete the private `_toPayload` method entirely**, including its doc
comment — that comment's content now lives on the top-level function.

- [ ] **Step 5: Run the tests to verify they pass**

Run from `apps/fcm_app`: `fvm flutter test test/remote_message_payload_test.dart test/inbox_view_test.dart test/push_inbox_test.dart`
Expected: PASS — 6 new tests, and the existing inbox and push tests unaffected.

- [ ] **Step 6: Run the gate and commit**

Run from the repo root: `fvm dart run melos run ci`
Expected: exit 0, 55 `fcm_app` tests.

```bash
git add apps/fcm_app
git commit -m "refactor(app): extract remoteMessageToPayload for both isolates"
```

---

### Task 2: The payload store

**Files:**
- Create: `apps/fcm_app/lib/push/push_payload_store.dart`
- Create: `apps/fcm_app/lib/push/shared_preferences_push_payload_store.dart`
- Create: `apps/fcm_app/test/fake_push_payload_store.dart`
- Modify: `apps/fcm_app/pubspec.yaml`
- Test: `apps/fcm_app/test/push_payload_store_test.dart`

**Interfaces:**
- Consumes: nothing.
- Produces:
  - `abstract interface class PushPayloadStore` with `Future<List<Map<String, Object?>>> loadInbox()`, `Future<void> saveInbox(List<Map<String, Object?>> payloads)`, `Future<void> appendPending(Map<String, Object?> payload)`, `Future<List<Map<String, Object?>>> takePending()`
  - `class SharedPreferencesPushPayloadStore implements PushPayloadStore` — `SharedPreferencesPushPayloadStore({SharedPreferencesAsync? preferences})`
  - `class FakePushPayloadStore implements PushPayloadStore` (test double) with mutable `inbox` and `pending` lists

- [ ] **Step 1: Add the dependencies**

In `apps/fcm_app/pubspec.yaml`. `sort_pub_dependencies` is fatal, so the lists must end up strictly alphabetical:

```yaml
dependencies:
  core:
    path: ../../packages/core
  cupertino_icons: ^1.0.8
  fcm_gallery_shared:
    path: ../../packages/fcm_gallery_shared
  firebase_core: ^4.13.0
  firebase_messaging: ^16.5.0
  flutter:
    sdk: flutter
  http: ^1.6.0
  shared_preferences: ^2.5.5

dev_dependencies:
  flutter_lints: ^6.0.0
  flutter_test:
    sdk: flutter
  shared_preferences_platform_interface: ^2.4.2
```

`shared_preferences_platform_interface` is a dev dependency because only the
store's test imports it, for the in-memory platform double.

Run from the repo root: `fvm dart pub get`
Expected: succeeds.

- [ ] **Step 2: Write the failing test**

`apps/fcm_app/test/push_payload_store_test.dart`:

```dart
import 'package:fcm_app/push/shared_preferences_push_payload_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  late SharedPreferencesPushPayloadStore store;

  Map<String, Object?> payload(String id) => {
    'id': id,
    'title': 'Build finished',
    'body': 'main #128 passed',
    'sentAt': '2026-08-11T09:30:00.000Z',
  };

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    store = SharedPreferencesPushPayloadStore();
  });

  group('the inbox key', () {
    test('starts empty', () async {
      expect(await store.loadInbox(), isEmpty);
    });

    test('round-trips payloads in the order they were saved', () async {
      await store.saveInbox([payload('a'), payload('b')]);

      final loaded = await store.loadInbox();

      expect(loaded.map((entry) => entry['id']), ['a', 'b']);
      expect(loaded.first['title'], 'Build finished');
    });

    test('replaces rather than appends, so the cap the caller applied holds', () async {
      await store.saveInbox([payload('a'), payload('b')]);

      await store.saveInbox([payload('c')]);

      expect((await store.loadInbox()).map((entry) => entry['id']), ['c']);
    });
  });

  group('the pending key', () {
    test('starts empty', () async {
      expect(await store.takePending(), isEmpty);
    });

    test('accumulates appended payloads', () async {
      await store.appendPending(payload('a'));
      await store.appendPending(payload('b'));

      expect((await store.takePending()).map((entry) => entry['id']), [
        'a',
        'b',
      ]);
    });

    test('clears on take, so a payload cannot be drained twice', () async {
      await store.appendPending(payload('a'));

      await store.takePending();

      expect(await store.takePending(), isEmpty);
    });

    test('is independent of the inbox key', () async {
      await store.saveInbox([payload('kept')]);

      await store.appendPending(payload('pending'));
      await store.takePending();

      expect((await store.loadInbox()).single['id'], 'kept');
    });
  });

  group('corruption', () {
    test('skips an entry that is not JSON and keeps the rest', () async {
      await SharedPreferencesAsync().setStringList('push.inbox', [
        'not json at all',
        '{"id":"good","title":"t","body":"b","sentAt":"2026-08-11T09:30:00.000Z"}',
      ]);

      final loaded = await store.loadInbox();

      expect(loaded.single['id'], 'good');
    });

    test('skips an entry that is JSON but not an object', () async {
      await SharedPreferencesAsync().setStringList('push.inbox', ['[1,2,3]']);

      expect(await store.loadInbox(), isEmpty);
    });
  });
}
```

- [ ] **Step 3: Run the test to verify it fails**

Run from `apps/fcm_app`: `fvm flutter test test/push_payload_store_test.dart`
Expected: FAIL — `Target of URI doesn't exist: 'package:fcm_app/push/shared_preferences_push_payload_store.dart'`.

- [ ] **Step 4: Write the interface**

`apps/fcm_app/lib/push/push_payload_store.dart`:

```dart
/// Where received payloads are kept so the inbox survives a restart.
///
/// Two collections rather than one, because two isolates write here: the UI
/// isolate owns the inbox, and the background message handler only ever appends
/// to the pending list. Neither reads-modifies-writes the other's collection, so
/// a push arriving mid-write cannot be lost.
///
/// Raw payload maps are stored rather than parsed messages, so there is one
/// format on disk and `PushMessageParser` stays the only thing that validates.
abstract interface class PushPayloadStore {
  /// Payloads kept from earlier sessions, in the order they were saved.
  Future<List<Map<String, Object?>>> loadInbox();

  /// Replaces the kept payloads. The caller has already applied the cap.
  Future<void> saveInbox(List<Map<String, Object?>> payloads);

  /// Appends one payload. Called **only** from the background isolate.
  Future<void> appendPending(Map<String, Object?> payload);

  /// Returns the pending payloads and clears them, so none is drained twice.
  Future<List<Map<String, Object?>>> takePending();
}
```

- [ ] **Step 5: Write the implementation**

`apps/fcm_app/lib/push/shared_preferences_push_payload_store.dart`:

```dart
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'push_payload_store.dart';

/// A [PushPayloadStore] over `shared_preferences`.
///
/// Uses [SharedPreferencesAsync] rather than the legacy `SharedPreferences` for
/// a reason that is load-bearing, not stylistic: the legacy API keeps an
/// in-memory cache per isolate, and the background message handler runs in its
/// own engine instance. A cached UI-side snapshot would never see what the
/// background isolate appended, so every untapped background push would be
/// silently lost. This API holds no cache and reads platform storage each call.
class SharedPreferencesPushPayloadStore implements PushPayloadStore {
  SharedPreferencesPushPayloadStore({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _preferences;

  @override
  Future<List<Map<String, Object?>>> loadInbox() => _read(_inboxKey);

  @override
  Future<void> saveInbox(List<Map<String, Object?>> payloads) => _preferences
      .setStringList(_inboxKey, payloads.map(jsonEncode).toList());

  @override
  Future<void> appendPending(Map<String, Object?> payload) async {
    final stored =
        await _preferences.getStringList(_pendingKey) ?? const <String>[];

    await _preferences.setStringList(_pendingKey, [
      ...stored,
      jsonEncode(payload),
    ]);
  }

  @override
  Future<List<Map<String, Object?>>> takePending() async {
    final payloads = await _read(_pendingKey);
    await _preferences.remove(_pendingKey);

    return payloads;
  }

  Future<List<Map<String, Object?>>> _read(String key) async {
    final stored = await _preferences.getStringList(key) ?? const <String>[];
    final payloads = <Map<String, Object?>>[];
    for (final entry in stored) {
      final decoded = _decodePayload(entry);
      if (decoded != null) {
        payloads.add(decoded);
      }
    }

    return payloads;
  }
}

/// Namespaced so a future preference cannot collide with them.
const _inboxKey = 'push.inbox';
const _pendingKey = 'push.pending';

/// Decodes one stored entry, or null when it is not a JSON object.
///
/// One corrupt entry must not cost the whole inbox, so it is skipped and logged
/// rather than thrown.
Map<String, Object?>? _decodePayload(String entry) {
  try {
    final decoded = jsonDecode(entry);
    if (decoded is! Map<String, Object?>) {
      debugPrint('Dropping a stored payload that is not an object: $entry');

      return null;
    }

    return decoded;
  } on FormatException catch (error) {
    debugPrint('Dropping a corrupt stored payload: ${error.message}');

    return null;
  }
}
```

- [ ] **Step 6: Write the test double**

`apps/fcm_app/test/fake_push_payload_store.dart`:

```dart
import 'package:fcm_app/push/push_payload_store.dart';

/// A [PushPayloadStore] held in memory, so no test touches platform channels.
class FakePushPayloadStore implements PushPayloadStore {
  FakePushPayloadStore({
    List<Map<String, Object?>>? inbox,
    List<Map<String, Object?>>? pending,
    this.loadThrows = false,
  }) : inbox = inbox ?? [],
       pending = pending ?? [];

  /// The saved inbox, readable by the test to assert what was persisted.
  List<Map<String, Object?>> inbox;

  /// The queue the background isolate would have appended to.
  List<Map<String, Object?>> pending;

  /// When true, [loadInbox] fails — used to check the inbox degrades instead of
  /// stopping the app from opening.
  final bool loadThrows;

  /// How many times [saveInbox] was called, so a test can prove the inbox was
  /// persisted rather than only held in memory.
  int saves = 0;

  @override
  Future<List<Map<String, Object?>>> loadInbox() async {
    if (loadThrows) {
      throw StateError('no storage');
    }

    return List.of(inbox);
  }

  @override
  Future<void> saveInbox(List<Map<String, Object?>> payloads) async {
    inbox = List.of(payloads);
    saves++;
  }

  @override
  Future<void> appendPending(Map<String, Object?> payload) async =>
      pending.add(payload);

  @override
  Future<List<Map<String, Object?>>> takePending() async {
    final taken = List.of(pending);
    pending.clear();

    return taken;
  }
}
```

- [ ] **Step 7: Run the test to verify it passes**

Run from `apps/fcm_app`: `fvm flutter test test/push_payload_store_test.dart`
Expected: PASS, 9 tests.

- [ ] **Step 8: Run the gate and commit**

Run from the repo root: `fvm dart run melos run ci`
Expected: exit 0, 64 `fcm_app` tests.

```bash
git add apps/fcm_app pubspec.lock
git commit -m "feat(app): add a cross-isolate payload store"
```

---

### Task 3: Make the inbox durable

The largest change to existing code in this plan.

**Files:**
- Modify: `apps/fcm_app/lib/push/push_inbox.dart`
- Modify: `apps/fcm_app/test/push_inbox_test.dart`
- Modify: `apps/fcm_app/test/inbox_view_test.dart` (constructor call sites only)
- Modify: `apps/fcm_app/test/app_shell_test.dart` (constructor call sites only)
- Modify: `apps/fcm_app/lib/main.dart` (constructor call site and `restore()`)

**Interfaces:**
- Consumes: `PushPayloadStore`, `FakePushPayloadStore` (Task 2).
- Produces, on `PushInbox`:
  - `PushInbox(PushSource source, {required PushPayloadStore store, String? setupError})` — note `store` is now **required**
  - `static const int maxStoredMessages = 100`
  - `Future<void> restore()` — load, drain, de-duplicate, cap, save
  - `Future<void> drainPending()` — merge what the background isolate left
  - `String? get setupError` — now a getter over a mutable field, so a storage failure can surface in the existing banner
  - `void _ingest(Map<String, Object?> payload)` — private; Task 4 gives it a `notify` parameter

**Ordering, stated once so it cannot be got wrong:** `messages` is newest-first, and the store holds payloads in that same order. `restore` therefore feeds the stored list **reversed** (oldest first) through `_ingest`, because each `_ingest` inserts at index 0. The pending list is appended oldest-to-newest by the background isolate, so it is fed **as-is**.

- [ ] **Step 1: Write the failing tests**

Add to `apps/fcm_app/test/push_inbox_test.dart`. Keep every existing test; they only need `store:` added to their `PushInbox(...)` calls (Step 3 covers that).

```dart
  group('PushInbox.restore', () {
    test('loads stored payloads newest first, as the inbox shows them', () async {
      final store = FakePushPayloadStore(
        inbox: [payload(id: 'newest'), payload(id: 'oldest')],
      );
      inbox = PushInbox(source, store: store);

      await inbox.restore();

      expect(inbox.messages.map((message) => message.id), [
        'newest',
        'oldest',
      ]);
    });

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

    test('persists the merged result, so the drained payload is not lost', () async {
      final store = FakePushPayloadStore(pending: [payload(id: 'background')]);
      inbox = PushInbox(source, store: store);

      await inbox.restore();

      expect(store.saves, 1);
      expect(store.inbox.single['id'], 'background');
    });

    test('counts a malformed stored payload as a rejection', () async {
      final store = FakePushPayloadStore(inbox: [{'id': 'broken'}]);
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

    test('leaves an existing setup error alone when storage also fails', () async {
      inbox = PushInbox(
        source,
        store: FakePushPayloadStore(loadThrows: true),
        setupError: 'Firebase is not configured',
      );

      await inbox.restore();

      expect(inbox.setupError, 'Firebase is not configured');
    });
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
    test('keeps only the newest maxStoredMessages and drops the oldest', () async {
      final store = FakePushPayloadStore();
      inbox = PushInbox(source, store: store)..listen();

      for (var index = 0; index <= PushInbox.maxStoredMessages; index++) {
        source.emit(payload(id: 'msg-$index'));
      }
      await pumpEventQueue();

      expect(inbox.messages, hasLength(PushInbox.maxStoredMessages));
      expect(inbox.messages.first.id, 'msg-${PushInbox.maxStoredMessages}');
      expect(inbox.messages.map((message) => message.id), isNot(contains('msg-0')));
    });

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
```

The file already has the helper these tests use, at the top:
`Map<String, Object?> payload({String id = 'msg-1', String title = 'Hello'})`.
Leave it as it is. Add `import 'fake_push_payload_store.dart';` to the imports.

`pumpEventQueue()` comes from `flutter_test` and is how the stream delivery plus
the fire-and-forget save settle before the assertion.

- [ ] **Step 2: Run the tests to verify they fail**

Run from `apps/fcm_app`: `fvm flutter test test/push_inbox_test.dart`
Expected: FAIL — `No named parameter with the name 'store'`.

- [ ] **Step 3: Rewrite `PushInbox`**

`apps/fcm_app/lib/push/push_inbox.dart` becomes exactly:

```dart
import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter/foundation.dart';

import 'push_payload_store.dart';
import 'push_source.dart';

/// Holds the messages received so far and exposes them to the UI.
///
/// Parsing lives in `core`; this class owns the subscription, the ordering, the
/// de-duplication and the persistence that the widget tree cares about.
class PushInbox extends ChangeNotifier {
  PushInbox(this._source, {required this._store, this._setupError});

  /// How many messages are kept, newest first. A bound exists so a long-lived
  /// install cannot grow the stored list without limit; 100 is far more than the
  /// sample needs and still decodes instantly at launch.
  static const maxStoredMessages = 100;

  final PushSource _source;
  final PushPayloadStore _store;
  final _parser = const PushMessageParser();
  final _accepted = <_AcceptedPush>[];
  final _rejections = <String>[];
  final _seenIds = <String>{};
  StreamSubscription<Map<String, Object?>>? _subscription;
  String? _setupError;
  String? _token;

  /// Why push is unavailable, or `null` when everything started cleanly.
  ///
  /// Mutable behind a getter because a storage failure discovered during
  /// [restore] belongs in the same banner as a Firebase failure.
  String? get setupError => _setupError;

  /// Received messages, newest first, with repeated ids dropped — FCM does not
  /// guarantee at-most-once delivery.
  List<PushMessage> get messages =>
      List.unmodifiable(_accepted.map((push) => push.message));

  /// Payloads that failed validation, oldest first. Kept so a malformed push is
  /// visible in the UI instead of being silently swallowed.
  List<String> get rejections => List.unmodifiable(_rejections);

  /// The device's registration token once [refreshToken] has resolved.
  String? get token => _token;

  /// Begins consuming [PushSource.payloads].
  void listen() {
    _subscription = _source.payloads.listen(_onLivePayload);
  }

  /// Loads the kept messages and everything the background isolate left.
  ///
  /// Called once before the first frame. A storage failure surfaces in
  /// [setupError] rather than throwing — persistence failing must not stop the
  /// app from opening, the same principle `main()` already applies to Firebase.
  Future<void> restore() async {
    try {
      final stored = await _store.loadInbox();
      final pending = await _store.takePending();
      // Stored payloads are newest first and each ingest inserts at the front,
      // so they go in reversed. Pending payloads were appended oldest first.
      for (final payload in stored.reversed) {
        _ingest(payload);
      }
      for (final payload in pending) {
        _ingest(payload);
      }
      await _save();
    } catch (error) {
      _setupError ??= 'Stored pushes could not be read: $error';
      notifyListeners();
    }
  }

  /// Merges anything the background isolate appended since the last drain.
  ///
  /// Called again whenever the UI resumes, because a push arriving while the app
  /// was merely backgrounded would otherwise sit unseen until a restart.
  Future<void> drainPending() async {
    final pending = await _store.takePending();
    if (pending.isEmpty) {
      return;
    }

    for (final payload in pending) {
      _ingest(payload);
    }
    await _save();
  }

  /// Fetches the registration token, ignoring failures — a missing token is
  /// worth showing as absent, not as a crash.
  Future<void> refreshToken() async {
    try {
      _token = await _source.token();
    } catch (error) {
      debugPrint('Could not read FCM token: $error');
      _token = null;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }

  void _onLivePayload(Map<String, Object?> payload) {
    _ingest(payload);
    // Fire and forget: the stream handler is synchronous, and a failed write
    // must not break delivery to the UI.
    unawaited(_save());
  }

  void _ingest(Map<String, Object?> payload) {
    try {
      final message = _parser.parse(payload);
      if (_seenIds.add(message.id)) {
        _accepted.insert(0, _AcceptedPush(message, payload));
        if (_accepted.length > maxStoredMessages) {
          // The evicted id stays in _seenIds, so a re-delivery cannot resurrect
          // it mid-session. A restart rebuilds the set from what was kept, which
          // is the only way an evicted message can reappear.
          _accepted.removeLast();
        }
      }
    } on PushMessageFormatException catch (error) {
      _rejections.add('$error');
    }
    notifyListeners();
  }

  Future<void> _save() =>
      _store.saveInbox(_accepted.map((push) => push.payload).toList());
}

/// One accepted push: the parsed message the UI shows, beside the raw payload
/// that produced it, which is what gets persisted.
///
/// One object rather than two parallel lists, so the message and its payload
/// cannot drift out of step as the cap trims them.
class _AcceptedPush {
  const _AcceptedPush(this.message, this.payload);

  final PushMessage message;
  final Map<String, Object?> payload;
}
```

- [ ] **Step 4: Update the other call sites**

Three files construct a `PushInbox` and now need a store.

In `apps/fcm_app/test/inbox_view_test.dart` and `apps/fcm_app/test/app_shell_test.dart`, add
`import 'fake_push_payload_store.dart';` and give every `PushInbox(source …)`
call a `store: FakePushPayloadStore()`. Change nothing else — those tests are the
regression net for the inbox's existing behaviour.

In `apps/fcm_app/lib/main.dart`, add `import 'push/push_payload_store.dart';` and
`import 'push/shared_preferences_push_payload_store.dart';`, then replace

```dart
  final inbox = PushInbox(source, setupError: setupError)..listen();
  await inbox.refreshToken();
```

with

```dart
  final PushPayloadStore store = SharedPreferencesPushPayloadStore();
  final inbox = PushInbox(source, store: store, setupError: setupError)
    ..listen();
  await inbox.restore();
  await inbox.refreshToken();
```

`restore()` runs before `refreshToken()` so the first frame already has the kept
messages.

- [ ] **Step 5: Run the tests to verify they pass**

Run from `apps/fcm_app`: `fvm flutter test test/push_inbox_test.dart test/inbox_view_test.dart test/app_shell_test.dart`
Expected: PASS — the 13 new tests plus every pre-existing one.

- [ ] **Step 6: Run the gate and commit**

Run from the repo root: `fvm dart run melos run ci`
Expected: exit 0, 77 `fcm_app` tests.

```bash
git add apps/fcm_app
git commit -m "feat(app): persist the inbox across restarts"
```

---

### Task 4: The presenter seam and the never-re-notify rule

**Files:**
- Create: `apps/fcm_app/lib/notifications/notification_presenter.dart`
- Create: `apps/fcm_app/lib/notifications/silent_notification_presenter.dart`
- Create: `apps/fcm_app/test/recording_notification_presenter.dart`
- Modify: `apps/fcm_app/lib/push/push_inbox.dart`
- Test: `apps/fcm_app/test/push_inbox_test.dart`

**Interfaces:**
- Consumes: `PushInbox` and its private `_ingest` (Task 3).
- Produces:
  - `abstract interface class NotificationPresenter` with `Future<void> initialize()`, `Future<void> show(PushMessage message)`, `Stream<String> get taps`, `Future<void> dispose()`
  - `class SilentNotificationPresenter implements NotificationPresenter` — `const SilentNotificationPresenter()`
  - `class RecordingNotificationPresenter implements NotificationPresenter` (test double) with `List<PushMessage> shown`, `bool initialized`, `void emitTap(String id)`
  - `PushInbox(PushSource source, {required PushPayloadStore store, NotificationPresenter presenter = const SilentNotificationPresenter(), String? setupError})`

**The rule this task exists for:** only payloads arriving on the live stream are shown as banners. Restored and drained payloads never are, because FCM's own SDK already drew those tray entries while the app was away — re-notifying them would replay every old notification at once on launch.

The presenter parameter **defaults to `SilentNotificationPresenter`** so no existing widget test needs touching; `main()` passes the real one.

- [ ] **Step 1: Write the test double**

`apps/fcm_app/test/recording_notification_presenter.dart`:

```dart
import 'dart:async';

import 'package:core/core.dart';
import 'package:fcm_app/notifications/notification_presenter.dart';

/// A [NotificationPresenter] that records instead of notifying.
class RecordingNotificationPresenter implements NotificationPresenter {
  /// Every message a banner was requested for, in order.
  final shown = <PushMessage>[];

  final _taps = StreamController<String>.broadcast();

  /// Whether [initialize] ran, so a test can prove the app set the channel up.
  bool initialized = false;

  @override
  Stream<String> get taps => _taps.stream;

  @override
  Future<void> initialize() async {
    initialized = true;
  }

  @override
  Future<void> show(PushMessage message) async => shown.add(message);

  /// Acts as though the user tapped the banner for [id].
  void emitTap(String id) => _taps.add(id);

  @override
  Future<void> dispose() => _taps.close();
}
```

- [ ] **Step 2: Write the failing tests**

Add to `apps/fcm_app/test/push_inbox_test.dart`, with
`import 'recording_notification_presenter.dart';`:

```dart
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

    test('shows nothing for a restored payload, which FCM already showed', () async {
      inbox = PushInbox(
        source,
        store: FakePushPayloadStore(inbox: [payload(id: 'old')]),
        presenter: presenter,
      );

      await inbox.restore();

      expect(inbox.messages, hasLength(1));
      expect(presenter.shown, isEmpty);
    });

    test('shows nothing for a drained payload, which FCM already showed', () async {
      inbox = PushInbox(
        source,
        store: FakePushPayloadStore(pending: [payload(id: 'background')]),
        presenter: presenter,
      );

      await inbox.drainPending();

      expect(inbox.messages, hasLength(1));
      expect(presenter.shown, isEmpty);
    });

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
```

- [ ] **Step 3: Run the tests to verify they fail**

Run from `apps/fcm_app`: `fvm flutter test test/push_inbox_test.dart`
Expected: FAIL — `No named parameter with the name 'presenter'`.

- [ ] **Step 4: Write the interface**

`apps/fcm_app/lib/notifications/notification_presenter.dart`:

```dart
import 'package:core/core.dart';

/// Shows a received push as an operating-system notification.
///
/// The same shape of seam as `PushSource`: an interface, one implementation over
/// a plugin, and a do-nothing stand-in — so the widget tests never construct
/// `flutter_local_notifications`.
///
/// Only foreground arrivals reach [show]. While the app is backgrounded, FCM's
/// own SDK draws the tray entry, so anything restored from storage has already
/// been notified once and must not be notified again.
abstract interface class NotificationPresenter {
  /// Creates the notification channel and starts listening for taps.
  Future<void> initialize();

  /// Posts a banner for a message that has just arrived in the foreground.
  Future<void> show(PushMessage message);

  /// Ids of messages whose banner the user tapped.
  Stream<String> get taps;

  /// Releases the tap stream.
  Future<void> dispose();
}
```

- [ ] **Step 5: Write the silent implementation**

`apps/fcm_app/lib/notifications/silent_notification_presenter.dart`:

```dart
import 'package:core/core.dart';

import 'notification_presenter.dart';

/// A [NotificationPresenter] that never shows anything.
///
/// The default in widget tests, and the fallback when the notification plugin
/// fails to initialise — a broken plugin should cost the banners, not the app.
/// The same role `DisabledPushSource` plays on the receiving side.
class SilentNotificationPresenter implements NotificationPresenter {
  const SilentNotificationPresenter();

  @override
  Future<void> initialize() => Future<void>.value();

  @override
  Future<void> show(PushMessage _) => Future<void>.value();

  @override
  Stream<String> get taps => const Stream.empty();

  @override
  Future<void> dispose() => Future<void>.value();
}
```

The unused parameter is named `_` because DCM's `avoid-unused-parameters` is
fatal; the signature still satisfies the interface, since only types matter.

- [ ] **Step 6: Wire it into `PushInbox`**

Four edits to `apps/fcm_app/lib/push/push_inbox.dart`:

1. Add the imports:

```dart
import '../notifications/notification_presenter.dart';
import '../notifications/silent_notification_presenter.dart';
```

2. Replace the constructor:

```dart
  PushInbox(
    this._source, {
    required this._store,
    this._presenter = const SilentNotificationPresenter(),
    this._setupError,
  });
```

**Measured, not assumed:** `prefer_initializing_formals` fires even when the
parameter carries a default value — a default does not stop the assignment being a
plain copy — so an initializer list is *not* usable here. A private initializing
formal takes the default directly, and Dart strips the underscore for the public
parameter name, so every existing call site still reads
`PushInbox(source, store: …, setupError: …)` unchanged.

3. Add the field beside `_store`:

```dart
  final NotificationPresenter _presenter;
```

4. Give `_ingest` the flag and pass it from all three callers:

```dart
  void _onLivePayload(Map<String, Object?> payload) {
    _ingest(payload, notify: true);
    // Fire and forget: the stream handler is synchronous, and a failed write
    // must not break delivery to the UI.
    unawaited(_save());
  }

  void _ingest(Map<String, Object?> payload, {required bool notify}) {
    try {
      final message = _parser.parse(payload);
      if (_seenIds.add(message.id)) {
        _accepted.insert(0, _AcceptedPush(message, payload));
        if (_accepted.length > maxStoredMessages) {
          // The evicted id stays in _seenIds, so a re-delivery cannot resurrect
          // it mid-session. A restart rebuilds the set from what was kept, which
          // is the only way an evicted message can reappear.
          _accepted.removeLast();
        }
        if (notify) {
          unawaited(_presenter.show(message));
        }
      }
    } on PushMessageFormatException catch (error) {
      _rejections.add('$error');
    }
    notifyListeners();
  }
```

and in `restore()` and `drainPending()` change every `_ingest(payload)` to
`_ingest(payload, notify: false)`.

- [ ] **Step 7: Run the tests to verify they pass**

Run from `apps/fcm_app`: `fvm flutter test test/push_inbox_test.dart`
Expected: PASS — the 5 new tests plus everything already there.

- [ ] **Step 8: Run the gate and commit**

Run from the repo root: `fvm dart run melos run ci`
Expected: exit 0, 82 `fcm_app` tests.

```bash
git add apps/fcm_app
git commit -m "feat(app): add the notification presenter seam"
```

---

### Task 5: Post real notifications

**Files:**
- Create: `apps/fcm_app/lib/notifications/notification_content.dart`
- Create: `apps/fcm_app/lib/notifications/local_notification_presenter.dart`
- Modify: `apps/fcm_app/pubspec.yaml`
- Modify: `apps/fcm_app/android/app/src/main/AndroidManifest.xml`
- Test: `apps/fcm_app/test/notification_content_test.dart`

**Interfaces:**
- Consumes: `NotificationPresenter` (Task 4).
- Produces:
  - `const String notificationChannelId` = `'fcm_sample_high'`, `notificationChannelName`, `notificationChannelDescription`
  - `int notificationIdFor(String messageId)`
  - `class LocalNotificationPresenter implements NotificationPresenter` — `LocalNotificationPresenter({FlutterLocalNotificationsPlugin? plugin})`

**On testability, stated honestly:** `flutter_local_notifications` offers no seam
to intercept a `show` call, so `LocalNotificationPresenter` itself cannot be
unit-tested. That is why every *decision* — the integer id, the channel, which
text goes where — lives in `notification_content.dart`, which is pure and fully
tested. What remains untested is three plugin calls with no branching, covered by
the analyzer and by the manual device checks in Task 11.

- [ ] **Step 1: Add the dependency**

In `apps/fcm_app/pubspec.yaml`, `dependencies:` gains one entry, alphabetically
after `firebase_messaging` and before `flutter`:

```yaml
  firebase_messaging: ^16.5.0
  flutter:
    sdk: flutter
  flutter_local_notifications: ^22.3.0
  http: ^1.6.0
  shared_preferences: ^2.5.5
```

Note `flutter_local_notifications` sorts **after** the `flutter` SDK entry.

Run from the repo root: `fvm dart pub get`
Expected: succeeds.

- [ ] **Step 2: Write the failing test**

`apps/fcm_app/test/notification_content_test.dart`:

```dart
import 'package:fcm_app/notifications/notification_content.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('notificationIdFor', () {
    test('is stable, so re-showing a message replaces its banner', () {
      expect(notificationIdFor('api-1754812345678901'), notificationIdFor('api-1754812345678901'));
    });

    test('separates different messages', () {
      expect(
        notificationIdFor('api-1'),
        isNot(notificationIdFor('api-2')),
      );
    });

    test('stays within a 32-bit signed int, which Android requires', () {
      for (final id in ['', 'a', 'api-1754812345678901', 'x' * 500]) {
        final value = notificationIdFor(id);

        expect(value, greaterThanOrEqualTo(0), reason: id);
        expect(value, lessThanOrEqualTo(2147483647), reason: id);
      }
    });
  });

  group('the channel', () {
    test('has an id, a name and a description', () {
      expect(notificationChannelId, isNotEmpty);
      expect(notificationChannelName.trim(), isNotEmpty);
      expect(notificationChannelDescription.trim(), isNotEmpty);
    });

    test('uses the id the Android manifest points FCM at', () {
      expect(notificationChannelId, 'fcm_sample_high');
    });
  });
}
```

The last test looks tautological but is not: the same literal is duplicated in
`AndroidManifest.xml`, which no Dart test can read, so pinning it here means a
rename cannot silently break the manifest agreement without a test failing.

- [ ] **Step 3: Run the test to verify it fails**

Run from `apps/fcm_app`: `fvm flutter test test/notification_content_test.dart`
Expected: FAIL — `Target of URI doesn't exist: 'package:fcm_app/notifications/notification_content.dart'`.

- [ ] **Step 4: Write the pure content**

`apps/fcm_app/lib/notifications/notification_content.dart`:

```dart
/// The Android channel every notification from this app goes to.
///
/// Importance high is what makes a banner pop instead of landing silently in the
/// tray. The same id is given to FCM in `AndroidManifest.xml`, so the entries it
/// draws itself while the app is backgrounded use this channel too — without
/// that, only foreground banners would be heads-up.
const notificationChannelId = 'fcm_sample_high';

/// Shown to the user in Android's per-channel notification settings.
const notificationChannelName = 'Sample pushes';

/// Explains the channel in Android's notification settings.
const notificationChannelDescription =
    'Pushes received by the FCM sample app.';

/// The integer id `flutter_local_notifications` requires, derived from the
/// payload id.
///
/// Deriving it means re-showing the same message replaces its banner instead of
/// stacking a second one. Masked to 31 bits because Android's `notify` takes a
/// Java `int`, and Dart's `hashCode` is neither bounded to that range nor
/// guaranteed non-negative.
int notificationIdFor(String messageId) => messageId.hashCode & 0x7fffffff;
```

- [ ] **Step 5: Write the presenter**

`apps/fcm_app/lib/notifications/local_notification_presenter.dart`:

```dart
import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'notification_content.dart';
import 'notification_presenter.dart';

/// A [NotificationPresenter] over `flutter_local_notifications`.
///
/// Needed only for the foreground: while the app is backgrounded, FCM's own SDK
/// draws the tray entry, and on iOS a single presentation-options call is enough.
/// This exists because Android shows nothing for a message that arrives while
/// the app is in use.
class LocalNotificationPresenter implements NotificationPresenter {
  LocalNotificationPresenter({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  final _taps = StreamController<String>.broadcast();

  @override
  Stream<String> get taps => _taps.stream;

  @override
  Future<void> initialize() async {
    await _plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: _onResponse,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            notificationChannelId,
            notificationChannelName,
            description: notificationChannelDescription,
            importance: Importance.high,
          ),
        );
  }

  @override
  Future<void> show(PushMessage message) => _plugin.show(
    notificationIdFor(message.id),
    message.title,
    message.body,
    const NotificationDetails(
      android: AndroidNotificationDetails(
        notificationChannelId,
        notificationChannelName,
        channelDescription: notificationChannelDescription,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    ),
    // The payload is the message id, which is how a tap resolves back to a
    // message the inbox already holds.
    payload: message.id,
  );

  @override
  Future<void> dispose() => _taps.close();

  void _onResponse(NotificationResponse response) {
    if (response.payload case final id? when id.isNotEmpty) {
      _taps.add(id);
    }
  }
}
```

- [ ] **Step 6: Point FCM at the same channel**

In `apps/fcm_app/android/app/src/main/AndroidManifest.xml`, inside
`<application>` and after the closing `</activity>` tag, add:

```xml
        <!-- Makes the tray entries FCM draws while the app is backgrounded use
             the same high-importance channel the app creates, so they pop as
             heads-up banners instead of landing silently. -->
        <meta-data
            android:name="com.google.firebase.messaging.default_notification_channel_id"
            android:value="fcm_sample_high" />
```

Leave the existing `flutterEmbedding` meta-data and everything else untouched.

- [ ] **Step 7: Run the test to verify it passes**

Run from `apps/fcm_app`: `fvm flutter test test/notification_content_test.dart`
Expected: PASS, 5 tests.

- [ ] **Step 8: Check the dependency did not break the web build**

Run from `apps/fcm_app`: `fvm flutter build web --release`
Expected: succeeds. `flutter_local_notifications` has no web implementation, but
its Dart API is platform-channel based, so it compiles for web and would only
throw at runtime — which cannot happen, because web never receives a push here.

If the web build fails, **report it rather than working around it**: it would mean
the plugin pulls in something web cannot compile, and the fix is a design
question, not an implementation one.

- [ ] **Step 9: Run the gate and commit**

Run from the repo root: `fvm dart run melos run ci`
Expected: exit 0, 87 `fcm_app` tests.

```bash
git add apps/fcm_app pubspec.lock
git commit -m "feat(app): post foreground notifications on a high-importance channel"
```

**A risk to record, not to solve here:** `flutter_local_notifications` 22.x needs a
recent `compileSdk` and, on some setups, Java desugaring in
`android/app/build.gradle`. This machine has no Android SDK, so an Android build
cannot be attempted and the requirement cannot be checked. Whoever first builds
the APK should expect that as the most likely failure and note it in the README.

---

### Task 6: Report FCM notification taps — and fix a buffering bug it depends on

**Files:**
- Modify: `apps/fcm_app/lib/push/push_source.dart`
- Modify: `apps/fcm_app/lib/push/firebase_push_source.dart`
- Modify: `apps/fcm_app/lib/push/disabled_push_source.dart`
- Modify: `apps/fcm_app/test/fake_push_source.dart`
- Test: `apps/fcm_app/test/fake_push_source_test.dart` (new)

**Interfaces:**
- Consumes: `remoteMessageToPayload` (Task 1).
- Produces:
  - `PushSource` gains `Stream<String> get taps`
  - `FakePushSource` gains `void emitTap(String id)`, and its payload controller becomes single-subscription

**A pre-existing bug this task must fix.** `FirebasePushSource.start()` calls
`_emit(launchMessage)` for the message that launched the app, but it does so
*before* `PushInbox.listen()` subscribes — and `_controller` is
`StreamController.broadcast()`, which **discards events added while nothing is
listening**. So the documented "replays the message that launched the app"
behaviour has never worked. The cold-start tap path in this plan depends on it, so
it is fixed here: both controllers become **single-subscription**, which buffers
until the first listener attaches. `PushInbox` is the only subscriber, so nothing
else changes.

- [ ] **Step 1: Write the failing test**

`apps/fcm_app/test/fake_push_source_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';

import 'fake_push_source.dart';

void main() {
  late FakePushSource source;

  setUp(() {
    source = FakePushSource();
  });

  tearDown(() async {
    await source.dispose();
  });

  group('the payload stream', () {
    test('buffers a payload emitted before anything listens', () async {
      // The launch message is emitted inside start(), before PushInbox
      // subscribes. A broadcast controller would drop it.
      source.emit({'id': 'launch'});

      final received = <Map<String, Object?>>[];
      source.payloads.listen(received.add);
      await pumpEventQueue();

      expect(received.single['id'], 'launch');
    });
  });

  group('the tap stream', () {
    test('reports a tapped id', () async {
      final tapped = <String>[];
      source.taps.listen(tapped.add);

      source.emitTap('msg-1');
      await pumpEventQueue();

      expect(tapped, ['msg-1']);
    });

    test('buffers a tap emitted before anything listens', () async {
      source.emitTap('launch');

      final tapped = <String>[];
      source.taps.listen(tapped.add);
      await pumpEventQueue();

      expect(tapped, ['launch']);
    });
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run from `apps/fcm_app`: `fvm flutter test test/fake_push_source_test.dart`
Expected: FAIL — `The method 'emitTap' isn't defined`, and the buffering test fails because the controller is a broadcast one.

- [ ] **Step 3: Add `taps` to the interface**

In `apps/fcm_app/lib/push/push_source.dart`, add after the `payloads` getter:

```dart
  /// Ids of messages whose notification the user tapped.
  ///
  /// Fed by FCM's own tray notifications — `onMessageOpenedApp` while the app was
  /// backgrounded, and the launch message when it was terminated. A banner the
  /// app posted itself is reported by `NotificationPresenter.taps` instead.
  Stream<String> get taps;
```

- [ ] **Step 4: Implement it in `FirebasePushSource`**

`apps/fcm_app/lib/push/firebase_push_source.dart` becomes exactly:

```dart
import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';

import 'push_source.dart';
import 'remote_message_payload.dart';

/// A [PushSource] backed by `firebase_messaging`.
class FirebasePushSource implements PushSource {
  FirebasePushSource(this._messaging);

  final FirebaseMessaging _messaging;

  // Single-subscription, not broadcast: start() emits the launch message before
  // PushInbox subscribes, and a broadcast controller discards events added while
  // nothing is listening. PushInbox is the only subscriber either way.
  final _controller = StreamController<Map<String, Object?>>();
  final _taps = StreamController<String>();
  StreamSubscription<RemoteMessage>? _subscription;
  StreamSubscription<RemoteMessage>? _openedSubscription;

  @override
  Stream<Map<String, Object?>> get payloads => _controller.stream;

  @override
  Stream<String> get taps => _taps.stream;

  /// Subscribes to foreground messages and notification taps, asks iOS to show
  /// banners while the app is in use, and replays the message that launched the
  /// app, if there was one.
  Future<void> start() async {
    _subscription = FirebaseMessaging.onMessage.listen(_emit);
    _openedSubscription = FirebaseMessaging.onMessageOpenedApp.listen(_onOpened);

    // Android shows nothing for a foreground message, which is what
    // LocalNotificationPresenter is for. iOS suppresses the banner unless asked,
    // and this one call is all it needs — no plugin involved.
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    final launchMessage = await _messaging.getInitialMessage();
    if (launchMessage != null) {
      // Payload first, so the inbox holds the message before the tap asks to
      // open it. Both controllers deliver in the order added.
      _emit(launchMessage);
      _onOpened(launchMessage);
    }
  }

  @override
  Future<String?> token() => _messaging.getToken();

  @override
  Future<bool> requestPermission() async {
    final settings = await _messaging.requestPermission();

    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }

  @override
  Future<void> dispose() async {
    await _subscription?.cancel();
    await _openedSubscription?.cancel();
    await _controller.close();
    await _taps.close();
  }

  void _emit(RemoteMessage message) =>
      _controller.add(remoteMessageToPayload(message));

  void _onOpened(RemoteMessage message) {
    final id = remoteMessageToPayload(message)['id'];
    if (id is String && id.isNotEmpty) {
      _taps.add(id);
    }
  }
}
```

- [ ] **Step 5: Implement it in `DisabledPushSource`**

In `apps/fcm_app/lib/push/disabled_push_source.dart`, add:

```dart
  @override
  Stream<String> get taps => const Stream.empty();
```

- [ ] **Step 6: Update the fake**

In `apps/fcm_app/test/fake_push_source.dart`, change the controller to
single-subscription and add the tap channel, so the fake matches the production
contract the test asserts:

```dart
  // Single-subscription, mirroring FirebasePushSource: a payload emitted before
  // anything listens must still be delivered.
  final _controller = StreamController<Map<String, Object?>>();
  final _taps = StreamController<String>();

  @override
  Stream<Map<String, Object?>> get payloads => _controller.stream;

  @override
  Stream<String> get taps => _taps.stream;

  /// Acts as though the user tapped the tray notification for [id].
  void emitTap(String id) => _taps.add(id);
```

and close both in `dispose`:

```dart
  @override
  Future<void> dispose() async {
    await _controller.close();
    await _taps.close();
  }
```

- [ ] **Step 7: Run the tests to verify they pass**

Run from `apps/fcm_app`: `fvm flutter test`
Expected: PASS. The 3 new tests, and every existing test unaffected — they all
emit after `listen()`, which single-subscription handles identically.

If a pre-existing test now fails, it is because it subscribed to `payloads` twice.
Report it rather than reverting the controller change; the fix is to share one
subscription, and the buffering behaviour is the point of this step.

- [ ] **Step 8: Run the gate and commit**

Run from the repo root: `fvm dart run melos run ci`
Expected: exit 0, 90 `fcm_app` tests.

```bash
git add apps/fcm_app
git commit -m "feat(app): report FCM notification taps and buffer the launch payload"
```

---

### Task 7: Ask the shell to open a message

**Files:**
- Modify: `apps/fcm_app/lib/push/push_inbox.dart`
- Test: `apps/fcm_app/test/push_inbox_test.dart`

**Interfaces:**
- Consumes: `PushInbox` (Tasks 3–4).
- Produces, on `PushInbox`:
  - `void requestOpen(String id)`
  - `PushMessage? get pendingOpen` — resolved **at read time**, not at request time
  - `bool get hasPendingOpen`
  - `void clearPendingOpen()`

**Why `pendingOpen` resolves lazily.** A tap and its payload arrive on two
different streams, so their relative order is not guaranteed. Resolving the id
every time the getter is read means the shell simply sees `null` until the message
lands and a `notifyListeners` brings it back — no ordering assumption anywhere.
`hasPendingOpen` is what tells the shell a tap is outstanding at all.

- [ ] **Step 1: Write the failing tests**

Add to `apps/fcm_app/test/push_inbox_test.dart`:

```dart
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

    test('resolves once the message arrives, whatever the stream order', () async {
      inbox = PushInbox(source, store: FakePushPayloadStore())..listen();

      inbox.requestOpen('late');
      expect(inbox.pendingOpen, isNull);
      source.emit(payload(id: 'late'));
      await pumpEventQueue();

      expect(inbox.pendingOpen?.id, 'late');
    });

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
```

- [ ] **Step 2: Run the tests to verify they fail**

Run from `apps/fcm_app`: `fvm flutter test test/push_inbox_test.dart`
Expected: FAIL — `The method 'requestOpen' isn't defined`.

- [ ] **Step 3: Implement it**

In `apps/fcm_app/lib/push/push_inbox.dart`, add the field beside `_token`:

```dart
  String? _pendingOpenId;
```

and these members after the `token` getter:

```dart
  /// Whether a notification tap is waiting to be acted on.
  bool get hasPendingOpen => _pendingOpenId != null;

  /// The message a tap asked to open, or null when there is no tap outstanding
  /// or its message is not held.
  ///
  /// Resolved on every read rather than when the tap arrived: the tap and the
  /// payload come from two different streams, so the message may land after the
  /// request. A `notifyListeners` from either brings the shell back to check.
  PushMessage? get pendingOpen {
    final id = _pendingOpenId;
    if (id == null) {
      return null;
    }

    for (final push in _accepted) {
      if (push.message.id == id) {
        return push.message;
      }
    }

    return null;
  }

  /// Asks the shell to open the message with [id].
  void requestOpen(String id) {
    _pendingOpenId = id;
    notifyListeners();
  }

  /// Called by the shell once it has navigated, so it does not navigate twice.
  void clearPendingOpen() {
    _pendingOpenId = null;
  }
```

- [ ] **Step 4: Run the tests to verify they pass**

Run from `apps/fcm_app`: `fvm flutter test test/push_inbox_test.dart`
Expected: PASS — the 5 new tests plus everything already there.

- [ ] **Step 5: Run the gate and commit**

Run from the repo root: `fvm dart run melos run ci`
Expected: exit 0, 95 `fcm_app` tests.

```bash
git add apps/fcm_app
git commit -m "feat(app): let a notification tap ask for a message"
```

---

### Task 8: The message detail page

**Files:**
- Create: `apps/fcm_app/lib/ui/message_detail_page.dart`
- Test: `apps/fcm_app/test/message_detail_page_test.dart`

**Interfaces:**
- Consumes: `PushMessage` from `package:core/core.dart` — fields `id`, `title`, `body`, `sentAt`, `data`.
- Produces: `class MessageDetailPage extends StatelessWidget` — `const MessageDetailPage(PushMessage message, {super.key})`

- [ ] **Step 1: Write the failing test**

`apps/fcm_app/test/message_detail_page_test.dart`:

```dart
import 'package:core/core.dart';
import 'package:fcm_app/ui/message_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final message = PushMessage(
    id: 'api-1754812345678901',
    title: 'Build finished',
    body: 'Release 1.0.0 is ready.',
    sentAt: DateTime.utc(2026, 8, 11, 9, 30),
    data: const {'event': 'build_finished', 'deepLink': '/builds/42'},
  );

  Future<void> pump(WidgetTester tester, PushMessage subject) => tester
      .pumpWidget(MaterialApp(home: MessageDetailPage(subject)));

  testWidgets('shows the title in the app bar and the body', (tester) async {
    await pump(tester, message);

    expect(find.widgetWithText(AppBar, 'Build finished'), findsOne);
    expect(find.text('Release 1.0.0 is ready.'), findsOne);
  });

  testWidgets('shows the payload id, which matches what the API reported', (
    tester,
  ) async {
    await pump(tester, message);

    expect(find.text('api-1754812345678901'), findsOne);
  });

  testWidgets('shows when it was sent, in UTC', (tester) async {
    await pump(tester, message);

    expect(find.textContaining('2026-08-11'), findsOne);
  });

  testWidgets('shows every data key and its value', (tester) async {
    await pump(tester, message);

    expect(find.text('event'), findsOne);
    expect(find.text('build_finished'), findsOne);
    expect(find.text('deepLink'), findsOne);
    expect(find.text('/builds/42'), findsOne);
  });

  testWidgets('says so when there is no extra data', (tester) async {
    await pump(
      tester,
      PushMessage(
        id: 'plain',
        title: 'Hello',
        body: 'Nothing but a title and a body.',
        sentAt: DateTime.utc(2026, 8, 11),
      ),
    );

    expect(find.text('No extra data keys.'), findsOne);
  });

  testWidgets('can be popped, so a tap is not a dead end', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => MessageDetailPage(message),
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Release 1.0.0 is ready.'), findsOne);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(find.text('open'), findsOne);
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run from `apps/fcm_app`: `fvm flutter test test/message_detail_page_test.dart`
Expected: FAIL — `Target of URI doesn't exist: 'package:fcm_app/ui/message_detail_page.dart'`.

- [ ] **Step 3: Write the page**

`apps/fcm_app/lib/ui/message_detail_page.dart`:

```dart
import 'package:core/core.dart';
import 'package:flutter/material.dart';

/// One received message in full.
///
/// A page rather than a destination, pushed over the shell, because it is reached
/// from two places that both mean "look at this one message": an inbox row, and a
/// notification the user tapped.
class MessageDetailPage extends StatelessWidget {
  const MessageDetailPage(this.message, {super.key});

  /// The message to show.
  final PushMessage message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(message.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(message.body, style: theme.textTheme.bodyLarge),
          const Divider(height: 32),
          Text('Sent', style: theme.textTheme.labelMedium),
          Text(message.sentAt.toIso8601String()),
          const SizedBox(height: 16),
          Text('Payload id', style: theme.textTheme.labelMedium),
          Text(message.id),
          const Divider(height: 32),
          Text('Extra data', style: theme.textTheme.labelMedium),
          const SizedBox(height: 8),
          if (message.data.isEmpty)
            const Text('No extra data keys.')
          else
            for (final entry in message.data.entries)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 120,
                      child: Text(entry.key, style: theme.textTheme.labelLarge),
                    ),
                    Expanded(child: Text(entry.value)),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Run the test to verify it passes**

Run from `apps/fcm_app`: `fvm flutter test test/message_detail_page_test.dart`
Expected: PASS, 6 tests.

- [ ] **Step 5: Run the gate and commit**

Run from the repo root: `fvm dart run melos run ci`
Expected: exit 0, 101 `fcm_app` tests.

```bash
git add apps/fcm_app
git commit -m "feat(app): add the message detail page"
```

---

### Task 9: Open a message from the inbox

**Files:**
- Modify: `apps/fcm_app/lib/ui/message_tile.dart`
- Modify: `apps/fcm_app/lib/ui/inbox_view.dart`
- Test: `apps/fcm_app/test/inbox_view_test.dart`

**Interfaces:**
- Consumes: `MessageDetailPage` (Task 8).
- Produces: `MessageTile` gains `final ValueChanged<PushMessage>? onTap`, called with its own message.

**Why the callback carries the message** rather than the row's index: the tile
already holds it, so nothing has to look it up in a list that may have changed
between the build and the tap.

- [ ] **Step 1: Write the failing tests**

Add to `apps/fcm_app/test/inbox_view_test.dart`, keeping every existing test:

```dart
  testWidgets('opens the detail page when a row is tapped', (tester) async {
    inbox = PushInbox(source, store: FakePushPayloadStore())..listen();
    await pumpApp(tester);
    source.emit(payload());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Build finished'));
    await tester.pumpAndSettle();

    expect(find.byType(MessageDetailPage), findsOne);
    expect(find.text('/builds/42'), findsOne);
  });

  testWidgets('comes back to the inbox from the detail page', (tester) async {
    inbox = PushInbox(source, store: FakePushPayloadStore())..listen();
    await pumpApp(tester);
    source.emit(payload());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Build finished'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(find.byType(MessageDetailPage), findsNothing);
    expect(find.widgetWithText(AppBar, 'Push inbox'), findsOne);
  });
```

Add `import 'package:fcm_app/ui/message_detail_page.dart';` to the file's imports.

- [ ] **Step 2: Run the tests to verify they fail**

Run from `apps/fcm_app`: `fvm flutter test test/inbox_view_test.dart`
Expected: FAIL — `MessageDetailPage` is never found, because tapping does nothing.

- [ ] **Step 3: Give the tile a tap callback**

In `apps/fcm_app/lib/ui/message_tile.dart`, change the constructor and add the
field:

```dart
  const MessageTile(this.message, {this.onTap, super.key});

  /// The message this row shows.
  final PushMessage message;

  /// Called with [message] when the row is tapped, or null to make the row inert.
  ///
  /// It carries the message rather than an index, so nothing has to look the row
  /// up in a list that may have changed since the build.
  final ValueChanged<PushMessage>? onTap;
```

and in `build`, above the `return`:

```dart
    final tap = onTap;
```

then give the `ListTile` its handler:

```dart
    return ListTile(
      onTap: tap == null ? null : () => tap(message),
      leading: const Icon(Icons.notifications_outlined),
```

Leave the rest of the `ListTile` exactly as it is.

- [ ] **Step 4: Push the page from the inbox**

In `apps/fcm_app/lib/ui/inbox_view.dart`, add
`import 'message_detail_page.dart';` and replace the `itemBuilder`:

```dart
                    itemBuilder: (context, index) => MessageTile(
                      inbox.messages[index],
                      onTap: (message) => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => MessageDetailPage(message),
                        ),
                      ),
                    ),
```

- [ ] **Step 5: Run the tests to verify they pass**

Run from `apps/fcm_app`: `fvm flutter test test/inbox_view_test.dart`
Expected: PASS — the 2 new tests plus the 5 that were already there.

- [ ] **Step 6: Run the gate and commit**

Run from the repo root: `fvm dart run melos run ci`
Expected: exit 0, 103 `fcm_app` tests.

```bash
git add apps/fcm_app
git commit -m "feat(app): open the detail page from an inbox row"
```

---

### Task 10: The shell reacts to taps and to resuming

**Files:**
- Modify: `apps/fcm_app/lib/ui/app_shell.dart`
- Test: `apps/fcm_app/test/app_shell_test.dart`

**Interfaces:**
- Consumes: `PushInbox.hasPendingOpen`, `pendingOpen`, `clearPendingOpen`, `drainPending` (Tasks 3 and 7); `MessageDetailPage` (Task 8).
- Produces: nothing new — `AppShell`'s constructor is unchanged.

**The two behaviours, and why they are in one task:** both are `AppShell` growing a
lifetime — a listener and an `AppLifecycleListener` — and both are disposed in the
same `dispose`. Splitting them would mean writing that plumbing twice.

**How an outstanding tap is handled.** The shell selects the Inbox destination as
soon as *any* tap is outstanding, then pushes the detail page if and when the
message resolves. That single behaviour covers both cases from the spec: it is the
documented fallback for an id that never resolves, and it is the right backdrop
for the page about to appear. `clearPendingOpen` is called before pushing, so a
further `notifyListeners` cannot navigate twice.

- [ ] **Step 1: Write the failing tests**

Add to `apps/fcm_app/test/app_shell_test.dart`, keeping every existing test:

```dart
  Future<void> openSandbox(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sandbox'));
    await tester.pumpAndSettle();
  }

  testWidgets('opens the detail page for a tapped notification', (tester) async {
    await pumpApp(tester);
    source.emit(payload(id: 'tapped'));
    await tester.pumpAndSettle();

    inbox.requestOpen('tapped');
    await tester.pumpAndSettle();

    expect(find.byType(MessageDetailPage), findsOne);
    expect(inbox.hasPendingOpen, isFalse);
  });

  testWidgets('leaves the sandbox for the inbox when a tap arrives', (
    tester,
  ) async {
    await pumpApp(tester);
    await openSandbox(tester);

    inbox.requestOpen('never-seen');
    await tester.pumpAndSettle();

    expect(selectedDestination(tester), 0);
    expect(find.byType(MessageDetailPage), findsNothing);
  });

  testWidgets('opens the page once the message catches up', (tester) async {
    await pumpApp(tester);

    inbox.requestOpen('late');
    await tester.pumpAndSettle();
    expect(find.byType(MessageDetailPage), findsNothing);
    source.emit(payload(id: 'late'));
    await tester.pumpAndSettle();

    expect(find.byType(MessageDetailPage), findsOne);
  });

  testWidgets('does not open the page twice for one tap', (tester) async {
    await pumpApp(tester);
    source.emit(payload(id: 'tapped'));
    await tester.pumpAndSettle();

    inbox.requestOpen('tapped');
    await tester.pumpAndSettle();
    source.emit(payload(id: 'unrelated'));
    await tester.pumpAndSettle();

    expect(find.byType(MessageDetailPage), findsOne);
  });

  testWidgets('drains pending payloads when the app resumes', (tester) async {
    final store = FakePushPayloadStore();
    inbox = PushInbox(source, store: store)..listen();
    sandbox = SandboxController(
      sender: FakeNotificationSender(),
      token: () => inbox.token,
    );
    await tester.pumpWidget(FcmSampleApp(inbox: inbox, sandbox: sandbox));
    await tester.pumpAndSettle();
    store.pending.add(payload(id: 'while-away'));

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(inbox.messages.single.id, 'while-away');
  });
```

`app_shell_test.dart` already has `int? selectedDestination(WidgetTester tester)`,
which reads the `IndexedStack`'s index — reuse it. It has **no** payload helper,
so add one at the top of the file, matching the one in `push_inbox_test.dart`:

```dart
Map<String, Object?> payload({String id = 'msg-1'}) => {
  'id': id,
  'title': 'Build finished',
  'body': 'Release 1.0.0 is ready.',
  'sentAt': '2026-08-11T09:30:00Z',
};
```

Add these imports too: `package:fcm_app/ui/message_detail_page.dart` and
`fake_push_payload_store.dart`.

- [ ] **Step 2: Run the tests to verify they fail**

Run from `apps/fcm_app`: `fvm flutter test test/app_shell_test.dart`
Expected: FAIL — no `MessageDetailPage` is ever pushed, and the resumed payload never arrives.

- [ ] **Step 3: Implement both behaviours**

In `apps/fcm_app/lib/ui/app_shell.dart`, add these imports:

```dart
import 'dart:async';

import 'message_detail_page.dart';
```

and replace `_AppShellState`'s opening — the fields and the two new lifecycle
methods — leaving `build` and `_select` as they are:

```dart
class _AppShellState extends State<AppShell> {
  static const _titles = ['Push inbox', 'Sandbox'];
  static const _inboxDestination = 0;

  late final AppLifecycleListener _lifecycle;

  int _destination = _inboxDestination;

  @override
  void initState() {
    super.initState();
    widget.inbox.addListener(_onInboxChanged);
    // A push that arrived while the app was merely backgrounded sits in the
    // pending key until something drains it, and resuming is that something.
    _lifecycle = AppLifecycleListener(onResume: _onResume);
  }

  @override
  void dispose() {
    widget.inbox.removeListener(_onInboxChanged);
    _lifecycle.dispose();
    super.dispose();
  }
```

and add these two methods after `_select`:

```dart
  void _onResume() => unawaited(widget.inbox.drainPending());

  /// Acts on a notification tap once its message is known.
  ///
  /// Selecting the inbox happens as soon as a tap is outstanding: it is the
  /// fallback for an id that will never resolve — evicted by the cap, or rejected
  /// as malformed — and the right backdrop for the page about to be pushed.
  void _onInboxChanged() {
    if (!widget.inbox.hasPendingOpen) {
      return;
    }

    if (_destination != _inboxDestination) {
      setState(() => _destination = _inboxDestination);
    }

    final message = widget.inbox.pendingOpen;
    if (message == null) {
      return;
    }

    // Cleared before navigating, so a later notifyListeners cannot push twice.
    widget.inbox.clearPendingOpen();
    unawaited(
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => MessageDetailPage(message)),
      ),
    );
  }
```

- [ ] **Step 4: Run the tests to verify they pass**

Run from `apps/fcm_app`: `fvm flutter test test/app_shell_test.dart`
Expected: PASS — the 5 new tests plus the 5 that were already there.

- [ ] **Step 5: Run the gate and commit**

Run from the repo root: `fvm dart run melos run ci`
Expected: exit 0, 108 `fcm_app` tests.

```bash
git add apps/fcm_app
git commit -m "feat(app): open tapped notifications and drain on resume"
```

---

### Task 11: Wire it up, persist from the background isolate, and document it

**Files:**
- Modify: `apps/fcm_app/lib/main.dart`
- Modify: `README.md`

**Interfaces:**
- Consumes: everything above.
- Produces: nothing new.

- [ ] **Step 1: Wire the presenter and the tap streams into `main()`**

In `apps/fcm_app/lib/main.dart`, add these imports alongside the existing ones:

```dart
import 'dart:ui' show DartPluginRegistrant;

import 'notifications/local_notification_presenter.dart';
import 'notifications/notification_presenter.dart';
import 'notifications/silent_notification_presenter.dart';
import 'push/remote_message_payload.dart';
```

`push/push_payload_store.dart` and `push/shared_preferences_push_payload_store.dart`
were added in Task 3 and stay.

Replace the inbox construction block with:

```dart
  final PushPayloadStore store = SharedPreferencesPushPayloadStore();
  final presenter = await _startPresenter();
  final inbox = PushInbox(
    source,
    store: store,
    presenter: presenter,
    setupError: setupError,
  )..listen();
  await inbox.restore();
  await inbox.refreshToken();

  // Both channels mean the same thing to the inbox: FCM reports taps on the tray
  // entries it drew itself, and the presenter reports taps on the banners the app
  // posted while it was in the foreground.
  source.taps.listen(inbox.requestOpen);
  presenter.taps.listen(inbox.requestOpen);
```

Add this top-level function below `main()`:

```dart
/// Starts local notifications, degrading to silence rather than failing.
///
/// A broken notification plugin should cost the banners, not the app — the same
/// principle `DisabledPushSource` applies when Firebase will not start.
Future<NotificationPresenter> _startPresenter() async {
  final presenter = LocalNotificationPresenter();
  try {
    await presenter.initialize();

    return presenter;
  } catch (error) {
    debugPrint('Local notifications are unavailable: $error');
    await presenter.dispose();

    return const SilentNotificationPresenter();
  }
}
```

- [ ] **Step 2: Persist from the background isolate**

Replace `_onBackgroundMessage` in the same file with:

```dart
/// Handles pushes that arrive while the app is backgrounded or terminated.
///
/// Must be a top-level function, and annotated so AOT compilation keeps it
/// reachable from the background isolate.
///
/// It only persists. FCM has already drawn the tray entry for this message, so
/// posting a notification here would show it twice. The UI isolate picks the
/// payload up in `PushInbox.restore` at next launch, or in `drainPending` when
/// the app resumes.
@pragma('vm:entry-point')
Future<void> _onBackgroundMessage(RemoteMessage message) async {
  // This isolate has its own memory and its own plugin registry, so both need
  // setting up before shared_preferences can be reached.
  DartPluginRegistrant.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await SharedPreferencesPushPayloadStore().appendPending(
    remoteMessageToPayload(message),
  );
}
```

- [ ] **Step 3: Run the gate and the build check**

Run from the repo root: `fvm dart run melos run ci`
Expected: exit 0, 108 `fcm_app` tests.

Run from `apps/fcm_app`: `fvm flutter build web --release`
Expected: succeeds.

- [ ] **Step 4: Document it in the root README**

Add a `## Notifications` section immediately after the existing
`## Sending a test push` section, and before `## Verified on this machine`:

````markdown
## Notifications

A received push is shown as a notification as well as landing in the inbox, and
tapping either the notification or an inbox row opens a detail page for it.

| When the push arrives | What draws the notification |
| --- | --- |
| App backgrounded or terminated | FCM's own SDK, from the `notification` block `apps/fcm_api` sends. No app code involved. |
| App in the foreground | `LocalNotificationPresenter`, because Android shows nothing itself in this case. On iOS a single `setForegroundNotificationPresentationOptions` call is enough. |

Both use one high-importance Android channel, `fcm_sample_high`. The app creates
it, and `AndroidManifest.xml` points FCM at the same id with
`default_notification_channel_id` — without that, only the foreground banners
would be heads-up.

The inbox is durable: the newest 100 payloads are kept in `shared_preferences`
and reloaded at launch, so a push that arrived while the app was away is there
whether or not it was ever tapped. The background handler writes to a separate
key that only it appends to, and the UI drains that key at launch and on every
resume — two keys rather than one, so neither isolate read-modify-writes the
other's data.

**A push is never notified twice.** Only messages arriving on the live foreground
stream produce a banner; anything restored from storage was already shown by FCM
while the app was away, so replaying it on launch is exactly what the code avoids.

Notification permission is requested at startup by `firebase_messaging`, which
covers Android 13+'s `POST_NOTIFICATIONS` grant. Denying it costs the banners
and nothing else — the inbox still fills.
````

Then update `## Verified on this machine` to add the notification behaviour to
the list of what has **not** been verified, using the real test counts from Step
3's `melos run ci` and keeping the section's existing honesty about the device
path. Do not claim any on-device behaviour passed.

- [ ] **Step 5: Commit**

```bash
git add apps/fcm_app README.md
git commit -m "feat(app): show notifications and persist background pushes"
```

- [ ] **Step 6: On-device verification (human, needs a device and a key)**

These are the plan's real acceptance criteria and **cannot** be run on this
machine — there is no Android device attached and no service-account key has been
generated. Report each as verified or unverified honestly; never assume.

Prerequisites: the two outstanding manual items from the previous plan — generate
a Firebase service-account key, and confirm `curl`ing `/send` with a bogus token
returns the mapped 404 that proves the OAuth path works.

With `apps/fcm_api` running and `adb reverse tcp:8080 tcp:8080` in place:

1. App in the foreground → send from the Sandbox → a **banner** appears *and* the
   row lands in the inbox.
2. Tap that banner → the **detail page** opens on that message.
3. Background the app → send → a **heads-up tray entry** appears.
4. Tap it → the app opens and lands on the detail page for that message.
5. Background the app → send → do **not** tap → reopen the app → the message is
   in the inbox.
6. Force-stop the app → send → relaunch → the message is in the inbox.
7. Relaunch the app twice more → **no banners are replayed** for old messages.
8. Tap an inbox row → the detail page opens.
9. Send 101 messages → the inbox holds 100 and the oldest is gone.

Item 7 is the one worth being most careful about: it is the check that the
never-re-notify rule actually holds on a device, and the failure it guards against
— every stored notification firing at once on launch — is the most user-visible
thing that could go wrong here.

## Verification summary

The work is done when all of these hold:

- [ ] `fvm dart run melos run ci` exits 0, with 108 `fcm_app` tests
- [ ] `fvm flutter build web --release` succeeds
- [ ] `grep -rn 'ignore:' packages/ apps/ --include=*.dart` returns nothing
- [ ] `packages/core`, `packages/fcm_gallery_shared` and `apps/fcm_api` are untouched by this branch
- [ ] The nine on-device checks above are each reported verified or unverified

## Notes for the implementer

- **`SharedPreferencesAsync`, never the legacy `SharedPreferences`.** Repeated here
  because it is the one mistake in this plan that would produce a silent,
  intermittent data-loss bug rather than a test failure.
- **The background isolate must not show a notification.** FCM already did.
- **Restored messages must not notify.** Task 4's tests are what hold this line;
  if one of them starts failing later, do not relax it.
- **Do not add routing on data keys.** The `deepLink` a gallery preset carries
  stays inert; it is named out of scope in the spec.
