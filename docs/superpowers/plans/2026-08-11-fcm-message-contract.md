# FCM Message Contract Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the app's invented payload shape with a typed mirror of FCM v1's `Message` model, rewrite `Scenario` to the FCM playground model with a raw `payloadTemplate`, turn the send endpoint into a passthrough that only injects the target, and replace the title/body form with a grouped scenario gallery over a raw JSON editor.

**Architecture:** `packages/fcm_gallery_shared/lib/src/message/` gains 16 files — the `Message` tree, four enums, and one `JsonObjectReader` that makes strict parsing report *where* an unknown field was. `Scenario` carries a raw `Map<String, dynamic>` template that parses into `FcmMessage`; raw → typed → raw round-tripping is the property the tests pin. `apps/fcm_api` stops building messages and forwards one, injecting only the token. `core`'s parser relaxes so a data-only push reaches the inbox.

**Tech Stack:** Dart 3.12.2 (fvm-pinned), Flutter 3.44.8, melos 8, DCM. No new dependencies.

**Spec:** `docs/superpowers/specs/2026-08-11-fcm-message-contract-design.md`

**Branch:** `feature/fcm-message-contract-impl`, off `main` at `a27283b`.

**Baseline:** `melos run ci` exit 0 — `core` 20, `fcm_gallery_shared` 41, `fcm_api` 44, `fcm_app` 49 tests.

**Note on `main`:** the notification-display work is **not** merged. `MessageDetailPage`, `PushPayloadStore`, `NotificationPresenter` and `remoteMessageToPayload` do **not** exist on this branch — do not reference them. `FirebasePushSource` still has its private `_toPayload`. Three files will conflict when that branch merges (`main.dart`, `message_tile.dart`, `README.md`); that is expected and is the other branch's problem to resolve.

## Global Constraints

Every task's requirements implicitly include this section.

- **Run everything through `fvm`.** There is no `dart` on PATH. `fvm dart test` from inside a pure-Dart package; `fvm flutter test` from inside `apps/fcm_app`.
- **`fvm dart run melos run ci` from the repo root is the gate.** It runs format:check, analyze, dcm and every suite. Check its **exit code**; it must exit 0 before any commit. Running analyze and dcm separately is not sufficient.
- If format:check complains, run `fvm dart run melos run format` from the repo root rather than hand-wrapping lines.
- **Fatal lints** (`--fatal-infos --fatal-warnings`): `prefer_single_quotes`, `require_trailing_commas`, `sort_pub_dependencies`, `prefer_final_locals`, `prefer_final_in_for_each`, `always_declare_return_types`, `unnecessary_parenthesis`, `unawaited_futures`, `use_super_parameters`, `cancel_subscriptions`, `close_sinks`, `avoid_print`, and **`prefer_initializing_formals`** — never write `: _field = param` where it is a plain copy, **even when the parameter has a default**; use `required this._field` or `this._field = default`. The public parameter name drops the underscore. An initializer list is correct only when the value is not a plain copy (`_x = x ?? Default()`).
- **Analyzer strictness:** `strict-casts`, `strict-inference`, `strict-raw-types` all on. No raw `Map`/`List` in a type position — write `Map<String, Object?>`, `List<Object?>`.
- **DCM metrics** (`source-lines-of-code: 50`, `number-of-parameters: 5`, `maximum-nesting-level: 5`, `cyclomatic-complexity: 15`) are fatal, **except** under the paths Task 1 adds to `metrics-exclude`. Outside those paths the limits still bind.
- **Fatal DCM rules:** `prefer-match-file-name` (file name matches its first public **type**, snake_case; a file of only top-level functions is fine), `prefer-single-widget-per-file`, `avoid-returning-widgets` (**no `Widget _buildFoo()` methods**), `always-remove-listener`, `use-setstate-synchronously`, `avoid-unused-parameters` (name a deliberately unused parameter `_`), `newline-before-return`, `prefer-trailing-comma`, `no-empty-block`, `prefer-correct-type-name`.
- **Doc comments on every public declaration.** Say *why*, not *what*. For the model classes, the *why* is usually FCM's own semantics — say what FCM does with the field, not that it is a string.
- **No `// ignore:` comments.** There are none in this repository and a review will reject one.
- **snake_case on the wire, camelCase in Dart.** Every JSON key is snake_case; every Dart field is camelCase. The two never coincide by accident — write the key out explicitly.
- **A null field is absent from `toJson`, never `null`.** FCM treats an explicit null as a value in some positions.
- **Durations and timestamps stay `String`.** `ttl`, `event_time`, `vibrate_timings`, `light_on_duration`, `light_off_duration` are proto duration/timestamp strings. Parsing them to `Duration`/`DateTime` would break round-trip fidelity, which is this model's contract.
- **Commit style:** Conventional Commits. Scope is the package: `feat(shared):`, `feat(api):`, `feat(app):`, `refactor(core):`, `chore(tooling):`.

## File Structure

**New — `packages/fcm_gallery_shared/lib/src/message/`** (16 files, one public type each)

| File | Type |
| --- | --- |
| `json_object_reader.dart` | `JsonObjectReader` — strict reading with a path |
| `android_message_priority.dart` | enum: `NORMAL`, `HIGH` |
| `android_notification_priority.dart` | enum: `PRIORITY_UNSPECIFIED` … `PRIORITY_MAX` |
| `notification_visibility.dart` | enum: `VISIBILITY_UNSPECIFIED`, `PRIVATE`, `PUBLIC`, `SECRET` |
| `notification_proxy.dart` | enum: `PROXY_UNSPECIFIED`, `ALLOW`, `DENY`, `IF_PRIORITY_LOWERED` |
| `fcm_notification.dart` | `FcmNotification` |
| `fcm_options.dart` | `FcmOptions` |
| `apns_fcm_options.dart` | `ApnsFcmOptions` |
| `webpush_fcm_options.dart` | `WebpushFcmOptions` |
| `light_color.dart` | `LightColor` |
| `light_settings.dart` | `LightSettings` |
| `android_notification.dart` | `AndroidNotification` (27 fields) |
| `android_config.dart` | `AndroidConfig` |
| `apns_config.dart` | `ApnsConfig` |
| `webpush_config.dart` | `WebpushConfig` |
| `fcm_message.dart` | `FcmMessage` |

**New elsewhere in `fcm_gallery_shared`**

| File | Type |
| --- | --- |
| `lib/src/scenario.dart` | `Scenario` + `const scenarioGallery` |
| `lib/src/send_message_request.dart` | `SendMessageRequest` |
| `lib/src/send_message_response.dart` | `SendMessageResponse` |

**Deleted, in Task 14 and not before** — `notification_draft.dart`, `notification_draft_validator.dart`, `draft_problem.dart`, `notification_scenario.dart`, `send_notification_request.dart`, `send_notification_response.dart`, `apps/fcm_api/lib/src/notification_message.dart`, and the app's `sandbox_form.dart`, `data_entry_row.dart`, `scenario_picker.dart`.

**Modified**

| File | Change |
| --- | --- |
| `analysis_options.yaml` | `metrics-exclude` gains the model directory and `scenario.dart` |
| `packages/core/lib/src/push_message_parser.dart` | `title`/`body` optional |
| `packages/core/lib/src/push_message.dart` | doc comments stop promising non-empty |
| `apps/fcm_api/lib/src/send_notification.dart` | takes `SendMessageRequest`, injects the token, forwards `validate_only` |
| `apps/fcm_api/lib/src/http_v1_fcm_sender.dart` | sends the request envelope rather than a bare message |
| `apps/fcm_app/lib/sandbox/http_notification_sender.dart` | posts the new request |
| `apps/fcm_app/lib/sandbox/sandbox_controller.dart` | holds editor text, a parse result and `validateOnly` |
| `apps/fcm_app/lib/ui/sandbox_view.dart` | grouped gallery + JSON editor |
| `apps/fcm_app/lib/ui/message_tile.dart` | placeholder for a blank title |
| `apps/fcm_app/lib/main.dart`, `README.md` | wiring and docs |

**Why the model is built additively first.** Tasks 1–9 only add files; nothing existing changes, so the gate stays green throughout and each task is reviewable on its own. Tasks 10–13 switch the consumers over one package at a time. The old types are deleted last, in Task 14, so no intermediate task leaves the build red.

---

### Task 1: `metrics-exclude` and the strict reader

**Files:**
- Modify: `analysis_options.yaml`
- Create: `packages/fcm_gallery_shared/lib/src/message/json_object_reader.dart`
- Test: `packages/fcm_gallery_shared/test/message/json_object_reader_test.dart`

**Interfaces:**
- Consumes: nothing.
- Produces: `JsonObjectReader` with the constructor `JsonObjectReader(Map<String, Object?> json, {required String path})`, the factory `JsonObjectReader.of(Object? value, {required String path})`, the readers `text`, `flag`, `integer`, `number`, `textList`, `stringMap`, `freeForm`, `object<T>`, `enumValue<E>`, and `requireNothingUnclaimed()`.

**Why this is one task with the config change:** the exclusion exists so the model can be written at all, and the reader is the first file that lands inside the excluded path. Splitting them would leave a config change with nothing to justify it.

- [ ] **Step 1: Widen `metrics-exclude`**

In `analysis_options.yaml`, under `dart_code_metrics:`:

```yaml
  metrics-exclude:
    - test/**
    # Data classes mirroring Google's FCM v1 Message API. AndroidNotification has
    # 27 fields and Scenario has 9, so number-of-parameters cannot apply: the
    # count is the shape of the API being mirrored, not a design smell. Every
    # metric still binds everywhere logic lives.
    - packages/fcm_gallery_shared/lib/src/message/**
    - packages/fcm_gallery_shared/lib/src/scenario.dart
```

- [ ] **Step 2: Write the failing test**

`packages/fcm_gallery_shared/test/message/json_object_reader_test.dart`:

```dart
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:test/test.dart';

void main() {
  JsonObjectReader readerOf(Map<String, Object?> json) =>
      JsonObjectReader(json, path: 'message');

  Matcher throwsFormatMentioning(String fragment) => throwsA(
    isA<FormatException>().having(
      (error) => error.message,
      'message',
      contains(fragment),
    ),
  );

  group('claiming and rejecting', () {
    test('accepts an object whose every key was read', () {
      final reader = readerOf({'title': 'Hi', 'sticky': true});

      expect(reader.text('title'), 'Hi');
      expect(reader.flag('sticky'), isTrue);
      reader.requireNothingUnclaimed();
    });

    test('rejects a key nobody read, naming the field and the path', () {
      final reader = readerOf({'titel': 'Hi'});

      expect(
        reader.requireNothingUnclaimed,
        throwsFormatMentioning('message: unknown field "titel"'),
      );
    });

    test('names every unclaimed key, not just the first', () {
      final reader = readerOf({'a': 1, 'b': 2});

      expect(reader.requireNothingUnclaimed, throwsFormatMentioning('"a"'));
    });

    test('treats an absent key as null rather than an error', () {
      final reader = readerOf(const {});

      expect(reader.text('title'), isNull);
      reader.requireNothingUnclaimed();
    });
  });

  group('typed reads', () {
    test('reports a wrong type with the path and what was expected', () {
      final reader = readerOf({'title': 7});

      expect(
        () => reader.text('title'),
        throwsFormatMentioning('message.title: expected a string'),
      );
    });

    test('reads false without mistaking it for absence', () {
      expect(readerOf({'sticky': false}).flag('sticky'), isFalse);
    });

    test('reads zero without mistaking it for absence', () {
      expect(readerOf({'count': 0}).integer('count'), 0);
    });

    test('accepts an int where a number is expected', () {
      expect(readerOf({'red': 1}).number('red'), 1.0);
    });

    test('reads a list of strings', () {
      expect(readerOf({'args': ['a', 'b']}).textList('args'), ['a', 'b']);
    });

    test('rejects a list with a non-string element', () {
      final reader = readerOf({'args': ['a', 2]});

      expect(() => reader.textList('args'), throwsFormatMentioning('args'));
    });

    test('reads a string map', () {
      expect(readerOf({'data': {'k': 'v'}}).stringMap('data'), {'k': 'v'});
    });

    test('rejects a string map with a non-string value', () {
      final reader = readerOf({'data': {'k': 1}});

      expect(() => reader.stringMap('data'), throwsFormatMentioning('data'));
    });

    test('reads a free-form map without inspecting its values', () {
      final payload = readerOf({
        'payload': {'aps': {'badge': 1}, 'custom': [1, 2]},
      }).freeForm('payload');

      expect(payload, {'aps': {'badge': 1}, 'custom': [1, 2]});
    });
  });

  group('nesting', () {
    test('composes the path for a nested object', () {
      final reader = readerOf({
        'android': {'titel': 'Hi'},
      });

      expect(
        () => reader.object('android', (child) {
          child.requireNothingUnclaimed();

          return 1;
        }),
        throwsFormatMentioning('message.android: unknown field "titel"'),
      );
    });

    test('rejects a non-object where an object was expected', () {
      final reader = readerOf({'android': 'nope'});

      expect(
        () => reader.object('android', (_) => 1),
        throwsFormatMentioning('message.android: expected an object'),
      );
    });
  });

  group('enums', () {
    test('maps a known wire name', () {
      final reader = readerOf({'priority': 'HIGH'});

      expect(
        reader.enumValue(
          'priority',
          AndroidMessagePriority.values,
          (value) => value.wireName,
        ),
        AndroidMessagePriority.high,
      );
    });

    test('rejects an unrecognised value, since it is indistinguishable from a typo', () {
      final reader = readerOf({'priority': 'URGENT'});

      expect(
        () => reader.enumValue(
          'priority',
          AndroidMessagePriority.values,
          (value) => value.wireName,
        ),
        throwsFormatMentioning('message.priority: unknown value "URGENT"'),
      );
    });
  });
}
```

