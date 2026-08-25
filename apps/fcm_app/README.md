# fcm_app

The Flutter app in this workspace. Receives Firebase Cloud Messaging pushes and
lists them.

Do not run tooling from this directory — the workspace root owns dependency
resolution and the melos scripts. From the repo root:

```bash
fvm dart run melos run test:app     # widget tests (no Firebase needed)
fvm dart run melos run ci           # the full gate
cd apps/fcm_app && fvm flutter run  # run on a device
```

End-to-end tests live in `integration_test/`, one file per catalogue group, and run
against a **connected Android device** rather than in the gate:

```bash
fvm dart run melos run api:serve    # one shell, GOOGLE_APPLICATION_CREDENTIALS set
adb reverse tcp:8080 tcp:8080       # physical handset only
fvm dart run melos run test:e2e     # another shell
```

Running it needs the `patrol_cli` activated globally — it is not something
`melos bootstrap` installs:

```bash
fvm dart pub global activate patrol_cli
```

The CLI and the `patrol` package are version-locked to each other: `patrol_cli`
declares a minimum `patrol` it will run against and refuses anything older with
`throwToolExit`. `patrol_cli` 4.7.0 is what is installed on this machine, and it
requires `patrol: ^4.9.0`, which `apps/fcm_app/pubspec.yaml` pins to. A `pub
upgrade` or a conflict-driven re-resolution that drifts the lock below that
floor breaks every target in this suite instantly — check both versions agree
before assuming a broken run is the app's fault.

26 of the 66 scenarios run. The other 40 are skipped with a reason taken from the
catalogue — 34 wait on a `ScenarioNeed` the app has not built, 4 need a physical
iPhone, and `b3_killed` and `f5_deeplink_killed` would each have to kill the app the
test runs inside. The split is pinned by `test/integration_coverage_test.dart`, which
runs in the ordinary gate, so a scenario becoming unblocked shows up as a failing
count rather than as silence.

The expectations in `integration_test/support/expected_events.dart` were derived from
reading the code, not from a device. See `integration_test/CALIBRATION.md` before
trusting a failure.

`integration_test/support/app_harness.dart` mirrors `lib/main.dart`'s startup and
stream wiring by hand, because `main` itself is not callable from a test that has
to interleave native automation with startup. It will not follow a change to
`main.dart` on its own — the two agree today except for the deliberately omitted
`_flushQuietly`, and it is on whoever next edits `main.dart` to check the harness
still matches.

Running `patrol build` or `patrol test` by hand leaves a generated
`apps/fcm_app/patrol_test/` directory behind. It is gitignored, but the gate walks
the filesystem regardless: `dart format` (so `format:check` fails on a file nobody
meant to commit), `melos run analyze` and `melos run dcm` all walk it too — delete
it before running the gate. `melos run test:e2e` deletes it itself when the loop
finishes; this warning is for anyone invoking `patrol` directly instead.

Structure:

- `lib/pages/<page>/` — one directory per destination (`inbox`, `scenarios`,
  `sandbox`, `runs`, `countdown`, `telemetry`, plus `shell`), each holding its page
  widget, its `cubit/`, and the `widgets/` only that page uses. `lib/app.dart` is
  the root that provides the cubits
- `lib/domains/<domain>/` — `entities/` for the interfaces and value types,
  `repositories/` for the app-scoped owners such as `PushRepository`, and
  `data_sources/` for the implementations that reach Firebase, Drift, HTTP or
  `shared_preferences`
- `lib/firebase_options.dart` — project id is real (`fcm-sandbox-770fa`), but
  `apiKey`, `appId` and `messagingSenderId` are **still placeholders**; see the
  root README for how to fetch them

Push payload parsing lives in `packages/core`, which has no Flutter dependency.
