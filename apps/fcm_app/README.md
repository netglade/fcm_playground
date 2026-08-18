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