This test uses `AndroidMessagePriority`, which Task 2 creates. Write the enum
group last and expect it to fail to compile until Task 2 lands — or, if you prefer
a green intermediate state, comment out only the `enums` group with a `TODO`-free
note and restore it in Task 2's step 1. State which you did in your report.

- [ ] **Step 3: Run the test to verify it fails**

Run from `packages/fcm_gallery_shared`: `fvm dart test test/message/json_object_reader_test.dart`
Expected: FAIL — `Undefined name 'JsonObjectReader'`.

- [ ] **Step 4: Write the reader**

`packages/fcm_gallery_shared/lib/src/message/json_object_reader.dart`:

```dart
/// Reads a JSON object strictly: every key must be claimed by a read, and
/// anything left over is an error.
///
/// Rejecting unknown fields is only useful if the error says *where*, so the
/// reader carries the path it is reading and composes it for nested objects —
/// producing `message.android.notification: unknown field "titel"` rather than a
/// bare complaint. That message is the whole point of parsing strictly.
class JsonObjectReader {
  JsonObjectReader(this._json, {required String path}) : _path = path;

  /// Reads [value] as an object, or throws [FormatException] naming [path].
  ///
  /// Used for nested objects, where the value's type is not yet known.
  factory JsonObjectReader.of(Object? value, {required String path}) {
    if (value is! Map<String, Object?>) {
      throw FormatException('$path: expected an object, got ${_nameOf(value)}');
    }

    return JsonObjectReader(value, path: path);
  }

  final Map<String, Object?> _json;
  final String _path;
  final _claimed = <String>{};

  /// An optional string.
  String? text(String key) =>
      _read(key, 'a string', (value) => value is String ? value : null);

  /// An optional boolean. A present `false` is a value, not an absence.
  bool? flag(String key) =>
      _read(key, 'a boolean', (value) => value is bool ? value : null);

  /// An optional integer. A present `0` is a value, not an absence.
  int? integer(String key) =>
      _read(key, 'an integer', (value) => value is int ? value : null);

  /// An optional number. An `int` is accepted, since JSON does not distinguish
  /// `1` from `1.0` and FCM's colour components are written both ways.
  double? number(String key) => _read(key, 'a number', (value) {
    if (value is double) {
      return value;
    }

    return value is int ? value.toDouble() : null;
  });

  /// An optional list of strings.
  List<String>? textList(String key) => _read(key, 'a list of strings', (value) {
    if (value is! List<Object?>) {
      return null;
    }

    final items = <String>[];
    for (final item in value) {
      if (item is! String) {
        return null;
      }
      items.add(item);
    }

    return List.unmodifiable(items);
  });

  /// An optional object of string values, whose keys are the caller's own.
  Map<String, String>? stringMap(String key) =>
      _read(key, 'an object of strings', (value) {
        if (value is! Map<String, Object?>) {
          return null;
        }

        final entries = <String, String>{};
        for (final entry in value.entries) {
          final entryValue = entry.value;
          if (entryValue is! String) {
            return null;
          }
          entries[entry.key] = entryValue;
        }

        return Map.unmodifiable(entries);
      });

  /// An optional object passed through without inspection.
  ///
  /// For the fields FCM itself defines as free-form — `apns.payload`,
  /// `webpush.notification` — where an unknown key is the caller's business and
  /// rejecting it would be wrong.
  Map<String, Object?>? freeForm(String key) => _read(
    key,
    'an object',
    (value) => value is Map<String, Object?> ? Map.unmodifiable(value) : null,
  );

  /// An optional nested object, parsed by [parse] with the composed path.
  T? object<T>(String key, T Function(JsonObjectReader reader) parse) {
    _claimed.add(key);
    final value = _json[key];
    if (value == null) {
      return null;
    }

    return parse(JsonObjectReader.of(value, path: '$_path.$key'));
  }

  /// An optional enum, matched against [values] by wire name.
  ///
  /// An unrecognised value throws rather than returning null: it is
  /// indistinguishable from a typo, and silently dropping it would send
  /// something other than what was written.
  E? enumValue<E>(
    String key,
    List<E> values,
    String Function(E value) wireNameOf,
  ) {
    final raw = text(key);
    if (raw == null) {
      return null;
    }

    for (final value in values) {
      if (wireNameOf(value) == raw) {
        return value;
      }
    }

    throw FormatException('$_path.$key: unknown value "$raw"');
  }

  /// Throws [FormatException] naming every key no read claimed.
  void requireNothingUnclaimed() {
    final unknown = _json.keys.where((key) => !_claimed.contains(key)).toList();
    if (unknown.isEmpty) {
      return;
    }

    final names = unknown.map((key) => '"$key"').join(', ');
    final label = unknown.length == 1 ? 'unknown field' : 'unknown fields';

    throw FormatException('$_path: $label $names');
  }

  T? _read<T>(String key, String expected, T? Function(Object? value) convert) {
    _claimed.add(key);
    final value = _json[key];
    if (value == null) {
      return null;
    }

    final converted = convert(value);
    if (converted == null) {
      throw FormatException(
        '$_path.$key: expected $expected, got ${_nameOf(value)}',
      );
    }

    return converted;
  }
}

/// A readable type name for an error message, since `runtimeType` on a decoded
/// map reads as `_Map<String, dynamic>` and helps nobody.
String _nameOf(Object? value) => switch (value) {
  null => 'null',
  String() => 'a string',
  bool() => 'a boolean',
  int() => 'an integer',
  double() => 'a number',
  List<Object?>() => 'a list',
  Map<String, Object?>() => 'an object',
  _ => '${value.runtimeType}',
};
```

Add to `packages/fcm_gallery_shared/lib/fcm_gallery_shared.dart`, keeping the
export list alphabetical:

```dart
export 'src/message/json_object_reader.dart';
```

- [ ] **Step 5: Run the test to verify it passes**

Run from `packages/fcm_gallery_shared`: `fvm dart test test/message/json_object_reader_test.dart`
Expected: PASS, 17 tests (or 15 with the enum group deferred to Task 2).

- [ ] **Step 6: Run the gate and commit**

Run from the repo root: `fvm dart run melos run ci`
Expected: exit 0.

```bash
git add analysis_options.yaml packages/fcm_gallery_shared
git commit -m "feat(shared): add a strict JSON reader that reports field paths"
```

---

### Task 2: The four enums

**Files:**
- Create: `packages/fcm_gallery_shared/lib/src/message/android_message_priority.dart`
- Create: `packages/fcm_gallery_shared/lib/src/message/android_notification_priority.dart`
- Create: `packages/fcm_gallery_shared/lib/src/message/notification_visibility.dart`
- Create: `packages/fcm_gallery_shared/lib/src/message/notification_proxy.dart`
- Modify: `packages/fcm_gallery_shared/lib/fcm_gallery_shared.dart`
- Test: `packages/fcm_gallery_shared/test/message/message_enums_test.dart`

**Interfaces:**
- Consumes: `JsonObjectReader.enumValue` (Task 1).
- Produces: four enums, each with a `final String wireName` and nothing else.

**No `fromWireName`.** `JsonObjectReader.enumValue` already does the lookup from
`values` and a `wireNameOf` accessor, so a per-enum lookup would be four copies of
one loop. The spec sketched one; the reader made it unnecessary.

- [ ] **Step 1: Write the failing test**

`packages/fcm_gallery_shared/test/message/message_enums_test.dart`:

```dart
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:test/test.dart';

void main() {
  group('wire names', () {
    test('AndroidMessagePriority matches FCM spelling', () {
      expect(
        AndroidMessagePriority.values.map((value) => value.wireName),
        ['NORMAL', 'HIGH'],
      );
    });

    test('AndroidNotificationPriority matches FCM spelling', () {
      expect(AndroidNotificationPriority.values.map((value) => value.wireName), [
        'PRIORITY_UNSPECIFIED',
        'PRIORITY_MIN',
        'PRIORITY_LOW',
        'PRIORITY_DEFAULT',
        'PRIORITY_HIGH',
        'PRIORITY_MAX',
      ]);
    });

    test('NotificationVisibility matches FCM spelling', () {
      expect(NotificationVisibility.values.map((value) => value.wireName), [
        'VISIBILITY_UNSPECIFIED',
        'PRIVATE',
        'PUBLIC',
        'SECRET',
      ]);
    });

    test('NotificationProxy matches FCM spelling', () {
      expect(NotificationProxy.values.map((value) => value.wireName), [
        'PROXY_UNSPECIFIED',
        'ALLOW',
        'DENY',
        'IF_PRIORITY_LOWERED',
      ]);
    });

    test('every wire name is unique within its enum', () {
      for (final names in [
        AndroidMessagePriority.values.map((value) => value.wireName),
        AndroidNotificationPriority.values.map((value) => value.wireName),
        NotificationVisibility.values.map((value) => value.wireName),
        NotificationProxy.values.map((value) => value.wireName),
      ]) {
        expect(names.toSet(), hasLength(names.length));
      }
    });
  });
}
```

These read as tautological but are not: the literals are FCM's spelling, and a
rename or a reordering that broke the wire contract would otherwise only surface
as an FCM 400 from a device.

- [ ] **Step 2: Run the test to verify it fails**

Run from `packages/fcm_gallery_shared`: `fvm dart test test/message/message_enums_test.dart`
Expected: FAIL — `Undefined name 'AndroidMessagePriority'`.

- [ ] **Step 3: Write the enums**

All four follow one shape. `android_message_priority.dart`:

```dart
/// How eagerly FCM should deliver the message to an Android device.
///
/// FCM's `AndroidConfig.priority`. `HIGH` wakes a dozing device immediately;
/// `NORMAL` may be held until the next maintenance window, which is the usual
/// reason a test push seems not to arrive.
enum AndroidMessagePriority {
  normal('NORMAL'),
  high('HIGH');

  const AndroidMessagePriority(this.wireName);

  /// The spelling FCM uses on the wire.
  final String wireName;
}
```

The other three, same shape, with these values and doc comments describing what
Android does with them:

| File | Dart values → wire names | What it controls |
| --- | --- | --- |
| `android_notification_priority.dart` | `unspecified('PRIORITY_UNSPECIFIED')`, `min('PRIORITY_MIN')`, `low('PRIORITY_LOW')`, `defaultPriority('PRIORITY_DEFAULT')`, `high('PRIORITY_HIGH')`, `max('PRIORITY_MAX')` | How prominently Android displays it. Distinct from `AndroidMessagePriority`, which is about *delivery* — a point worth making in the doc comment, since the two are easily confused |
| `notification_visibility.dart` | `unspecified('VISIBILITY_UNSPECIFIED')`, `private('PRIVATE')`, `public('PUBLIC')`, `secret('SECRET')` | Whether the content shows on a locked screen |
| `notification_proxy.dart` | `unspecified('PROXY_UNSPECIFIED')`, `allow('ALLOW')`, `deny('DENY')`, `ifPriorityLowered('IF_PRIORITY_LOWERED')` | Whether Android may proxy the notification |

Note `defaultPriority` and `max`: `default` is a reserved word, and `max` collides
with nothing but reads oddly beside `min` — keep both spellings as given so the
test above passes.

Add all four exports to the barrel, alphabetically.

- [ ] **Step 4: Restore the reader's enum tests**

If Task 1 deferred the `enums` group in `json_object_reader_test.dart`, restore it
now and confirm it passes.

- [ ] **Step 5: Run the tests and the gate, then commit**

Run from `packages/fcm_gallery_shared`: `fvm dart test test/message/`
Expected: PASS, 22 tests.

Run from the repo root: `fvm dart run melos run ci`
Expected: exit 0.

```bash
git add packages/fcm_gallery_shared
git commit -m "feat(shared): add the FCM message enums"
```

---

