# FCM sample app

A small Flutter monorepo that receives Firebase Cloud Messaging pushes, set up
with **fvm** (pinned SDK), **melos** (workspace scripts) and **DCM** (static
analysis).

## Layout

```
.
├── .fvmrc                      Flutter SDK pin (3.44.8)
├── pubspec.yaml                pub workspace root + melos config
├── analysis_options.yaml       shared analyzer, linter and DCM rules
├── apps/fcm_app/               Flutter app (Android, iOS, web)
└── packages/core/              pure Dart: push payload model + parser
```

`packages/core` has **no Flutter dependency**. The message model and the payload
parser live there so they can be tested with plain `dart test`, with no device,
no Flutter binding and no Firebase project. Everything plugin-shaped lives in
the app behind `PushSource`, an interface with two implementations
(`FirebasePushSource`, `DisabledPushSource`) plus a fake in the tests — which is
why the widget tests never touch Firebase.

## Prerequisites

- [fvm](https://fvm.app) — the SDK itself is downloaded by fvm, not installed by hand
- [DCM](https://dcm.dev) on `PATH`, with a license activated (`dcm license`)

Everything else comes from `pub get`, melos included.

## Getting started

```bash
fvm install                     # fetch the SDK named in .fvmrc
fvm dart pub get                # resolve the workspace (needed once, for melos)
fvm dart run melos bootstrap    # link packages, generate IDE files
fvm dart run melos run ci       # format check → analyze → DCM → tests
```

`melos` is a dev dependency of the workspace root rather than a global install,
so the version is pinned per checkout. Run it as `fvm dart run melos …` — that
routes through the fvm-pinned Dart, so a globally activated `melos` (which needs
a `dart` on `PATH`) is not required.

## Scripts

| Command | What it does |
| --- | --- |
| `melos run analyze` | `dart analyze --fatal-infos --fatal-warnings` per package |
| `melos run dcm` | `dcm analyze --fatal-style --fatal-warnings` over the workspace |
| `melos run format` | format all Dart sources in place |
| `melos run format:check` | fail if anything is unformatted |
| `melos run fix` | apply automated analyzer fixes |
| `melos run test:core` | `dart test` in pure-Dart packages |
| `melos run test:app` | `flutter test` in Flutter packages |
| `melos run test` | both suites |
| `melos run ci` | the full gate, in order |

Each script shells out through `fvm`, so the pinned SDK is used no matter what
is on `PATH`. Note `fvm exec dcm …` rather than `fvm dcm …`: fvm only proxies
`dart` and `flutter`, and `exec` is how third-party tools get the pinned SDK.

## Tooling notes

**fvm.** `.fvmrc` is tracked; `.fvm/` (the SDK cache) is not. To move the whole
repo to another SDK, `fvm use <version>` and commit the changed `.fvmrc`.

**pub workspaces.** The root `pubspec.yaml` lists members under `workspace:`,
and each member declares `resolution: workspace`. One `pubspec.lock` and one
`.dart_tool` at the root, so `melos bootstrap` is a single resolve rather than
one per package. Member lockfiles are gitignored because they should not exist.

**melos 8.** Configuration lives under the `melos:` key in the root
`pubspec.yaml`. A separate `melos.yaml` is *not* read when the root is a pub
workspace.

**DCM.** Configured under `dart_code_metrics:` in the root
`analysis_options.yaml`; both packages inherit it via `include:`. The analyzer
supports a list of includes, so each package combines the shared config with its
own lint preset — `flutter_lints` for the app, `lints` for `core`.

## Connecting a real Firebase project

`apps/fcm_app/lib/firebase_options.dart` ships with **placeholder values**, and
`apps/fcm_app/lib/firebase_setup.dart` holds the sentinel that detects them. The
app therefore starts in a degraded mode: `main()` catches the failure, falls back
to `DisabledPushSource`, and the UI shows a banner explaining what to do instead
of crashing.

To wire up a real project:

```bash
fvm dart pub global activate flutterfire_cli
cd apps/fcm_app
fvm exec flutterfire configure
```

That overwrites `firebase_options.dart` with real values (the placeholder file
deliberately mirrors the generated shape, so it is a straight overwrite) and
handles the Android Gradle and iOS wiring. `google-services.json` and
`GoogleService-Info.plist` are gitignored — they are per-project, not per-repo.

## Message format

`PushMessageParser` expects a flat FCM `data` payload with four required keys;
anything else is passed through in `PushMessage.data`.

```json
{
  "id": "msg-1",
  "title": "Build finished",
  "body": "Release 1.0.0 is ready.",
  "sentAt": "2026-08-06T09:30:00Z",
  "deepLink": "/builds/42"
}
```

A payload that fails validation is counted and surfaced in the UI rather than
silently dropped — see `PushInbox.rejections`.

## Verified on this machine

`melos run ci` passes clean (20 `core` tests, 12 `fcm_app` tests) and
`fvm flutter build web --release` succeeds. The Android and iOS builds have
**not** been verified here — there is no Android SDK or Xcode on this machine.
