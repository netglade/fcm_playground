# FCM Notification Sandbox Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a drawer-navigated Sandbox page to `fcm_app` that composes a push notification from a scenario gallery plus a full editor and sends it to the device via a Dart Cloud Function, with `packages/fcm_gallery_shared` holding the event enum, scenario models, DTOs and validation used by both sides.

**Architecture:** `packages/fcm_gallery_shared` (pure Dart, depends on `packages/core`) defines the contract. `apps/fcm_functions` registers one `onCallWithData` callable that validates the request, builds a `TokenMessage` and sends it through the Firebase Admin SDK. `apps/fcm_app` gains an `AppShell` with a drawer over two views, and a `SandboxController` that talks to the callable through a `NotificationSender` interface so widget tests never construct `cloud_functions`.

**Tech Stack:** Dart 3.12.2 (fvm-pinned), Flutter 3.44.8, `firebase_functions ^0.6.0`, `firebase_admin_sdk ^0.5.4`, `cloud_functions ^6.3.6`, `build_runner ^2.10.5`, melos 8, DCM.

**Spec:** `docs/superpowers/specs/2026-08-10-fcm-notification-sandbox-design.md`

## Global Constraints

Every task's requirements implicitly include this section.

- **Run everything through fvm.** `fvm dart`, `fvm flutter`, `fvm exec dcm`, `fvm exec firebase`. There is no `dart` on `PATH` on this machine.
- **Run tooling from the repo root**, never from a package directory. The root is the pub workspace owner. `fvm dart run melos run <script>`.
- **Run `firebase` from the repo root only.** `apps/fcm_app/firebase.json` exists and has no `functions` block; the CLI picks the nearest file walking up from cwd.
- **Dart SDK constraint for every new package:** `sdk: ^3.12.2`.
- **Every new package declares `resolution: workspace`** and is added to `workspace:` in the root `pubspec.yaml`. No member has its own `pubspec.lock` (they are gitignored).
- **Every new package's `analysis_options.yaml`** is exactly:
  ```yaml
  include:
    - package:lints/recommended.yaml
    - ../../analysis_options.yaml
  ```
  (`package:flutter_lints/flutter.yaml` instead for Flutter packages — only `fcm_app` is one, and it already has this file.)
