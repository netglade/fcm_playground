# Scenario Catalogue Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the nine-scenario gallery with the full 66-scenario catalogue in groups A–K, and widen the send envelope so a topic, a condition or an explicit token can be targeted.

**Architecture:** The catalogue becomes eleven `const` lists, one file per group, concatenated by a barrel that keeps the name `scenarioGallery`. `Scenario` gains `needs` (an enum whose every value is a later sub-project), `manualSteps` and `target`. The delivery target moves into the send envelope as a sealed `SendTarget`, leaving `FcmMessage` still rejecting any template that sets a target itself.

**Tech Stack:** Dart pub workspace, melos 8, fvm-pinned Flutter 3.44.8, DCM, `glade_forms` 6.0.0, `shelf` for the API.

## Global Constraints

- **No `// ignore:` comments anywhere.** If a lint fires, fix the code. The only one in the repo is FlutterFire's generated `firebase_options.dart` header.
- **No `dart`/`flutter` on `PATH`.** Always `fvm dart` / `fvm flutter`.
- **The only gate is `fvm dart run melos run ci` from the repo root, judged by exit code 0** (format:check → analyze → dcm → tests). Run `fvm dart run melos run format` *before* the gate — hand-written files are reliably unformatted and this has failed tasks on three earlier plans.
- **All content in English.** The source catalogue is Czech; ids and group letters are kept verbatim, prose is translated.
- **Fatal lints that have bitten this repo:** `prefer_initializing_formals` (fires even with a default — use `this._field`), `use_null_aware_elements` (`'k': ?v`, `...?list`), `sort_pub_dependencies`, `avoid_print`, `directives_ordering`.
- **Fatal DCM:** `number-of-parameters: 5`, `source-lines-of-code: 50`, `prefer-match-file-name`, `prefer-single-widget-per-file`, `avoid-returning-widgets`, `always-remove-listener`.
- **`metrics-exclude` covers** `test/**`, `packages/fcm_gallery_shared/lib/src/message/**`, `packages/fcm_gallery_shared/lib/src/scenario.dart`, `apps/fcm_app/lib/sandbox/forms/**`. It does **not** cover `apps/fcm_app/lib/ui/**` — a 50-line `build` limit applies there.
- **Baseline, measured:** `melos run ci` exit 0 — core 20, `fcm_gallery_shared` 91, `fcm_api` 36, `fcm_app` 282.
- **Branch:** `feature/fcm-message-contract-impl`, at `167b622`.

---

## File Structure

```
packages/fcm_gallery_shared/lib/src/
  send_target.dart                    NEW  sealed SendTarget + 4 variants
  send_message_request.dart           MOD  token -> SendTarget target
  scenarios/
    scenario.dart                     MOV  from src/scenario.dart, + 3 fields
    scenario_need.dart                NEW  enum ScenarioNeed
    group_a.dart … group_k.dart       NEW  one const list each
    scenario_gallery.dart             NEW  concatenates A..K as scenarioGallery

apps/fcm_api/lib/src/send_message.dart  MOD  target instead of token

apps/fcm_app/lib/
  sandbox/sandbox_controller.dart     MOD  target state; applyScenario sets it
  ui/send_target_field.dart           NEW  the target selector
  ui/scenario_needs_banner.dart       NEW  "needs notification actions"
  ui/manual_steps_block.dart          NEW  selectable adb/procedure text
```

`analysis_options.yaml`'s `metrics-exclude` entry for `src/scenario.dart` becomes `src/scenarios/**` in Task 3.

---

### Task 1: `SendTarget`

The delivery target as a closed set, so the API can switch on it exhaustively.

**Files:**
- Create: `packages/fcm_gallery_shared/lib/src/send_target.dart`
- Modify: `packages/fcm_gallery_shared/lib/fcm_gallery_shared.dart` (add the export, alphabetically — it sorts between `src/scenario.dart` and `src/send_message_request.dart`)
- Test: `packages/fcm_gallery_shared/test/send_target_test.dart`

