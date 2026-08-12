# FCM Payload Form Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the Sandbox's raw JSON text field with nested, collapsible forms covering every property of an FCM v1 `Message`, built with `glade_forms`.

**Architecture:** Five reusable controls (collapsible section, tristate checkbox, enum dropdown, string-map rows, dotted-path rows) plus ten `GladeModel`s mirroring the ten typed FCM classes 1:1. Each model exposes `readFrom(typed?)` / `toModel()`, so the mapping is mechanical and testable without a widget pump. `SandboxController` swaps its text-and-parse-result for the models' own validity.

**Tech Stack:** Dart 3.12.2 (fvm-pinned), Flutter 3.44.8, `glade_forms ^6.0.0`, melos 8, DCM.

**Spec:** `docs/superpowers/specs/2026-08-11-fcm-payload-form-design.md`

**Branch:** continues on `feature/fcm-message-contract-impl`.

**Baseline, measured:** `melos run ci` exit 0 — core 20, `fcm_gallery_shared` 91, `fcm_api` 36, `fcm_app` 58.

## Global Constraints

Every task's requirements implicitly include this section.

- **Run everything through `fvm`.** There is no `dart` on PATH. `fvm flutter test <path>` from inside `apps/fcm_app`.
- **`fvm dart run melos run ci` from the repo root is the gate.** Check its **exit code**; it must exit 0 before any commit. It is also the **only** authority on test counts — report numbers measured from a command you ran. Every count estimate in this project's plans has been wrong at least once.
- If format:check complains, run `fvm dart run melos run format` from the repo root rather than hand-wrapping lines.
- **`glade_forms ^6.0.0` resolves** against this SDK (it needs `^3.10.0`) and pulls `provider`, `equatable`, `clock`, `netglade_utils`, `netglade_flutter_utils`. `sort_pub_dependencies` is fatal, so it sorts between `flutter` and `http` in `apps/fcm_app/pubspec.yaml`.
- **Three `glade_forms` defaults are the opposite of what this needs**, verified against the published API:
  - `GladeStringInput` defaults `isRequired: true` → **every** optional FCM string must pass `isRequired: false`.
  - `GladeIntInputNullable` defaults `useTextEditingController: false` → pass `true` to bind a `TextFormField`.
  - `GladeBoolInput` is `GladeInput<bool>` and cannot hold null → use `GladeInput<bool?>.optional(value: null)` for FCM's optional bools.
- **Every input takes an explicit `inputKey` equal to its FCM JSON path** (`android.notification.channel_id`), so a validation failure is traceable and the DevTools extension is readable.
- **A null field is absent from the payload, never null.** `toModel()` returns null when every input is empty, so an untouched block is omitted rather than sent as `{}`.
- **Fatal lints** (`--fatal-infos --fatal-warnings`): `prefer_single_quotes`, `require_trailing_commas`, `sort_pub_dependencies`, `prefer_final_locals`, `prefer_final_in_for_each`, `always_declare_return_types`, `unnecessary_parenthesis`, `unawaited_futures`, `use_super_parameters`, `cancel_subscriptions`, `close_sinks`, `avoid_print` (use `debugPrint`), `prefer_initializing_formals` (never `: _field = param` for a plain copy, **even with a default**), `use_null_aware_elements` (prefer `'key': ?value` and `...?list`).
- **Analyzer strictness:** `strict-casts`, `strict-inference`, `strict-raw-types` all on. No raw `Map`/`List` in a type position.
- **Fatal DCM metrics** in `apps/fcm_app` (it is **not** in `metrics-exclude`): `source-lines-of-code: 50` per function, `number-of-parameters: 5` (**counts `super.key`**), `maximum-nesting-level: 5`, `cyclomatic-complexity: 15`. The form *models* will need an exclusion — Task 6 adds `apps/fcm_app/lib/sandbox/forms/**` to `metrics-exclude`, for the same reason the typed model needed one: `AndroidNotificationForm` declares 27 inputs.
- **Fatal DCM rules:** `prefer-match-file-name`, `prefer-single-widget-per-file` (one *widget* class per file; a private `State` beside its `StatefulWidget` is fine), **`avoid-returning-widgets`** (no `Widget _buildFoo()` methods — build inline with collection-`for`, or extract a widget class), `always-remove-listener`, `use-setstate-synchronously`, `avoid-unused-parameters` (name a deliberately unused parameter `_`), `newline-before-return`, `prefer-trailing-comma`, `no-empty-block`.
- **Doc comments on every public declaration.** Say *why*, not *what*. For a form field, the *why* is what FCM or the OS does with it.
- **No `// ignore:` comments.** There are none in this repository and a review will reject one.
- **Commit style:** Conventional Commits, scope `app`.

## File Structure

**New — `apps/fcm_app/lib/sandbox/forms/`** (the models; excluded from DCM metrics by Task 6)

| File | Type | Mirrors |
| --- | --- | --- |
| `path_rows.dart` | `expandPaths` / `flattenPaths` top-level functions | the free-form islands |
| `fcm_notification_form.dart` | `FcmNotificationForm` | `FcmNotification` |
| `fcm_options_form.dart` | `FcmOptionsForm` | `FcmOptions` |
| `apns_fcm_options_form.dart` | `ApnsFcmOptionsForm` | `ApnsFcmOptions` |
| `webpush_fcm_options_form.dart` | `WebpushFcmOptionsForm` | `WebpushFcmOptions` |
| `light_settings_form.dart` | `LightSettingsForm` | `LightSettings` + `LightColor` |
| `android_notification_form.dart` | `AndroidNotificationForm` | `AndroidNotification` (27) |
| `android_config_form.dart` | `AndroidConfigForm` | `AndroidConfig` |
| `apns_config_form.dart` | `ApnsConfigForm` | `ApnsConfig` |
| `webpush_config_form.dart` | `WebpushConfigForm` | `WebpushConfig` |
| `fcm_message_form.dart` | `FcmMessageForm` | `FcmMessage` |

**New — `apps/fcm_app/lib/ui/form/`** (the reusable controls, one widget each)

| File | Widget |
| --- | --- |
| `form_section.dart` | `FormSection` — an `ExpansionTile` with an invalid badge |
| `tristate_field.dart` | `TristateField` — absent / true / false |
| `enum_field.dart` | `EnumField<E>` — a dropdown whose first entry is "not set" |
| `string_map_rows.dart` | `StringMapRows` — flat key/value rows |
| `path_rows_field.dart` | `PathRowsField` — dotted-path rows |
| `string_list_rows.dart` | `StringListRows` — ordered string rows |

**New — the section widgets**, one per model, in `apps/fcm_app/lib/ui/form/sections/`: `message_section.dart`, `notification_section.dart`, `android_section.dart`, `android_notification_section.dart`, `light_settings_section.dart`, `apns_section.dart`, `webpush_section.dart`, `fcm_options_section.dart`, `apns_fcm_options_section.dart`, `webpush_fcm_options_section.dart` — ten files, because the three `fcm_options` variants carry different fields and one widget per file is mandatory. Each renders one model's inputs inside a `FormSection`.

**Modified:** `apps/fcm_app/lib/sandbox/sandbox_controller.dart`, `apps/fcm_app/lib/ui/sandbox_view.dart`, `apps/fcm_app/pubspec.yaml`, `analysis_options.yaml`, `README.md`.

**Deleted, in Task 15:** `apps/fcm_app/lib/ui/payload_editor.dart` and its tests.

**Why the order is infrastructure → models → wiring.** Tasks 1–5 add controls nothing yet uses; Tasks 6–13 add models nothing yet renders; Task 14 renders them; Task 15 removes the JSON editor. Nothing existing breaks until Task 14, so the gate stays green throughout and each task is reviewable alone. This is the same shape that worked for the contract plan.

---

### Task 1: Add `glade_forms` and prove it works end to end

The smallest possible real form, so a dependency and API problem surfaces before ten models are built on it.

**Files:**
- Modify: `apps/fcm_app/pubspec.yaml`
- Create: `apps/fcm_app/test/glade_forms_smoke_test.dart`