- **Report the test count you measured, not the one this plan predicts.** Two of this plan's predicted counts have already been wrong (Task 9 said 11 where 10 were written). If your run disagrees with the expectation, the run wins — say what you actually saw and flag the discrepancy. A report that echoes the expected number instead of the observed one destroys the only test evidence the review has.
- **Run `fvm dart format .` from the repo root before every commit**, and confirm with `fvm dart format --output=none --set-exit-if-changed .`. `melos run ci`'s **first** step is that check, so unformatted code fails the gate before the analyzer is even reached. Do not hand-patch code to satisfy a formatting lint — `require_trailing_commas` and the formatter disagree about layout, and the formatter wins. This was added after Task 2 was committed with three unformatted files.
- **Lints that will fail the build if ignored** (`--fatal-infos --fatal-warnings`): `prefer_single_quotes`, `require_trailing_commas`, `sort_pub_dependencies` (alphabetical), `prefer_final_locals`, `always_declare_return_types`, `unawaited_futures`, `avoid_print` (use `debugPrint` in Flutter code, `firebase_functions`' `logger` in functions).
- **DCM metrics that will fail the build** (`--fatal-style --fatal-warnings`): `source-lines-of-code: 50` per function, `number-of-parameters: 5` (**counts named parameters and `super.key`**), `maximum-nesting-level: 5`, `cyclomatic-complexity: 15`. Excluded under `test/**`.
- **DCM rules that constrain file layout:** `prefer-match-file-name` (the file's name must match its first public type, snake_case), `prefer-single-widget-per-file` (exactly one widget class per file), `avoid-returning-widgets` (**no `Widget _buildFoo()` helper methods** — extract a widget class instead), `newline-before-return`, `prefer-trailing-comma`.
- **Doc comments on every public declaration**, in the voice of the existing code: say why, not what. Read `packages/core/lib/src/push_message.dart` and `apps/fcm_app/lib/push/push_source.dart` first to match the register.
- **Test naming:** descriptive sentences, `group` per unit. Match `packages/core/test/push_message_parser_test.dart`.
- **Commit style:** Conventional Commits, as in `git log`. Scope is the package (`feat(shared):`, `feat(functions):`, `feat(app):`, `chore(tooling):`).
- **JSON boundary types:** every `fromJson` factory takes `Map<String, dynamic>` and every `toJson` returns `Map<String, dynamic>`. This matches `firebase_functions`' `Input Function(Map<String, dynamic>)` signature. `strict-casts: true` is on, so read fields with explicit casts (`json['x'] as String?`).

## Two refinements to the spec

Both are forced by the constraints above and are deliberate deviations from the committed spec. They do not change behaviour.

1. **`NotificationDraft` does not hold `asNotification` and `priority` directly.** The spec's six-field draft would give its constructor six parameters, over DCM's `number-of-parameters: 5`. They move into a `NotificationDelivery` value object (`asNotification`, `priority`), which is a real boundary anyway — "how it is delivered" versus "what it says" — and maps onto one UI group. Draft fields become `event`, `title`, `body`, `data`, `delivery`.
2. **The functions-side sender interface is `FcmMessageSender`, not `NotificationSender`.** The spec named both the app-side and functions-side seams `NotificationSender`. They send different things (a `SendNotificationRequest` versus a built `TokenMessage`), so the functions one is renamed to keep the repo readable. The app side keeps `NotificationSender`.

## Pre-flight findings — measured, not assumed

A throwaway probe ran before Task 1 and was reverted. Four facts came out of it,
and they override the spec where they collide with it.

**1. `firebase_functions ^0.7.0` cannot resolve here, so this plan uses `^0.6.0`.**

```
firebase_functions 0.7.0 → google_cloud_shelf ^0.6.0 → meta ^1.18.2
fcm_app → flutter (SDK 3.44.8) → meta 1.18.0        ← SDK pin, not overridable
```

Every published `google_cloud_shelf` requires `meta ^1.18.2`, so no version of it
helps. The only Flutter that pins `meta ≥ 1.18.2` is the current beta
(3.47.0-0.4.pre, Dart 3.13.0); the newest stable, 3.44.9, still pins `1.18.0`.
Staying on stable was the explicit decision, so the pin is `^0.6.0` — which is
also the version `firebase init functions` generates. `onCallWithData`,
`CallableOptions`, `Instances`, `TimeoutSeconds`, `firebase.adminApp`,
`runFunctions` and the builder are byte-for-byte the same API in 0.6.0.

**2. Errors use `InvalidArgumentError`, not `HttpResponseException`.** 0.6.0 has no
`HttpResponseException`; it has a sealed `HttpsError` hierarchy, and
`InvalidArgumentError(message)` is the invalid-argument member. This is better
for us than the 0.7.0 form: it is a native callable error, so the
`cloud_functions` plugin surfaces it as
`FirebaseFunctionsException(code: 'invalid-argument')` rather than an opaque 400.
`_handleCallable` catches `HttpsError` and converts it, so throwing from the
handler works.

**3. There is no `lib/testing.dart` in 0.6.0.** `runFunctionsTest` does not exist
at all, so the spec's optional in-process callable test is not merely skipped —
it is unavailable. Task 7 tests the handler directly, which is what the spec
allowed as the fallback.

**4. `build_runner 2.15.1` removed `--delete-conflicting-outputs`.** It warns and
ignores the flag. Every command and melos script here omits it.

**5. The deployed function is called `send-notification`, not `sendNotification`.**
Measured from the manifest Task 8 generated. `firebase_functions` runs every
registered name through `toCloudRunId`, so the camelCase name in
`register_functions.dart` is kebab-cased in three places at once: the
`functions.yaml` endpoint key, its `entryPoint`, and the path
`Firebase.registerFunction` routes on. The app must therefore call
`httpsCallable('send-notification')` — Task 9 is written that way. My earlier
probe missed this because its throwaway function was named `probe`, a single
lowercase word that the sanitiser leaves unchanged.

### The Task 8 gate already passed once

The probe proved the toolchain, so the risk the spec flagged is retired:

- `dart pub get` resolved the workspace with `firebase_functions 0.6.0`,
  `firebase_admin_sdk 0.5.4`, `build_runner 2.15.1`.
- `dart run build_runner build` wrote `apps/fcm_functions/functions.yaml` — in the
  package directory, which is exactly where the Firebase CLI reads it — with the
  endpoint discovered correctly: `maxInstances: 3`, `timeoutSeconds: 30`,
  `callableTrigger: {}`, `command: ./bin/server`.
- `dart compile exe … --target-os=linux --target-arch=x64` produced a 9.7 MB ELF
  x86-64 binary.

Task 8's gate steps stay in the plan as verification. But a failure there now
points at the code written in Tasks 6-8, **not** at the toolchain — do not go
looking for a workspace problem that has already been ruled out.

## Ordering note

The spec called for a throwaway spike proving `build_runner` works inside the pub workspace **before** anything else. This plan instead front-loads Tasks 1–5, the pure-Dart shared package, and puts the toolchain gate at Task 8. Nothing is wasted by that order: the shared package is required regardless of how `apps/fcm_functions` ends up being resolved, and it depends on no new tooling. **Task 8 is still a gate** — if generation or compilation cannot work inside the workspace, stop and revisit the design rather than working around it.

## File Structure

```
packages/fcm_gallery_shared/           Tasks 1-5
  lib/fcm_gallery_shared.dart          the only public entry point; exports src/
  lib/src/notification_event.dart      NotificationEvent
  lib/src/notification_priority.dart   NotificationPriority
  lib/src/notification_delivery.dart   NotificationDelivery
  lib/src/notification_draft.dart      NotificationDraft
  lib/src/notification_scenario.dart   NotificationScenario + notificationGallery
  lib/src/draft_problem.dart           DraftProblem
  lib/src/notification_draft_validator.dart  NotificationDraftValidator
  lib/src/send_notification_request.dart     SendNotificationRequest
  lib/src/send_notification_response.dart    SendNotificationResponse

apps/fcm_functions/                    Tasks 6-8
  bin/server.dart                      main() -> runFunctions(registerFunctions)
  lib/register_functions.dart          the callable declaration
  lib/send_notification_handler.dart   handleSendNotification + defaultPayloadId
  lib/notification_message_builder.dart NotificationMessageBuilder
  lib/fcm_message_sender.dart          FcmMessageSender interface
  lib/admin_fcm_message_sender.dart    AdminFcmMessageSender

apps/fcm_app/                          Tasks 9-12
  lib/sandbox/notification_sender.dart              interface
  lib/sandbox/callable_notification_sender.dart     cloud_functions impl
  lib/sandbox/unavailable_notification_sender.dart  always fails, with a reason
  lib/sandbox/sandbox_controller.dart               ChangeNotifier
  lib/ui/app_destination.dart          AppDestination enum
  lib/ui/app_shell.dart                AppShell (Scaffold + AppBar + drawer)
  lib/ui/app_drawer.dart               AppDrawer
  lib/ui/inbox_view.dart               renamed from inbox_screen.dart, no Scaffold
  lib/ui/sandbox_view.dart             SandboxView
  lib/ui/scenario_gallery.dart         ScenarioGallery
  lib/ui/draft_form_fields.dart        DraftFormFields (event, title, body)
  lib/ui/delivery_fields.dart          DeliveryFields (notification switch, priority)
  lib/ui/extra_data_editor.dart        ExtraDataEditor
  lib/ui/data_entry_row.dart           DataEntryRow
  lib/ui/send_result_card.dart         SendResultCard

root                                   Tasks 1, 6, 8, 12
  pubspec.yaml                         workspace members + melos scripts
  firebase.json                        NEW — the CLI's functions + emulators config
  .gitignore                           generated + compiled + credential artifacts
  README.md, apps/fcm_app/README.md    documentation
```

---

### Task 1: Shared package skeleton, `NotificationEvent`, `NotificationPriority`

**Files:**
- Create: `packages/fcm_gallery_shared/pubspec.yaml`
- Create: `packages/fcm_gallery_shared/analysis_options.yaml`
- Create: `packages/fcm_gallery_shared/lib/fcm_gallery_shared.dart`
- Create: `packages/fcm_gallery_shared/lib/src/notification_event.dart`
- Create: `packages/fcm_gallery_shared/lib/src/notification_priority.dart`
- Test: `packages/fcm_gallery_shared/test/notification_event_test.dart`
- Test: `packages/fcm_gallery_shared/test/notification_priority_test.dart`
- Modify: `pubspec.yaml` (root `workspace:` list)

**Interfaces:**
- Consumes: nothing.
- Produces: `abstract interface class WireNamed` with `String get wireName`, and the top-level `T? wireNamedFrom<T extends WireNamed>(Iterable<T> values, String wireName)`. `enum NotificationEvent implements WireNamed` with `final String wireName` and `static NotificationEvent? fromWireName(String wireName)`; values `chatMessage`, `buildFinished`, `promo`, `silentSync`. `enum NotificationPriority implements WireNamed` with the same shape; values `high`, `normal`.

**Amended after the Task 1 review.** This task originally prescribed a
copy-pasted linear-scan `fromWireName` body in each enum. The reviewer flagged
the duplication and the human ruled that the finding governs, so the search
lives once in `wireNamedFrom` and each enum keeps a one-line static that calls
it. `WireNamed` is worth having on its own terms: it names the concept the two
enums share — a value carrying a wire name that is deliberately decoupled from
its Dart identifier — rather than merely factoring out four lines.

- [ ] **Step 1: Add the package to the workspace and create its pubspec**

`pubspec.yaml` (root) — replace the `workspace:` list:

```yaml
workspace:
  - apps/fcm_app
  - packages/core
  - packages/fcm_gallery_shared
```

Create `packages/fcm_gallery_shared/pubspec.yaml`:

```yaml
name: fcm_gallery_shared
description: The contract shared by the FCM sample app and its Cloud Functions — notification events, gallery scenarios, callable DTOs and one validator used by both sides. Pure Dart, so it can be tested with plain `dart test`.
version: 1.0.0
publish_to: none
resolution: workspace

environment:
  sdk: ^3.12.2

dependencies:
  core:
    path: ../core

dev_dependencies:
  lints: ^6.0.0
  test: ^1.25.6
```

Create `packages/fcm_gallery_shared/analysis_options.yaml`:

```yaml
include:
  - package:lints/recommended.yaml
  - ../../analysis_options.yaml
```

- [ ] **Step 2: Resolve the workspace**

Run: `fvm dart pub get`
Expected: succeeds, and the output mentions `fcm_gallery_shared`. If resolution fails, stop — nothing later will work.

- [ ] **Step 3: Write the failing tests**

Create `packages/fcm_gallery_shared/test/notification_event_test.dart`:

```dart
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:test/test.dart';

void main() {
  group('NotificationEvent', () {
    test('wire names are unique, so fromWireName is unambiguous', () {
      final names = NotificationEvent.values.map((e) => e.wireName).toSet();

      expect(names, hasLength(NotificationEvent.values.length));
    });

    test('every value round-trips through its wire name', () {
      for (final event in NotificationEvent.values) {
        expect(NotificationEvent.fromWireName(event.wireName), event);
      }
    });

    test('wire names are snake_case, not the Dart identifier', () {
      expect(NotificationEvent.chatMessage.wireName, 'chat_message');
      expect(NotificationEvent.buildFinished.wireName, 'build_finished');
      expect(NotificationEvent.silentSync.wireName, 'silent_sync');
    });

    test('an unrecognised wire name resolves to null rather than throwing', () {
      expect(NotificationEvent.fromWireName('from_the_future'), isNull);
    });
  });
}
```

Create `packages/fcm_gallery_shared/test/notification_priority_test.dart`:

```dart
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:test/test.dart';

void main() {
  group('NotificationPriority', () {
    test('every value round-trips through its wire name', () {
      for (final priority in NotificationPriority.values) {
        expect(NotificationPriority.fromWireName(priority.wireName), priority);
      }
    });

    test('wire names match the FCM vocabulary', () {
      expect(NotificationPriority.high.wireName, 'high');
      expect(NotificationPriority.normal.wireName, 'normal');
    });

    test('an unrecognised wire name resolves to null', () {
      expect(NotificationPriority.fromWireName('urgent'), isNull);
    });
  });
}
```

- [ ] **Step 4: Run the tests to verify they fail**

Run: `fvm dart test packages/fcm_gallery_shared`
Expected: FAIL — `Target of URI doesn't exist: 'package:fcm_gallery_shared/fcm_gallery_shared.dart'`.

- [ ] **Step 5: Write the implementation**

Create `packages/fcm_gallery_shared/lib/src/notification_event.dart`:

```dart
/// The kind of notification a sandbox message stands for.
///
/// Travels in the FCM data payload under the `event` key. Nothing in `core` has
/// to know about it: `PushMessageParser` passes keys it does not recognise
/// straight through to `PushMessage.data`.
enum NotificationEvent {
  chatMessage('chat_message'),
  buildFinished('build_finished'),
  promo('promo'),
  silentSync('silent_sync');

  const NotificationEvent(this.wireName);

  /// The value that goes on the wire.
  ///
  /// Kept separate from the Dart identifier so renaming an enum value cannot
  /// silently change the payload a deployed sender produces.
  final String wireName;

  /// The event named by [wireName], or `null` when nothing matches.
  ///
  /// Returns `null` instead of throwing because a payload from an older or
  /// newer sender must not be able to break the inbox.
  static NotificationEvent? fromWireName(String wireName) =>
      wireNamedFrom(values, wireName);
}
```

And `packages/fcm_gallery_shared/lib/src/wire_named.dart`, which both enums use:

```dart
/// A value that travels under a name of its own, independent of its Dart
/// identifier.
///
/// Implemented by every enum in this package that crosses the wire, so renaming
/// an enum value cannot silently change the payload a deployed sender produces.
abstract interface class WireNamed {
  /// The value that goes on the wire.
  String get wireName;
}

/// The element of [values] whose [WireNamed.wireName] is [wireName], or `null`
/// when nothing matches.
///
/// Returns `null` rather than throwing: a payload from an older or newer sender
/// must not be able to break the receiver.
T? wireNamedFrom<T extends WireNamed>(Iterable<T> values, String wireName) {
  for (final value in values) {
    if (value.wireName == wireName) {
      return value;
    }
  }

  return null;
}
```

Create `packages/fcm_gallery_shared/lib/src/notification_priority.dart`:

```dart
/// The delivery priority requested for a message.
///
/// Maps onto `AndroidConfig.priority` on the sending side. The two values are
/// FCM's own vocabulary rather than an abstraction over it, so there is nothing
/// to translate when reading the Firebase docs.
enum NotificationPriority {
  high('high'),
  normal('normal');

  const NotificationPriority(this.wireName);

  /// The value that goes on the wire. See [NotificationEvent.wireName].
  final String wireName;

  /// The priority named by [wireName], or `null` when nothing matches.
  static NotificationPriority? fromWireName(String wireName) =>
      wireNamedFrom(values, wireName);
}
```

Create `packages/fcm_gallery_shared/lib/fcm_gallery_shared.dart`:

```dart
/// The contract shared by `fcm_app` and `fcm_functions`.
///
/// Pure Dart on purpose: the app, the functions and their tests all import this
/// library, so it must not drag in Flutter or the Firebase SDKs.
library;

export 'src/notification_event.dart';
export 'src/notification_priority.dart';
export 'src/wire_named.dart';
```

- [ ] **Step 6: Run the tests to verify they pass**

Run: `fvm dart test packages/fcm_gallery_shared`
Expected: PASS, 7 tests.

- [ ] **Step 7: Check the analyzer and DCM**

Run: `fvm dart analyze --fatal-infos --fatal-warnings packages/fcm_gallery_shared`
Then: `fvm exec dcm analyze --fatal-style --fatal-warnings packages/fcm_gallery_shared`
Expected: no issues from either.

- [ ] **Step 8: Commit**

```bash
git add pubspec.yaml pubspec.lock packages/fcm_gallery_shared
git commit -m "feat(shared): add fcm_gallery_shared with the notification event and priority enums"
```

---

### Task 2: `NotificationDelivery` and `NotificationDraft`

**Files:**
- Create: `packages/fcm_gallery_shared/lib/src/notification_delivery.dart`
- Create: `packages/fcm_gallery_shared/lib/src/notification_draft.dart`
- Modify: `packages/fcm_gallery_shared/lib/fcm_gallery_shared.dart`
- Test: `packages/fcm_gallery_shared/test/notification_delivery_test.dart`
- Test: `packages/fcm_gallery_shared/test/notification_draft_test.dart`

**Interfaces:**
- Consumes: `NotificationEvent`, `NotificationPriority` from Task 1.
- Produces:
  - `class NotificationDelivery` — `const NotificationDelivery({bool asNotification = true, NotificationPriority priority = NotificationPriority.high})`, `factory NotificationDelivery.fromJson(Map<String, dynamic>)`, `NotificationDelivery copyWith({bool? asNotification, NotificationPriority? priority})`, `Map<String, dynamic> toJson()`, value equality.
  - `class NotificationDraft` — `const NotificationDraft({required NotificationEvent event, required String title, required String body, Map<String, String> data = const {}, NotificationDelivery delivery = const NotificationDelivery()})`, `factory NotificationDraft.fromJson(Map<String, dynamic>)`, `NotificationDraft copyWith({NotificationEvent? event, String? title, String? body, Map<String, String>? data, NotificationDelivery? delivery})`, `Map<String, dynamic> toJson()`, value equality.

- [ ] **Step 1: Write the failing tests**

Create `packages/fcm_gallery_shared/test/notification_delivery_test.dart`:

```dart
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:test/test.dart';

void main() {
  group('NotificationDelivery', () {
    test('defaults to a visible, high-priority notification', () {
      const delivery = NotificationDelivery();

      expect(delivery.asNotification, isTrue);
      expect(delivery.priority, NotificationPriority.high);
    });

    test('round-trips through JSON', () {
      const delivery = NotificationDelivery(
        asNotification: false,
        priority: NotificationPriority.normal,
      );

      expect(NotificationDelivery.fromJson(delivery.toJson()), delivery);
    });

    test('copyWith replaces one field and leaves the other alone', () {
      const delivery = NotificationDelivery();

      final silent = delivery.copyWith(asNotification: false);

      expect(silent.asNotification, isFalse);
      expect(silent.priority, NotificationPriority.high);
    });

    test('an unknown priority is a format error, not a silent default', () {
      expect(
        () => NotificationDelivery.fromJson({
          'asNotification': true,
          'priority': 'urgent',
        }),
        throwsFormatException,
      );
    });
  });
}
```

Create `packages/fcm_gallery_shared/test/notification_draft_test.dart`:

```dart
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:test/test.dart';

const _draft = NotificationDraft(
  event: NotificationEvent.chatMessage,
  title: 'Ada replied',
  body: 'See you at the seminar.',
  data: {'deepLink': '/chats/7'},
  delivery: NotificationDelivery(priority: NotificationPriority.normal),
);

void main() {
  group('NotificationDraft', () {
    test('round-trips through JSON, extra data included', () {
      expect(NotificationDraft.fromJson(_draft.toJson()), _draft);
    });

    test('defaults to no extra data and a visible high-priority notification',
        () {
      const draft = NotificationDraft(
        event: NotificationEvent.promo,
        title: 'Sale',
        body: 'Half price.',
      );

      expect(draft.data, isEmpty);
      expect(draft.delivery, const NotificationDelivery());
    });

    test('copyWith replaces only what it is given', () {
      final edited = _draft.copyWith(title: 'Ada replied twice');

      expect(edited.title, 'Ada replied twice');
      expect(edited.body, _draft.body);
      expect(edited.data, _draft.data);
      expect(edited.delivery, _draft.delivery);
    });

    test('an unknown event is a format error', () {
      final json = _draft.toJson()..['event'] = 'nope';

      expect(() => NotificationDraft.fromJson(json), throwsFormatException);
    });

    test('a missing event is a format error', () {
      final json = _draft.toJson()..remove('event');

      expect(() => NotificationDraft.fromJson(json), throwsFormatException);
    });

    test('non-string data values are stringified rather than rejected', () {
      final draft = NotificationDraft.fromJson({
        ..._draft.toJson(),
        'data': {'attempt': 2},
      });

      expect(draft.data, {'attempt': '2'});
    });

    test('data is unmodifiable, so a draft cannot be mutated after the fact',
        () {
      final draft = NotificationDraft.fromJson(_draft.toJson());

      expect(() => draft.data['sneaky'] = 'yes', throwsUnsupportedError);
    });
  });
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `fvm dart test packages/fcm_gallery_shared`
Expected: FAIL — `NotificationDelivery` and `NotificationDraft` are undefined.

- [ ] **Step 3: Write `NotificationDelivery`**

Create `packages/fcm_gallery_shared/lib/src/notification_delivery.dart`:

```dart
import 'notification_priority.dart';

/// How a message should reach the device, as opposed to what it says.
///
/// Grouping these two together keeps `NotificationDraft` inside the parameter
/// budget the shared DCM configuration allows, and they belong together anyway:
/// a silent message and a visible one are two different delivery modes, not two
/// unrelated flags.
class NotificationDelivery {
  const NotificationDelivery({
    this.asNotification = true,
    this.priority = NotificationPriority.high,
  });

  /// Reads a delivery written by [toJson].
  ///
  /// Throws [FormatException] on an unknown priority rather than defaulting:
  /// silently downgrading a message the caller asked to be urgent is worse than
  /// refusing it.
  factory NotificationDelivery.fromJson(Map<String, dynamic> json) {
    final rawPriority = json['priority'] as String?;
    final priority = rawPriority == null
        ? null
        : NotificationPriority.fromWireName(rawPriority);
    if (priority == null) {
      throw FormatException('Unknown notification priority: $rawPriority');
    }

    return NotificationDelivery(
      asNotification: json['asNotification'] as bool? ?? true,
      priority: priority,
    );
  }

  /// Whether FCM should show a notification. `false` sends a data-only push,
  /// which arrives silently and wakes the app instead.
  final bool asNotification;

  /// The delivery priority requested from FCM.
  final NotificationPriority priority;

  NotificationDelivery copyWith({
    bool? asNotification,
    NotificationPriority? priority,
  }) => NotificationDelivery(
    asNotification: asNotification ?? this.asNotification,
    priority: priority ?? this.priority,
  );

  Map<String, dynamic> toJson() => {
    'asNotification': asNotification,
    'priority': priority.wireName,
  };

  @override
  bool operator ==(Object other) =>
      other is NotificationDelivery &&
      asNotification == other.asNotification &&
      priority == other.priority;

  @override
  int get hashCode => Object.hash(asNotification, priority);

  @override
  String toString() =>
      'NotificationDelivery(asNotification: $asNotification, '
      'priority: ${priority.wireName})';
}
```

- [ ] **Step 4: Write `NotificationDraft`**

Create `packages/fcm_gallery_shared/lib/src/notification_draft.dart`:

```dart
import 'notification_delivery.dart';
import 'notification_event.dart';

/// Everything the sandbox lets you decide about a message.
///
/// This is the value the editor edits, the value a gallery scenario supplies as
/// a starting point, and the value that travels inside
/// `SendNotificationRequest`. It carries no ids and no timestamp: those are
/// stamped by the function, so the app has no authority over what it is about
/// to receive.
class NotificationDraft {
  const NotificationDraft({
    required this.event,
    required this.title,
    required this.body,
    this.data = const {},
    this.delivery = const NotificationDelivery(),
  });

  /// Reads a draft written by [toJson].
  ///
  /// Throws [FormatException] on a missing or unknown event. Extra data values
  /// are stringified because FCM data payloads are `String`-valued on the wire
  /// anyway, so coercing here is closer to the truth than rejecting.
  factory NotificationDraft.fromJson(Map<String, dynamic> json) {
    final rawEvent = json['event'] as String?;
    final event = rawEvent == null
        ? null
        : NotificationEvent.fromWireName(rawEvent);
    if (event == null) {
      throw FormatException('Unknown notification event: $rawEvent');
    }

    final rawData = json['data'];
    final data = <String, String>{};
    if (rawData is Map) {
      for (final entry in rawData.entries) {
        data['${entry.key}'] = '${entry.value}';
      }
    }

    final rawDelivery = json['delivery'];

    return NotificationDraft(
      event: event,
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      data: Map.unmodifiable(data),
      delivery: rawDelivery is Map<String, dynamic>
          ? NotificationDelivery.fromJson(rawDelivery)
          : const NotificationDelivery(),
    );
  }

  /// The archetype this message stands for. Travels as the `event` data key.
  final NotificationEvent event;

  /// Notification title, and the `title` data key.
  final String title;

  /// Notification body, and the `body` data key.
  final String body;

  /// Extra data keys, passed through to the device untouched.
  final Map<String, String> data;

  /// How the message should reach the device.
  final NotificationDelivery delivery;

  NotificationDraft copyWith({
    NotificationEvent? event,
    String? title,
    String? body,
    Map<String, String>? data,
    NotificationDelivery? delivery,
  }) => NotificationDraft(
    event: event ?? this.event,
    title: title ?? this.title,
    body: body ?? this.body,
    data: data ?? this.data,
    delivery: delivery ?? this.delivery,
  );

  Map<String, dynamic> toJson() => {
    'event': event.wireName,
    'title': title,
    'body': body,
    'data': data,
    'delivery': delivery.toJson(),
  };

  @override
  bool operator ==(Object other) =>
      other is NotificationDraft &&
      event == other.event &&
      title == other.title &&
      body == other.body &&
      delivery == other.delivery &&
      _sameData(other.data);

  @override
  int get hashCode =>
      Object.hash(event, title, body, delivery, data.length);

  @override
  String toString() =>
      'NotificationDraft(event: ${event.wireName}, title: $title, '
      'delivery: $delivery, extra keys: ${data.keys.toList()})';

  bool _sameData(Map<String, String> other) {
    if (data.length != other.length) {
      return false;
    }

    for (final entry in data.entries) {
      if (other[entry.key] != entry.value) {
        return false;
      }
    }

    return true;
  }
}
```

- [ ] **Step 5: Export both types**

`packages/fcm_gallery_shared/lib/fcm_gallery_shared.dart` — the export list becomes:

```dart
export 'src/notification_delivery.dart';
export 'src/notification_draft.dart';
export 'src/notification_event.dart';
export 'src/notification_priority.dart';
```

- [ ] **Step 6: Run the tests to verify they pass**

Run: `fvm dart test packages/fcm_gallery_shared`
Expected: PASS, 18 tests.

- [ ] **Step 7: Check the analyzer and DCM**

Run: `fvm dart analyze --fatal-infos --fatal-warnings packages/fcm_gallery_shared`
Then: `fvm exec dcm analyze --fatal-style --fatal-warnings packages/fcm_gallery_shared`
Expected: no issues. If `source-lines-of-code` fires on `NotificationDraft.fromJson`, extract the data-coercion loop into a private top-level `Map<String, String> _stringifyData(Object? raw)`.

- [ ] **Step 8: Commit**

```bash
git add packages/fcm_gallery_shared
git commit -m "feat(shared): add NotificationDelivery and NotificationDraft"
```

---

### Task 3: `NotificationScenario` and the gallery catalogue

**Files:**
- Create: `packages/fcm_gallery_shared/lib/src/notification_scenario.dart`
- Modify: `packages/fcm_gallery_shared/lib/fcm_gallery_shared.dart`
- Test: `packages/fcm_gallery_shared/test/notification_scenario_test.dart`

**Interfaces:**
- Consumes: `NotificationDraft`, `NotificationDelivery`, `NotificationEvent`, `NotificationPriority`.
- Produces: `class NotificationScenario` — `const NotificationScenario({required String id, required String label, required String description, required NotificationDraft draft})`; and `const List<NotificationScenario> notificationGallery` with ids `chat-message`, `build-finished`, `promo`, `silent-sync`.

- [ ] **Step 1: Write the failing test**

Create `packages/fcm_gallery_shared/test/notification_scenario_test.dart`:

```dart
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:test/test.dart';

void main() {
  group('notificationGallery', () {
    test('ids are unique, so a scenario can be addressed by id', () {
      final ids = notificationGallery.map((s) => s.id).toSet();

      expect(ids, hasLength(notificationGallery.length));
    });

    test('every scenario has a label and a description to show', () {
      for (final scenario in notificationGallery) {
        expect(scenario.label, isNotEmpty, reason: scenario.id);
        expect(scenario.description, isNotEmpty, reason: scenario.id);
      }
    });

    test('covers every event exactly once, so the gallery is a full tour', () {
      final events = notificationGallery.map((s) => s.draft.event).toList();

      expect(events, unorderedEquals(NotificationEvent.values));
    });

    test('the silent scenario is the one that sends data only', () {
      final silent = notificationGallery.firstWhere(
        (s) => s.id == 'silent-sync',
      );

      expect(silent.draft.delivery.asNotification, isFalse);
    });

    test('the chat scenario carries a deep link, exercising extra data keys',
        () {
      final chat = notificationGallery.firstWhere(
        (s) => s.id == 'chat-message',
      );

      expect(chat.draft.data, containsPair('deepLink', '/chats/7'));
    });

    test('the promo scenario is normal priority, not everything is urgent', () {
      final promo = notificationGallery.firstWhere((s) => s.id == 'promo');

      expect(promo.draft.delivery.priority, NotificationPriority.normal);
    });
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `fvm dart test packages/fcm_gallery_shared/test/notification_scenario_test.dart`
Expected: FAIL — `notificationGallery` is undefined.

- [ ] **Step 3: Write the implementation**

Create `packages/fcm_gallery_shared/lib/src/notification_scenario.dart`:

```dart
import 'notification_delivery.dart';
import 'notification_draft.dart';
import 'notification_event.dart';
import 'notification_priority.dart';

/// A ready-made starting point for the sandbox editor.
///
/// A scenario is only a set of defaults: applying one replaces the form
/// contents, and everything stays editable afterwards. Nothing downstream
/// knows scenarios exist — the wire only ever carries a `NotificationDraft`.
class NotificationScenario {
  const NotificationScenario({
    required this.id,
    required this.label,
    required this.description,
    required this.draft,
  });

  /// Stable identifier, used as a widget key and in tests.
  final String id;

  /// Short name for the gallery chip.
  final String label;

  /// One line explaining what this scenario demonstrates.
  final String description;

  /// The values the editor starts from.
  final NotificationDraft draft;

  @override
  String toString() => 'NotificationScenario($id)';
}

/// The scenarios the sandbox offers.
///
/// Chosen to cover the axes that behave differently — visible versus silent,
/// high versus normal priority, with and without extra data keys — rather than
/// four variations on the same message. `notification_scenario_test.dart`
/// asserts the tour is complete.
const notificationGallery = <NotificationScenario>[
  NotificationScenario(
    id: 'chat-message',
    label: 'Chat message',
    description: 'High priority, visible, and carries a deep link.',
    draft: NotificationDraft(
      event: NotificationEvent.chatMessage,
      title: 'Ada replied',
      body: 'See you at the seminar.',
      data: {'deepLink': '/chats/7'},
    ),
  ),
  NotificationScenario(
    id: 'build-finished',
    label: 'Build finished',
    description: 'The payload shape documented in the root README.',
    draft: NotificationDraft(
      event: NotificationEvent.buildFinished,
      title: 'Build finished',
      body: 'Release 1.0.0 is ready.',
      data: {'deepLink': '/builds/42'},
      delivery: NotificationDelivery(priority: NotificationPriority.normal),
    ),
  ),
  NotificationScenario(
    id: 'promo',
    label: 'Promo',
    description: 'Normal priority — not everything deserves to be urgent.',
    draft: NotificationDraft(
      event: NotificationEvent.promo,
      title: 'Half price this week',
      body: 'Every seminar, until Sunday.',
      data: {'campaign': 'summer-2026'},
      delivery: NotificationDelivery(priority: NotificationPriority.normal),
    ),
  ),
  NotificationScenario(
    id: 'silent-sync',
    label: 'Silent sync',
    description: 'Data only: nothing is shown, the app is woken instead.',
    draft: NotificationDraft(
      event: NotificationEvent.silentSync,
      title: 'Sync requested',
      body: 'The device should refresh its cache.',
      delivery: NotificationDelivery(asNotification: false),
    ),
  ),
];
```

- [ ] **Step 4: Export it**

Add to `packages/fcm_gallery_shared/lib/fcm_gallery_shared.dart`, keeping the list alphabetical:

```dart
export 'src/notification_scenario.dart';
```

- [ ] **Step 5: Run the tests to verify they pass**

Run: `fvm dart test packages/fcm_gallery_shared`
Expected: PASS, 24 tests.

- [ ] **Step 6: Check the analyzer and DCM**

Run: `fvm dart analyze --fatal-infos --fatal-warnings packages/fcm_gallery_shared`
Then: `fvm exec dcm analyze --fatal-style --fatal-warnings packages/fcm_gallery_shared`
Expected: no issues.

- [ ] **Step 7: Commit**

```bash
git add packages/fcm_gallery_shared
git commit -m "feat(shared): add notification scenarios and the gallery catalogue"
```

---

### Task 4: `DraftProblem` and `NotificationDraftValidator`

**Files:**
- Create: `packages/fcm_gallery_shared/lib/src/draft_problem.dart`
- Create: `packages/fcm_gallery_shared/lib/src/notification_draft_validator.dart`
- Modify: `packages/fcm_gallery_shared/lib/fcm_gallery_shared.dart`
- Test: `packages/fcm_gallery_shared/test/notification_draft_validator_test.dart`

**Interfaces:**
- Consumes: `NotificationDraft`, `notificationGallery`, and `PushMessageParser.reservedKeys` from `package:core/core.dart`.
- Produces:
  - `class DraftProblem` — `const DraftProblem(this.field, this.reason)`, both `String`, with value equality and a `toString()` of `'<field>: <reason>'`.
  - `class NotificationDraftValidator` — `const NotificationDraftValidator()`, `List<DraftProblem> validate(NotificationDraft draft)`, and `static const Set<String> reservedDataKeys`.

**Field names used in `DraftProblem.field`:** `'title'`, `'body'`, and `'data'` — Task 9 and Task 11 match on exactly these strings.

- [ ] **Step 1: Write the failing test**

Create `packages/fcm_gallery_shared/test/notification_draft_validator_test.dart`:

```dart
import 'package:core/core.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:test/test.dart';

const _validator = NotificationDraftValidator();

const _valid = NotificationDraft(
  event: NotificationEvent.promo,
  title: 'Sale',
  body: 'Half price.',
);

List<String> _fields(NotificationDraft draft) =>
    _validator.validate(draft).map((problem) => problem.field).toList();

void main() {
  group('NotificationDraftValidator', () {
    test('a well-formed draft has no problems', () {
      expect(_validator.validate(_valid), isEmpty);
    });

    test('every gallery scenario validates clean', () {
      for (final scenario in notificationGallery) {
        expect(
          _validator.validate(scenario.draft),
          isEmpty,
          reason: scenario.id,
        );
      }
    });

    test('a visible notification needs a title and a body', () {
      final blank = _valid.copyWith(title: '  ', body: '');

      expect(_fields(blank), containsAll(['title', 'body']));
    });

    test('a silent message may have neither, since nothing is shown', () {
      final silent = _valid.copyWith(
        title: '',
        body: '',
        delivery: const NotificationDelivery(asNotification: false),
      );

      expect(_validator.validate(silent), isEmpty);
    });

    test('a blank extra data key is a problem', () {
      final draft = _valid.copyWith(data: const {'  ': 'value'});

      expect(_fields(draft), contains('data'));
    });

    test('an extra data key may not collide with a reserved payload key', () {
      for (final reserved in PushMessageParser.reservedKeys) {
        final draft = _valid.copyWith(data: {reserved: 'value'});

        expect(_fields(draft), contains('data'), reason: reserved);
      }
    });

    test('the event key is reserved too, since the builder writes it', () {
      final draft = _valid.copyWith(data: const {'event': 'promo'});

      expect(_fields(draft), contains('data'));
    });

    test('the reserved set is core\'s keys plus event, defined in one place',
        () {
      expect(
        NotificationDraftValidator.reservedDataKeys,
        {...PushMessageParser.reservedKeys, 'event'},
      );
    });

    test('a problem names its field and reason when printed', () {
      const problem = DraftProblem('title', 'must not be blank');

      expect('$problem', 'title: must not be blank');
    });
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `fvm dart test packages/fcm_gallery_shared/test/notification_draft_validator_test.dart`
Expected: FAIL — `NotificationDraftValidator` is undefined.

- [ ] **Step 3: Write `DraftProblem`**

Create `packages/fcm_gallery_shared/lib/src/draft_problem.dart`:

```dart
/// One reason a [NotificationDraft] cannot be sent.
///
/// Carries the field it belongs to so the editor can render it against the
/// right input, and the function can name it in a 400 response.
class DraftProblem {
  const DraftProblem(this.field, this.reason);

  /// Which part of the draft is at fault: `title`, `body` or `data`.
  final String field;

  /// What is wrong with it, phrased for a person to read.
  final String reason;

  @override
  bool operator ==(Object other) =>
      other is DraftProblem && field == other.field && reason == other.reason;

  @override
  int get hashCode => Object.hash(field, reason);

  @override
  String toString() => '$field: $reason';
}
```

- [ ] **Step 4: Write `NotificationDraftValidator`**

Create `packages/fcm_gallery_shared/lib/src/notification_draft_validator.dart`:

```dart
import 'package:core/core.dart';

import 'draft_problem.dart';
import 'notification_draft.dart';

/// Checks a draft before it is sent.
///
/// Deliberately shared: the editor uses it to render inline errors and to
/// disable its send button, and the function runs it again on the request it
/// receives. The app is therefore not the only line of defence, and there is
/// only one place to change a rule.
class NotificationDraftValidator {
  const NotificationDraftValidator();

  /// Data keys the sender writes itself, which a draft may not overwrite.
  ///
  /// Built from `core`'s own set so the four keys `PushMessageParser` requires
  /// stay defined in exactly one place, plus `event`, which
  /// `NotificationMessageBuilder` adds.
  static const reservedDataKeys = {...PushMessageParser.reservedKeys, 'event'};

  /// Every problem with [draft], in a stable order. Empty means sendable.
  List<DraftProblem> validate(NotificationDraft draft) => [
    if (draft.delivery.asNotification) ..._visibleTextProblems(draft),
    ..._dataProblems(draft),
  ];

  /// A silent push shows nothing, so blank text is only a problem when FCM is
  /// being asked to display it.
  List<DraftProblem> _visibleTextProblems(NotificationDraft draft) => [
    if (draft.title.trim().isEmpty)
      const DraftProblem('title', 'must not be blank'),
    if (draft.body.trim().isEmpty)
      const DraftProblem('body', 'must not be blank'),
  ];

  List<DraftProblem> _dataProblems(NotificationDraft draft) {
    final problems = <DraftProblem>[];
    for (final key in draft.data.keys) {
      if (key.trim().isEmpty) {
        problems.add(const DraftProblem('data', 'a key must not be blank'));
      } else if (reservedDataKeys.contains(key)) {
        problems.add(
          DraftProblem('data', '"$key" is written by the sender, pick another'),
        );
      }
    }

    return problems;
  }
}
```

- [ ] **Step 5: Export both types**

Add to `packages/fcm_gallery_shared/lib/fcm_gallery_shared.dart`, keeping the list alphabetical:

```dart
export 'src/draft_problem.dart';
export 'src/notification_draft_validator.dart';
```

- [ ] **Step 6: Run the tests to verify they pass**

Run: `fvm dart test packages/fcm_gallery_shared`
Expected: PASS, 33 tests.

- [ ] **Step 7: Check the analyzer and DCM**

Run: `fvm dart analyze --fatal-infos --fatal-warnings packages/fcm_gallery_shared`
Then: `fvm exec dcm analyze --fatal-style --fatal-warnings packages/fcm_gallery_shared`
Expected: no issues.

- [ ] **Step 8: Commit**

```bash
git add packages/fcm_gallery_shared
git commit -m "feat(shared): add the draft validator shared by app and functions"
```

---

### Task 5: The callable DTOs

**Files:**
- Create: `packages/fcm_gallery_shared/lib/src/send_notification_request.dart`
- Create: `packages/fcm_gallery_shared/lib/src/send_notification_response.dart`
- Modify: `packages/fcm_gallery_shared/lib/fcm_gallery_shared.dart`
- Test: `packages/fcm_gallery_shared/test/send_notification_dto_test.dart`

**Interfaces:**
- Consumes: `NotificationDraft`.
- Produces:
  - `class SendNotificationRequest` — `const SendNotificationRequest({required String token, required NotificationDraft draft})`, `factory SendNotificationRequest.fromJson(Map<String, dynamic>)`, `Map<String, dynamic> toJson()`, value equality.
  - `class SendNotificationResponse` — `const SendNotificationResponse({required String messageId, required String payloadId, required DateTime sentAt})`, `factory SendNotificationResponse.fromJson(Map<String, dynamic>)`, `Map<String, dynamic> toJson()` with `sentAt` as an ISO-8601 UTC string, value equality.

- [ ] **Step 1: Write the failing test**

Create `packages/fcm_gallery_shared/test/send_notification_dto_test.dart`:

```dart
import 'dart:convert';

import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:test/test.dart';

const _request = SendNotificationRequest(
  token: 'device-token',
  draft: NotificationDraft(
    event: NotificationEvent.buildFinished,
    title: 'Build finished',
    body: 'Release 1.0.0 is ready.',
  ),
);

final _response = SendNotificationResponse(
  messageId: 'projects/fcm-sandbox-770fa/messages/1',
  payloadId: 'sandbox-1754812800000000',
  sentAt: DateTime.utc(2026, 8, 10, 9, 30),
);

void main() {
  group('SendNotificationRequest', () {
    test('round-trips through JSON', () {
      expect(SendNotificationRequest.fromJson(_request.toJson()), _request);
    });

    test('a missing token is a format error', () {
      final json = _request.toJson()..remove('token');

      expect(
        () => SendNotificationRequest.fromJson(json),
        throwsFormatException,
      );
    });
  });

  group('SendNotificationResponse', () {
    test('round-trips through JSON', () {
      expect(SendNotificationResponse.fromJson(_response.toJson()), _response);
    });

    test('sentAt is serialised as an ISO-8601 UTC string', () {
      expect(_response.toJson()['sentAt'], '2026-08-10T09:30:00.000Z');
    });

    test('sentAt is normalised to UTC on the way in', () {
      final local = SendNotificationResponse(
        messageId: 'm',
        payloadId: 'p',
        sentAt: DateTime.utc(2026, 8, 10).toLocal(),
      );

      expect(local.sentAt.isUtc, isTrue);
    });

    test('jsonEncode works on the object itself', () {
      // This is exactly what firebase_functions does with the returned value:
      // jsonEncode({'result': response}), which reaches toJson via toEncodable.
      final encoded = jsonEncode({'result': _response});

      expect(encoded, contains('sandbox-1754812800000000'));
    });

    test('an unparseable sentAt is a format error', () {
      final json = _response.toJson()..['sentAt'] = 'yesterday';

      expect(
        () => SendNotificationResponse.fromJson(json),
        throwsFormatException,
      );
    });

    test('a missing messageId is a format error, not the string "null"', () {
      final json = _response.toJson()..remove('messageId');

      expect(
        () => SendNotificationResponse.fromJson(json),
        throwsFormatException,
      );
    });

    test('a missing payloadId is a format error, not the string "null"', () {
      final json = _response.toJson()..remove('payloadId');

      expect(
        () => SendNotificationResponse.fromJson(json),
        throwsFormatException,
      );
    });
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `fvm dart test packages/fcm_gallery_shared/test/send_notification_dto_test.dart`
Expected: FAIL — the DTOs are undefined.

- [ ] **Step 3: Write `SendNotificationRequest`**

Create `packages/fcm_gallery_shared/lib/src/send_notification_request.dart`:

```dart
import 'notification_draft.dart';

/// What the app asks the `sendNotification` callable to do.
///
/// The token is the caller's own registration token: the sandbox only ever
/// sends to the device it is running on, which is why an unauthenticated
/// function is an acceptable risk here.
class SendNotificationRequest {
  const SendNotificationRequest({required this.token, required this.draft});

  /// Reads a request written by [toJson].
  factory SendNotificationRequest.fromJson(Map<String, dynamic> json) {
    final token = json['token'] as String?;
    if (token == null) {
      throw const FormatException('sendNotification request has no token');
    }

    final draft = json['draft'];
    if (draft is! Map<String, dynamic>) {
      throw const FormatException('sendNotification request has no draft');
    }

    return SendNotificationRequest(
      token: token,
      draft: NotificationDraft.fromJson(draft),
    );
  }

  /// The FCM registration token of the device that should receive the message.
  final String token;

  /// What to send.
  final NotificationDraft draft;

  Map<String, dynamic> toJson() => {'token': token, 'draft': draft.toJson()};

  @override
  bool operator ==(Object other) =>
      other is SendNotificationRequest &&
      token == other.token &&
      draft == other.draft;

  @override
  int get hashCode => Object.hash(token, draft);

  @override
  String toString() => 'SendNotificationRequest(draft: $draft)';
}
```

- [ ] **Step 4: Write `SendNotificationResponse`**

Create `packages/fcm_gallery_shared/lib/src/send_notification_response.dart`:

```dart
/// What the `sendNotification` callable reports back.
///
/// [payloadId] is the value the function put in the payload's `id` key, so the
/// sandbox can show the id that is about to appear in the inbox. That makes the
/// round trip visible instead of something the user has to infer.
class SendNotificationResponse {
  SendNotificationResponse({
    required this.messageId,
    required this.payloadId,
    required DateTime sentAt,
  }) : sentAt = sentAt.toUtc();

  /// Reads a response written by [toJson].
  ///
  /// Every field is required and validated. Interpolating a missing key would
  /// yield the four-character string `"null"`, so the sandbox would report
  /// `Sent · id null` instead of failing — which is exactly the wire-format
  /// drift this boundary exists to catch.
  factory SendNotificationResponse.fromJson(Map<String, dynamic> json) {
    final sentAt = DateTime.tryParse('${json['sentAt']}');
    if (sentAt == null) {
      throw FormatException('Unparseable sentAt: ${json['sentAt']}');
    }

    return SendNotificationResponse(
      messageId: _requireString(json, 'messageId'),
      payloadId: _requireString(json, 'payloadId'),
      sentAt: sentAt,
    );
  }

  /// The message name FCM assigned, useful for correlating with Firebase logs.
  final String messageId;

  /// The `id` data key the function stamped. Matches `PushMessage.id`.
  final String payloadId;

  /// When the function stamped the payload, in UTC.
  final DateTime sentAt;

  Map<String, dynamic> toJson() => {
    'messageId': messageId,
    'payloadId': payloadId,
    'sentAt': sentAt.toIso8601String(),
  };

  @override
  bool operator ==(Object other) =>
      other is SendNotificationResponse &&
      messageId == other.messageId &&
      payloadId == other.payloadId &&
      sentAt == other.sentAt;

  @override
  int get hashCode => Object.hash(messageId, payloadId, sentAt);

  @override
  String toString() =>
      'SendNotificationResponse(payloadId: $payloadId, sentAt: $sentAt)';
}

/// Reads a required `String` field, or throws [FormatException].
String _requireString(Map<String, dynamic> json, String field) {
  final value = json[field];
  if (value is! String) {
    throw FormatException(
      'sendNotification response field "$field" must be a String, '
      'got ${value.runtimeType}',
    );
  }

  return value;
}
```

**Amended after the Task 5 review.** This factory originally read `messageId`
and `payloadId` by interpolation, so a missing key became the string `"null"`
rather than an error — while `sentAt` was validated, because
`DateTime.tryParse('null')` returns null. Two of three fields checked and one
pair not was an oversight in this plan, not a deliberate asymmetry. The reviewer
flagged it and the human ruled the finding governs.

- [ ] **Step 5: Export both types**

Add to `packages/fcm_gallery_shared/lib/fcm_gallery_shared.dart`, keeping the list alphabetical:

```dart
export 'src/send_notification_request.dart';
export 'src/send_notification_response.dart';
```

- [ ] **Step 6: Run the tests to verify they pass**

Run: `fvm dart test packages/fcm_gallery_shared`
Expected: PASS, 40 tests.

- [ ] **Step 7: Check the analyzer and DCM**

Run: `fvm dart analyze --fatal-infos --fatal-warnings packages/fcm_gallery_shared`
Then: `fvm exec dcm analyze --fatal-style --fatal-warnings packages/fcm_gallery_shared`
Expected: no issues.

- [ ] **Step 8: Commit**

```bash
git add packages/fcm_gallery_shared
git commit -m "feat(shared): add the sendNotification request and response DTOs"
```

---

### Task 6: The functions package and `NotificationMessageBuilder`

**Files:**
- Create: `apps/fcm_functions/pubspec.yaml`
- Create: `apps/fcm_functions/analysis_options.yaml`
- Create: `apps/fcm_functions/lib/notification_message_builder.dart`
- Test: `apps/fcm_functions/test/notification_message_builder_test.dart`
- Modify: `pubspec.yaml` (root `workspace:` list)
- Modify: `.gitignore`

**Interfaces:**
- Consumes: everything exported by `package:fcm_gallery_shared/fcm_gallery_shared.dart`.
- Produces: `class NotificationMessageBuilder` — `const NotificationMessageBuilder()`, and
  `TokenMessage build({required NotificationDraft draft, required String token, required String payloadId, required DateTime sentAt})`.

**Why the package exists before the entry point:** the builder is pure translation and needs no Firebase runtime, so it is testable on its own. `bin/server.dart` and the deploy toolchain arrive in Task 8.

- [ ] **Step 1: Create the package and add it to the workspace**

`pubspec.yaml` (root) — the `workspace:` list becomes:

```yaml
workspace:
  - apps/fcm_app
  - apps/fcm_functions
  - packages/core
  - packages/fcm_gallery_shared
```

Create `apps/fcm_functions/pubspec.yaml`:

```yaml
name: fcm_functions
description: Cloud Functions for Firebase, written in Dart, that send the notifications composed in the fcm_app sandbox. Deployed as a pre-compiled linux-x64 executable.
version: 1.0.0
publish_to: none
resolution: workspace

environment:
  sdk: ^3.12.2

dependencies:
  fcm_gallery_shared:
    path: ../../packages/fcm_gallery_shared
  firebase_admin_sdk: ^0.5.4
  firebase_functions: ^0.6.0

dev_dependencies:
  build_runner: ^2.10.5
  lints: ^6.0.0
  test: ^1.25.6
```

Create `apps/fcm_functions/analysis_options.yaml`:

```yaml
include:
  - package:lints/recommended.yaml
  - ../../analysis_options.yaml
```

- [ ] **Step 2: Resolve the workspace — the first real toolchain signal**

Run: `fvm dart pub get`
Expected: succeeds and reports `fcm_functions`, resolving `firebase_functions 0.6.0`, `firebase_admin_sdk 0.5.4` and `build_runner 2.15.1`. A pre-flight probe already confirmed this exact resolution, so **if it fails on a version conflict, stop and report it** — do not "fix" it by loosening a constraint or bumping `firebase_functions` to `^0.7.0`, which is known not to resolve against Flutter 3.44.8's `meta 1.18.0` pin.

- [ ] **Step 3: Ignore the artifacts this package will generate**

Add to `.gitignore`, after the "Pub workspace" block:

```
# Generated by the firebase_functions build_runner builder, read by the CLI at
# deploy time. Regenerate with `melos run functions:build`.
apps/fcm_functions/functions.yaml

# The linux-x64 executable `firebase deploy` uploads. Built, never committed.
apps/fcm_functions/bin/server

# Service account key, needed to let the Functions emulator reach real FCM.
*-service-account.json
```

- [ ] **Step 4: Write the failing test**

Create `apps/fcm_functions/test/notification_message_builder_test.dart`:

```dart
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

    test('reserved keys win over caller data, even though the validator '
        'should have rejected the collision first', () {
      final draft = _visible.copyWith(data: const {'id': 'not-this'});

      expect(_build(draft).data?['id'], 'sandbox-1');
    });

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

    test('a silent draft sets APNs content-available so iOS wakes the app '
        'instead of dropping the push', () {
      final silent = _visible.copyWith(
        delivery: const NotificationDelivery(asNotification: false),
      );

      expect(_build(silent).apns?.payload?.aps.contentAvailable, isTrue);
    });

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
```

- [ ] **Step 5: Run the test to verify it fails**

Run: `fvm dart test apps/fcm_functions`
Expected: FAIL — `Target of URI doesn't exist: 'package:fcm_functions/notification_message_builder.dart'`.

- [ ] **Step 6: Write the implementation**

Create `apps/fcm_functions/lib/notification_message_builder.dart`:

```dart
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:firebase_admin_sdk/messaging.dart';

/// Turns a [NotificationDraft] into the message the Admin SDK sends.
///
/// Pure translation, with no Firebase runtime and no network, so it can be
/// exercised exhaustively with plain `dart test`. Everything that needs a live
/// project sits behind `FcmMessageSender` instead.
class NotificationMessageBuilder {
  const NotificationMessageBuilder();

  /// The message for [draft], addressed to [token].
  ///
  /// [payloadId] and [sentAt] are supplied rather than generated here so the
  /// handler can report the same values it sent.
  TokenMessage build({
    required NotificationDraft draft,
    required String token,
    required String payloadId,
    required DateTime sentAt,
  }) {
    final delivery = draft.delivery;

    return TokenMessage(
      token: token,
      data: _data(draft: draft, payloadId: payloadId, sentAt: sentAt),
      notification: delivery.asNotification
          ? Notification(title: draft.title, body: draft.body)
          : null,
      android: AndroidConfig(priority: _androidPriority(delivery.priority)),
      apns: delivery.asNotification ? null : _silentApnsConfig(),
    );
  }

  /// The flat data payload, shaped so `PushMessageParser` accepts it.
  ///
  /// The caller's extra keys are spread first so the keys this builder owns
  /// always win. `NotificationDraftValidator` rejects such a collision before
  /// it gets here; this ordering means a bug there cannot produce a payload the
  /// device fails to parse.
  Map<String, String> _data({
    required NotificationDraft draft,
    required String payloadId,
    required DateTime sentAt,
  }) => {
    ...draft.data,
    'id': payloadId,
    'title': draft.title,
    'body': draft.body,
    'sentAt': sentAt.toUtc().toIso8601String(),
    'event': draft.event.wireName,
  };

  /// Without `content-available`, iOS treats a notification-less push as
  /// nothing to do and may never hand it to the app.
  ApnsConfig _silentApnsConfig() =>
      ApnsConfig(payload: ApnsPayload(aps: Aps(contentAvailable: true)));

  AndroidConfigPriority _androidPriority(NotificationPriority priority) =>
      switch (priority) {
        NotificationPriority.high => AndroidConfigPriority.high,
        NotificationPriority.normal => AndroidConfigPriority.normal,
      };
}
```

- [ ] **Step 7: Run the test to verify it passes**

Run: `fvm dart test apps/fcm_functions`
Expected: PASS, 10 tests.

- [ ] **Step 8: Check the analyzer and DCM**

Run: `fvm dart analyze --fatal-infos --fatal-warnings apps/fcm_functions`
Then: `fvm exec dcm analyze --fatal-style --fatal-warnings apps/fcm_functions`
Expected: no issues.

- [ ] **Step 9: Commit**

```bash
git add pubspec.yaml pubspec.lock .gitignore apps/fcm_functions
git commit -m "feat(functions): add fcm_functions with the FCM message builder"
```

---

### Task 7: `FcmMessageSender` and `handleSendNotification`

**Files:**
- Create: `apps/fcm_functions/lib/fcm_message_sender.dart`
- Create: `apps/fcm_functions/lib/admin_fcm_message_sender.dart`
- Create: `apps/fcm_functions/lib/send_notification_handler.dart`
- Test: `apps/fcm_functions/test/send_notification_handler_test.dart`

**Interfaces:**
- Consumes: `NotificationMessageBuilder` from Task 6; `SendNotificationRequest`, `SendNotificationResponse`, `NotificationDraftValidator` from Tasks 4-5.
- Produces:
  - `abstract interface class FcmMessageSender` — `Future<String> send(TokenMessage message)`.
  - `class AdminFcmMessageSender implements FcmMessageSender` — `const AdminFcmMessageSender(Messaging messaging)`.
  - `String defaultPayloadId()` — returns `'sandbox-<microsecondsSinceEpoch>'`.
  - `Future<SendNotificationResponse> handleSendNotification(SendNotificationRequest request, {required FcmMessageSender sender, String Function() newPayloadId = defaultPayloadId, DateTime Function() now = DateTime.now})`.

**Error type:** rejections throw `InvalidArgumentError` from `package:firebase_functions/firebase_functions.dart` — the invalid-argument member of 0.6.0's sealed `HttpsError` hierarchy. Its constructor is positional: `InvalidArgumentError('message')`. There is no `HttpResponseException` in this version.

- [ ] **Step 1: Write the failing test**

Create `apps/fcm_functions/test/send_notification_handler_test.dart`:

```dart
import 'package:fcm_functions/fcm_message_sender.dart';
import 'package:fcm_functions/send_notification_handler.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:firebase_admin_sdk/messaging.dart';
import 'package:firebase_functions/firebase_functions.dart';
import 'package:test/test.dart';

class _FakeSender implements FcmMessageSender {
  TokenMessage? sentMessage;
  Object? failWith;

  @override
  Future<String> send(TokenMessage message) async {
    sentMessage = message;
    if (failWith case final failure?) {
      throw failure;
    }

    return 'projects/fcm-sandbox-770fa/messages/42';
  }
}

const _draft = NotificationDraft(
  event: NotificationEvent.promo,
  title: 'Sale',
  body: 'Half price.',
);

const _request = SendNotificationRequest(token: 'device-token', draft: _draft);

final _now = DateTime.utc(2026, 8, 10, 9, 30);

Future<SendNotificationResponse> _handle(
  _FakeSender sender, {
  SendNotificationRequest request = _request,
}) => handleSendNotification(
  request,
  sender: sender,
  newPayloadId: () => 'sandbox-1',
  now: () => _now,
);

void main() {
  group('handleSendNotification', () {
    test('reports the message id, payload id and timestamp it used', () async {
      final sender = _FakeSender();

      final response = await _handle(sender);

      expect(response.messageId, 'projects/fcm-sandbox-770fa/messages/42');
      expect(response.payloadId, 'sandbox-1');
      expect(response.sentAt, _now);
    });

    test('the payload it sent carries the id it reported, so the app can '
        'match the response against the inbox', () async {
      final sender = _FakeSender();

      final response = await _handle(sender);

      expect(sender.sentMessage?.data?['id'], response.payloadId);
    });

    test('rejects a draft the shared validator refuses, naming the field',
        () async {
      final sender = _FakeSender();
      const invalid = SendNotificationRequest(
        token: 'device-token',
        draft: NotificationDraft(
          event: NotificationEvent.promo,
          title: '',
          body: '',
        ),
      );

      await expectLater(
        _handle(sender, request: invalid),
        throwsA(
          isA<InvalidArgumentError>().having(
            (e) => e.message,
            'message',
            allOf(contains('title'), contains('body')),
          ),
        ),
      );
      expect(sender.sentMessage, isNull, reason: 'nothing should be sent');
    });

    test('rejects a blank token', () async {
      final sender = _FakeSender();
      const blank = SendNotificationRequest(token: '   ', draft: _draft);

      await expectLater(
        _handle(sender, request: blank),
        throwsA(isA<InvalidArgumentError>()),
      );
      expect(sender.sentMessage, isNull);
    });

    test('turns an unregistered token into an explanation, not a raw code',
        () async {
      final sender = _FakeSender()
        ..failWith = FirebaseMessagingAdminException(
          MessagingClientErrorCode.registrationTokenNotRegistered,
        );

      await expectLater(
        _handle(sender),
        throwsA(
          isA<InvalidArgumentError>().having(
            (e) => e.message,
            'message',
            contains('no longer registered'),
          ),
        ),
      );
    });

    test('names the FCM error code for cases it has no wording for', () async {
      final sender = _FakeSender()
        ..failWith = FirebaseMessagingAdminException(
          MessagingClientErrorCode.serverUnavailable,
        );

      await expectLater(
        _handle(sender),
        throwsA(
          isA<InvalidArgumentError>().having(
            (e) => e.message,
            'message',
            contains('server-unavailable'),
          ),
        ),
      );
    });
  });

  group('defaultPayloadId', () {
    test('is prefixed so a sandbox id is recognisable in the inbox', () {
      expect(defaultPayloadId(), startsWith('sandbox-'));
    });

    test('does not repeat within a run', () {
      expect(defaultPayloadId(), isNot(defaultPayloadId()));
    });
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `fvm dart test apps/fcm_functions/test/send_notification_handler_test.dart`
Expected: FAIL — `fcm_message_sender.dart` and `send_notification_handler.dart` do not exist.

- [ ] **Step 3: Write the sender interface and its Admin SDK implementation**

Create `apps/fcm_functions/lib/fcm_message_sender.dart`:

```dart
import 'package:firebase_admin_sdk/messaging.dart';

/// Sends an already-built FCM message.
///
/// The seam that keeps the Admin SDK, and therefore credentials and the
/// network, out of `handleSendNotification`. It mirrors `PushSource` on the app
/// side: an interface with one real implementation and a fake in the tests.
abstract interface class FcmMessageSender {
  /// Sends [message] and returns the message name FCM assigned.
  Future<String> send(TokenMessage message);
}
```

Create `apps/fcm_functions/lib/admin_fcm_message_sender.dart`:

```dart
import 'package:firebase_admin_sdk/messaging.dart';

import 'fcm_message_sender.dart';

/// The production [FcmMessageSender], backed by the Firebase Admin SDK.
///
/// Thin on purpose — it holds no logic worth testing, which is the point of the
/// interface it implements.
class AdminFcmMessageSender implements FcmMessageSender {
  const AdminFcmMessageSender(this._messaging);

  final Messaging _messaging;

  @override
  Future<String> send(TokenMessage message) => _messaging.send(message);
}
```

- [ ] **Step 4: Write the handler**

Create `apps/fcm_functions/lib/send_notification_handler.dart`:

```dart
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:firebase_functions/firebase_functions.dart';

import 'fcm_message_sender.dart';
import 'notification_message_builder.dart';

/// The `id` a payload gets when the caller does not supply one.
///
/// Prefixed so a message sent from the sandbox is recognisable in the inbox at
/// a glance, and microsecond-stamped so two sends in the same second differ.
String defaultPayloadId() =>
    'sandbox-${DateTime.now().microsecondsSinceEpoch}';

/// Validates [request], sends it, and reports what was sent.
///
/// Takes its collaborators as parameters — the sender, the id generator and the
/// clock — so the whole thing is testable without a Firebase runtime. The
/// registration in `register_functions.dart` supplies only the sender and lets
/// the other two default.
///
/// Throws [InvalidArgumentError] for anything the caller can fix: an invalid
/// draft, a blank token, or an FCM rejection of the token itself. That is a
/// native callable error, so the app receives it as
/// `FirebaseFunctionsException(code: 'invalid-argument')` rather than an opaque
/// HTTP failure.
Future<SendNotificationResponse> handleSendNotification(
  SendNotificationRequest request, {
  required FcmMessageSender sender,
  String Function() newPayloadId = defaultPayloadId,
  DateTime Function() now = DateTime.now,
}) async {
  final problems = const NotificationDraftValidator().validate(request.draft);
  if (problems.isNotEmpty) {
    throw InvalidArgumentError(problems.join('; '));
  }
  if (request.token.trim().isEmpty) {
    throw InvalidArgumentError('token must not be blank');
  }

  final payloadId = newPayloadId();
  final sentAt = now().toUtc();
  final message = const NotificationMessageBuilder().build(
    draft: request.draft,
    token: request.token,
    payloadId: payloadId,
    sentAt: sentAt,
  );

  try {
    final messageId = await sender.send(message);

    return SendNotificationResponse(
      messageId: messageId,
      payloadId: payloadId,
      sentAt: sentAt,
    );
  } on FirebaseMessagingAdminException catch (error) {
    throw InvalidArgumentError(_explain(error));
  }
}

/// Turns an Admin SDK error into something a person can act on.
///
/// An unregistered token is by far the most common failure in a sandbox — the
/// app was reinstalled, or the token rotated — and deserves better than the raw
/// `registration-token-not-registered`.
String _explain(FirebaseMessagingAdminException error) =>
    switch (error.errorCode) {
      MessagingClientErrorCode.registrationTokenNotRegistered =>
        'This device is no longer registered with FCM. Restart the app to pick '
            'up a fresh token, then send again.',
      MessagingClientErrorCode.invalidRegistrationToken =>
        'The registration token is malformed.',
      _ => 'FCM rejected the message: ${error.code}',
    };
```

**Note on the imports:** `InvalidArgumentError` comes from `package:firebase_functions/firebase_functions.dart`. `FirebaseMessagingAdminException` and `MessagingClientErrorCode` reach this file through that same library only if it re-exports them; if the analyzer reports them as undefined, add `import 'package:firebase_admin_sdk/messaging.dart';` and keep both imports. The test file already imports both packages for exactly this reason.

**`InvalidArgumentError.message` is `String?`**, inherited from `HttpsError`. The tests match on it directly rather than on `toString()`, which would also carry the code prefix.

- [ ] **Step 5: Run the test to verify it passes**

Run: `fvm dart test apps/fcm_functions`
Expected: PASS, 18 tests.

- [ ] **Step 6: Check the analyzer and DCM**

Run: `fvm dart analyze --fatal-infos --fatal-warnings apps/fcm_functions`
Then: `fvm exec dcm analyze --fatal-style --fatal-warnings apps/fcm_functions`
Expected: no issues. `handleSendNotification` has four parameters and roughly 30 lines of code, inside both budgets.

- [ ] **Step 7: Commit**

```bash
git add apps/fcm_functions
git commit -m "feat(functions): add the sendNotification handler and its FCM sender seam"
```

---

### Task 8: The entry point, Firebase config, melos scripts — and the toolchain gate

**Files:**
- Create: `apps/fcm_functions/bin/server.dart`
- Create: `apps/fcm_functions/lib/register_functions.dart`
- Create: `firebase.json` (repo root)
- Modify: `pubspec.yaml` (root, `melos:` scripts)

**Interfaces:**
- Consumes: `handleSendNotification`, `AdminFcmMessageSender` from Task 7; the DTOs from Task 5.
- Produces: a deployable codebase — a generated `apps/fcm_functions/functions.yaml` declaring one endpoint named `sendNotification`, and a compiled `apps/fcm_functions/bin/server`.

**This task is a gate.** It is the first point at which `build_runner` and `dart compile exe` run inside the pub workspace. If either cannot work here, **stop and report** rather than restructuring the workspace to get past it — the spec calls for revisiting the design in that case.

- [ ] **Step 1: Enable the Dart functions experiment**

Run: `firebase experiments:enable dartfunctions`
Then: `firebase experiments:list | grep dartfunctions`
Expected: the row now shows `y`. This is per-machine state, not repo state.

- [ ] **Step 2: Write the function registration**

Create `apps/fcm_functions/lib/register_functions.dart`:

```dart
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:firebase_functions/firebase_functions.dart';

import 'admin_fcm_message_sender.dart';
import 'send_notification_handler.dart';

/// Registers every function this codebase deploys.
///
/// Lives in `lib/` rather than in `bin/server.dart` because the
/// `firebase_functions` builder resolves declarations across every Dart file in
/// the package, so the entry point can stay a single line.
///
/// The callable is unauthenticated: the app has no Firebase Auth, and it can
/// only ask for a push to the token it supplies itself. `maxInstances` and
/// `timeoutSeconds` cap what abuse can cost. App Check is the production
/// answer and is deliberately out of scope — see the design document.
void registerFunctions(Firebase firebase) {
  firebase.https
      .onCallWithData<SendNotificationRequest, SendNotificationResponse>(
        name: 'sendNotification',
        fromJson: SendNotificationRequest.fromJson,
        options: const CallableOptions(
          maxInstances: Instances(3),
          timeoutSeconds: TimeoutSeconds(30),
        ),
        (request, _) => handleSendNotification(
          request.data,
          sender: AdminFcmMessageSender(firebase.adminApp.messaging()),
        ),
      );
}
```

**Both `name:` and `options:` are `@mustBeConst`.** They must stay literal here — the builder reads them from the AST, so a variable or a computed value makes the endpoint undiscoverable.

- [ ] **Step 3: Write the entry point**

Create `apps/fcm_functions/bin/server.dart`:

```dart
import 'package:fcm_functions/register_functions.dart';
import 'package:firebase_functions/firebase_functions.dart';

/// The path `firebase deploy` compiles and the container runs.
///
/// `bin/server.dart` is not configurable: the Firebase CLI looks for exactly
/// this file. Keep it a single call so everything worth reading lives in `lib/`.
Future<void> main() async {
  await runFunctions(registerFunctions);
}
```

- [ ] **Step 4: Generate the manifest — gate part one**

Run: `cd apps/fcm_functions && fvm dart run build_runner build; cd -`
Expected: succeeds, writes `apps/fcm_functions/functions.yaml`.

Then: `cat apps/fcm_functions/functions.yaml`
Expected: contains an endpoint named `sendNotification` with a `callableTrigger`. A warning reading `No Firebase Functions were discovered` means the builder could not resolve `firebase.https` — **stop and report**, do not hand-write the manifest.

- [ ] **Step 5: Compile the executable — gate part two**

Run: `cd apps/fcm_functions && fvm dart compile exe bin/server.dart -o bin/server --target-os=linux --target-arch=x64; cd -`
Expected: succeeds and writes `apps/fcm_functions/bin/server`.

This is exactly the command `firebase deploy` runs, so a clean compile is the evidence that the path dependency on `fcm_gallery_shared` links into a self-contained binary. Confirm with:

Run: `ls -la apps/fcm_functions/bin/server && file apps/fcm_functions/bin/server`
Expected: an ELF 64-bit x86-64 executable.

- [ ] **Step 6: Write the root Firebase config**

Create `firebase.json` at the repo root:

```json
{
  "functions": {
    "source": "apps/fcm_functions",
    "codebase": "default",
    "runtime": "dart3",
    "ignore": [".dart_tool", "build", "test", "*.local"]
  },
  "emulators": {
    "functions": {
      "port": 5001
    },
    "ui": {
      "enabled": true
    }
  }
}
```

`apps/fcm_app/firebase.json`, written by `flutterfire configure`, is left alone. It has no `functions` block, which is why every `firebase` command must run from the repo root.

- [ ] **Step 7: Add the melos scripts**

Add to the `melos: scripts:` map in the root `pubspec.yaml`, after `fix:`:

```yaml
    functions:build:
      description: Regenerate apps/fcm_functions/functions.yaml from the Dart sources.
      exec: fvm dart run build_runner build
      packageFilters:
        scope: fcm_functions

    functions:compile:
      description: Compile the functions entry point to the linux-x64 executable that deploy uploads.
      exec: fvm dart compile exe bin/server.dart -o bin/server --target-os=linux --target-arch=x64
      packageFilters:
        scope: fcm_functions

    functions:serve:
      description: Run the Functions emulator. Needs GOOGLE_APPLICATION_CREDENTIALS to reach real FCM.
      # `fvm exec` puts the pinned SDK on PATH, which is how the Firebase CLI
      # finds a `dart` at all — there is none installed globally.
      run: fvm exec firebase emulators:start --only functions

    functions:deploy:
      description: Deploy the Dart functions. Needs the Blaze plan and the dartfunctions experiment.
      run: fvm exec firebase deploy --only functions
```

- [ ] **Step 8: Verify the scripts work through melos**

Run: `fvm dart run melos run functions:build`
Then: `fvm dart run melos run functions:compile`
Expected: both succeed. If `scope: fcm_functions` matches nothing, run `fvm dart run melos list` and use the name it prints.

- [ ] **Step 9: Check the analyzer and DCM, then the whole gate**

Run: `fvm dart analyze --fatal-infos --fatal-warnings apps/fcm_functions`
Then: `fvm exec dcm analyze --fatal-style --fatal-warnings apps/fcm_functions`
Then: `fvm dart run melos run ci`
Expected: all clean. `ci` now covers four packages.

- [ ] **Step 10: Commit**

```bash
git add pubspec.yaml firebase.json apps/fcm_functions
git commit -m "feat(functions): register the sendNotification callable and wire up deploy tooling"
```

---

### Task 9: App-side sender seam and `SandboxController`

**Files:**
- Create: `apps/fcm_app/lib/sandbox/notification_sender.dart`
- Create: `apps/fcm_app/lib/sandbox/callable_notification_sender.dart`
- Create: `apps/fcm_app/lib/sandbox/unavailable_notification_sender.dart`
- Create: `apps/fcm_app/lib/sandbox/sandbox_controller.dart`
- Test: `apps/fcm_app/test/fake_notification_sender.dart`
- Test: `apps/fcm_app/test/sandbox_controller_test.dart`
- Modify: `apps/fcm_app/pubspec.yaml`

**Interfaces:**
- Consumes: the DTOs, `NotificationDraft`, `NotificationDraftValidator`, `DraftProblem`, `NotificationScenario`, `notificationGallery`.
- Produces:
  - `abstract interface class NotificationSender` — `Future<SendNotificationResponse> send(SendNotificationRequest request)`.
  - `class CallableNotificationSender implements NotificationSender` — `CallableNotificationSender(FirebaseFunctions functions)`.
  - `class UnavailableNotificationSender implements NotificationSender` — `const UnavailableNotificationSender(String reason)`.
  - `class SandboxController extends ChangeNotifier` — constructor `SandboxController({required NotificationSender sender, required String? Function() readToken})`; getters `NotificationDraft draft`, `List<DraftProblem> problems`, `SendNotificationResponse? lastResponse`, `String? lastError`, `bool isSending`, `String? token`, `bool canSend`, `int scenarioGeneration`; methods `void applyScenario(NotificationScenario scenario)`, `void editDraft(NotificationDraft draft)`, `Future<void> send()`.

**Note on `scenarioGeneration`:** it increments only in `applyScenario`. Task 11 uses it as a widget key so the text inputs reseed when a scenario is applied, and only then — that is why the controller owns it rather than the view.

- [ ] **Step 1: Add the two new app dependencies**

`apps/fcm_app/pubspec.yaml` — the `dependencies:` block becomes (alphabetical, `sort_pub_dependencies` is fatal):

```yaml
dependencies:
  cloud_functions: ^6.3.6
  core:
    path: ../../packages/core
  cupertino_icons: ^1.0.8
  fcm_gallery_shared:
    path: ../../packages/fcm_gallery_shared
  firebase_core: ^4.13.0
  firebase_messaging: ^16.5.0
  flutter:
    sdk: flutter
```

Run: `fvm dart pub get`
Expected: resolves. `cloud_functions ^6.3.6` requires `firebase_core ^4.13.0`, which is what the app already pins.

- [ ] **Step 2: Write the failing test**

Create `apps/fcm_app/test/fake_notification_sender.dart`:

```dart
import 'package:fcm_app/sandbox/notification_sender.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';

/// A [NotificationSender] the tests drive directly.
///
/// Exists for the same reason `FakePushSource` does: `cloud_functions` must
/// never be constructed in a widget test.
class FakeNotificationSender implements NotificationSender {
  SendNotificationRequest? lastRequest;
  Object? failWith;

  @override
  Future<SendNotificationResponse> send(SendNotificationRequest request) async {
    lastRequest = request;
    if (failWith case final failure?) {
      throw failure;
    }

    return SendNotificationResponse(
      messageId: 'projects/fcm-sandbox-770fa/messages/42',
      payloadId: 'sandbox-1',
      sentAt: DateTime.utc(2026, 8, 10, 9, 30),
    );
  }
}
```

Create `apps/fcm_app/test/sandbox_controller_test.dart`:

```dart
import 'package:fcm_app/sandbox/sandbox_controller.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_notification_sender.dart';

SandboxController _controller(
  FakeNotificationSender sender, {
  String? token = 'device-token',
}) => SandboxController(sender: sender, readToken: () => token);

void main() {
  group('SandboxController', () {
    test('starts from the first gallery scenario, so the form is never blank',
        () {
      final controller = _controller(FakeNotificationSender());

      expect(controller.draft, notificationGallery.first.draft);
      expect(controller.problems, isEmpty);
    });

    test('applying a scenario replaces the draft and bumps the generation', () {
      final controller = _controller(FakeNotificationSender());
      final before = controller.scenarioGeneration;

      controller.applyScenario(notificationGallery.last);

      expect(controller.draft, notificationGallery.last.draft);
      expect(controller.scenarioGeneration, greaterThan(before));
    });

    test('editing the draft revalidates but leaves the generation alone, so '
        'the text fields are not reseeded mid-typing', () {
      final controller = _controller(FakeNotificationSender());
      final before = controller.scenarioGeneration;

      controller.editDraft(controller.draft.copyWith(title: ''));

      expect(controller.problems.map((p) => p.field), contains('title'));
      expect(controller.scenarioGeneration, before);
    });

    test('cannot send an invalid draft', () {
      final controller = _controller(FakeNotificationSender());

      controller.editDraft(controller.draft.copyWith(title: '', body: ''));

      expect(controller.canSend, isFalse);
    });

    test('cannot send without a registration token', () {
      final controller = _controller(FakeNotificationSender(), token: null);

      expect(controller.canSend, isFalse);
    });

    test('sends the current draft with the current token', () async {
      final sender = FakeNotificationSender();
      final controller = _controller(sender);

      await controller.send();

      expect(sender.lastRequest?.token, 'device-token');
      expect(sender.lastRequest?.draft, controller.draft);
    });

    test('records the response and clears any earlier error', () async {
      final sender = FakeNotificationSender();
      final controller = _controller(sender);

      await controller.send();

      expect(controller.lastResponse?.payloadId, 'sandbox-1');
      expect(controller.lastError, isNull);
      expect(controller.isSending, isFalse);
    });

    test('records a failure instead of throwing, and drops the stale response',
        () async {
      final sender = FakeNotificationSender();
      final controller = _controller(sender);
      await controller.send();

      sender.failWith = StateError('functions unreachable');
      await controller.send();

      expect(controller.lastError, contains('functions unreachable'));
      expect(controller.lastResponse, isNull);
      expect(controller.isSending, isFalse);
    });

    test('notifies listeners while sending and again when finished', () async {
      final controller = _controller(FakeNotificationSender());
      var notifications = 0;
      controller.addListener(() => notifications++);

      await controller.send();

      expect(notifications, greaterThanOrEqualTo(2));
    });

    test('does not send when the draft is invalid, even if asked', () async {
      final sender = FakeNotificationSender();
      final controller = _controller(sender);
      controller.editDraft(controller.draft.copyWith(title: '', body: ''));

      await controller.send();

      expect(sender.lastRequest, isNull);
    });
  });
}
```

- [ ] **Step 3: Run the test to verify it fails**

Run: `fvm flutter test test/sandbox_controller_test.dart` from `apps/fcm_app`
Expected: FAIL — `sandbox_controller.dart` does not exist.

- [ ] **Step 4: Write the sender interface and both implementations**

Create `apps/fcm_app/lib/sandbox/notification_sender.dart`:

```dart
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';

/// Asks the backend to send a notification.
///
/// The seam that keeps `cloud_functions` out of the widget tree and out of the
/// tests, exactly as `PushSource` does for `firebase_messaging`.
abstract interface class NotificationSender {
  /// Sends [request], or throws if the backend refuses or cannot be reached.
  Future<SendNotificationResponse> send(SendNotificationRequest request);
}
```

Create `apps/fcm_app/lib/sandbox/callable_notification_sender.dart`:

```dart
import 'package:cloud_functions/cloud_functions.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';

import 'notification_sender.dart';

/// The production [NotificationSender], calling the `sendNotification`
/// callable in `apps/fcm_functions`.
class CallableNotificationSender implements NotificationSender {
  const CallableNotificationSender(this._functions);

  /// The deployed function's id, which is **not** the string passed to
  /// `onCallWithData`.
  ///
  /// `firebase_functions` runs every registered name through its
  /// `toCloudRunId` sanitiser, so `sendNotification` in
  /// `register_functions.dart` becomes `send-notification` in the generated
  /// `functions.yaml`, in the deployed Cloud Run service, and in the path the
  /// container routes on. Calling `sendNotification` here would target a
  /// function that does not exist.
  ///
  /// Changing either side without the other breaks the call at runtime, not at
  /// compile time. Task 13's end-to-end step is what catches that.
  static const functionName = 'send-notification';

  final FirebaseFunctions _functions;

  @override
  Future<SendNotificationResponse> send(
    SendNotificationRequest request,
  ) async {
    final callable = _functions.httpsCallable(functionName);
    final result = await callable.call<Object?>(request.toJson());
    final data = result.data;
    // The plugin hands back Map<Object?, Object?> on Android, so the map is
    // rebuilt with String keys rather than cast.
    if (data is! Map) {
      throw StateError(
        '$functionName returned ${data.runtimeType}, expected a JSON object',
      );
    }

    return SendNotificationResponse.fromJson(
      data.map((key, value) => MapEntry('$key', value)),
    );
  }
}
```

Create `apps/fcm_app/lib/sandbox/unavailable_notification_sender.dart`:

```dart
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';

import 'notification_sender.dart';

/// The [NotificationSender] used when Firebase never started.
///
/// The counterpart of `DisabledPushSource`: the sandbox still renders, the send
/// button is disabled, and the reason is the one already shown in the setup
/// banner rather than a second, different explanation.
class UnavailableNotificationSender implements NotificationSender {
  const UnavailableNotificationSender(this.reason);

  /// Why sending is impossible.
  final String reason;

  @override
  Future<SendNotificationResponse> send(SendNotificationRequest request) =>
      Future.error(StateError(reason));
}
```

- [ ] **Step 5: Write the controller**

Create `apps/fcm_app/lib/sandbox/sandbox_controller.dart`:

```dart
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter/foundation.dart';

import 'notification_sender.dart';

/// Holds what the sandbox is about to send, and what happened last time.
///
/// Reads the registration token through a callback rather than holding a
/// `PushInbox`, so the sandbox depends on the one fact it needs instead of on
/// the whole inbox.
class SandboxController extends ChangeNotifier {
  SandboxController({
    required NotificationSender sender,
    required String? Function() readToken,
  }) : _sender = sender,
       _readToken = readToken,
       _draft = notificationGallery.first.draft;

  final NotificationSender _sender;
  final String? Function() _readToken;
  final _validator = const NotificationDraftValidator();

  NotificationDraft _draft;
  List<DraftProblem> _problems = const [];
  SendNotificationResponse? _lastResponse;
  String? _lastError;
  bool _sending = false;
  int _scenarioGeneration = 0;

  /// What will be sent.
  NotificationDraft get draft => _draft;

  /// Why [draft] cannot be sent, empty when it can.
  List<DraftProblem> get problems => List.unmodifiable(_problems);

  /// The last successful send, or `null` if there has not been one.
  SendNotificationResponse? get lastResponse => _lastResponse;

  /// Why the last send failed, or `null` if it did not.
  String? get lastError => _lastError;

  /// Whether a send is in flight.
  bool get isSending => _sending;

  /// This device's registration token, or `null` while there is none.
  String? get token => _readToken();

  /// Whether [send] would do anything.
  bool get canSend => !_sending && token != null && _problems.isEmpty;

  /// Increments only when a scenario is applied.
  ///
  /// The editor keys its text inputs on this, so applying a scenario reseeds
  /// them and typing does not.
  int get scenarioGeneration => _scenarioGeneration;

  /// Replaces the draft with [scenario]'s starting point.
  void applyScenario(NotificationScenario scenario) {
    _scenarioGeneration++;
    _setDraft(scenario.draft);
  }

  /// Records an edit from the form.
  void editDraft(NotificationDraft draft) => _setDraft(draft);

  /// Sends [draft] to this device, recording either the response or the error.
  ///
  /// Never throws: a failed send is a thing to display, not a crash.
  Future<void> send() async {
    final token = _readToken();
    if (!canSend || token == null) {
      return;
    }

    _sending = true;
    _lastError = null;
    notifyListeners();
    try {
      _lastResponse = await _sender.send(
        SendNotificationRequest(token: token, draft: _draft),
      );
    } catch (error) {
      _lastResponse = null;
      _lastError = '$error';
    } finally {
      _sending = false;
      notifyListeners();
    }
  }

  void _setDraft(NotificationDraft draft) {
    _draft = draft;
    _problems = _validator.validate(draft);
    notifyListeners();
  }
}
```

- [ ] **Step 6: Run the tests to verify they pass**

Run: `fvm flutter test test/sandbox_controller_test.dart` from `apps/fcm_app`
Expected: PASS, **10** tests — count them in Step 1 above; this step originally
said 11, which was an arithmetic error in this plan. The whole `apps/fcm_app`
suite goes from 13 to **23**.

Note the first test asserts `problems` is empty at construction. `_problems` starts as `const []` and the first gallery scenario validates clean (Task 4 asserts that for every scenario), so no validation call is needed in the constructor.

- [ ] **Step 7: Check the analyzer and DCM**

Run from the repo root: `fvm dart analyze --fatal-infos --fatal-warnings apps/fcm_app`
Then: `fvm exec dcm analyze --fatal-style --fatal-warnings apps/fcm_app`
Expected: no issues.

- [ ] **Step 8: Commit**

```bash
git add apps/fcm_app/pubspec.yaml pubspec.lock apps/fcm_app/lib/sandbox apps/fcm_app/test
git commit -m "feat(app): add the sandbox controller and its notification sender seam"
```

---

### Task 10: The drawer shell, and `InboxScreen` becomes `InboxView`

**Files:**
- Create: `apps/fcm_app/lib/ui/app_destination.dart`
- Create: `apps/fcm_app/lib/ui/app_shell.dart`
- Create: `apps/fcm_app/lib/ui/app_drawer.dart`
- Create: `apps/fcm_app/lib/ui/inbox_view.dart`
- Delete: `apps/fcm_app/lib/ui/inbox_screen.dart`
- Modify: `apps/fcm_app/lib/ui/fcm_sample_app.dart`
- Test: `apps/fcm_app/test/app_shell_test.dart`
- Modify: `apps/fcm_app/test/inbox_screen_test.dart` → rename to `inbox_view_test.dart`

**Interfaces:**
- Consumes: `PushInbox`, `SandboxController` from Task 9.
- Produces:
  - `enum AppDestination { inbox, sandbox }`.
  - `class AppShell extends StatefulWidget` — `const AppShell({required PushInbox inbox, required SandboxController sandbox, super.key})`.
  - `class AppDrawer extends StatelessWidget` — `const AppDrawer({required AppDestination selected, required ValueChanged<AppDestination> onSelected, super.key})`.
  - `class InboxView extends StatelessWidget` — `const InboxView({required PushInbox inbox, super.key})`, no `Scaffold` and no `AppBar`.
  - `FcmSampleApp` gains a `sandbox` parameter: `const FcmSampleApp({required PushInbox inbox, required SandboxController sandbox, super.key})`.

**Gap this task originally had, filled during execution:** changing `FcmSampleApp`'s constructor to require `sandbox` breaks `apps/fcm_app/lib/main.dart`, which this task's file list did not mention — Task 12 is where `main()` gets wired properly. The task therefore also needs a one-line stopgap in `main.dart` so the package still compiles and analyzes: construct the controller with `UnavailableNotificationSender`, which Task 12 replaces with `buildNotificationSender(...)`. Leaving `main.dart` broken between tasks would fail the analyzer gate.

**Sequencing note:** `AppShell` renders `SandboxView`, which Task 11 creates. To keep this task independently testable, `AppShell` renders a placeholder for the sandbox destination here and Task 11 replaces that one line. The placeholder is `Center(child: Text('Sandbox goes here'))` — deliberately **not** the word `Sandbox` alone, because the app bar title already carries that and `find.text('Sandbox')` would then match twice. The test below asserts on the drawer's behaviour, not on the sandbox body.

- [ ] **Step 1: Write the failing test**

Create `apps/fcm_app/test/app_shell_test.dart`:

```dart
import 'package:fcm_app/push/push_inbox.dart';
import 'package:fcm_app/sandbox/sandbox_controller.dart';
import 'package:fcm_app/ui/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_notification_sender.dart';
import 'fake_push_source.dart';

Widget _app() {
  final inbox = PushInbox(FakePushSource())..listen();

  return MaterialApp(
    home: AppShell(
      inbox: inbox,
      sandbox: SandboxController(
        sender: FakeNotificationSender(),
        readToken: () => 'device-token',
      ),
    ),
  );
}

void main() {
  group('AppShell', () {
    testWidgets('opens on the inbox', (tester) async {
      await tester.pumpWidget(_app());

      expect(find.text('Push inbox'), findsOneWidget);
      expect(find.text('No pushes received yet.'), findsOneWidget);
    });

    testWidgets('offers both destinations in the drawer', (tester) async {
      await tester.pumpWidget(_app());

      await tester.tap(find.byTooltip('Open navigation menu'));
      await tester.pumpAndSettle();

      expect(find.text('Inbox'), findsOneWidget);
      expect(find.text('Sandbox'), findsOneWidget);
    });

    testWidgets('switching to the sandbox retitles the bar and closes the '
        'drawer', (tester) async {
      await tester.pumpWidget(_app());
      await tester.tap(find.byTooltip('Open navigation menu'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sandbox'));
      await tester.pumpAndSettle();

      expect(find.text('Sandbox'), findsOneWidget);
      expect(find.text('No pushes received yet.'), findsNothing);
      expect(find.text('Inbox'), findsNothing, reason: 'drawer should close');
    });

    testWidgets('switching back returns to the inbox', (tester) async {
      await tester.pumpWidget(_app());
      await tester.tap(find.byTooltip('Open navigation menu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sandbox'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Open navigation menu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Inbox'));
      await tester.pumpAndSettle();

      expect(find.text('Push inbox'), findsOneWidget);
      expect(find.text('No pushes received yet.'), findsOneWidget);
    });
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `fvm flutter test test/app_shell_test.dart` from `apps/fcm_app`
Expected: FAIL — `app_shell.dart` does not exist.

- [ ] **Step 3: Write the destination enum and the drawer**

Create `apps/fcm_app/lib/ui/app_destination.dart`:

```dart
/// The pages the drawer switches between.
///
/// Declaration order is the drawer order: `NavigationDrawer` addresses its
/// destinations by index, so reordering these reorders the menu.
enum AppDestination { inbox, sandbox }
```

Create `apps/fcm_app/lib/ui/app_drawer.dart`:

```dart
import 'package:flutter/material.dart';

import 'app_destination.dart';

/// The navigation drawer shared by every destination.
///
/// Stateless: the selection lives in `AppShell`, so the drawer cannot disagree
/// with the body about which page is showing.
class AppDrawer extends StatelessWidget {
  const AppDrawer({
    required this.selected,
    required this.onSelected,
    super.key,
  });

  /// The destination currently on screen.
  final AppDestination selected;

  /// Called with the destination the user picked.
  final ValueChanged<AppDestination> onSelected;

  @override
  Widget build(BuildContext context) => NavigationDrawer(
    selectedIndex: selected.index,
    onDestinationSelected: (index) =>
        onSelected(AppDestination.values[index]),
    children: const [
      Padding(
        padding: EdgeInsets.fromLTRB(28, 16, 16, 10),
        child: Text('FCM Sample'),
      ),
      NavigationDrawerDestination(
        icon: Icon(Icons.inbox_outlined),
        label: Text('Inbox'),
      ),
      NavigationDrawerDestination(
        icon: Icon(Icons.science_outlined),
        label: Text('Sandbox'),
      ),
    ],
  );
}
```

- [ ] **Step 4: Turn `InboxScreen` into `InboxView`**

Create `apps/fcm_app/lib/ui/inbox_view.dart` with the body of the old `InboxScreen`, minus its `Scaffold` and `AppBar` — `AppShell` owns those now:

```dart
import 'package:flutter/material.dart';

import '../push/push_inbox.dart';
import 'message_tile.dart';
import 'setup_error_banner.dart';

/// Lists every push received this session, newest first.
///
/// A body rather than a page: the surrounding `Scaffold` and `AppBar` belong to
/// `AppShell`, which is what makes the drawer shared across destinations.
class InboxView extends StatelessWidget {
  const InboxView({required this.inbox, super.key});

  final PushInbox inbox;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: inbox,
    builder: (context, _) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (inbox.setupError case final error?) SetupErrorBanner(error),
        if (inbox.token case final token?)
          ListTile(
            dense: true,
            leading: const Icon(Icons.key_outlined),
            title: const Text('Registration token'),
            subtitle: Text(
              token,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        Expanded(
          child: inbox.messages.isEmpty
              ? const Center(child: Text('No pushes received yet.'))
              : ListView.builder(
                  itemCount: inbox.messages.length,
                  itemBuilder: (context, index) =>
                      MessageTile(inbox.messages[index]),
                ),
        ),
        if (inbox.rejections.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              '${inbox.rejections.length} malformed payload(s) dropped',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
      ],
    ),
  );
}
```

Then delete the old file:

```bash
git rm apps/fcm_app/lib/ui/inbox_screen.dart
```

- [ ] **Step 5: Write the shell**

Create `apps/fcm_app/lib/ui/app_shell.dart`:

```dart
import 'package:flutter/material.dart';

import '../push/push_inbox.dart';
import '../sandbox/sandbox_controller.dart';
import 'app_destination.dart';
import 'app_drawer.dart';
import 'inbox_view.dart';

/// The one `Scaffold` in the app.
///
/// Owning the app bar and the drawer here means each destination is a plain
/// body widget with no chrome of its own, and the title cannot drift out of
/// step with what is showing.
class AppShell extends StatefulWidget {
  const AppShell({required this.inbox, required this.sandbox, super.key});

  final PushInbox inbox;
  final SandboxController sandbox;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  AppDestination _destination = AppDestination.inbox;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(_title)),
    drawer: AppDrawer(selected: _destination, onSelected: _select),
    body: switch (_destination) {
      AppDestination.inbox => InboxView(inbox: widget.inbox),
      // Replaced by SandboxView in Task 11.
      AppDestination.sandbox => const Center(child: Text('Sandbox goes here')),
    },
  );

  String get _title => switch (_destination) {
    AppDestination.inbox => 'Push inbox',
    AppDestination.sandbox => 'Sandbox',
  };

  void _select(AppDestination destination) {
    setState(() => _destination = destination);
    Navigator.of(context).pop();
  }
}
```

- [ ] **Step 6: Point the root widget at the shell**

`apps/fcm_app/lib/ui/fcm_sample_app.dart` becomes:

```dart
import 'package:flutter/material.dart';

import '../push/push_inbox.dart';
import '../sandbox/sandbox_controller.dart';
import 'app_shell.dart';

/// Root widget. Takes its state holders as parameters rather than creating
/// them, so widget tests can supply fakes.
class FcmSampleApp extends StatelessWidget {
  const FcmSampleApp({required this.inbox, required this.sandbox, super.key});

  final PushInbox inbox;
  final SandboxController sandbox;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'FCM Sample',
    theme: ThemeData(colorSchemeSeed: Colors.indigo),
    home: AppShell(inbox: inbox, sandbox: sandbox),
  );
}
```

- [ ] **Step 7: Move the existing inbox test onto the new widget**

```bash
git mv apps/fcm_app/test/inbox_screen_test.dart apps/fcm_app/test/inbox_view_test.dart
```

In `apps/fcm_app/test/inbox_view_test.dart`, make three changes and nothing else:
1. `import 'package:fcm_app/ui/inbox_screen.dart';` → `import 'package:fcm_app/ui/inbox_view.dart';`
2. every `InboxScreen(` → `InboxView(`
3. `InboxView` has no `Scaffold`, so wherever the test pumps it directly, wrap it: `MaterialApp(home: Scaffold(body: InboxView(inbox: inbox)))`. Any expectation on the `'Push inbox'` app bar title moves to `app_shell_test.dart`, which already covers it — delete it here rather than duplicating.

- [ ] **Step 8: Run the app's whole suite**

Run: `fvm flutter test` from `apps/fcm_app`
Expected: PASS. `app_shell_test.dart` contributes 4 tests; the moved inbox tests still pass.

- [ ] **Step 9: Check the analyzer and DCM**

Run from the repo root: `fvm dart analyze --fatal-infos --fatal-warnings apps/fcm_app`
Then: `fvm exec dcm analyze --fatal-style --fatal-warnings apps/fcm_app`
Expected: no issues. `_AppShellState.build` returns widgets from a `switch` expression inside `build`, which `avoid-returning-widgets` allows; a `Widget _buildBody()` method would not.

- [ ] **Step 10: Commit**

```bash
git add -A apps/fcm_app
git commit -m "feat(app): add the drawer shell and turn InboxScreen into InboxView"
```

---

### Task 11: The Sandbox page

**Files:**
- Create: `apps/fcm_app/lib/ui/sandbox_view.dart`
- Create: `apps/fcm_app/lib/ui/scenario_gallery.dart`
- Create: `apps/fcm_app/lib/ui/draft_form_fields.dart`
- Create: `apps/fcm_app/lib/ui/delivery_fields.dart`
- Create: `apps/fcm_app/lib/ui/extra_data_editor.dart`
- Create: `apps/fcm_app/lib/ui/data_entry_row.dart`
- Create: `apps/fcm_app/lib/ui/send_result_card.dart`
- Modify: `apps/fcm_app/lib/ui/app_shell.dart` (one line)
- Test: `apps/fcm_app/test/sandbox_view_test.dart`

**Interfaces:**
- Consumes: `SandboxController` from Task 9; `notificationGallery`, `NotificationDraft`, `NotificationEvent`, `NotificationPriority`, `NotificationDelivery`, `DraftProblem`, `SendNotificationResponse`.
- Produces, all `StatelessWidget` unless noted:
  - `SandboxView({required SandboxController controller, super.key})`
  - `ScenarioGallery({required NotificationEvent selectedEvent, required ValueChanged<NotificationScenario> onSelected, super.key})`
  - `DraftFormFields({required NotificationDraft draft, required List<DraftProblem> problems, required ValueChanged<NotificationDraft> onChanged, super.key})`
  - `DeliveryFields({required NotificationDraft draft, required ValueChanged<NotificationDraft> onChanged, super.key})`
  - `ExtraDataEditor({required NotificationDraft draft, required ValueChanged<NotificationDraft> onChanged, super.key})` — `StatefulWidget`
  - `DataEntryRow({required String initialName, required String initialValue, required void Function(String name, String value) onChanged, required VoidCallback onRemove, super.key})` — `StatefulWidget`
  - `SendResultCard({required SendNotificationResponse? response, required String? error, super.key})`

**Why the text inputs are keyed:** `DraftFormFields`, `DeliveryFields` and `ExtraDataEditor` seed their inputs from the draft they are given. `SandboxView` gives them `key: ValueKey(controller.scenarioGeneration)`, so applying a scenario builds fresh state with the new values, while typing — which does not bump the generation — leaves the inputs alone. This is why no widget here needs `didUpdateWidget` syncing.

**Why so many files:** DCM's `prefer-single-widget-per-file` allows exactly one widget class per file, `avoid-returning-widgets` forbids `Widget _buildFoo()` helpers, and `source-lines-of-code: 50` caps each `build`. The form has to be composed from small widgets; it cannot be one large one.

**`avoid-returning-widgets` applies to test files too.** DCM excludes `test/**` from its *metrics* but not from its *rules*, so a `Widget _view(…)` test helper fails the gate. That is why the helper below is `Future<void> _pumpView(tester, controller)`, which pumps the widget instead of returning it — the same shape Task 10 settled on for `app_shell_test.dart` after hitting this. This section originally prescribed the returning form; it was corrected before Task 11 was dispatched.

- [ ] **Step 1: Write the failing test**

Create `apps/fcm_app/test/sandbox_view_test.dart`:

```dart
import 'package:fcm_app/sandbox/sandbox_controller.dart';
import 'package:fcm_app/ui/sandbox_view.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_notification_sender.dart';

Future<void> _pumpView(
  WidgetTester tester,
  SandboxController controller,
) async {
  await tester.pumpWidget(
    MaterialApp(home: Scaffold(body: SandboxView(controller: controller))),
  );
}

SandboxController _controller(
  FakeNotificationSender sender, {
  String? token = 'device-token',
}) => SandboxController(sender: sender, readToken: () => token);

Finder _field(String label) => find.ancestor(
  of: find.text(label),
  matching: find.byType(TextFormField),
);

void main() {
  group('SandboxView', () {
    testWidgets('shows a chip per gallery scenario', (tester) async {
      await _pumpView(tester, _controller(FakeNotificationSender()));

      for (final scenario in notificationGallery) {
        expect(find.text(scenario.label), findsOneWidget);
      }
    });

    testWidgets('opens prefilled from the first scenario', (tester) async {
      await _pumpView(tester, _controller(FakeNotificationSender()));

      expect(
        find.text(notificationGallery.first.draft.title),
        findsOneWidget,
      );
    });

    testWidgets('tapping a scenario replaces the form contents',
        (tester) async {
      await _pumpView(tester, _controller(FakeNotificationSender()));
      final promo = notificationGallery.firstWhere((s) => s.id == 'promo');

      await tester.tap(find.text(promo.label));
      await tester.pumpAndSettle();

      expect(find.text(promo.draft.title), findsWidgets);
      expect(find.text(promo.draft.body), findsOneWidget);
    });

    testWidgets('clearing the title shows the validator\'s message and '
        'disables sending', (tester) async {
      final sender = FakeNotificationSender();
      await _pumpView(tester, _controller(sender));

      await tester.enterText(_field('Title'), '');
      await tester.pump();

      expect(find.text('must not be blank'), findsOneWidget);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
    });

    testWidgets('says why it cannot send when there is no token',
        (tester) async {
      await _pumpView(
        tester,
        _controller(FakeNotificationSender(), token: null),
      );

      expect(find.text('No registration token yet.'), findsOneWidget);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
    });

    testWidgets('sending hands the fake sender the edited draft',
        (tester) async {
      final sender = FakeNotificationSender();
      await _pumpView(tester, _controller(sender));

      await tester.enterText(_field('Title'), 'Hand-written');
      await tester.pump();
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(sender.lastRequest?.draft.title, 'Hand-written');
      expect(sender.lastRequest?.token, 'device-token');
    });

    testWidgets('reports the payload id that will appear in the inbox',
        (tester) async {
      await _pumpView(tester, _controller(FakeNotificationSender()));

      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(find.textContaining('sandbox-1'), findsOneWidget);
    });

    testWidgets('shows the failure and keeps the form contents',
        (tester) async {
      final sender = FakeNotificationSender()
        ..failWith = StateError('functions unreachable');
      await _pumpView(tester, _controller(sender));
      await tester.enterText(_field('Title'), 'Still here');
      await tester.pump();

      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(find.textContaining('functions unreachable'), findsOneWidget);
      expect(find.text('Still here'), findsOneWidget);
    });

    testWidgets('turning off "Show as notification" allows a blank title, '
        'because nothing is displayed', (tester) async {
      await _pumpView(tester, _controller(FakeNotificationSender()));
      await tester.enterText(_field('Title'), '');
      await tester.enterText(_field('Body'), '');
      await tester.pump();

      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();

      expect(find.text('must not be blank'), findsNothing);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNotNull,
      );
    });

    testWidgets('adding an extra data key sends it', (tester) async {
      final sender = FakeNotificationSender();
      await _pumpView(tester, _controller(sender));

      await tester.tap(find.text('Add key/value'));
      await tester.pumpAndSettle();
      await tester.enterText(_field('Key').last, 'campaign');
      await tester.enterText(_field('Value').last, 'summer');
      await tester.pump();
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(
        sender.lastRequest?.draft.data,
        containsPair('campaign', 'summer'),
      );
    });

    testWidgets('a reserved extra data key is rejected before sending',
        (tester) async {
      final sender = FakeNotificationSender();
      await _pumpView(tester, _controller(sender));

      await tester.tap(find.text('Add key/value'));
      await tester.pumpAndSettle();
      await tester.enterText(_field('Key').last, 'id');
      await tester.pump();

      expect(find.textContaining('written by the sender'), findsOneWidget);
      expect(sender.lastRequest, isNull);
    });
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `fvm flutter test test/sandbox_view_test.dart` from `apps/fcm_app`
Expected: FAIL — `sandbox_view.dart` does not exist.

- [ ] **Step 3: Write the gallery**

Create `apps/fcm_app/lib/ui/scenario_gallery.dart`:

```dart
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter/material.dart';

/// The row of presets at the top of the sandbox.
///
/// Selection is derived from the draft's event rather than stored, so editing
/// the event dropdown moves the highlight too — there is no second source of
/// truth to keep in step.
class ScenarioGallery extends StatelessWidget {
  const ScenarioGallery({
    required this.selectedEvent,
    required this.onSelected,
    super.key,
  });

  final NotificationEvent selectedEvent;
  final ValueChanged<NotificationScenario> onSelected;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final scenario in notificationGallery)
        ChoiceChip(
          key: ValueKey(scenario.id),
          label: Text(scenario.label),
          tooltip: scenario.description,
          selected: scenario.draft.event == selectedEvent,
          onSelected: (_) => onSelected(scenario),
        ),
    ],
  );
}
```

- [ ] **Step 4: Write the text and event fields**

Create `apps/fcm_app/lib/ui/draft_form_fields.dart`:

```dart
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter/material.dart';

/// The what-it-says half of the editor: event, title, body.
///
/// Seeded from [draft] once. `SandboxView` keys this widget on the controller's
/// scenario generation, so applying a scenario rebuilds it with new values
/// while typing does not disturb the cursor.
class DraftFormFields extends StatelessWidget {
  const DraftFormFields({
    required this.draft,
    required this.problems,
    required this.onChanged,
    super.key,
  });

  final NotificationDraft draft;
  final List<DraftProblem> problems;
  final ValueChanged<NotificationDraft> onChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      InputDecorator(
        decoration: const InputDecoration(labelText: 'Event'),
        child: DropdownButton<NotificationEvent>(
          value: draft.event,
          isExpanded: true,
          underline: const SizedBox.shrink(),
          items: [
            for (final event in NotificationEvent.values)
              DropdownMenuItem(value: event, child: Text(event.wireName)),
          ],
          onChanged: (event) =>
              event == null ? null : onChanged(draft.copyWith(event: event)),
        ),
      ),
      const SizedBox(height: 8),
      TextFormField(
        initialValue: draft.title,
        decoration: InputDecoration(
          labelText: 'Title',
          errorText: _reasonFor('title'),
        ),
        onChanged: (value) => onChanged(draft.copyWith(title: value)),
      ),
      const SizedBox(height: 8),
      TextFormField(
        initialValue: draft.body,
        minLines: 2,
        maxLines: 4,
        decoration: InputDecoration(
          labelText: 'Body',
          errorText: _reasonFor('body'),
        ),
        onChanged: (value) => onChanged(draft.copyWith(body: value)),
      ),
    ],
  );

  String? _reasonFor(String field) => problems
      .where((problem) => problem.field == field)
      .map((problem) => problem.reason)
      .firstOrNull;
}
```

- [ ] **Step 5: Write the delivery fields**

Create `apps/fcm_app/lib/ui/delivery_fields.dart`:

```dart
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter/material.dart';

/// The how-it-arrives half of the editor: visible or silent, and priority.
///
/// Mirrors `NotificationDelivery`, which is why these two controls sit together
/// rather than being scattered through the form.
class DeliveryFields extends StatelessWidget {
  const DeliveryFields({
    required this.draft,
    required this.onChanged,
    super.key,
  });

  final NotificationDraft draft;
  final ValueChanged<NotificationDraft> onChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Show as notification'),
        subtitle: const Text('Off sends a silent, data-only push'),
        value: draft.delivery.asNotification,
        onChanged: (value) => onChanged(
          draft.copyWith(
            delivery: draft.delivery.copyWith(asNotification: value),
          ),
        ),
      ),
      Align(
        alignment: Alignment.centerLeft,
        child: SegmentedButton<NotificationPriority>(
          segments: const [
            ButtonSegment(
              value: NotificationPriority.high,
              label: Text('high'),
            ),
            ButtonSegment(
              value: NotificationPriority.normal,
              label: Text('normal'),
            ),
          ],
          selected: {draft.delivery.priority},
          onSelectionChanged: (selection) => onChanged(
            draft.copyWith(
              delivery: draft.delivery.copyWith(priority: selection.first),
            ),
          ),
        ),
      ),
    ],
  );
}
```

- [ ] **Step 6: Write the extra data editor and its row**

Create `apps/fcm_app/lib/ui/data_entry_row.dart`:

```dart
import 'package:flutter/material.dart';

/// One editable extra data key/value pair.
///
/// Holds its own controllers so the parent can rebuild freely without the text
/// jumping. Reports both halves on every keystroke, because a key without its
/// value is not a meaningful intermediate state to the draft.
class DataEntryRow extends StatefulWidget {
  const DataEntryRow({
    required this.initialName,
    required this.initialValue,
    required this.onChanged,
    required this.onRemove,
    super.key,
  });

  final String initialName;
  final String initialValue;
  final void Function(String name, String value) onChanged;
  final VoidCallback onRemove;

  @override
  State<DataEntryRow> createState() => _DataEntryRowState();
}

class _DataEntryRowState extends State<DataEntryRow> {
  late final _name = TextEditingController(text: widget.initialName);
  late final _value = TextEditingController(text: widget.initialValue);

  @override
  void dispose() {
    _name.dispose();
    _value.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Key'),
            onChanged: (_) => _report(),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextFormField(
            controller: _value,
            decoration: const InputDecoration(labelText: 'Value'),
            onChanged: (_) => _report(),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Remove',
          onPressed: widget.onRemove,
        ),
      ],
    ),
  );

  void _report() => widget.onChanged(_name.text, _value.text);
}
```

Create `apps/fcm_app/lib/ui/extra_data_editor.dart`:

```dart
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter/material.dart';

import 'data_entry_row.dart';

/// Editor for the extra data keys the payload carries alongside the four the
/// sender writes itself.
///
/// Keeps an ordered list rather than editing the draft's map directly: a map
/// cannot hold a half-typed key, and two blank keys would collapse into one.
/// The map is rebuilt from the list on every change, so the draft only ever
/// sees a well-formed value.
class ExtraDataEditor extends StatefulWidget {
  const ExtraDataEditor({
    required this.draft,
    required this.onChanged,
    super.key,
  });

  final NotificationDraft draft;
  final ValueChanged<NotificationDraft> onChanged;

  @override
  State<ExtraDataEditor> createState() => _ExtraDataEditorState();
}

class _ExtraDataEditorState extends State<ExtraDataEditor> {
  late final List<_Entry> _entries = [
    for (final entry in widget.draft.data.entries)
      _Entry(_nextId++, entry.key, entry.value),
  ];
  static int _nextId = 0;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'Extra data',
          style: Theme.of(context).textTheme.labelLarge,
        ),
      ),
      const SizedBox(height: 8),
      for (final entry in _entries)
        DataEntryRow(
          key: ValueKey(entry.id),
          initialName: entry.name,
          initialValue: entry.value,
          onChanged: (name, value) => _update(entry, name, value),
          onRemove: () => _remove(entry),
        ),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          icon: const Icon(Icons.add),
          label: const Text('Add key/value'),
          onPressed: _add,
        ),
      ),
    ],
  );

  void _add() {
    setState(() => _entries.add(_Entry(_nextId++, '', '')));
    _publish();
  }

  void _remove(_Entry entry) {
    setState(() => _entries.remove(entry));
    _publish();
  }

  void _update(_Entry entry, String name, String value) {
    entry
      ..name = name
      ..value = value;
    _publish();
  }

  /// A blank key is dropped rather than reported, so an empty row the user has
  /// just added does not immediately read as an error.
  void _publish() => widget.onChanged(
    widget.draft.copyWith(
      data: {
        for (final entry in _entries)
          if (entry.name.isNotEmpty) entry.name: entry.value,
      },
    ),
  );
}