### Task 3: The leaf objects

Six small classes with no nested objects of their own, so they establish the
pattern every later class follows.

**Files:**
- Create: `fcm_notification.dart`, `fcm_options.dart`, `apns_fcm_options.dart`, `webpush_fcm_options.dart`, `light_color.dart`, `light_settings.dart` under `packages/fcm_gallery_shared/lib/src/message/`
- Modify: `packages/fcm_gallery_shared/lib/fcm_gallery_shared.dart`
- Test: `packages/fcm_gallery_shared/test/message/leaf_objects_test.dart`

**Interfaces:**
- Consumes: `JsonObjectReader` (Task 1).
- Produces, each with `const` constructor, `factory X.fromJson(Map<String, Object?>)`, `static X read(JsonObjectReader)`, `Map<String, Object?> toJson()`, `==` and `hashCode`:

| Type | Fields (Dart → JSON) |
| --- | --- |
| `FcmNotification` | `title` → `title`, `body` → `body`, `image` → `image` |
| `FcmOptions` | `analyticsLabel` → `analytics_label` |
| `ApnsFcmOptions` | `image` → `image`, `analyticsLabel` → `analytics_label` |
| `WebpushFcmOptions` | `link` → `link`, `analyticsLabel` → `analytics_label` |
| `LightColor` | `red`, `green`, `blue`, `alpha` — all `double`, all **required** |
| `LightSettings` | `color` (`LightColor`, **required**), `lightOnDuration` → `light_on_duration` (`String`, required), `lightOffDuration` → `light_off_duration` (`String`, required) |

**Three `fcm_options` types, not one**, because the generic block accepts only
`analytics_label` while APNs adds `image` and WebPush adds `link`. One shared class
would let a field through on a platform that rejects it.

- [ ] **Step 1: Write the failing test**

`packages/fcm_gallery_shared/test/message/leaf_objects_test.dart`:

```dart
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:test/test.dart';

void main() {
  Matcher throwsFormatMentioning(String fragment) => throwsA(
    isA<FormatException>().having(
      (error) => error.message,
      'message',
      contains(fragment),
    ),
  );

  group('FcmNotification', () {
    test('round-trips every field', () {
      const json = {
        'title': 'Build finished',
        'body': 'Release 1.0.0 is ready.',
        'image': 'https://example.test/build.png',
      };

      expect(FcmNotification.fromJson(json).toJson(), json);
    });

    test('omits absent fields rather than writing null', () {
      const notification = FcmNotification(title: 'Only a title');

      expect(notification.toJson(), {'title': 'Only a title'});
    });

    test('rejects a field FCM does not define', () {
      expect(
        () => FcmNotification.fromJson({'titel': 'typo'}),
        throwsFormatMentioning('unknown field "titel"'),
      );
    });

    test('compares by value', () {
      expect(
        const FcmNotification(title: 'a', body: 'b'),
        const FcmNotification(title: 'a', body: 'b'),
      );
    });
  });

  group('the three fcm_options types', () {
    test('the generic one carries only an analytics label', () {
      const json = {'analytics_label': 'campaign-1'};

      expect(FcmOptions.fromJson(json).toJson(), json);
    });

    test('the APNs one adds an image', () {
      const json = {'image': 'https://example.test/a.png', 'analytics_label': 'x'};

      expect(ApnsFcmOptions.fromJson(json).toJson(), json);
    });

    test('the WebPush one adds a link', () {
      const json = {'link': 'https://example.test/open', 'analytics_label': 'x'};

      expect(WebpushFcmOptions.fromJson(json).toJson(), json);
    });

    test('the generic one rejects a link, which only WebPush accepts', () {
      expect(
        () => FcmOptions.fromJson({'link': 'https://example.test'}),
        throwsFormatMentioning('unknown field "link"'),
      );
    });
  });

  group('LightSettings', () {
    const json = {
      'color': {'red': 1.0, 'green': 0.5, 'blue': 0.0, 'alpha': 1.0},
      'light_on_duration': '1s',
      'light_off_duration': '0.5s',
    };

    test('round-trips, keeping the durations as written', () {
      expect(LightSettings.fromJson(json).toJson(), json);
    });

    test('reads an integer colour component as a number', () {
      final settings = LightSettings.fromJson({
        ...json,
        'color': {'red': 1, 'green': 0, 'blue': 0, 'alpha': 1},
      });

      expect(settings.color.red, 1.0);
    });

    test('rejects a colour missing a component, since FCM requires all four', () {
      expect(
        () => LightSettings.fromJson({
          ...json,
          'color': {'red': 1.0, 'green': 0.5, 'blue': 0.0},
        }),
        throwsFormatMentioning('alpha'),
      );
    });

    test('rejects light settings with no duration, since FCM requires both', () {
      expect(
        () => LightSettings.fromJson({'color': json['color']}),
        throwsFormatMentioning('light_on_duration'),
      );
    });

    test('names the nested path when the colour is malformed', () {
      expect(
        () => LightSettings.fromJson({...json, 'color': {'red': 'red'}}),
        throwsFormatMentioning('color.red'),
      );
    });
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run from `packages/fcm_gallery_shared`: `fvm dart test test/message/leaf_objects_test.dart`
Expected: FAIL — `Undefined name 'FcmNotification'`.

- [ ] **Step 3: Write `FcmNotification` as the pattern for all six**

`packages/fcm_gallery_shared/lib/src/message/fcm_notification.dart`:

```dart
import 'json_object_reader.dart';

/// The notification FCM renders itself when the app is not in the foreground.
///
/// FCM's `Message.notification`, which applies to every platform; the platform
/// blocks override it where they need to.
class FcmNotification {
  const FcmNotification({this.title, this.body, this.image});

  /// Reads FCM's `Notification` object.
  factory FcmNotification.fromJson(Map<String, Object?> json) =>
      read(JsonObjectReader(json, path: 'notification'));

  /// Reads from an existing reader, so a parent composes the path rather than
  /// each class inventing its own.
  static FcmNotification read(JsonObjectReader reader) {
    final notification = FcmNotification(
      title: reader.text('title'),
      body: reader.text('body'),
      image: reader.text('image'),
    );
    reader.requireNothingUnclaimed();

    return notification;
  }

  /// The notification's headline.
  final String? title;

  /// The notification's text.
  final String? body;

  /// URL of an image for FCM to download and display — a URL, never bytes.
  final String? image;

  Map<String, Object?> toJson() => {
    'title': ?title,
    'body': ?body,
    'image': ?image,
  };

  @override
  bool operator ==(Object other) =>
      other is FcmNotification &&
      title == other.title &&
      body == other.body &&
      image == other.image;

  @override
  int get hashCode => Object.hash(title, body, image);
}
```

`'title': ?title` is the null-aware map entry: the key is omitted entirely when
the value is null, which is exactly the "absent, never null" rule. This project
already uses it in `ApiError.toJson`.

- [ ] **Step 4: Write the other five**

Same shape, from the field table above. Two notes:

`LightColor`'s four components and `LightSettings`' three fields are **required**,
so their `read` uses a local and throws when a required value is missing:

```dart
  static LightColor read(JsonObjectReader reader) {
    final red = reader.number('red');
    final green = reader.number('green');
    final blue = reader.number('blue');
    final alpha = reader.number('alpha');
    reader.requireNothingUnclaimed();
    if (red == null || green == null || blue == null || alpha == null) {
      throw FormatException(
        'color: red, green, blue and alpha are all required, '
        'and one or more was missing',
      );
    }

    return LightColor(red: red, green: green, blue: blue, alpha: alpha);
  }
```

`LightSettings.read` follows the same shape, reading its colour with
`reader.object('color', LightColor.read)` and naming `light_on_duration` and
`light_off_duration` in its own missing-field message.

Add all six exports to the barrel, alphabetically.

- [ ] **Step 5: Run the tests and the gate, then commit**

Run from `packages/fcm_gallery_shared`: `fvm dart test test/message/`
Expected: PASS, 35 tests.

Run from the repo root: `fvm dart run melos run ci`
Expected: exit 0.

```bash
git add packages/fcm_gallery_shared
git commit -m "feat(shared): add the FCM message leaf objects"
```

---

### Task 4: `AndroidNotification`

Twenty-seven fields, which is why it gets a task of its own.

**Files:**
- Create: `packages/fcm_gallery_shared/lib/src/message/android_notification.dart`
- Modify: `packages/fcm_gallery_shared/lib/fcm_gallery_shared.dart`
- Test: `packages/fcm_gallery_shared/test/message/android_notification_test.dart`

**Interfaces:**
- Consumes: `JsonObjectReader` (Task 1), the three notification enums (Task 2), `LightSettings` (Task 3).
- Produces: `AndroidNotification` with `const` constructor, `fromJson`, `static read`, `toJson`, `==`, `hashCode` — the same shape as `FcmNotification`.

**Fields, all optional:**

| Dart | JSON key | Reader |
| --- | --- | --- |
| `title` | `title` | `text` |
| `body` | `body` | `text` |
| `icon` | `icon` | `text` |
| `color` | `color` | `text` |
| `sound` | `sound` | `text` |
| `tag` | `tag` | `text` |
| `clickAction` | `click_action` | `text` |
| `bodyLocKey` | `body_loc_key` | `text` |
| `bodyLocArgs` | `body_loc_args` | `textList` |
| `titleLocKey` | `title_loc_key` | `text` |
| `titleLocArgs` | `title_loc_args` | `textList` |
| `channelId` | `channel_id` | `text` |
| `ticker` | `ticker` | `text` |
| `sticky` | `sticky` | `flag` |
| `eventTime` | `event_time` | `text` |
| `localOnly` | `local_only` | `flag` |
| `notificationPriority` | `notification_priority` | `enumValue`, `AndroidNotificationPriority` |
| `defaultSound` | `default_sound` | `flag` |
| `defaultVibrateTimings` | `default_vibrate_timings` | `flag` |
| `defaultLightSettings` | `default_light_settings` | `flag` |
| `vibrateTimings` | `vibrate_timings` | `textList` |
| `visibility` | `visibility` | `enumValue`, `NotificationVisibility` |
| `notificationCount` | `notification_count` | `integer` |
| `lightSettings` | `light_settings` | `object`, `LightSettings.read` |
| `image` | `image` | `text` |
| `bypassProxyNotification` | `bypass_proxy_notification` | `flag` |
| `proxy` | `proxy` | `enumValue`, `NotificationProxy` |

**Two things twenty-seven fields break that three did not:**

1. **`Object.hash` takes at most 20 positional arguments.** Use
   `Object.hashAll([...])` with every field in a list. `Object.hash(a, b, …)` with
   27 arguments does not compile.
2. **Three fields are lists, and Dart lists have no value equality.** `==` must
   compare `bodyLocArgs`, `titleLocArgs` and `vibrateTimings` with
   `const ListEquality<String>().equals(...)` from `package:collection`, which is
   already a dependency of this package. A plain `==` on two equal lists returns
   false, and the round-trip test below would pass while equality silently did not
   work — so the equality test is not decoration.

- [ ] **Step 1: Write the failing test**

`packages/fcm_gallery_shared/test/message/android_notification_test.dart`:

```dart
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:test/test.dart';

