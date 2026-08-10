# fcm_functions

The backend for the `fcm_app` sandbox: one callable, registered in Dart as
`sendNotification` and **deployed as `send-notification`**, which validates a
`NotificationDraft` and sends it to a device through the Firebase Admin SDK.

`firebase_functions` runs every registered name through its `toCloudRunId`
sanitiser, so the kebab-case form is what appears in the generated
`functions.yaml`, in the deployed Cloud Run service, and in the path the
container routes on. That is why the app calls `send-notification` — see
`CallableNotificationSender.functionName`.

Do not run tooling from this directory — the workspace root owns dependency
resolution and the melos scripts. From the repo root:

```bash
fvm dart run melos run functions:build      # regenerate functions.yaml
fvm dart run melos run functions:compile    # what deploy compiles
fvm dart run melos run functions:serve      # Functions emulator
fvm dart run melos run functions:deploy     # needs Blaze
fvm dart test apps/fcm_functions            # unit tests, no emulator needed
```

Structure:

- `bin/server.dart` — the entry point the Firebase CLI requires, by that exact
  path. One line.
- `lib/register_functions.dart` — the callable declaration. `name:` and
  `options:` are `@mustBeConst` because a build_runner builder reads them from
  the AST to generate `functions.yaml`; a variable there makes the endpoint
  undiscoverable.
- `lib/send_notification_handler.dart` — the handler, taking its sender, id
  generator and clock as parameters so it is testable with no Firebase runtime.
- `lib/notification_message_builder.dart` — draft to `TokenMessage`, pure.
- `lib/fcm_message_sender.dart` — the interface that keeps the Admin SDK out of
  the handler, mirroring `PushSource` in the app.

## How this deploys

`firebase deploy` runs `build_runner` to produce `functions.yaml`, then
`dart compile exe … --target-os=linux --target-arch=x64`, and uploads the
resulting `bin/server` binary. Because the binary is self-contained, the path
dependency on `packages/fcm_gallery_shared` links in at compile time and needs
nothing at runtime.

Two consequences worth knowing:

- The Firebase CLI invokes `dart` from `PATH`, and this repo has no global Dart.
  Every firebase command therefore goes through `fvm exec firebase …`, which is
  what the melos scripts do.
- The CLI looks for `<source>/.dart_tool/package_config.json` to decide whether
  to run `dart pub get`. A pub workspace only has one, at the repo root, so the
  CLI re-runs `pub get` on every deploy. Harmless, just noisy.

## Not verified

`firebase deploy` has never been run against `fcm-sandbox-770fa`. The Cloud
Functions API is disabled on the project, and Dart functions target Cloud Run,
which requires the Blaze plan. `functions:compile` succeeding is the evidence
that the code is deployable; the deploy itself is not.