class _Entry {
  _Entry(this.id, this.name, this.value);

  final int id;
  String name;
  String value;
}
```

- [ ] **Step 7: Write the result card**

Create `apps/fcm_app/lib/ui/send_result_card.dart`:

```dart
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter/material.dart';

/// What happened to the last send.
///
/// Reports the payload id on success, because that is the value about to show up
/// in the inbox — it is what turns "it said sent" into something checkable.
class SendResultCard extends StatelessWidget {
  const SendResultCard({
    required this.response,
    required this.error,
    super.key,
  });

  final SendNotificationResponse? response;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    if (error case final failure?) {
      return Card(
        color: colors.errorContainer,
        child: ListTile(
          leading: Icon(Icons.error_outline, color: colors.onErrorContainer),
          title: const Text('Send failed'),
          subtitle: Text(failure),
        ),
      );
    }

    if (response case final sent?) {
      return Card(
        color: colors.secondaryContainer,
        child: ListTile(
          leading: const Icon(Icons.check),
          title: Text('Sent · id ${sent.payloadId}'),
          subtitle: const Text('It should appear in the Inbox shortly.'),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
```

- [ ] **Step 8: Write the page itself**

Create `apps/fcm_app/lib/ui/sandbox_view.dart`:

```dart
import 'package:flutter/material.dart';

import '../sandbox/sandbox_controller.dart';
import 'delivery_fields.dart';
import 'draft_form_fields.dart';
import 'extra_data_editor.dart';
import 'scenario_gallery.dart';
import 'send_result_card.dart';

/// Compose a notification and send it to this device.
///
/// The three editors are keyed on the controller's scenario generation, so
/// applying a preset reseeds their inputs and ordinary typing does not.
class SandboxView extends StatelessWidget {
  const SandboxView({required this.controller, super.key});

  final SandboxController controller;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final seed = ValueKey(controller.scenarioGeneration);

      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ScenarioGallery(
            selectedEvent: controller.draft.event,
            onSelected: controller.applyScenario,
          ),
          const SizedBox(height: 16),
          DraftFormFields(
            key: seed,
            draft: controller.draft,
            problems: controller.problems,
            onChanged: controller.editDraft,
          ),
          const SizedBox(height: 8),
          DeliveryFields(
            draft: controller.draft,
            onChanged: controller.editDraft,
          ),
          const SizedBox(height: 8),
          ExtraDataEditor(
            key: seed,
            draft: controller.draft,
            onChanged: controller.editDraft,
          ),
          if (controller.problems.any((problem) => problem.field == 'data'))
            Text(
              controller.problems
                  .firstWhere((problem) => problem.field == 'data')
                  .reason,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: controller.canSend ? controller.send : null,
            icon: const Icon(Icons.send_outlined),
            label: Text(
              controller.isSending ? 'Sending…' : 'Send to this device',
            ),
          ),
          if (controller.token == null)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'No registration token yet.',
                textAlign: TextAlign.center,
              ),
            ),
          const SizedBox(height: 16),
          SendResultCard(
            response: controller.lastResponse,
            error: controller.lastError,
          ),
        ],
      );
    },
  );
}
```

**Two `ValueKey(controller.scenarioGeneration)` instances on sibling widgets is fine** — keys only have to be unique among siblings of the same type, and these are different types.

- [ ] **Step 9: Replace the placeholder in the shell**

In `apps/fcm_app/lib/ui/app_shell.dart`, add the import and swap the one line:

```dart
import 'sandbox_view.dart';
```

```dart
      AppDestination.sandbox => SandboxView(controller: widget.sandbox),
