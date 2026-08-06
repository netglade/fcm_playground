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

- `lib/push/` — `PushSource` interface plus its Firebase and disabled
  implementations, and `PushInbox`, the `ChangeNotifier` the UI listens to
- `lib/ui/` — one widget per file
- `lib/firebase_options.dart` — **placeholder values**; see the root README for
  how to point this at a real Firebase project

Push payload parsing lives in `packages/core`, which has no Flutter dependency.