**Interfaces:**
- Consumes: nothing.
- Produces: nothing. This task's output is knowledge — that the package resolves, and that its API behaves as the plan assumes.

**Why a smoke test rather than going straight to the real forms:** three of this package's defaults are the opposite of what this design needs, and the whole plan rests on `GladeInput<bool?>.optional` being able to hold null. Finding out otherwise on Task 8, with 27 fields written, would be expensive.

- [ ] **Step 1: Add the dependency**

In `apps/fcm_app/pubspec.yaml`, `dependencies:` — alphabetically between `flutter` and `http`:

```yaml
  flutter:
    sdk: flutter
  glade_forms: ^6.0.0
  http: ^1.6.0
```

Run from the repo root: `fvm dart pub get`
Expected: resolves. It needs `sdk: ^3.10.0` and this workspace is `^3.12.2`.

If resolution fails, **stop and report the conflict** — every later task depends on this and there is no workaround worth improvising.

- [ ] **Step 2: Write the smoke test**

`apps/fcm_app/test/glade_forms_smoke_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:glade_forms/glade_forms.dart';

/// A model exercising exactly the three input shapes this plan depends on.
class _SmokeModel extends GladeModel {
  late GladeStringInput text;
  late GladeInput<bool?> flag;
  late GladeIntInputNullable count;

  @override
  List<GladeInput<Object?>> get inputs => [text, flag, count];

  @override
  void initialize() {
    text = GladeStringInput(inputKey: 'text', isRequired: false);
    flag = GladeInput<bool?>.optional(inputKey: 'flag', value: null);
    count = GladeIntInputNullable(
      inputKey: 'count',
      useTextEditingController: true,
    );
    super.initialize();
  }
}

void main() {
  late _SmokeModel model;

  setUp(() {
    model = _SmokeModel()..initialize();
  });

  test('an optional string starts empty and leaves the model valid', () {
    // GladeStringInput defaults isRequired: true. If that default leaked
    // through, the model would be invalid here and ~50 FCM fields would each
    // need to be filled before anything could be sent.
    expect(model.text.value, isEmpty);
    expect(model.isValid, isTrue);
  });

  test('a nullable bool really holds three distinct states', () {
    // The whole tristate design rests on this. GladeBoolInput is
    // GladeInput<bool> and cannot do it.
    expect(model.flag.value, isNull);

    model.flag.updateValue(true);
    expect(model.flag.value, isTrue);

    model.flag.updateValue(false);
    expect(model.flag.value, isFalse);

    model.flag.updateValue(null);
    expect(model.flag.value, isNull);
  });

  test('a nullable int exposes a controller when asked for one', () {
    expect(model.count.controller, isNotNull);
    expect(model.count.value, isNull);
  });

  test('a nullable int reads back a typed value from its controller', () {
    model.count.controller!.text = '42';

    expect(model.count.value, 42);
  });

  test('clearing the int controller returns it to null, not to zero', () {
    model.count.controller!.text = '42';
    model.count.controller!.text = '';

    expect(model.count.value, isNull);
  });

  test('a string input exposes a controller by default', () {
    // GladeStringInput defaults useTextEditingController: true, unlike the
    // int input. Confirming rather than trusting the docs.
    expect(model.text.controller, isNotNull);
  });

  test('the model reports which inputs changed', () {
    model.text.updateValue('hello');

    expect(model.lastUpdatedInputKeys, contains('text'));
  });
}
```

- [ ] **Step 3: Run it**

Run from `apps/fcm_app`: `fvm flutter test test/glade_forms_smoke_test.dart`
Expected: PASS, 7 tests.

**One likely wrinkle before you conclude the API is broken.** `glade_forms` reads a
value out of its `TextEditingController` by listening to it, and a listener may fire
in a microtask rather than synchronously. If `count.value` is still null immediately
after setting `controller.text`, add `await Future<void>.delayed(Duration.zero)`
before the assertion and make the test `async` — that is a test-harness detail, not
a broken package. Say in your report whether it was needed.

**Any other failure here is a finding, not an obstacle.** Report exactly which assumption broke and what the API does instead — the design depends on all seven, and the remaining tasks would need reshaping. Do not work around a failure by changing the design yourself.

- [ ] **Step 4: Run the gate and commit**

Run from the repo root: `fvm dart run melos run ci`
Expected: exit 0.

```bash
git add apps/fcm_app pubspec.lock
git commit -m "feat(app): add glade_forms and pin down its behaviour"
```

---

### Task 2: `FormSection`, the collapsible with a badge

**Files:**
- Create: `apps/fcm_app/lib/ui/form/form_section.dart`
- Test: `apps/fcm_app/test/ui/form/form_section_test.dart`

**Interfaces:**
- Consumes: nothing.
- Produces: `FormSection` — `const FormSection({required String title, required bool isValid, required List<Widget> children, String? subtitle, super.key})`

**Why the badge matters:** with four nesting levels and ten sections, an invalid
field can sit behind a collapsed header where nothing shows it. A section that is
collapsed *and* invalid must say so, or Send is disabled for a reason the user
cannot see.

Five parameters including `super.key` is exactly at DCM's limit — do not add a
sixth.

- [ ] **Step 1: Write the failing test**

`apps/fcm_app/test/ui/form/form_section_test.dart`:

```dart
import 'package:fcm_app/ui/form/form_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pump(
    WidgetTester tester, {
    required bool isValid,
    bool expanded = false,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FormSection(
            title: 'Android',
            isValid: isValid,
            children: const [Text('a field')],
          ),
        ),
      ),
    );
    if (expanded) {
      await tester.tap(find.text('Android'));
      await tester.pumpAndSettle();
    }
  }

  testWidgets('starts collapsed, so ten sections do not fill the screen', (
    tester,
  ) async {
    await pump(tester, isValid: true);

    expect(find.text('a field'), findsNothing);
  });

  testWidgets('reveals its children when tapped', (tester) async {
    await pump(tester, isValid: true, expanded: true);

    expect(find.text('a field'), findsOne);
  });

  testWidgets('shows no badge while valid', (tester) async {
    await pump(tester, isValid: true);

    expect(find.byIcon(Icons.error_outline), findsNothing);
  });

  testWidgets('badges an invalid section, so an error cannot hide collapsed', (
    tester,
  ) async {
    await pump(tester, isValid: false);

    expect(find.byIcon(Icons.error_outline), findsOne);
  });

  testWidgets('keeps the badge while expanded', (tester) async {
    await pump(tester, isValid: false, expanded: true);

    expect(find.byIcon(Icons.error_outline), findsOne);
    expect(find.text('a field'), findsOne);
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run from `apps/fcm_app`: `fvm flutter test test/ui/form/form_section_test.dart`
Expected: FAIL — `Target of URI doesn't exist: 'package:fcm_app/ui/form/form_section.dart'`.

- [ ] **Step 3: Write it**

`apps/fcm_app/lib/ui/form/form_section.dart`:

```dart
import 'package:flutter/material.dart';

/// One collapsible object of the payload.
///
/// The payload nests four levels deep across ten objects, so every section
/// starts closed — otherwise the page is unusable on arrival, which is exactly
/// the defect that moved the gallery to its own page.
///
/// [isValid] drives a badge on the header. Without it an invalid field could sit
/// behind a closed section, disabling Send for a reason the user cannot see.
class FormSection extends StatelessWidget {
  const FormSection({
    required this.title,
    required this.isValid,
    required this.children,
    this.subtitle,
    super.key,
  });

  /// The FCM object this section edits, in its own words — `android`, `apns`.
  final String title;

  /// Whether every input inside is currently valid.
  final bool isValid;

  /// What this object is for, when the name alone is not obvious.
  final String? subtitle;

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => ExpansionTile(
    title: Text(title),
    subtitle: subtitle == null ? null : Text(subtitle!),
    trailing: isValid
        ? null
        : Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
    childrenPadding: const EdgeInsets.only(left: 16, bottom: 8),
    expandedCrossAxisAlignment: CrossAxisAlignment.start,
    children: children,
  );
}
```