```

Delete the `// Replaced by SandboxView in Task 11.` comment.

- [ ] **Step 10: Run the app's whole suite**

Run: `fvm flutter test` from `apps/fcm_app`
Expected: PASS. `sandbox_view_test.dart` contributes 11 tests.

If `SandboxView.build`'s closure trips `source-lines-of-code: 50`, extract the `data` problem `Text` into its own widget file `data_problem_text.dart` — that is the cheapest cut and keeps the rule satisfied honestly rather than by suppression.

- [ ] **Step 11: Check the analyzer and DCM**

Run from the repo root: `fvm dart analyze --fatal-infos --fatal-warnings apps/fcm_app`
Then: `fvm exec dcm analyze --fatal-style --fatal-warnings apps/fcm_app`
Expected: no issues.

- [ ] **Step 12: Commit**

```bash
git add apps/fcm_app
git commit -m "feat(app): add the sandbox page with the scenario gallery and editor"
```

---

### Task 12: Wire up `main()`, document everything, run the full gate

**Files:**
- Create: `apps/fcm_app/lib/sandbox/functions_setup.dart`
- Modify: `apps/fcm_app/lib/main.dart`
- Modify: `README.md`
- Modify: `apps/fcm_app/README.md`
- Create: `apps/fcm_functions/README.md`