**Interfaces:**
- Consumes: nothing.
- Produces: `sealed class SendTarget` with `Map<String, Object?> toJson()` and `static SendTarget readFrom(Map<String, Object?> json)`; variants `TokenTarget(String token)`, `TopicTarget(String topic)`, `ConditionTarget(String condition)`, `AllDevicesTarget()`. All four are `const`-constructible with value equality.

**The wire format keeps FCM's own shape**: the target sits at the *top level* of the request beside `validate_only` and `message`, exactly as `token` does today, so every existing `curl` example in the README keeps working and the union mirrors FCM's own `oneof`. `AllDevicesTarget` writes `{'all_devices': true}`, which is ours rather than FCM's — the API refuses it in Task 2.

- [ ] **Step 1: Write the failing test**

```dart
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:test/test.dart';

void main() {
  group('toJson', () {
    test('writes the target at the top level, as FCM spells it', () {
      expect(const TokenTarget('abc').toJson(), {'token': 'abc'});
      expect(const TopicTarget('news').toJson(), {'topic': 'news'});
      expect(
        const ConditionTarget("'news' in topics").toJson(),
        {'condition': "'news' in topics"},
      );
      expect(const AllDevicesTarget().toJson(), {'all_devices': true});
    });
  });

  group('readFrom', () {
    test('round-trips every variant', () {
      const targets = [
        TokenTarget('abc'),
        TopicTarget('news'),
        ConditionTarget("'news' in topics"),
        AllDevicesTarget(),
      ];
      for (final target in targets) {
        expect(SendTarget.readFrom(target.toJson()), target, reason: '$target');
      }
    });

    test('rejects a request with no target', () {
      // Defaulting to this device would send a topic broadcast to one phone and
      // look like it worked.
      expect(
        () => SendTarget.readFrom(<String, Object?>{'validate_only': false}),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects two targets at once, naming both', () {
      expect(
        () => SendTarget.readFrom({'token': 'abc', 'topic': 'news'}),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            allOf(contains('token'), contains('topic')),
          ),
        ),
      );
    });

    test('rejects a blank target value', () {
      expect(
        () => SendTarget.readFrom({'topic': '   '}),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects a non-string target value', () {
      expect(
        () => SendTarget.readFrom({'token': 42}),
        throwsA(isA<FormatException>()),
      );
    });
  });

  test('has value equality, so a scenario can be compared', () {
    expect(const TopicTarget('news'), const TopicTarget('news'));
    expect(const TopicTarget('news'), isNot(const TopicTarget('beta')));
    expect(const TokenTarget('news'), isNot(const TopicTarget('news')));
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run from the repo root: `fvm dart test --chain-stack-traces packages/fcm_gallery_shared/test/send_target_test.dart`
Expected: FAIL — `Error: Type 'TokenTarget' not found`.

- [ ] **Step 3: Write the implementation**

```dart
/// Where the API should deliver a message.
///
/// FCM's `Message` carries a `oneof` of `token`, `topic` and `condition`, and
/// the typed [FcmMessage] deliberately rejects all three: a payload template
/// must not choose its own audience, or a template pasted from Google's docs
/// could quietly broadcast. The target therefore lives in the *envelope*
/// alongside `validate_only`, and this is that target as a closed set — so the
/// API switches on it exhaustively rather than testing fields for null.
sealed class SendTarget {
  const SendTarget();

