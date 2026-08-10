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
├── firebase.json               Firebase CLI config (functions + emulators)
├── apps/fcm_app/               Flutter app (Android, iOS, web)
├── apps/fcm_functions/         Dart Cloud Functions — the sandbox backend
├── packages/core/              pure Dart: push payload model + parser
└── packages/fcm_gallery_shared/ pure Dart: the contract app and functions share
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
| `melos run functions:build` | regenerate `apps/fcm_functions/functions.yaml` |
| `melos run functions:compile` | compile the linux-x64 binary that deploy uploads |
| `melos run functions:serve` | run the Functions emulator |
| `melos run functions:deploy` | deploy the functions (needs Blaze) |

Each script shells out through `fvm`, so the pinned SDK is used no matter what
is on `PATH`. Note `fvm exec dcm …` rather than `fvm dcm …`: fvm only proxies
`dart` and `flutter`, and `exec` is how third-party tools get the pinned SDK.

## Debugging in VS Code

`.vscode/launch.json` and `.vscode/settings.json` are tracked; the rest of
`.vscode/` is not. Four configurations, all with `cwd` set to `apps/fcm_app`
because the repo root is a pub workspace rather than a Flutter project:

| Configuration | Target |
| --- | --- |
| `fcm_app · Android phone` | the phone pinned by serial, debug mode |
| `fcm_app · Android phone (profile)` | same phone, profile mode for real frame times |
| `fcm_app · pick device` | whatever is selected in the status bar — use this on another machine |
| `fcm_app · Chrome` | Chrome on a fixed port, `http://localhost:5555` |

`dart.flutterSdkPath` in `settings.json` points the Dart extension at
`.fvm/flutter_sdk`. **This is what makes the launch configs work** — without it
the extension searches `PATH`, where a fvm-only machine has no Flutter at all.

Two things worth knowing about `deviceId`:

- `flutter run -d` matches a **prefix of the device id or name**, not a platform.
  `"deviceId": "android"` resolves to nothing. The Android configs therefore pin
  a serial; run `fvm flutter devices` and substitute yours, or use
  `fcm_app · pick device`.
- `"deviceId": "chrome"` works because that is literally the device's id.

The web port is fixed rather than random because Firebase authorised domains and
CORS allowlists are configured per origin, and a moving port makes that
unworkable. Note that push on web additionally needs a
`web/firebase-messaging-sw.js` service worker, which `flutterfire configure`
does not generate for you.

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

## Firebase project

The project is **`fcm-sandbox-770fa`**, recorded in two places:

- `.firebaserc` — read by the `firebase` CLI, so its commands default to this project
- `firebaseProjectId` in `apps/fcm_app/lib/firebase_setup.dart` — used by
  `firebase_options.dart` for all three platforms

### Still needed before push works

`apiKey`, `appId` and `messagingSenderId` in
`apps/fcm_app/lib/firebase_options.dart` are **still placeholders**. They are
per-app credentials issued by Firebase and cannot be derived from the project id,
so they have to be fetched:

```bash
npm install -g firebase-tools && firebase login   # the CLI is not installed yet
fvm dart pub global activate flutterfire_cli
cd apps/fcm_app
fvm exec flutterfire configure --project=fcm-sandbox-770fa
```

That overwrites `firebase_options.dart` with real values — the placeholder file
deliberately mirrors the generated shape, so it is a straight overwrite — and
handles the Android Gradle and iOS wiring. `google-services.json` and
`GoogleService-Info.plist` are gitignored; they are per-developer, not per-repo.

Until then the app still runs. `main()` compares `apiKey` against the sentinel in
`firebase_setup.dart`, throws before `Firebase.initializeApp`, falls back to
`DisabledPushSource`, and the UI shows a banner with the commands above. The check
keys off `apiKey` rather than `projectId` precisely because the project id is now
real — a real key is the thing that is still missing.

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

## The notification sandbox

The app's Sandbox page composes a push and sends it to the device it is running
on. The request goes to `send-notification`, a Dart Cloud Function in
`apps/fcm_functions` — registered in Dart as `sendNotification`, deployed under
the kebab-case name `firebase_functions`' `toCloudRunId` sanitiser produces. It
validates the draft, stamps an `id` and `sentAt`, and sends the message through
the Firebase Admin SDK.

The design intent is that the push then comes back through FCM into the same
inbox as any other, carrying the `payloadId` the send reported, so the round trip
is visible rather than inferred. **That path has not been exercised yet** — see
"Not verified" below and `apps/fcm_functions/README.md`.

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
`maxInstances: 3` and `timeoutSeconds: 30` cap what abuse can cost.

Firebase App Check is the production answer and is deliberately out of scope: it
needs Play Integrity and DeviceCheck registration plus debug providers for the
emulator and the tests, none of which this sample demonstrates. Anonymous
Firebase Auth was considered and rejected — anyone can mint an anonymous
account, so it would add a dependency without adding a barrier.

## Verified on this machine

`melos run ci` passes clean (20 `core` tests, 42 `fcm_gallery_shared` tests, 18
`fcm_functions` tests, 38 `fcm_app` tests) and `fvm flutter build web --release`
succeeds. The Android and iOS builds have **not** been verified here — there is
no Android SDK or Xcode on this machine. `firebase deploy` has not been run
either — see `apps/fcm_functions/README.md`.

### The sandbox

The Functions emulator starts and serves the callable: the log shows
`send-notification` initialized at `127.0.0.1:5001`, matching the port in the
root `firebase.json`. That one boot proves the generated manifest is
well-formed, the compiled Dart entry point actually runs, and request routing
resolves to the right endpoint — the largest piece of the sandbox path that
this machine can exercise.

It came up with **no credentials present at all**, and logged nothing about
them. That is worth calling out: a missing service account key does not stop
the emulator from starting. It will only surface once a call actually tries to
send, which is a less obvious failure mode than "the emulator won't boot" for
whoever sets this up next.

No push has ever been sent, on this machine or otherwise. There is no Android
device or emulator here — `fvm flutter devices` sees only `Linux (desktop)`
and `Chrome (web)` — and no service account key, so the send path, a
notification actually appearing on a device, and the message landing in the
Inbox with the `payloadId` the app reports are all untested. Web is not a
substitute for that: web push additionally needs a
`web/firebase-messaging-sw.js`, which `flutterfire configure` does not
generate.

`firebase deploy` remains unrun for the same reason noted above — the Cloud
Functions API is disabled on `fcm-sandbox-770fa` and Dart functions deploy to
Cloud Run, which needs the Blaze plan.