**Interfaces:**
- Consumes: `CallableNotificationSender`, `UnavailableNotificationSender`, `SandboxController`, `FcmSampleApp`.
- Produces: `const String functionsEmulatorHost` and `NotificationSender buildNotificationSender({required bool firebaseStarted, required String? setupError})`.

**Why the emulator host is a `--dart-define`:** during development the callable has to reach a Functions emulator on the developer's machine, which is `10.0.2.2` from the Android emulator and a LAN address from a physical device. Neither can be hard-coded, and neither belongs in a committed file.

- [ ] **Step 1: Write the sender factory**

Create `apps/fcm_app/lib/sandbox/functions_setup.dart`:

```dart
import 'package:cloud_functions/cloud_functions.dart';

import 'callable_notification_sender.dart';
import 'notification_sender.dart';
import 'unavailable_notification_sender.dart';

/// Host running the Functions emulator, supplied at build time.
///
/// Empty means "use the deployed function". Pass a value with
/// `--dart-define=FUNCTIONS_EMULATOR_HOST=…`: `10.0.2.2` from the Android
/// emulator, or the machine's LAN address from a physical device. It cannot be
/// hard-coded because it differs per developer and per device.
const functionsEmulatorHost = String.fromEnvironment(
  'FUNCTIONS_EMULATOR_HOST',
);

/// Port from the `emulators` block in the root `firebase.json`.
const functionsEmulatorPort = 5001;

/// The sender the sandbox should use.
///
/// Returns [UnavailableNotificationSender] when Firebase never started, so the
/// sandbox still renders and reports the same reason the inbox banner does,
/// rather than crashing on first use.
NotificationSender buildNotificationSender({
  required bool firebaseStarted,
  required String? setupError,
}) {
  if (!firebaseStarted) {
    return UnavailableNotificationSender(
      setupError ?? 'Firebase is not configured, so nothing can be sent.',
    );
  }

  final functions = FirebaseFunctions.instance;
  if (functionsEmulatorHost.isNotEmpty) {
    functions.useFunctionsEmulator(
      functionsEmulatorHost,
      functionsEmulatorPort,
    );
  }

  return CallableNotificationSender(functions);
}
```