  /// Reads the one target in [json], which sits at the request's top level.
  ///
  /// Throws when there is none or more than one. Neither is recoverable and
  /// both are dangerous to guess at: defaulting a missing target to this device
  /// would send a topic broadcast to a single phone and look like a success.
  static SendTarget readFrom(Map<String, Object?> json) {
    const keys = ['token', 'topic', 'condition', 'all_devices'];
    final present = keys.where(json.containsKey).toList();

    if (present.isEmpty) {
      throw FormatException(
        'a delivery target is required: one of ${keys.join(', ')}',
      );
    }
    if (present.length > 1) {
      throw FormatException(
        'only one delivery target is allowed, got ${present.join(' and ')}',
      );
    }

    final key = present.single;
    if (key == 'all_devices') {
      return const AllDevicesTarget();
    }

    final value = json[key];
    if (value is! String) {
      throw FormatException(
        '"$key" must be a String, got ${value.runtimeType}',
      );
    }
    if (value.trim().isEmpty) {
      throw FormatException('"$key" must not be blank');
    }

    return switch (key) {
      'token' => TokenTarget(value),
      'topic' => TopicTarget(value),
      _ => ConditionTarget(value),
    };
  }

  /// The single key/value this target contributes to the request body.
  Map<String, Object?> toJson();
}

/// Deliver to one device's registration token.
class TokenTarget extends SendTarget {
  /// Targets the device holding [token].
  const TokenTarget(this.token);

  /// The registration token to deliver to.
  final String token;

  @override
  Map<String, Object?> toJson() => {'token': token};

  @override
  bool operator ==(Object other) =>
      other is TokenTarget && other.token == token;

  @override
  int get hashCode => Object.hash(TokenTarget, token);

  @override
  String toString() => 'TokenTarget($token)';
}

/// Deliver to every device subscribed to a topic.
class TopicTarget extends SendTarget {
  /// Targets subscribers of [topic].
  const TopicTarget(this.topic);

  /// The topic name, without the `/topics/` prefix FCM's older API used.
  final String topic;

  @override
  Map<String, Object?> toJson() => {'topic': topic};

  @override
  bool operator ==(Object other) => other is TopicTarget && other.topic == topic;

  @override
  int get hashCode => Object.hash(TopicTarget, topic);

  @override
  String toString() => 'TopicTarget($topic)';
}

/// Deliver to the devices matching a boolean topic expression.
class ConditionTarget extends SendTarget {
  /// Targets devices matching [condition], e.g. `'news' in topics`.
  const ConditionTarget(this.condition);

  /// FCM's condition expression.
  final String condition;

  @override
  Map<String, Object?> toJson() => {'condition': condition};

  @override
  bool operator ==(Object other) =>
      other is ConditionTarget && other.condition == condition;

  @override
  int get hashCode => Object.hash(ConditionTarget, condition);

  @override
  String toString() => 'ConditionTarget($condition)';
}

/// Deliver to every device this project has ever registered.
///
/// Not an FCM concept: FCM has no "all devices" audience, so honouring this
/// means keeping a registry of tokens and sending to each. The API therefore
/// refuses it with a stated reason until that registry exists, which is better
/// than falling back to this device and reporting success.
class AllDevicesTarget extends SendTarget {
  /// Targets every registered device.
  const AllDevicesTarget();

  @override
  Map<String, Object?> toJson() => {'all_devices': true};

  @override
  bool operator ==(Object other) => other is AllDevicesTarget;

  @override
  int get hashCode => AllDevicesTarget.hashCode;