`trailing: null` keeps `ExpansionTile`'s own rotating chevron when valid; supplying
a trailing widget replaces it, which is why the badge only appears when it must.

- [ ] **Step 4: Run the test, the gate, and commit**

Run from `apps/fcm_app`: `fvm flutter test test/ui/form/form_section_test.dart`
Expected: PASS, 5 tests.

Run from the repo root: `fvm dart run melos run ci`
Expected: exit 0.

```bash
git add apps/fcm_app
git commit -m "feat(app): add the collapsible form section"
```

---

### Task 3: The dotted-path functions

The trickiest logic in this plan, and pure — so it is written and tested with no
widget in sight.

**Files:**
- Create: `apps/fcm_app/lib/sandbox/forms/path_rows.dart`
- Test: `apps/fcm_app/test/sandbox/forms/path_rows_test.dart`

**Interfaces:**
- Consumes: nothing.
- Produces:
  - `Map<String, Object?> expandPaths(List<MapEntry<String, String>> rows)`
  - `List<MapEntry<String, String>> flattenPaths(Map<String, Object?> source)`

**What these are for.** `apns.payload` and `webpush.notification` are free-form by
FCM's definition, so no form can enumerate their fields. They are edited as rows
whose key is a **dotted path**: `aps.alert.title` → `Build finished`.

Three things make this more than a string split:

1. **A numeric segment is a list index.** `aps.alert.loc-args.0` builds a `List`,
   not a `Map`. Apple's `loc-args` and `title-loc-args` really are arrays; without
   this they would flatten to the text `[a, b]` and expand back as a string,
   corrupting the payload rather than merely failing to edit it.
2. **Values are parsed leniently.** `badge` is a number and `content-available` is
   `0`/`1`. Treating every value as a string would send wrong payloads.
3. **A blank path is dropped**, so an empty row never produces an empty key.

- [ ] **Step 1: Write the failing test**

`apps/fcm_app/test/sandbox/forms/path_rows_test.dart`:

```dart
import 'package:fcm_app/sandbox/forms/path_rows.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  List<MapEntry<String, String>> rows(Map<String, String> from) =>
      from.entries.toList();

  group('expandPaths', () {
    test('nests a dotted path', () {
      expect(expandPaths(rows({'aps.alert.title': 'Hi'})), {
        'aps': {
          'alert': {'title': 'Hi'},
        },
      });
    });

    test('merges rows sharing a prefix', () {
      expect(
        expandPaths(rows({'aps.alert.title': 'Hi', 'aps.badge': '1'})),
        {
          'aps': {
            'alert': {'title': 'Hi'},
            'badge': 1,
          },
        },
      );
    });

    test('keeps a single segment at the top level', () {
      expect(expandPaths(rows({'custom': 'value'})), {'custom': 'value'});
    });

    test('reads an integer as a number, since badge is one', () {
      expect(expandPaths(rows({'aps.badge': '3'}))['aps'], {'badge': 3});
    });

    test('reads true and false as booleans', () {
      final expanded = expandPaths(
        rows({'a': 'true', 'b': 'false', 'c': 'True'}),
      );

      expect(expanded['a'], isTrue);
      expect(expanded['b'], isFalse);
      // Only the JSON spellings convert; anything else is text.
      expect(expanded['c'], 'True');
    });

    test('leaves anything else as text', () {
      expect(expandPaths(rows({'a': '1.5'}))['a'], '1.5');
      expect(expandPaths(rows({'b': 'hello'}))['b'], 'hello');
    });

    test('builds a list from numeric segments', () {
      expect(
        expandPaths(
          rows({'aps.alert.loc-args.0': 'first', 'aps.alert.loc-args.1': 'second'}),
        ),
        {
          'aps': {
            'alert': {'loc-args': ['first', 'second']},
          },
        },
      );
    });

    test('drops a blank path rather than making an empty key', () {
      expect(expandPaths(rows({'  ': 'orphan', 'kept': 'yes'})), {'kept': 'yes'});
    });

    test('lets a later row win when two share a path', () {
      expect(
        expandPaths([
          const MapEntry('a', 'first'),
          const MapEntry('a', 'second'),
        ]),
        {'a': 'second'},
      );
    });

    test('returns an empty map for no rows', () {
      expect(expandPaths(const []), isEmpty);
    });
  });

  group('flattenPaths', () {
    test('walks a nested map into dotted rows', () {
      final flat = flattenPaths({
        'aps': {
          'alert': {'title': 'Hi'},
          'badge': 1,
        },
      });

      expect(flat.map((row) => '${row.key}=${row.value}'), [
        'aps.alert.title=Hi',
        'aps.badge=1',
      ]);
    });

    test('indexes list elements', () {
      final flat = flattenPaths({
        'aps': {
          'alert': {'loc-args': ['first', 'second']},
        },
      });

      expect(flat.map((row) => row.key), [
        'aps.alert.loc-args.0',
        'aps.alert.loc-args.1',
      ]);
    });

    test('returns nothing for an empty map', () {
      expect(flattenPaths(const {}), isEmpty);
    });
  });

  group('round trips', () {
    test('a realistic APNs payload survives expand after flatten', () {
      const payload = {
        'aps': {
          'alert': {
            'title': 'Build finished',
            'body': 'Release 1.0.0 is ready.',
            'loc-args': ['1.0.0'],
          },
          'badge': 1,
          'sound': 'default',
          'content-available': 1,
          'thread-id': 'builds',
        },
        'custom_key': 'kept',
      };

      expect(expandPaths(flattenPaths(payload)), payload);
    });

    test('rows survive flatten after expand', () {
      final original = rows({
        'aps.alert.title': 'Hi',
        'aps.badge': '1',
        'top': 'level',
      });

      final round = flattenPaths(expandPaths(original));

      expect(
        round.map((row) => '${row.key}=${row.value}'),
        original.map((row) => '${row.key}=${row.value}'),
      );
    });
  });
}
```

The first round-trip test is the one that matters: it is the `apns_alert`
scenario's actual payload shape, and if it fails the iOS scenario is not editable.

- [ ] **Step 2: Run the test to verify it fails**

Run from `apps/fcm_app`: `fvm flutter test test/sandbox/forms/path_rows_test.dart`
Expected: FAIL — `Undefined name 'expandPaths'`.

- [ ] **Step 3: Write the functions**

`apps/fcm_app/lib/sandbox/forms/path_rows.dart`:

```dart
/// Expands dotted-path rows into the nested structure FCM and Apple expect.
///
/// `apns.payload` and `webpush.notification` are free-form by FCM's own
/// definition, so they are edited as rows rather than as fields. A path builds
/// the nesting: `aps.alert.title` becomes
/// `{'aps': {'alert': {'title': …}}}`.
///
/// A **numeric** segment builds a list rather than a map, because Apple's
/// `loc-args` and `title-loc-args` are string arrays — without this they would
/// round-trip into the literal text `[a, b]`.
///
/// A blank path is dropped, so a half-typed row never produces an empty key.
Map<String, Object?> expandPaths(List<MapEntry<String, String>> rows) {
  final result = <String, Object?>{};

  for (final row in rows) {
    final segments = row.key.trim().split('.');
    if (segments.any((segment) => segment.isEmpty)) {
      continue;
    }
    _place(result, segments, _scalarOf(row.value));
  }

  return result;
}

/// Flattens a nested structure back into the rows the editor shows, so a
/// scenario's payload arrives as something editable and leaves unchanged.
List<MapEntry<String, String>> flattenPaths(Map<String, Object?> source) {
  final rows = <MapEntry<String, String>>[];
  _walk('', source, rows);

  return rows;
}

/// Reads a row's text as the JSON scalar it looks like.
///
/// `badge` is a number and `content-available` is 0 or 1, so treating every
/// value as text would produce payloads APNs rejects or misreads. Only the JSON
/// spellings of true and false convert; everything else stays text, including
/// decimals, which Apple does not use here and which would otherwise lose their
/// exact form.
Object? _scalarOf(String value) => switch (value) {
  'true' => true,
  'false' => false,
  _ => int.tryParse(value) ?? value,
};

/// Whether [segment] addresses a list index rather than a map key.
bool _isIndex(String segment) => int.tryParse(segment) != null;

void _place(Map<String, Object?> root, List<String> segments, Object? value) {
  Object? node = root;

  for (var index = 0; index < segments.length - 1; index++) {
    node = _childOf(node, segments[index], _isIndex(segments[index + 1]));
  }

  _set(node, segments.last, value);
}

/// Returns the container at [segment], creating it when absent.
///
/// [nextIsIndex] decides whether a missing container becomes a list or a map,
/// which is the only place the numeric-segment rule takes effect.
Object? _childOf(Object? node, String segment, bool nextIsIndex) {
  final existing = _get(node, segment);
  if (existing is Map<String, Object?> || existing is List<Object?>) {
    return existing;
  }

  final child = nextIsIndex ? <Object?>[] : <String, Object?>{};
  _set(node, segment, child);

  return child;
}

Object? _get(Object? node, String segment) => switch (node) {
  final Map<String, Object?> map => map[segment],
  final List<Object?> list => _isIndex(segment) && int.parse(segment) < list.length
      ? list[int.parse(segment)]
      : null,
  _ => null,
};

void _set(Object? node, String segment, Object? value) {
  if (node is Map<String, Object?>) {
    node[segment] = value;

    return;
  }
  if (node is List<Object?> && _isIndex(segment)) {
    final index = int.parse(segment);
    while (node.length <= index) {
      node.add(null);
    }
    node[index] = value;
  }
}

void _walk(
  String prefix,
  Object? node,
  List<MapEntry<String, String>> rows,
) {
  switch (node) {
    case final Map<String, Object?> map:
      for (final entry in map.entries) {
        _walk(_join(prefix, entry.key), entry.value, rows);
      }
    case final List<Object?> list:
      for (final (index, item) in list.indexed) {
        _walk(_join(prefix, '$index'), item, rows);
      }
    default:
      rows.add(MapEntry(prefix, '$node'));
  }
}

String _join(String prefix, String segment) =>
    prefix.isEmpty ? segment : '$prefix.$segment';
```

Note `expandPaths` rejects a path with *any* empty segment, not just a blank one —
`a..b` is as malformed as `  `, and both are typos rather than intent.

- [ ] **Step 4: Run the test, the gate, and commit**

Run from `apps/fcm_app`: `fvm flutter test test/sandbox/forms/path_rows_test.dart`
Expected: PASS, 15 tests.

Run from the repo root: `fvm dart run melos run ci`
Expected: exit 0.

```bash
git add apps/fcm_app
git commit -m "feat(app): add dotted-path expansion for free-form payloads"
```

---

### Task 4: `TristateField` and `EnumField`

The two controls that exist because FCM distinguishes **absent** from a value.

**Files:**
- Create: `apps/fcm_app/lib/ui/form/tristate_field.dart`
- Create: `apps/fcm_app/lib/ui/form/enum_field.dart`
- Test: `apps/fcm_app/test/ui/form/tristate_field_test.dart`
- Test: `apps/fcm_app/test/ui/form/enum_field_test.dart`