- [ ] **Step 2: Wire it into `main()`**

`apps/fcm_app/lib/main.dart` — replace the body of `main()`, leaving `_onBackgroundMessage` and `_startPushSource` untouched:

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  PushSource source = const DisabledPushSource();
  String? setupError;
  try {
    source = await _startPushSource();
  } catch (error) {
    // Firebase failing to start must not stop the app from opening — the
    // reason is shown in the UI instead.
    setupError = '$error';
  }

  final inbox = PushInbox(source, setupError: setupError)..listen();
  await inbox.refreshToken();

  final sandbox = SandboxController(
    sender: buildNotificationSender(
      firebaseStarted: setupError == null,
      setupError: setupError,
    ),
    // The sandbox only ever sends to this device, and the inbox is what knows
    // its token.
    readToken: () => inbox.token,
  );

  runApp(FcmSampleApp(inbox: inbox, sandbox: sandbox));
}
```

Add these imports, keeping the existing block ordering (`package:` imports first, then relative):

```dart
import 'sandbox/functions_setup.dart';
import 'sandbox/sandbox_controller.dart';
```

- [ ] **Step 3: Verify the app still builds and the suite passes**

Run: `fvm flutter test` from `apps/fcm_app`
Then: `fvm flutter build web --release` from `apps/fcm_app`
Expected: tests pass; the web build succeeds. The web build is the one platform this machine can actually compile, so it is the check that the new imports and plugin registration are sound.

- [ ] **Step 4: Write the functions README**

Create `apps/fcm_functions/README.md`:

```markdown
# fcm_functions

