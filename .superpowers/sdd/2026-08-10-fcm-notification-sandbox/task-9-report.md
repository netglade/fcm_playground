# Task 9 Report: App-side sender seam and `SandboxController`

## What was implemented

Per the brief, in `apps/fcm_app`:

- `lib/sandbox/notification_sender.dart` — `abstract interface class NotificationSender` with `Future<SendNotificationResponse> send(SendNotificationRequest request)`.
- `lib/sandbox/callable_notification_sender.dart` — `CallableNotificationSender`, the production `NotificationSender`. Calls `_functions.httpsCallable('send-notification')` (the kebab-case deployed id, per the brief's doc comment — **not** `'sendNotification'`, the literal registered in `register_functions.dart`). Rebuilds the returned map with `String` keys rather than casting, to tolerate the `Map<Object?, Object?>` the plugin returns on Android.
- `lib/sandbox/unavailable_notification_sender.dart` — `UnavailableNotificationSender(reason)`, used when Firebase never started; `send()` always errors with the given reason.
- `lib/sandbox/sandbox_controller.dart` — `SandboxController extends ChangeNotifier`, holding the current draft, validation problems, last response/error, sending state, and `scenarioGeneration` (incremented only by `applyScenario`, per the brief's note so Task 11's text-field keys don't reseed mid-typing).
- `test/fake_notification_sender.dart` — `FakeNotificationSender`, driven directly by tests, following the `FakePushSource` file convention.
- `test/sandbox_controller_test.dart` — the 10 brief tests, verbatim in intent (one test's source layout was adjusted post-formatter, see Deviations below; text and assertions are identical to the brief).
- `pubspec.yaml` — added `cloud_functions: ^6.3.6` and `fcm_gallery_shared: {path: ../../packages/fcm_gallery_shared}` in alphabetical order.

No test was written for `CallableNotificationSender`, as instructed (it's a thin wrapper with no logic worth mocking `cloud_functions` for).

## Resolved `cloud_functions` version

`fvm dart pub get` resolved:
- `cloud_functions 6.3.6`
- `cloud_functions_platform_interface 6.0.6`
- `cloud_functions_web 5.1.12`

Matches the brief's `^6.3.6` constraint; `firebase_core ^4.13.0` (already pinned) satisfied its requirement with no conflict.

## Deviations from the brief's literal snippets (with reasons)

1. **`SandboxController`'s constructor gained two `// ignore: prefer_initializing_formals` comments.**
   The brief's exact constructor code, run through this repo's actual analyzer config (`flutter_lints ^6.0.0` → `package:lints/recommended.yaml`, which enables `prefer_initializing_formals`), produces 2 `info`-level diagnostics under `--fatal-infos`. The lint's own suggested fix (`this._sender`) is not applicable here: an initializing formal forces the external parameter name to equal the field name, which would turn the named argument from `sender:`/`readToken:` (required by the tests and by `SandboxController(sender: ..., readToken: ...)`) into `_sender:`/`_readToken:`. Since the private field name and the public API name must differ, the assignment-in-initializer-list form the brief specifies is the only correct shape, and the lint is a false positive in this exact case. I suppressed it inline with a one-line comment explaining why, rather than changing the constructor's public shape or the field's privacy. No other part of the class changed.

2. **One test's source layout changed to survive `dart format`, without changing its behavior or wording.**
   The brief wrote the "editing the draft…" test's description as two adjacent string literals split across two lines (`'...so ' \n 'the text...'`), with the `test(desc, () { ... })` call left in place. `dart format` collapses that into a compact two-line form (description partly on the `test(` line) because the adjacent-string split lets it fit under 80 columns without exploding the whole call — and that compact form has no trailing comma before the closure, which DCM's `prefer-trailing-comma` (fatal style) flags. I restructured the call into the fully exploded `test(\n  'description',\n  () { ... },\n)` shape (same technique the brief's own "records a failure…" test already uses, since its longer, single-literal description forces the same explosion). `dart format` now leaves it untouched (0 changes), and DCM is clean. The concatenated string content is character-for-character identical to the brief's; only the split point of the two literal pieces moved to keep the words together, and only the call's line breaks changed.

No other file deviates from the brief.

## TDD Evidence

**RED** — `fvm flutter test test/sandbox_controller_test.dart` (run from `apps/fcm_app`, before any `lib/sandbox/*` file existed):

```
test/sandbox_controller_test.dart:1:8: Error: Error when reading 'lib/sandbox/sandbox_controller.dart': No such file or directory
import 'package:fcm_app/sandbox/sandbox_controller.dart';
       ^
test/fake_notification_sender.dart:1:8: Error: Error when reading 'lib/sandbox/notification_sender.dart': No such file or directory
...
00:00 +0 -1: Some tests failed.
```

Expected and correct: neither `notification_sender.dart` nor `sandbox_controller.dart` existed yet, so the test file couldn't even compile.

**GREEN** — same command after writing all four `lib/sandbox/*.dart` files:

```
00:00 +0: SandboxController starts from the first gallery scenario, so the form is never blank
00:00 +1: SandboxController applying a scenario replaces the draft and bumps the generation
00:00 +2: SandboxController editing the draft revalidates but leaves the generation alone, so the text fields are not reseeded mid-typing
00:00 +3: SandboxController cannot send an invalid draft
00:00 +4: SandboxController cannot send without a registration token
00:00 +5: SandboxController sends the current draft with the current token
00:00 +6: SandboxController records the response and clears any earlier error
00:00 +7: SandboxController records a failure instead of throwing, and drops the stale response
00:00 +8: SandboxController notifies listeners while sending and again when finished
00:00 +9: SandboxController does not send when the draft is invalid, even if asked
00:00 +10: All tests passed!
```

That transcript lists ten distinct `SandboxController` test descriptions (`+0` through `+9`). All 10 new tests pass. (An earlier draft of this report said "11 new tests" and "13 → 24" — both wrong; corrected below and throughout. The plan's own verification step had the same arithmetic error, independently corrected upstream in commit f10a09e.)

## Testing — exact per-package counts observed

- `apps/fcm_app`: **23 tests, all passing** (13 existing: 5 `inbox_screen_test.dart` + 7 `push_inbox_test.dart` + 1 `firebase_options_test.dart`; 10 new in `sandbox_controller_test.dart`). Matches the brief's target of 13 → 23. (Corrected from the original report's "24" / "11 new" — see the TDD Evidence section above.)
- `packages/core`: **20 tests, all passing** — unchanged.
- `packages/fcm_gallery_shared`: **42 tests, all passing** — unchanged.
- `apps/fcm_functions`: **18 tests, all passing** — unchanged.

**On the discovery-quirk claim in the original report:** that report asserted, as an established fact, that `fvm flutter test` at default concurrency "intermittently under-discovered" test files and that `--concurrency=1` was needed to see all four `*_test.dart` files. The reviewer could not reproduce this in three consecutive default-concurrency runs and found no plausible mechanism in the diff. Re-testing for this fix round, in my current session, I got the opposite result: six consecutive fresh attempts at default concurrency (five direct `fvm flutter test` runs plus one `fvm dart run melos run test:app`, the exact command the plan's `test:app` script uses) all exercised only `inbox_screen_test.dart` (5 tests) and `push_inbox_test.dart` (7 tests) — `firebase_options_test.dart` and `sandbox_controller_test.dart` were never attempted, with no error printed. Each of those runs still ended with a `+23`-style summary line, because `flutter test`'s compact reporter re-prints one slow test's status repeatedly (11 duplicate lines for "shows an empty state before anything arrives" in this suite), which inflates the running counter to a number that happens to coincide with the real total test count and can look like full coverage at a glance. `--concurrency=1` reliably ran all four files with no duplicate lines, every time I tried it, both now and during the original implementation.

So: this is real and reproducible in my environment right now, not a one-off — but the reviewer's environment did not show it at all, and I don't know why the two disagree. I'm not asserting a cause or a general toolchain property; I'm reporting exactly what six fresh runs just showed. Given the disagreement, treat `fvm flutter test` (or `melos run test:app`) at default concurrency as unverified for confirming full test-file coverage in this package until someone can explain the discrepancy — `--concurrency=1`, or checking unique `file: test name` pairs rather than the final `+N` line, is the reliable way to confirm all files ran.

## Gate output

**1. Format check** (`fvm dart format --output=none --set-exit-if-changed .` from repo root):
```
Formatted 53 files (0 changed) in 0.08 seconds.
```
Exit 0. (One intermediate run required `fvm dart format .` to apply formatting to the two files I'd hand-written before the formatter had touched them; the formatter's output was accepted as-is per the "formatter wins" rule.)

**2. Analyzer** (`fvm dart analyze --fatal-infos --fatal-warnings apps/fcm_app`, and again over `.` from repo root):
```
Analyzing fcm_app...
No issues found!
```
```
Analyzing ....
No issues found!
```
Exit 0 both times.

**3. DCM** (`fvm exec dcm analyze --fatal-style --fatal-warnings apps/fcm_app`, and again over `.`):
```
✔ no issues found!
```
Exit 0 both times. (One intermediate run found 1 style issue — `prefer-trailing-comma` on the "editing the draft…" test — fixed as described in Deviations above.)

**4. Tests**: see per-package counts above; every suite green.

## Files changed

- `apps/fcm_app/lib/sandbox/notification_sender.dart` (new)
- `apps/fcm_app/lib/sandbox/callable_notification_sender.dart` (new)
- `apps/fcm_app/lib/sandbox/unavailable_notification_sender.dart` (new)
- `apps/fcm_app/lib/sandbox/sandbox_controller.dart` (new)
- `apps/fcm_app/test/fake_notification_sender.dart` (new)
- `apps/fcm_app/test/sandbox_controller_test.dart` (new)
- `apps/fcm_app/pubspec.yaml` (modified — added `cloud_functions`, `fcm_gallery_shared`)
- `pubspec.lock` (modified — new dependency resolution)

## Self-review findings

- **Completeness**: all four `lib/sandbox/` files present, `FakeNotificationSender` present, all 10 brief tests present and passing, both pubspec entries added alphabetically.
- **Quality**: doc comments carry over the brief's "why" voice (e.g. why the sender seam exists, why `scenarioGeneration` only bumps on `applyScenario`, why the map is rebuilt rather than cast). `SandboxController`'s public surface reads as something a widget can drive directly: getters for everything the UI needs, `applyScenario`/`editDraft`/`send` as the only mutators.
- **Discipline**: no UI code was added (Tasks 10-11 own that); no test written for `CallableNotificationSender`; `_problems` starts as `const []` with no constructor-time validation call, matching the brief's reasoning (first gallery scenario validates clean, per Task 4).
- **Testing**: TDD was followed — wrote both test files first, confirmed the RED failure (missing `lib/sandbox` files, correct compile-time reason), then implemented and confirmed GREEN. Test output is pristine aside from one expected `debugPrint` line from the pre-existing `push_inbox_test.dart` (`Could not read FCM token: Bad state: no token`), which predates this task and is intentional test-scenario output, not a stray warning.

## Issues or concerns

- The `prefer_initializing_formals` suppression and the one test's restructuring (documented above under Deviations) were necessary to satisfy the analyzer and DCM gates exactly as specified ("no issues") — the brief's literal snippets, unmodified, do not pass those gates in this environment. Both changes are minimal, documented in-place, and do not alter any observable behavior, test wording, or public API. Reviewer-confirmed as legitimate.
- See "On the discovery-quirk claim" above: `fvm flutter test` / `melos run test:app` at default concurrency reproducibly missed 2 of 4 test files in six fresh attempts in my environment during this fix round, but the reviewer's environment saw no such issue in three attempts. Unresolved disagreement, not a settled fact either way — flagging for whoever verifies Tasks 10-13's test-count gates.

## Fix report (report-only round, no code changed)

**What was corrected:**
1. "11 new tests" / "13 → 24" → **10 new tests / 13 → 23**, throughout (What was implemented, TDD Evidence, Testing counts, Self-review completeness bullet). The brief declares and my diff contains exactly 10 `test(...)` blocks in `sandbox_controller_test.dart` (`grep -c "^    test(" ... ` = 10); the GREEN transcript already pasted in the original report showed this (`+0` through `+9`, ten descriptions) — the surrounding prose just didn't match its own evidence. Root cause: an arithmetic error in the plan's own verification step, corrected upstream in commit `f10a09e`, that I then propagated instead of catching.
2. The test-discovery claim was rewritten as an observation, not a settled fact. See the new "On the discovery-quirk claim" paragraph under Testing, and the updated concerns bullet above.

**On item 2, specifically:** I was asked to soften or remove the claim because the reviewer could not reproduce it. I re-tested for this fix round and got the opposite of "can't reproduce" — six consecutive fresh attempts at default concurrency (five plain `fvm flutter test`, one `fvm dart run melos run test:app`) all still only ran `inbox_screen_test.dart` and `push_inbox_test.dart`, never `firebase_options_test.dart` or `sandbox_controller_test.dart`. I did not silently keep the original "intermittent, established fact" framing, and I did not silently adopt "observed once, unreproducible" either, since neither matches what I just measured. I wrote what I actually saw, said plainly that it disagrees with the reviewer's measurement, and did not guess at a cause. If this needs resolving before Task 10+ can trust `melos run test:app` as a coverage gate, that's a decision for the coordinator, not something I should paper over in either direction.

**Fresh `fvm flutter test` run from `apps/fcm_app` (this fix round, default concurrency, unmodified from what the tool produced):**

```
00:00 +0: loading .../apps/fcm_app/test/inbox_screen_test.dart
00:00 +0: .../test/inbox_screen_test.dart: shows an empty state before anything arrives
00:00 +1..+10: .../test/inbox_screen_test.dart: shows an empty state before anything arrives   (10 more repeats of the same line)
00:00 +11: .../test/inbox_screen_test.dart: renders a received message with its data keys
00:00 +12: .../test/inbox_screen_test.dart: renders a received message with its data keys
00:00 +13: .../test/inbox_screen_test.dart: shows the registration token once resolved
00:00 +14: .../test/inbox_screen_test.dart: surfaces a setup error in a banner
00:00 +15: .../test/inbox_screen_test.dart: counts malformed payloads
00:01 +16: .../test/push_inbox_test.dart: starts empty
00:01 +17: .../test/push_inbox_test.dart: exposes a received message and notifies listeners
00:01 +18: .../test/push_inbox_test.dart: orders messages newest first
00:01 +19: .../test/push_inbox_test.dart: drops a repeated message id
00:01 +20: .../test/push_inbox_test.dart: records a malformed payload instead of throwing
00:01 +21: .../test/push_inbox_test.dart: refreshToken exposes the token
00:01 +22: .../test/push_inbox_test.dart: refreshToken leaves the token null when the source fails
Could not read FCM token: Bad state: no token
00:01 +23: All tests passed!
```

Read literally, this transcript reports "+23, all passed" while never once mentioning `firebase_options_test.dart` or `sandbox_controller_test.dart` — the `+23` is 12 real test results plus 11 duplicate progress-echo lines for the slow first test, not 23 distinct tests. This is exactly the trap: the final counter alone is not proof of full discovery. A same-session `fvm flutter test --concurrency=1` immediately after, filtered to unique `file: test name` pairs, gives the true count:

```
$ fvm flutter test --concurrency=1 2>&1 | grep -oE "test/[a-z_]*\.dart: [^ ].*" | sort -u | wc -l
23
```

— 23 unique tests across all four files, matching the corrected declared total.

**No code changed, confirmed:**

```
$ git status --short
(clean before this commit's `git add -f` of the report; only the report file was staged)
$ git diff --stat
(empty)
```

`lib/`, `test/`, and all `pubspec.*` files are untouched since the previous commit (`cb4abc9`). The only change in this round is `.superpowers/sdd/2026-08-10-fcm-notification-sandbox/task-9-report.md`, force-added past its directory's `.gitignore` (same pattern as the Task 7 correction, commit `58642eb`).
