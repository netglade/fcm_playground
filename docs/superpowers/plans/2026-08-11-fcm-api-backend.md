# Simple Send API, Shared Contract and Sandbox Page — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a standalone Dart `shelf` server with one `POST /send` endpoint that pushes a notification through FCM, a `packages/fcm_gallery_shared` holding the contract both sides speak, and a drawer-navigated Sandbox page in `fcm_app` that composes a notification and sends it to the device it runs on.

**Architecture:** `packages/fcm_gallery_shared` (pure Dart, depends on `packages/core`) defines `NotificationDraft`, the scenario gallery, the request/response/error DTOs and the one validator both sides run. `apps/fcm_api` is a `shelf` server whose interesting logic is two pure units (`NotificationMessage`, `sendNotification`) behind an `FcmSender` interface implemented over the FCM HTTP v1 REST API with `googleapis_auth`. `apps/fcm_app` gains an `AppShell` with a drawer over `InboxView` and `SandboxView`, and a `SandboxController` that talks to the endpoint through a `NotificationSender` interface so widget tests never construct an HTTP client.

**Tech Stack:** Dart 3.12.2 (fvm-pinned), Flutter 3.44.8, `shelf ^1.4.2`, `shelf_router ^1.1.4`, `googleapis_auth ^2.3.3`, `http ^1.6.0`, melos 8, DCM.

**Spec:** `docs/superpowers/specs/2026-08-11-fcm-api-backend-design.md`

## Global Constraints

Every task's requirements implicitly include this section.

- **Run everything through fvm.** `fvm dart`, `fvm flutter`, `fvm exec dcm`. There is no `dart` on `PATH` on this machine.
- **`dart test` and `flutter test` must be run from inside the package directory**, because the workspace root is not itself a package with a `test` dependency. Every test command in this plan states its directory. Melos scripts (`fvm dart run melos run <script>`) are run **from the repo root**.
- **Dart SDK constraint for every new package:** `sdk: ^3.12.2`.
- **Every new package declares `resolution: workspace`** and is added to `workspace:` in the root `pubspec.yaml`. Members have no `pubspec.lock` (gitignored). After adding a member, run `fvm dart pub get` from the repo root.
- **Every new pure-Dart package's `analysis_options.yaml`** is exactly:
  ```yaml
  include:
    - package:lints/recommended.yaml
    - ../../analysis_options.yaml
  ```