The backend for the `fcm_app` sandbox: one callable, `sendNotification`, which
validates a `NotificationDraft` and sends it to a device through the Firebase
Admin SDK.

Do not run tooling from this directory — the workspace root owns dependency
resolution and the melos scripts. From the repo root:

```bash
fvm dart run melos run functions:build      # regenerate functions.yaml
fvm dart run melos run functions:compile    # what deploy compiles
fvm dart run melos run functions:serve      # Functions emulator
fvm dart run melos run functions:deploy     # needs Blaze
fvm dart test apps/fcm_functions            # unit tests, no emulator needed
```

Structure:

- `bin/server.dart` — the entry point the Firebase CLI requires, by that exact
  path. One line.
- `lib/register_functions.dart` — the callable declaration. `name:` and
  `options:` are `@mustBeConst` because a build_runner builder reads them from
  the AST to generate `functions.yaml`; a variable there makes the endpoint
  undiscoverable.
- `lib/send_notification_handler.dart` — the handler, taking its sender, id
  generator and clock as parameters so it is testable with no Firebase runtime.
- `lib/notification_message_builder.dart` — draft to `TokenMessage`, pure.
- `lib/fcm_message_sender.dart` — the interface that keeps the Admin SDK out of
  the handler, mirroring `PushSource` in the app.