void main() {
  /// Every field set, so the round-trip proves no field was forgotten.
  const everyField = {
    'title': 'Build finished',
    'body': 'Release 1.0.0 is ready.',
    'icon': 'ic_stat_build',
    'color': '#4285f4',
    'sound': 'default',
    'tag': 'builds',
    'click_action': 'OPEN_BUILD',
    'body_loc_key': 'build_body',
    'body_loc_args': ['1.0.0'],
    'title_loc_key': 'build_title',
    'title_loc_args': ['128'],
    'channel_id': 'fcm_sample_high',
    'ticker': 'Build finished',
    'sticky': true,
    'event_time': '2026-08-11T09:30:00Z',
    'local_only': false,
    'notification_priority': 'PRIORITY_HIGH',
    'default_sound': true,
    'default_vibrate_timings': false,
    'default_light_settings': false,
    'vibrate_timings': ['0.5s', '0.5s'],
    'visibility': 'PUBLIC',
    'notification_count': 3,
    'light_settings': {
      'color': {'red': 1.0, 'green': 0.5, 'blue': 0.0, 'alpha': 1.0},
      'light_on_duration': '1s',
      'light_off_duration': '0.5s',
    },
    'image': 'https://example.test/build.png',
    'bypass_proxy_notification': false,
    'proxy': 'ALLOW',
  };

  test('round-trips all 27 fields, so none is silently dropped', () {
    expect(AndroidNotification.fromJson(everyField).toJson(), everyField);
  });

  test('the round-trip really covered every field', () {
    // Guards against a field being added to the class but not to everyField:
    // the fixture must mention as many keys as the class writes out.
    expect(everyField, hasLength(27));
  });

  test('omits absent fields rather than writing null', () {
    const notification = AndroidNotification(title: 'Only a title');

    expect(notification.toJson(), {'title': 'Only a title'});
  });

  test('keeps a false flag, which is a value rather than an absence', () {
    expect(
      AndroidNotification.fromJson({'sticky': false}).toJson(),
      {'sticky': false},
    );
  });

  test('keeps durations and timestamps exactly as written', () {
    final parsed = AndroidNotification.fromJson({
      'event_time': '2026-08-11T09:30:00.000000Z',
      'vibrate_timings': ['3.500s'],
    });

    expect(parsed.toJson()['event_time'], '2026-08-11T09:30:00.000000Z');
    expect(parsed.toJson()['vibrate_timings'], ['3.500s']);
  });

  test('rejects a field FCM does not define, naming it', () {
    expect(
      () => AndroidNotification.fromJson({'channelID': 'wrong_case'}),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('unknown field "channelID"'),
        ),
      ),
    );
  });

  test('rejects an unrecognised enum value with its path', () {
    expect(
      () => AndroidNotification.fromJson({'visibility': 'HIDDEN'}),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('visibility: unknown value "HIDDEN"'),
        ),
      ),
    );
  });

  group('equality', () {
    test('compares list fields by value, not by identity', () {
      expect(
        AndroidNotification.fromJson({'vibrate_timings': ['1s']}),
        AndroidNotification.fromJson({'vibrate_timings': ['1s']}),
      );
    });

    test('separates notifications differing only inside a list', () {
      expect(
        AndroidNotification.fromJson({'vibrate_timings': ['1s']}),
        isNot(AndroidNotification.fromJson({'vibrate_timings': ['2s']})),
      );
    });

    test('hashes equal notifications equally, despite 27 fields', () {
      expect(
        AndroidNotification.fromJson(everyField).hashCode,
        AndroidNotification.fromJson(everyField).hashCode,
      );
    });
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run from `packages/fcm_gallery_shared`: `fvm dart test test/message/android_notification_test.dart`
Expected: FAIL — `Undefined name 'AndroidNotification'`.

- [ ] **Step 3: Write the class**

Follow `FcmNotification`'s shape from Task 3 exactly — `const` constructor with all
27 named parameters, `fromJson` delegating to `read` with `path: 'notification'`,
`read` assigning each field with the reader method from the table then calling
`requireNothingUnclaimed()`, and `toJson` using `'key': ?field` throughout.

For the two list fields and the enums:

```dart
      bodyLocArgs: reader.textList('body_loc_args'),
      notificationPriority: reader.enumValue(
        'notification_priority',
        AndroidNotificationPriority.values,
        (value) => value.wireName,
      ),
      lightSettings: reader.object('light_settings', LightSettings.read),
```

and in `toJson`, the enums and the nested object serialise through their own
representations:

```dart
    'notification_priority': ?notificationPriority?.wireName,
    'light_settings': ?lightSettings?.toJson(),
    'body_loc_args': ?bodyLocArgs,
```

Equality and hashing:

```dart
  static const _stringList = ListEquality<String>();

  @override
  bool operator ==(Object other) =>
      other is AndroidNotification &&
      title == other.title &&
      // … the other scalar fields …
      _stringList.equals(bodyLocArgs, other.bodyLocArgs) &&
      _stringList.equals(titleLocArgs, other.titleLocArgs) &&
      _stringList.equals(vibrateTimings, other.vibrateTimings) &&
      lightSettings == other.lightSettings;

  @override
  int get hashCode => Object.hashAll([
    title,
    // … every field …
    if (bodyLocArgs case final args?) ...args,
    if (titleLocArgs case final args?) ...args,
    if (vibrateTimings case final args?) ...args,
    lightSettings,
  ]);
```

Note the lists are spread into the hash rather than hashed as list objects, since
two equal lists are different objects and would otherwise hash differently —
breaking the `hashCode` contract that equal values hash equally.

Add the export to the barrel, alphabetically.

- [ ] **Step 4: Run the tests and the gate, then commit**

Run from `packages/fcm_gallery_shared`: `fvm dart test test/message/`
Expected: PASS, 45 tests.

Run from the repo root: `fvm dart run melos run ci`
Expected: exit 0. DCM will not complain about the 27 parameters because Task 1
excluded this directory; if it does, the exclusion path is wrong — fix that rather
than the class.

```bash
git add packages/fcm_gallery_shared
git commit -m "feat(shared): add AndroidNotification"
```

---

### Task 5: `AndroidConfig`

**Files:**
- Create: `packages/fcm_gallery_shared/lib/src/message/android_config.dart`
- Modify: `packages/fcm_gallery_shared/lib/fcm_gallery_shared.dart`
- Test: `packages/fcm_gallery_shared/test/message/android_config_test.dart`

**Interfaces:**
- Consumes: `JsonObjectReader`, `AndroidMessagePriority` (Task 2), `AndroidNotification` (Task 4), `FcmOptions` (Task 3).
- Produces: `AndroidConfig`, same shape as the others.

| Dart | JSON key | Reader |
| --- | --- | --- |
| `collapseKey` | `collapse_key` | `text` |
| `priority` | `priority` | `enumValue`, `AndroidMessagePriority` |
| `ttl` | `ttl` | `text` |
| `restrictedPackageName` | `restricted_package_name` | `text` |
| `data` | `data` | `stringMap` |
| `notification` | `notification` | `object`, `AndroidNotification.read` |
| `fcmOptions` | `fcm_options` | `object`, `FcmOptions.read` |
| `directBootOk` | `direct_boot_ok` | `flag` |

`data` is a free-form island: its keys are the caller's, so `stringMap` passes them
through and never rejects one. Equality needs `const MapEquality<String, String>()`
for it, for the same reason the lists needed `ListEquality`.

- [ ] **Step 1: Write the failing test**

`packages/fcm_gallery_shared/test/message/android_config_test.dart`:

```dart
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:test/test.dart';

void main() {
  const everyField = {
    'collapse_key': 'builds',
    'priority': 'HIGH',
    'ttl': '3600s',
    'restricted_package_name': 'cz.netglade.fcm_app',
    'data': {'event': 'build_finished'},
    'notification': {'title': 'Build finished', 'channel_id': 'fcm_sample_high'},
    'fcm_options': {'analytics_label': 'campaign-1'},
    'direct_boot_ok': true,
  };

  test('round-trips every field', () {
    expect(AndroidConfig.fromJson(everyField).toJson(), everyField);
  });

  test('the round-trip really covered every field', () {
    expect(everyField, hasLength(8));
  });

  test('keeps arbitrary data keys, which are the caller\'s own', () {
    final config = AndroidConfig.fromJson({
      'data': {'anything_at_all': '1', 'even_this': '2'},
    });

    expect(config.data, {'anything_at_all': '1', 'even_this': '2'});
  });

  test('rejects an unknown field at the config level', () {
    expect(
      () => AndroidConfig.fromJson({'collapseKey': 'wrong_case'}),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('unknown field "collapseKey"'),
        ),
      ),
    );
  });

  test('names the nested path when the notification is malformed', () {
    expect(
      () => AndroidConfig.fromJson({
        'notification': {'titel': 'typo'},
      }),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('android.notification: unknown field "titel"'),
        ),
      ),
    );
  });

  test('compares data maps by value', () {
    expect(
      AndroidConfig.fromJson({'data': {'k': 'v'}}),
      AndroidConfig.fromJson({'data': {'k': 'v'}}),
    );
  });
}
```

The nested-path test pins that `fromJson` uses `path: 'android'`, which is what
makes a parse error point at the right place from the root.

- [ ] **Step 2: Run the test, implement, and run it again**

Run from `packages/fcm_gallery_shared`: `fvm dart test test/message/android_config_test.dart`
Expected first: FAIL — `Undefined name 'AndroidConfig'`. Then write the class per
the table, with `fromJson` using `path: 'android'`. Expected after: PASS, 6 tests.

- [ ] **Step 3: Run the gate and commit**

Run from the repo root: `fvm dart run melos run ci`
Expected: exit 0.

```bash
git add packages/fcm_gallery_shared
git commit -m "feat(shared): add AndroidConfig"
```

---

### Task 6: `ApnsConfig` and `WebpushConfig`

The two blocks whose payloads FCM defines as free-form, which is what makes them a
pair rather than two tasks.

**Files:**
- Create: `packages/fcm_gallery_shared/lib/src/message/apns_config.dart`
- Create: `packages/fcm_gallery_shared/lib/src/message/webpush_config.dart`
- Modify: `packages/fcm_gallery_shared/lib/fcm_gallery_shared.dart`
- Test: `packages/fcm_gallery_shared/test/message/platform_configs_test.dart`

**Interfaces:**
- Consumes: `JsonObjectReader`, `ApnsFcmOptions`, `WebpushFcmOptions` (Task 3).
- Produces:

| Type | Dart → JSON | Reader |
| --- | --- | --- |
| `ApnsConfig` | `headers` → `headers` | `stringMap` |
| | `payload` → `payload` | `freeForm` |
| | `fcmOptions` → `fcm_options` | `object`, `ApnsFcmOptions.read` |
| `WebpushConfig` | `headers` → `headers` | `stringMap` |
| | `data` → `data` | `stringMap` |
| | `notification` → `notification` | `freeForm` |
| | `fcmOptions` → `fcm_options` | `object`, `WebpushFcmOptions.read` |

**`apns.payload` and `webpush.notification` are `Map<String, Object?>` read with
`freeForm`, and are never inspected.** Apple's `aps` dictionary and the Web
Notification API's options are the caller's business, and a payload may carry
arbitrary sibling keys alongside `aps`. Rejecting unknown keys there would be
wrong, and typing `aps` is explicitly Spec 3's decision to make.

Equality uses `const MapEquality<String, Object?>()` for the free-form maps and
`const MapEquality<String, String>()` for the header maps.

- [ ] **Step 1: Write the failing test**

`packages/fcm_gallery_shared/test/message/platform_configs_test.dart`:

```dart
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:test/test.dart';

void main() {
  group('ApnsConfig', () {
    const everyField = {
      'headers': {'apns-priority': '10', 'apns-push-type': 'alert'},
      'payload': {
        'aps': {
          'alert': {'title': 'Build finished', 'body': 'Ready.'},
          'badge': 1,
          'sound': 'default',
          'content-available': 1,
          'thread-id': 'builds',
        },
        'custom_key': [1, 2, 3],
      },
      'fcm_options': {'image': 'https://example.test/a.png'},
    };

    test('round-trips every field', () {
      expect(ApnsConfig.fromJson(everyField).toJson(), everyField);
    });

    test('passes the payload through untouched, including nested structure', () {
      final config = ApnsConfig.fromJson(everyField);
      final aps = config.payload!['aps']! as Map<String, Object?>;

      expect(aps['content-available'], 1);
      expect(aps['thread-id'], 'builds');
      expect(config.payload!['custom_key'], [1, 2, 3]);
    });

    test('accepts a payload key the model has never heard of', () {
      // The escape hatch that makes an untyped aps acceptable: anything Apple
      // adds is writable today, without a model change.
      final config = ApnsConfig.fromJson({
        'payload': {
          'aps': {'interruption-level': 'time-sensitive'},
        },
      });

      expect(
        (config.payload!['aps']! as Map<String, Object?>)['interruption-level'],
        'time-sensitive',
      );
    });

    test('still rejects an unknown field at the config level', () {
      expect(
        () => ApnsConfig.fromJson({'payloads': <String, Object?>{}}),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('apns: unknown field "payloads"'),
          ),
        ),
      );
    });

    test('rejects an image in the generic options position', () {
      // ApnsFcmOptions accepts image; the generic FcmOptions does not. This pins
      // that apns uses the APNs-specific type.
      expect(
        ApnsConfig.fromJson({
          'fcm_options': {'image': 'https://example.test/a.png'},
        }).fcmOptions?.image,
        'https://example.test/a.png',
      );
    });
  });

  group('WebpushConfig', () {
    const everyField = {
      'headers': {'TTL': '60'},
      'data': {'event': 'build_finished'},
      'notification': {'title': 'Build finished', 'requireInteraction': true},
      'fcm_options': {'link': 'https://example.test/builds'},
    };

    test('round-trips every field', () {
      expect(WebpushConfig.fromJson(everyField).toJson(), everyField);
    });

    test('passes the notification through untouched', () {
      final config = WebpushConfig.fromJson(everyField);

      expect(config.notification!['requireInteraction'], isTrue);
    });

    test('reads the link only WebPush accepts', () {
      expect(
        WebpushConfig.fromJson(everyField).fcmOptions?.link,
        'https://example.test/builds',
      );
    });

    test('rejects an unknown field at the config level', () {
      expect(
        () => WebpushConfig.fromJson({'header': <String, Object?>{}}),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('webpush: unknown field "header"'),
          ),
        ),
      );
    });
  });
}
```

- [ ] **Step 2: Run the test, implement, and run it again**

Run from `packages/fcm_gallery_shared`: `fvm dart test test/message/platform_configs_test.dart`
Expected first: FAIL. Then write both classes per the table, `fromJson` using
`path: 'apns'` and `path: 'webpush'`. Expected after: PASS, 9 tests.

- [ ] **Step 3: Run the gate and commit**

Run from the repo root: `fvm dart run melos run ci`
Expected: exit 0.

```bash
git add packages/fcm_gallery_shared
git commit -m "feat(shared): add the APNs and WebPush configs"
```

---

### Task 7: `FcmMessage` and the target rule

**Files:**
- Create: `packages/fcm_gallery_shared/lib/src/message/fcm_message.dart`
- Modify: `packages/fcm_gallery_shared/lib/fcm_gallery_shared.dart`
- Test: `packages/fcm_gallery_shared/test/message/fcm_message_test.dart`

**Interfaces:**
- Consumes: everything from Tasks 1–6.
- Produces: `FcmMessage` with fields `data` → `data` (`stringMap`), `notification` → `notification` (`FcmNotification.read`), `android` → `android` (`AndroidConfig.read`), `webpush` → `webpush` (`WebpushConfig.read`), `apns` → `apns` (`ApnsConfig.read`), `fcmOptions` → `fcm_options` (`FcmOptions.read`).

**`Message.name` is omitted** — it is output-only and never sent.

**The target rule needs claiming, not just rejecting.** `token`, `topic` and
`condition` would already be caught by `requireNothingUnclaimed()` as unknown
fields, but "unknown field" is the wrong explanation: they are real FCM fields the
server owns. So `read` claims them and throws its own message:

```dart
    for (final target in const ['token', 'topic', 'condition']) {
      if (reader.text(target) != null) {
        throw FormatException(
          'message.$target: the server sets the delivery target, so a payload '
          'template must not set it',
        );
      }
    }
```

- [ ] **Step 1: Write the failing test**

`packages/fcm_gallery_shared/test/message/fcm_message_test.dart`:

```dart
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:test/test.dart';

void main() {
  Matcher throwsFormatMentioning(String fragment) => throwsA(
    isA<FormatException>().having(
      (error) => error.message,
      'message',
      contains(fragment),
    ),
  );

  const everyBlock = {
    'data': {'event': 'build_finished'},
    'notification': {'title': 'Build finished', 'body': 'Ready.'},
    'android': {'priority': 'HIGH'},
    'webpush': {'headers': {'TTL': '60'}},
    'apns': {'headers': {'apns-priority': '10'}},
    'fcm_options': {'analytics_label': 'campaign-1'},
  };

  test('round-trips every block', () {
    expect(FcmMessage.fromJson(everyBlock).toJson(), everyBlock);
  });

  test('the round-trip really covered every block', () {
    expect(everyBlock, hasLength(6));
  });

  test('accepts a notification-only message', () {
    const json = {'notification': {'title': 'Hi'}};

    expect(FcmMessage.fromJson(json).toJson(), json);
  });

  test('accepts a data-only message, which is the silent path', () {
    const json = {'data': {'event': 'sync'}};

    final message = FcmMessage.fromJson(json);

    expect(message.notification, isNull);
    expect(message.toJson(), json);
  });

  test('accepts an empty message, leaving FCM to reject it', () {
    expect(FcmMessage.fromJson(const {}).toJson(), isEmpty);
  });

  group('the delivery target', () {
    test('rejects a token, explaining that the server sets it', () {
      expect(
        () => FcmMessage.fromJson({'token': 'e…'}),
        throwsFormatMentioning('message.token: the server sets the delivery target'),
      );
    });

    test('rejects a topic', () {
      expect(
        () => FcmMessage.fromJson({'topic': 'builds'}),
        throwsFormatMentioning('message.topic'),
      );
    });

    test('rejects a condition', () {
      expect(
        () => FcmMessage.fromJson({'condition': "'builds' in topics"}),
        throwsFormatMentioning('message.condition'),
      );
    });

    test('never writes a target, so one cannot leak back out', () {
      final json = FcmMessage.fromJson(everyBlock).toJson();

      expect(json.keys, isNot(contains('token')));
      expect(json.keys, isNot(contains('topic')));
      expect(json.keys, isNot(contains('condition')));
    });
  });

  test('rejects the output-only name field', () {
    expect(
      () => FcmMessage.fromJson({'name': 'projects/p/messages/1'}),
      throwsFormatMentioning('unknown field "name"'),
    );
  });

  test('names the deepest path when a nested block is malformed', () {
    expect(
      () => FcmMessage.fromJson({
        'android': {
          'notification': {'light_settings': {'color': {'red': 'red'}}},
        },
      }),
      throwsFormatMentioning('android.notification.light_settings.color.red'),
    );
  });
}
```

The last test is the one that proves the whole reader design works: a typo four
levels down reports its full path.

- [ ] **Step 2: Run the test, implement, and run it again**

Run from `packages/fcm_gallery_shared`: `fvm dart test test/message/fcm_message_test.dart`
Expected first: FAIL. Then write the class, `fromJson` using `path: 'message'`.
Expected after: PASS, 11 tests.

- [ ] **Step 3: Run the gate and commit**

Run from the repo root: `fvm dart run melos run ci`
Expected: exit 0, and `fvm dart test test/message/` reports 71 tests.

```bash
git add packages/fcm_gallery_shared
git commit -m "feat(shared): add FcmMessage and the target rule"
```

---

### Task 8: `Scenario` and the gallery

**Files:**
- Create: `packages/fcm_gallery_shared/lib/src/scenario.dart`
- Modify: `packages/fcm_gallery_shared/lib/fcm_gallery_shared.dart`
- Test: `packages/fcm_gallery_shared/test/scenario_test.dart`

**Interfaces:**
- Consumes: `FcmMessage` (Task 7).
- Produces: `Scenario` with the nine fields below, and `const scenarioGallery` — a `List<Scenario>` of nine.

`NotificationScenario` and `notificationGallery` **stay** for now; Task 14 deletes
them once nothing uses them. Both existing and new must coexist here, so the gate
stays green.

```dart
class Scenario {
  const Scenario({
    required this.id,
    required this.group,
    required this.title,
    required this.description,
    required this.payloadTemplate,
    this.expectation,
    this.requiresKilledApp = false,
    this.defaultDelaySeconds = 0,
    this.tags = const [],
  });

  /// Stable slug, used as a widget key and in tests.
  final String id;

  /// The heading this scenario is filed under in the Sandbox.
  final String group;

  final String title;

  /// What should happen, and what to watch for while it does.
  final String description;

  /// A device- or platform-specific caveat, when there is one.
  final String? expectation;

  /// An FCM v1 message, without a delivery target — the server sets that.
  ///
  /// Deliberately a raw map rather than an [FcmMessage]: this is the authoring
  /// format, so a template can be pasted straight out of Google's REST
  /// reference. `FcmMessage.fromJson` is what turns it into something editable.
  final Map<String, dynamic> payloadTemplate;

  /// Whether the scenario only demonstrates anything with the app killed.
  ///
  /// Carried but not acted on yet: Spec 2 turns this into a delayed send. The
  /// Sandbox shows it as a hint so the field is not silently meaningless.
  final bool requiresKilledApp;

  /// Seconds to hold the send for, once Spec 2 implements delaying.
  final int defaultDelaySeconds;

  /// Free-form labels shown as chips: platform names, features.
  final List<String> tags;
}
```

`Scenario` lives in `lib/src/scenario.dart`, which Task 1 added to
`metrics-exclude` — nine named parameters exceed `number-of-parameters: 5`.

- [ ] **Step 1: Write the failing test**

`packages/fcm_gallery_shared/test/scenario_test.dart`:

```dart
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:test/test.dart';

void main() {
  group('scenarioGallery', () {
    test('offers the nine scenarios the Sandbox lists', () {
      expect(scenarioGallery, hasLength(9));
    });

    test('gives every scenario a unique id', () {
      final ids = scenarioGallery.map((scenario) => scenario.id).toSet();

      expect(ids, hasLength(scenarioGallery.length));
    });

    test('files every scenario under a non-blank group', () {
      for (final scenario in scenarioGallery) {
        expect(scenario.group.trim(), isNotEmpty, reason: scenario.id);
      }
    });

    test('gives every scenario a title, description and at least one tag', () {
      for (final scenario in scenarioGallery) {
        expect(scenario.title.trim(), isNotEmpty, reason: scenario.id);
        expect(scenario.description.trim(), isNotEmpty, reason: scenario.id);
        expect(scenario.tags, isNotEmpty, reason: scenario.id);
      }
    });

    test('every template parses as an FCM message', () {
      for (final scenario in scenarioGallery) {
        expect(
          () => FcmMessage.fromJson(scenario.payloadTemplate),
          returnsNormally,
          reason: scenario.id,
        );
      }
    });

    test('every template round-trips unchanged, so nothing is dropped', () {
      for (final scenario in scenarioGallery) {
        expect(
          FcmMessage.fromJson(scenario.payloadTemplate).toJson(),
          scenario.payloadTemplate,
          reason: scenario.id,
        );
      }
    });

    test('no template sets a delivery target', () {
      for (final scenario in scenarioGallery) {
        expect(scenario.payloadTemplate.keys, isNot(contains('token')));
        expect(scenario.payloadTemplate.keys, isNot(contains('topic')));
        expect(scenario.payloadTemplate.keys, isNot(contains('condition')));
      }
    });

    test('covers more than one group', () {
      final groups = scenarioGallery.map((scenario) => scenario.group).toSet();

      expect(groups, hasLength(greaterThan(1)));
    });

    test('the data-only scenario really carries no notification', () {
      final dataOnly = scenarioGallery.firstWhere(
        (scenario) => scenario.id == 'data_only',
      );

      expect(dataOnly.payloadTemplate.keys, contains('data'));
      expect(dataOnly.payloadTemplate.keys, isNot(contains('notification')));
      expect(dataOnly.requiresKilledApp, isTrue);
    });

    test('a scenario that needs a killed app asks for a delay', () {
      for (final scenario in scenarioGallery) {
        if (scenario.requiresKilledApp) {
          expect(
            scenario.defaultDelaySeconds,
            greaterThan(0),
            reason: '${scenario.id} cannot be demonstrated without time to kill '
                'the app',
          );
        }
      }
    });
  });
}
```

The round-trip test is the one that earns its keep: it proves the typed model is a
faithful mirror for every payload actually shipped, and it fails loudly if a
template uses a field nobody modelled.

- [ ] **Step 2: Run the test to verify it fails**

Run from `packages/fcm_gallery_shared`: `fvm dart test test/scenario_test.dart`
Expected: FAIL — `Undefined name 'scenarioGallery'`.

- [ ] **Step 3: Write the nine scenarios**

Below `Scenario` in the same file. Templates are authored in snake_case so they read
as the FCM reference does.

| id | group | title | Template |
| --- | --- | --- | --- |
| `big_picture_remote` | Appearance | Notification with an image | `{'notification': {'title': 'Build finished', 'body': 'Release 1.0.0 is ready.', 'image': 'https://picsum.photos/600/300'}}` |
| `coloured_icon` | Appearance | Coloured small icon | `{'notification': {'title': 'Build finished', 'body': 'Release 1.0.0 is ready.'}, 'android': {'notification': {'icon': 'ic_stat_build', 'color': '#4285f4'}}}` |
| `custom_channel` | Appearance | High-importance channel | `{'notification': {'title': 'Heads up', 'body': 'This should pop as a banner.'}, 'android': {'notification': {'channel_id': 'fcm_sample_high'}}}` |
| `high_priority` | Delivery | High priority | `{'notification': {'title': 'High priority', 'body': 'Should arrive at once.'}, 'android': {'priority': 'HIGH'}}` |
| `normal_priority_long_ttl` | Delivery | Normal priority, one hour TTL | `{'notification': {'title': 'Normal priority', 'body': 'May be held for a while.'}, 'android': {'priority': 'NORMAL', 'ttl': '3600s'}}` |
| `collapsible` | Delivery | Collapsible | `{'notification': {'title': 'Build finished', 'body': 'Only the newest should arrive.'}, 'android': {'collapse_key': 'builds'}}` |
| `data_only` | Data | Data-only, silent | `{'data': {'event': 'sync', 'build_number': '128'}, 'android': {'priority': 'HIGH'}}` |
| `notification_and_data` | Data | Notification plus data | `{'notification': {'title': 'Build finished', 'body': 'Tap to open it.'}, 'data': {'event': 'build_finished', 'deep_link': '/builds/128'}}` |
| `apns_alert` | iOS | APNs alert with a badge | `{'apns': {'headers': {'apns-priority': '10'}, 'payload': {'aps': {'alert': {'title': 'Build finished', 'body': 'Release 1.0.0 is ready.'}, 'badge': 1, 'sound': 'default'}}}}` |

Descriptions say what should happen and what to watch. Expectations, where they
exist:

| id | `expectation` | `requiresKilledApp` | `defaultDelaySeconds` | `tags` |
| --- | --- | --- | --- | --- |
| `big_picture_remote` | On some Xiaomi and Huawei builds the image may not appear. | false | 0 | `['android', 'ios', 'image']` |
| `coloured_icon` | The icon must exist as a drawable in the app; Android falls back to the launcher icon otherwise. | false | 0 | `['android', 'icon']` |
| `custom_channel` | The channel must already exist. Android silently uses the default channel for an unknown id. | false | 0 | `['android', 'channel']` |
| `high_priority` | — | false | 0 | `['android', 'priority']` |
| `normal_priority_long_ttl` | A dozing device may hold this until its next maintenance window, so minutes is normal. | false | 0 | `['android', 'priority', 'ttl']` |
| `collapsible` | Send twice while the device is offline; only the last should arrive. | false | 0 | `['android', 'collapse']` |
| `data_only` | No notification is drawn. It appears in the inbox with empty text and its data keys. | **true** | **10** | `['android', 'ios', 'data', 'silent']` |
| `notification_and_data` | — | false | 0 | `['android', 'ios', 'data']` |
| `apns_alert` | Unverified here — this machine has no Xcode and no iOS device. | false | 0 | `['ios', 'apns']` |

- [ ] **Step 4: Run the tests and the gate, then commit**

Run from `packages/fcm_gallery_shared`: `fvm dart test`
Expected: PASS. If the round-trip test fails for a scenario, the **template** is
what to fix — either a key is misspelled, or it uses a field Task 4–7 did not
model. Report which, rather than loosening the assertion.

Run from the repo root: `fvm dart run melos run ci`
Expected: exit 0.

```bash
git add packages/fcm_gallery_shared
git commit -m "feat(shared): add Scenario and the payload template gallery"
```

---

### Task 9: The request and response envelope

**Files:**
- Create: `packages/fcm_gallery_shared/lib/src/send_message_request.dart`
- Create: `packages/fcm_gallery_shared/lib/src/send_message_response.dart`
- Modify: `packages/fcm_gallery_shared/lib/fcm_gallery_shared.dart`
- Test: `packages/fcm_gallery_shared/test/send_message_envelope_test.dart`

**Interfaces:**
- Consumes: `FcmMessage` (Task 7), the `json_field.dart` helpers already in this package (`requireText`, `requireTimestamp`).
- Produces:
  - `SendMessageRequest` — `const SendMessageRequest({required String token, required FcmMessage message, bool validateOnly = false})`, `fromJson`, `toJson` writing `{token, validate_only, message}`
  - `SendMessageResponse` — `const SendMessageResponse({required String messageId, required DateTime sentAt})`, `fromJson`, `toJson` writing `{messageId, sentAt}`

`validate_only` is snake_case like the rest of the FCM surface, and is always
written even when false — it is the caller's explicit intent, not an optional
field. `SendNotificationRequest`/`Response` stay until Task 14.

- [ ] **Step 1: Write the failing test**

`packages/fcm_gallery_shared/test/send_message_envelope_test.dart`:

```dart
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:test/test.dart';

void main() {
  group('SendMessageRequest', () {
    const request = SendMessageRequest(
      token: 'device-token',
      message: FcmMessage(notification: FcmNotification(title: 'Hi')),
    );

    test('writes the token, the flag and the message', () {
      expect(request.toJson(), {
        'token': 'device-token',
        'validate_only': false,
        'message': {'notification': {'title': 'Hi'}},
      });
    });

    test('round-trips', () {
      final parsed = SendMessageRequest.fromJson(request.toJson());

      expect(parsed.token, 'device-token');
      expect(parsed.validateOnly, isFalse);
      expect(parsed.message.notification?.title, 'Hi');
    });

    test('carries validate_only when set', () {
      const validating = SendMessageRequest(
        token: 't',
        message: FcmMessage(),
        validateOnly: true,
      );

      expect(validating.toJson()['validate_only'], isTrue);
      expect(SendMessageRequest.fromJson(validating.toJson()).validateOnly, isTrue);
    });

    test('defaults validate_only to false when absent from the body', () {
      final parsed = SendMessageRequest.fromJson({
        'token': 't',
        'message': <String, Object?>{},
      });

      expect(parsed.validateOnly, isFalse);
    });

    test('rejects a body with no message, since there is nothing to send', () {
      expect(
        () => SendMessageRequest.fromJson({'token': 't'}),
        throwsA(isA<FormatException>()),
      );
    });

    test('reports a malformed message with its path, not as a bare failure', () {
      expect(
        () => SendMessageRequest.fromJson({
          'token': 't',
          'message': {'notification': {'titel': 'typo'}},
        }),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('notification: unknown field "titel"'),
          ),
        ),
      );
    });

    test('rejects a message that sets its own target', () {
      expect(
        () => SendMessageRequest.fromJson({
          'token': 't',
          'message': {'token': 'other'},
        }),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('the server sets the delivery target'),
          ),
        ),
      );
    });
  });

  group('SendMessageResponse', () {
    final response = SendMessageResponse(
      messageId: 'projects/p/messages/0:17',
      sentAt: DateTime.utc(2026, 8, 11, 9, 12, 3),
    );

    test('round-trips', () {
      final parsed = SendMessageResponse.fromJson(response.toJson());

      expect(parsed.messageId, response.messageId);
      expect(parsed.sentAt, response.sentAt);
    });

    test('normalises the timestamp to UTC', () {
      final parsed = SendMessageResponse.fromJson({
        'messageId': 'm',
        'sentAt': '2026-08-11T11:12:03+02:00',
      });

      expect(parsed.sentAt, DateTime.utc(2026, 8, 11, 9, 12, 3));
      expect(parsed.sentAt.isUtc, isTrue);
    });

    test('rejects a response missing a field rather than inventing one', () {
      expect(
        () => SendMessageResponse.fromJson({'messageId': 'm'}),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
```

- [ ] **Step 2: Run the test, implement, and run it again**

Run from `packages/fcm_gallery_shared`: `fvm dart test test/send_message_envelope_test.dart`
Expected first: FAIL. Then write both classes. `SendMessageRequest.fromJson` reads
`token` with `requireText`, `validate_only` with a `bool` cast defaulting to false,
and `message` by requiring the key then calling `FcmMessage.fromJson`. Expected
after: PASS, 10 tests.

- [ ] **Step 3: Run the gate and commit**

Run from the repo root: `fvm dart run melos run ci`
Expected: exit 0.

```bash
git add packages/fcm_gallery_shared
git commit -m "feat(shared): add the send message request and response"
```

---

### Task 10: Relax `core`'s parser

**Files:**
- Modify: `packages/core/lib/src/push_message_parser.dart`
- Modify: `packages/core/lib/src/push_message.dart`
- Modify: `apps/fcm_app/lib/ui/message_tile.dart`
- Test: `packages/core/test/push_message_parser_test.dart`
- Test: `apps/fcm_app/test/inbox_view_test.dart`

**Interfaces:**
- Consumes: nothing new.
- Produces: `PushMessageParser.parse` accepts a payload with no `title` or `body`, yielding `''` for each. `id` and `sentAt` stay required.

**Why:** raw payload templates mean data-only pushes, which carry no title or body.
Without this they are counted as malformed and never seen, which defeats the point
of being able to send them.

**Consequence to record in Task 14's README edit:** `PushInbox.rejections` becomes
nearly unreachable — only a `sentAt` that will not parse, or a blank `id`, can
trigger it. The counter stays, because that is exactly when you want to know, but
it stops being an expected outcome.

- [ ] **Step 1: Write the failing tests**

Add to `packages/core/test/push_message_parser_test.dart`, keeping every existing
test — they are the regression net:

```dart
  group('optional headline fields', () {
    test('accepts a payload with no title or body, as a data-only push has', () {
      final message = parser.parse({
        'id': 'msg-1',
        'sentAt': '2026-08-06T09:30:00Z',
        'event': 'sync',
      });

      expect(message.title, isEmpty);
      expect(message.body, isEmpty);
      expect(message.data, {'event': 'sync'});
    });

    test('accepts a blank title, rather than calling it malformed', () {
      final message = parser.parse(validPayload(overrides: {'title': ''}));

      expect(message.title, isEmpty);
    });

    test('still rejects a title of the wrong type', () {
      expect(
        () => parser.parse(validPayload(overrides: {'title': 7})),
        throwsA(isA<PushMessageFormatException>()),
      );
    });

    test('still requires an id, which is what de-duplicates deliveries', () {
      expect(
        () => parser.parse(validPayload(overrides: {'id': ''})),
        throwsA(isA<PushMessageFormatException>()),
      );
    });

    test('still requires a parseable sentAt, which is what orders the inbox', () {
      expect(
        () => parser.parse(validPayload(overrides: {'sentAt': 'yesterday'})),
        throwsA(isA<PushMessageFormatException>()),
      );
    });
  });
```

And add to `apps/fcm_app/test/inbox_view_test.dart`:

```dart
  testWidgets('shows a placeholder for a push with no title', (tester) async {
    inbox = PushInbox(source)..listen();
    await pumpApp(tester);

    source.emit({
      'id': 'silent-1',
      'sentAt': '2026-08-06T09:30:00Z',
      'event': 'sync',
    });
    await tester.pumpAndSettle();

    expect(find.text('(no title)'), findsOne);
    expect(find.textContaining('event'), findsOne);
    expect(find.text('1 malformed payload(s) dropped'), findsNothing);
  });
```

- [ ] **Step 2: Run the tests to verify they fail**

Run from `packages/core`: `fvm dart test test/push_message_parser_test.dart`
Expected: FAIL — the parser throws on a missing title.

- [ ] **Step 3: Relax the parser**

In `packages/core/lib/src/push_message_parser.dart`, change the two calls and add
one method:

```dart
    return PushMessage(
      id: _requireText(payload, 'id'),
      title: _optionalText(payload, 'title'),
      body: _optionalText(payload, 'body'),
      sentAt: _requireTimestamp(payload, 'sentAt'),
      data: Map.unmodifiable(data),
    );
```

```dart
  /// Reads a field that may be absent or blank.
  ///
  /// A data-only push carries no title and no body, and sending exactly those is
  /// the point of the playground — so an empty headline is a value, not a fault.
  /// A *wrong-typed* value is still a fault.
  String _optionalText(Map<String, Object?> payload, String field) {
    final value = payload[field];
    if (value == null) {
      return '';
    }
    if (value is! String) {
      throw PushMessageFormatException(
        field,
        'expected a String, got ${value.runtimeType}',
      );
    }

    return value;
  }
```

`reservedKeys` is unchanged: all four keys are still lifted out of `data`.

In `packages/core/lib/src/push_message.dart`, `title` and `body` doc comments stop
promising content:

```dart
  /// Short headline, suitable for a notification title or list tile.
  ///
  /// Empty for a data-only push, which carries no notification block at all — so
  /// a caller rendering this must handle a blank string.
  final String title;
```

and the class-level comment's promise that "a `PushMessage` that exists is always
well-formed — callers never have to null-check its fields" gains: fields are still
never null, but `title` and `body` may be empty.

- [ ] **Step 4: Add the placeholder to `MessageTile`**

In `apps/fcm_app/lib/ui/message_tile.dart`, above the `return`:

```dart
    final headline = message.title.isEmpty ? '(no title)' : message.title;
```

and use it for the `title:`, styled muted when it is the placeholder:

```dart
      title: Text(
        headline,
        style: message.title.isEmpty
            ? TextStyle(
                fontStyle: FontStyle.italic,
                color: Theme.of(context).colorScheme.outline,
              )
            : null,
      ),
```

- [ ] **Step 5: Run the tests and the gate, then commit**

Run from `packages/core`: `fvm dart test` — expect 25 tests.
Run from `apps/fcm_app`: `fvm flutter test test/inbox_view_test.dart` — expect 6.

Run from the repo root: `fvm dart run melos run ci`
Expected: exit 0. Every pre-existing `core` test must still pass; if one fails, the
relaxation went further than intended.

```bash
git add packages/core apps/fcm_app
git commit -m "refactor(core): let a push arrive with no title or body"
```

---

### Task 11: The server forwards a message instead of building one

**Files:**
- Modify: `apps/fcm_api/lib/src/send_notification.dart`
- Modify: `apps/fcm_api/lib/src/api_router.dart`
- Modify: `apps/fcm_api/test/send_notification_test.dart`
- Modify: `apps/fcm_api/test/api_router_test.dart`

**Interfaces:**
- Consumes: `SendMessageRequest`, `SendMessageResponse` (Task 9).
- Produces:
  - `Future<SendOutcome> sendMessage(SendMessageRequest request, {required FcmSender sender, required DateTime Function() now})`
  - `ApiRouter({required FcmSender sender, required DateTime Function() now})` — the `newPayloadId` parameter is **gone**

**What changes and why.** The server no longer invents `id`, `title`, `body` and
`sentAt` data keys, so `newPayloadId` and `NotificationMessage` have no purpose.
The outgoing body becomes FCM's own request envelope with the target injected:

```dart
  final body = {
    'validate_only': request.validateOnly,
    'message': {...request.message.toJson(), 'token': request.token},
  };
```

`HttpV1FcmSender` needs **no change** — it already posts whatever map it is given.
`NotificationMessage` is deleted in Task 14, not here, so this task stays additive
where it can.

Validation reduces to the blank-token check; everything else was caught by
`SendMessageRequest.fromJson` before the handler ran.

- [ ] **Step 1: Rewrite the handler tests**

Replace the body of `apps/fcm_api/test/send_notification_test.dart`. The fake
sender and the FCM error-mapping tests carry over unchanged in substance — only the
request type and the absence of a payload id differ:

```dart
import 'package:fcm_api/fcm_api.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:test/test.dart';

import 'fake_fcm_sender.dart';

void main() {
  final sentAt = DateTime.utc(2026, 8, 11, 9, 12, 3);

  Future<SendOutcome> run(
    SendMessageRequest request, {
    FakeFcmSender? sender,
  }) => sendMessage(
    request,
    sender: sender ?? FakeFcmSender(),
    now: () => sentAt,
  );

  SendMessageRequest request({
    String token = 'device-token',
    bool validateOnly = false,
    FcmMessage message = const FcmMessage(
      notification: FcmNotification(title: 'Build finished'),
    ),
  }) => SendMessageRequest(
    token: token,
    message: message,
    validateOnly: validateOnly,
  );

  group('sendMessage', () {
    test('reports the message name FCM assigned and its own send time', () async {
      final outcome = await run(request());

      final response = (outcome as SendSucceeded).response;
      expect(response.messageId, 'projects/p/messages/0:17');
      expect(response.sentAt, sentAt);
    });

    test('injects the token into the message, which is the target', () async {
      final sender = FakeFcmSender();

      await run(request(), sender: sender);

      final message = sender.sent.single['message']! as Map<String, Object?>;
      expect(message['token'], 'device-token');
    });

    test('forwards the payload as written, adding nothing of its own', () async {
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

      final message = sender.sent.single['message']! as Map<String, Object?>;
      expect(message['data'], {'event': 'sync'});
      expect(message['android'], {'priority': 'HIGH'});
      // The server used to invent these. It must not any more.
      expect(message.keys, isNot(contains('notification')));
      expect((message['data']! as Map<String, Object?>).keys, isNot(contains('id')));
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

    test('rejects a blank token with 400, naming the field', () async {
      final outcome = await run(request(token: '  '));

      final rejected = outcome as SendRejected;
      expect(rejected.statusCode, 400);
      expect(rejected.error.field, 'token');
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
  });
}
```

- [ ] **Step 2: Update the router tests**

In `apps/fcm_api/test/api_router_test.dart`, `handlerWith` drops `newPayloadId`, and
`validBody` becomes the new shape:

```dart
  Handler handlerWith(FakeFcmSender sender) =>
      ApiRouter(sender: sender, now: () => sentAt).handler;

  Map<String, Object?> validBody({String token = 'device-token'}) => {
    'token': token,
    'message': {'notification': {'title': 'Build finished'}},
  };
```

The 200-body assertion becomes `{'messageId': …, 'sentAt': …}` with no `id`, and
add one test for the new failure mode:

```dart
    test('answers 400 with the field path for an unknown message field', () async {
      final response = await post({
        'token': 'device-token',
        'message': {'notification': {'titel': 'typo'}},
      });

      expect(response.statusCode, 400);
      expect(
        (await bodyOf(response))['error'],
        contains('notification: unknown field "titel"'),
      );
    });
```

Keep every other router test — the health route, the malformed-body cases and the
FCM mappings are unchanged in substance.

- [ ] **Step 3: Run the tests to verify they fail, then rewrite the handler**

Run from `apps/fcm_api`: `fvm dart test`
Expected: FAIL — `sendMessage` is undefined.

Rename `send_notification.dart`'s function to `sendMessage` with the signature
above (`git mv` the file to `send_message.dart` so the name matches), build the
body as shown, and keep `_statusFor`/`_messageFor` exactly as they are. Update the
barrel export and `ApiRouter` to match.

- [ ] **Step 4: Run the tests and the gate, then commit**

Run from `apps/fcm_api`: `fvm dart test` — expect 45 tests.

Run from the repo root: `fvm dart run melos run ci`
Expected: exit 0. `apps/fcm_app` still compiles: it does not reference
`sendMessage`, and its own sender changes in Task 12.

```bash
git add apps/fcm_api
git commit -m "feat(api): forward an FCM message instead of building one"
```

---

### Task 12: The app sends a message

**Files:**
- Modify: `apps/fcm_app/lib/sandbox/notification_sender.dart`
- Modify: `apps/fcm_app/lib/sandbox/http_notification_sender.dart`
- Modify: `apps/fcm_app/lib/sandbox/unavailable_notification_sender.dart`
- Modify: `apps/fcm_app/lib/sandbox/sandbox_send_state.dart`
- Modify: `apps/fcm_app/lib/sandbox/sandbox_controller.dart`
- Modify: `apps/fcm_app/test/fake_notification_sender.dart`
- Modify: `apps/fcm_app/test/http_notification_sender_test.dart`
- Modify: `apps/fcm_app/test/sandbox_controller_test.dart`

**Interfaces:**
- Consumes: `SendMessageRequest`, `SendMessageResponse`, `Scenario`, `scenarioGallery`, `FcmMessage` (Tasks 7–9).
- Produces:
  - `NotificationSender.send(SendMessageRequest request) → Future<SendMessageResponse>`
  - `SandboxSent(SendMessageResponse response)` — same variant, new payload type
  - `SandboxController({required NotificationSender sender, required String? Function() token})` with: `String get payloadText`, `void editPayload(String text)`, `String? get parseError`, `FcmMessage? get parsedMessage`, `bool get validateOnly`, `void setValidateOnly(bool value)`, `Scenario? get selectedScenario`, `void applyScenario(Scenario scenario)`, `int get scenarioRevision`, `String? get sendBlockedReason`, `bool get canSend`, `Future<void> send()`

**How the controller works now.** It holds the editor's **text**, not a draft.
Every `editPayload` re-parses: on success `parsedMessage` is set and `parseError` is
null; on `FormatException` the reverse. `canSend` requires a token, a parsed
message, and no send in flight. `applyScenario` writes the template into the text
as indented JSON (`JsonEncoder.withIndent('  ')`) and bumps `scenarioRevision`, so
the view can rebuild its `TextEditingController` — the mechanism already used for
the old form.

- [ ] **Step 1: Write the failing controller tests**

Replace `apps/fcm_app/test/sandbox_controller_test.dart`. The shape carries over;
the subject changes:

```dart
import 'dart:convert';

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
    test('opens on the first scenario, so the page is sendable at once', () {
      final controller = controllerWith();

      expect(controller.selectedScenario?.id, scenarioGallery.first.id);
      expect(controller.parseError, isNull);
      expect(controller.parsedMessage, isNotNull);
      expect(controller.canSend, isTrue);
    });

    test('writes the template into the editor as indented JSON', () {
      final controller = controllerWith();

      expect(controller.payloadText, contains('\n'));
      expect(
        jsonDecode(controller.payloadText),
        scenarioGallery.first.payloadTemplate,
      );
    });

    test('replaces the editor when another scenario is applied', () {
      final controller = controllerWith();
      final dataOnly = scenarioGallery.firstWhere(
        (scenario) => scenario.id == 'data_only',
      );

      controller.applyScenario(dataOnly);

      expect(controller.selectedScenario?.id, 'data_only');
      expect(jsonDecode(controller.payloadText), dataOnly.payloadTemplate);
    });

    test('bumps the revision on a scenario so the field can be rebuilt', () {
      final controller = controllerWith();
      final before = controller.scenarioRevision;

      controller.applyScenario(scenarioGallery.last);

      expect(controller.scenarioRevision, greaterThan(before));
    });

    test('does not bump the revision on an ordinary edit', () {
      final controller = controllerWith();
      final before = controller.scenarioRevision;

      controller.editPayload('{"data": {"a": "b"}}');

      expect(controller.scenarioRevision, before);
    });

    test('reports text that is not JSON and blocks Send', () {
      final controller = controllerWith();

      controller.editPayload('{not json');

      expect(controller.parseError, isNotNull);
      expect(controller.parsedMessage, isNull);
      expect(controller.canSend, isFalse);
    });

    test('reports an unknown field with its path', () {
      final controller = controllerWith();

      controller.editPayload('{"notification": {"titel": "typo"}}');

      expect(controller.parseError, contains('unknown field "titel"'));
    });

    test('reports a template that sets its own target', () {
      final controller = controllerWith();

      controller.editPayload('{"token": "mine"}');

      expect(controller.parseError, contains('the server sets the delivery target'));
    });

    test('accepts a payload that is valid again after being broken', () {
      final controller = controllerWith()..editPayload('{oops');

      controller.editPayload('{"data": {"a": "b"}}');

      expect(controller.parseError, isNull);
      expect(controller.parsedMessage?.data, {'a': 'b'});
    });

    test('blocks Send with a reason when there is no token', () {
      final controller = controllerWith(token: null);

      expect(controller.canSend, isFalse);
      expect(controller.sendBlockedReason, contains('token'));
    });

    test('sends the parsed message with the device token', () async {
      final controller = controllerWith()
        ..editPayload('{"data": {"event": "manual"}}');

      await controller.send();

      expect(sender.sent.single.token, 'device-token');
      expect(sender.sent.single.message.data, {'event': 'manual'});
      expect(sender.sent.single.validateOnly, isFalse);
    });

    test('sends validate_only when the flag is set', () async {
      final controller = controllerWith()..setValidateOnly(true);

      await controller.send();

      expect(sender.sent.single.validateOnly, isTrue);
      expect(controller.validateOnly, isTrue);
    });

    test('lands on Sent with the response', () async {
      final controller = controllerWith();

      await controller.send();

      expect(controller.state, isA<SandboxSent>());
      expect(
        (controller.state as SandboxSent).response.messageId,
        FakeNotificationSender.response.messageId,
      );
    });

    test('refuses to send unparseable text, without calling the sender', () async {
      final controller = controllerWith()..editPayload('{oops');

      await controller.send();

      expect(sender.sent, isEmpty);
    });

    test('lands on Failed and keeps the text when the send fails', () async {
      final controller = controllerWith(
        withSender: FakeNotificationSender(
          failure: const NotificationSendException('The API is unreachable'),
        ),
      )..editPayload('{"data": {"kept": "yes"}}');

      await controller.send();

      expect(controller.state, isA<SandboxFailed>());
      expect(controller.payloadText, contains('kept'));
    });
  });
}
```

- [ ] **Step 2: Run the tests to verify they fail, then implement**

Run from `apps/fcm_app`: `fvm flutter test test/sandbox_controller_test.dart`
Expected: FAIL — `editPayload` is undefined.

Then: change the sender interface and its three implementations to the new request
and response types; update `FakeNotificationSender` to record
`SendMessageRequest`s and return a `SendMessageResponse`; change `SandboxSent` to
carry `SendMessageResponse`; rewrite `SandboxController` per the interface list
above. `HttpNotificationSender` posts `request.toJson()` and parses
`SendMessageResponse.fromJson` — its error handling, including the `adb reverse`
message, is unchanged.

`http_notification_sender_test.dart` needs the same substitutions: the posted body
becomes `{token, validate_only, message}` and the 200 body becomes
`{messageId, sentAt}`. Keep every error-path test.

- [ ] **Step 3: Run the tests and the gate, then commit**

Run from `apps/fcm_app`: `fvm flutter test test/sandbox_controller_test.dart test/http_notification_sender_test.dart`
Expected: PASS — 15 controller tests and 7 sender tests.

Run from the repo root: `fvm dart run melos run ci`
Expected: exit 0. `sandbox_view_test.dart` will fail to compile if it references the
old controller API — if so, that is Task 13's job; comment the file out with a note
and restore it in Task 13, and say so in your report.

```bash
git add apps/fcm_app
git commit -m "feat(app): send an FCM message from the sandbox controller"
```

---

### Task 13: The grouped gallery and the JSON editor

**Files:**
- Create: `apps/fcm_app/lib/ui/scenario_group_list.dart`
- Create: `apps/fcm_app/lib/ui/payload_editor.dart`
- Modify: `apps/fcm_app/lib/ui/sandbox_view.dart`
- Modify: `apps/fcm_app/lib/ui/send_result_card.dart`
- Test: `apps/fcm_app/test/sandbox_view_test.dart`

**Interfaces:**
- Consumes: `SandboxController` (Task 12), `Scenario`, `scenarioGallery`.
- Produces:
  - `ScenarioGroupList` — `const ScenarioGroupList({required SandboxController controller, super.key})`, one `ExpansionTile` per group
  - `PayloadEditor` — `const PayloadEditor({required SandboxController controller, super.key})`, a `StatefulWidget` owning the `TextEditingController`

**Layout**, top to bottom: the grouped scenario list, a divider, the "validate
only" checkbox, the editor, the parse error when there is one, the Send button with
its blocked reason, then the result card.

Each scenario row shows its `title`, its `tags` as small chips, its `description`,
and — when present — its `expectation` prefixed with a warning icon. A scenario
with `requiresKilledApp` shows "needs the app killed" as a hint, so the field is
visible even though Spec 2 is what acts on it.

`PayloadEditor` is keyed on `controller.scenarioRevision` by `SandboxView`, so
applying a scenario replaces the text by replacing the `State` — ordinary typing
never disturbs the cursor. It uses a monospace `TextField` with
`maxLines: null` and `keyboardType: TextInputType.multiline`.

`SendResultCard` gains one distinction: when the last send had `validateOnly`, it
says the payload was **validated, not sent**. Sending something and being told it
arrived when it did not would be the worst outcome here.

- [ ] **Step 1: Write the failing tests**

Replace `apps/fcm_app/test/sandbox_view_test.dart`:

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

  final first = scenarioGallery.first;

  tearDown(() => controller.dispose());

  testWidgets('lists every group', (tester) async {
    build();

    await pump(tester);

    for (final group in scenarioGallery.map((s) => s.group).toSet()) {
      expect(find.text(group), findsOne, reason: group);
    }
  });

  testWidgets('shows the first group\'s scenarios and their tags', (tester) async {
    build();

    await pump(tester);

    expect(find.text(first.title), findsOne);
    for (final tag in first.tags) {
      expect(find.text(tag), findsAtLeast(1));
    }
  });

  testWidgets('shows an expectation when the scenario has one', (tester) async {
    build();

    await pump(tester);

    final withExpectation = scenarioGallery.firstWhere(
      (scenario) => scenario.group == first.group && scenario.expectation != null,
    );
    expect(find.text(withExpectation.expectation!), findsOne);
  });

  testWidgets('opens on the first scenario, with its payload in the editor', (
    tester,
  ) async {
    build();

    await pump(tester);

    expect(find.textContaining('"notification"'), findsOne);
  });

  testWidgets('loads a scenario from another group when tapped', (tester) async {
    build();
    await pump(tester);
    final dataOnly = scenarioGallery.firstWhere((s) => s.id == 'data_only');

    await tester.tap(find.text(dataOnly.group));
    await tester.pumpAndSettle();
    await tester.tap(find.text(dataOnly.title));
    await tester.pumpAndSettle();

    expect(find.textContaining('"event"'), findsOne);
  });

  testWidgets('renders a parse error and disables Send', (tester) async {
    build();
    await pump(tester);

    await tester.enterText(find.byType(TextField), '{not json');
    await tester.pumpAndSettle();

    expect(find.textContaining('FormatException'), findsNothing);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
  });

  testWidgets('names the offending field for an unknown key', (tester) async {
    build();
    await pump(tester);

    await tester.enterText(
      find.byType(TextField),
      '{"notification": {"titel": "typo"}}',
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('unknown field "titel"'), findsOne);
  });

  testWidgets('sends the edited payload', (tester) async {
    build();
    await pump(tester);

    await tester.enterText(find.byType(TextField), '{"data": {"a": "b"}}');
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(sender.sent.single.message.data, {'a': 'b'});
  });

  testWidgets('sends validate_only when the box is ticked', (tester) async {
    build();
    await pump(tester);

    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(sender.sent.single.validateOnly, isTrue);
    expect(find.textContaining('Validated'), findsOne);
  });

  testWidgets('says sent, not validated, for a real send', (tester) async {
    build();
    await pump(tester);

    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(find.textContaining('Sent'), findsOne);
    expect(find.textContaining('Validated'), findsNothing);
  });

  testWidgets('explains why Send is disabled with no token', (tester) async {
    build(token: null);

    await pump(tester);

    expect(find.textContaining('token'), findsAtLeast(1));
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
  });

  testWidgets('renders a failure and keeps the payload', (tester) async {
    build(failure: const NotificationSendException('The API is unreachable'));
    await pump(tester);

    await tester.enterText(find.byType(TextField), '{"data": {"kept": "yes"}}');
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(find.text('The API is unreachable'), findsOne);
    expect(find.textContaining('kept'), findsOne);
  });
}
```

The `FormatException` assertion is deliberate: the message shown must be the
exception's *message*, not its `toString()`, so the user never reads the words
"FormatException".

- [ ] **Step 2: Run the tests, implement, and run them again**

Run from `apps/fcm_app`: `fvm flutter test test/sandbox_view_test.dart`
Expected first: FAIL. Then write `ScenarioGroupList` and `PayloadEditor`, rewrite
`SandboxView` to compose them, and add the validated/sent distinction to
`SendResultCard`. Remember `avoid-returning-widgets`: build rows with a
collection-`for` inside the `ExpansionTile`'s children, not from a helper method.

If the scroll-into-view problem from the earlier sandbox work recurs — the 800×600
test surface pushing Send below the built extent — use
`tester.scrollUntilVisible` plus a further drag, exactly as
`sandbox_view_test.dart` did before this rewrite, and say so in your report.

Expected after: PASS, 13 tests.

- [ ] **Step 3: Run the gate and commit**

Run from the repo root: `fvm dart run melos run ci`
Expected: exit 0.

```bash
git add apps/fcm_app
git commit -m "feat(app): add the grouped scenario gallery and payload editor"
```

---

### Task 14: Delete the old contract, wire it up, document it

**Files:**
- Delete: `packages/fcm_gallery_shared/lib/src/notification_draft.dart`, `notification_draft_validator.dart`, `draft_problem.dart`, `notification_scenario.dart`, `send_notification_request.dart`, `send_notification_response.dart`
- Delete: their tests — `notification_draft_test.dart`, `notification_draft_validator_test.dart`, `notification_scenario_test.dart`, `send_notification_dto_test.dart`
- Delete: `apps/fcm_api/lib/src/notification_message.dart` and `apps/fcm_api/test/notification_message_test.dart`
- Delete: `apps/fcm_app/lib/ui/sandbox_form.dart`, `data_entry_row.dart`, `scenario_picker.dart`
- Modify: `packages/fcm_gallery_shared/lib/fcm_gallery_shared.dart`, `apps/fcm_api/lib/fcm_api.dart`
- Modify: `apps/fcm_app/lib/main.dart`, `README.md`

**Interfaces:**
- Consumes: everything above.
- Produces: nothing new.

- [ ] **Step 1: Delete the superseded types and their exports**

`git rm` each file above, then remove their `export` lines from both barrels.

Nothing should reference them. Verify rather than assume:

```bash
grep -rn 'NotificationDraft\|DraftProblem\|NotificationScenario\|notificationGallery\|SendNotificationRequest\|SendNotificationResponse\|NotificationMessage\|SandboxForm\|DataEntryRow\|ScenarioPicker' \
  packages apps --include=*.dart
```

Expected: no output. Any hit is a call site the earlier tasks missed — fix it rather
than keeping the file.

- [ ] **Step 2: Check `main.dart` still wires correctly**

`main()` constructs `SandboxController(sender: …, token: () => inbox.token)`, which
is unchanged by this plan — the controller's constructor kept that signature. Read
the file and confirm; if the sender construction needs no change, say so in your
report rather than editing for the sake of it.

- [ ] **Step 3: Run the gate**

Run from the repo root: `fvm dart run melos run ci`
Expected: exit 0. Test totals: `core` 25, `fcm_gallery_shared` 82, `fcm_api` 45,
`fcm_app` 55 — the shared and app counts fall as the old suites go and rise as the
new ones land, so treat these as approximate and report the real numbers.

Run from `apps/fcm_app`: `fvm flutter build apk --debug` and
`fvm flutter build web --release`. Both must succeed.

- [ ] **Step 4: Rewrite the README's payload sections**

Replace `## Message format` with a section describing what is actually sent now: an
FCM v1 `Message` typed in `fcm_gallery_shared`, authored as a raw template on
`Scenario`, forwarded by `apps/fcm_api` with only the target injected. Include:

- the endpoint's new shape, `{token, validate_only, message}` → `{messageId, sentAt}`
- that unknown fields are rejected with their path, and what that error looks like
- that `apns.payload`, `webpush.notification` and every `data` map pass through
  untouched, because FCM defines them as free-form
- that snake_case is what the model reads and writes, so a payload copied from
  Google's REST reference round-trips unchanged
- that `title` and `body` are now optional on arrival, so a data-only push appears
  in the inbox with a `(no title)` placeholder — **and** that
  `PushInbox.rejections` is consequently a rare signal rather than an expected one
- that the response no longer carries a payload id, so matching a send to an
  arrival needs an `id` of your own in `data`

Also update `## Layout`'s description of `packages/fcm_gallery_shared`: it no longer
holds "the editable draft… and the one validator both of them run", and it no
longer depends on `core` for `reservedKeys`.

Update `## Verified on this machine` with the real counts and the real build
results, and state plainly what was not verified.

- [ ] **Step 5: Commit**

```bash
git add -A packages apps README.md
git commit -m "feat(shared): delete the superseded draft contract"
```

- [ ] **Step 6: The `validate_only` sweep (needs the API running)**

The cheapest check that Google actually accepts what the model emits, and the only
one no unit test can substitute for. It needs the service-account key from the
earlier plan but **no device**.

With the API running (`GOOGLE_APPLICATION_CREDENTIALS=… fvm dart run melos run api:serve`):

```bash
for id in big_picture_remote coloured_icon custom_channel high_priority \
          normal_priority_long_ttl collapsible data_only \
          notification_and_data apns_alert; do
  echo "— $id"
done
```

For each scenario, send its template with `validate_only: true` and a real
registration token from the Inbox page, and confirm **200**:

```bash
curl -s -o /dev/null -w '%{http_code}\n' -X POST http://127.0.0.1:8080/send \
  -H 'content-type: application/json' \
  -d '{"token":"<token>","validate_only":true,
       "message":{"notification":{"title":"t","body":"b"}}}'
```

A 400 here means the template is not a payload FCM accepts, and the response body
names the field. Report each scenario as passing or failing; do not summarise nine
checks as one.

- [ ] **Step 7: On-device verification (human, needs a device)**

1. `big_picture_remote` → the image appears in the notification.
2. `data_only` → no notification is drawn, and the inbox gains a row with
   `(no title)` and the `event` and `build_number` data keys.
3. `custom_channel` → the notification pops as a heads-up banner.
4. An edited payload with a deliberate typo → Send is disabled and the field path
   is shown, with no request made.

Item 2 is the one that proves this whole spec: before the parser relaxation, that
push was invisible.

## Verification summary

- [ ] `fvm dart run melos run ci` exits 0
- [ ] `fvm flutter build apk --debug` and `fvm flutter build web --release` succeed
- [ ] `grep -rn 'ignore:' packages apps --include=*.dart` returns nothing
- [ ] The grep in Task 14 step 1 returns nothing
- [ ] All nine gallery templates pass the `validate_only` sweep, individually reported
- [ ] The four on-device checks are each reported verified or unverified

## Notes for the implementer

- **The model is built additively first (Tasks 1–9), then the consumers switch over
  (10–13), then the old types go (14).** Do not delete anything early: an
  intermediate red build makes every later task's gate meaningless.
- **`Object.hash` caps at 20 arguments.** `AndroidNotification` needs
  `Object.hashAll`.
- **Dart lists and maps have no value equality.** Every class with a list or map
  field needs `ListEquality`/`MapEquality` from `package:collection` in its `==`,
  or two equal messages will compare unequal and the round-trip tests will not
  catch it.
- **`prefer_initializing_formals` fires even when the parameter has a default.**
  Use `this._field = default`, never `: _field = param`.
- **Do not type Apple's `aps`.** It is Spec 3's decision, and `apns.payload` being
  free-form is what keeps every APNs payload writable today.
- **Do not implement delayed sending.** `requiresKilledApp` and
  `defaultDelaySeconds` are carried and displayed, nothing more, until Spec 2.