  @override
  String toString() => 'AllDevicesTarget()';
}
```

- [ ] **Step 4: Run the test and the gate**

Run: `fvm dart test packages/fcm_gallery_shared/test/send_target_test.dart` — expect PASS, 7 tests.
Then `fvm dart run melos run format` and `fvm dart run melos run ci` — exit 0.

Report the measured `fcm_gallery_shared` count (baseline 91).

- [ ] **Step 5: Commit**

```bash
git add packages/fcm_gallery_shared
git commit -m "feat(shared): add the send envelope's delivery target"
```

---

### Task 2: The envelope and the API carry a target

The only breaking change in this plan, done in one task so the gate is never red.

**Files:**
- Modify: `packages/fcm_gallery_shared/lib/src/send_message_request.dart`
- Modify: `apps/fcm_api/lib/src/send_message.dart`
- Modify: `packages/fcm_gallery_shared/test/send_message_request_test.dart`
- Modify: `apps/fcm_api/test/send_message_test.dart`
- Modify: `apps/fcm_app/lib/sandbox/sandbox_controller.dart` (the one `SendMessageRequest(token: …)` call site)
- Modify: any app test constructing a `SendMessageRequest` — find them with `grep -rn 'SendMessageRequest(' apps packages --include=*.dart`

**Interfaces:**
- Consumes: `SendTarget` and its four variants from Task 1.
- Produces: `SendMessageRequest({required SendTarget target, required FcmMessage message, bool validateOnly = false})`. The `token` field is **gone**; `target` replaces it. `sendMessage` keeps its signature.

`SendMessageRequest.fromJson` now delegates the target to `SendTarget.readFrom(json)`, so the "no target" and "two targets" errors come from one place. `toJson` spreads the target: `{...target.toJson(), 'validate_only': validateOnly, 'message': message.toJson()}`.

In `sendMessage`, the blank-token guard is replaced by a switch:

```dart
  // AllDevices is the one target FCM cannot express: it has no such audience,
  // so honouring it needs a registry of tokens this app does not keep. Refusing
  // with a reason beats sending to one device and calling it a broadcast.
  if (request.target case AllDevicesTarget()) {
    return const SendRejected(
      statusCode: 501,
      error: ApiError(
        'sending to all devices needs a token registry, which this API does '
        'not have yet — pick a token, topic or condition',
        field: 'all_devices',
      ),
    );
  }

  final body = {
    'validate_only': request.validateOnly,
    'message': {...request.message.toJson(), ...request.target.toJson()},
  };
```

Blankness is now rejected by `SendTarget.readFrom`, so the old `token must not be blank` guard and its test move to Task 1's coverage. **Keep one API-level test** asserting a blank token still yields 400 through the whole `fromJson` path, so the guarantee is not lost when it changes owner — a `FormatException` from `readFrom` must surface as a 400, not a 500.

- [ ] **Step 1: Write the failing tests**

```dart
// packages/fcm_gallery_shared/test/send_message_request_test.dart — add:
  test('reads a topic target', () {
    final request = SendMessageRequest.fromJson({
      'topic': 'news',
      'message': {'notification': {'title': 'Hi'}},
    });

    expect(request.target, const TopicTarget('news'));
  });

  test('writes the target back at the top level', () {
    const request = SendMessageRequest(
      target: TopicTarget('news'),
      message: FcmMessage(),
    );

    expect(request.toJson()['topic'], 'news');
    expect(request.toJson().containsKey('token'), isFalse);
  });

  test('still rejects a message that sets its own target', () {
    // The envelope owning the target is exactly why the message must not.
    expect(
      () => SendMessageRequest.fromJson({
        'token': 'abc',
        'message': {'topic': 'news'},
      }),
      throwsA(isA<FormatException>()),
    );
  });
```

```dart
// apps/fcm_api/test/send_message_test.dart — add:
  test('forwards a topic as the delivery target', () async {
    final outcome = await sendMessage(
      const SendMessageRequest(
        target: TopicTarget('news'),
        message: FcmMessage(),
      ),
      sender: sender,
      now: () => DateTime.utc(2026, 8, 13),
    );

    expect(outcome, isA<SendSucceeded>());
    expect(sender.lastBody!['message'], containsPair('topic', 'news'));
  });

  test('refuses all-devices with 501 rather than sending to one', () async {
    final outcome = await sendMessage(
      const SendMessageRequest(
        target: AllDevicesTarget(),
        message: FcmMessage(),
      ),
      sender: sender,
      now: () => DateTime.utc(2026, 8, 13),
    );

    expect(outcome, isA<SendRejected>());
    expect((outcome as SendRejected).statusCode, 501);
    expect(sender.lastBody, isNull, reason: 'nothing may be sent');
  });

  test('a blank token is still a 400, now via the target reader', () {
    expect(
      () => SendMessageRequest.fromJson({
        'token': '  ',
        'message': <String, Object?>{},
      }),
      throwsA(isA<FormatException>()),
    );
  });