## How this deploys

`firebase deploy` runs `build_runner` to produce `functions.yaml`, then
`dart compile exe … --target-os=linux --target-arch=x64`, and uploads the
resulting `bin/server` binary. Because the binary is self-contained, the path
dependency on `packages/fcm_gallery_shared` links in at compile time and needs
nothing at runtime.

Two consequences worth knowing:

- The Firebase CLI invokes `dart` from `PATH`, and this repo has no global Dart.
  Every firebase command therefore goes through `fvm exec firebase …`, which is
  what the melos scripts do.
- The CLI looks for `<source>/.dart_tool/package_config.json` to decide whether
  to run `dart pub get`. A pub workspace only has one, at the repo root, so the
  CLI re-runs `pub get` on every deploy. Harmless, just noisy.

## Not verified

`firebase deploy` has never been run against `fcm-sandbox-770fa`. The Cloud
Functions API is disabled on the project, and Dart functions target Cloud Run,
which requires the Blaze plan. `functions:compile` succeeding is the evidence
that the code is deployable; the deploy itself is not.
```

- [ ] **Step 5: Update the app README**

In `apps/fcm_app/README.md`, extend the `Structure:` list with the new directories and add a section. Insert after the existing structure list:

```markdown
- `lib/sandbox/` — `NotificationSender` interface plus its callable and
  unavailable implementations, `SandboxController`, and `functions_setup.dart`,
  which picks between the emulator and the deployed function
- `lib/ui/app_shell.dart` — the app's only `Scaffold`; owns the app bar and the
  drawer, so each destination is a body widget with no chrome of its own

## Running against the Functions emulator

The sandbox calls `sendNotification` in `apps/fcm_functions`. To point it at a
local emulator instead of a deployed function, pass the host at build time:

```bash
# From the repo root, in one terminal:
fvm dart run melos run functions:serve

# In another, from apps/fcm_app. 10.0.2.2 is the host as seen from the Android
# emulator; use the machine's LAN address from a physical device.
fvm flutter run --dart-define=FUNCTIONS_EMULATOR_HOST=10.0.2.2
```

Without the define, the app calls the deployed function.

The emulator needs credentials of its own: it has no metadata server, so the
Admin SDK cannot authenticate to send a real push. Download a service account
key from the Firebase console (Project settings → Service accounts) and export
`GOOGLE_APPLICATION_CREDENTIALS` before starting it. `*-service-account.json` is
gitignored.
```

- [ ] **Step 6: Update the root README**

Three edits to `README.md`:

1. The `## Layout` block becomes:

```
.
├── .fvmrc                      Flutter SDK pin (3.44.8)
├── pubspec.yaml                pub workspace root + melos config
├── analysis_options.yaml       shared analyzer, linter and DCM rules
├── firebase.json               Firebase CLI config (functions + emulators)
├── apps/fcm_app/               Flutter app (Android, iOS, web)
├── apps/fcm_functions/         Dart Cloud Functions — the sandbox backend
├── packages/core/              pure Dart: push payload model + parser
└── packages/fcm_gallery_shared/ pure Dart: the contract app and functions share
```

2. Add these rows to the `## Scripts` table:

```
| `melos run functions:build` | regenerate `apps/fcm_functions/functions.yaml` |
| `melos run functions:compile` | compile the linux-x64 binary that deploy uploads |
| `melos run functions:serve` | run the Functions emulator |
| `melos run functions:deploy` | deploy the functions (needs Blaze) |
```

3. Add a new section before `## Verified on this machine`:

```markdown
## The notification sandbox

The app's Sandbox page composes a push and sends it to the device it is running
on. The request goes to `sendNotification`, a Dart Cloud Function in
`apps/fcm_functions`, which validates it, stamps an `id` and `sentAt`, and sends
it through the Firebase Admin SDK. It comes back through FCM into the same inbox
as any other push, carrying the `payloadId` the send reported — so the round
trip is visible rather than inferred.

`packages/fcm_gallery_shared` is the contract in the middle: the event enum, the
gallery scenarios, the callable DTOs, and one `NotificationDraftValidator` that
the editor uses for inline errors and the function re-runs on every request. It
depends on `packages/core` so the reserved payload keys stay defined in exactly
one place.

### Before it works

```bash
firebase experiments:enable dartfunctions   # once per machine
```

Dart Cloud Functions are an experimental Firebase feature and deploy to Cloud
Run, which needs the **Blaze** plan. See `apps/fcm_functions/README.md` for the
local emulator loop, which does not.

### Security

The callable is unauthenticated: the app has no Firebase Auth, and a caller can
only ask for a push to the token it supplies itself, so an attacker would need
someone's registration token before they could bother them with it.
`maxInstances: 3` and `timeoutSeconds: 30` cap what abuse can cost. Firebase App
Check is the production answer and is deliberately out of scope — see the design
document.
```

- [ ] **Step 7: Run the full gate**

Run from the repo root: `fvm dart run melos run ci`
Expected: PASS across all four packages — format check, `dart analyze --fatal-infos`, DCM, then both test suites.

Record the actual test counts from the output. Do not claim a number the run did not print.

- [ ] **Step 8: Commit**

```bash
git add -A
git commit -m "feat(app): wire the sandbox into main and document the backend"
```

---

### Task 13: End-to-end verification on a device

**Files:** none. This task produces evidence, not code.

**Prerequisites:** an Android device or emulator with the app installed, a
service account key for `fcm-sandbox-770fa`, and `google-services.json` in
`apps/fcm_app/android/app/` (gitignored, per-developer).

**This task cannot be faked.** If any step cannot be completed on this machine,
say which one and why, and leave the rest of the verification unclaimed.

- [ ] **Step 1: Fetch a service account key**

In the Firebase console for `fcm-sandbox-770fa`: Project settings → Service
accounts → Generate new private key. Save it as
`fcm-sandbox-service-account.json` at the repo root — `*-service-account.json`
is already gitignored.

- [ ] **Step 2: Start the Functions emulator with credentials**

```bash
export GOOGLE_APPLICATION_CREDENTIALS="$PWD/fcm-sandbox-service-account.json"
fvm dart run melos run functions:serve
```

Expected: the emulator starts and lists `sendNotification` as a callable
function. If it reports that the `dartfunctions` experiment is disabled, run
`firebase experiments:enable dartfunctions` and retry.

- [ ] **Step 3: Run the app pointed at the emulator**

```bash
cd apps/fcm_app
fvm flutter run --dart-define=FUNCTIONS_EMULATOR_HOST=10.0.2.2
```

Use the machine's LAN address instead of `10.0.2.2` on a physical device. Expected:
the app opens on the inbox and the Registration token row is populated. **If the
token row is absent, stop** — the sandbox cannot send without it, and that is a
push-setup problem, not a sandbox one.

- [ ] **Step 4: Send a visible notification**

Open the drawer, choose Sandbox, tap the **Build finished** chip, edit the title
to something recognisable, and tap **Send to this device**.

Expected, in order:
1. The result card reads `Sent · id sandbox-<digits>`.
2. The emulator log shows the `sendNotification` invocation with no error.
3. A notification appears on the device.
4. Switching to Inbox shows the message, and its id matches the one on the card.

- [ ] **Step 5: Send a silent push**

Tap the **Silent sync** chip and send.

Expected: no notification is displayed, but the message still appears in the
Inbox. This is the data-only path, and the difference from step 4 is the whole
point of that scenario.

- [ ] **Step 6: Exercise a rejection**

Clear the Title while **Show as notification** is on.

Expected: `must not be blank` appears under the field and the send button is
disabled — the shared validator, running in the app.

Then add an extra data key named `id`. Expected: the message about the key being
written by the sender, and the button disabled again.

- [ ] **Step 7: Exercise a backend failure**

Stop the emulator and press Send.

Expected: the red **Send failed** card appears with the underlying error, and the
form keeps everything that was typed.

- [ ] **Step 8: Write down what was verified**

Add a `### The sandbox` subsection to `## Verified on this machine` in
`README.md`, recording exactly which of steps 3-7 passed, on which device, and
what remains unverified — at minimum `firebase deploy`, which needs Blaze, and
the iOS path, which needs Xcode.

- [ ] **Step 9: Commit**

```bash
git add README.md
git commit -m "docs: record what the sandbox verification actually covered"
```

---

## Self-review

**Spec coverage.** Every section of the design maps to a task: repository layout
(1, 6), `NotificationEvent` (1), `NotificationDraft` (2), scenarios (3),
validator (4), DTOs (5), the functions package and message builder (6), handler
and sender seam (7), entry point, `firebase.json`, melos scripts and the
toolchain gate (8), the app-side seam and controller (9), drawer shell and
`InboxView` (10), the Sandbox page (11), `main()` wiring, security note and
documentation (12), end-to-end verification (13). The spec's five error-handling
paths are covered by tests in Tasks 4, 7, 9 and 11 plus manual steps 6 and 7 of
Task 13.

**Two things the spec asks for that this plan does not do.**
`runFunctionsTest` is **not** used, and on `firebase_functions 0.6.0` it cannot
be: there is no `lib/testing.dart` in that version at all. Task 7 tests the
handler directly, which is the fallback the spec allowed. And
`CallableNotificationSender` has **no test** — it is a thin wrapper over
`cloud_functions` with no logic worth asserting, and testing it would mean
mocking the plugin. Both are noted here so neither reads as an oversight.

**Type consistency.** `NotificationDraft` carries `delivery`, not `asNotification`
and `priority`, in every task that touches it. `DraftProblem.field` is only ever
`'title'`, `'body'` or `'data'`, and Tasks 9 and 11 match on those exact strings.
The functions-side interface is `FcmMessageSender` throughout; the app-side one is
`NotificationSender`. `SendNotificationResponse.payloadId` is the same name in
Tasks 5, 7, 9 and 11. `scenarioGeneration` is produced in Task 9 and consumed in
Task 11 under that name.