**Interfaces:**
- Consumes: `GladeInput` (Task 1).
- Produces:
  - `TristateField` — `const TristateField({required String label, required GladeInput<bool?> input, super.key})`
  - `EnumField<E>` — `const EnumField({required String label, required GladeInput<E?> input, required List<E> values, required String Function(E) labelOf, super.key})` (5 params including `super.key` — at DCM's limit, do not add a sixth)

**Why tristate at all.** `direct_boot_ok: false` and omitting `direct_boot_ok` are
different messages to FCM, and the typed model encodes that with a nullable field.
A `Checkbox` has two states, so using one would make "absent" unreachable and
silently send fields the user never set — a change in delivery behaviour with
nothing on screen to explain it. Flutter's `Checkbox` supports `tristate: true`,
which cycles false → true → null.

`EnumField` has the same problem in a different shape: its first dropdown entry is
"Not set", mapping to null.

- [ ] **Step 1: Write the failing tests**

`apps/fcm_app/test/ui/form/tristate_field_test.dart`:

```dart
import 'package:fcm_app/ui/form/tristate_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glade_forms/glade_forms.dart';

class _Model extends GladeModel {
  late GladeInput<bool?> flag;

  @override
  List<GladeInput<Object?>> get inputs => [flag];

  @override
  void initialize() {
    flag = GladeInput<bool?>.optional(inputKey: 'flag', value: null);
    super.initialize();
  }
}

void main() {
  late _Model model;

  setUp(() {
    model = _Model()..initialize();
  });

  Future<void> pump(WidgetTester tester) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: TristateField(label: 'Direct boot ok', input: model.flag),
      ),
    ),
  );

  testWidgets('starts unset, which is not the same as false', (tester) async {
    await pump(tester);

    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isNull);
    expect(model.flag.value, isNull);
  });

  testWidgets('is tristate, so absent stays reachable', (tester) async {
    await pump(tester);

    expect(tester.widget<Checkbox>(find.byType(Checkbox)).tristate, isTrue);
  });

  testWidgets('shows its label, since a bare checkbox says nothing', (
    tester,
  ) async {
    await pump(tester);

    expect(find.text('Direct boot ok'), findsOne);
  });

  testWidgets('writes each of the three states back to the input', (
    tester,
  ) async {
    await pump(tester);

    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    final first = model.flag.value;

    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    final second = model.flag.value;

    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    final third = model.flag.value;

    // Whatever order Flutter cycles them in, all three must be visited.
    expect({first, second, third}, {null, true, false});
  });

  testWidgets('reflects a value set on the input from elsewhere', (
    tester,
  ) async {
    model.flag.updateValue(true);

    await pump(tester);

    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);
  });
}
```

`apps/fcm_app/test/ui/form/enum_field_test.dart` follows the same shape, over
`AndroidMessagePriority` from `package:fcm_gallery_shared/fcm_gallery_shared.dart`:

```dart
  testWidgets('offers a not-set entry plus every value', (tester) async {
    await pump(tester);
    await tester.tap(find.byType(DropdownButtonFormField<AndroidMessagePriority?>));
    await tester.pumpAndSettle();

    expect(find.text('Not set'), findsAtLeast(1));
    expect(find.text('NORMAL'), findsOne);
    expect(find.text('HIGH'), findsOne);
  });
```

plus: starts null; selecting a value writes it to the input; selecting "Not set"
writes null; a value set from elsewhere is displayed. Five tests, labelled by
`wireName` so what the dropdown shows is what goes on the wire.

- [ ] **Step 2: Run them to verify they fail**

Run from `apps/fcm_app`: `fvm flutter test test/ui/form/`
Expected: FAIL — the two URIs do not exist.

- [ ] **Step 3: Write `TristateField`**

```dart
import 'package:flutter/material.dart';
import 'package:glade_forms/glade_forms.dart';

/// A checkbox for an FCM field that may be true, false, or **absent**.
///
/// FCM treats `direct_boot_ok: false` and an omitted `direct_boot_ok` as
/// different messages, so a two-state checkbox would make "absent" unreachable
/// and silently send fields nobody set. `tristate` is what keeps null a state
/// the user can choose.
class TristateField extends StatelessWidget {
  const TristateField({required this.label, required this.input, super.key});

  /// The field's name, as FCM spells it.
  final String label;

  final GladeInput<bool?> input;

  @override
  Widget build(BuildContext context) => CheckboxListTile(
    contentPadding: EdgeInsets.zero,
    controlAffinity: ListTileControlAffinity.leading,
    tristate: true,
    value: input.value,
    title: Text(label),
    subtitle: input.value == null ? const Text('Not sent') : null,
    onChanged: input.updateValue,
  );
}
```

`subtitle` naming the unset state matters: a null tristate checkbox renders as a
dash, which most people read as "off" rather than "absent".

- [ ] **Step 4: Write `EnumField`**

Same shape, wrapping a `DropdownButtonFormField<E?>` whose items are
`[null, ...values]` with null shown as `Not set`, `onChanged: input.updateValue`,
and `labelOf` supplying each entry's text — pass `(value) => value.wireName` at
every call site so the dropdown shows FCM's own spelling.

- [ ] **Step 5: Run the tests, the gate, and commit**

Run from `apps/fcm_app`: `fvm flutter test test/ui/form/`
Expected: PASS — 5 tristate tests, 5 enum tests, 5 section tests from Task 2.

Run from the repo root: `fvm dart run melos run ci`
Expected: exit 0.

```bash
git add apps/fcm_app
git commit -m "feat(app): add tristate and enum form controls"
```

---

### Task 5: The three row editors

**Files:**
- Create: `apps/fcm_app/lib/ui/form/string_map_rows.dart`
- Create: `apps/fcm_app/lib/ui/form/string_list_rows.dart`
- Create: `apps/fcm_app/lib/ui/form/path_rows_field.dart`
- Test: `apps/fcm_app/test/ui/form/row_editors_test.dart`

**Interfaces:**
- Consumes: `expandPaths` / `flattenPaths` (Task 3).
- Produces, each a `StatefulWidget` owning its rows' `TextEditingController`s:
  - `StringMapRows` — `const StringMapRows({required String label, required Map<String, String> value, required ValueChanged<Map<String, String>> onChanged, super.key})`
  - `StringListRows` — same shape over `List<String>`
  - `PathRowsField` — same shape over `Map<String, Object?>`, converting through `flattenPaths`/`expandPaths`

**Why these own controllers rather than binding `GladeInput`s.** The number of rows
is not known ahead of time, so there is no fixed input to bind — the rows are view
state, and the collapsed value goes to the model through `onChanged`. That is the
same reasoning that kept `TextEditingController`s out of `SandboxController`.

**Dispose every controller.** Each row holds two (or one, for the list), and
removing a row must dispose its controllers rather than orphan them.

- [ ] **Step 1: Write the failing test**

`apps/fcm_app/test/ui/form/row_editors_test.dart` — the three widgets share one
file because they share one shape. Cover, for `StringMapRows`:

```dart
  testWidgets('starts with no rows when the value is empty', (tester) async {
    await pumpMap(tester, const {});

    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('renders a row per entry', (tester) async {
    await pumpMap(tester, const {'event': 'build_finished'});

    expect(find.widgetWithText(TextField, 'event'), findsOne);
    expect(find.widgetWithText(TextField, 'build_finished'), findsOne);
  });

  testWidgets('reports a new row', (tester) async {
    await pumpMap(tester, const {});

    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'k');
    await tester.enterText(find.byType(TextField).last, 'v');

    expect(lastValue, {'k': 'v'});
  });

  testWidgets('reports a removal', (tester) async {
    await pumpMap(tester, const {'a': '1', 'b': '2'});

    await tester.tap(find.byIcon(Icons.remove_circle_outline).first);
    await tester.pumpAndSettle();

    expect(lastValue, {'b': '2'});
  });

  testWidgets('drops a row with a blank key', (tester) async {
    await pumpMap(tester, const {});

    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'orphan');

    expect(lastValue, isEmpty);
  });
```

For `PathRowsField`, the tests that matter are the two conversions:

```dart
  testWidgets('shows a nested payload as dotted rows', (tester) async {
    await pumpPaths(tester, const {
      'aps': {'alert': {'title': 'Hi'}, 'badge': 1},
    });

    expect(find.widgetWithText(TextField, 'aps.alert.title'), findsOne);
    expect(find.widgetWithText(TextField, 'aps.badge'), findsOne);
  });

  testWidgets('reports an edited row as nested structure', (tester) async {
    await pumpPaths(tester, const {});

    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'aps.badge');
    await tester.enterText(find.byType(TextField).last, '2');

    expect(lastPaths, {'aps': {'badge': 2}});
  });
```

And for `StringListRows`: empty, one row per item, add, remove, and that a blank
entry is dropped.

- [ ] **Step 2: Run it, implement, run it again**

Run from `apps/fcm_app`: `fvm flutter test test/ui/form/row_editors_test.dart`
Expected first: FAIL. Then write the three widgets: a `Column` of rows built with a
collection-`for` (never a `Widget _buildRow()` — `avoid-returning-widgets` is
fatal), an "Add" `TextButton`, and a remove `IconButton` per row using
`Icons.remove_circle_outline`. Rows are held in a private class pairing the
controllers, as `SandboxForm` did before it was deleted — check
`git show 9875cd7 -- apps/fcm_app/lib/ui/sandbox_form.dart` for that shape.

Expected after: PASS.

- [ ] **Step 3: Run the gate and commit**

Run from the repo root: `fvm dart run melos run ci`
Expected: exit 0.

```bash
git add apps/fcm_app
git commit -m "feat(app): add the map, list and path row editors"
```

---

### Task 6: `metrics-exclude`, and the four leaf forms

Establishes the model pattern the next five tasks copy.

**Files:**
- Modify: `analysis_options.yaml`
- Create: `apps/fcm_app/lib/sandbox/forms/fcm_notification_form.dart`
- Create: `apps/fcm_app/lib/sandbox/forms/fcm_options_form.dart`
- Create: `apps/fcm_app/lib/sandbox/forms/apns_fcm_options_form.dart`
- Create: `apps/fcm_app/lib/sandbox/forms/webpush_fcm_options_form.dart`
- Test: `apps/fcm_app/test/sandbox/forms/leaf_forms_test.dart`

**Interfaces:**
- Consumes: `glade_forms`; `FcmNotification`, `FcmOptions`, `ApnsFcmOptions`, `WebpushFcmOptions` from `package:fcm_gallery_shared/fcm_gallery_shared.dart`.
- Produces four `GladeModel`s, each with `void readFrom(T? source)` and `T? toModel()`.

**The pattern, written out for `FcmNotificationForm`:**

```dart
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:glade_forms/glade_forms.dart';

/// Edits FCM's cross-platform `notification` block.
///
/// Mirrors [FcmNotification] one-for-one, so the mapping in both directions is
/// mechanical and this can be tested without pumping a widget.
class FcmNotificationForm extends GladeModel {
  late GladeStringInput title;
  late GladeStringInput body;
  late GladeStringInput image;

  @override
  List<GladeInput<Object?>> get inputs => [title, body, image];

  @override
  void initialize() {
    // isRequired: false on every one of them — GladeStringInput defaults to
    // required, and FCM has no required fields in this block.
    title = GladeStringInput(inputKey: 'notification.title', isRequired: false);
    body = GladeStringInput(inputKey: 'notification.body', isRequired: false);
    image = GladeStringInput(inputKey: 'notification.image', isRequired: false);
    super.initialize();
  }

  /// Fills the inputs from [source], clearing them when it is null.
  void readFrom(FcmNotification? source) {
    title.updateValue(source?.title ?? '');
    body.updateValue(source?.body ?? '');
    image.updateValue(source?.image ?? '');
  }

  /// The block as FCM's model, or null when nothing is set.
  ///
  /// Null rather than an empty object, so an untouched block is omitted from the
  /// payload instead of being sent as `"notification": {}`.
  FcmNotification? toModel() {
    final result = FcmNotification(
      title: _orNull(title.value),
      body: _orNull(body.value),
      image: _orNull(image.value),
    );

    return result == const FcmNotification() ? null : result;
  }
}

/// Empty text means the field is absent, not that it is an empty string.
String? _orNull(String value) => value.isEmpty ? null : value;
```

The `result == const FcmNotification()` check is why Spec 1 gave every model value
equality: "is anything set?" is exactly "does this differ from the empty one?", and
asking it that way cannot drift out of step as fields are added.

The other three follow identically:

| Form | Inputs (`inputKey` → field) |
| --- | --- |
| `FcmOptionsForm` | `fcm_options.analytics_label` → `analyticsLabel` |
| `ApnsFcmOptionsForm` | `apns.fcm_options.image` → `image`, `apns.fcm_options.analytics_label` → `analyticsLabel` |
| `WebpushFcmOptionsForm` | `webpush.fcm_options.link` → `link`, `webpush.fcm_options.analytics_label` → `analyticsLabel` |

- [ ] **Step 1: Widen `metrics-exclude`**

In `analysis_options.yaml`, add to the existing list:

```yaml
    # Form models mirroring the FCM Message API. AndroidNotificationForm declares
    # 27 inputs, so number-of-parameters and source-lines-of-code cannot apply
    # for the same reason they cannot apply to the typed model itself.
    - apps/fcm_app/lib/sandbox/forms/**
```

- [ ] **Step 2: Write the failing test**

`apps/fcm_app/test/sandbox/forms/leaf_forms_test.dart`, per form:

```dart
  group('FcmNotificationForm', () {
    test('is valid while empty, since FCM requires nothing here', () {
      final form = FcmNotificationForm()..initialize();

      expect(form.isValid, isTrue);
    });

    test('returns null when nothing is set, so the block is omitted', () {
      final form = FcmNotificationForm()..initialize();

      expect(form.toModel(), isNull);
    });

    test('round-trips a populated block', () {
      const source = FcmNotification(
        title: 'Build finished',
        body: 'Ready.',
        image: 'https://example.test/a.png',
      );
      final form = FcmNotificationForm()..initialize();

      form.readFrom(source);

      expect(form.toModel(), source);
    });

    test('omits a field left empty rather than sending a blank string', () {
      final form = FcmNotificationForm()..initialize();

      form.readFrom(const FcmNotification(title: 'Only a title'));

      expect(form.toModel(), const FcmNotification(title: 'Only a title'));
      expect(form.toModel()!.body, isNull);
    });

    test('clears every input when read from null', () {
      final form = FcmNotificationForm()..initialize();
      form.readFrom(const FcmNotification(title: 'set'));

      form.readFrom(null);

      expect(form.toModel(), isNull);
    });
  });
```

The same five for each of the other three.

- [ ] **Step 3: Run it, implement, run it again**

Run from `apps/fcm_app`: `fvm flutter test test/sandbox/forms/leaf_forms_test.dart`
Expected first: FAIL. Then write the four models. Expected after: PASS, 20 tests.

- [ ] **Step 4: Run the gate and commit**

Run from the repo root: `fvm dart run melos run ci`
Expected: exit 0. If DCM complains about a form model, the exclusion path is wrong
— fix that rather than the model.

```bash
git add analysis_options.yaml apps/fcm_app
git commit -m "feat(app): add the leaf payload forms"
```

---

### Task 7: `LightSettingsForm`

The one form whose fields are **required**, which makes "is anything set?" a
different question.

**Files:**
- Create: `apps/fcm_app/lib/sandbox/forms/light_settings_form.dart`
- Test: `apps/fcm_app/test/sandbox/forms/light_settings_form_test.dart`

**Interfaces:**
- Consumes: `LightSettings`, `LightColor`.
- Produces: `LightSettingsForm` with seven inputs — `red`, `green`, `blue`, `alpha` (`GladeInput<double>`), `lightOnDuration`, `lightOffDuration` (`GladeStringInput`), and the same `readFrom`/`toModel` pair.

**Why this one is different.** FCM requires all of `color`, `light_on_duration` and
`light_off_duration` when `light_settings` is present, and all four colour
components within it. So `toModel()` returns null unless **every** field is set,
and returns a value only when all of them are — a partially filled block is not a
valid payload, and returning one would produce an FCM 400 rather than a local
error. The colour components use `GladeInput<double>.required`, the only
non-nullable inputs in the whole form.

Colour components are edited as text (`GladeStringInput` would lose the type, so
use `GladeInput<double>` with `useTextEditingController: true` and a
`stringToValueConverter`), each validated to `0.0`–`1.0`.

- [ ] **Step 1–3: Test, implement, verify**

Tests: empty returns null; all-set round-trips; a colour missing one component
returns null; a duration missing returns null; an out-of-range component is
invalid; `readFrom(null)` clears. Six tests.

Run, implement, run. Then the gate.

```bash
git add apps/fcm_app
git commit -m "feat(app): add the light settings form"
```

---

### Task 8: `AndroidNotificationForm`

Twenty-seven inputs, which is why it gets a task to itself.

**Files:**
- Create: `apps/fcm_app/lib/sandbox/forms/android_notification_form.dart`
- Test: `apps/fcm_app/test/sandbox/forms/android_notification_form_test.dart`

**Interfaces:**
- Consumes: `AndroidNotification`, `AndroidNotificationPriority`, `NotificationVisibility`, `NotificationProxy`, `LightSettingsForm` (Task 7).
- Produces: `AndroidNotificationForm`, same `readFrom`/`toModel` pair. It **owns a nested `LightSettingsForm`** as a field, and `toModel()` asks it for its value.

Every `inputKey` is prefixed `android.notification.`.

| Field | Control |
| --- | --- |
| `title`, `body`, `icon`, `color`, `sound`, `tag`, `clickAction`, `bodyLocKey`, `titleLocKey`, `channelId`, `ticker`, `eventTime`, `image` | `GladeStringInput(isRequired: false)` |
| `sticky`, `localOnly`, `defaultSound`, `defaultVibrateTimings`, `defaultLightSettings`, `bypassProxyNotification` | `GladeInput<bool?>.optional` |
| `notificationPriority` | `GladeInput<AndroidNotificationPriority?>.optional` |
| `visibility` | `GladeInput<NotificationVisibility?>.optional` |
| `proxy` | `GladeInput<NotificationProxy?>.optional` |
| `notificationCount` | `GladeIntInputNullable` with the empty-means-absent converter below |
| `bodyLocArgs`, `titleLocArgs`, `vibrateTimings` | `GladeInput<List<String>?>.optional` — the row editor hands back a whole list and `updateValue` takes it |
| `lightSettings` | the nested `LightSettingsForm` |

**The collections are real `GladeInput`s**, typed over the collection itself
(`GladeInput<List<String>?>.optional`). An earlier draft of this plan held them as
plain fields with a hand-rolled setter, which would have left them outside
`inputs` — so glade's validity and dirty/pure tracking would have ignored them, and
`toModel()` would have been the only thing that knew they existed. Typing the input
over the whole collection avoids a second, parallel state mechanism: the row editor
hands back a list and `updateValue` takes it like any other value.

**Validators**, the only ones FCM justifies here: `color` must match `#rrggbb`, and
each entry of `vibrateTimings` must be a duration like `0.5s`.

**`notificationCount` needs a custom converter, and this is not optional.** Task 1
found and I confirmed that `GladeIntInputNullable`'s default converter treats an
empty string as *unparseable* rather than as "no value": clearing the field leaves
the last number in place, so a user who types `3` and then clears it still sends
`notification_count: 3`. That is precisely the silent-wrong-payload failure this
design exists to avoid. Measured working fix:

```dart
    notificationCount = GladeIntInputNullable(
      inputKey: 'android.notification.notification_count',
      useTextEditingController: true,
      // The default converter treats '' as unparseable and keeps the previous
      // value, so clearing the field would still send the old number.
      stringToValueConverter: StringToTypeConverter<int?>(
        converter: (raw, _) =>
            (raw == null || raw.trim().isEmpty) ? null : int.parse(raw),
        converterBack: (value) => value?.toString() ?? '',
      ),
    );
```

Note the two signatures, verified by compiling them: `converter` takes
`(String? raw, _)` and `converterBack` takes only `(int? value)` — not the
symmetric two-argument pair you would expect.

- [ ] **Step 1: Write the failing test**

The important tests, beyond the five from Task 6's pattern:

```dart
    test('round-trips all 27 fields', () {
      // Reuse the everyField fixture from the contract package's own test as the
      // source of truth for what "all 27" means.
      final source = AndroidNotification.fromJson(everyField);
      final form = AndroidNotificationForm()..initialize();

      form.readFrom(source);

      expect(form.toModel(), source);
    });

    test('a false flag survives, and is not confused with absent', () {
      final form = AndroidNotificationForm()..initialize();

      form.readFrom(const AndroidNotification(sticky: false));

      final result = form.toModel()!;
      expect(result.sticky, isFalse);
      expect(result.toJson()['sticky'], isFalse);
    });

    test('an unset flag is omitted entirely', () {
      final form = AndroidNotificationForm()..initialize();

      form.readFrom(const AndroidNotification(title: 'only'));

      expect(form.toModel()!.toJson().keys, isNot(contains('sticky')));
    });

    test('rejects a colour that is not #rrggbb', () {
      final form = AndroidNotificationForm()..initialize();

      form.color.updateValue('blue');

      expect(form.isValid, isFalse);
    });

    test('carries a nested light settings block', () {
      const source = AndroidNotification(
        lightSettings: LightSettings(
          color: LightColor(red: 1, green: 0, blue: 0, alpha: 1),
          lightOnDuration: '1s',
          lightOffDuration: '0.5s',
        ),
      );
      final form = AndroidNotificationForm()..initialize();

      form.readFrom(source);

      expect(form.toModel(), source);
    });
```

The false-flag pair is the pair that proves the tristate design works end to end:
one asserts `false` reaches the JSON, the other that absent stays out of it.

- [ ] **Step 2–4: Run, implement, verify, commit**

Run from `apps/fcm_app`: `fvm flutter test test/sandbox/forms/android_notification_form_test.dart`
Expected first FAIL, then PASS.

Run from the repo root: `fvm dart run melos run ci` — exit 0.

```bash
git add apps/fcm_app
git commit -m "feat(app): add the Android notification form"
```

---

### Task 9: `AndroidConfigForm`

**Files:**
- Create: `apps/fcm_app/lib/sandbox/forms/android_config_form.dart`
- Test: `apps/fcm_app/test/sandbox/forms/android_config_form_test.dart`

**Interfaces:**
- Consumes: `AndroidConfig`, `AndroidMessagePriority`, `AndroidNotificationForm` (Task 8), `FcmOptionsForm` (Task 6).
- Produces: `AndroidConfigForm`, owning a nested `AndroidNotificationForm` and `FcmOptionsForm`.

`inputKey`s prefixed `android.`.

| Field | Control |
| --- | --- |
| `collapseKey`, `restrictedPackageName`, `ttl` | `GladeStringInput(isRequired: false)`; `ttl` validated as a duration |
| `priority` | `GladeInput<AndroidMessagePriority?>.optional` |
| `directBootOk` | `GladeInput<bool?>.optional` |
| `data` | `GladeInput<Map<String, String>?>.optional`, edited by `StringMapRows` |
| `notification` | nested `AndroidNotificationForm` |
| `fcmOptions` | nested `FcmOptionsForm` |

Tests: the five from the pattern, plus a `ttl` of `'later'` is invalid, a nested
notification round-trips, and `isValid` is false when the nested form is invalid —
that last one is what makes the section badge in Task 12 meaningful.

```bash
git add apps/fcm_app
git commit -m "feat(app): add the Android config form"
```

---

### Task 10: `ApnsConfigForm` and `WebpushConfigForm`

The two dominated by row editors rather than fields, which is why they pair.

**Files:**
- Create: `apps/fcm_app/lib/sandbox/forms/apns_config_form.dart`
- Create: `apps/fcm_app/lib/sandbox/forms/webpush_config_form.dart`
- Test: `apps/fcm_app/test/sandbox/forms/platform_config_forms_test.dart`

**Interfaces:**
- Consumes: `ApnsConfig`, `WebpushConfig`, `ApnsFcmOptionsForm`, `WebpushFcmOptionsForm` (Task 6), `expandPaths`/`flattenPaths` (Task 3).
- Produces both forms, each owning its options subform.

| `ApnsConfigForm` | Control |
| --- | --- |
| `headers` | `GladeInput<Map<String, String>?>.optional`, `StringMapRows` |
| `payload` | `GladeInput<Map<String, Object?>?>.optional`, **`PathRowsField`** |
| `fcmOptions` | nested `ApnsFcmOptionsForm` |

| `WebpushConfigForm` | Control |
| --- | --- |
| `headers`, `data` | `GladeInput<Map<String, String>?>.optional`, `StringMapRows` |
| `notification` | `GladeInput<Map<String, Object?>?>.optional`, **`PathRowsField`** |
| `fcmOptions` | nested `WebpushFcmOptionsForm` |

Every field here is a collection input or a subform, so `isValid` is effectively
the conjunction of the subforms', and
`toModel()` returns null when every collection is empty and the subform is null.

**The test that matters most** is the `apns_alert` scenario's payload surviving a
round trip, because that is the whole reason for the dotted-path work:

```dart
    test('round-trips the apns_alert scenario payload', () {
      final scenario = scenarioGallery.firstWhere((s) => s.id == 'apns_alert');
      final source = FcmMessage.fromJson(scenario.payloadTemplate).apns!;
      final form = ApnsConfigForm()..initialize();

      form.readFrom(source);

      expect(form.toModel(), source);
    });
```

```bash
git add apps/fcm_app
git commit -m "feat(app): add the APNs and WebPush forms"
```

---

### Task 11: `FcmMessageForm`, the root

**Files:**
- Create: `apps/fcm_app/lib/sandbox/forms/fcm_message_form.dart`
- Test: `apps/fcm_app/test/sandbox/forms/fcm_message_form_test.dart`

**Interfaces:**
- Consumes: every form from Tasks 6–10.
- Produces: `FcmMessageForm` with `readFrom(FcmMessage?)`, `FcmMessage toModel()` (**non-null** here — the root always produces a message, even an empty one), `bool get isValid`, and `List<GladeModelBase> get allModels` so the page can listen to each.

| Field | Control |
| --- | --- |
| `data` | `GladeInput<Map<String, String>?>.optional`, `StringMapRows` |
| `notification` | nested `FcmNotificationForm` |
| `android` | nested `AndroidConfigForm` |
| `apns` | nested `ApnsConfigForm` |
| `webpush` | nested `WebpushConfigForm` |
| `fcmOptions` | nested `FcmOptionsForm` |

`isValid` is the conjunction across `allModels`.

**The notification chain is the thing to get right here, and Task 4 showed why.**
A `GladeModel` is a `ChangeNotifier`, but a nested model's notification does **not**
propagate to its parent — and the controls are `StatelessWidget`s that read
`input.value` without listening to anything. Task 4 found this the honest way: its
tristate-cycling test only advanced past the first state once the widget was
rebuilt between taps, because nothing was telling it to.

So `allModels` must return **every model in the tree, flattened** — the root, its
children, and their children — and whoever renders the form listens to all of them.
Listening to the root alone would leave a change three levels down invisible: the
value would be in the model and not on the screen, which is worse than either.

**The gallery invariant lands here**, and it is this plan's counterpart to the
contract plan's round-trip test:

```dart
    test('every gallery scenario survives a form round trip', () {
      for (final scenario in scenarioGallery) {
        final source = FcmMessage.fromJson(scenario.payloadTemplate);
        final form = FcmMessageForm()..initialize();

        form.readFrom(source);

        expect(form.toModel(), source, reason: scenario.id);
      }
    });
```

If that fails for a scenario, **a field is missing from a form** — report which,
because it means the form does not yet cover a payload that actually ships. Do not
adjust the assertion.

```bash
git add apps/fcm_app
git commit -m "feat(app): add the root message form"
```

---

### Task 12: The section widgets

**Files:**
- Create ten files under `apps/fcm_app/lib/ui/form/sections/`: `message_section.dart`, `notification_section.dart`, `android_section.dart`, `android_notification_section.dart`, `light_settings_section.dart`, `apns_section.dart`, `webpush_section.dart`, `fcm_options_section.dart`, `apns_fcm_options_section.dart`, `webpush_fcm_options_section.dart`
- Test: `apps/fcm_app/test/ui/form/sections_test.dart`

**Interfaces:**
- Consumes: the ten forms, the six controls.
- Produces one widget per file, each `const X({required <its form> form, super.key})`, rendering that form's inputs inside a `FormSection` and nesting its children's sections.

**Three separate options sections, not one parameterised widget.** The three
`fcm_options` variants carry different fields — the generic one only
`analytics_label`, APNs adds `image`, WebPush adds `link` — and
`prefer-single-widget-per-file` forbids putting three widgets in one file anyway. So
`fcm_options_section.dart` holds `FcmOptionsSection`, and
`apns_fcm_options_section.dart` and `webpush_fcm_options_section.dart` hold theirs:
ten section files, not eight.

Rules that bite here: **no `Widget _buildFoo()`** (build inline with
collection-`for`), one widget per file, and every text field binds
`controller: form.x.controller` with `validator: form.x.formFieldValidator`.

Tests, at the level that is worth testing in a widget: each section renders
collapsed; expanding `android` reveals its fields and its nested `notification`
section header; an invalid nested field badges **both** its own section and its
ancestors, since that is the property that stops an error hiding.

```bash
git add apps/fcm_app
git commit -m "feat(app): add the payload form sections"
```

---

### Task 13: `SandboxController` over forms

**Files:**
- Modify: `apps/fcm_app/lib/sandbox/sandbox_controller.dart`
- Modify: `apps/fcm_app/lib/main.dart` (add `GladeForms.initialize()`)
- Modify: `apps/fcm_app/test/sandbox_controller_test.dart`

**Interfaces:**
- Consumes: `FcmMessageForm` (Task 11).
- Produces, on `SandboxController`: `FcmMessageForm get form`, `Scenario? get selectedScenario`, `void applyScenario(Scenario)`, `bool get validateOnly`, `void setValidateOnly(bool)`, `String? get sendBlockedReason`, `bool get canSend`, `SandboxSendState get state`, `Future<void> send()`.

**Removed:** `payloadText`, `editPayload`, `parseError`, `parsedMessage`,
`scenarioRevision`.

An earlier draft of this plan justified dropping the revision by claiming that
"`readFrom` updates the inputs in place and the widgets follow". **That was wrong,
and Task 5 found it.** The text-bound controls do follow, because they read through
a `GladeInput`'s controller — but the row editors own their rows in `State` and
would have ignored a new value entirely, so applying a scenario would have
populated the model while the rows on screen still showed the previous scenario.
Task 5 fixes that inside the row editors with a `didUpdateWidget` that reloads only
when the incoming value differs from what the rows currently collapse to. That is
self-correcting — a user's own keystroke round-trips to an equal value and changes
nothing — which is why no revision counter is needed after all.

**`GladeForms.initialize()` must be called once before any model is built.** Task 1
found this the hard way in a test `setUpAll`; the app needs it too, so add it to
`main()` in `apps/fcm_app/lib/main.dart` before `runApp`, alongside the existing
`WidgetsFlutterBinding.ensureInitialized()`.

`applyScenario` becomes `form.readFrom(FcmMessage.fromJson(scenario.payloadTemplate))`.
`send()` uses `form.toModel()`. `canSend` requires a token, `form.isValid`, and no
send in flight.

**The controller listens to every model in `form.allModels`** and re-notifies, so
the page still needs only one listenable while a change at any depth reaches it.
Listening to `form` alone is not enough, for the reason Task 11 records. Add each
listener in the constructor and remove every one in `dispose` — `always-remove-listener`
is fatal, and ten un-removed listeners on a long-lived model would be a real leak.

Tests carry over in shape: opens on the first scenario and is sendable; applying
another replaces the fields; an invalid field blocks Send with a reason; Send posts
the form's message; validate-only is forwarded; a failure keeps the form's
contents. Plus one new: **editing a field after a scenario is applied changes what
is sent**, which is the behaviour the whole feature exists for.

```bash
git add apps/fcm_app
git commit -m "feat(app): drive the sandbox from the payload form"
```

---

### Task 14: `SandboxView` over sections, and the editor goes

**Files:**
- Modify: `apps/fcm_app/lib/ui/sandbox_view.dart`
- Delete: `apps/fcm_app/lib/ui/payload_editor.dart`
- Modify: `apps/fcm_app/test/sandbox_view_test.dart`

`SandboxView` keeps its shape — the loaded scenario's header, the validate-only
checkbox, Send, the result card — and swaps the `PayloadEditor` for
`MessageSection(form: controller.form)`.

**Keep the regression test from the scenarios-page fix**: the form's first field
must be reachable **with no scroll helper**, since burying the editable surface is
the defect that started this. Assert `find.byType(TextField)` after nothing but a
`pump`. With every section collapsed except the root's own fields, that holds — and
if it does not, report it rather than adding a scroll helper.

`git rm apps/fcm_app/lib/ui/payload_editor.dart` and confirm
`grep -rn 'PayloadEditor' apps packages --include=*.dart` is empty.

```bash
git add apps/fcm_app
git commit -m "feat(app): replace the JSON editor with the payload form"
```

---

### Task 15: Verify and document

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Run the gate and both builds**

Run from the repo root: `fvm dart run melos run ci` — exit 0, and report every
package's count as measured.

From `apps/fcm_app`: `fvm flutter build apk --debug` and
`fvm flutter build web --release`. Both must succeed. `glade_forms` pulls
`provider` and two `netglade_*` packages, so a web-compilation problem would show
up here rather than at runtime.

- [ ] **Step 2: Update the README**

Replace the passage describing the Sandbox's JSON editor with the form: ten
collapsible sections mirroring FCM's own objects, tristate controls for the
optional booleans **and why** (FCM distinguishes absent from false), and
dotted-path rows for `apns.payload` and `webpush.notification` **and why** (FCM
defines them as free-form, so no form can enumerate them).

State the accepted limitation plainly: with no JSON escape hatch, only fields the
form models can be sent.

Update `## Verified on this machine` with measured counts and honest build results.

- [ ] **Step 3: Commit**

```bash
git add README.md apps/fcm_app
git commit -m "docs: describe the payload form"
```

- [ ] **Step 4: The verifications that need a human**

Neither can run here. Report each as verified or unverified; never assume.

1. **The `validate_only` sweep, now through the form.** For each of the nine
   scenarios: open it, send with validate-only on, expect 200. Spec 1's sweep
   proved the *model* emits payloads Google accepts; this proves the *form* does,
   which is a different claim and the more valuable one now.
2. **On a device:** build `big_picture_remote` from the form and confirm the image
   arrives. Then set `direct_boot_ok` to each of its three states and confirm the
   sent payload contains `false` when false and omits the key when unset — the
   tristate design's only real-world proof.

## Verification summary

- [ ] `melos run ci` exits 0
- [ ] `flutter build apk --debug` and `build web --release` succeed
- [ ] `grep -rn 'ignore:' packages apps --include=*.dart` returns nothing
- [ ] `grep -rn 'PayloadEditor' apps packages --include=*.dart` returns nothing
- [ ] The gallery invariant passes for all nine scenarios
- [ ] The Sandbox's first field is reachable with no scroll helper
- [ ] The `validate_only` sweep and the two device checks are each reported

## Notes for the implementer

- **`GladeIntInputNullable` keeps the old value when its field is cleared**, unless
  given the custom converter in Task 8. Confirmed by measurement, not inference.
- **`GladeForms.initialize()` is required once** before any model is constructed —
  in `main()` for the app, in `setUpAll` for tests.
- **Three `glade_forms` defaults are traps**, and Task 1 exists to prove them:
  `GladeStringInput` is required by default, `GladeIntInputNullable` has no
  controller by default, and `GladeBoolInput` cannot hold null.
- **`toModel()` returning null for an untouched block is load-bearing.** It is what
  keeps `"android": {}` out of the payload, and the `== const X()` comparison is
  how to ask it without a field-by-field check that would rot.
- **Never let a two-state control near an optional bool.** It silently sends fields
  nobody set, and nothing on screen would explain the changed behaviour.
- **The gallery invariant in Task 11 is the completeness check.** A missing form
  field shows up there and nowhere else.
- **The controls do not rebuild themselves.** They are stateless and read
  `input.value`, so something above them must listen to the model that owns the
  input. That is why the controller listens to every model in the tree rather than
  just the root.
- **Do not add a JSON escape hatch back.** Removing it was explicit; the
  consequence is recorded in the spec and the README.
