# FCM sample app

A Flutter app that receives Firebase Cloud Messaging (FCM) pushes, a
catalogue of payloads built to send at it, and a small server that sends
them. It exists to show how notifications actually behave across a device's
states, and how to structure an app around that — not to be a real product.
Three workspace members make it up: `apps/fcm_app` (the app), `apps/fcm_api`
(the server), and `packages/fcm_gallery_shared` (the payload types and
templates both sides import).

## Setup

### Prerequisites

- [fvm](https://fvm.app) — the pinned Flutter SDK is fetched by fvm, not
  installed by hand
- [DCM](https://dcm.dev) on `PATH`, with a license activated (`dcm license`)

Everything else, melos included, comes from `pub get`.

### Firebase project

The project is `fcm-sandbox-770fa`, recorded in `.firebaserc` and in
`firebaseProjectId` in `apps/fcm_app/lib/firebase_setup.dart`. `apiKey`,
`appId` and `messagingSenderId` in `apps/fcm_app/lib/firebase_options.dart`
ship as placeholders — they are per-app credentials Firebase issues and
cannot be derived from the project id — so fetch real ones once:

```bash
npm install -g firebase-tools && firebase login
fvm dart pub global activate flutterfire_cli
cd apps/fcm_app && fvm exec flutterfire configure --project=fcm-sandbox-770fa
```

That overwrites `firebase_options.dart` with real values and wires the
Android and iOS project files. Until you do this the app still runs: it
falls back to a disabled push source and shows a banner with the commands
above, instead of crashing on a Firebase init that cannot succeed.

### Bootstrap

Run these from the repo root, not from `apps/fcm_app` or `apps/fcm_api` — the
root is a pub workspace, and it alone owns dependency resolution and the
melos scripts.

```bash
fvm install                             # fetch the SDK named in .fvmrc
fvm dart pub get                        # resolve the workspace (needed once, for melos)
fvm dart run melos bootstrap            # link packages, generate IDE files
fvm dart run melos run --no-select ci   # format check → analyze → DCM → tests
```

melos is a dev dependency of the workspace root, not a global install, so run
it as `fvm dart run melos …`. In a non-interactive shell, every `melos run`
needs `--no-select`, or melos prompts for a package to run against and dies
with `StdinException: Error getting terminal echo mode`.

### Running the app

```bash
cd apps/fcm_app && fvm flutter run
```

The first Android build needs core library desugaring enabled, or
`:app:checkDebugAarMetadata` fails with `Dependency
':flutter_local_notifications' requires core library desugaring to be
enabled for :app`. This repo already sets `isCoreLibraryDesugaringEnabled =
true` and adds `coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")`
in `android/app/build.gradle.kts`, so a fresh clone builds clean — worth
knowing if that file ever gets touched.

### Running the API

`apps/fcm_api` is a development tool, not a production service: no
authentication, bound to loopback only.

```bash
GOOGLE_APPLICATION_CREDENTIALS=~/.config/fcm-sandbox-service-account.json \
  fvm dart run melos run --no-select api:serve
```

It needs a service account key — Firebase console → Project settings →
Service accounts → Generate new private key — referenced by
`GOOGLE_APPLICATION_CREDENTIALS`. Telemetry events land in a SQLite file next
to it by default; set `FCM_TELEMETRY_DB` to put it somewhere else. To reach
the API from a physical Android device rather than an emulator, `adb reverse
tcp:8080 tcp:8080`.

### End-to-end tests

The Patrol suite needs `patrol_cli` activated globally. `melos bootstrap`
does not install it, and the suite cannot run at all without it:

```bash
fvm dart pub global activate patrol_cli
```

`patrol_cli` and the `patrol` package are version-locked: the CLI declares a
minimum `patrol` version and refuses to run against anything older. If a
dependency re-resolution ever drifts `patrol` below that floor, every e2e
target breaks at once — check both versions before assuming the app itself
is at fault.

With the API running and a physical handset connected:

```bash
# shell 1
GOOGLE_APPLICATION_CREDENTIALS=~/.config/fcm-sandbox-service-account.json \
  fvm dart run melos run --no-select api:serve
adb reverse tcp:8080 tcp:8080

# shell 2
fvm dart run melos run --no-select test:e2e
```

## Scripts

Run any of these as `fvm dart run melos run --no-select <name>`:

| Script | What it does |
| --- | --- |
| `analyze` | run the Dart analyzer, treating infos as failures |
| `dcm` | run DCM over the whole workspace |
| `format` | format all Dart sources in place |
| `format:check` | fail if anything is unformatted |
| `fix` | apply automated analyzer fixes |
| `generate` | regenerate Drift's database code |
| `l10n` | regenerate the typed translations from the CSV |
| `api:serve` | run the send API on `127.0.0.1:8080` |
| `test:core` | pure-Dart tests, no Flutter binding |
| `test:app` | Flutter widget tests |
| `test:e2e` | the device-driven Patrol suite |
| `test` | `test:core` and `test:app` together |
| `ci` | the full gate: `format:check`, `analyze`, `dcm`, `test` |

## Where to read next

- [`docs/architecture.md`](docs/architecture.md) — how the workspace and the
  app's code are laid out, and why
- [`docs/notifications.md`](docs/notifications.md) — what a push actually
  does: the four payload shapes against the three app states
- [`docs/scenarios.md`](docs/scenarios.md) — how to drive the app: the
  catalogue, the payload form, delayed sending
- [`docs/telemetry.md`](docs/telemetry.md) — what gets measured, and why the
  trace id starts at the API
- [`docs/localization.md`](docs/localization.md) — how a string gets from the
  CSV into the app
