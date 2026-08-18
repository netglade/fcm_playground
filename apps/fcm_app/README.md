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

17 of the 66 scenarios run. The other 49 are skipped with a reason taken from the
catalogue — 44 wait on a `ScenarioNeed` the app has not built, 4 need a physical
iPhone, and `b3_killed` would have to kill the app the test runs inside. The split is
pinned by `test/integration_coverage_test.dart`, which runs in the ordinary gate, so a
scenario becoming unblocked shows up as a failing count rather than as silence.

The expectations in `integration_test/support/expected_events.dart` were derived from
reading the code, not from a device. See `integration_test/CALIBRATION.md` before
trusting a failure.

Running `patrol build` or `patrol test` by hand leaves a generated
`apps/fcm_app/patrol_test/` directory behind. It is gitignored, but `dart format`
walks it anyway and `melos run format:check` then fails on a file nobody meant to
commit — delete it before running the gate. `melos run test:e2e` deletes it itself
when the loop finishes; this warning is for anyone invoking `patrol` directly
instead.

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
