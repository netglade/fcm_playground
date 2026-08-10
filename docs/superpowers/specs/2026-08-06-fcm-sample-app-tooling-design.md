# FCM sample app — tooling design

**Date:** 2026-08-06
**Status:** implemented

## Goal

A sample Flutter app in this repo, set up with fvm, DCM and melos. The tooling is
the point; the app is the thing the tooling operates on, so it should be small
but not a toy — real enough that the lint and test configuration has something to
bite on.

## Decisions

| Decision | Choice | Why |
| --- | --- | --- |
| Repo shape | `apps/fcm_app` + `packages/core` | Two packages is the minimum that makes melos meaningful. A single-package repo would make melos decorative. |
| Dependency resolution | Dart pub workspaces | Melos 8's native mode. One lockfile, one `.dart_tool`, one resolve. |
| Flutter version | 3.44.8 (stable) | Latest stable, already in the fvm cache. Dart 3.12.2 supports pub workspaces and multi-value analyzer `include:`. |
| Platforms | Android, iOS, web | Mobile is where push matters; web included on request. Desktop runners omitted as noise. |
| Firebase | `firebase_core` + `firebase_messaging`, real wiring | Requested. Project id is `fcm-sandbox-770fa`; the remaining credentials are placeholders — see "Partially configured Firebase" below. |
| melos config location | `melos:` key in root `pubspec.yaml` | Melos 8 does not read `melos.yaml` when the root is a pub workspace. Discovered during implementation; the initial `melos.yaml` failed with `NoScriptException`. |

## Architecture

The design constraint that shapes everything: **the test suite must not require
Firebase, a device, or network access.**

```
packages/core (pure Dart)
  PushMessage                 immutable, validated value type
  PushMessageParser           Map<String, Object?> → PushMessage
  PushMessageFormatException  carries the offending field

apps/fcm_app
  PushSource                  interface: payloads / token / requestPermission / dispose
  ├── FirebasePushSource      wraps firebase_messaging, flattens RemoteMessage
  └── DisabledPushSource      never emits; used when Firebase fails to start
  PushInbox (ChangeNotifier)  subscription, newest-first ordering, id de-duplication
  FcmSampleApp → InboxScreen → MessageTile / SetupErrorBanner
```

`PushSource` is the seam. Because it is an interface, the widget tests inject a
`FakePushSource` and drive arrivals synchronously; `firebase_messaging` is never
constructed in a test.

Parsing lives in `core` because it is the part with branching logic worth
exhaustive testing, and it needs nothing from Flutter. `PushInbox` owns only what
the widget tree cares about: ordering, de-duplication (FCM does not guarantee
at-most-once delivery), and error accumulation.

## Error handling

Three failure modes, each visible rather than swallowed:

1. **Firebase will not start** — `main()` catches, substitutes
   `DisabledPushSource`, and passes the reason to `PushInbox.setupError`, which
   `InboxScreen` renders as a banner. The app always opens.
2. **A payload is malformed** — `PushMessageParser` throws
   `PushMessageFormatException`; `PushInbox` records it in `rejections` and the
   UI shows a count. One bad push does not kill the stream.
3. **Token unavailable** — `PushInbox.refreshToken` logs and leaves `token` null;
   the UI simply omits the token row.

## Partially configured Firebase

`firebase_options.dart` mirrors the shape of real `flutterfire configure` output,
so regenerating it is a straight overwrite. The sentinel constant and the
user-facing instructions live in a separate `firebase_setup.dart`, so regeneration
does not delete the check.

The project id is real (`fcm-sandbox-770fa`, also in `.firebaserc`). `apiKey`,
`appId` and `messagingSenderId` are per-app credentials issued by Firebase and
cannot be derived from a project id, so they remain placeholders until someone
runs `flutterfire configure --project=fcm-sandbox-770fa`.

`main()` compares `options.apiKey` against the sentinel and throws `StateError`
before calling `Firebase.initializeApp`. This makes the unconfigured state
deterministic and self-explanatory instead of surfacing as whatever opaque error a
fake API key happens to produce.

**The check keys off `apiKey`, not `projectId`.** It originally used `projectId`,
which worked only while *every* value was fake. Setting a real project id would
have silently satisfied that check and let initialisation proceed with a bogus key
— trading a clear message for an opaque failure. The sentinel has to sit on a
value that is still missing.

## Tooling configuration

**fvm** — `.fvmrc` pins 3.44.8 and is tracked; `.fvm/` is gitignored. Every melos
script invokes `fvm dart` / `fvm flutter`, so the pinned SDK wins regardless of
`PATH`. DCM goes through `fvm exec dcm` because fvm only proxies `dart` and
`flutter`.

**DCM** — configured under `dart_code_metrics:` in the root
`analysis_options.yaml`: four metrics (cyclomatic complexity 15, nesting 5,
parameters 5, SLOC 50, excluded from tests) and 21 rules across Dart and Flutter.
Both packages inherit via `include:`, combined with their own lint preset
(`flutter_lints` for the app, `lints` for `core`) using the analyzer's multi-value
`include:`.

**melos** — nine scripts; `ci` composes `format:check → analyze → dcm → test`.
`test` splits by `packageFilters: {flutter: true/false}` so `core` runs under
`dart test` and the app under `flutter test`.

## Verification

- `melos bootstrap` — 2 packages
- `melos run ci` — passes clean: formatting, `dart analyze --fatal-infos`, DCM
  (`no issues found`), 20 `core` tests, 12 `fcm_app` tests
- `fvm flutter build web --release` — succeeds

Not verified: Android and iOS builds. This machine has no Android SDK and no
Xcode.

## Deliberately out of scope

- A CI workflow file. `melos run ci` is the single entry point a workflow would
  call; adding one was not requested.
- State management beyond `ChangeNotifier`. The app has one screen.
- Notification display (`flutter_local_notifications`), topic subscription,
  deep-link routing. The sample proves the pipeline, not the product.
