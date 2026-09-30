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
- [Node.js and npm](https://nodejs.org) — needed to install `firebase-tools`,
  which the [Firebase project](#firebase-project) step below shells out to;
  nothing else in this repo touches them
- `$HOME/.pub-cache/bin` on `PATH` — where `dart pub global activate` installs
  a package's executable. This repo needs two: `flutterfire_cli` (below) and,
  only for the end-to-end tests, `patrol_cli`.

Everything else Dart-side, melos included, comes from `pub get`.

### Bootstrap

Run these from the repo root, not from `apps/fcm_app` or `apps/fcm_api` — the
root is a pub workspace, and it alone owns dependency resolution and the
melos scripts.

```bash
fvm install                             # fetch the SDK named in .fvmrc
fvm flutter pub get                     # resolve the workspace (needed once, for melos)
fvm dart run melos bootstrap            # link packages, generate IDE files
fvm dart run melos run --no-select ci   # format check → analyze → DCM → tests
```

`flutter pub get`, not `dart pub get`: the workspace contains a Flutter app,
and `dart pub` resolves it without the Flutter SDK — either failing outright
(`shared_preferences_platform_interface … requires the Flutter SDK`, which
`dart pub` itself answers with *"Flutter users should use `flutter pub`"*) or
writing a lockfile that pins a different, Flutter-less dependency set.

melos is a dev dependency of the workspace root, not a global install, so run
it as `fvm dart run melos …`. In a non-interactive shell, every `melos run`
needs `--no-select`, or melos prompts for a package to run against and dies
with `StdinException: Error getting terminal echo mode`.

### Running the app

```bash
cd apps/fcm_app && fvm flutter run
```

With no Firebase project configured yet, the app still starts — it falls
back to a disabled push source and shows a banner explaining what's missing,
rather than crashing on an initialization that cannot succeed. That fallback
is not a special case for this banner; it's the same pattern every data
source in the app follows, and [`docs/architecture.md`](docs/architecture.md)
is where it's explained properly.

The first Android build needs core library desugaring enabled, or
`:app:checkDebugAarMetadata` fails with `Dependency
':flutter_local_notifications' requires core library desugaring to be
enabled for :app`. This repo already sets `isCoreLibraryDesugaringEnabled =
true` and adds `coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")`
in `apps/fcm_app/android/app/build.gradle.kts`, so a fresh clone builds
clean — worth knowing if that file ever gets touched.

### Firebase project

Every field in `apps/fcm_app/lib/firebase_options.dart` — `apiKey`, `appId`,
`messagingSenderId`, `projectId`, and the rest — ships as an obvious
placeholder, not a real project's values, so the banner above is what a
fresh clone always shows. There is no shared project a stranger can point
this at; make the banner go away with a Firebase project of your own:

1. Create one at [console.firebase.google.com](https://console.firebase.google.com)
   — the free Spark plan is enough, and Cloud Messaging needs no extra
   enabling.
2. Install the Firebase CLI and log in, then activate FlutterFire's CLI:

   ```bash
   npm install -g firebase-tools && firebase login
   fvm dart pub global activate flutterfire_cli
   ```

3. From `apps/fcm_app`, run the configuration wizard with no `--project` —
   it lists every project your logged-in account can reach and lets you pick
   one, so there is nothing to name on the command line:

   ```bash
   cd apps/fcm_app && fvm exec flutterfire configure
   ```

   This overwrites `firebase_options.dart` with your project's real values
   and, for Android, drops a `google-services.json` into `android/app` —
   the file `android/app/build.gradle.kts` only applies the
   `com.google.gms.google-services` plugin when it is present, precisely so
   a checkout without one still builds.

`.firebaserc`'s project name and `firebaseProjectId` in
`apps/fcm_app/lib/firebase_setup.dart` are both the placeholder
`your-project-id` — the same one `firebase_options.dart` uses — not a real
project, so there is nothing for the `firebase` CLI's own default
`--project` to resolve until you put your project's id in `.firebaserc`
yourself (`firebase use <your-project-id>`, or edit the file directly).
`flutterfire configure` does not read or write either file — it asks which
project interactively — so updating them is only worth doing if you drive
the `firebase` CLI directly from this repo. Nothing in the running app reads
`firebaseProjectId` any more — the in-app banner no longer names a
project — it is kept only as a fixture value for
`service_locator_test.dart` and to give `.firebaserc`'s value a Dart-side
mirror.

Run the app again and push works.

### Running the API

`apps/fcm_api` is a development tool, not a production service: no
authentication, bound to loopback only — see
[`docs/telemetry.md`](docs/telemetry.md) for why that bind is the only
thing protecting it.

```bash
GOOGLE_APPLICATION_CREDENTIALS=~/.config/fcm-app-service-account.json \
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
GOOGLE_APPLICATION_CREDENTIALS=~/.config/fcm-app-service-account.json \
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

- [`docs/overview.md`](docs/overview.md) — start here: what the app does, what
  notifications you can build, how Firebase and tokens fit together
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
- [Push notifikace naživo](https://claude.ai/artifact/8NbAbebuf15AE6yYdrfzgw)
  — workshop handout in Czech: how a push travels, tokens, payload shapes,
  channels, and every demo scenario with its payload and a screenshot from a
  real phone

## License

[MIT](LICENSE).
