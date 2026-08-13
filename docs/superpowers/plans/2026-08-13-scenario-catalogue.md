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
- Modify: `packages/fcm_gallery_shared/lib/fcm_gallery_shared.dart` (add the export **last**: `send_m` sorts before `send_t`, so `src/send_target.dart` follows `src/send_message_response.dart`, not `src/scenario.dart`)
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

  // There is no field to hash, so every instance is the same value and the type
  // is the whole identity. NOT `AllDevicesTarget.hashCode` — that is static member
  // access on a class with no such static, and does not compile.
  @override
  int get hashCode => runtimeType.hashCode;

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

  test('a killed-app scenario needs delayed sending to be arranged', () {
    // Gives requiresKilledApp exactly one meaning: "meaningless unless the app
    // is killed". Arranging that means holding the send, so the flag and the
    // need go together. Without this the flag drifts into meaning "the killed
    // case is the interesting one", which is true of far more scenarios and
    // tells the Sandbox nothing. This replaces the invariant the legacy
    // scenario_test.dart used to guard.
    for (final scenario in scenarioGallery) {
      if (scenario.requiresKilledApp) {
        expect(
          scenario.needs,
          contains(ScenarioNeed.delayedSend),
          reason: scenario.id,
        );
        expect(
          scenario.defaultDelaySeconds,
          greaterThan(0),
          reason: '${scenario.id} must say how long to hold the send',
        );
      }
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
      // Sendable today, so no killed-app flag: see the comment on the entry.
      expect(dataOnly.requiresKilledApp, isFalse);
      expect(dataOnly.isSupported, isTrue);
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
    // Deliberately NOT requiresKilledApp, despite the description asking about
    // the killed case. That flag means "meaningless unless the app is killed",
    // which implies delayed sending is needed to arrange it at all — and a
    // data-only push is observable in every app state, so this one is sendable
    // today. b3_killed is the scenario that is only about the killed state, and
    // it carries the flag and the need together.
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

## Tasks 5–14: one group per task

Each of these ten tasks has the **same mechanics**, spelled out here once so the
per-task sections carry only what differs — the data, and the assertions specific
to that group. Every one of Tasks 5–14 performs these steps:

1. **Write the failing test** at `packages/fcm_gallery_shared/test/scenarios/group_<x>_test.dart`, asserting the group's exact id list in order, and the group-specific assertions given in the task. **Also assert every id in the group is present in `scenarioGallery`** — added on Task 5, because it is the one thing that catches writing the data file and forgetting the spread append in step 4, which every gallery-wide test would happily pass with the file orphaned. Compare **ids, not `Scenario` instances**: `Scenario` has no `operator ==`, so a `contains(scenario)` matcher would be relying on const canonicalisation.
2. **Run it and see it fail:** `fvm dart test packages/fcm_gallery_shared/test/scenarios/group_<x>_test.dart` — `group<X>` not found.
3. **Create** `packages/fcm_gallery_shared/lib/src/scenarios/group_<x>.dart` with the `const group<X>` list given in the task.
4. **Append it** to `scenario_gallery.dart`'s spread, in letter order, and **export** the new file from `packages/fcm_gallery_shared/lib/fcm_gallery_shared.dart` in alphabetical position.
5. **Run** `fvm dart run melos run format`, then `fvm dart run melos run ci` — exit 0. The gallery-wide tests from Task 4 now also cover the new group; if the round-trip assertion fails, a template has a key the typed model does not define — fix the template, never the assertion.
6. **Commit:** `git add packages && git commit -m "feat(shared): add scenario group <X>"`

Report, per task: the measured `fcm_gallery_shared` count, and the running
`scenarioGallery.length`.

**Every `payloadTemplate` below round-trips through `FcmMessage.fromJson`.** They
use only snake_case keys the typed model defines. `data` values are always strings —
FCM's `data` map is `map<string, string>` and the model enforces it, so `'5'` not `5`.

---

### Task 5: Group B — Application states

Six scenarios where the *state of the app* is the variable, not the payload. Five
of the six need a step no payload can perform, which is why `manualSteps` exists.

Group-specific assertions:

```dart
    test('b3 is the one that drives the delayed-send work', () {
      final killed = groupB.firstWhere((s) => s.id == 'b3_killed');

      expect(killed.needs, contains(ScenarioNeed.delayedSend));
      expect(killed.requiresKilledApp, isTrue);
      expect(killed.defaultDelaySeconds, greaterThan(0));
    });

    test('b5 expects NOT to arrive, and says so', () {
      // A scenario whose success is a non-delivery has to state that, or it
      // reads as a broken test. `contains('not')` would NOT do here: it is
      // satisfied accidentally by the word "nothing", so it would pass on an
      // expectation that never mentioned non-delivery at all.
      final forceStopped = groupB.firstWhere((s) => s.id == 'b5_force_stopped');

      expect(forceStopped.expectation, contains('nothing'));
      expect(forceStopped.expectation, contains('force-stopped'));
    });

    test('every manual-step scenario spells out the step', () {
      for (final scenario in groupB) {
        if (scenario.needs.contains(ScenarioNeed.manualStep)) {
          expect(scenario.manualSteps, isNotNull, reason: scenario.id);
          expect(scenario.manualSteps!.trim(), isNotEmpty, reason: scenario.id);
        }
      }
    });
```

```dart
import 'scenario.dart';
import 'scenario_need.dart';

/// **B — Application states.** The same push, delivered into six different
/// conditions of the app.
///
/// Nothing here varies the payload: every difference is in what the app is doing
/// when the message lands. That is why five of the six carry a manual step — no
/// payload can kill an app, reboot a phone or revoke a permission.
const groupB = <Scenario>[
  Scenario(
    id: 'b1_foreground',
    group: 'B — Application states',
    title: 'Delivered with the app in the foreground',
    description:
        'onMessage fires and nothing is drawn by the system, so the app must '
        'draw it. Watch that a banner appears at all.',
    payloadTemplate: {
      'notification': {'title': 'Foreground', 'body': 'Drawn by the app.'},
      'data': {'event': 'foreground'},
    },
  ),
  Scenario(
    id: 'b2_background',
    group: 'B — Application states',
    title: 'App backgrounded, screen locked',
    description:
        'The system draws this one. Watch whether it reaches the lock screen '
        'and how much of it is shown there.',
    payloadTemplate: {
      'notification': {'title': 'Backgrounded', 'body': 'Drawn by Android.'},
    },
    needs: [ScenarioNeed.manualStep],
    manualSteps:
        'Background the app with the home button, then lock the screen. Send '
        'from another machine, or use validate-only first to check the payload.',
  ),
  Scenario(
    id: 'b3_killed',
    group: 'B — Application states',
    title: 'App swiped out of recents',
    description:
        'The hardest case, and the reason delayed sending exists: the send has '
        'to happen after the app is gone. Watch whether the data handler runs.',
    payloadTemplate: {
      'data': {'event': 'killed_probe', 'sent_at_stage': 'killed'},
      'android': {'priority': 'HIGH'},
    },
    needs: [ScenarioNeed.delayedSend],
    requiresKilledApp: true,
    defaultDelaySeconds: 20,
  ),
  Scenario(
    id: 'b4_after_reboot',
    group: 'B — Application states',
    title: 'After a reboot, app never opened',
    description:
        'Until the app is opened once after boot, some manufacturers hold its '
        'background work entirely. Watch whether anything arrives.',
    payloadTemplate: {
      'notification': {'title': 'After reboot', 'body': 'Did this arrive?'},
      'android': {'priority': 'HIGH', 'direct_boot_ok': true},
    },
    needs: [ScenarioNeed.manualStep],
    manualSteps:
        'adb reboot — then do NOT open the app. Wait for the lock screen and '
        'send.',
  ),
  Scenario(
    id: 'b5_force_stopped',
    group: 'B — Application states',
    title: 'After Force stop',
    description:
        'Force stop revokes the app\'s ability to be woken. This scenario '
        'exists to prove we know that, rather than to be debugged.',
    expectation:
        'Expected to arrive: nothing. A force-stopped app receives no pushes at '
        'all until it is launched by hand. If something does arrive, that is the '
        'surprise worth investigating.',
    payloadTemplate: {
      'notification': {'title': 'Force stopped', 'body': 'Should not arrive.'},
      'android': {'priority': 'HIGH'},
    },
    needs: [ScenarioNeed.manualStep],
    manualSteps:
        'Settings › Apps › FCM Sample › Force stop. Then send, and expect '
        'nothing.',
  ),
  Scenario(
    id: 'b6_token_refresh',
    group: 'B — Application states',
    title: 'Token rotated by a reinstall or clear-data',
    description:
        'The old token is dead and sending to it must fail loudly. Watch the '
        'Inbox page for the new token, and compare it with the old one.',
    payloadTemplate: {
      'notification': {'title': 'Token check', 'body': 'Which token got this?'},
    },
    needs: [ScenarioNeed.manualStep],
    manualSteps:
        'adb shell pm clear cz.netglade.fcm_app — reopen the app and read the '
        'new token off the Inbox page. Sending to the old one should give '
        'UNREGISTERED, which is k2_invalid_token.',
  ),
];
```

---

### Task 6: Group C — Priority and delivery window

Group-specific assertions:

```dart
    test('the two priority scenarios differ only in priority', () {
      final high = groupC.firstWhere((s) => s.id == 'c1_priority_high');
      final normal = groupC.firstWhere((s) => s.id == 'c2_priority_normal');

      expect(
        (high.payloadTemplate['android']! as Map)['priority'],
        'HIGH',
      );
      expect(
        (normal.payloadTemplate['android']! as Map)['priority'],
        'NORMAL',
      );
    });

    test('both ttl scenarios use a proto duration, not a number', () {
      // FCM wants "0s", not 0. A bare number is a 400 from Google.
      //
      // Matched against the full duration shape rather than endsWith('s'):
      // '86400 seconds', '0 s' and even 'abcs' all end in s, so that check
      // would pass on three spellings FCM rejects.
      final duration = RegExp(r'^\d+(\.\d+)?s$');

      for (final id in const ['c3_ttl_zero', 'c4_ttl_long']) {
        final ttl =
            (groupC.firstWhere((s) => s.id == id).payloadTemplate['android']!
                as Map)['ttl'];
        expect(ttl, isA<String>(), reason: id);
        expect(ttl, matches(duration), reason: id);
      }
    });

    test('the adb scenarios carry a runnable command, not just a keyword', () {
      // contains('force-idle') alone would pass on prose that merely mentioned
      // the flag. These are commands a user copies verbatim, so the assertion
      // pins the whole invocation.
      expect(
        groupC.firstWhere((s) => s.id == 'c6_doze_test').manualSteps,
        contains('adb shell dumpsys deviceidle force-idle'),
      );
      expect(
        groupC.firstWhere((s) => s.id == 'c7_standby_bucket').manualSteps,
        contains('adb shell am set-standby-bucket cz.netglade.fcm_app'),
      );
    });
```

```dart
import 'scenario.dart';
import 'scenario_need.dart';

/// **C — Priority and delivery window.** How hard FCM tries, and for how long.
///
/// The group that explains most "it arrived twenty minutes late" reports: NORMAL
/// priority may wait for a maintenance window, and Doze extends that window a
/// long way. The last two are adb commands rather than payloads, because Doze
/// cannot be entered by asking politely.
const groupC = <Scenario>[
  Scenario(
    id: 'c1_priority_high',
    group: 'C — Priority and delivery window',
    title: 'android.priority HIGH',
    description:
        'Wakes a dozing device. Watch how quickly it lands with the screen off '
        'compared with c2.',
    payloadTemplate: {
      'notification': {'title': 'High priority', 'body': 'Should wake now.'},
      'android': {'priority': 'HIGH'},
    },
  ),
  Scenario(
    id: 'c2_priority_normal',
    group: 'C — Priority and delivery window',
    title: 'android.priority NORMAL',
    description:
        'May wait for the next maintenance window. Watch for a delay with the '
        'screen off — this is the usual cause of a "missing" push.',
    payloadTemplate: {
      'notification': {'title': 'Normal priority', 'body': 'May be held.'},
      'android': {'priority': 'NORMAL'},
    },
  ),
  Scenario(
    id: 'c3_ttl_zero',
    group: 'C — Priority and delivery window',
    title: 'android.ttl 0s — now or never',
    description:
        'FCM makes one attempt and discards the message if the device is not '
        'reachable. Watch that an offline device never receives it.',
    payloadTemplate: {
      'notification': {'title': 'Now or never', 'body': 'ttl 0s.'},
      'android': {'priority': 'HIGH', 'ttl': '0s'},
    },
  ),
  Scenario(
    id: 'c4_ttl_long',
    group: 'C — Priority and delivery window',
    title: 'android.ttl 86400s — a day of retries',
    description:
        'Held for 24 hours. Watch it arrive when the network comes back, long '
        'after it was sent.',
    payloadTemplate: {
      'notification': {'title': 'Patient', 'body': 'ttl 86400s.'},
      'android': {'priority': 'HIGH', 'ttl': '86400s'},
    },
  ),
  Scenario(
    id: 'c5_collapse_key',
    group: 'C — Priority and delivery window',
    title: 'Five sends sharing a collapse_key, offline',
    description:
        'Only the last should survive. Watch that one notification appears, not '
        'five, once the network returns.',
    payloadTemplate: {
      'notification': {'title': 'Collapsible', 'body': 'Only the last one.'},
      'android': {'priority': 'HIGH', 'collapse_key': 'builds'},
    },
    needs: [ScenarioNeed.manualStep],
    manualSteps:
        'Put the device in airplane mode. Send five times, changing the body '
        'each time. Restore the network: exactly one notification should appear, '
        'carrying the last body.',
  ),
  Scenario(
    id: 'c6_doze_test',
    group: 'C — Priority and delivery window',
    title: 'Delivery while the device is in Doze',
    description:
        'Real Doze behaviour, not a simulation. Watch which priorities break '
        'through and which are held.',
    payloadTemplate: {
      'notification': {'title': 'Doze probe', 'body': 'Did this break through?'},
      'android': {'priority': 'HIGH'},
    },
    needs: [ScenarioNeed.manualStep],
    manualSteps:
        'adb shell dumpsys deviceidle force-idle — send, then '
        'adb shell dumpsys deviceidle unforce to restore.',
  ),
  Scenario(
    id: 'c7_standby_bucket',
    group: 'C — Priority and delivery window',
    title: 'App in the restricted standby bucket',
    description:
        'The harshest state Android imposes on an unused app. Watch whether a '
        'HIGH priority push still arrives.',
    payloadTemplate: {
      'notification': {'title': 'Restricted', 'body': 'Bucket probe.'},
      'android': {'priority': 'HIGH'},
    },
    needs: [ScenarioNeed.manualStep],
    manualSteps:
        'adb shell am set-standby-bucket cz.netglade.fcm_app restricted — check '
        'with adb shell am get-standby-bucket cz.netglade.fcm_app.',
  ),
];
```

---

### Task 7: Group D — Channels and importance

All eight need `ScenarioNeed.channels`.

**The `custom_channel` stand-in turned out to be a no-op**, verified on Task 7
against history: the legacy id existed only as a gallery entry in the old
`scenario.dart` and was never referenced by a test, so Task 4 had nothing to
re-point and neither does this task. Checked with
`git grep custom_channel 3cc6091^ -- '*.dart'`. The `apns_alert` stand-in was real
and is Task 10's to resolve.

Group-specific assertions:

```dart
    test('all eight are blocked on channel work', () {
      for (final scenario in groupD) {
        expect(scenario.needs, [ScenarioNeed.channels], reason: scenario.id);
      }
    });

    test('each names a distinct, non-blank channel — that is the variable', () {
      // Set-uniqueness alone is NOT enough: an entry that omitted channel_id
      // contributes null, and a lone null is as "distinct" as any string, so the
      // test would pass while one of the eight named no channel at all — the one
      // defect this group cannot tolerate.
      final channels = groupD
          .map(
            (s) =>
                ((s.payloadTemplate['android']! as Map)['notification']!
                    as Map)['channel_id'],
          )
          .toList();

      for (final channel in channels) {
        expect(channel, isA<String>());
        expect(channel, isNotEmpty);
      }
      expect(channels.toSet(), hasLength(channels.length));
    });

    test('d7 states that Android ignores the change, and names the fix', () {
      // NOT "the immutability scenario is versioned": d7's own channel is
      // deliberately chat_v1, the UNversioned one — d8 is the versioned one — so
      // that name would be false. And contains('ignore') alone is satisfied by
      // prose meaning the opposite ("do not ignore"), while contains('_v2')
      // matches any token ending _v2 including a typo'd channel id.
      final immutable = groupD.firstWhere(
        (s) => s.id == 'd7_channel_immutability',
      );

      expect(channelIdOf(immutable), 'chat_v1');
      expect(immutable.description, contains('ignore the change'));
      expect(immutable.expectation, contains('chat_v2'));
      expect(channelIdOf(groupD.last), 'chat_v2', reason: 'the fix d7 names');
    });
```

```dart
import 'scenario.dart';
import 'scenario_need.dart';

/// **D — Channels and importance.** What the user, not the sender, controls.
///
/// Importance is a property of the *channel*, set once when it is created, and
/// Android ignores every later attempt to change it — so a channel is effectively
/// immutable and the only fix is a new one with a new id. That is why d7 exists,
/// and why channels get versioned names like `chat_v2`.
///
/// None of these demonstrates anything until the app registers the channels and
/// offers a screen showing each one's importance **as read back from the system**.
/// Reading it from our own code would only ever tell us what we asked for, not
/// what the user has since changed.
const groupD = <Scenario>[
  Scenario(
    id: 'd1_importance_high',
    group: 'D — Channels and importance',
    title: 'IMPORTANCE_HIGH — heads-up banner',
    description:
        'Watch for a banner that floats over the current app, with sound.',
    payloadTemplate: {
      'notification': {'title': 'Heads up', 'body': 'Importance high.'},
      'android': {
        'priority': 'HIGH',
        'notification': {'channel_id': 'importance_high'},
      },
    },
    needs: [ScenarioNeed.channels],
  ),
  Scenario(
    id: 'd2_importance_default',
    group: 'D — Channels and importance',
    title: 'IMPORTANCE_DEFAULT — sound, no banner',
    description: 'Watch for a sound and a tray entry, but nothing floating.',
    payloadTemplate: {
      'notification': {'title': 'Default', 'body': 'Sound, no banner.'},
      'android': {'notification': {'channel_id': 'importance_default'}},
    },
    needs: [ScenarioNeed.channels],
  ),
  Scenario(
    id: 'd3_importance_low',
    group: 'D — Channels and importance',
    title: 'IMPORTANCE_LOW — silent',
    description:
        'Visible but with no sound and no vibration. Watch that it is genuinely '
        'silent rather than quiet.',
    payloadTemplate: {
      'notification': {'title': 'Low', 'body': 'No sound, no vibration.'},
      'android': {'notification': {'channel_id': 'importance_low'}},
    },
    needs: [ScenarioNeed.channels],
  ),
  Scenario(
    id: 'd4_importance_min',
    group: 'D — Channels and importance',
    title: 'IMPORTANCE_MIN — status bar only',
    description:
        'No icon in the status bar on some versions; only in the shade. Watch '
        'where it appears at all.',
    payloadTemplate: {
      'notification': {'title': 'Min', 'body': 'Shade only.'},
      'android': {'notification': {'channel_id': 'importance_min'}},
    },
    needs: [ScenarioNeed.channels],
  ),
  Scenario(
    id: 'd5_custom_sound',
    group: 'D — Channels and importance',
    title: 'A custom sound on the channel',
    description:
        'The sound is a channel property, so changing it needs a new channel. '
        'Watch that the custom sound plays rather than the default.',
    expectation:
        'The named resource must exist in android/app/src/main/res/raw. A '
        'missing file falls back to the default sound silently.',
    payloadTemplate: {
      'notification': {'title': 'Custom sound', 'body': 'Should chime.'},
      'android': {
        'notification': {'channel_id': 'custom_sound', 'sound': 'chime'},
      },
    },
    needs: [ScenarioNeed.channels],
  ),
  Scenario(
    id: 'd6_vibration_pattern',
    group: 'D — Channels and importance',
    title: 'A custom vibration pattern',
    description:
        'Alternating vibrate and pause durations. Watch that the pattern is the '
        'one asked for rather than the channel default.',
    payloadTemplate: {
      'notification': {'title': 'Buzz', 'body': 'Short, long, short.'},
      'android': {
        'notification': {
          'channel_id': 'vibration_pattern',
          'default_vibrate_timings': false,
          'vibrate_timings': ['0s', '0.4s', '0.2s', '0.4s'],
        },
      },
    },
    needs: [ScenarioNeed.channels],
  ),
  Scenario(
    id: 'd7_channel_immutability',
    group: 'D — Channels and importance',
    title: 'Changing an existing channel — Android will ignore it',
    description:
        'Re-create chat_v1 with a different importance and watch Android ignore '
        'the change completely. This is the demonstration of why channels carry '
        'a version in their id.',
    expectation:
        'The importance shown on the channel screen stays at its original '
        'value. The only fix is a new channel — chat_v2 — which is what d8 uses.',
    payloadTemplate: {
      'notification': {'title': 'chat_v1', 'body': 'Importance is frozen.'},
      'android': {'notification': {'channel_id': 'chat_v1'}},
    },
    needs: [ScenarioNeed.channels],
  ),
  Scenario(
    id: 'd8_channel_group',
    group: 'D — Channels and importance',
    title: 'Channels collected into a group',
    description:
        'Watch the system notification settings: the channels should appear '
        'nested under a named group rather than as a flat list.',
    payloadTemplate: {
      'notification': {'title': 'chat_v2', 'body': 'Grouped in settings.'},
      'android': {'notification': {'channel_id': 'chat_v2'}},
    },
    needs: [ScenarioNeed.channels],
  ),
];
```

---

### Task 8: Group E — Appearance

Eleven scenarios, five of which work today. **Also re-point** any test using
`a1_notification_only` as a stand-in for the old `big_picture_remote` id: it becomes
`e2_image_remote`.

Group-specific assertions:

```dart
    test('exactly five of the eleven work today', () {
      // The count is asserted so that quietly unmarking one to look supported
      // fails the build.
      expect(groupE.where((s) => s.isSupported).map((s) => s.id), [
        'e2_image_remote',
        'e4_image_huge',
        'e5_image_404',
        'e10_color_and_icon',
        'e11_emoji_rtl',
      ]);
    });

    test('the long-text body is genuinely long, with diacritics', () {
      final long = groupE.firstWhere((s) => s.id == 'e1_long_text');
      final body =
          (long.payloadTemplate['notification']! as Map)['body']! as String;

      expect(body.length, greaterThan(600));
      expect(body, contains('ě'));
    });

    test('e2 warns that iOS needs a service extension', () {
      final remote = groupE.firstWhere((s) => s.id == 'e2_image_remote');

      expect(remote.expectation, contains('Notification Service Extension'));
    });

    test('the 404 scenario points somewhere that cannot resolve', () {
      final broken = groupE.firstWhere((s) => s.id == 'e5_image_404');
      final image =
          (broken.payloadTemplate['notification']! as Map)['image']! as String;

      expect(image, contains('example.test'));
    });
```

```dart
import 'scenario.dart';
import 'scenario_need.dart';

/// **E — Appearance.** How a notification looks once something decides to draw it.
///
/// Split down the middle: `notification.image`, `color` and long or awkward text
/// are FCM fields and work now, while big-picture-from-a-download, large icons and
/// the inbox, messaging and progress styles are all things the *client* builds and
/// FCM has no field for. That division is why half this group is blocked.
const groupE = <Scenario>[
  Scenario(
    id: 'e1_long_text',
    group: 'E — Appearance',
    title: 'BigTextStyle with ~800 characters',
    description:
        'Watch where the text is cut in the collapsed view, and whether '
        'expanding shows all of it. Diacritics are included because byte-length '
        'and character-length limits behave differently.',
    payloadTemplate: {
      'notification': {
        'title': 'Release notes',
        'body':
            'Tato zpráva je záměrně velmi dlouhá, protože potřebujeme zjistit, '
            'kde přesně Android text ořízne ve sbalené podobě a co se stane po '
            'rozbalení. Obsahuje diakritiku — ěščřžýáíé — aby bylo vidět, jestli '
            'se limit počítá v bajtech nebo ve znacích, což se u UTF-8 liší '
            'zásadně. Dále obsahuje několik vět za sebou, aby bylo možné '
            'posoudit, jak se zachází s odstavci a zda se zachovají mezery mezi '
            'větami. Notifikace tohoto typu se v praxi používají pro poznámky k '
            'vydání, delší zprávy v chatu nebo popisy chyb, takže je užitečné '
            'vědět, kolik textu má vůbec smysl posílat a kdy je lepší otevřít '
            'aplikaci. Pokud se text ořízne příliš brzy, je nutné zvolit jiný '
            'styl notifikace nebo zkrátit obsah na serveru ještě před odesláním.',
      },
    },
    needs: [ScenarioNeed.styles],
  ),
  Scenario(
    id: 'e2_image_remote',
    group: 'E — Appearance',
    title: 'notification.image — fetched by the platform',
    description:
        'FCM passes a URL and the platform downloads it. Watch that it appears '
        'expanded, and how long it takes on a slow connection.',
    expectation:
        'Android does this natively. iOS requires a Notification Service '
        'Extension, which this app does not ship, so nothing will render there.',
    payloadTemplate: {
      'notification': {
        'title': 'With an image',
        'body': 'Expand to see it.',
        'image': 'https://picsum.photos/1200/600',
      },
    },
  ),
  Scenario(
    id: 'e3_image_local',
    group: 'E — Appearance',
    title: 'Image downloaded by the data handler',
    description:
        'The app fetches the URL itself and builds a BigPictureStyle. Compare '
        'the result and the timing against e2.',
    payloadTemplate: {
      'data': {
        'style': 'big_picture',
        'image_url': 'https://picsum.photos/1200/600',
        'title': 'Downloaded locally',
        'body': 'Built by the app, not the platform.',
      },
    },
    needs: [ScenarioNeed.styles],
  ),
  Scenario(
    id: 'e4_image_huge',
    group: 'E — Appearance',
    title: 'A 4000×3000 image',
    description:
        'Watch for a resize, an out-of-memory kill, or a silent failure where '
        'the text arrives and the picture does not.',
    payloadTemplate: {
      'notification': {
        'title': 'Very large image',
        'body': 'Does this survive?',
        'image': 'https://picsum.photos/4000/3000',
      },
    },
  ),
  Scenario(
    id: 'e5_image_404',
    group: 'E — Appearance',
    title: 'An image URL that does not resolve',
    description:
        'The important question is whether the text still arrives. A push that '
        'vanishes because its picture 404s is a bad failure mode.',
    payloadTemplate: {
      'notification': {
        'title': 'Broken image',
        'body': 'The text should still be here.',
        'image': 'https://example.test/missing.png',
      },
    },
  ),
  Scenario(
    id: 'e6_large_icon',
    group: 'E — Appearance',
    title: 'A large icon beside the text',
    description:
        'The round avatar slot, distinct from the small status-bar icon. Watch '
        'that it is circular and not stretched.',
    payloadTemplate: {
      'data': {
        'style': 'large_icon',
        'large_icon_url': 'https://picsum.photos/200/200',
        'title': 'With an avatar',
        'body': 'Round icon on the right.',
      },
    },
    needs: [ScenarioNeed.styles],
  ),
  Scenario(
    id: 'e7_inbox_style',
    group: 'E — Appearance',
    title: 'InboxStyle with seven lines',
    description:
        'Watch how many lines are actually shown when expanded — Android caps '
        'it, and the cap is lower than most people expect.',
    payloadTemplate: {
      'data': {
        'style': 'inbox',
        'title': '7 new builds',
        'lines':
            'build 128 passed|build 127 passed|build 126 failed|build 125 '
            'passed|build 124 passed|build 123 failed|build 122 passed',
      },
    },
    needs: [ScenarioNeed.styles],
  ),
  Scenario(
    id: 'e8_messaging_style',
    group: 'E — Appearance',
    title: 'MessagingStyle with several senders',
    description:
        'The chat layout, with a name and avatar per message. Watch the '
        'grouping and the ordering.',
    payloadTemplate: {
      'data': {
        'style': 'messaging',
        'conversation': 'Release team',
        'messages': 'Ada:ready when you are|Grace:shipping now|Ada:👍',
      },
    },
    needs: [ScenarioNeed.styles],
  ),
  Scenario(
    id: 'e9_progress',
    group: 'E — Appearance',
    title: 'A progress bar, updated in place',
    description:
        'Several pushes updating one notification. Watch that it updates rather '
        'than stacking, and what happens when it completes.',
    payloadTemplate: {
      'data': {
        'style': 'progress',
        'title': 'Downloading',
        'progress': '40',
        'max': '100',
      },
    },
    needs: [ScenarioNeed.styles],
  ),
  Scenario(
    id: 'e10_color_and_icon',
    group: 'E — Appearance',
    title: 'Accent colour and a monochrome icon',
    description:
        'The classic Xiaomi white-square bug: a small icon that is not a flat '
        'monochrome alpha mask renders as a filled block. Watch the status bar.',
    expectation:
        'The icon must be a monochrome drawable with transparency. A full-colour '
        'launcher icon is what produces the white square.',
    payloadTemplate: {
      'notification': {'title': 'Tinted', 'body': 'Check the small icon.'},
      'android': {
        'notification': {'color': '#4285f4', 'icon': 'ic_stat_notify'},
      },
    },
  ),
  Scenario(
    id: 'e11_emoji_rtl',
    group: 'E — Appearance',
    title: 'Emoji, right-to-left text and unbreakable words',
    description:
        'Watch the text direction of the Arabic line, whether the emoji render '
        'in colour, and where a word with no spaces is broken.',
    payloadTemplate: {
      'notification': {
        'title': 'Mixed 🍺 نص عربي',
        'body':
            'مرحبا بالعالم — and a very long unbreakable token: '
            'Donaudampfschiffahrtselektrizitaetenhauptbetriebswerkbauunterbeamten'
            'gesellschaft 🎉🍺🚀',
      },
    },
  ),
];
```

---

### Task 9: Group F — Interaction

All nine need `ScenarioNeed.interaction`; F8 needs `externalApproval` too.

Group-specific assertions:

```dart
    test('all nine are blocked on interaction work', () {
      for (final scenario in groupF) {
        expect(
          scenario.needs,
          contains(ScenarioNeed.interaction),
          reason: scenario.id,
        );
      }
    });

    test('f8 also needs a permission Android 14+ may refuse', () {
      final fullScreen = groupF.firstWhere(
        (s) => s.id == 'f8_full_screen_intent',
      );

      expect(fullScreen.needs, contains(ScenarioNeed.externalApproval));
      expect(fullScreen.expectation, contains('USE_FULL_SCREEN_INTENT'));
    });

    test('the three deep-link scenarios all carry a link to route to', () {
      for (final id in const [
        'f3_deeplink_foreground',
        'f4_deeplink_background',
        'f5_deeplink_killed',
      ]) {
        final scenario = groupF.firstWhere((s) => s.id == id);
        expect(
          (scenario.payloadTemplate['data']! as Map)['deep_link'],
          isNotNull,
          reason: id,
        );
      }
    });

    test('f5 says it is the commonest source of bugs', () {
      expect(
        groupF.firstWhere((s) => s.id == 'f5_deeplink_killed').description,
        contains('getInitialMessage'),
      );
    });
```

```dart
import 'scenario.dart';
import 'scenario_need.dart';

/// **F — Interaction.** What happens when the user touches it, or does not.
///
/// FCM has no field for any of this: action buttons, inline replies and
/// full-screen intents are all built by the client from `data`. The three
/// deep-link scenarios are separated by app state on purpose — foreground,
/// background and killed take three different code paths
/// (`onMessage`, `onMessageOpenedApp`, `getInitialMessage`), and the third is
/// where most routing bugs live because it is the one that is easy to forget.
const groupF = <Scenario>[
  Scenario(
    id: 'f1_actions',
    group: 'F — Interaction',
    title: 'Two or three action buttons',
    description:
        'Watch whether the buttons survive a reboot of the notification shade, '
        'and what happens to the notification when one is pressed.',
    payloadTemplate: {
      'notification': {'title': 'Build failed', 'body': 'Retry or open?'},
      'data': {'actions': 'retry:Retry|open:Open build', 'build': '128'},
    },
    needs: [ScenarioNeed.interaction],
  ),
  Scenario(
    id: 'f2_inline_reply',
    group: 'F — Interaction',
    title: 'Inline reply with RemoteInput',
    description:
        'Type a reply without opening the app. Watch that the notification '
        'shows a sending state and then updates.',
    payloadTemplate: {
      'notification': {'title': 'Ada', 'body': 'ready when you are'},
      'data': {'reply_to': 'thread-42', 'actions': 'reply:Reply'},
    },
    needs: [ScenarioNeed.interaction],
  ),
  Scenario(
    id: 'f3_deeplink_foreground',
    group: 'F — Interaction',
    title: 'Tap while the app is running',
    description:
        'Routing from onMessage, with the app already on screen. Watch that the '
        'current screen is not lost.',
    payloadTemplate: {
      'notification': {'title': 'Open build 128', 'body': 'Tap to route.'},
      'data': {'deep_link': '/builds/128'},
    },
    needs: [ScenarioNeed.interaction],
  ),
  Scenario(
    id: 'f4_deeplink_background',
    group: 'F — Interaction',
    title: 'Tap while the app is backgrounded',
    description:
        'Routing from onMessageOpenedApp. Watch that the app resumes on the '
        'linked screen rather than where it was left.',
    payloadTemplate: {
      'notification': {'title': 'Open build 127', 'body': 'Tap to route.'},
      'data': {'deep_link': '/builds/127'},
    },
    needs: [ScenarioNeed.interaction],
  ),
  Scenario(
    id: 'f5_deeplink_killed',
    group: 'F — Interaction',
    title: 'Tap with the app killed',
    description:
        'Routing from getInitialMessage, which runs once at startup and is the '
        'commonest source of deep-link bugs — it is easy to forget, and it fails '
        'only in the one state nobody tests by hand.',
    payloadTemplate: {
      'notification': {'title': 'Open build 126', 'body': 'Tap to route.'},
      'data': {'deep_link': '/builds/126'},
    },
    // delayedSend as well as interaction: requiresKilledApp means the scenario
    // is meaningless in any other state, and arranging that means holding the
    // send until the app is gone.
    needs: [ScenarioNeed.interaction, ScenarioNeed.delayedSend],
    requiresKilledApp: true,
    defaultDelaySeconds: 20,
  ),
  Scenario(
    id: 'f6_delete_intent',
    group: 'F — Interaction',
    title: 'Detecting a swipe-away',
    description:
        'The delete intent fires when the user dismisses without tapping. Watch '
        'that it is distinguishable from a tap.',
    payloadTemplate: {
      'notification': {'title': 'Dismiss me', 'body': 'Swipe, do not tap.'},
      'data': {'track_dismiss': 'true'},
    },
    needs: [ScenarioNeed.interaction],
  ),
  Scenario(
    id: 'f7_ongoing',
    group: 'F — Interaction',
    title: 'An ongoing, undismissable notification',
    description:
        'Watch that it cannot be swiped away, and confirm there is a way to '
        'clear it — an ongoing notification with no exit is a support ticket.',
    payloadTemplate: {
      'notification': {'title': 'Syncing', 'body': 'Cannot be dismissed.'},
      'data': {'ongoing': 'true'},
    },
    needs: [ScenarioNeed.interaction],
  ),
  Scenario(
    id: 'f8_full_screen_intent',
    group: 'F — Interaction',
    title: 'Full-screen intent, as an incoming call',
    description:
        'Takes over the lock screen. Watch whether it is granted at all, and '
        'what it degrades to when it is refused.',
    expectation:
        'Needs the USE_FULL_SCREEN_INTENT permission, which Android 14+ grants '
        'only to calling and alarm apps. Expect a degraded heads-up notification '
        'rather than a takeover here.',
    payloadTemplate: {
      'notification': {'title': 'Incoming call', 'body': 'Ada is calling.'},
      'android': {
        'priority': 'HIGH',
        'notification': {'channel_id': 'calls'},
      },
      'data': {'full_screen': 'true', 'caller': 'Ada'},
    },
    needs: [ScenarioNeed.interaction, ScenarioNeed.externalApproval],
  ),
  Scenario(
    id: 'f9_trampoline',
    group: 'F — Interaction',
    title: 'A notification trampoline, which should fail',
    description:
        'Starting an activity from a service or broadcast receiver after a tap. '
        'Banned since Android 12. Watch for the failure and its log line.',
    expectation:
        'Expected to fail on Android 12 and later. The demonstration is the '
        'error, not a working route.',
    payloadTemplate: {
      'notification': {'title': 'Trampoline', 'body': 'This should not work.'},
      'data': {'trampoline': 'true', 'deep_link': '/builds/125'},
    },
    needs: [ScenarioNeed.interaction],
  ),
];
```

---

### Task 10: Group G — Groups, badge, updates

**Also re-point** any test using `a3_hybrid` as a stand-in for the old `apns_alert`
id: it becomes `g4_badge_ios`.

Group-specific assertions:

```dart
    test('only the iOS badge scenario works today', () {
      expect(groupG.where((s) => s.isSupported).map((s) => s.id), [
        'g4_badge_ios',
      ]);
    });

    test('the Android badge uses notification_count, an FCM field', () {
      final badge = groupG.firstWhere((s) => s.id == 'g3_badge');

      expect(
        ((badge.payloadTemplate['android']! as Map)['notification']!
            as Map)['notification_count'],
        5,
      );
      expect(badge.needs, [ScenarioNeed.badge]);
    });

    test('the iOS badge rides inside the free-form aps dictionary', () {
      final badge = groupG.firstWhere((s) => s.id == 'g4_badge_ios');
      final aps =
          ((badge.payloadTemplate['apns']! as Map)['payload']! as Map)['aps']!
              as Map;

      expect(aps['badge'], 7);
    });

    test('the update scenario reuses a tag, which is how Android replaces', () {
      final update = groupG.firstWhere((s) => s.id == 'g2_update_same_id');

      expect(
        ((update.payloadTemplate['android']! as Map)['notification']!
            as Map)['tag'],
        isNotNull,
      );
    });
```

```dart
import 'scenario.dart';
import 'scenario_need.dart';

/// **G — Groups, badge and updates.** Several notifications behaving as one.
///
/// The badge is the wildest thing in this catalogue: Android has no standard for
/// it, so One UI, MIUI and the Pixel launcher each do something different with the
/// same `notification_count`, and some ignore it entirely. iOS, by contrast, has
/// exactly one well-defined answer — `aps.badge` — which is why g4 works today and
/// g3 does not.
const groupG = <Scenario>[
  Scenario(
    id: 'g1_group_summary',
    group: 'G — Groups, badge, updates',
    title: 'Five notifications with a summary',
    description:
        'Watch that they collapse under one summary row, and what the summary '
        'says when the fifth arrives.',
    payloadTemplate: {
      'notification': {'title': 'Build 128', 'body': 'Passed.'},
      'android': {
        'notification': {'tag': 'builds-group', 'channel_id': 'builds'},
      },
      'data': {'group': 'builds', 'group_summary': 'false'},
    },
    needs: [ScenarioNeed.interaction],
  ),
  Scenario(
    id: 'g2_update_same_id',
    group: 'G — Groups, badge, updates',
    title: 'Replacing a notification in place',
    description:
        'Send twice with the same tag. Watch that the second replaces the first '
        'rather than stacking, and whether it re-alerts.',
    payloadTemplate: {
      'notification': {'title': 'Build 128', 'body': 'Running…'},
      'android': {'notification': {'tag': 'build-128'}},
    },
    needs: [ScenarioNeed.interaction],
  ),
  Scenario(
    id: 'g3_badge',
    group: 'G — Groups, badge, updates',
    title: 'A count on the launcher icon',
    description:
        'The least portable thing here. Watch whether the launcher shows the '
        'number, a dot, or nothing at all.',
    expectation:
        'Behaviour differs per manufacturer: One UI, MIUI and the Pixel launcher '
        'all disagree, and several require the user to enable badges per app.',
    payloadTemplate: {
      'notification': {'title': 'Five waiting', 'body': 'Check the launcher.'},
      'android': {'notification': {'notification_count': 5}},
    },
    needs: [ScenarioNeed.badge],
  ),
  Scenario(
    id: 'g4_badge_ios',
    group: 'G — Groups, badge, updates',
    title: 'The iOS badge via aps.badge',
    description:
        'One well-defined number, set by the sender. Watch that it replaces '
        'rather than increments — iOS does not add.',
    payloadTemplate: {
      'apns': {
        'headers': {'apns-priority': '10'},
        'payload': {
          'aps': {
            'alert': {'title': 'Five waiting', 'body': 'Badge set to 7.'},
            'badge': 7,
            'sound': 'default',
          },
        },
      },
    },
  ),
];
```

---

### Task 11: Group H — Intrusive and priority

Group-specific assertions:

```dart
    test('only the two safe iOS interruption levels work today', () {
      expect(groupH.where((s) => s.isSupported).map((s) => s.id), [
        'h3_ios_time_sensitive',
        'h5_ios_passive',
      ]);
    });

    test('h4 is permanently blocked on Apple, not on us', () {
      final critical = groupH.firstWhere((s) => s.id == 'h4_ios_critical');

      expect(critical.needs, [ScenarioNeed.externalApproval]);
      expect(critical.expectation, contains('entitlement'));
    });

    test('the interruption level rides in the free-form aps dictionary', () {
      // FCM has no field for it, which is exactly why apns.payload is untyped.
      for (final (id, level) in const [
        ('h3_ios_time_sensitive', 'time-sensitive'),
        ('h4_ios_critical', 'critical'),
        ('h5_ios_passive', 'passive'),
      ]) {
        final scenario = groupH.firstWhere((s) => s.id == id);
        final aps =
            ((scenario.payloadTemplate['apns']! as Map)['payload']! as Map)['aps']!
                as Map;
        expect(aps['interruption-level'], level, reason: id);
      }
    });
```

```dart
import 'scenario.dart';
import 'scenario_need.dart';

/// **H — Intrusive and priority.** Breaking through the user's quiet.
///
/// Android and iOS solve this differently, and the split shows: on Android the
/// power to bypass Do Not Disturb is a *channel* property needing the user's
/// policy consent, while on iOS it is a per-message `interruption-level` inside
/// the free-form `aps` dictionary — which is precisely why `apns.payload` is left
/// untyped in this repo's model.
const groupH = <Scenario>[
  Scenario(
    id: 'h1_dnd_bypass',
    group: 'H — Intrusive and priority',
    title: 'A channel that bypasses Do Not Disturb',
    description:
        'Watch that it sounds while DND is on. Setting the flag is not enough — '
        'the user must have granted notification-policy access.',
    expectation:
        'Requires Notification Policy Access, granted by the user in system '
        'settings. Without it the flag is accepted and silently ignored.',
    payloadTemplate: {
      'notification': {'title': 'Urgent', 'body': 'Should sound during DND.'},
      'android': {
        'priority': 'HIGH',
        'notification': {'channel_id': 'dnd_bypass'},
      },
    },
    needs: [ScenarioNeed.channels, ScenarioNeed.externalApproval],
  ),
  Scenario(
    id: 'h2_category_alarm',
    group: 'H — Intrusive and priority',
    title: 'CATEGORY_ALARM',
    description:
        'Alarms are treated as a special class by DND. Watch whether the '
        'category alone changes anything without policy access.',
    expectation:
        'FCM has no field for the notification category — it is set by the client '
        'when building the local notification, which is why this needs the '
        'channel work.',
    payloadTemplate: {
      'notification': {'title': 'Alarm', 'body': 'Categorised as an alarm.'},
      'android': {
        'priority': 'HIGH',
        'notification': {'channel_id': 'alarms'},
      },
      'data': {'category': 'alarm'},
    },
    needs: [ScenarioNeed.channels],
  ),
  Scenario(
    id: 'h3_ios_time_sensitive',
    group: 'H — Intrusive and priority',
    title: 'iOS time-sensitive — breaks through Focus',
    description:
        'Watch that it arrives during a Focus mode that would hold an ordinary '
        'notification.',
    payloadTemplate: {
      'apns': {
        'headers': {'apns-priority': '10'},
        'payload': {
          'aps': {
            'alert': {'title': 'Time sensitive', 'body': 'Through Focus.'},
            'interruption-level': 'time-sensitive',
            'sound': 'default',
          },
        },
      },
    },
  ),
  Scenario(
    id: 'h4_ios_critical',
    group: 'H — Intrusive and priority',
    title: 'iOS critical — through Focus and the mute switch',
    description:
        'The most intrusive delivery Apple offers. Watch that it sounds even '
        'when the device is muted.',
    expectation:
        'Requires a critical-alert entitlement that Apple must approve for the '
        'app. Without it APNs rejects the push, so this stays untestable here — '
        'listed for completeness rather than scheduled.',
    payloadTemplate: {
      'apns': {
        'headers': {'apns-priority': '10'},
        'payload': {
          'aps': {
            'alert': {'title': 'Critical', 'body': 'Through the mute switch.'},
            'interruption-level': 'critical',
            'sound': {'critical': 1, 'name': 'default', 'volume': 1.0},
          },
        },
      },
    },
    needs: [ScenarioNeed.externalApproval],
  ),
  Scenario(
    id: 'h5_ios_passive',
    group: 'H — Intrusive and priority',
    title: 'iOS passive — no sound, no wake',
    description:
        'The quietest level: it appears in the list without alerting. Watch that '
        'the screen does not light up.',
    payloadTemplate: {
      'apns': {
        'headers': {'apns-priority': '5'},
        'payload': {
          'aps': {
            'alert': {'title': 'Passive', 'body': 'No alert at all.'},
            'interruption-level': 'passive',
          },
        },
      },
    },
  ),
];
```

---

### Task 12: Group I — Silent and data

Group-specific assertions:

```dart
    test('the two data scenarios work today', () {
      expect(groupI.where((s) => s.isSupported).map((s) => s.id), [
        'i2_silent_data_sync',
        'i3_ios_content_available',
      ]);
    });

    test('the iOS background push sets content-available and low priority', () {
      // Both are required together: content-available without apns-priority 5
      // is throttled harder, and Apple documents the pair.
      final background = groupI.firstWhere(
        (s) => s.id == 'i3_ios_content_available',
      );
      final apns = background.payloadTemplate['apns']! as Map;

      expect((apns['headers']! as Map)['apns-priority'], '5');
      expect(((apns['payload']! as Map)['aps']! as Map)['content-available'], 1);
    });

    test('the sync scenario draws nothing', () {
      final sync = groupI.firstWhere((s) => s.id == 'i2_silent_data_sync');

      expect(sync.payloadTemplate.containsKey('notification'), isFalse);
    });

    test('the burst scenario says how many and how fast', () {
      final burst = groupI.firstWhere((s) => s.id == 'i4_burst');

      expect(burst.manualSteps, contains('20'));
    });
```

```dart
import 'scenario.dart';
import 'scenario_need.dart';

/// **I — Silent and data.** Delivery the user is not meant to notice.
///
/// The distinction that matters here is *visible but quiet* versus *not visible at
/// all*. The first is a channel-importance question and so is blocked; the second
/// is just a `data` payload and works today. i4 is the odd one out: twenty pushes
/// in ten seconds is about rate limiting, and MIUI in particular will start
/// dropping them.
const groupI = <Scenario>[
  Scenario(
    id: 'i1_silent_no_sound',
    group: 'I — Silent and data',
    title: 'Visible but silent',
    description:
        'Appears in the tray with no sound and no vibration. Watch that it is '
        'silent but still lights the screen or not.',
    payloadTemplate: {
      'notification': {'title': 'Quiet', 'body': 'Seen, not heard.'},
      'android': {'notification': {'channel_id': 'importance_low'}},
    },
    needs: [ScenarioNeed.channels],
  ),
  Scenario(
    id: 'i2_silent_data_sync',
    group: 'I — Silent and data',
    title: 'Invisible, writes to local storage only',
    description:
        'Nothing is drawn; the handler writes a row and that is the whole '
        'observable effect. Watch the Inbox page rather than the tray.',
    payloadTemplate: {
      'data': {
        'event': 'sync',
        'entity': 'builds',
        'cursor': '2026-08-13T09:30:00Z',
      },
    },
  ),
  Scenario(
    id: 'i3_ios_content_available',
    group: 'I — Silent and data',
    title: 'iOS background refresh via content-available',
    description:
        'Wakes the app to fetch without showing anything. Watch how often iOS '
        'actually honours it — it throttles this aggressively.',
    expectation:
        'iOS may delay or drop these entirely depending on battery and usage. A '
        'missed one is not necessarily a bug.',
    payloadTemplate: {
      'apns': {
        'headers': {'apns-priority': '5', 'apns-push-type': 'background'},
        'payload': {
          'aps': {'content-available': 1},
        },
      },
      'data': {'event': 'sync'},
    },
  ),
  Scenario(
    id: 'i4_burst',
    group: 'I — Silent and data',
    title: 'Twenty messages in ten seconds',
    description:
        'Watch for rate limiting, coalescing, and manufacturer caps. MIUI will '
        'usually start dropping before FCM does.',
    payloadTemplate: {
      'notification': {'title': 'Burst', 'body': 'One of twenty.'},
      'android': {'priority': 'HIGH'},
    },
    needs: [ScenarioNeed.manualStep],
    manualSteps:
        'Send this 20 times within 10 seconds and count what arrives. Vary the '
        'body so collapsing is visible.',
  ),
];
```

---

### Task 13: Group J — Targeting

Three scenarios, all needing sub-project 6. **This is the group that exercises
`Scenario.target`** — the field Task 3 added and Task 15 wires to the Sandbox.

Group-specific assertions:

```dart
    test('none of the targeting scenarios works yet', () {
      for (final scenario in groupJ) {
        expect(scenario.needs, [ScenarioNeed.targeting], reason: scenario.id);
      }
    });

    test('each declares its audience through target, not the payload', () {
      // A template that set its own topic would be rejected by FcmMessage, which
      // is the guarantee that keeps payload and audience separate.
      expect(
        groupJ.firstWhere((s) => s.id == 'j1_topic').target,
        const TopicTarget('news'),
      );
      expect(
        groupJ.firstWhere((s) => s.id == 'j2_condition').target,
        const ConditionTarget("'news' in topics && 'beta' in topics"),
      );
      expect(
        groupJ.firstWhere((s) => s.id == 'j3_multicast').target,
        const AllDevicesTarget(),
      );
    });

    test('every template is still target-free', () {
      for (final scenario in groupJ) {
        for (final key in const ['token', 'topic', 'condition']) {
          expect(
            scenario.payloadTemplate.containsKey(key),
            isFalse,
            reason: scenario.id,
          );
        }
      }
    });
```

```dart
import '../send_target.dart';
import 'scenario.dart';
import 'scenario_need.dart';

/// **J — Targeting.** Who receives it, rather than what it says.
///
/// The audience lives in [Scenario.target] and never in the payload: the typed
/// `FcmMessage` rejects `token`, `topic` and `condition` outright, so a template
/// pasted out of Google's docs cannot quietly broadcast. The API reads the target
/// from the send envelope instead.
///
/// All three are blocked, and for two different reasons. j1 and j2 can be *sent*
/// today — FCM answers 200 — but nothing is delivered, because this device has
/// never called `subscribeToTopic`. A send that succeeds while nothing arrives is
/// worse than no scenario at all, so they wait for subscription support. j3 needs
/// a registry of tokens, which FCM does not provide and this app does not keep.
const groupJ = <Scenario>[
  Scenario(
    id: 'j1_topic',
    group: 'J — Targeting',
    title: 'Send to a topic',
    description:
        'Subscribe the device, then send to the topic rather than the token. '
        'Watch that it arrives without the sender knowing any token at all.',
    expectation:
        'Sending works now and FCM answers 200, but nothing is delivered until '
        'the app can subscribe to a topic.',
    payloadTemplate: {
      'notification': {'title': 'Topic push', 'body': 'Sent to "news".'},
    },
    target: TopicTarget('news'),
    needs: [ScenarioNeed.targeting],
  ),
  Scenario(
    id: 'j2_condition',
    group: 'J — Targeting',
    title: 'Send to a boolean topic condition',
    description:
        'A device must be in both topics to receive this. Watch that subscribing '
        'to only one excludes it.',
    payloadTemplate: {
      'notification': {'title': 'Condition push', 'body': 'news AND beta.'},
    },
    target: ConditionTarget("'news' in topics && 'beta' in topics"),
    needs: [ScenarioNeed.targeting],
  ),
  Scenario(
    id: 'j3_multicast',
    group: 'J — Targeting',
    title: 'Send to every registered device',
    description:
        'The main tool for comparing behaviour across handsets: one send, every '
        'device, and the differences are the result.',
    expectation:
        'FCM has no "all devices" audience, so this needs a token registry the '
        'API does not have. Sending it now returns 501 with that reason rather '
        'than quietly delivering to one device.',
    payloadTemplate: {
      'notification': {'title': 'Everyone', 'body': 'Compare across devices.'},
      'android': {'priority': 'HIGH'},
    },
    target: AllDevicesTarget(),
    needs: [ScenarioNeed.targeting],
  ),
];
```

---

### Task 14: Group K — Edge cases and errors, and the final counts

The last group, and the task that locks the catalogue's totals.

Group-specific assertions, plus the catalogue-wide ones:

```dart
    test('the two payload-level failures work today', () {
      expect(groupK.where((s) => s.isSupported).map((s) => s.id), [
        'k1_payload_oversize',
        'k2_invalid_token',
      ]);
    });

    test('the oversize payload really is over 4 KB', () {
      // Asserting the size rather than trusting the name: a template trimmed
      // during editing would silently stop testing the limit.
      final oversize = groupK.firstWhere((s) => s.id == 'k1_payload_oversize');
      final data = oversize.payloadTemplate['data']! as Map<String, Object?>;
      final bytes = data.entries
          .map((e) => e.key.length + (e.value! as String).length)
          .reduce((a, b) => a + b);

      expect(bytes, greaterThan(4096));
    });

    test('the dead-token scenario targets a token, and a bad one', () {
      final dead = groupK.firstWhere((s) => s.id == 'k2_invalid_token');

      expect(dead.target, isA<TokenTarget>());
      expect((dead.target! as TokenTarget).token, isNot(isEmpty));
      expect(dead.expectation, contains('UNREGISTERED'));
    });
```

```dart
// packages/fcm_gallery_shared/test/scenarios/scenario_gallery_test.dart — add:
  test('the catalogue is complete: 66 scenarios in 11 groups', () {
    expect(scenarioGallery, hasLength(66));
    expect(scenarioGallery.map((s) => s.group).toSet(), hasLength(11));
  });

  test('exactly 21 scenarios work today', () {
    // Asserted so that mis-marking one as blocked, or quietly unmarking one to
    // make it look supported, fails the build.
    final supported = scenarioGallery.where((s) => s.isSupported).toList();

    expect(supported, hasLength(21), reason: supported.map((s) => s.id).join(', '));
  });

  test('every ScenarioNeed is used, so the enum cannot drift', () {
    for (final need in ScenarioNeed.values) {
      expect(
        scenarioGallery.any((s) => s.needs.contains(need)),
        isTrue,
        reason: '${need.name} is declared but no scenario needs it',
      );
    }
  });

  test('the groups appear in A to K order', () {
    final letters = scenarioGallery
        .map((s) => s.group.substring(0, 1))
        .toSet()
        .toList();

    expect(letters, ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K']);
  });
```

```dart
import '../send_target.dart';
import 'scenario.dart';
import 'scenario_need.dart';

/// **K — Edge cases and errors.** The failures worth being able to reproduce.
///
/// Two of these are payload-level and work today: an oversize body and a dead
/// token both produce a clean, specific error from FCM, and being able to trigger
/// them on demand is what makes the error handling elsewhere trustworthy. The
/// other three are states of the device that no payload can create.
const groupK = <Scenario>[
  Scenario(
    id: 'k1_payload_oversize',
    group: 'K — Edge cases and errors',
    title: 'A payload over FCM\'s 4 KB limit',
    description:
        'Watch that the API surfaces FCM\'s error with a usable message rather '
        'than a bare 400.',
    expectation:
        'FCM rejects this with INVALID_ARGUMENT. The send should fail before '
        'anything reaches the device.',
    payloadTemplate: {
      'data': {
        'chunk_1':
            'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do '
            'eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim '
            'ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut '
            'aliquip ex ea commodo consequat. Duis aute irure dolor in '
            'reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla '
            'pariatur. Excepteur sint occaecat cupidatat non proident, sunt in '
            'culpa qui officia deserunt mollit anim id est laborum. Sed ut '
            'perspiciatis unde omnis iste natus error sit voluptatem accusantium '
            'doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo '
            'inventore veritatis et quasi architecto beatae vitae dicta sunt '
            'explicabo. Nemo enim ipsam voluptatem quia voluptas sit aspernatur '
            'aut odit aut fugit, sed quia consequuntur magni dolores eos qui '
            'ratione voluptatem sequi nesciunt.',
        'chunk_2':
            'Neque porro quisquam est, qui dolorem ipsum quia dolor sit amet, '
            'consectetur, adipisci velit, sed quia non numquam eius modi tempora '
            'incidunt ut labore et dolore magnam aliquam quaerat voluptatem. Ut '
            'enim ad minima veniam, quis nostrum exercitationem ullam corporis '
            'suscipit laboriosam, nisi ut aliquid ex ea commodi consequatur? '
            'Quis autem vel eum iure reprehenderit qui in ea voluptate velit '
            'esse quam nihil molestiae consequatur, vel illum qui dolorem eum '
            'fugiat quo voluptas nulla pariatur? At vero eos et accusamus et '
            'iusto odio dignissimos ducimus qui blanditiis praesentium '
            'voluptatum deleniti atque corrupti quos dolores et quas molestias '
            'excepturi sint occaecati cupiditate non provident, similique sunt '
            'in culpa qui officia deserunt mollitia animi, id est laborum et '
            'dolorum fuga.',
        'chunk_3':
            'Et harum quidem rerum facilis est et expedita distinctio. Nam '
            'libero tempore, cum soluta nobis est eligendi optio cumque nihil '
            'impedit quo minus id quod maxime placeat facere possimus, omnis '
            'voluptas assumenda est, omnis dolor repellendus. Temporibus autem '
            'quibusdam et aut officiis debitis aut rerum necessitatibus saepe '
            'eveniet ut et voluptates repudiandae sint et molestiae non '
            'recusandae. Itaque earum rerum hic tenetur a sapiente delectus, ut '
            'aut reiciendis voluptatibus maiores alias consequatur aut '
            'perferendis doloribus asperiores repellat. Sed ut perspiciatis unde '
            'omnis iste natus error sit voluptatem accusantium doloremque '
            'laudantium, totam rem aperiam, eaque ipsa quae ab illo inventore '
            'veritatis et quasi architecto beatae vitae dicta sunt explicabo.',
        'chunk_4':
            'Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua, '
            'ut enim ad minim veniam, quis nostrud exercitation ullamco laboris '
            'nisi ut aliquip ex ea commodo consequat, duis aute irure dolor in '
            'reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla '
            'pariatur, excepteur sint occaecat cupidatat non proident, sunt in '
            'culpa qui officia deserunt mollit anim id est laborum, and that '
            'should be comfortably past four kilobytes once the other chunks are '
            'counted alongside it.',
      },
    },
  ),
  Scenario(
    id: 'k2_invalid_token',
    group: 'K — Edge cases and errors',
    title: 'A token that is no longer registered',
    description:
        'The everyday production failure. Watch that the API reports it as '
        'UNREGISTERED rather than a generic 404, which is what tells a real '
        'backend to delete the row.',
    expectation:
        'FCM answers with UNREGISTERED, which this API maps to 404 with its own '
        'wording. The errorCode in error.details takes precedence over the '
        'top-level NOT_FOUND status.',
    payloadTemplate: {
      'notification': {'title': 'Nobody', 'body': 'This token is dead.'},
    },
    target: TokenTarget(
      'fZ9-this-token-was-never-real-and-never-will-be-000000000000',
    ),
  ),
  Scenario(
    id: 'k3_permission_denied',
    group: 'K — Edge cases and errors',
    title: 'POST_NOTIFICATIONS denied on Android 13+',
    description:
        'Watch that the data handler still runs and the inbox still fills, even '
        'though nothing can be drawn.',
    payloadTemplate: {
      'notification': {'title': 'Denied', 'body': 'Nothing should be drawn.'},
      'data': {'event': 'permission_probe'},
    },
    needs: [ScenarioNeed.manualStep],
    manualSteps:
        'adb shell pm revoke cz.netglade.fcm_app '
        'android.permission.POST_NOTIFICATIONS — then send, and check the Inbox '
        'page rather than the tray.',
  ),
  Scenario(
    id: 'k4_notifications_disabled',
    group: 'K — Edge cases and errors',
    title: 'Notifications switched off in system settings',
    description:
        'Distinct from a denied permission: the app has the grant and the user '
        'has turned it off. Watch that data delivery is unaffected.',
    payloadTemplate: {
      'notification': {'title': 'Disabled', 'body': 'Tray is off.'},
      'data': {'event': 'disabled_probe'},
    },
    needs: [ScenarioNeed.manualStep],
    manualSteps:
        'Settings › Apps › FCM Sample › Notifications › off. Send, then confirm '
        'the row appears in the Inbox page.',
  ),
  Scenario(
    id: 'k5_battery_restricted',
    group: 'K — Edge cases and errors',
    title: 'App in Restricted battery mode',
    description:
        'The state a user reaches by tapping "restrict" in battery settings. '
        'Watch whether a HIGH priority push still wakes the app.',
    payloadTemplate: {
      'notification': {'title': 'Restricted', 'body': 'Battery probe.'},
      'android': {'priority': 'HIGH'},
      'data': {'event': 'battery_probe'},
    },
    needs: [ScenarioNeed.manualStep],
    manualSteps:
        'Settings › Apps › FCM Sample › Battery › Restricted. Send and compare '
        'the delay against c1_priority_high in the unrestricted state.',
  ),
];
```

---

### Task 15: The target selector, and the controller carries a target

**Files:**
- Create: `apps/fcm_app/lib/ui/send_target_field.dart`
- Modify: `apps/fcm_app/lib/sandbox/sandbox_controller.dart`
- Modify: `apps/fcm_app/lib/ui/sandbox_view.dart`
- Test: `apps/fcm_app/test/ui/send_target_field_test.dart`
- Modify: `apps/fcm_app/test/sandbox_controller_test.dart`

**Interfaces:**
- Consumes: `SendTarget` and variants (Task 1), `Scenario.target` (Task 3), `SandboxController` as it stands after Task 2.
- Produces: on `SandboxController` — `SendTarget? get target` (null = this device), `void setTarget(SendTarget? target)`; and `SendTargetField({required SandboxController controller, super.key})`.

`applyScenario` sets `_target = scenario.target`, so opening J1 selects its topic
and opening anything else resets to this device. `send()` resolves
`_target ?? TokenTarget(token)`, replacing the `TokenTarget(token)` placed in Task 2.

**The widget is a dropdown of four kinds plus one text field**, not four separate
controls: the kinds are mutually exclusive, and a form that lets two be filled in
invites exactly the "two targets" error `SendTarget.readFrom` exists to reject.
Selecting *This device* hides the text field, because there is nothing to type.

`lib/ui/**` is **not** in `metrics-exclude`, so `build` must stay under 50 lines.

- [ ] **Step 1: Write the failing test**

```dart
import 'package:fcm_app/sandbox/sandbox_controller.dart';
import 'package:fcm_app/ui/send_target_field.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glade_forms/glade_forms.dart';

import '../fake_notification_sender.dart';

void main() {
  setUpAll(GladeForms.initialize);

  late SandboxController controller;

  setUp(() {
    controller = SandboxController(
      sender: FakeNotificationSender(),
      token: () => 'device-token',
    );
  });

  tearDown(() => controller.dispose());

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: SendTargetField(controller: controller)),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('defaults to this device, with nothing to type', (tester) async {
    await pump(tester);

    expect(find.text('This device'), findsOne);
    expect(find.byType(TextField), findsNothing);
    expect(controller.target, isNull);
  });

  testWidgets('choosing a topic reveals a field and sets the target', (
    tester,
  ) async {
    await pump(tester);

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Topic').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'news');
    await tester.pumpAndSettle();

    expect(controller.target, const TopicTarget('news'));
  });

  testWidgets('all devices needs no text and warns it is unsupported', (
    tester,
  ) async {
    await pump(tester);

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('All devices').last);
    await tester.pumpAndSettle();

    expect(controller.target, const AllDevicesTarget());
    expect(find.byType(TextField), findsNothing);
    expect(find.textContaining('registry'), findsOne);
  });

  testWidgets('a scenario with a topic preselects it', (tester) async {
    controller.applyScenario(
      scenarioGallery.firstWhere((s) => s.id == 'j1_topic'),
    );

    await pump(tester);

    expect(find.text('Topic'), findsOne);
    expect(find.widgetWithText(TextField, 'news'), findsOne);
  });

  testWidgets('applying an ordinary scenario resets to this device', (
    tester,
  ) async {
    controller
      ..applyScenario(scenarioGallery.firstWhere((s) => s.id == 'j1_topic'))
      ..applyScenario(
        scenarioGallery.firstWhere((s) => s.id == 'a1_notification_only'),
      );

    await pump(tester);

    expect(controller.target, isNull);
    expect(find.text('This device'), findsOne);
  });
}
```

Plus, in `sandbox_controller_test.dart`:

```dart
  test('sends to this device when no target is chosen', () async {
    await controller.send();

    expect(sender.sent.single.target, const TokenTarget('device-token'));
  });

  test('sends to the chosen target instead of this device', () async {
    controller.setTarget(const TopicTarget('news'));

    await controller.send();

    expect(sender.sent.single.target, const TopicTarget('news'));
  });
```

- [ ] **Step 2: Run to verify they fail**

Run from `apps/fcm_app`: `fvm flutter test test/ui/send_target_field_test.dart test/sandbox_controller_test.dart`
Expected: FAIL — `SendTargetField` not found, `setTarget` not defined.

- [ ] **Step 3: Implement the controller changes**

```dart
  SendTarget? _target;

  /// Who to send to, or null for this device.
  ///
  /// Null rather than a resolved `TokenTarget`, because the device's token can
  /// change under us — it is read at send time, not when the choice is made.
  SendTarget? get target => _target;

  /// Chooses an audience, or null to go back to this device.
  void setTarget(SendTarget? target) {
    _target = target;
    notifyListeners();
  }
```

In `applyScenario`, after reading the payload: `_target = scenario.target;`
In `send()`: `final target = _target ?? TokenTarget(token);`

- [ ] **Step 4: Implement `SendTargetField`**

```dart
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter/material.dart';

import '../sandbox/sandbox_controller.dart';

/// Chooses who a send goes to.
///
/// One dropdown and one text field rather than four separate inputs: the kinds
/// are mutually exclusive, and a form that lets two be filled at once invites
/// exactly the "only one delivery target is allowed" error that
/// `SendTarget.readFrom` exists to reject. *This device* and *All devices* need
/// nothing typed, so the field is hidden for them rather than disabled — a box
/// you cannot use is worse than no box.
class SendTargetField extends StatelessWidget {
  /// Reads and sets [controller]'s target.
  const SendTargetField({required this.controller, super.key});

  /// The controller whose target this chooses.
  final SandboxController controller;

  static const _kinds = ['This device', 'Token', 'Topic', 'Condition',
      'All devices'];

  @override
  Widget build(BuildContext context) {
    final target = controller.target;
    final kind = switch (target) {
      null => 'This device',
      TokenTarget() => 'Token',
      TopicTarget() => 'Topic',
      ConditionTarget() => 'Condition',
      AllDevicesTarget() => 'All devices',
    };
    final value = switch (target) {
      TokenTarget(:final token) => token,
      TopicTarget(:final topic) => topic,
      ConditionTarget(:final condition) => condition,
      _ => '',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          initialValue: kind,
          decoration: const InputDecoration(labelText: 'Send to'),
          items: [
            for (final k in _kinds)
              DropdownMenuItem(value: k, child: Text(k)),
          ],
          onChanged: (chosen) => controller.setTarget(_emptyFor(chosen)),
        ),
        if (kind == 'Token' || kind == 'Topic' || kind == 'Condition')
          TextFormField(
            key: ValueKey(kind),
            initialValue: value,
            decoration: InputDecoration(labelText: kind.toLowerCase()),
            onChanged: (text) => controller.setTarget(_withValue(kind, text)),
          ),
        if (kind == 'All devices')
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Sending to every device needs a token registry the API does not '
              'have yet, so this will be refused.',
            ),
          ),
      ],
    );
  }

  /// The empty target for a freshly chosen [kind].
  static SendTarget? _emptyFor(String? kind) => switch (kind) {
    'Token' => const TokenTarget(''),
    'Topic' => const TopicTarget(''),
    'Condition' => const ConditionTarget(''),
    'All devices' => const AllDevicesTarget(),
    _ => null,
  };

  /// [kind]'s target carrying [text].
  static SendTarget? _withValue(String kind, String text) => switch (kind) {
    'Token' => TokenTarget(text),
    'Topic' => TopicTarget(text),
    _ => ConditionTarget(text),
  };
}
```

Note `_emptyFor` returns a target with a **blank** value, which
`SendTarget.readFrom` would reject — that is deliberate: `canSend` must refuse a
blank target rather than sending to the wrong audience. Add to
`sendBlockedReason`, before the token check:

```dart
    if (_target case TokenTarget(token: '') ||
        TopicTarget(topic: '') ||
        ConditionTarget(condition: '')) {
      return 'Fill in the delivery target, or switch back to this device.';
    }
```

Render it in `sandbox_view.dart` as the first child of the scrolling `ListView`,
above the validate-only checkbox.

- [ ] **Step 5: Verify**

Run both test files, then `fvm dart run melos run format` and
`fvm dart run melos run ci` — exit 0. Report the measured `fcm_app` count.

- [ ] **Step 6: Commit**

```bash
git add apps/fcm_app
git commit -m "feat(app): choose the delivery target in the sandbox"
```

---

### Task 16: The needs banner and the manual-steps block

**Files:**
- Create: `apps/fcm_app/lib/ui/scenario_needs_banner.dart`
- Create: `apps/fcm_app/lib/ui/manual_steps_block.dart`
- Modify: `apps/fcm_app/lib/ui/sandbox_view.dart`
- Modify: `apps/fcm_app/lib/ui/scenario_group_list.dart` (a needs chip per row)
- Test: `apps/fcm_app/test/ui/scenario_needs_banner_test.dart`
- Test: `apps/fcm_app/test/ui/manual_steps_block_test.dart`

**Interfaces:**
- Consumes: `Scenario`, `ScenarioNeed` and `ScenarioNeed.label` (Task 3).
- Produces: `ScenarioNeedsBanner({required Scenario? scenario, super.key})` and `ManualStepsBlock({required String steps, super.key})`.

Two widgets in two files because `prefer-single-widget-per-file` is fatal.

`ScenarioNeedsBanner` renders nothing at all for a null scenario or one with no
needs — that is the common case and it must not take vertical space. Otherwise it
lists each need's `label`, comma-separated, prefixed "Needs ".

`ManualStepsBlock` wraps the text in `SelectableText` in a monospace style, because
an adb command that cannot be copied is a command that will be mistyped.

- [ ] **Step 1: Write the failing tests**

```dart
// scenario_needs_banner_test.dart
import 'package:fcm_app/ui/scenario_needs_banner.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pump(WidgetTester tester, Scenario? scenario) =>
      tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ScenarioNeedsBanner(scenario: scenario)),
        ),
      );

  testWidgets('renders nothing when no scenario is loaded', (tester) async {
    await pump(tester, null);

    expect(find.byType(Text), findsNothing);
  });

  testWidgets('renders nothing for a scenario that works', (tester) async {
    // The common case: 21 of 66 have no needs, and a banner on each would be
    // noise that trains the user to ignore it.
    await pump(
      tester,
      scenarioGallery.firstWhere((s) => s.id == 'a1_notification_only'),
    );

    expect(find.byType(Text), findsNothing);
  });

  testWidgets('names every unmet need, using its own words', (tester) async {
    await pump(
      tester,
      scenarioGallery.firstWhere((s) => s.id == 'f8_full_screen_intent'),
    );

    expect(find.textContaining('notification actions'), findsOne);
    expect(find.textContaining('external approval'), findsOne);
  });

  testWidgets('says the push is still sent, so the banner is not a block', (
    tester,
  ) async {
    await pump(tester, scenarioGallery.firstWhere((s) => s.id == 'd1_importance_high'));

    expect(find.textContaining('still be sent'), findsOne);
  });
}
```

```dart
// manual_steps_block_test.dart
import 'package:fcm_app/ui/manual_steps_block.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the steps as selectable text, so a command can be copied', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ManualStepsBlock(steps: 'adb shell dumpsys deviceidle force-idle'),
        ),
      ),
    );

    expect(find.byType(SelectableText), findsOne);
    expect(find.textContaining('force-idle'), findsOne);
  });
}
```

- [ ] **Step 2: Run to verify they fail**

Run from `apps/fcm_app`:
`fvm flutter test test/ui/scenario_needs_banner_test.dart test/ui/manual_steps_block_test.dart`
Expected: FAIL — neither widget exists.

- [ ] **Step 3: Implement both widgets**

```dart
// scenario_needs_banner.dart
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter/material.dart';

/// Says what the loaded scenario still needs before it demonstrates anything.
///
/// Renders nothing when there is nothing to say — no scenario, or one that works
/// today, which is 21 of the 66. A banner on every scenario would be noise, and
/// noise trains people to stop reading banners.
///
/// It deliberately does **not** block Send. The push is genuine and valid; only
/// the behaviour it is meant to show is missing, and watching a client with no
/// action support receive an action payload is itself worth seeing.
class ScenarioNeedsBanner extends StatelessWidget {
  /// Reports [scenario]'s unmet needs, if it has any.
  const ScenarioNeedsBanner({required this.scenario, super.key});

  /// The loaded scenario, or null when the form was filled in by hand.
  final Scenario? scenario;

  @override
  Widget build(BuildContext context) {
    final needs = scenario?.needs ?? const <ScenarioNeed>[];
    if (needs.isEmpty) {
      return const SizedBox.shrink();
    }

    final scheme = Theme.of(context).colorScheme;

    return Card(
      color: scheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          'Needs ${needs.map((need) => need.label).join(', ')}. '
          'The push will still be sent, but this scenario cannot be observed '
          'yet.',
          style: TextStyle(color: scheme.onSecondaryContainer),
        ),
      ),
    );
  }
}
```

```dart
// manual_steps_block.dart
import 'package:flutter/material.dart';

/// The step a scenario needs a human to perform.
///
/// `SelectableText` in a monospace face, because most of these are adb commands
/// and a command that cannot be copied is a command that will be mistyped —
/// `set-standby-bucket` in particular.
class ManualStepsBlock extends StatelessWidget {
  /// Shows [steps] as copyable text.
  const ManualStepsBlock({required this.steps, super.key});

  /// The instruction, verbatim from the scenario.
  final String steps;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      color: scheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: SelectableText(
          steps,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Wire both into `sandbox_view.dart`**

Directly below `SendTargetField`, above the validate-only checkbox:

```dart
              ScenarioNeedsBanner(scenario: controller.selectedScenario),
              if (controller.selectedScenario?.manualSteps case final steps?)
                ManualStepsBlock(steps: steps),
```

In `scenario_group_list.dart`, add a trailing chip to each row for a scenario with
needs — `Chip(label: Text('needs work'))` is enough; the detail belongs to the
banner, and a row carrying five labels would be unreadable.

- [ ] **Step 5: Verify**

Run both new test files plus `test/sandbox_view_test.dart` and
`test/ui/scenarios_view_test.dart`, then `fvm dart run melos run format` and
`fvm dart run melos run ci` — exit 0. Report the measured `fcm_app` count.

- [ ] **Step 6: Commit**

```bash
git add apps/fcm_app
git commit -m "feat(app): report what a scenario still needs"
```

---

### Task 17: Verify and document

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Run the gate and both builds**

From the repo root: `fvm dart run melos run ci` — exit 0. Report every package's
count as measured, not as expected.

From `apps/fcm_app`: `fvm flutter build apk --debug` and
`fvm flutter build web --release`. Both must succeed.

- [ ] **Step 2: Update the README**

Replace the "nine scenarios" wording wherever it appears — check with
`grep -n 'nine' README.md`. State:

- The catalogue is 66 scenarios in eleven groups A–K, mirroring the FCM playground
  test plan.
- **21 of them work today.** The rest are listed with what they still need, and
  that number is asserted by a test so the README cannot drift from the code.
- The delivery target is chosen in the envelope, not the payload: a send can go to
  this device, an explicit token, a topic, a condition, or (refused for now) every
  device. `FcmMessage` still rejects a template that sets its own target.
- `curl` examples keep working unchanged, because the target sits at the top level
  exactly where `token` used to.

Update `## Verified on this machine` with the measured counts and honest build
results.

**Also fix `apps/fcm_api/README.md`**, found stale during Task 2: line 7 still
documents the send body as `{token, title, body, data?}`, which stopped being true
when the envelope started taking a nested `message` — before this plan, not because
of it. It now takes a target plus `validate_only` plus `message`.

- [ ] **Step 3: Commit**

```bash
git add README.md
git commit -m "docs: describe the scenario catalogue"
```

- [ ] **Step 4: The verifications that need a human**

Neither can run here. Report each as verified or unverified; never assume.

1. **The validate-only sweep over all 66**, through the form, expecting 200 for
   each scenario whose `needs` do not include `targeting` or `manualStep`. This is
   the one that would catch a template FCM rejects for a reason the local parser
   cannot know about.
2. **On a device:** that the needs banner appears for a blocked scenario and not
   for a working one, that an adb command can actually be selected and copied out
   of `ManualStepsBlock`, and that `k2_invalid_token` produces UNREGISTERED rather
   than a generic 404.

---

## Verification summary

| Task | Deliverable | Test |
| --- | --- | --- |
| 1 | `SendTarget`, four variants | 7 unit tests |
| 2 | envelope + API carry a target | topic forwarded, all-devices refused 501 |
| 3 | `ScenarioNeed`, `Scenario` + 3 fields | labels non-blank, `isSupported` |
| 4 | group A + gallery switchover | ids unique, prefixes match, round-trip |
| 5–14 | groups B–K | per-group ids and assertions |
| 14 | the totals | 66 scenarios, 11 groups, 21 supported, enum fully used |
| 15 | target selector | 5 widget tests + 2 controller tests |
| 16 | needs banner, manual steps | 5 widget tests |
| 17 | docs, builds | gate exit 0, apk + web build |

## Notes for the implementer

- **The round-trip assertion is the safety net for this whole plan.** If it fails
  after you add a group, a template has a key the typed model does not define.
  Fix the template. Never weaken the assertion, and never add the field to the
  model to make a template pass — the model mirrors Google's reference, and a key
  it lacks is a key FCM lacks.
- **`data` values are strings.** FCM's `data` is `map<string, string>`. `'5'`, not
  `5`. The model enforces it and the round-trip test will catch it.
- **Numbers inside `apns.payload` are not.** That block is free-form, so
  `'badge': 7` is correct there and `'badge': '7'` would be wrong.
- **Group letters live in `group`, not just the id.** The prefix test compares the
  id's first character with the group string's first character, so
  `group: 'C — Priority and delivery window'` and `id: 'c1_…'` must agree.
- **Do not reflow the source document's meaning when translating.** The *Co
  sledovat* column is the most valuable part of the catalogue — it is what turns an
  entry from a payload into a test. Keep it as an instruction about what to watch.