- **Lints that fail the build** (`--fatal-infos --fatal-warnings`): `prefer_single_quotes`, `require_trailing_commas`, `sort_pub_dependencies` (alphabetical), `prefer_final_locals`, `prefer_final_in_for_each`, `always_declare_return_types`, `unawaited_futures`, `unnecessary_parenthesis`, `use_super_parameters`, `avoid_print` (use `stdout.writeln`/`stderr.writeln` in the server, `debugPrint` in Flutter code).
- **Analyzer strictness:** `strict-casts`, `strict-inference` and `strict-raw-types` are all on. Read JSON fields with explicit casts or the `json_field.dart` helpers from Task 1; never leave a raw `Map` or `List` in a type position.
- **DCM metrics that fail the build** (`--fatal-style --fatal-warnings`): `source-lines-of-code: 50` per function, `number-of-parameters: 5` (**counts named parameters and `super.key`**), `maximum-nesting-level: 5`, `cyclomatic-complexity: 15`. Excluded under `test/**`.
- **DCM rules that constrain file layout:** `prefer-match-file-name` (the file's name must match its first public **type**, snake_case — a file of only top-level functions has no type to match and is fine), `prefer-single-widget-per-file` (exactly one *widget* class per file; a private `State` class alongside its `StatefulWidget` is fine), `avoid-returning-widgets` (**no `Widget _buildFoo()` helper methods** — extract a widget class or use `IndexedStack`/inline conditionals), `newline-before-return`, `prefer-trailing-comma`, `avoid-unused-parameters`.
- **Doc comments on every public declaration**, in the voice of the existing code: say why, not what. Read `packages/core/lib/src/push_message.dart` and `apps/fcm_app/lib/push/push_source.dart` first to match the register.
- **Test naming:** descriptive sentences, `group` per unit. Match `packages/core/test/push_message_parser_test.dart`.
- **Commit style:** Conventional Commits, as in `git log`. Scope is the package: `feat(shared):`, `feat(api):`, `feat(app):`, `chore(tooling):`, `docs:`.
- **JSON boundary types:** every `fromJson` factory takes `Map<String, dynamic>` and every `toJson` returns `Map<String, dynamic>`, except `NotificationMessage.toJson()` which returns `Map<String, Object?>` because it is an FCM wire object rather than a DTO.
- **A malformed request body throws `FormatException`** (from `dart:core` — no new exception type) and the router maps it to 400. Blankness is never a `FormatException`; it is a `DraftProblem`, so the user gets a message naming the field.

## File Structure

**`packages/fcm_gallery_shared`** — pure Dart, depends on `core`. The contract, and nothing about HTTP or FCM.

| File | Responsibility |
| --- | --- |
| `lib/fcm_gallery_shared.dart` | Barrel; exports everything below except `json_field.dart` |
| `lib/src/json_field.dart` | Top-level JSON read helpers shared by the DTOs |
| `lib/src/notification_draft.dart` | `NotificationDraft` — title, body, data |
| `lib/src/draft_problem.dart` | `DraftProblem` — field + what is wrong |
| `lib/src/notification_draft_validator.dart` | `NotificationDraftValidator` — the one validation |
| `lib/src/notification_scenario.dart` | `NotificationScenario` + `notificationGallery` |
| `lib/src/send_notification_request.dart` | `SendNotificationRequest` — serialises flat |
| `lib/src/send_notification_response.dart` | `SendNotificationResponse` |
| `lib/src/api_error.dart` | `ApiError` — the server's error body |

**`apps/fcm_api`** — the server. Two pure units hold the logic; everything else is I/O.

| File | Responsibility |
| --- | --- |
| `bin/server.dart` | `main()` — config, auth client, serve on loopback |
| `lib/fcm_api.dart` | Barrel |
| `lib/src/notification_message.dart` | Pure: draft + token + id + sentAt → FCM v1 message |
| `lib/src/fcm_sender.dart` | `FcmSender` interface |
| `lib/src/fcm_send_exception.dart` | `FcmSendException` — FCM's status + message |
| `lib/src/send_outcome.dart` | `SendOutcome` sealed: `SendSucceeded` / `SendRejected` |
| `lib/src/send_notification.dart` | Pure handler: request → outcome |
| `lib/src/api_router.dart` | `ApiRouter` — routes, JSON in/out, status codes |
| `lib/src/http_v1_fcm_sender.dart` | `HttpV1FcmSender` over an injected `http.Client` |
| `lib/src/server_config.dart` | `ServerConfig.fromEnvironment` — fail-fast startup config |

**`apps/fcm_app`** — new `lib/sandbox/` for logic, new widgets in `lib/ui/`.

| File | Responsibility |
| --- | --- |
| `lib/sandbox/notification_sender.dart` | `NotificationSender` interface |
| `lib/sandbox/notification_send_exception.dart` | `NotificationSendException` |
| `lib/sandbox/unavailable_notification_sender.dart` | Always throws its reason |
| `lib/sandbox/http_notification_sender.dart` | POSTs to the endpoint; `defaultApiBaseUrl` |
| `lib/sandbox/sandbox_send_state.dart` | `SandboxSendState` sealed: idle/sending/sent/failed |
| `lib/sandbox/sandbox_controller.dart` | `SandboxController extends ChangeNotifier` |
| `lib/ui/app_shell.dart` | `AppShell` — drawer, single AppBar, `IndexedStack` |
| `lib/ui/inbox_view.dart` | `InboxView` — was `InboxScreen`, minus its `Scaffold` |
| `lib/ui/sandbox_view.dart` | `SandboxView` — composes the parts below |
| `lib/ui/scenario_picker.dart` | `ScenarioPicker` — the preset chips |
| `lib/ui/sandbox_form.dart` | `SandboxForm` — owns the `TextEditingController`s |
| `lib/ui/data_entry_row.dart` | `DataEntryRow` — one key/value row |
| `lib/ui/send_result_card.dart` | `SendResultCard` — success line or error card |
| `lib/ui/fcm_sample_app.dart` | Modified: gains a `sandbox` parameter |
| `lib/main.dart` | Modified: builds the sender and the controller |

**Why the text controllers live in `SandboxForm` and not in `SandboxController`:** a `TextEditingController` is view state, and the controller must stay `flutter_test`-free of it so its own tests need no widget pump. Applying a scenario has to replace what is in the fields, though. `SandboxController` therefore exposes a `scenarioRevision` counter that `applyScenario` bumps, and `SandboxView` builds `SandboxForm(key: ValueKey(controller.scenarioRevision), …)`. A new key means a fresh `State` with fresh controllers initialised from the current draft; ordinary typing never changes the revision, so the cursor never jumps.

---

### Task 1: `fcm_gallery_shared` scaffold, JSON helpers and `NotificationDraft`

**Files:**
- Create: `packages/fcm_gallery_shared/pubspec.yaml`
- Create: `packages/fcm_gallery_shared/analysis_options.yaml`
- Create: `packages/fcm_gallery_shared/README.md`
- Create: `packages/fcm_gallery_shared/CHANGELOG.md`
- Create: `packages/fcm_gallery_shared/lib/fcm_gallery_shared.dart`
- Create: `packages/fcm_gallery_shared/lib/src/json_field.dart`
- Create: `packages/fcm_gallery_shared/lib/src/notification_draft.dart`
- Modify: `pubspec.yaml` (root `workspace:` list)
- Test: `packages/fcm_gallery_shared/test/notification_draft_test.dart`

**Interfaces:**
- Consumes: nothing.
- Produces:
  - `String readOptionalText(Object? value, String field)` — `null` → `''`, non-string → `FormatException`
  - `String requireText(Object? value, String field)` — `null` or non-string → `FormatException`
  - `DateTime requireTimestamp(Object? value, String field)` — parsed, `.toUtc()`
  - `Map<String, String> readStringMap(Object? value, String field)` — `null` → `const {}`, non-map or non-string value → `FormatException`
  - `class NotificationDraft` with `const NotificationDraft({required String title, required String body, Map<String, String> data = const {}})`, `NotificationDraft.fromJson(Map<String, dynamic>)`, `Map<String, dynamic> toJson()`, `NotificationDraft copyWith({String? title, String? body, Map<String, String>? data})`, `==`/`hashCode`

- [ ] **Step 1: Create the package skeleton**

`packages/fcm_gallery_shared/pubspec.yaml`:

```yaml
name: fcm_gallery_shared
description: The notification contract shared by the Sandbox page and the send API — drafts, gallery presets, request and response DTOs, and the one validator both sides run.
version: 1.0.0
publish_to: none
resolution: workspace

environment:
  sdk: ^3.12.2

dependencies:
  collection: ^1.19.1
  core:
    path: ../core

dev_dependencies:
  lints: ^6.0.0
  test: ^1.25.6
```

`packages/fcm_gallery_shared/analysis_options.yaml`:

```yaml
include:
  - package:lints/recommended.yaml
  - ../../analysis_options.yaml
```

`packages/fcm_gallery_shared/CHANGELOG.md`:

```markdown
## 1.0.0

- Initial version.
```

`packages/fcm_gallery_shared/README.md`:

```markdown
# fcm_gallery_shared

The notification contract shared by `apps/fcm_app` and `apps/fcm_api`.

Pure Dart. It depends on `core` for exactly one thing —
`PushMessageParser.reservedKeys` — so the payload keys the app requires stay
defined in one place and the compiler enforces the agreement.

| Type | Purpose |
| --- | --- |
| `NotificationDraft` | The editable payload: title, body, extra data keys. |
| `NotificationScenario` | A gallery preset. `notificationGallery` holds them all. |
| `SendNotificationRequest` | `POST /send`'s body. Serialises flat: `{token, title, body, data}`. |
| `SendNotificationResponse` | Its 200 body: `{messageId, id, sentAt}`. |
| `ApiError` | Its non-2xx body: `{error, field?}`. |
| `NotificationDraftValidator` | The one validation, run by both sides. |
```

In the root `pubspec.yaml`, add the member to `workspace:` (keep the list alphabetical within its two groups — `apps/` first, then `packages/`):

```yaml
workspace:
  - apps/fcm_app
  - packages/core
  - packages/fcm_gallery_shared
```

- [ ] **Step 2: Resolve the new member**

Run from the repo root: `fvm dart pub get`
Expected: succeeds, and the output mentions `fcm_gallery_shared`.

- [ ] **Step 3: Write the failing test**

`packages/fcm_gallery_shared/test/notification_draft_test.dart`:

```dart
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:test/test.dart';

void main() {
  const draft = NotificationDraft(
    title: 'Build finished',
    body: 'main #128 passed',
    data: {'event': 'build_finished'},
  );

  group('NotificationDraft.toJson', () {
    test('writes the flat shape the endpoint accepts', () {
      expect(draft.toJson(), {
        'title': 'Build finished',
        'body': 'main #128 passed',
        'data': {'event': 'build_finished'},
      });
    });

    test('writes an empty data map rather than omitting the key', () {
      const bare = NotificationDraft(title: 'Hi', body: 'There');

      expect(bare.toJson()['data'], isEmpty);
    });
  });

  group('NotificationDraft.fromJson', () {
    test('round-trips a draft', () {
      expect(NotificationDraft.fromJson(draft.toJson()), draft);
    });

    test('treats an absent data key as empty', () {
      final parsed = NotificationDraft.fromJson({
        'title': 'Hi',
        'body': 'There',
      });

      expect(parsed.data, isEmpty);
    });

    test('treats an absent title or body as blank, for the validator to name', () {
      final parsed = NotificationDraft.fromJson({'body': 'There'});

      expect(parsed.title, isEmpty);
      expect(parsed.body, 'There');
    });

    test('rejects a non-string title', () {
      expect(
        () => NotificationDraft.fromJson({'title': 7, 'body': 'There'}),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects a non-string data value, naming the key', () {
      expect(
        () => NotificationDraft.fromJson({
          'title': 'Hi',
          'body': 'There',
          'data': {'retries': 3},
        }),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('retries'),
          ),
        ),
      );
    });

    test('rejects a data value that is not an object', () {
      expect(
        () => NotificationDraft.fromJson({
          'title': 'Hi',
          'body': 'There',
          'data': 'nope',
        }),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('NotificationDraft.copyWith', () {
    test('replaces only what it is given', () {
      final edited = draft.copyWith(title: 'Build failed');

      expect(edited.title, 'Build failed');
      expect(edited.body, draft.body);
      expect(edited.data, draft.data);
    });
  });

  test('two drafts with equal contents are equal', () {
    expect(
      const NotificationDraft(title: 'a', body: 'b', data: {'k': 'v'}),
      const NotificationDraft(title: 'a', body: 'b', data: {'k': 'v'}),
    );
  });

  test('drafts differing only in a data value are not equal', () {
    expect(
      const NotificationDraft(title: 'a', body: 'b', data: {'k': 'v'}),
      isNot(const NotificationDraft(title: 'a', body: 'b', data: {'k': 'w'})),
    );
  });
}
```

- [ ] **Step 4: Run the test to verify it fails**

Run from `packages/fcm_gallery_shared`: `fvm dart test test/notification_draft_test.dart`
Expected: FAIL — `Target of URI doesn't exist: 'package:fcm_gallery_shared/fcm_gallery_shared.dart'`.

- [ ] **Step 5: Write the JSON helpers**

`packages/fcm_gallery_shared/lib/src/json_field.dart`:

```dart
/// JSON field readers shared by the DTOs in this package.
///
/// They exist so a malformed body fails as a [FormatException] naming the
/// offending field, rather than as a `TypeError` from a blind cast that says
/// nothing a caller could act on.
library;

/// Reads an optional string, treating absence as `''`.
///
/// Blankness is deliberately not an error here: the validator reports it against
/// the field, which produces a message a user can read, whereas a parse failure
/// would only produce a generic 400.
String readOptionalText(Object? value, String field) {
  if (value == null) {
    return '';
  }
  if (value is! String) {
    throw FormatException('"$field" must be a string, got ${value.runtimeType}');
  }

  return value;
}

/// Reads a required string.
String requireText(Object? value, String field) {
  if (value == null) {
    throw FormatException('"$field" is missing');
  }

  return readOptionalText(value, field);
}

/// Reads a required ISO-8601 timestamp, normalised to UTC.
DateTime requireTimestamp(Object? value, String field) {
  final raw = requireText(value, field);
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) {
    throw FormatException('"$field" must be an ISO-8601 timestamp, got "$raw"');
  }

  return parsed.toUtc();
}

/// Reads an optional object of string values, treating absence as empty.
Map<String, String> readStringMap(Object? value, String field) {
  if (value == null) {
    return const {};
  }
  if (value is! Map<String, Object?>) {
    throw FormatException('"$field" must be an object, got ${value.runtimeType}');
  }

  final result = <String, String>{};
  for (final entry in value.entries) {
    result[entry.key] = readOptionalText(entry.value, '$field["${entry.key}"]');
  }

  return Map.unmodifiable(result);
}
```

Note: `readOptionalText` is reused for the map's values, so a `null` value becomes `''` rather than an error. That is deliberate — an explicit `null` in a data map is the caller saying "no value", and the validator has no rule against a blank value (only against a blank *key*).

- [ ] **Step 6: Write `NotificationDraft`**

`packages/fcm_gallery_shared/lib/src/notification_draft.dart`:

```dart
import 'package:collection/collection.dart';

import 'json_field.dart';

/// The editable body of a push: what the Sandbox form holds, and what
/// `POST /send` receives.
///
/// Immutable, so a draft handed to a sender cannot change underneath it while
/// the request is in flight.
class NotificationDraft {
  const NotificationDraft({
    required this.title,
    required this.body,
    this.data = const {},
  });

  /// Reads the flat request shape. Absent `title`/`body` become blank so the
  /// validator can name them; a wrong *type* is a [FormatException].
  factory NotificationDraft.fromJson(Map<String, dynamic> json) =>
      NotificationDraft(
        title: readOptionalText(json['title'], 'title'),
        body: readOptionalText(json['body'], 'body'),
        data: readStringMap(json['data'], 'data'),
      );

  /// Notification title, and the `title` data key.
  final String title;

  /// Notification body, and the `body` data key.
  final String body;

  /// Extra data keys, passed through to the payload untouched.
  final Map<String, String> data;

  Map<String, dynamic> toJson() => {
    'title': title,
    'body': body,
    'data': data,
  };

  NotificationDraft copyWith({
    String? title,
    String? body,
    Map<String, String>? data,
  }) => NotificationDraft(
    title: title ?? this.title,
    body: body ?? this.body,
    data: data ?? this.data,
  );

  @override
  bool operator ==(Object other) {
    if (other is! NotificationDraft) {
      return false;
    }

    return title == other.title &&
        body == other.body &&
        _dataEquality.equals(data, other.data);
  }

  @override
  int get hashCode =>
      Object.hash(title, body, _dataEquality.hash(data));

  @override
  String toString() => 'NotificationDraft(title: $title, data: ${data.keys})';
}

/// `core` compares its own maps with a hand-rolled helper; this package uses
/// `package:collection` instead of copying it, so there is one implementation
/// here rather than a second copy of the same loop.
const _dataEquality = MapEquality<String, String>();
```

`packages/fcm_gallery_shared/lib/fcm_gallery_shared.dart`:

```dart
/// The notification contract shared by the Sandbox page and the send API.
///
/// Pure Dart, so both a Flutter app and a server process can depend on it, and
/// every rule in it is exercised by plain `dart test`.
library;

export 'src/notification_draft.dart';
```

- [ ] **Step 7: Run the test to verify it passes**

Run from `packages/fcm_gallery_shared`: `fvm dart test test/notification_draft_test.dart`
Expected: PASS, 11 tests.

- [ ] **Step 8: Check the analyzer and DCM**

Run from the repo root: `fvm dart run melos run analyze && fvm dart run melos run dcm`
Expected: both green. If `prefer-match-file-name` flags `json_field.dart` (it should not — the file declares no type), wrap the four functions as `static` members of an `abstract final class JsonField` and update the two call sites in `notification_draft.dart`.

- [ ] **Step 9: Commit**

```bash
git add pubspec.yaml pubspec.lock packages/fcm_gallery_shared
git commit -m "feat(shared): add fcm_gallery_shared with NotificationDraft"
```

---

### Task 2: `DraftProblem` and `NotificationDraftValidator`

**Files:**
- Create: `packages/fcm_gallery_shared/lib/src/draft_problem.dart`
- Create: `packages/fcm_gallery_shared/lib/src/notification_draft_validator.dart`
- Modify: `packages/fcm_gallery_shared/lib/fcm_gallery_shared.dart`
- Test: `packages/fcm_gallery_shared/test/notification_draft_validator_test.dart`

**Interfaces:**
- Consumes: `NotificationDraft` (Task 1); `PushMessageParser.reservedKeys` from `package:core/core.dart` — the `const Set<String>` `{'id', 'title', 'body', 'sentAt'}`.
- Produces:
  - `class DraftProblem` with `const DraftProblem(String field, String message)`, `==`/`hashCode`, `toString()` → `'<field> <message>'`
  - `class NotificationDraftValidator` with `const NotificationDraftValidator()`, `List<DraftProblem> validate(NotificationDraft draft)` and `List<DraftProblem> validateEntries({required String title, required String body, required List<MapEntry<String, String>> data})`

**Why two entry points:** rule 4 forbids a duplicated data key, and a `Map<String, String>` cannot represent one. The Sandbox form holds a *list* of rows, so it validates the rows with `validateEntries` before collapsing them into a map. The server only ever has a map — a duplicate cannot survive JSON decoding — so it calls `validate`, where rule 4 is vacuous.

- [ ] **Step 1: Write the failing test**

`packages/fcm_gallery_shared/test/notification_draft_validator_test.dart`:

```dart
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:test/test.dart';

void main() {
  const validator = NotificationDraftValidator();

  NotificationDraft draft({
    String title = 'Build finished',
    String body = 'main #128 passed',
    Map<String, String> data = const {},
  }) => NotificationDraft(title: title, body: body, data: data);

  group('NotificationDraftValidator.validate', () {
    test('accepts a well-formed draft', () {
      expect(validator.validate(draft()), isEmpty);
    });

    test('accepts extra data keys that collide with nothing', () {
      expect(
        validator.validate(draft(data: {'event': 'build_finished'})),
        isEmpty,
      );
    });

    test('rejects a blank title against the title field', () {
      final problems = validator.validate(draft(title: '   '));

      expect(problems, [const DraftProblem('title', 'must not be blank')]);
    });

    test('rejects a blank body against the body field', () {
      final problems = validator.validate(draft(body: ''));

      expect(problems, [const DraftProblem('body', 'must not be blank')]);
    });

    test('reports a blank title and a blank body together', () {
      expect(validator.validate(draft(title: '', body: '')), hasLength(2));
    });

    test('rejects a blank data key', () {
      final problems = validator.validate(draft(data: {'  ': 'v'}));

      expect(problems, [const DraftProblem('data', 'has a blank key')]);
    });

    test('rejects a data key that collides with a reserved payload key', () {
      final problems = validator.validate(draft(data: {'sentAt': 'now'}));

      expect(problems, [
        const DraftProblem(
          'data.sentAt',
          'collides with a reserved payload key',
        ),
      ]);
    });

    test('rejects every reserved key, so the rule cannot rot as core changes', () {
      for (final reserved in PushMessageParser.reservedKeys) {
        expect(
          validator.validate(draft(data: {reserved: 'x'})),
          hasLength(1),
          reason: '$reserved should be rejected',
        );
      }
    });

    test('returns an unmodifiable list', () {
      expect(
        () => validator.validate(draft()).add(const DraftProblem('a', 'b')),
        throwsUnsupportedError,
      );
    });
  });

  group('NotificationDraftValidator.validateEntries', () {
    test('rejects a duplicated key, which a map could not have shown', () {
      final problems = validator.validateEntries(
        title: 'Build finished',
        body: 'main #128 passed',
        data: const [MapEntry('event', 'a'), MapEntry('event', 'b')],
      );

      expect(problems, [const DraftProblem('data.event', 'is duplicated')]);
    });

    test('reports the collision once, not once per repeat', () {
      final problems = validator.validateEntries(
        title: 'Build finished',
        body: 'main #128 passed',
        data: const [
          MapEntry('event', 'a'),
          MapEntry('event', 'b'),
          MapEntry('event', 'c'),
        ],
      );

      expect(problems, hasLength(2));
    });

    test('accepts distinct keys', () {
      final problems = validator.validateEntries(
        title: 'Build finished',
        body: 'main #128 passed',
        data: const [MapEntry('event', 'a'), MapEntry('deepLink', '/b')],
      );

      expect(problems, isEmpty);
    });
  });
}
```

The `PushMessageParser` reference means the test also imports `package:core/core.dart` — add that import at the top alongside the two already there.

- [ ] **Step 2: Run the test to verify it fails**

Run from `packages/fcm_gallery_shared`: `fvm dart test test/notification_draft_validator_test.dart`
Expected: FAIL — `Undefined name 'NotificationDraftValidator'`.

- [ ] **Step 3: Write `DraftProblem`**

`packages/fcm_gallery_shared/lib/src/draft_problem.dart`:

```dart
/// A reason a draft cannot be sent, tied to the field that caused it.
///
/// [field] is what the app renders the message against: `'title'`, `'body'`,
/// `'data'` for the map as a whole, or `'data.<key>'` for one entry.
class DraftProblem {
  const DraftProblem(this.field, this.message);

  /// The offending field's name.
  final String field;

  /// What is wrong with it, phrased to follow the field name in a sentence.
  final String message;

  @override
  bool operator ==(Object other) =>
      other is DraftProblem && field == other.field && message == other.message;

  @override
  int get hashCode => Object.hash(field, message);

  @override
  String toString() => '$field $message';
}
```

- [ ] **Step 4: Write the validator**

`packages/fcm_gallery_shared/lib/src/notification_draft_validator.dart`:

```dart
import 'package:core/core.dart';

import 'draft_problem.dart';
import 'notification_draft.dart';

/// The single validation both the app and the server run.
///
/// The app renders the problems inline and disables Send; the server runs the
/// same rules and answers 400, so the app is not the only line of defence.
class NotificationDraftValidator {
  const NotificationDraftValidator();

  /// Validates a draft. Duplicate data keys are unreachable here — a map cannot
  /// hold one — so use [validateEntries] for editor rows.
  List<DraftProblem> validate(NotificationDraft draft) => validateEntries(
    title: draft.title,
    body: draft.body,
    data: draft.data.entries.toList(),
  );

  /// Validates the parts of a draft while the data keys are still a list, so a
  /// key the user has typed twice can be reported instead of silently losing one.
  List<DraftProblem> validateEntries({
    required String title,
    required String body,
    required List<MapEntry<String, String>> data,
  }) {
    final problems = <DraftProblem>[
      if (title.trim().isEmpty)
        const DraftProblem('title', 'must not be blank'),
      if (body.trim().isEmpty) const DraftProblem('body', 'must not be blank'),
    ];

    final seen = <String>{};
    for (final entry in data) {
      problems.addAll(_problemsForKey(entry.key, seen));
    }

    return List.unmodifiable(problems);
  }

  Iterable<DraftProblem> _problemsForKey(String key, Set<String> seen) {
    if (key.trim().isEmpty) {
      return const [DraftProblem('data', 'has a blank key')];
    }
    if (PushMessageParser.reservedKeys.contains(key)) {
      return [
        DraftProblem('data.$key', 'collides with a reserved payload key'),
      ];
    }
    if (!seen.add(key)) {
      return [DraftProblem('data.$key', 'is duplicated')];
    }

    return const [];
  }
}
```

Add both exports to `packages/fcm_gallery_shared/lib/fcm_gallery_shared.dart`, keeping the list alphabetical:

```dart
export 'src/draft_problem.dart';
export 'src/notification_draft.dart';
export 'src/notification_draft_validator.dart';
```

- [ ] **Step 5: Run the test to verify it passes**

Run from `packages/fcm_gallery_shared`: `fvm dart test test/notification_draft_validator_test.dart`
Expected: PASS, 12 tests.

- [ ] **Step 6: Commit**

```bash
git add packages/fcm_gallery_shared
git commit -m "feat(shared): add the draft validator both sides run"
```

---

### Task 3: `NotificationScenario` and the gallery

**Files:**
- Create: `packages/fcm_gallery_shared/lib/src/notification_scenario.dart`
- Modify: `packages/fcm_gallery_shared/lib/fcm_gallery_shared.dart`
- Test: `packages/fcm_gallery_shared/test/notification_scenario_test.dart`

**Interfaces:**
- Consumes: `NotificationDraft` (Task 1), `NotificationDraftValidator` (Task 2).
- Produces:
  - `class NotificationScenario` with `const NotificationScenario({required String id, required String label, required String description, required NotificationDraft draft})`
  - `const List<NotificationScenario> notificationGallery` — four entries, ids `chatMessage`, `buildFinished`, `promo`, `plainText`

- [ ] **Step 1: Write the failing test**

`packages/fcm_gallery_shared/test/notification_scenario_test.dart`:

```dart
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:test/test.dart';

void main() {
  group('notificationGallery', () {
    test('offers the four presets the Sandbox shows', () {
      expect(notificationGallery, hasLength(4));
    });

    test('gives every scenario a unique id', () {
      final ids = notificationGallery.map((scenario) => scenario.id).toSet();

      expect(ids, hasLength(notificationGallery.length));
    });

    test('gives every scenario a non-blank label and description', () {
      for (final scenario in notificationGallery) {
        expect(scenario.label.trim(), isNotEmpty, reason: scenario.id);
        expect(scenario.description.trim(), isNotEmpty, reason: scenario.id);
      }
    });

    test('every preset validates clean, so one tap is always sendable', () {
      const validator = NotificationDraftValidator();

      for (final scenario in notificationGallery) {
        expect(
          validator.validate(scenario.draft),
          isEmpty,
          reason: '${scenario.id} should need no editing',
        );
      }
    });

    test('covers both the with-data and the without-data path', () {
      final withData = notificationGallery.where(
        (scenario) => scenario.draft.data.isNotEmpty,
      );
      final withoutData = notificationGallery.where(
        (scenario) => scenario.draft.data.isEmpty,
      );

      expect(withData, isNotEmpty);
      expect(withoutData, isNotEmpty);
    });
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run from `packages/fcm_gallery_shared`: `fvm dart test test/notification_scenario_test.dart`
Expected: FAIL — `Undefined name 'notificationGallery'`.

- [ ] **Step 3: Write the scenarios**

`packages/fcm_gallery_shared/lib/src/notification_scenario.dart`:

```dart
import 'notification_draft.dart';

/// A gallery preset: a named draft the Sandbox can load with one tap.
///
/// Loading a scenario replaces the form's contents; everything stays editable
/// afterwards, so a preset is a starting point rather than a fixed payload.
class NotificationScenario {
  const NotificationScenario({
    required this.id,
    required this.label,
    required this.description,
    required this.draft,
  });

  /// Stable identifier, used as a widget key and in tests.
  final String id;

  /// Shown on the chip.
  final String label;

  /// One line explaining what makes this preset different from the others.
  final String description;

  /// The draft loaded into the form.
  final NotificationDraft draft;
}

/// The presets the Sandbox offers.
///
/// They cover different axes rather than four flavours of the same thing: a
/// routing key the app would act on, the payload from the root README, two
/// unrelated extra keys, and no extra data at all.
const notificationGallery = <NotificationScenario>[
  NotificationScenario(
    id: 'chatMessage',
    label: 'Chat message',
    description: 'Carries a deep link the app would route on.',
    draft: NotificationDraft(
      title: 'Ada: are we still on for 14:00?',
      body: 'Tap to open the thread.',
      data: {'event': 'chat_message', 'deepLink': '/chats/ada'},
    ),
  ),
  NotificationScenario(
    id: 'buildFinished',
    label: 'Build finished',
    description: 'The payload the root README documents.',
    draft: NotificationDraft(
      title: 'Build finished',
      body: 'Release 1.0.0 is ready.',
      data: {'event': 'build_finished', 'buildNumber': '128'},
    ),
  ),
  NotificationScenario(
    id: 'promo',
    label: 'Promo',
    description: 'Two unrelated extra keys at once.',
    draft: NotificationDraft(
      title: '20% off this week',
      body: 'Your upgrade is discounted until Sunday.',
      data: {'event': 'promo', 'campaign': 'summer-2026'},
    ),
  ),
  NotificationScenario(
    id: 'plainText',
    label: 'Plain text',
    description: 'No extra data — exercises the empty-map path.',
    draft: NotificationDraft(
      title: 'Hello from the Sandbox',
      body: 'Nothing but a title and a body.',
    ),
  ),
];
```

Add the export to the barrel, alphabetically after `notification_draft_validator.dart`:

```dart
export 'src/notification_scenario.dart';
```

- [ ] **Step 4: Run the test to verify it passes**

Run from `packages/fcm_gallery_shared`: `fvm dart test test/notification_scenario_test.dart`
Expected: PASS, 5 tests.

- [ ] **Step 5: Commit**

```bash
git add packages/fcm_gallery_shared
git commit -m "feat(shared): add the scenario gallery"
```

---

### Task 4: The request, response and error DTOs

**Files:**
- Create: `packages/fcm_gallery_shared/lib/src/send_notification_request.dart`
- Create: `packages/fcm_gallery_shared/lib/src/send_notification_response.dart`
- Create: `packages/fcm_gallery_shared/lib/src/api_error.dart`
- Modify: `packages/fcm_gallery_shared/lib/fcm_gallery_shared.dart`
- Test: `packages/fcm_gallery_shared/test/send_notification_dto_test.dart`

**Interfaces:**
- Consumes: `NotificationDraft` (Task 1), the `json_field.dart` helpers (Task 1).
- Produces:
  - `class SendNotificationRequest` — `const SendNotificationRequest({required String token, required NotificationDraft draft})`, `.fromJson(Map<String, dynamic>)`, `Map<String, dynamic> toJson()` which is **flat**: `{token, title, body, data}`
  - `class SendNotificationResponse` — `const SendNotificationResponse({required String messageId, required String payloadId, required DateTime sentAt})`, `.fromJson(Map<String, dynamic>)`, `toJson()` writing `{messageId, id, sentAt}`
  - `class ApiError` — `const ApiError(String message, {String? field})`, `.fromJson(Map<String, dynamic>)`, `toJson()` writing `{error, field?}`

**Why the response's wire key is `id` while the Dart field is `payloadId`:** on the wire it is the payload's `id`, matching `PushMessage.id` so the round trip is visible in the inbox. In Dart, sitting next to `messageId`, the name has to say *which* id it is.

- [ ] **Step 1: Write the failing test**

`packages/fcm_gallery_shared/test/send_notification_dto_test.dart`:

```dart
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:test/test.dart';

void main() {
  group('SendNotificationRequest', () {
    const request = SendNotificationRequest(
      token: 'device-token',
      draft: NotificationDraft(
        title: 'Build finished',
        body: 'main #128 passed',
        data: {'event': 'build_finished'},
      ),
    );

    test('serialises flat, so the DTO is the endpoint body', () {
      expect(request.toJson(), {
        'token': 'device-token',
        'title': 'Build finished',
        'body': 'main #128 passed',
        'data': {'event': 'build_finished'},
      });
    });

    test('round-trips', () {
      final parsed = SendNotificationRequest.fromJson(request.toJson());

      expect(parsed.token, request.token);
      expect(parsed.draft, request.draft);
    });

    test('treats an absent token as blank, for the server to name', () {
      final parsed = SendNotificationRequest.fromJson({
        'title': 'Hi',
        'body': 'There',
      });

      expect(parsed.token, isEmpty);
    });

    test('rejects a non-string token', () {
      expect(
        () => SendNotificationRequest.fromJson({'token': 7}),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('SendNotificationResponse', () {
    final response = SendNotificationResponse(
      messageId: 'projects/p/messages/0:17',
      payloadId: 'api-1754812345678901',
      sentAt: DateTime.utc(2026, 8, 11, 9, 12, 3),
    );

    test('writes the payload id under the wire key "id"', () {
      expect(response.toJson(), {
        'messageId': 'projects/p/messages/0:17',
        'id': 'api-1754812345678901',
        'sentAt': '2026-08-11T09:12:03.000Z',
      });
    });

    test('round-trips', () {
      final parsed = SendNotificationResponse.fromJson(response.toJson());

      expect(parsed.messageId, response.messageId);
      expect(parsed.payloadId, response.payloadId);
      expect(parsed.sentAt, response.sentAt);
    });

    test('normalises the timestamp to UTC', () {
      final parsed = SendNotificationResponse.fromJson({
        'messageId': 'm',
        'id': 'p',
        'sentAt': '2026-08-11T11:12:03+02:00',
      });

      expect(parsed.sentAt.isUtc, isTrue);
      expect(parsed.sentAt, DateTime.utc(2026, 8, 11, 9, 12, 3));
    });

    test('rejects a response missing a field, rather than inventing one', () {
      expect(
        () => SendNotificationResponse.fromJson({'messageId': 'm', 'id': 'p'}),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects an unparseable timestamp', () {
      expect(
        () => SendNotificationResponse.fromJson({
          'messageId': 'm',
          'id': 'p',
          'sentAt': 'yesterday',
        }),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('ApiError', () {
    test('omits the field key when there is no field to blame', () {
      expect(const ApiError('FCM is unreachable').toJson(), {
        'error': 'FCM is unreachable',
      });
    });

    test('round-trips with a field', () {
      const error = ApiError('title must not be blank', field: 'title');

      final parsed = ApiError.fromJson(error.toJson());

      expect(parsed.message, error.message);
      expect(parsed.field, 'title');
    });

    test('tolerates a non-string field rather than failing the error path', () {
      final parsed = ApiError.fromJson({'error': 'boom', 'field': 7});

      expect(parsed.field, isNull);
    });

    test('rejects a body with no error message', () {
      expect(
        () => ApiError.fromJson({'field': 'title'}),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run from `packages/fcm_gallery_shared`: `fvm dart test test/send_notification_dto_test.dart`
Expected: FAIL — `Undefined name 'SendNotificationRequest'`.

- [ ] **Step 3: Write the request**

`packages/fcm_gallery_shared/lib/src/send_notification_request.dart`:

```dart
import 'json_field.dart';
import 'notification_draft.dart';

/// The body of `POST /send`.
///
/// It serialises flat rather than nesting the draft, so this class *is* the
/// endpoint's shape instead of a wrapper around it — there is no envelope to
/// keep in agreement on two sides.
class SendNotificationRequest {
  const SendNotificationRequest({required this.token, required this.draft});

  factory SendNotificationRequest.fromJson(Map<String, dynamic> json) =>
      SendNotificationRequest(
        token: readOptionalText(json['token'], 'token'),
        draft: NotificationDraft.fromJson(json),
      );

  /// The registration token to deliver to. The app sends its own, so the loop
  /// closes on the calling device.
  final String token;

  /// What to send.
  final NotificationDraft draft;

  Map<String, dynamic> toJson() => {'token': token, ...draft.toJson()};
}
```

- [ ] **Step 4: Write the response**

`packages/fcm_gallery_shared/lib/src/send_notification_response.dart`:

```dart
import 'json_field.dart';

/// The 200 body of `POST /send`.
///
/// Every field is stamped by the server, so what the caller is told and what the
/// device receives cannot drift.
class SendNotificationResponse {
  const SendNotificationResponse({
    required this.messageId,
    required this.payloadId,
    required this.sentAt,
  });

  factory SendNotificationResponse.fromJson(Map<String, dynamic> json) =>
      SendNotificationResponse(
        messageId: requireText(json['messageId'], 'messageId'),
        payloadId: requireText(json['id'], 'id'),
        sentAt: requireTimestamp(json['sentAt'], 'sentAt'),
      );

  /// FCM's own message name, e.g. `projects/p/messages/0:17…`. Useful only for
  /// correlating with FCM's logs.
  final String messageId;

  /// The payload's `id` data key, which is what the inbox shows — so the user
  /// can match the send to the arrival.
  final String payloadId;

  /// When the server stamped the message, in UTC.
  final DateTime sentAt;

  Map<String, dynamic> toJson() => {
    'messageId': messageId,
    'id': payloadId,
    'sentAt': sentAt.toIso8601String(),
  };
}
```

- [ ] **Step 5: Write the error**

`packages/fcm_gallery_shared/lib/src/api_error.dart`:

```dart
import 'json_field.dart';

/// The body of every non-2xx answer from the send API.
///
/// Shared so the app parses failures with the same type the server produced them
/// with, rather than guessing at a shape at the moment things are already wrong.
class ApiError {
  const ApiError(this.message, {this.field});

  factory ApiError.fromJson(Map<String, dynamic> json) {
    final field = json['field'];

    return ApiError(
      requireText(json['error'], 'error'),
      // A malformed `field` must not turn a reportable error into a parse
      // failure — the message is the part the user needs.
      field: field is String ? field : null,
    );
  }

  /// Human-readable, and safe to show as-is.
  final String message;

  /// The request field at fault, when there is one, matching
  /// `DraftProblem.field`.
  final String? field;

  Map<String, dynamic> toJson() => {
    'error': message,
    if (field case final field?) 'field': field,
  };
}
```

Add all three exports to the barrel, keeping it alphabetical:

```dart
export 'src/api_error.dart';
export 'src/draft_problem.dart';
export 'src/notification_draft.dart';
export 'src/notification_draft_validator.dart';
export 'src/notification_scenario.dart';
export 'src/send_notification_request.dart';
export 'src/send_notification_response.dart';
```

- [ ] **Step 6: Run the whole package's tests**

Run from `packages/fcm_gallery_shared`: `fvm dart test`
Expected: PASS, 41 tests across four files (11 + 12 + 5 + 13).

- [ ] **Step 7: Check the analyzer and DCM**

Run from the repo root: `fvm dart run melos run analyze && fvm dart run melos run dcm`
Expected: both green.

- [ ] **Step 8: Commit**

```bash
git add packages/fcm_gallery_shared
git commit -m "feat(shared): add the send request, response and error DTOs"
```

---

### Task 5: `fcm_api` scaffold and the FCM v1 message

**Files:**
- Create: `apps/fcm_api/pubspec.yaml`
- Create: `apps/fcm_api/analysis_options.yaml`
- Create: `apps/fcm_api/README.md`
- Create: `apps/fcm_api/lib/fcm_api.dart`
- Create: `apps/fcm_api/lib/src/notification_message.dart`
- Modify: `pubspec.yaml` (root `workspace:` list)
- Test: `apps/fcm_api/test/notification_message_test.dart`

**Interfaces:**
- Consumes: `NotificationDraft` (Task 1).
- Produces:
  - `class NotificationMessage` with `const NotificationMessage({required String token, required NotificationDraft draft, required String payloadId, required DateTime sentAt})` and `Map<String, Object?> toJson()` returning `{'message': {...}}`

- [ ] **Step 1: Create the package skeleton**

`apps/fcm_api/pubspec.yaml`:

```yaml
name: fcm_api
description: A local HTTP server with one endpoint that sends a push through Firebase Cloud Messaging. A development tool — unauthenticated, and bound to loopback.
version: 1.0.0
publish_to: none
resolution: workspace

environment:
  sdk: ^3.12.2

dependencies:
  fcm_gallery_shared:
    path: ../../packages/fcm_gallery_shared
  googleapis_auth: ^2.3.3
  http: ^1.6.0
  shelf: ^1.4.2
  shelf_router: ^1.1.4

dev_dependencies:
  lints: ^6.0.0
  test: ^1.25.6
```

It does **not** depend on `core`: the reserved keys reach it through
`fcm_gallery_shared`'s validator, and nothing here needs `PushMessage` itself.

`apps/fcm_api/analysis_options.yaml`:

```yaml
include:
  - package:lints/recommended.yaml
  - ../../analysis_options.yaml
```

`apps/fcm_api/README.md`:

````markdown
# fcm_api

One endpoint that sends a push through FCM, so the Sandbox page in `fcm_app` has
something to talk to.

```
POST /send   {token, title, body, data?}  →  200 {messageId, id, sentAt}
GET  /health                              →  200 {"status": "ok"}
```

`id` and `sentAt` are stamped by the server, so the response and the delivered
payload cannot drift, and the message is guaranteed to satisfy
`PushMessageParser` in `packages/core`.

**This is a development tool.** It has no authentication and binds `127.0.0.1`,
so it is reachable only from the machine it runs on. Binding it to `0.0.0.0`
would expose an open relay to whatever network it sits on — do not deploy it as
is.

See the root `README.md` for how to run it.
````

In the root `pubspec.yaml`, add the member — `apps/` entries first, alphabetically:

```yaml
workspace:
  - apps/fcm_api
  - apps/fcm_app
  - packages/core
  - packages/fcm_gallery_shared
```

- [ ] **Step 2: Resolve the new member**

Run from the repo root: `fvm dart pub get`
Expected: succeeds, and resolves `shelf`, `shelf_router`, `googleapis_auth` and `http`.

- [ ] **Step 3: Write the failing test**

`apps/fcm_api/test/notification_message_test.dart`:

```dart
import 'package:fcm_api/fcm_api.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:test/test.dart';

void main() {
  Map<String, Object?> messageFor(NotificationDraft draft) {
    final built = NotificationMessage(
      token: 'device-token',
      draft: draft,
      payloadId: 'api-1754812345678901',
      sentAt: DateTime.utc(2026, 8, 11, 9, 12, 3),
    ).toJson();

    return built['message']! as Map<String, Object?>;
  }

  const draft = NotificationDraft(
    title: 'Build finished',
    body: 'main #128 passed',
    data: {'event': 'build_finished'},
  );

  group('NotificationMessage.toJson', () {
    test('wraps the message the way the v1 endpoint requires', () {
      final built = NotificationMessage(
        token: 'device-token',
        draft: draft,
        payloadId: 'api-1',
        sentAt: DateTime.utc(2026),
      ).toJson();

      expect(built.keys, ['message']);
    });

    test('targets the supplied token', () {
      expect(messageFor(draft)['token'], 'device-token');
    });

    test('sends a notification block so a backgrounded app still shows it', () {
      expect(messageFor(draft)['notification'], {
        'title': 'Build finished',
        'body': 'main #128 passed',
      });
    });

    test('asks Android for high priority, so it arrives while you watch', () {
      expect(messageFor(draft)['android'], {'priority': 'high'});
    });

    test('repeats the four keys PushMessageParser reads inside data', () {
      final data = messageFor(draft)['data']! as Map<String, Object?>;

      expect(data['id'], 'api-1754812345678901');
      expect(data['title'], 'Build finished');
      expect(data['body'], 'main #128 passed');
      expect(data['sentAt'], '2026-08-11T09:12:03.000Z');
    });

    test('passes the extra data keys through untouched', () {
      final data = messageFor(draft)['data']! as Map<String, Object?>;

      expect(data['event'], 'build_finished');
    });

    test('still carries the four required keys when data is empty', () {
      final data =
          messageFor(const NotificationDraft(title: 'Hi', body: 'There'))['data']!
              as Map<String, Object?>;

      expect(data.keys, containsAll(['id', 'title', 'body', 'sentAt']));
      expect(data, hasLength(4));
    });

    test('writes every data value as a string, as FCM requires', () {
      final data = messageFor(draft)['data']! as Map<String, Object?>;

      expect(data.values, everyElement(isA<String>()));
    });
  });
}
```

- [ ] **Step 4: Run the test to verify it fails**

Run from `apps/fcm_api`: `fvm dart test test/notification_message_test.dart`
Expected: FAIL — `Target of URI doesn't exist: 'package:fcm_api/fcm_api.dart'`.

- [ ] **Step 5: Write the message builder**

`apps/fcm_api/lib/src/notification_message.dart`:

```dart
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';

/// The FCM HTTP v1 request body for one draft.
///
/// Pure translation, so the exact payload FCM will receive is assertable in a
/// unit test without a network or a credential.
class NotificationMessage {
  const NotificationMessage({
    required this.token,
    required this.draft,
    required this.payloadId,
    required this.sentAt,
  });

  /// The registration token to deliver to.
  final String token;

  /// What to send.
  final NotificationDraft draft;

  /// The `id` data key. Stamped by the server, and echoed to the caller so the
  /// send can be matched to the arrival in the inbox.
  final String payloadId;

  /// The `sentAt` data key, in UTC.
  final DateTime sentAt;

  /// The body to POST to `…/messages:send`.
  ///
  /// `title` and `body` appear twice on purpose: the `notification` block is what
  /// the OS renders while the app is backgrounded, and the `data` copies are what
  /// `PushMessageParser` reads — it requires all four of `id`, `title`, `body`
  /// and `sentAt` to be present in `data`.
  ///
  /// The extra keys are spread last, but they cannot shadow the required four:
  /// the validator rejects a draft whose data collides with a reserved key, and
  /// the server validates before building this.
  Map<String, Object?> toJson() => {
    'message': {
      'token': token,
      'notification': {'title': draft.title, 'body': draft.body},
      'android': {'priority': 'high'},
      'data': {
        'id': payloadId,
        'title': draft.title,
        'body': draft.body,
        'sentAt': sentAt.toIso8601String(),
        ...draft.data,
      },
    },
  };
}
```

`apps/fcm_api/lib/fcm_api.dart`:

```dart
/// A local HTTP server with one endpoint that sends a push through FCM.
///
/// The interesting logic is in [NotificationMessage] and `sendNotification`,
/// both of which are pure — no socket, no credential — so the payload and the
/// status codes are unit-testable directly.
library;

export 'src/notification_message.dart';
```

- [ ] **Step 6: Run the test to verify it passes**

Run from `apps/fcm_api`: `fvm dart test test/notification_message_test.dart`
Expected: PASS, 8 tests.

- [ ] **Step 7: Commit**

```bash
git add pubspec.yaml pubspec.lock apps/fcm_api
git commit -m "feat(api): add fcm_api with the FCM v1 message builder"
```

---

### Task 6: The sender seam and the `sendNotification` handler

**Files:**
- Create: `apps/fcm_api/lib/src/fcm_sender.dart`
- Create: `apps/fcm_api/lib/src/fcm_send_exception.dart`
- Create: `apps/fcm_api/lib/src/send_outcome.dart`
- Create: `apps/fcm_api/lib/src/send_notification.dart`
- Modify: `apps/fcm_api/lib/fcm_api.dart`
- Create: `apps/fcm_api/test/fake_fcm_sender.dart`
- Test: `apps/fcm_api/test/send_notification_test.dart`

**Interfaces:**
- Consumes: `NotificationMessage` (Task 5); `SendNotificationRequest`, `SendNotificationResponse`, `ApiError`, `NotificationDraftValidator` (Tasks 2 and 4).
- Produces:
  - `abstract interface class FcmSender` with `Future<String> send(Map<String, Object?> message)`
  - `class FcmSendException implements Exception` with `const FcmSendException({required String status, required String message})`
  - `sealed class SendOutcome`; `final class SendSucceeded extends SendOutcome` with `const SendSucceeded(SendNotificationResponse response)`; `final class SendRejected extends SendOutcome` with `const SendRejected({required int statusCode, required ApiError error})`
  - `Future<SendOutcome> sendNotification(SendNotificationRequest request, {required FcmSender sender, required String Function() newPayloadId, required DateTime Function() now})`

**Why an outcome rather than exceptions:** the router then has one exhaustive `switch` and no `catch` blocks deciding status codes, and each rejection's code is asserted in a unit test rather than inferred from which exception escaped.

- [ ] **Step 1: Write the fake sender**

`apps/fcm_api/test/fake_fcm_sender.dart`:

```dart
import 'package:fcm_api/fcm_api.dart';

/// An [FcmSender] driven by the test rather than by FCM.
class FakeFcmSender implements FcmSender {
  FakeFcmSender({this.messageId = 'projects/p/messages/0:17', this.failure});

  /// Returned by [send] when [failure] is null.
  final String messageId;

  /// Thrown by [send] when set — used to check the error mapping.
  final FcmSendException? failure;

  /// Every message handed to [send], so the payload can be asserted.
  final sent = <Map<String, Object?>>[];

  @override
  Future<String> send(Map<String, Object?> message) async {
    sent.add(message);
    if (failure case final failure?) {
      throw failure;
    }

    return messageId;
  }
}
```

- [ ] **Step 2: Write the failing test**

`apps/fcm_api/test/send_notification_test.dart`:

```dart
import 'package:fcm_api/fcm_api.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:test/test.dart';

import 'fake_fcm_sender.dart';

void main() {
  final sentAt = DateTime.utc(2026, 8, 11, 9, 12, 3);

  Future<SendOutcome> run(
    SendNotificationRequest request, {
    FakeFcmSender? sender,
  }) => sendNotification(
    request,
    sender: sender ?? FakeFcmSender(),
    newPayloadId: () => 'api-1754812345678901',
    now: () => sentAt,
  );

  SendNotificationRequest request({
    String token = 'device-token',
    String title = 'Build finished',
    String body = 'main #128 passed',
    Map<String, String> data = const {},
  }) => SendNotificationRequest(
    token: token,
    draft: NotificationDraft(title: title, body: body, data: data),
  );

  group('sendNotification', () {
    test('reports the id and timestamp it stamped, not the caller\'s', () async {
      final outcome = await run(request());

      expect(outcome, isA<SendSucceeded>());
      final response = (outcome as SendSucceeded).response;
      expect(response.payloadId, 'api-1754812345678901');
      expect(response.sentAt, sentAt);
      expect(response.messageId, 'projects/p/messages/0:17');
    });

    test('hands FCM the message built from the draft', () async {
      final sender = FakeFcmSender();

      await run(request(data: {'event': 'build_finished'}), sender: sender);

      expect(sender.sent, hasLength(1));
      final message = sender.sent.single['message']! as Map<String, Object?>;
      final data = message['data']! as Map<String, Object?>;
      expect(message['token'], 'device-token');
      expect(data['id'], 'api-1754812345678901');
      expect(data['event'], 'build_finished');
    });

    test('rejects a blank token with 400, naming the field', () async {
      final outcome = await run(request(token: '  '));

      expect(outcome, isA<SendRejected>());
      final rejected = outcome as SendRejected;
      expect(rejected.statusCode, 400);
      expect(rejected.error.field, 'token');
    });

    test('rejects an invalid draft with 400 and does not call FCM', () async {
      final sender = FakeFcmSender();

      final outcome = await run(request(title: ''), sender: sender);

      expect((outcome as SendRejected).statusCode, 400);
      expect(outcome.error.field, 'title');
      expect(outcome.error.message, contains('must not be blank'));
      expect(sender.sent, isEmpty);
    });

    test('rejects a draft whose data collides with a reserved key', () async {
      final outcome = await run(request(data: {'sentAt': 'now'}));

      expect((outcome as SendRejected).statusCode, 400);
      expect(outcome.error.field, 'data.sentAt');
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
      expect(outcome.error.message, isNot(contains('UNREGISTERED')));
    });

    test('maps a rejected argument to 400', () async {
      final sender = FakeFcmSender(
        failure: const FcmSendException(
          status: 'INVALID_ARGUMENT',
          message: 'The registration token is not a valid FCM token.',
        ),
      );

      final outcome = await run(request(), sender: sender);

      expect((outcome as SendRejected).statusCode, 400);
      expect(outcome.error.message, contains('not a valid FCM token'));
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
      expect(outcome.error.field, isNull);
    });
  });
}
```

- [ ] **Step 3: Run the test to verify it fails**

Run from `apps/fcm_api`: `fvm dart test test/send_notification_test.dart`
Expected: FAIL — `Undefined name 'sendNotification'`.

- [ ] **Step 4: Write the sender seam**

`apps/fcm_api/lib/src/fcm_sender.dart`:

```dart
/// The seam between the handler and FCM.
///
/// The same shape as `PushSource` in the app: an interface, one implementation
/// over the network, and a fake in the tests — so the handler's behaviour is
/// testable without a credential or a socket.
abstract interface class FcmSender {
  /// Sends an FCM HTTP v1 request body and returns the message name FCM
  /// assigned, or throws [FcmSendException] if FCM refused it.
  Future<String> send(Map<String, Object?> message);
}
```

`apps/fcm_api/lib/src/fcm_send_exception.dart`:

```dart
/// A send FCM refused.
///
/// [status] is FCM's own error code — `UNREGISTERED`, `INVALID_ARGUMENT`,
/// `QUOTA_EXCEEDED` and so on — kept verbatim so the handler can decide the HTTP
/// status without re-parsing prose.
class FcmSendException implements Exception {
  const FcmSendException({required this.status, required this.message});

  /// FCM's error code.
  final String status;

  /// FCM's own explanation.
  final String message;

  @override
  String toString() => 'FcmSendException($status): $message';
}
```

- [ ] **Step 5: Write the outcome**

`apps/fcm_api/lib/src/send_outcome.dart`:

```dart
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';

/// What a send attempt produced: the response to return, or the error to report
/// with the status it deserves.
///
/// Sealed rather than thrown, so the router decides nothing — it switches once,
/// exhaustively — and every status code is asserted in a unit test.
sealed class SendOutcome {
  const SendOutcome();
}

/// FCM accepted the message.
final class SendSucceeded extends SendOutcome {
  const SendSucceeded(this.response);

  /// The 200 body.
  final SendNotificationResponse response;
}

/// The send did not happen, or FCM refused it.
final class SendRejected extends SendOutcome {
  const SendRejected({required this.statusCode, required this.error});

  /// The HTTP status to answer with.
  final int statusCode;

  /// The body to answer with.
  final ApiError error;
}
```

- [ ] **Step 6: Write the handler**

`apps/fcm_api/lib/src/send_notification.dart`:

```dart
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';

import 'fcm_send_exception.dart';
import 'fcm_sender.dart';
import 'notification_message.dart';
import 'send_outcome.dart';

/// Validates, stamps and sends one notification.
///
/// Takes its clock and its id generator as parameters rather than reading them
/// from the environment, so its tests assert exact values instead of matching
/// patterns — and it depends on no `Request`, no credential and no socket.
Future<SendOutcome> sendNotification(
  SendNotificationRequest request, {
  required FcmSender sender,
  required String Function() newPayloadId,
  required DateTime Function() now,
}) async {
  if (request.token.trim().isEmpty) {
    return const SendRejected(
      statusCode: 400,
      error: ApiError('token must not be blank', field: 'token'),
    );
  }

  final problems = const NotificationDraftValidator().validate(request.draft);
  if (problems.isNotEmpty) {
    final problem = problems.first;

    return SendRejected(
      statusCode: 400,
      error: ApiError('$problem', field: problem.field),
    );
  }

  final message = NotificationMessage(
    token: request.token,
    draft: request.draft,
    payloadId: newPayloadId(),
    sentAt: now(),
  );

  try {
    final messageId = await sender.send(message.toJson());

    return SendSucceeded(
      SendNotificationResponse(
        messageId: messageId,
        payloadId: message.payloadId,
        sentAt: message.sentAt,
      ),
    );
  } on FcmSendException catch (error) {
    return SendRejected(
      statusCode: _statusFor(error.status),
      error: ApiError(_messageFor(error)),
    );
  }
}

/// FCM's error codes, mapped onto the status the caller should see.
int _statusFor(String fcmStatus) => switch (fcmStatus) {
  'UNREGISTERED' => 404,
  'INVALID_ARGUMENT' => 400,
  _ => 502,
};

/// A stale token is the common failure and gets wording of its own, because
/// `UNREGISTERED` tells the person holding the phone nothing.
String _messageFor(FcmSendException error) => switch (error.status) {
  'UNREGISTERED' =>
    'The registration token is no longer valid — the app was reinstalled or '
        'the token rotated. Restart the app to get a fresh one.',
  'INVALID_ARGUMENT' => 'FCM rejected the message: ${error.message}',
  _ => 'FCM failed (${error.status}): ${error.message}',
};
```

`'$problem'` uses `DraftProblem.toString()`, which is `'<field> <message>'` — so a blank title becomes `title must not be blank`. That is why `DraftProblem.message` is phrased to follow the field name.

Add the exports to `apps/fcm_api/lib/fcm_api.dart`, alphabetically:

```dart
export 'src/fcm_send_exception.dart';
export 'src/fcm_sender.dart';
export 'src/notification_message.dart';
export 'src/send_notification.dart';
export 'src/send_outcome.dart';
```

- [ ] **Step 7: Run the test to verify it passes**

Run from `apps/fcm_api`: `fvm dart test test/send_notification_test.dart`
Expected: PASS, 8 tests.

- [ ] **Step 8: Check the analyzer and DCM**

Run from the repo root: `fvm dart run melos run analyze && fvm dart run melos run dcm`
Expected: both green.

- [ ] **Step 9: Commit**

```bash
git add apps/fcm_api
git commit -m "feat(api): add the send handler behind an FcmSender seam"
```

---

### Task 7: `ApiRouter`

**Files:**
- Create: `apps/fcm_api/lib/src/api_router.dart`
- Modify: `apps/fcm_api/lib/fcm_api.dart`
- Test: `apps/fcm_api/test/api_router_test.dart`

**Interfaces:**
- Consumes: `sendNotification`, `SendOutcome`, `FcmSender`, `FcmSendException` (Task 6); `FakeFcmSender` (Task 6).
- Produces:
  - `class ApiRouter` with `ApiRouter({required FcmSender sender, required String Function() newPayloadId, required DateTime Function() now})` and `Handler get handler`

- [ ] **Step 1: Write the failing test**

`apps/fcm_api/test/api_router_test.dart`:

```dart
import 'dart:convert';

import 'package:fcm_api/fcm_api.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

import 'fake_fcm_sender.dart';

void main() {
  final sentAt = DateTime.utc(2026, 8, 11, 9, 12, 3);

  Handler handlerWith(FakeFcmSender sender) => ApiRouter(
    sender: sender,
    newPayloadId: () => 'api-1754812345678901',
    now: () => sentAt,
  ).handler;

  Future<Response> post(Object? body, {FakeFcmSender? sender}) => handlerWith(
    sender ?? FakeFcmSender(),
  )(
    Request(
      'POST',
      Uri.parse('http://localhost:8080/send'),
      body: body is String ? body : jsonEncode(body),
      headers: const {'content-type': 'application/json'},
    ),
  );

  Future<Map<String, dynamic>> bodyOf(Response response) async =>
      jsonDecode(await response.readAsString()) as Map<String, dynamic>;

  Map<String, Object?> validBody({
    String token = 'device-token',
    String title = 'Build finished',
  }) => {'token': token, 'title': title, 'body': 'main #128 passed'};

  group('GET /health', () {
    test('answers 200 so the server can be checked without sending', () async {
      final response = await handlerWith(FakeFcmSender())(
        Request('GET', Uri.parse('http://localhost:8080/health')),
      );

      expect(response.statusCode, 200);
      expect(await bodyOf(response), {'status': 'ok'});
    });
  });

  group('POST /send', () {
    test('answers 200 with the stamped id and timestamp', () async {
      final response = await post(validBody());

      expect(response.statusCode, 200);
      expect(await bodyOf(response), {
        'messageId': 'projects/p/messages/0:17',
        'id': 'api-1754812345678901',
        'sentAt': '2026-08-11T09:12:03.000Z',
      });
    });

    test('answers JSON', () async {
      final response = await post(validBody());

      expect(response.headers['content-type'], startsWith('application/json'));
    });

    test('answers 400 when the body is not JSON at all', () async {
      final response = await post('not json');

      expect(response.statusCode, 400);
      expect(await bodyOf(response), contains('error'));
    });

    test('answers 400 when the body is a JSON array', () async {
      final response = await post([1, 2, 3]);

      expect(response.statusCode, 400);
      expect((await bodyOf(response))['error'], contains('object'));
    });

    test('answers 400 with the field when a data value is not a string', () async {
      final response = await post({
        ...validBody(),
        'data': {'retries': 3},
      });

      expect(response.statusCode, 400);
      expect((await bodyOf(response))['error'], contains('retries'));
    });

    test('answers 400 and names the field for an invalid draft', () async {
      final response = await post(validBody(title: ''));

      expect(response.statusCode, 400);
      expect(await bodyOf(response), {
        'error': 'title must not be blank',
        'field': 'title',
      });
    });

    test('answers 404 for an unregistered token', () async {
      final response = await post(
        validBody(),
        sender: FakeFcmSender(
          failure: const FcmSendException(
            status: 'UNREGISTERED',
            message: 'Requested entity was not found.',
          ),
        ),
      );

      expect(response.statusCode, 404);
      expect((await bodyOf(response))['error'], contains('no longer valid'));
    });

    test('answers 502 when FCM fails for any other reason', () async {
      final response = await post(
        validBody(),
        sender: FakeFcmSender(
          failure: const FcmSendException(
            status: 'INTERNAL',
            message: 'Backend error.',
          ),
        ),
      );

      expect(response.statusCode, 502);
    });
  });

  group('unknown routes', () {
    test('answer 404 with the same error shape as everything else', () async {
      final response = await handlerWith(FakeFcmSender())(
        Request('GET', Uri.parse('http://localhost:8080/nope')),
      );

      expect(response.statusCode, 404);
      expect(await bodyOf(response), contains('error'));
    });

    test('answer 404 for GET /send, which only accepts POST', () async {
      final response = await handlerWith(FakeFcmSender())(
        Request('GET', Uri.parse('http://localhost:8080/send')),
      );

      expect(response.statusCode, 404);
    });
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run from `apps/fcm_api`: `fvm dart test test/api_router_test.dart`
Expected: FAIL — `Undefined name 'ApiRouter'`.

- [ ] **Step 3: Write the router**

`apps/fcm_api/lib/src/api_router.dart`:

```dart
import 'dart:convert';

import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'fcm_sender.dart';
import 'send_notification.dart';
import 'send_outcome.dart';

/// The HTTP surface: two routes, JSON in and JSON out.
///
/// It decides nothing about a send — [sendNotification] returns the status and
/// the body, and this class only translates between that and `shelf`.
class ApiRouter {
  ApiRouter({
    required FcmSender sender,
    required String Function() newPayloadId,
    required DateTime Function() now,
  }) : _sender = sender,
       _newPayloadId = newPayloadId,
       _now = now;

  final FcmSender _sender;
  final String Function() _newPayloadId;
  final DateTime Function() _now;

  /// The handler to serve.
  Handler get handler {
    final router = Router(notFoundHandler: _notFound)
      ..get('/health', _health)
      ..post('/send', _send);

    return router.call;
  }

  Response _health(Request request) => _json(200, const {'status': 'ok'});

  Future<Response> _send(Request request) async {
    final SendNotificationRequest parsed;
    try {
      parsed = SendNotificationRequest.fromJson(
        _decodeObject(await request.readAsString()),
      );
    } on FormatException catch (error) {
      return _json(400, ApiError(error.message).toJson());
    }

    final outcome = await sendNotification(
      parsed,
      sender: _sender,
      newPayloadId: _newPayloadId,
      now: _now,
    );

    return switch (outcome) {
      SendSucceeded(:final response) => _json(200, response.toJson()),
      SendRejected(:final statusCode, :final error) =>
        _json(statusCode, error.toJson()),
    };
  }

  Response _notFound(Request request) => _json(
    404,
    const ApiError(
      'No such route. The API has POST /send and GET /health.',
    ).toJson(),
  );
}

/// Decodes a request body that must be a JSON object.
///
/// A JSON array or a bare value is as malformed as broken JSON, and both must
/// reach the caller as a 400 rather than as a cast failure.
Map<String, dynamic> _decodeObject(String body) {
  final decoded = jsonDecode(body);
  if (decoded is! Map<String, dynamic>) {
    throw FormatException(
      'The body must be a JSON object, got ${decoded.runtimeType}',
    );
  }

  return decoded;
}

Response _json(int statusCode, Map<String, dynamic> body) => Response(
  statusCode,
  body: jsonEncode(body),
  headers: const {'content-type': 'application/json'},
);
```

Add the export to `apps/fcm_api/lib/fcm_api.dart`, alphabetically first:

```dart
export 'src/api_router.dart';
```

- [ ] **Step 4: Run the test to verify it passes**

Run from `apps/fcm_api`: `fvm dart test test/api_router_test.dart`
Expected: PASS, 11 tests.

If the `jsonDecode('not json')` case surfaces as something other than a
`FormatException`, do not widen the `catch` — `jsonDecode` throws
`FormatException` by contract, so an unexpected type means the body was read
wrongly, not that the mapping is incomplete.

- [ ] **Step 5: Commit**

```bash
git add apps/fcm_api
git commit -m "feat(api): add the router over POST /send and GET /health"
```

---

### Task 8: `HttpV1FcmSender`

**Files:**
- Create: `apps/fcm_api/lib/src/http_v1_fcm_sender.dart`
- Modify: `apps/fcm_api/lib/fcm_api.dart`
- Test: `apps/fcm_api/test/http_v1_fcm_sender_test.dart`

**Interfaces:**
- Consumes: `FcmSender`, `FcmSendException` (Task 6).
- Produces:
  - `const String fcmMessagingScope` — `'https://www.googleapis.com/auth/firebase.messaging'`
  - `class HttpV1FcmSender implements FcmSender` with `HttpV1FcmSender({required http.Client client, required String projectId})`

**Why the client is injected:** in production it is an `AutoRefreshingAuthClient` from `googleapis_auth`, which adds and refreshes the bearer token itself. Because the constructor takes any `http.Client`, the tests drive it with `MockClient` from `package:http/testing.dart` and need no credential.

**The detail that matters:** FCM v1 reports a dead token as HTTP 404 with `error.status: "NOT_FOUND"`, and the code worth acting on — `UNREGISTERED` — appears only in `error.details[].errorCode`. Reading `status` alone would mis-map the single most common failure, so `details` is read first and `status` is the fallback.

- [ ] **Step 1: Write the failing test**

`apps/fcm_api/test/http_v1_fcm_sender_test.dart`:

```dart
import 'dart:convert';

import 'package:fcm_api/fcm_api.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

void main() {
  late List<http.Request> requests;

  MockClient clientAnswering(int statusCode, Object? body) => MockClient((
    request,
  ) async {
    requests.add(request);

    return http.Response(
      jsonEncode(body),
      statusCode,
      headers: const {'content-type': 'application/json'},
    );
  });

  HttpV1FcmSender senderWith(http.Client client) =>
      HttpV1FcmSender(client: client, projectId: 'fcm-sandbox-770fa');

  Map<String, Object?> fcmError({
    required String status,
    String message = 'Something went wrong.',
    String? errorCode,
  }) => {
    'error': {
      'code': 400,
      'message': message,
      'status': status,
      if (errorCode != null)
        'details': [
          {
            '@type': 'type.googleapis.com/google.firebase.fcm.v1.FcmError',
            'errorCode': errorCode,
          },
        ],
    },
  };

  setUp(() {
    requests = [];
  });

  group('HttpV1FcmSender.send', () {
    test('posts to the project\'s messages:send endpoint', () async {
      final sender = senderWith(
        clientAnswering(200, {'name': 'projects/p/messages/0:17'}),
      );

      await sender.send(const {'message': <String, Object?>{}});

      expect(
        requests.single.url.toString(),
        'https://fcm.googleapis.com/v1/projects/fcm-sandbox-770fa/messages:send',
      );
      expect(requests.single.method, 'POST');
    });

    test('sends the message as the JSON body', () async {
      final sender = senderWith(
        clientAnswering(200, {'name': 'projects/p/messages/0:17'}),
      );

      await sender.send(const {
        'message': {'token': 'device-token'},
      });

      expect(jsonDecode(requests.single.body), {
        'message': {'token': 'device-token'},
      });
    });

    test('returns the message name FCM assigned', () async {
      final sender = senderWith(
        clientAnswering(200, {'name': 'projects/p/messages/0:17'}),
      );

      expect(
        await sender.send(const {'message': <String, Object?>{}}),
        'projects/p/messages/0:17',
      );
    });

    test('prefers the FcmError detail over the generic status', () async {
      final sender = senderWith(
        clientAnswering(
          404,
          fcmError(
            status: 'NOT_FOUND',
            message: 'Requested entity was not found.',
            errorCode: 'UNREGISTERED',
          ),
        ),
      );

      await expectLater(
        () => sender.send(const {'message': <String, Object?>{}}),
        throwsA(
          isA<FcmSendException>()
              .having((error) => error.status, 'status', 'UNREGISTERED')
              .having(
                (error) => error.message,
                'message',
                'Requested entity was not found.',
              ),
        ),
      );
    });

    test('falls back to the generic status when there is no detail', () async {
      final sender = senderWith(
        clientAnswering(429, fcmError(status: 'RESOURCE_EXHAUSTED')),
      );

      await expectLater(
        () => sender.send(const {'message': <String, Object?>{}}),
        throwsA(
          isA<FcmSendException>().having(
            (error) => error.status,
            'status',
            'RESOURCE_EXHAUSTED',
          ),
        ),
      );
    });

    test('survives an error body that is not the documented shape', () async {
      final sender = senderWith(clientAnswering(500, 'gateway exploded'));

      await expectLater(
        () => sender.send(const {'message': <String, Object?>{}}),
        throwsA(
          isA<FcmSendException>()
              .having((error) => error.status, 'status', 'UNKNOWN')
              .having(
                (error) => error.message,
                'message',
                contains('gateway exploded'),
              ),
        ),
      );
    });

    test('treats a 200 without a name as a failure, not a silent success', () async {
      final sender = senderWith(clientAnswering(200, const <String, Object?>{}));

      await expectLater(
        () => sender.send(const {'message': <String, Object?>{}}),
        throwsA(isA<FcmSendException>()),
      );
    });
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run from `apps/fcm_api`: `fvm dart test test/http_v1_fcm_sender_test.dart`
Expected: FAIL — `Undefined name 'HttpV1FcmSender'`.

- [ ] **Step 3: Write the sender**

`apps/fcm_api/lib/src/http_v1_fcm_sender.dart`:

```dart
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'fcm_send_exception.dart';
import 'fcm_sender.dart';

/// The one OAuth2 scope this server needs.
const fcmMessagingScope = 'https://www.googleapis.com/auth/firebase.messaging';

/// Sends through the FCM HTTP v1 REST API.
///
/// The client is injected because in production it is an
/// `AutoRefreshingAuthClient` from `googleapis_auth`, which adds and refreshes
/// the bearer token itself — and because that leaves the tests able to drive
/// this with a `MockClient` and no credential.
class HttpV1FcmSender implements FcmSender {
  HttpV1FcmSender({required http.Client client, required String projectId})
    : _client = client,
      _projectId = projectId;

  final http.Client _client;
  final String _projectId;

  @override
  Future<String> send(Map<String, Object?> message) async {
    final response = await _client.post(
      Uri.https(
        'fcm.googleapis.com',
        '/v1/projects/$_projectId/messages:send',
      ),
      headers: const {'content-type': 'application/json'},
      body: jsonEncode(message),
    );

    if (response.statusCode != 200) {
      throw _exceptionFrom(response);
    }

    final name = _decode(response.body)?['name'];
    if (name is! String) {
      throw FcmSendException(
        status: 'UNKNOWN',
        message: 'FCM accepted the message but returned no name: '
            '${response.body}',
      );
    }

    return name;
  }
}

/// Reads FCM's error body.
///
/// The code worth acting on lives in `error.details[].errorCode` —
/// `UNREGISTERED` for a dead token — while `error.status` only carries the
/// generic gRPC name (`NOT_FOUND`). Reading `status` alone would mis-map the
/// most common failure there is, so the detail wins when it is present.
FcmSendException _exceptionFrom(http.Response response) {
  final error = _decode(response.body)?['error'];
  if (error is! Map<String, Object?>) {
    return FcmSendException(
      status: 'UNKNOWN',
      message: 'FCM answered ${response.statusCode}: ${response.body}',
    );
  }

  final message = error['message'];

  return FcmSendException(
    status: _errorCodeIn(error['details']) ?? _textOr(error['status'], 'UNKNOWN'),
    message: _textOr(message, 'FCM answered ${response.statusCode}.'),
  );
}

/// The `errorCode` of the first detail that carries one, or null.
String? _errorCodeIn(Object? details) {
  if (details is! List<Object?>) {
    return null;
  }

  for (final detail in details) {
    if (detail is Map<String, Object?> && detail['errorCode'] is String) {
      return detail['errorCode']! as String;
    }
  }

  return null;
}

Map<String, Object?>? _decode(String body) {
  try {
    final decoded = jsonDecode(body);

    return decoded is Map<String, Object?> ? decoded : null;
  } on FormatException {
    return null;
  }
}

String _textOr(Object? value, String fallback) =>
    value is String && value.isNotEmpty ? value : fallback;
```

Add the export to `apps/fcm_api/lib/fcm_api.dart`, alphabetically after `fcm_sender.dart`:

```dart
export 'src/http_v1_fcm_sender.dart';
```

- [ ] **Step 4: Run the test to verify it passes**

Run from `apps/fcm_api`: `fvm dart test test/http_v1_fcm_sender_test.dart`
Expected: PASS, 7 tests.

- [ ] **Step 5: Check the analyzer and DCM**

Run from the repo root: `fvm dart run melos run analyze && fvm dart run melos run dcm`
Expected: both green.

- [ ] **Step 6: Commit**

```bash
git add apps/fcm_api
git commit -m "feat(api): send through the FCM HTTP v1 REST API"
```

---

### Task 9: `ServerConfig`, the entry point, and a real send

This is the first task whose deliverable is verified against Google's servers rather than a fake.

**Files:**
- Create: `apps/fcm_api/lib/src/server_config.dart`
- Create: `apps/fcm_api/bin/server.dart`
- Modify: `apps/fcm_api/lib/fcm_api.dart`
- Modify: `pubspec.yaml` (melos `scripts:`)
- Modify: `.gitignore`
- Test: `apps/fcm_api/test/server_config_test.dart`

**Interfaces:**
- Consumes: `ApiRouter` (Task 7), `HttpV1FcmSender` and `fcmMessagingScope` (Task 8).
- Produces:
  - `class ServerConfig` with `const ServerConfig({required Map<String, dynamic> serviceAccountJson, required String projectId, required int port})` and `factory ServerConfig.fromEnvironment(Map<String, String> environment, {required String Function(String path) readFile})`, throwing `StateError` with a message naming what is wrong

**Why `ServerConfig` holds the raw JSON map rather than a `ServiceAccountCredentials`:** it keeps `googleapis_auth` out of the config unit entirely, so its tests need no plausible RSA key — `bin/server.dart` does the one-line conversion.

- [ ] **Step 1: Write the failing test**

`apps/fcm_api/test/server_config_test.dart`:

```dart
import 'dart:convert';

import 'package:fcm_api/fcm_api.dart';
import 'package:test/test.dart';

void main() {
  const keyPath = '/keys/service-account.json';
  final keyJson = jsonEncode({
    'type': 'service_account',
    'project_id': 'fcm-sandbox-770fa',
    'client_email': 'sender@fcm-sandbox-770fa.iam.gserviceaccount.com',
    'private_key': '-----BEGIN PRIVATE KEY-----\nnot-a-real-key\n',
  });

  ServerConfig read(
    Map<String, String> environment, {
    String? fileContents,
    Object? fileError,
  }) => ServerConfig.fromEnvironment(
    environment,
    readFile: (path) {
      if (fileError != null) {
        throw fileError;
      }

      return fileContents ?? keyJson;
    },
  );

  group('ServerConfig.fromEnvironment', () {
    test('reads the service account from GOOGLE_APPLICATION_CREDENTIALS', () {
      final config = read(const {'GOOGLE_APPLICATION_CREDENTIALS': keyPath});

      expect(config.serviceAccountJson['client_email'], isNotNull);
    });

    test('defaults the project id to the key\'s own project', () {
      final config = read(const {'GOOGLE_APPLICATION_CREDENTIALS': keyPath});

      expect(config.projectId, 'fcm-sandbox-770fa');
    });

    test('lets FCM_PROJECT_ID override it', () {
      final config = read(const {
        'GOOGLE_APPLICATION_CREDENTIALS': keyPath,
        'FCM_PROJECT_ID': 'other-project',
      });

      expect(config.projectId, 'other-project');
    });

    test('defaults the port to 8080', () {
      final config = read(const {'GOOGLE_APPLICATION_CREDENTIALS': keyPath});

      expect(config.port, 8080);
    });

    test('reads PORT when it is set', () {
      final config = read(const {
        'GOOGLE_APPLICATION_CREDENTIALS': keyPath,
        'PORT': '9000',
      });

      expect(config.port, 9000);
    });

    test('refuses to start without a credential, saying which variable', () {
      expect(
        () => read(const {}),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('GOOGLE_APPLICATION_CREDENTIALS'),
          ),
        ),
      );
    });

    test('refuses to start when the key file cannot be read, saying the path', () {
      expect(
        () => read(
          const {'GOOGLE_APPLICATION_CREDENTIALS': keyPath},
          fileError: const FileSystemException('no such file'),
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains(keyPath),
          ),
        ),
      );
    });

    test('refuses to start when the key file is not JSON', () {
      expect(
        () => read(
          const {'GOOGLE_APPLICATION_CREDENTIALS': keyPath},
          fileContents: 'nope',
        ),
        throwsStateError,
      );
    });

    test('refuses to start when the key has no project and none is given', () {
      expect(
        () => read(
          const {'GOOGLE_APPLICATION_CREDENTIALS': keyPath},
          fileContents: jsonEncode({'type': 'service_account'}),
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('FCM_PROJECT_ID'),
          ),
        ),
      );
    });

    test('refuses to start when PORT is not a number', () {
      expect(
        () => read(const {
          'GOOGLE_APPLICATION_CREDENTIALS': keyPath,
          'PORT': 'eight thousand',
        }),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('PORT'),
          ),
        ),
      );
    });
  });
}
```

The `FileSystemException` reference means the test imports `dart:io` — add
`import 'dart:io';` at the top.

- [ ] **Step 2: Run the test to verify it fails**

Run from `apps/fcm_api`: `fvm dart test test/server_config_test.dart`
Expected: FAIL — `Undefined name 'ServerConfig'`.

- [ ] **Step 3: Write the config**

`apps/fcm_api/lib/src/server_config.dart`:

```dart
import 'dart:convert';

/// Everything the server reads from its environment, resolved once at startup.
///
/// Every failure here is a [StateError] naming the variable at fault, and the
/// entry point refuses to serve — a missing credential must surface as "the
/// server would not start" rather than as a 500 on somebody's first send.
class ServerConfig {
  const ServerConfig({
    required this.serviceAccountJson,
    required this.projectId,
    required this.port,
  });

  /// Reads the config from [environment], using [readFile] to load the service
  /// account key.
  ///
  /// [readFile] is a parameter rather than a direct `File(...).readAsStringSync`
  /// so the rules here are testable without touching a disk or holding a real
  /// key.
  factory ServerConfig.fromEnvironment(
    Map<String, String> environment, {
    required String Function(String path) readFile,
  }) {
    final path = environment['GOOGLE_APPLICATION_CREDENTIALS'];
    if (path == null || path.trim().isEmpty) {
      throw StateError(
        'GOOGLE_APPLICATION_CREDENTIALS is not set. It must point at a Firebase '
        'service account JSON key — see apps/fcm_api/README.md.',
      );
    }

    final serviceAccountJson = _readServiceAccount(path, readFile);
    final projectId =
        environment['FCM_PROJECT_ID'] ??
        _textOrNull(serviceAccountJson['project_id']);
    if (projectId == null) {
      throw StateError(
        'The key at $path has no "project_id", so set FCM_PROJECT_ID.',
      );
    }

    return ServerConfig(
      serviceAccountJson: serviceAccountJson,
      projectId: projectId,
      port: _readPort(environment['PORT']),
    );
  }

  /// The service account key, as loaded. Passed straight to
  /// `ServiceAccountCredentials.fromJson`.
  final Map<String, dynamic> serviceAccountJson;

  /// The Firebase project to send through.
  final String projectId;

  /// The loopback port to listen on.
  final int port;
}

Map<String, dynamic> _readServiceAccount(
  String path,
  String Function(String path) readFile,
) {
  final String contents;
  try {
    contents = readFile(path);
  } catch (error) {
    // Any read failure is the same problem for the operator: the path is wrong
    // or unreadable. The original error is kept in the message.
    throw StateError('Could not read the service account key at $path: $error');
  }

  try {
    final decoded = jsonDecode(contents);
    if (decoded is! Map<String, dynamic>) {
      throw StateError('The key at $path is not a JSON object.');
    }

    return decoded;
  } on FormatException catch (error) {
    throw StateError('The key at $path is not valid JSON: ${error.message}');
  }
}

int _readPort(String? value) {
  if (value == null) {
    return 8080;
  }

  final port = int.tryParse(value);
  if (port == null) {
    throw StateError('PORT must be a number, got "$value".');
  }

  return port;
}

String? _textOrNull(Object? value) =>
    value is String && value.trim().isNotEmpty ? value : null;
```

Add the export to `apps/fcm_api/lib/fcm_api.dart`, alphabetically last:

```dart
export 'src/server_config.dart';
```

- [ ] **Step 4: Run the test to verify it passes**

Run from `apps/fcm_api`: `fvm dart test test/server_config_test.dart`
Expected: PASS, 10 tests.

- [ ] **Step 5: Write the entry point**

`apps/fcm_api/bin/server.dart`:

```dart
import 'dart:io';

import 'package:fcm_api/fcm_api.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';

/// Starts the send API on loopback.
///
/// Exits 64 (`EX_USAGE`) on a configuration problem, so a wrong environment is
/// distinguishable from a crash.
Future<void> main() async {
  final ServerConfig config;
  try {
    config = ServerConfig.fromEnvironment(
      Platform.environment,
      readFile: (path) => File(path).readAsStringSync(),
    );
  } on StateError catch (error) {
    stderr.writeln(error.message);
    exitCode = 64;

    return;
  }

  await _serve(config);
}

Future<void> _serve(ServerConfig config) async {
  final client = await clientViaServiceAccount(
    ServiceAccountCredentials.fromJson(config.serviceAccountJson),
    const [fcmMessagingScope],
  );

  final router = ApiRouter(
    sender: HttpV1FcmSender(client: client, projectId: config.projectId),
    // Microseconds, so two sends in the same millisecond still differ — the id
    // is what de-duplicates deliveries in the inbox.
    newPayloadId: () => 'api-${DateTime.now().microsecondsSinceEpoch}',
    now: () => DateTime.now().toUtc(),
  );

  final server = await serve(
    const Pipeline().addMiddleware(logRequests()).addHandler(router.handler),
    InternetAddress.loopbackIPv4,
    config.port,
  );

  stdout.writeln(
    'Send API listening on http://${server.address.host}:${server.port} '
    '(project ${config.projectId}).',
  );
}
```

- [ ] **Step 6: Add the melos script and gitignore the key**

In the root `pubspec.yaml`, add to `melos: scripts:`, keeping the existing style
(place it after `fix:` and before `test:core:`):

```yaml
    api:serve:
      description: >-
        Run the send API on 127.0.0.1:8080. Needs GOOGLE_APPLICATION_CREDENTIALS
        pointing at a Firebase service account key — see apps/fcm_api/README.md.
      run: fvm dart run apps/fcm_api/bin/server.dart
```

In `.gitignore`, add a section before `# OS`:

```
# Firebase service account keys. These grant send rights on the whole project.
*service-account*.json
```

- [ ] **Step 7: Verify the whole package compiles and its tests pass**

Run from `apps/fcm_api`: `fvm dart test`
Expected: PASS, 44 tests across five files.

Run from the repo root: `fvm dart run melos run ci`
Expected: green — formatting, analyzer, DCM and every test suite.

- [ ] **Step 8: Get a service account key (manual, one-time)**

This cannot be scripted; it needs a browser.

1. Open <https://console.firebase.google.com/project/fcm-sandbox-770fa/settings/serviceaccounts/adminsdk>
2. Click **Generate new private key**, then **Generate key**.
3. Save the download as `~/.config/fcm-sandbox-service-account.json` (outside the
   repo, so no gitignore rule is load-bearing).

If the Firebase Admin SDK page refuses to generate a key, the fallback is
`gcloud iam service-accounts keys create` against the same project — but the
console is the documented path and needs no `gcloud` install.

- [ ] **Step 9: Verify the server starts and answers**

In one terminal, from the repo root:

```bash
GOOGLE_APPLICATION_CREDENTIALS=~/.config/fcm-sandbox-service-account.json \
  fvm dart run melos run api:serve
```

Expected: `Send API listening on http://127.0.0.1:8080 (project fcm-sandbox-770fa).`

In another terminal:

```bash
curl -s http://127.0.0.1:8080/health
```

Expected: `{"status":"ok"}`

- [ ] **Step 10: Verify the credential path against FCM**

```bash
curl -s -o /dev/stderr -w '%{http_code}\n' -X POST http://127.0.0.1:8080/send \
  -H 'content-type: application/json' \
  -d '{"token":"definitely-not-a-real-token","title":"Hi","body":"There"}'
```

Expected: status `404` (or `400`), and a JSON body whose `error` is readable
prose rather than an FCM code.

**This is the evidence that OAuth actually worked.** An unusable token cannot
produce an FCM-level rejection unless the request carried a valid access token —
a bad credential would surface as a 502 mentioning `UNAUTHENTICATED` or a
`StateError` at startup instead. If you get a 502, the credential is the problem,
not the token.

- [ ] **Step 11: Verify a validation failure needs no round trip**

```bash
curl -s -X POST http://127.0.0.1:8080/send \
  -H 'content-type: application/json' \
  -d '{"token":"t","title":"","body":"There"}'
```

Expected: `{"error":"title must not be blank","field":"title"}`

- [ ] **Step 12: Commit**

```bash
git add pubspec.yaml .gitignore apps/fcm_api
git commit -m "feat(api): add the server entry point and startup config"
```

---

### Task 10: The app's sender seam

**Files:**
- Create: `apps/fcm_app/lib/sandbox/notification_sender.dart`
- Create: `apps/fcm_app/lib/sandbox/notification_send_exception.dart`
- Create: `apps/fcm_app/lib/sandbox/unavailable_notification_sender.dart`
- Create: `apps/fcm_app/lib/sandbox/http_notification_sender.dart`
- Modify: `apps/fcm_app/pubspec.yaml`
- Test: `apps/fcm_app/test/http_notification_sender_test.dart`

**Interfaces:**
- Consumes: `SendNotificationRequest`, `SendNotificationResponse`, `ApiError` (Task 4).
- Produces:
  - `abstract interface class NotificationSender` with `Future<SendNotificationResponse> send(SendNotificationRequest request)`
  - `class NotificationSendException implements Exception` — `const NotificationSendException(String message, {String? field})`, `.fromApiError(ApiError)`
  - `class UnavailableNotificationSender implements NotificationSender` — `const UnavailableNotificationSender(String reason)`
  - `class HttpNotificationSender implements NotificationSender` — `HttpNotificationSender({required http.Client client, required Uri baseUrl})`
  - `const String defaultApiBaseUrl` — from `--dart-define=FCM_API_BASE_URL`, default `http://localhost:8080`

- [ ] **Step 1: Add the dependencies**

In `apps/fcm_app/pubspec.yaml`, `dependencies:` becomes (alphabetical — `sort_pub_dependencies` is fatal):

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
```

Run from the repo root: `fvm dart pub get`
Expected: succeeds.

- [ ] **Step 2: Write the failing test**

`apps/fcm_app/test/http_notification_sender_test.dart`:

```dart
import 'dart:convert';

import 'package:fcm_app/sandbox/http_notification_sender.dart';
import 'package:fcm_app/sandbox/notification_send_exception.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  late List<http.Request> requests;

  HttpNotificationSender senderAnswering(int statusCode, Object? body) =>
      HttpNotificationSender(
        client: MockClient((request) async {
          requests.add(request);

          return http.Response(jsonEncode(body), statusCode);
        }),
        baseUrl: Uri.parse('http://localhost:8080'),
      );

  const request = SendNotificationRequest(
    token: 'device-token',
    draft: NotificationDraft(title: 'Build finished', body: 'main #128 passed'),
  );

  final successBody = {
    'messageId': 'projects/p/messages/0:17',
    'id': 'api-1754812345678901',
    'sentAt': '2026-08-11T09:12:03.000Z',
  };

  setUp(() {
    requests = [];
  });

  group('HttpNotificationSender.send', () {
    test('posts the flat request body to /send', () async {
      await senderAnswering(200, successBody).send(request);

      expect(requests.single.url.path, '/send');
      expect(requests.single.method, 'POST');
      expect(jsonDecode(requests.single.body), {
        'token': 'device-token',
        'title': 'Build finished',
        'body': 'main #128 passed',
        'data': <String, String>{},
      });
    });

    test('returns the parsed response', () async {
      final response = await senderAnswering(200, successBody).send(request);

      expect(response.payloadId, 'api-1754812345678901');
      expect(response.sentAt, DateTime.utc(2026, 8, 11, 9, 12, 3));
    });

    test('surfaces the server\'s error message and field', () async {
      final sender = senderAnswering(400, {
        'error': 'title must not be blank',
        'field': 'title',
      });

      await expectLater(
        () => sender.send(request),
        throwsA(
          isA<NotificationSendException>()
              .having(
                (error) => error.message,
                'message',
                'title must not be blank',
              )
              .having((error) => error.field, 'field', 'title'),
        ),
      );
    });

    test('stays readable when the error body is not the documented shape', () async {
      final sender = senderAnswering(502, 'Bad Gateway');

      await expectLater(
        () => sender.send(request),
        throwsA(
          isA<NotificationSendException>().having(
            (error) => error.message,
            'message',
            contains('502'),
          ),
        ),
      );
    });

    test('names the base URL and adb reverse when nothing is listening', () async {
      final sender = HttpNotificationSender(
        client: MockClient(
          (request) async => throw const SocketException('connection refused'),
        ),
        baseUrl: Uri.parse('http://localhost:8080'),
      );

      await expectLater(
        () => sender.send(request),
        throwsA(
          isA<NotificationSendException>()
              .having(
                (error) => error.message,
                'message',
                contains('http://localhost:8080'),
              )
              .having(
                (error) => error.message,
                'message',
                contains('adb reverse'),
              ),
        ),
      );
    });

    test('rejects a 200 body it cannot read', () async {
      final sender = senderAnswering(200, {'messageId': 'm'});

      await expectLater(
        () => sender.send(request),
        throwsA(isA<NotificationSendException>()),
      );
    });
  });

  group('UnavailableNotificationSender', () {
    test('always fails with the reason it was given', () async {
      const sender = UnavailableNotificationSender('Firebase did not start');

      await expectLater(
        () => sender.send(request),
        throwsA(
          isA<NotificationSendException>().having(
            (error) => error.message,
            'message',
            'Firebase did not start',
          ),
        ),
      );
    });
  });
}
```

The `SocketException` reference means the test imports `dart:io` — add
`import 'dart:io';` at the top, and
`import 'package:fcm_app/sandbox/unavailable_notification_sender.dart';`
alongside the other `fcm_app` imports.

- [ ] **Step 3: Run the test to verify it fails**

Run from `apps/fcm_app`: `fvm flutter test test/http_notification_sender_test.dart`
Expected: FAIL — `Target of URI doesn't exist: 'package:fcm_app/sandbox/http_notification_sender.dart'`.

- [ ] **Step 4: Write the interface and the exception**

`apps/fcm_app/lib/sandbox/notification_sender.dart`:

```dart
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';

/// A way to ask the send API for a push.
///
/// The same seam as `PushSource` on the receiving side: an interface, one
/// implementation over HTTP, and a stand-in used when the API cannot be reached
/// — so the widget tests never construct an HTTP client.
abstract interface class NotificationSender {
  /// Sends [request], or throws `NotificationSendException` with a message that
  /// is safe to show to the user.
  Future<SendNotificationResponse> send(SendNotificationRequest request);
}
```

`apps/fcm_app/lib/sandbox/notification_send_exception.dart`:

```dart
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';

/// A send that did not happen, with a message written for the person holding the
/// phone rather than for a log.
class NotificationSendException implements Exception {
  const NotificationSendException(this.message, {this.field});

  /// Rewraps the server's own error, so a 400 keeps the field it blamed.
  factory NotificationSendException.fromApiError(ApiError error) =>
      NotificationSendException(error.message, field: error.field);

  /// Shown in the UI as-is.
  final String message;

  /// The draft field at fault, when the server named one.
  final String? field;

  @override
  String toString() => message;
}
```

`apps/fcm_app/lib/sandbox/unavailable_notification_sender.dart`:

```dart
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';

import 'notification_send_exception.dart';
import 'notification_sender.dart';

/// A [NotificationSender] that always fails with the reason it cannot work.
///
/// Used when Firebase failed to start: there will be no registration token, so
/// there is nowhere to send. The reason travels to the UI instead of the app
/// special-casing a null sender — exactly as `DisabledPushSource` does on the
/// receiving side.
class UnavailableNotificationSender implements NotificationSender {
  const UnavailableNotificationSender(this.reason);

  /// Why sending is unavailable.
  final String reason;

  @override
  Future<SendNotificationResponse> send(SendNotificationRequest _) =>
      Future.error(NotificationSendException(reason));
}
```

The parameter is named `_` because it is deliberately unused and DCM's
`avoid-unused-parameters` would otherwise flag it.

- [ ] **Step 5: Write the HTTP sender**

`apps/fcm_app/lib/sandbox/http_notification_sender.dart`:

```dart
import 'dart:convert';

import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:http/http.dart' as http;

import 'notification_send_exception.dart';
import 'notification_sender.dart';

/// Where the send API is expected to be.
///
/// Overridden at build time with `--dart-define=FCM_API_BASE_URL=…`. The default
/// works on a physical device once `adb reverse tcp:8080 tcp:8080` is running,
/// and on the Android emulator it must be pointed at `http://10.0.2.2:8080`.
const defaultApiBaseUrl = String.fromEnvironment(
  'FCM_API_BASE_URL',
  defaultValue: 'http://localhost:8080',
);

/// Talks to `POST /send` on the local API.
class HttpNotificationSender implements NotificationSender {
  HttpNotificationSender({required http.Client client, required Uri baseUrl})
    : _client = client,
      _baseUrl = baseUrl;

  final http.Client _client;
  final Uri _baseUrl;

  @override
  Future<SendNotificationResponse> send(SendNotificationRequest request) async {
    final http.Response response;
    try {
      response = await _client.post(
        _baseUrl.replace(path: '/send'),
        headers: const {'content-type': 'application/json'},
        body: jsonEncode(request.toJson()),
      );
    } catch (error) {
      // Every transport failure means one thing to the user — nothing is
      // listening — and the usual cause is a forgotten port forward, so the
      // remedy goes in the message rather than the exception type.
      throw NotificationSendException(
        'Could not reach $_baseUrl — is the API running?\n'
        'On a physical device, run: adb reverse tcp:8080 tcp:8080\n'
        '($error)',
      );
    }

    if (response.statusCode != 200) {
      throw NotificationSendException.fromApiError(_errorFrom(response));
    }

    try {
      return SendNotificationResponse.fromJson(_decodeObject(response.body));
    } on FormatException catch (error) {
      throw NotificationSendException(
        'The API answered 200 with something unreadable: ${error.message}',
      );
    }
  }
}

/// Reads the server's `ApiError`, falling back to the status code when the body
/// is not one — a proxy or a crash can answer with anything.
ApiError _errorFrom(http.Response response) {
  try {
    return ApiError.fromJson(_decodeObject(response.body));
  } on FormatException {
    return ApiError(
      'The API answered ${response.statusCode}: ${response.body}',
    );
  }
}

Map<String, dynamic> _decodeObject(String body) {
  final decoded = jsonDecode(body);
  if (decoded is! Map<String, dynamic>) {
    throw FormatException('Expected a JSON object, got ${decoded.runtimeType}');
  }

  return decoded;
}
```

`_decodeObject` throws `FormatException` for a non-object *and* `jsonDecode`
throws it for invalid JSON, so both fall into the same handler.

- [ ] **Step 6: Run the test to verify it passes**

Run from `apps/fcm_app`: `fvm flutter test test/http_notification_sender_test.dart`
Expected: PASS, 7 tests.

- [ ] **Step 7: Commit**

```bash
git add apps/fcm_app pubspec.lock
git commit -m "feat(app): add the notification sender seam"
```

---

### Task 11: `SandboxController`

**Files:**
- Create: `apps/fcm_app/lib/sandbox/sandbox_send_state.dart`
- Create: `apps/fcm_app/lib/sandbox/sandbox_controller.dart`
- Create: `apps/fcm_app/test/fake_notification_sender.dart`
- Test: `apps/fcm_app/test/sandbox_controller_test.dart`

**Interfaces:**
- Consumes: `NotificationSender`, `NotificationSendException` (Task 10); `NotificationDraft`, `NotificationScenario`, `notificationGallery`, `NotificationDraftValidator`, `DraftProblem` (Tasks 1–4).
- Produces:
  - `sealed class SandboxSendState`; `SandboxIdle`, `SandboxSending`, `SandboxSent(SendNotificationResponse response)`, `SandboxFailed(String message)`
  - `class SandboxController extends ChangeNotifier` with `SandboxController({required NotificationSender sender, required String? Function() token})`, getters `title`, `body`, `entries`, `problems`, `state`, `scenarioRevision`, `draft`, `sendBlockedReason`, `canSend`, and methods `applyScenario(NotificationScenario)`, `edit({String? title, String? body, List<MapEntry<String, String>>? entries})`, `Future<void> send()`
  - `class FakeNotificationSender implements NotificationSender` (test double, reused by Tasks 12 and 13)

- [ ] **Step 1: Write the fake sender**

`apps/fcm_app/test/fake_notification_sender.dart`:

```dart
import 'package:fcm_app/sandbox/notification_send_exception.dart';
import 'package:fcm_app/sandbox/notification_sender.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';

/// A [NotificationSender] driven by the test rather than by the API.
class FakeNotificationSender implements NotificationSender {
  FakeNotificationSender({this.failure});

  /// Thrown by [send] when set.
  final NotificationSendException? failure;

  /// Every request handed to [send], so the payload can be asserted.
  final sent = <SendNotificationRequest>[];

  /// Returned by [send] on success.
  static final response = SendNotificationResponse(
    messageId: 'projects/p/messages/0:17',
    payloadId: 'api-1754812345678901',
    sentAt: DateTime.utc(2026, 8, 11, 9, 12, 3),
  );

  @override
  Future<SendNotificationResponse> send(SendNotificationRequest request) async {
    sent.add(request);
    if (failure case final failure?) {
      throw failure;
    }

    return response;
  }
}
```

- [ ] **Step 2: Write the failing test**

`apps/fcm_app/test/sandbox_controller_test.dart`:

```dart
import 'package:fcm_app/sandbox/notification_send_exception.dart';
import 'package:fcm_app/sandbox/sandbox_controller.dart';
import 'package:fcm_app/sandbox/sandbox_send_state.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_notification_sender.dart';

void main() {
  late FakeNotificationSender sender;

  SandboxController controllerWith({
    String? token = 'device-token',
    FakeNotificationSender? withSender,
  }) {
    sender = withSender ?? FakeNotificationSender();

    return SandboxController(sender: sender, token: () => token);
  }

  group('SandboxController', () {
    test('opens on the first preset, so the page is sendable immediately', () {
      final controller = controllerWith();

      expect(controller.title, notificationGallery.first.draft.title);
      expect(controller.problems, isEmpty);
      expect(controller.canSend, isTrue);
    });

    test('replaces the form when a scenario is applied', () {
      final controller = controllerWith();
      final promo = notificationGallery.firstWhere(
        (scenario) => scenario.id == 'promo',
      );

      controller.applyScenario(promo);

      expect(controller.title, promo.draft.title);
      // MapEntry has no value equality in Dart, so compare the entries as
      // records rather than the MapEntry objects themselves. (Two `const`
      // MapEntry literals do compare equal, because canonicalisation makes them
      // identical — but `data.entries` yields runtime instances, which do not.)
      expect(
        controller.entries.map((entry) => (entry.key, entry.value)),
        promo.draft.data.entries.map((entry) => (entry.key, entry.value)),
      );
    });

    test('bumps the revision on a scenario, so the fields are rebuilt', () {
      final controller = controllerWith();
      final before = controller.scenarioRevision;

      controller.applyScenario(notificationGallery.last);

      expect(controller.scenarioRevision, greaterThan(before));
    });

    test('does not bump the revision on an ordinary edit', () {
      final controller = controllerWith();
      final before = controller.scenarioRevision;

      controller.edit(title: 'Typed by hand');

      expect(controller.scenarioRevision, before);
    });

    test('reports a blank title and blocks Send', () {
      final controller = controllerWith();

      controller.edit(title: '  ');

      expect(controller.problems, contains(isA<DraftProblem>()));
      expect(controller.problems.first.field, 'title');
      expect(controller.canSend, isFalse);
      expect(controller.sendBlockedReason, isNotNull);
    });

    test('reports a duplicated data key, which the draft alone could not', () {
      final controller = controllerWith();

      controller.edit(
        entries: const [MapEntry('event', 'a'), MapEntry('event', 'b')],
      );

      expect(controller.problems, [
        const DraftProblem('data.event', 'is duplicated'),
      ]);
    });

    test('reports a data key that collides with a reserved payload key', () {
      final controller = controllerWith();

      controller.edit(entries: const [MapEntry('sentAt', 'now')]);

      expect(controller.problems.single.field, 'data.sentAt');
    });

    test('blocks Send with a reason when there is no token yet', () {
      final controller = controllerWith(token: null);

      expect(controller.canSend, isFalse);
      expect(controller.sendBlockedReason, contains('token'));
    });

    test('does not call the sender when there is no token', () async {
      final controller = controllerWith(token: null);

      await controller.send();

      expect(sender.sent, isEmpty);
      expect(controller.state, isA<SandboxFailed>());
    });

    test('sends the current draft with the device token', () async {
      final controller = controllerWith();

      controller.edit(
        title: 'Hand written',
        body: 'From the sandbox',
        entries: const [MapEntry('event', 'manual')],
      );
      await controller.send();

      expect(sender.sent, hasLength(1));
      expect(sender.sent.single.token, 'device-token');
      expect(sender.sent.single.draft, const NotificationDraft(
        title: 'Hand written',
        body: 'From the sandbox',
        data: {'event': 'manual'},
      ));
    });

    test('lands on Sent with the response, so the id can be shown', () async {
      final controller = controllerWith();

      await controller.send();

      expect(controller.state, isA<SandboxSent>());
      expect(
        (controller.state as SandboxSent).response.payloadId,
        'api-1754812345678901',
      );
    });

    test('refuses to send an invalid draft, without calling the sender', () async {
      final controller = controllerWith();

      controller.edit(body: '');
      await controller.send();

      expect(sender.sent, isEmpty);
      expect(controller.state, isA<SandboxIdle>());
    });

    test('lands on Failed and keeps the form when the send fails', () async {
      final controller = controllerWith(
        withSender: FakeNotificationSender(
          failure: const NotificationSendException('The API is unreachable'),
        ),
      );

      controller.edit(title: 'Kept');
      await controller.send();

      expect(controller.state, isA<SandboxFailed>());
      expect((controller.state as SandboxFailed).message, 'The API is unreachable');
      expect(controller.title, 'Kept');
    });

    test('notifies listeners as it goes', () async {
      final controller = controllerWith();
      var notifications = 0;
      controller.addListener(() => notifications++);

      controller.edit(title: 'Typed');
      await controller.send();

      expect(notifications, greaterThanOrEqualTo(3));
    });
  });
}
```

- [ ] **Step 3: Run the test to verify it fails**

Run from `apps/fcm_app`: `fvm flutter test test/sandbox_controller_test.dart`
Expected: FAIL — `Target of URI doesn't exist: 'package:fcm_app/sandbox/sandbox_controller.dart'`.

- [ ] **Step 4: Write the send state**

`apps/fcm_app/lib/sandbox/sandbox_send_state.dart`:

```dart
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';

/// Where a send has got to.
///
/// Sealed, so the view switches over it exhaustively instead of reading a
/// handful of booleans that could contradict each other.
sealed class SandboxSendState {
  const SandboxSendState();
}

/// Nothing has been sent yet, or the form has been edited since.
final class SandboxIdle extends SandboxSendState {
  const SandboxIdle();
}

/// A send is in flight.
final class SandboxSending extends SandboxSendState {
  const SandboxSending();
}

/// The API accepted the send.
final class SandboxSent extends SandboxSendState {
  const SandboxSent(this.response);

  /// Carries the payload id, which is what the inbox will show.
  final SendNotificationResponse response;
}

/// The send did not happen.
final class SandboxFailed extends SandboxSendState {
  const SandboxFailed(this.message);

  /// Safe to show as-is.
  final String message;
}
```

- [ ] **Step 5: Write the controller**

`apps/fcm_app/lib/sandbox/sandbox_controller.dart`:

```dart
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter/foundation.dart';

import 'notification_send_exception.dart';
import 'notification_sender.dart';
import 'sandbox_send_state.dart';

/// Holds what the Sandbox form contains and what became of the last send.
///
/// It asks for a token through a callback rather than holding a `PushInbox`, so
/// the Sandbox knows nothing about the receiving side, and it holds no
/// `TextEditingController` — that is view state, and keeping it out is what lets
/// these rules be tested without pumping a widget.
class SandboxController extends ChangeNotifier {
  SandboxController({
    required NotificationSender sender,
    required String? Function() token,
  }) : _sender = sender,
       _token = token {
    // Opening on a preset means the page is sendable on arrival, and it makes
    // the gallery's purpose obvious without a tap.
    _load(notificationGallery.first.draft);
  }

  static const _validator = NotificationDraftValidator();

  final NotificationSender _sender;
  final String? Function() _token;

  String _title = '';
  String _body = '';
  List<MapEntry<String, String>> _entries = const [];
  List<DraftProblem> _problems = const [];
  SandboxSendState _state = const SandboxIdle();
  int _scenarioRevision = 0;

  String get title => _title;

  String get body => _body;

  /// The data rows, still a list so a key typed twice is visible.
  List<MapEntry<String, String>> get entries => List.unmodifiable(_entries);

  /// What is wrong with the form right now. Empty when it can be sent.
  List<DraftProblem> get problems => _problems;

  /// Where the last send got to.
  SandboxSendState get state => _state;

  /// Bumped every time a scenario is loaded, so the view can rebuild its text
  /// fields from the new values without fighting the user's cursor.
  int get scenarioRevision => _scenarioRevision;

  /// The form as a draft, with duplicate keys collapsed — only ever read once
  /// [problems] is empty, which is where duplicates are caught.
  NotificationDraft get draft => NotificationDraft(
    title: _title,
    body: _body,
    data: Map.fromEntries(_entries),
  );

  /// Why Send cannot be pressed, or null when it can.
  String? get sendBlockedReason {
    if (_token() == null) {
      return 'No registration token yet, so there is nowhere to send.';
    }
    if (_state is SandboxSending) {
      return 'Sending…';
    }
    if (_problems.isNotEmpty) {
      return 'Fix the problems above first.';
    }

    return null;
  }

  bool get canSend => sendBlockedReason == null;

  /// Replaces the whole form with a preset.
  void applyScenario(NotificationScenario scenario) {
    _scenarioRevision++;
    _load(scenario.draft);
  }

  /// Applies an edit from the form. Anything omitted is left alone.
  void edit({
    String? title,
    String? body,
    List<MapEntry<String, String>>? entries,
  }) {
    _title = title ?? _title;
    _body = body ?? _body;
    _entries = entries ?? _entries;
    // An edit invalidates the previous result: a stale "✓ Sent" next to changed
    // fields would claim something untrue.
    _state = const SandboxIdle();
    _revalidate();
    notifyListeners();
  }

  /// Sends the current draft to this device.
  Future<void> send() async {
    final token = _token();
    if (token == null) {
      _state = const SandboxFailed(
        'No registration token yet — push is unavailable on this device.',
      );
      notifyListeners();

      return;
    }

    _revalidate();
    if (_problems.isNotEmpty) {
      notifyListeners();

      return;
    }

    _state = const SandboxSending();
    notifyListeners();

    try {
      final response = await _sender.send(
        SendNotificationRequest(token: token, draft: draft),
      );
      _state = SandboxSent(response);
    } on NotificationSendException catch (error) {
      _state = SandboxFailed(error.message);
    }
    notifyListeners();
  }

  void _load(NotificationDraft draft) {
    _title = draft.title;
    _body = draft.body;
    _entries = draft.data.entries.toList();
    _state = const SandboxIdle();
    _revalidate();
    notifyListeners();
  }

  void _revalidate() {
    _problems = _validator.validateEntries(
      title: _title,
      body: _body,
      data: _entries,
    );
  }
}
```

`_load` calls `notifyListeners()` from the constructor, which is harmless — there
are no listeners yet — and keeps `applyScenario` a two-liner.

- [ ] **Step 6: Run the test to verify it passes**

Run from `apps/fcm_app`: `fvm flutter test test/sandbox_controller_test.dart`
Expected: PASS, 14 tests.

- [ ] **Step 7: Check the analyzer and DCM**

Run from the repo root: `fvm dart run melos run analyze && fvm dart run melos run dcm`
Expected: both green.

- [ ] **Step 8: Commit**

```bash
git add apps/fcm_app
git commit -m "feat(app): add the sandbox controller"
```

---

### Task 12: The Sandbox page

Built before the shell, so it can be pumped on its own and no throwaway
placeholder is needed.

**Files:**
- Create: `apps/fcm_app/lib/ui/sandbox_view.dart`
- Create: `apps/fcm_app/lib/ui/scenario_picker.dart`
- Create: `apps/fcm_app/lib/ui/sandbox_form.dart`
- Create: `apps/fcm_app/lib/ui/data_entry_row.dart`
- Create: `apps/fcm_app/lib/ui/send_result_card.dart`
- Test: `apps/fcm_app/test/sandbox_view_test.dart`

**Interfaces:**
- Consumes: `SandboxController`, `SandboxSendState` and its four variants (Task 11); `notificationGallery` (Task 3); `FakeNotificationSender` (Task 11).
- Produces:
  - `class SandboxView extends StatelessWidget` — `const SandboxView({required SandboxController controller, super.key})`
  - `class ScenarioPicker extends StatelessWidget` — `const ScenarioPicker({required SandboxController controller, super.key})`
  - `class SandboxForm extends StatefulWidget` — `const SandboxForm({required SandboxController controller, super.key})`
  - `class DataEntryRow extends StatelessWidget` — `const DataEntryRow({required TextEditingController keyController, required TextEditingController valueController, required VoidCallback onChanged, required VoidCallback onRemove, super.key})`
  - `class SendResultCard extends StatelessWidget` — `const SendResultCard(SandboxSendState state, {super.key})`

- [ ] **Step 1: Write the failing test**

`apps/fcm_app/test/sandbox_view_test.dart`:

```dart
import 'package:fcm_app/sandbox/notification_send_exception.dart';
import 'package:fcm_app/sandbox/sandbox_controller.dart';
import 'package:fcm_app/ui/sandbox_view.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_notification_sender.dart';

void main() {
  late FakeNotificationSender sender;
  late SandboxController controller;

  void build({String? token = 'device-token', NotificationSendException? failure}) {
    sender = FakeNotificationSender(failure: failure);
    controller = SandboxController(sender: sender, token: () => token);
  }

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: SandboxView(controller: controller))),
    );
    await tester.pumpAndSettle();
  }

  Finder fieldLabelled(String label) => find.ancestor(
    of: find.text(label),
    matching: find.byType(TextField),
  );

  final first = notificationGallery.first;
  final promo = notificationGallery.firstWhere(
    (scenario) => scenario.id == 'promo',
  );

  tearDown(() => controller.dispose());

  testWidgets('opens on the first preset', (tester) async {
    build();

    await pump(tester);

    expect(find.widgetWithText(TextField, first.draft.title), findsOne);
  });

  testWidgets('offers every preset as a chip', (tester) async {
    build();

    await pump(tester);

    for (final scenario in notificationGallery) {
      expect(find.text(scenario.label), findsOne, reason: scenario.id);
    }
  });

  testWidgets('replaces the fields when a preset is tapped', (tester) async {
    build();
    await pump(tester);

    await tester.tap(find.text(promo.label));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextField, promo.draft.title), findsOne);
    expect(find.widgetWithText(TextField, 'campaign'), findsOne);
    expect(find.widgetWithText(TextField, first.draft.title), findsNothing);
  });

  testWidgets('shows a problem against the field and blocks Send', (tester) async {
    build();
    await pump(tester);

    await tester.enterText(fieldLabelled('Title'), '');
    await tester.pumpAndSettle();

    expect(find.text('must not be blank'), findsOne);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
  });

  testWidgets('explains why Send is disabled with no token', (tester) async {
    build(token: null);

    await pump(tester);

    expect(find.textContaining('nowhere to send'), findsOne);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
  });

  testWidgets('sends the edited draft to this device', (tester) async {
    build();
    await pump(tester);

    await tester.enterText(fieldLabelled('Title'), 'Hand written');
    await tester.enterText(fieldLabelled('Body'), 'From the sandbox');
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(sender.sent.single.token, 'device-token');
    expect(sender.sent.single.draft.title, 'Hand written');
    expect(sender.sent.single.draft.body, 'From the sandbox');
  });

  testWidgets('sends a data row the user added', (tester) async {
    build();
    await pump(tester);

    await tester.tap(find.text('Add key/value'));
    await tester.pumpAndSettle();
    final keyFields = find.widgetWithText(TextField, 'key');
    await tester.enterText(keyFields.last, 'ticket');
    await tester.enterText(
      find.widgetWithText(TextField, 'value').last,
      'ABC-1',
    );
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(sender.sent.single.draft.data['ticket'], 'ABC-1');
  });

  testWidgets('removes a data row', (tester) async {
    build();
    await pump(tester);
    final rowsBefore = find.byIcon(Icons.remove_circle_outline).evaluate().length;

    await tester.tap(find.byIcon(Icons.remove_circle_outline).first);
    await tester.pumpAndSettle();

    expect(
      find.byIcon(Icons.remove_circle_outline),
      findsNWidgets(rowsBefore - 1),
    );
  });

  testWidgets('shows the payload id after a send, so it can be matched', (
    tester,
  ) async {
    build();
    await pump(tester);

    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(find.textContaining('api-1754812345678901'), findsOne);
  });

  testWidgets('renders a failure and keeps what was typed', (tester) async {
    build(failure: const NotificationSendException('The API is unreachable'));
    await pump(tester);

    await tester.enterText(fieldLabelled('Title'), 'Kept');
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(find.text('The API is unreachable'), findsOne);
    expect(find.widgetWithText(TextField, 'Kept'), findsOne);
  });
}
```

`fieldLabelled` finds the `TextField` whose `labelText` is rendered as a
descendant `Text`, which is how a Material label is built — it avoids depending on
field order.

- [ ] **Step 2: Run the test to verify it fails**

Run from `apps/fcm_app`: `fvm flutter test test/sandbox_view_test.dart`
Expected: FAIL — `Target of URI doesn't exist: 'package:fcm_app/ui/sandbox_view.dart'`.

- [ ] **Step 3: Write the scenario picker**

`apps/fcm_app/lib/ui/scenario_picker.dart`:

```dart
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter/material.dart';

import '../sandbox/sandbox_controller.dart';

/// The gallery: one chip per preset.
///
/// A preset is a starting point, not a fixed payload — tapping one replaces the
/// form's contents and everything stays editable, which is why these are action
/// chips rather than a selection.
class ScenarioPicker extends StatelessWidget {
  const ScenarioPicker({required this.controller, super.key});

  final SandboxController controller;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final scenario in notificationGallery)
        ActionChip(
          key: ValueKey(scenario.id),
          label: Text(scenario.label),
          tooltip: scenario.description,
          onPressed: () => controller.applyScenario(scenario),
        ),
    ],
  );
}
```

- [ ] **Step 4: Write the data row**

`apps/fcm_app/lib/ui/data_entry_row.dart`:

```dart
import 'package:flutter/material.dart';

/// One editable extra-data key/value pair.
///
/// The controllers are owned by [SandboxForm] rather than created here, so
/// removing a row above does not shuffle text between the remaining fields.
class DataEntryRow extends StatelessWidget {
  const DataEntryRow({
    required this.keyController,
    required this.valueController,
    required this.onChanged,
    required this.onRemove,
    super.key,
  });

  final TextEditingController keyController;
  final TextEditingController valueController;

  /// Called on every keystroke, so validation keeps up with the form.
  final VoidCallback onChanged;

  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        Expanded(
          child: TextField(
            controller: keyController,
            onChanged: (_) => onChanged(),
            decoration: const InputDecoration(labelText: 'key'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: valueController,
            onChanged: (_) => onChanged(),
            decoration: const InputDecoration(labelText: 'value'),
          ),
        ),
        IconButton(
          onPressed: onRemove,
          icon: const Icon(Icons.remove_circle_outline),
          tooltip: 'Remove this key',
        ),
      ],
    ),
  );
}
```

- [ ] **Step 5: Write the form**

`apps/fcm_app/lib/ui/sandbox_form.dart`:

```dart
import 'package:flutter/material.dart';

import '../sandbox/sandbox_controller.dart';
import 'data_entry_row.dart';

/// The editable payload: title, body, and the extra data rows.
///
/// It owns the [TextEditingController]s, because those are view state and the
/// controller must stay testable without a widget pump. Loading a preset changes
/// [SandboxController.scenarioRevision], and the parent keys this widget on that
/// revision — so a preset replaces the fields by replacing this `State`, while
/// ordinary typing never disturbs the cursor.
class SandboxForm extends StatefulWidget {
  const SandboxForm({required this.controller, super.key});

  final SandboxController controller;

  @override
  State<SandboxForm> createState() => _SandboxFormState();
}

class _SandboxFormState extends State<SandboxForm> {
  late final TextEditingController _title;
  late final TextEditingController _body;
  late final List<_DataRowControllers> _rows;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.controller.title);
    _body = TextEditingController(text: widget.controller.body);
    _rows = widget.controller.entries.map(_DataRowControllers.of).toList();
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    for (final row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      TextField(
        controller: _title,
        onChanged: (_) => _push(),
        decoration: InputDecoration(
          labelText: 'Title',
          errorText: _problemWith('title'),
        ),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _body,
        onChanged: (_) => _push(),
        minLines: 2,
        maxLines: 4,
        decoration: InputDecoration(
          labelText: 'Body',
          errorText: _problemWith('body'),
        ),
      ),
      const SizedBox(height: 20),
      Text('Extra data', style: Theme.of(context).textTheme.titleSmall),
      const SizedBox(height: 8),
      for (final (index, row) in _rows.indexed)
        DataEntryRow(
          keyController: row.key,
          valueController: row.value,
          onChanged: _push,
          onRemove: () => _removeRow(index),
        ),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: _addRow,
          icon: const Icon(Icons.add),
          label: const Text('Add key/value'),
        ),
      ),
      for (final problem in widget.controller.problems)
        if (problem.field.startsWith('data'))
          Text(
            '$problem',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
    ],
  );

  /// The message for [field], or null when it is fine.
  String? _problemWith(String field) {
    for (final problem in widget.controller.problems) {
      if (problem.field == field) {
        return problem.message;
      }
    }

    return null;
  }

  /// Pushes the whole form into the controller, which revalidates.
  ///
  /// The rows go up as a list, not a map, so a key typed twice is reported
  /// instead of one value silently winning.
  void _push() => widget.controller.edit(
    title: _title.text,
    body: _body.text,
    entries: [
      for (final row in _rows) MapEntry(row.key.text, row.value.text),
    ],
  );

  void _addRow() {
    setState(() => _rows.add(_DataRowControllers.empty()));
    _push();
  }

  void _removeRow(int index) {
    setState(() => _rows.removeAt(index).dispose());
    _push();
  }
}

/// The two controllers behind one data row.
class _DataRowControllers {
  _DataRowControllers({required this.key, required this.value});

  factory _DataRowControllers.of(MapEntry<String, String> entry) =>
      _DataRowControllers(
        key: TextEditingController(text: entry.key),
        value: TextEditingController(text: entry.value),
      );

  factory _DataRowControllers.empty() => _DataRowControllers(
    key: TextEditingController(),
    value: TextEditingController(),
  );

  final TextEditingController key;
  final TextEditingController value;

  void dispose() {
    key.dispose();
    value.dispose();
  }
}
```

- [ ] **Step 6: Write the result card**

`apps/fcm_app/lib/ui/send_result_card.dart`:

```dart
import 'package:flutter/material.dart';

import '../sandbox/sandbox_send_state.dart';

/// What became of the last send.
///
/// Shows the payload id on success, because that is the value the inbox will
/// display — it is what turns "the API said 200" into "this push is mine".
class SendResultCard extends StatelessWidget {
  const SendResultCard(this.state, {super.key});

  final SandboxSendState state;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return switch (state) {
      SandboxIdle() => const SizedBox.shrink(),
      SandboxSending() => const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: LinearProgressIndicator(),
      ),
      SandboxSent(:final response) => Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Text(
          '✓ Sent · id ${response.payloadId} · it should appear in the Inbox '
          'shortly',
          style: TextStyle(color: colors.primary),
        ),
      ),
      SandboxFailed(:final message) => Padding(
        padding: const EdgeInsets.only(top: 16),
        child: ColoredBox(
          color: colors.errorContainer,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              message,
              style: TextStyle(color: colors.onErrorContainer),
            ),
          ),
        ),
      ),
    };
  }
}
```

- [ ] **Step 7: Write the page**

`apps/fcm_app/lib/ui/sandbox_view.dart`:

```dart
import 'package:flutter/material.dart';

import '../sandbox/sandbox_controller.dart';
import 'sandbox_form.dart';
import 'scenario_picker.dart';
import 'send_result_card.dart';

/// Composes a push and sends it to this device.
///
/// A `ListView` rather than a `Column`, because the form is taller than a phone
/// once a few data rows are added and the keyboard is up.
class SandboxView extends StatelessWidget {
  const SandboxView({required this.controller, super.key});

  final SandboxController controller;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) => ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Presets', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        ScenarioPicker(controller: controller),
        const Divider(height: 32),
        // Keyed on the revision so loading a preset rebuilds the fields from the
        // new draft; typing leaves the revision alone and the cursor with it.
        SandboxForm(
          key: ValueKey(controller.scenarioRevision),
          controller: controller,
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: controller.canSend ? controller.send : null,
          icon: const Icon(Icons.send_outlined),
          label: const Text('Send to this device'),
        ),
        if (controller.sendBlockedReason case final reason?)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              reason,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        SendResultCard(controller.state),
      ],
    ),
  );
}
```

- [ ] **Step 8: Run the test to verify it passes**

Run from `apps/fcm_app`: `fvm flutter test test/sandbox_view_test.dart`
Expected: PASS, 10 tests.

If `find.text('must not be blank')` misses, the label and the error are both
rendered — check the `errorText` is reaching `InputDecoration` rather than
loosening the finder.

- [ ] **Step 9: Check the analyzer and DCM**

Run from the repo root: `fvm dart run melos run analyze && fvm dart run melos run dcm`
Expected: both green. `prefer-single-widget-per-file` is satisfied — each new file
holds one widget class, and `_SandboxFormState`/`_DataRowControllers` are not
widgets.

- [ ] **Step 10: Commit**

```bash
git add apps/fcm_app
git commit -m "feat(app): add the Sandbox page"
```

---

### Task 13: The shell and the drawer

**Files:**
- Create: `apps/fcm_app/lib/ui/app_shell.dart`
- Rename: `apps/fcm_app/lib/ui/inbox_screen.dart` → `apps/fcm_app/lib/ui/inbox_view.dart` (class `InboxScreen` → `InboxView`, loses its `Scaffold` and `AppBar`)
- Modify: `apps/fcm_app/lib/ui/fcm_sample_app.dart`
- Rename: `apps/fcm_app/test/inbox_screen_test.dart` → `apps/fcm_app/test/inbox_view_test.dart`
- Test: `apps/fcm_app/test/app_shell_test.dart`

**Interfaces:**
- Consumes: `PushInbox`, `SandboxController` (Task 11), `SandboxView` (Task 12), `FakeNotificationSender` (Task 11), `FakePushSource` (existing).
- Produces:
  - `class AppShell extends StatefulWidget` — `const AppShell({required PushInbox inbox, required SandboxController sandbox, super.key})`
  - `class InboxView extends StatelessWidget` — `const InboxView({required PushInbox inbox, super.key})`
  - `FcmSampleApp` gains a required `SandboxController sandbox` parameter

- [ ] **Step 1: Write the failing test**

`apps/fcm_app/test/app_shell_test.dart`:

```dart
import 'package:fcm_app/push/push_inbox.dart';
import 'package:fcm_app/sandbox/sandbox_controller.dart';
import 'package:fcm_app/ui/fcm_sample_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_notification_sender.dart';
import 'fake_push_source.dart';

void main() {
  late FakePushSource source;
  late PushInbox inbox;
  late SandboxController sandbox;

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(FcmSampleApp(inbox: inbox, sandbox: sandbox));
    await tester.pumpAndSettle();
  }

  Future<void> openDrawer(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
  }

  int selectedDestination(WidgetTester tester) =>
      tester.widget<IndexedStack>(find.byType(IndexedStack)).index;

  setUp(() {
    source = FakePushSource();
    inbox = PushInbox(source)..listen();
    sandbox = SandboxController(
      sender: FakeNotificationSender(),
      token: () => inbox.token,
    );
  });

  tearDown(() async {
    sandbox.dispose();
    inbox.dispose();
    await source.dispose();
  });

  testWidgets('opens on the inbox', (tester) async {
    await pumpApp(tester);

    expect(find.widgetWithText(AppBar, 'Push inbox'), findsOne);
    expect(selectedDestination(tester), 0);
  });

  testWidgets('offers both destinations in the drawer', (tester) async {
    await pumpApp(tester);

    await openDrawer(tester);

    expect(find.text('Inbox'), findsOne);
    expect(find.text('Sandbox'), findsOne);
  });

  testWidgets('switches to the sandbox and retitles the bar', (tester) async {
    await pumpApp(tester);
    await openDrawer(tester);

    await tester.tap(find.text('Sandbox'));
    await tester.pumpAndSettle();

    expect(selectedDestination(tester), 1);
    expect(find.widgetWithText(AppBar, 'Sandbox'), findsOne);
  });

  testWidgets('closes the drawer once a destination is chosen', (tester) async {
    await pumpApp(tester);
    await openDrawer(tester);

    await tester.tap(find.text('Sandbox'));
    await tester.pumpAndSettle();

    expect(find.byType(NavigationDrawer), findsNothing);
  });

  testWidgets('switches back to the inbox', (tester) async {
    await pumpApp(tester);
    await openDrawer(tester);
    await tester.tap(find.text('Sandbox'));
    await tester.pumpAndSettle();

    await openDrawer(tester);
    await tester.tap(find.text('Inbox'));
    await tester.pumpAndSettle();

    expect(selectedDestination(tester), 0);
    expect(find.widgetWithText(AppBar, 'Push inbox'), findsOne);
  });
}
```

**Note on the assertion:** `IndexedStack` keeps both pages in the tree, so
`find.byType(SandboxView)` would match even while the inbox is showing. The
selected destination is therefore read from the stack's `index`, with the AppBar
title as the corroborating check.

- [ ] **Step 2: Run the test to verify it fails**

Run from `apps/fcm_app`: `fvm flutter test test/app_shell_test.dart`
Expected: FAIL — `FcmSampleApp` has no `sandbox` parameter.

- [ ] **Step 3: Turn `InboxScreen` into `InboxView`**

```bash
git mv apps/fcm_app/lib/ui/inbox_screen.dart apps/fcm_app/lib/ui/inbox_view.dart
```

Then edit `apps/fcm_app/lib/ui/inbox_view.dart` so it is exactly:

```dart
import 'package:flutter/material.dart';

import '../push/push_inbox.dart';
import 'message_tile.dart';
import 'setup_error_banner.dart';

/// Lists every push received this session, newest first.
///
/// A body rather than a page: the `Scaffold` and the `AppBar` belong to
/// `AppShell`, so each destination is one widget with no chrome of its own.
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
            subtitle: Text(token, maxLines: 2, overflow: TextOverflow.ellipsis),
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

- [ ] **Step 4: Write the shell**

`apps/fcm_app/lib/ui/app_shell.dart`:

```dart
import 'package:flutter/material.dart';

import '../push/push_inbox.dart';
import '../sandbox/sandbox_controller.dart';
import 'inbox_view.dart';
import 'sandbox_view.dart';

/// Owns the app's chrome: one `AppBar` whose title follows the drawer's
/// selection, and one body per destination.
///
/// The destinations sit in an `IndexedStack` so both keep their state — the
/// half-filled Sandbox form survives a look at the inbox — and because a
/// `Widget`-returning helper method would break DCM's `avoid-returning-widgets`.
class AppShell extends StatefulWidget {
  const AppShell({required this.inbox, required this.sandbox, super.key});

  final PushInbox inbox;
  final SandboxController sandbox;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  static const _titles = ['Push inbox', 'Sandbox'];

  int _destination = 0;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(_titles[_destination])),
    drawer: NavigationDrawer(
      selectedIndex: _destination,
      onDestinationSelected: _select,
      children: const [
        Padding(
          padding: EdgeInsets.fromLTRB(28, 24, 16, 12),
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
    ),
    body: IndexedStack(
      index: _destination,
      children: [
        InboxView(inbox: widget.inbox),
        SandboxView(controller: widget.sandbox),
      ],
    ),
  );

  void _select(int index) {
    setState(() => _destination = index);
    // Choosing a destination should get the drawer out of the way, which
    // NavigationDrawer does not do on its own.
    Navigator.pop(context);
  }
}
```

`NavigationDrawer.selectedIndex` counts only its `NavigationDrawerDestination`
children, so the header `Padding` does not shift the indices.

- [ ] **Step 5: Thread the controller through the root widget**

`apps/fcm_app/lib/ui/fcm_sample_app.dart`:

```dart
import 'package:flutter/material.dart';

import '../push/push_inbox.dart';
import '../sandbox/sandbox_controller.dart';
import 'app_shell.dart';

/// Root widget. Takes the [PushInbox] and the [SandboxController] as parameters
/// rather than creating them, so widget tests can supply an inbox wired to a fake
/// source and a sandbox wired to a fake sender.
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

- [ ] **Step 6: Move the inbox test with its widget**

```bash
git mv apps/fcm_app/test/inbox_screen_test.dart apps/fcm_app/test/inbox_view_test.dart
```

Then make three edits to `apps/fcm_app/test/inbox_view_test.dart`, leaving every
`testWidgets` body as it is:

1. Add these imports alongside the existing ones:

```dart
import 'package:fcm_app/sandbox/sandbox_controller.dart';

import 'fake_notification_sender.dart';
```

2. Every test assigns `inbox` itself, so the sandbox controller has to be built
   per pump rather than in `setUp`. Replace `pumpApp` with:

```dart
  late SandboxController sandbox;

  Future<void> pumpApp(WidgetTester tester) async {
    sandbox = SandboxController(
      sender: FakeNotificationSender(),
      token: () => inbox.token,
    );
    await tester.pumpWidget(FcmSampleApp(inbox: inbox, sandbox: sandbox));
    await tester.pumpAndSettle();
  }
```

3. Dispose it in `tearDown`, before the inbox:

```dart
  tearDown(() async {
    sandbox.dispose();
    inbox.dispose();
    await source.dispose();
  });
```

The existing assertions still hold: the inbox is the destination on launch, and
its empty state, token tile, banner and rejection counter are all unchanged.

- [ ] **Step 7: Run both suites to verify they pass**

Run from `apps/fcm_app`: `fvm flutter test test/app_shell_test.dart test/inbox_view_test.dart`
Expected: PASS — 5 shell tests and the 5 pre-existing inbox tests.

If the `SandboxView` inside the `IndexedStack` makes the inbox's
`find.text('No pushes received yet.')` ambiguous, the cause is a genuine clash of
copy between the two pages — rename the sandbox's text rather than loosening the
inbox's assertion.

- [ ] **Step 8: Run the whole app suite and the gate**

Run from `apps/fcm_app`: `fvm flutter test`
Expected: PASS, all files.

Run from the repo root: `fvm dart run melos run ci`
Expected: green.

- [ ] **Step 9: Commit**

```bash
git add apps/fcm_app
git commit -m "feat(app): add a drawer over the inbox and the sandbox"
```

---

### Task 14: Wire up `main()`, document it, and close the loop for real

**Files:**
- Modify: `apps/fcm_app/lib/main.dart`
- Modify: `README.md`

**Interfaces:**
- Consumes: everything above.
- Produces: nothing new.

- [ ] **Step 1: Build the sender and the controller in `main()`**

In `apps/fcm_app/lib/main.dart`, add these imports alongside the existing ones
(`package:http/http.dart` goes with the other `package:` imports; the relative
ones follow):

```dart
import 'package:http/http.dart' as http;

import 'sandbox/http_notification_sender.dart';
import 'sandbox/notification_sender.dart';
import 'sandbox/sandbox_controller.dart';
import 'sandbox/unavailable_notification_sender.dart';
```

Replace the last line of `main()` — `runApp(FcmSampleApp(inbox: inbox));` — with:

```dart
  final sandbox = SandboxController(
    sender: _buildSender(setupError),
    // The sandbox asks for a token rather than holding the inbox, so it knows
    // nothing about the receiving side.
    token: () => inbox.token,
  );

  runApp(FcmSampleApp(inbox: inbox, sandbox: sandbox));
```

And add this top-level function below `main()`:

```dart
/// The sender the Sandbox will use.
///
/// When Firebase did not start there will never be a registration token, so
/// there is nowhere to send: the reason travels into the UI instead of the page
/// offering a button that cannot work. This mirrors `DisabledPushSource` on the
/// receiving side.
NotificationSender _buildSender(String? setupError) {
  if (setupError case final error?) {
    return UnavailableNotificationSender(error);
  }

  return HttpNotificationSender(
    client: http.Client(),
    baseUrl: Uri.parse(defaultApiBaseUrl),
  );
}
```

- [ ] **Step 2: Verify the app still builds and the gate is green**

Run from the repo root: `fvm dart run melos run ci`
Expected: green.

Run from `apps/fcm_app`: `fvm flutter build web --release`
Expected: succeeds. (Web cannot receive FCM pushes without a VAPID key, so this
is a compile check, not a functional one.)

- [ ] **Step 3: Document it in the root README**

Four edits.

**a.** In `## Layout`, the tree becomes:

```
.
├── .fvmrc                      Flutter SDK pin (3.44.8)
├── pubspec.yaml                pub workspace root + melos config
├── analysis_options.yaml       shared analyzer, linter and DCM rules
├── apps/fcm_app/               Flutter app (Android, iOS, web)
├── apps/fcm_api/               local HTTP server that sends pushes through FCM
├── packages/core/              pure Dart: push payload model + parser
└── packages/fcm_gallery_shared/ pure Dart: the contract the app and API share
```

**b.** After the existing paragraph about `packages/core`, add:

```markdown
`packages/fcm_gallery_shared` holds what the two sides must agree on: the
editable draft, the gallery presets, the request and response DTOs, and the one
validator both of them run. It depends on `core` for
`PushMessageParser.reservedKeys`, so the payload keys the app requires are
defined once and a data key that would collide with them fails to compile past
the validator rather than at delivery time.

`apps/fcm_api` is a plain `shelf` server, not a Cloud Function: `dart run` and
`curl` are the whole story, and the interesting logic — the FCM v1 payload and
the status mapping — is pure and unit-tested without a credential.
```

**c.** In `## Scripts`, add a row after `melos run fix`:

```markdown
| `melos run api:serve` | run the send API on `127.0.0.1:8080` |
```

**d.** Add this section between `## Message format` and `## Verified on this
machine`:

````markdown
## Sending a test push

The Sandbox page (drawer → Sandbox) composes a payload and sends it to the
device the app is running on, through `apps/fcm_api`.

**One-time:** download a service account key from the
[Firebase console](https://console.firebase.google.com/project/fcm-sandbox-770fa/settings/serviceaccounts/adminsdk)
(**Generate new private key**) and save it outside the repo, e.g.
`~/.config/fcm-sandbox-service-account.json`. It grants send rights on the whole
project, so it is not committed — `*service-account*.json` is gitignored as a
second line of defence.

Run the API:

```bash
GOOGLE_APPLICATION_CREDENTIALS=~/.config/fcm-sandbox-service-account.json \
  fvm dart run melos run api:serve
```

It listens on `127.0.0.1:8080` and takes `FCM_PROJECT_ID` and `PORT` as optional
overrides. Check it with `curl -s http://127.0.0.1:8080/health`.

The app defaults to `http://localhost:8080`, which needs one of:

| Target | What makes `localhost` resolve |
| --- | --- |
| Physical Android device | `adb reverse tcp:8080 tcp:8080` |
| Android emulator | `--dart-define=FCM_API_BASE_URL=http://10.0.2.2:8080` |
| Anything else | `--dart-define=FCM_API_BASE_URL=http://<host>:8080` |

Sending by hand instead:

```bash
curl -X POST http://127.0.0.1:8080/send \
  -H 'content-type: application/json' \
  -d '{"token":"<registration token from the Inbox page>",
       "title":"Build finished",
       "body":"Release 1.0.0 is ready.",
       "data":{"deepLink":"/builds/42"}}'
```

The response's `id` is the payload's `id`, so it is the value that then appears
in the inbox — that is how a send is matched to an arrival. `id` and `sentAt` are
stamped by the server, and a data key colliding with one of the four reserved
keys is rejected with a 400.

**The API is a development tool.** It has no authentication and binds loopback,
so only the machine running it can reach it. Do not deploy it as is — bound to
`0.0.0.0` it is an open relay to any token an attacker already holds.
````

**e.** Update `## Verified on this machine` to state what was actually run —
use the real test counts from `melos run ci`, and describe the end-to-end result
from Step 4 honestly, including "not verified" if no device was available.

- [ ] **Step 4: Verify the loop end to end on a device**

1. Start the API as documented above.
2. `adb reverse tcp:8080 tcp:8080`
3. `cd apps/fcm_app && fvm flutter run` on the connected device.
4. On the Inbox page, confirm a registration token is shown. (If it is not, the
   Sandbox will say why Send is disabled.)
5. Drawer → Sandbox. Tap **Build finished**, then **Send to this device**.
6. Note the `id` in the `✓ Sent` line.
7. Go back to Inbox.

Expected: the push arrives and appears in the inbox with the **same id** as the
one the Sandbox reported, its `data:` line naming `event` and `buildNumber`.

Also check two failure paths, because they are the ones that will actually be hit:

- Clear the Title and confirm Send is disabled with `must not be blank` under the
  field — no request is made.
- Stop the API and press Send: the error card names the base URL and mentions
  `adb reverse`.

If no Android device is available, **say so** in the README and in the final
report rather than implying this step passed. Everything else in this plan is
verified without one.

- [ ] **Step 5: Commit**

```bash
git add README.md apps/fcm_app
git commit -m "feat(app): wire the sandbox into main and document the API"
```

---

## Verification summary

The work is done when all of these hold:

- [ ] `fvm dart run melos run ci` is green, covering four packages
- [ ] `GET /health` answers `{"status":"ok"}`
- [ ] `POST /send` with a bogus token answers a mapped 404 (or 400) with readable
      prose — the evidence that OAuth against FCM succeeded, since an FCM-level
      rejection is unreachable without a valid access token
- [ ] `POST /send` with a blank title answers
      `{"error":"title must not be blank","field":"title"}`
- [ ] `fvm flutter build web --release` succeeds
- [ ] On a real Android device: a Sandbox send arrives in the Inbox with the same
      `id` the Sandbox reported — or is reported as unverified, with the reason

## Notes for the implementer

- **Do not add authentication, a non-loopback binding, silent pushes or priority
  controls.** They are named out of scope in the spec; a "while I'm here" addition
  here changes the security posture the README documents.
- **The `data` map's four reserved keys are load-bearing.**
  `PushMessageParser` reads `id`, `title`, `body` and `sentAt` out of `data`, not
  out of the `notification` block. A payload that only sets `notification` will
  deliver and then be counted as a malformed rejection in the inbox.
- **If `melos run ci` fails on formatting**, run `fvm dart run melos run format`
  rather than hand-wrapping — every code block in this plan is written at
  `dart format`'s 80-column default, but a paste can still drift.