```

- [ ] **Step 2: Run to verify they fail**

Run: `fvm dart test packages/fcm_gallery_shared/test/send_message_request_test.dart apps/fcm_api/test/send_message_test.dart`
Expected: FAIL — no `target` parameter.

- [ ] **Step 3: Implement**

Change `SendMessageRequest`'s `token` to `target` as described above, apply the `sendMessage` switch, then fix every call site the grep found. In `SandboxController.send`, the existing token callback resolves to `TokenTarget`:

```dart
    final target = _target ?? TokenTarget(token);
```

where `_target` is the scenario's or the user's choice — Task 15 adds the setter; until then pass `TokenTarget(token)` so this task compiles on its own.

- [ ] **Step 4: Verify**

Run the two test files, then `fvm dart run melos run format` and `fvm dart run melos run ci` — exit 0. `grep -rn 'request.token\|token:' apps/fcm_api/lib` must show no leftover use of the removed field.

Report measured counts for all four packages.

- [ ] **Step 5: Commit**

```bash
git add packages apps
git commit -m "feat(api): take the delivery target in the send envelope"
```

---

### Task 3: `ScenarioNeed`, and `Scenario` grows three fields

**Files:**
- Create: `packages/fcm_gallery_shared/lib/src/scenarios/scenario_need.dart`
- Move: `packages/fcm_gallery_shared/lib/src/scenario.dart` → `packages/fcm_gallery_shared/lib/src/scenarios/scenario.dart` (use `git mv`, then fix the barrel export and the `import 'message/…'` paths, which gain a `../`)
- Modify: `packages/fcm_gallery_shared/lib/fcm_gallery_shared.dart`
- Modify: `analysis_options.yaml` — the `metrics-exclude` entry `packages/fcm_gallery_shared/lib/src/scenario.dart` becomes `packages/fcm_gallery_shared/lib/src/scenarios/**`
- Test: `packages/fcm_gallery_shared/test/scenario_need_test.dart`

**Interfaces:**
- Consumes: `SendTarget` (Task 1).
- Produces: `enum ScenarioNeed { channels, styles, interaction, badge, targeting, delayedSend, manualStep, externalApproval }` with a `String get label`. `Scenario` gains `List<ScenarioNeed> needs = const []`, `String? manualSteps`, `SendTarget? target`, and `bool get isSupported => needs.isEmpty`.

The nine existing scenarios stay exactly as they are in this task — the gallery is switched over in Task 4. Keeping this task purely additive means the gate stays green while the model changes shape.

- [ ] **Step 1: Write the failing test**

```dart
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:test/test.dart';

void main() {
  test('every need has a human label, since the UI shows it verbatim', () {
    for (final need in ScenarioNeed.values) {
      expect(need.label, isNotEmpty, reason: need.name);
      expect(need.label.trim(), need.label, reason: need.name);
    }
  });

  test('a scenario with no needs is supported', () {
    const scenario = Scenario(
      id: 'x',
      group: 'A',
      title: 't',
      description: 'd',
      payloadTemplate: <String, dynamic>{},
    );

    expect(scenario.needs, isEmpty);
    expect(scenario.isSupported, isTrue);
    expect(scenario.manualSteps, isNull);
    expect(scenario.target, isNull, reason: 'null means this device');
  });

  test('a scenario with a need is not supported', () {
    const scenario = Scenario(
      id: 'x',
      group: 'A',
      title: 't',
      description: 'd',
      payloadTemplate: <String, dynamic>{},
      needs: [ScenarioNeed.channels],
    );

    expect(scenario.isSupported, isFalse);
  });

  test('a scenario can name its own audience', () {
    const scenario = Scenario(
      id: 'x',
      group: 'J',
      title: 't',
      description: 'd',
      payloadTemplate: <String, dynamic>{},
      target: TopicTarget('news'),
    );

    expect(scenario.target, const TopicTarget('news'));
  });
}
```

- [ ] **Step 2: Run to verify it fails**

Run: `fvm dart test packages/fcm_gallery_shared/test/scenario_need_test.dart` — FAIL, `ScenarioNeed` not found.

- [ ] **Step 3: Implement**

```dart
/// What a scenario needs, beyond a payload, before it demonstrates anything.
///
/// Every value is a planned sub-project, which is the point: "which scenarios
/// does the channels work unblock?" is a filter rather than a search through
/// prose, and a scenario cannot be marked as needing something no plan will
/// deliver. [externalApproval] is the one exception — it is permanently outside
/// this project's control.
enum ScenarioNeed {
  /// Several notification channels, their importance, and a screen that reads
  /// that importance back from the system.
  channels('notification channels'),

  /// Local notification styles: big picture, big text, inbox, messaging,
  /// progress, large icon.
  styles('notification styles'),

  /// Action buttons, inline reply, delete intents, deep-link routing and the
  /// full-screen intent.
  interaction('notification actions'),

  /// The launcher icon's badge count.
  badge('launcher badge'),

  /// A registry of every registered token, so a message can fan out.
  targeting('a device registry'),

  /// Holding a send long enough for the app to be killed first.
  delayedSend('delayed sending'),

  /// A step on the device or over adb that no payload can perform.
  manualStep('a manual step'),

  /// Approval or capability from Apple or the OS that this project cannot grant
  /// itself: a critical-alert entitlement, a Notification Service Extension,
  /// notification-policy access.
  externalApproval('external approval');

  const ScenarioNeed(this.label);

  /// Shown to the user, verbatim, wherever an unmet need is reported.
  final String label;
}
```

Then add to `Scenario`, alongside the existing fields:

```dart
    this.needs = const [],
    this.manualSteps,
    this.target,
```

```dart
  /// What this scenario needs before it demonstrates anything, empty when it
  /// works today.
  final List<ScenarioNeed> needs;

  /// A step the user must perform by hand — an adb command, a settings change —
  /// when the payload alone cannot produce the scenario.
  final String? manualSteps;

  /// Who to deliver to, or null for this device, which is what all but four
  /// scenarios want.
  final SendTarget? target;

  /// Whether the app can demonstrate this scenario as it stands.
  bool get isSupported => needs.isEmpty;
```

- [ ] **Step 4: Verify**

Run the new test, then `fvm dart run melos run format` and `fvm dart run melos run ci` — exit 0. Confirm the `metrics-exclude` path change with `grep -n 'scenarios' analysis_options.yaml`, and that the old path is gone.

- [ ] **Step 5: Commit**

```bash
git add packages analysis_options.yaml
git commit -m "feat(shared): let a scenario declare its needs and audience"
```

---

### Task 4: Group A, and the gallery switches over

The migration task. It replaces the nine old scenarios with group A's four, so every test naming an old id moves **once**, while only four entries exist to reason about. Groups B–K then append with no further churn.

**Files:**
- Create: `packages/fcm_gallery_shared/lib/src/scenarios/group_a.dart`
- Create: `packages/fcm_gallery_shared/lib/src/scenarios/scenario_gallery.dart`
- Modify: `packages/fcm_gallery_shared/lib/src/scenarios/scenario.dart` — delete the old `scenarioGallery` const from the bottom of the file
- Modify: `packages/fcm_gallery_shared/lib/fcm_gallery_shared.dart`
- Test: `packages/fcm_gallery_shared/test/scenarios/scenario_gallery_test.dart`
- Modify: every test naming an old id. Find them with
  `grep -rln "big_picture_remote\|data_only\|apns_alert\|custom_channel\|scenarioGallery" apps packages --include=*.dart`

**Interfaces:**
- Consumes: `Scenario`, `ScenarioNeed` (Task 3).
- Produces: `const groupA = <Scenario>[…]` and `const scenarioGallery = <Scenario>[...groupA]`. The name and type of `scenarioGallery` are unchanged, so consumers compile untouched; only the ids change.

**Old id → new id.** Apply this mapping wherever a test names one:

| Old | New |
| --- | --- |
| `plain` / first entry | `a1_notification_only` |
| `data_only` | `a2_data_only` |
| `big_picture_remote` | `e2_image_remote` (Task 8 — until then use `a1_notification_only`) |
| `apns_alert` | `g4_badge_ios` (Task 10 — until then use `a3_hybrid`) |
| `custom_channel` | `d1_importance_high` (Task 7 — until then use `a1_notification_only`) |

A test needing a scenario from a group that does not exist yet uses the group-A stand-in named above and is **re-pointed in the task that adds the real group**. Each of Tasks 7, 8 and 10 lists this as an explicit step.

- [ ] **Step 1: Write the failing test**

```dart
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:test/test.dart';

void main() {
  test('every id is unique', () {
    final ids = scenarioGallery.map((s) => s.id).toList();

    expect(ids.toSet(), hasLength(ids.length));
  });

  test("every id starts with its group's letter", () {
    // The one assertion that catches an entry filed under the wrong table as
    // eleven files grow independently.
    for (final scenario in scenarioGallery) {
      final letter = scenario.group.substring(0, 1).toLowerCase();
      expect(
        scenario.id,
        startsWith(letter),
        reason: '${scenario.id} is filed under ${scenario.group}',
      );
    }
  });

  test('every template round-trips through the typed model', () {
    // 66 hand-written templates is exactly where a `titel` typo or a camelCase
    // key slips in. The strict parser plus this assertion turns that into a
    // failed build rather than an opaque 400 from Google on a device.
    for (final scenario in scenarioGallery) {
      final raw = Map<String, Object?>.from(scenario.payloadTemplate);
      expect(
        FcmMessage.fromJson(raw).toJson(),
        raw,
        reason: scenario.id,
      );
    }
  });

  test('no template sets its own delivery target', () {
    for (final scenario in scenarioGallery) {
      for (final key in const ['token', 'topic', 'condition']) {
        expect(
          scenario.payloadTemplate.containsKey(key),
          isFalse,
          reason: '${scenario.id} sets $key; use Scenario.target instead',
        );
      }
    }
  });

  test('every scenario has a non-blank title and description', () {
    for (final scenario in scenarioGallery) {
      expect(scenario.title.trim(), isNotEmpty, reason: scenario.id);
      expect(scenario.description.trim(), isNotEmpty, reason: scenario.id);
    }
  });

  test('a manual-step scenario says what the step is', () {
    for (final scenario in scenarioGallery) {
      if (scenario.needs.contains(ScenarioNeed.manualStep)) {
        expect(scenario.manualSteps, isNotNull, reason: scenario.id);
      }
    }
  });

  group('group A', () {
    test('offers all four basic-delivery scenarios', () {
      expect(groupA.map((s) => s.id), [
        'a1_notification_only',
        'a2_data_only',
        'a3_hybrid',
        'a4_no_display',
      ]);
    });

    test('all four work today, with nothing outstanding', () {
      for (final scenario in groupA) {
        expect(scenario.isSupported, isTrue, reason: scenario.id);
      }
    });

    test('the data-only scenario carries no notification block', () {
      final dataOnly = groupA.firstWhere((s) => s.id == 'a2_data_only');

      expect(dataOnly.payloadTemplate.containsKey('notification'), isFalse);
      expect(dataOnly.payloadTemplate['data'], isNotEmpty);
      expect(dataOnly.requiresKilledApp, isTrue);
    });

    test('the hybrid scenario carries both blocks', () {
      final hybrid = groupA.firstWhere((s) => s.id == 'a3_hybrid');

      expect(hybrid.payloadTemplate['notification'], isNotNull);
      expect(hybrid.payloadTemplate['data'], isNotNull);
    });
  });
}
```

- [ ] **Step 2: Run to verify it fails**

Run: `fvm dart test packages/fcm_gallery_shared/test/scenarios/scenario_gallery_test.dart` — FAIL, `groupA` not found.

- [ ] **Step 3: Implement `group_a.dart`**

```dart
import 'scenario.dart';

/// **A — Basic delivery.** The four shapes an FCM message can take, and which
/// layer draws each one.
///
/// The whole catalogue rests on telling these apart: a `notification` payload is
/// drawn by the system while the app is backgrounded and by the app itself while
/// it is foregrounded, and a `data` payload is never drawn by anyone unless the
/// app does it. Most confusion about "the push did not arrive" is really one of
/// these four being mistaken for another.
const groupA = <Scenario>[
  Scenario(
    id: 'a1_notification_only',
    group: 'A — Basic delivery',
    title: 'Notification-only payload',
    description:
        'Watch which layer drew it — the system while backgrounded, the app '
        'while foregrounded — and how the icon and accent colour come out.',
    payloadTemplate: {
      'notification': {
        'title': 'Build finished',
        'body': 'Release 1.0.0 is ready.',
      },
    },
  ),
  Scenario(
    id: 'a2_data_only',
    group: 'A — Basic delivery',
    title: 'Data-only payload, drawn locally',
    description:
        'Nothing draws this but the app. Watch whether it arrives at all with '
        'the app killed, which is the case data-only delivery exists for.',
    expectation:
        'On iOS a data-only push needs content-available and is throttled; see '
        'i3_ios_content_available.',
    payloadTemplate: {
      'data': {'event': 'sync', 'build_number': '128'},
    },
    requiresKilledApp: true,
  ),
  Scenario(
    id: 'a3_hybrid',
    group: 'A — Basic delivery',
    title: 'notification and data together',
    description:
        'The common shape in production. Watch whether the data map reaches the '
        'handler after a tap, which is where deep links get their arguments.',
    payloadTemplate: {
      'notification': {
        'title': 'Build finished',
        'body': 'Release 1.0.0 is ready.',
      },
      'data': {'event': 'build_finished', 'deep_link': '/builds/128'},
    },
  ),
  Scenario(
    id: 'a4_no_display',
    group: 'A — Basic delivery',
    title: 'Data with nothing drawn, logged only',
    description:
        'A silent synchronisation: the handler runs and writes a log line, and '
        'the user sees nothing at all. Watch the inbox rather than the tray.',
    payloadTemplate: {
      'data': {'event': 'log_only', 'silent': 'true'},
    },
  ),
];
```

- [ ] **Step 4: Implement `scenario_gallery.dart`**

```dart
import 'group_a.dart';
import 'scenario.dart';

/// The scenario catalogue, in the order of the source document.
///
/// Eleven groups, each authored in its own file against one table of that
/// document, concatenated here. The name and type are unchanged from the
/// nine-scenario gallery this replaces, so every consumer compiles untouched.
const scenarioGallery = <Scenario>[...groupA];
```

Delete the old `scenarioGallery` from `scenario.dart`, export both new files from the barrel (alphabetically: `src/scenarios/group_a.dart`, `src/scenarios/scenario.dart`, `src/scenarios/scenario_gallery.dart`, `src/scenarios/scenario_need.dart`), and re-point every test the grep found using the mapping table above.

- [ ] **Step 5: Verify**

Run the new test file, then `fvm dart run melos run format` and `fvm dart run melos run ci` — exit 0.

**This task will fail the gate until every old id is migrated.** That is intended: the compiler and the tests together enumerate the work. Report which files you changed and confirm `grep -rn 'big_picture_remote\|data_only\|apns_alert\|custom_channel' apps packages --include=*.dart` returns nothing.

- [ ] **Step 6: Commit**

```bash
git add packages apps
git commit -m "feat(shared): start the catalogue with group A"
```

---
