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
- `lib/firebase_options.dart` — project id is real (`fcm-sandbox-770fa`), but
  `apiKey`, `appId` and `messagingSenderId` are **still placeholders**; see the
  root README for how to fetch them
- `lib/sandbox/` — `NotificationSender` interface plus its callable and
  unavailable implementations, `SandboxController`, and `functions_setup.dart`,
  which picks between the emulator and the deployed function
- `lib/ui/app_shell.dart` — the app's only `Scaffold`; owns the app bar and the
  drawer, so each destination is a body widget with no chrome of its own

Push payload parsing lives in `packages/core`, which has no Flutter dependency.

## Running against the Functions emulator

The sandbox calls `send-notification` in `apps/fcm_functions` — kebab-case,
because `firebase_functions` sanitises the `sendNotification` name the Dart
source registers. To point it at a local emulator instead of a deployed
function, pass the host at build time:

```bash
# From the repo root, in one terminal:
fvm dart run melos run functions:serve

# In another, from apps/fcm_app. 10.0.2.2 is the host as seen from the Android
# emulator; use the machine's LAN address from a physical device.
fvm flutter run --dart-define=FUNCTIONS_EMULATOR_HOST=10.0.2.2
```

Without the define, the app calls the deployed function.

The emulator needs credentials of its own: it has no metadata server, so the
Admin SDK cannot authenticate to send a real push. Download a service account
key from the Firebase console (Project settings → Service accounts) and export
`GOOGLE_APPLICATION_CREDENTIALS` before starting it. `*-service-account.json` is
gitignored.
