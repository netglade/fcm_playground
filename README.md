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
├── apps/fcm_api/               local HTTP server that sends pushes through FCM
├── packages/core/              pure Dart: push payload model + parser
└── packages/fcm_gallery_shared/ pure Dart: the contract the app and API share
```

`packages/core` has **no Flutter dependency**. The message model and the payload
parser live there so they can be tested with plain `dart test`, with no device,
no Flutter binding and no Firebase project. Everything plugin-shaped lives in
the app behind `PushSource`, an interface with two implementations
(`FirebasePushSource`, `DisabledPushSource`) plus a fake in the tests — which is
why the widget tests never touch Firebase.

`packages/fcm_gallery_shared` holds what the two sides must agree on: FCM's own
`Message` model, typed as `FcmMessage` and its nested blocks
(`AndroidConfig`, `ApnsConfig`, `WebpushConfig`, `FcmNotification`, …), the
scenario gallery's raw payload templates, and the `/send` request and response
DTOs. It no longer depends on `core` for anything — the inbox's four reserved
`data` keys are `core`'s concern alone, and this package only knows the shape
FCM itself defines.

`apps/fcm_api` is a plain `shelf` server, not a Cloud Function: `dart run` and
`curl` are the whole story, and the interesting logic — the FCM v1 payload and
the status mapping — is pure and unit-tested without a credential.

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
| `melos run api:serve` | run the send API on `127.0.0.1:8080` |
| `melos run test:core` | `dart test` in pure-Dart packages |
| `melos run test:app` | `flutter test` in Flutter packages |
| `melos run test` | both suites |
| `melos run ci` | the full gate, in order |

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

What the Sandbox sends is FCM's own v1 `Message` object — typed in
`packages/fcm_gallery_shared` as `FcmMessage`, with nested blocks for
`notification`, `android`, `webpush`, `apns` and `fcm_options`. A `Scenario`
holds a raw JSON template of that object, so it can be pasted straight out of
[Google's REST reference](https://firebase.google.com/docs/reference/fcm/rest/v1/projects.messages)
without translation; the Sandbox's form lets you change the template before
sending.

`apps/fcm_api`'s `POST /send` is a passthrough. It takes

```json
{"token": "<registration token>", "validate_only": false, "message": {"…": "…"}}
```

parses `message` with `FcmMessage.fromJson`, injects `token` as the delivery
target — a template must not set its own `token`, `topic` or `condition`, and
is rejected if it does — forwards the result to FCM verbatim, and on success
answers

```json
{"messageId": "projects/p/messages/0:1234…", "sentAt": "2026-08-12T09:30:00Z"}
```

The parser is strict: an unknown key anywhere inside `message`, at any depth,
is rejected with the JSON path that named it, for example
`{"error": "message.android.notification: unknown field \"titel\""}`, rather
than being silently dropped or sent as something else. `apns.payload`,
`webpush.notification` and every `data` map are the exception — FCM defines
those as free-form, so whatever is inside them passes through unexamined,
`aps` dictionary included. The model reads and writes the same snake_case keys
FCM's REST API does (`fcm_options`, `validate_only`, …), so a payload copied
from Google's docs round-trips through `FcmMessage.fromJson`/`.toJson()`
unchanged.

On arrival, `core`'s parser treats `title` and `body` as optional: a data-only
push, with no `notification` block at all, still reaches the inbox, showing a
`(no title)` placeholder in place of the missing headline. As a result,
`PushInbox.rejections` is now a **rare** signal rather than an expected one —
only a blank `id` or an unparseable `sentAt` still trips it. Neither comes from
the server: the client fills them from the FCM envelope itself (`messageId` and
`sentTime`) and then spreads the message's own `data` over the top, so they are
always present unless a `data` entry overrides one of them with something
broken. Adding `id` or `sentAt` to the `data` map in the Sandbox form is
therefore the one way to trip it on purpose.

**A real loss of observability:** the send response no longer carries a
payload id — only FCM's own `messageId`, which has no relationship to
anything the inbox stores. Matching a send to its arrival therefore needs an
`id` you put in the message's `data` map yourself; there is no longer any
other way to tell which arriving push came from which send.

## The payload form

The Sandbox edits the message through a form, not a JSON text field. Ten
collapsible sections mirror FCM's own objects one for one — `message`,
`notification`, `android`, `android.notification`, `android.notification.
light_settings`, `apns`, `webpush` and the three `fcm_options` variants — nesting
four levels deep exactly as the payload does. Every section starts closed except
the outermost, so arriving shows the payload's shape rather than a wall of
fields; each header carries an error badge that lights when anything inside it is
invalid, at any depth, so a bad field cannot hide behind a closed section while
Send sits disabled.

**Optional booleans are tristate, and that is not a nicety.** FCM distinguishes
"absent" from "false": omitting `direct_boot_ok` leaves the platform default in
place, while sending `false` states a choice. A plain checkbox has only two
states and would silently send `false` for every flag the user never touched, so
each one offers unset / true / false and shows "Not sent" when unset. The same
rule drives the text fields — an empty box means the key is omitted, not sent as
`""` — and emptying a list or map editor omits the key rather than sending `[]`
or `{}`.

**`apns.payload` and `webpush.notification` are edited as dotted-path rows**
(`aps.alert.title`, `aps.badge`) instead of nested controls. FCM defines both as
free-form — Apple's `aps` dictionary is Apple's, not Google's — so no form can
enumerate their fields. Rows expand back into nested JSON on send, with numeric
path segments becoming list indices.

**The accepted limitation: there is no JSON escape hatch.** Only fields the form
models can be sent. That is the deliberate trade for a form that cannot produce
a malformed payload, and the typed model in `packages/fcm_gallery_shared` covers
the whole of FCM's v1 `Message`, so the gap is FCM's future additions rather
than its present surface. All nine gallery scenarios round-trip through the form
unchanged — a test asserts it, so a field missing from a form fails the build.

## Sending a test push

The Sandbox page (drawer → Sandbox) composes a payload and sends it to the
device the app is running on, through `apps/fcm_api`.

**One-time:** download a service account key from the
[Firebase console](https://console.firebase.google.com/project/fcm-sandbox-770fa/settings/serviceaccounts/adminsdk)
(**Generate new private key**) and save it outside the repo, e.g.
`~/.config/fcm-sandbox-service-account.json`. It grants send rights on the whole
project, so it is not committed — `*service-account*.json` is gitignored as a
second line of defence.

Run the API:

```bash
GOOGLE_APPLICATION_CREDENTIALS=~/.config/fcm-sandbox-service-account.json \
  fvm dart run melos run api:serve
```

It listens on `127.0.0.1:8080` and takes `FCM_PROJECT_ID` and `PORT` as optional
overrides. Check it with `curl -s http://127.0.0.1:8080/health`.

The app defaults to `http://localhost:8080`, which needs one of:

| Target | What makes `localhost` resolve |
| --- | --- |
| Physical Android device | `adb reverse tcp:8080 tcp:8080` |
| Android emulator | `--dart-define=FCM_API_BASE_URL=http://10.0.2.2:8080` |
| Anything else | `--dart-define=FCM_API_BASE_URL=http://<host>:8080` |

Sending by hand instead:

```bash
curl -X POST http://127.0.0.1:8080/send \
  -H 'content-type: application/json' \
  -d '{"token":"<registration token from the Inbox page>",
       "validate_only":false,
       "message":{
         "notification":{"title":"Build finished","body":"Release 1.0.0 is ready."},
         "data":{"id":"msg-1","sentAt":"2026-08-12T09:30:00Z","deepLink":"/builds/42"}
       }}'
```

The `id` and `sentAt` above are read by `core`'s parser once the push arrives —
they are plain `data` keys as far as FCM and this API are concerned, not
something the server stamps. See [Message format](#message-format) above for
why: the response no longer echoes an id, so the `id` in `data` is the only
thing that ties a send to the row it produces in the inbox.

**The API is a development tool.** It has no authentication and binds loopback,
so only the machine running it can reach it. Do not deploy it as is — bound to
`0.0.0.0` it is an open relay to any token an attacker already holds.

## Notifications

A received push is shown as a notification as well as landing in the inbox, and
tapping either the notification or an inbox row opens a detail page for it.

| When the push arrives | What draws the notification |
| --- | --- |
| App backgrounded or terminated | FCM's own SDK, from the `notification` block `apps/fcm_api` sends. No app code involved. |
| App in the foreground | `LocalNotificationPresenter`, because Android shows nothing itself in this case. On iOS a single `setForegroundNotificationPresentationOptions` call is enough. |

Both use one high-importance Android channel, `fcm_sample_high`. The app creates
it, and `AndroidManifest.xml` points FCM at the same id with
`default_notification_channel_id` — without that, only the foreground banners
would be heads-up.

The inbox is durable: the newest 100 payloads are kept in `shared_preferences`
and reloaded at launch, so a push that arrived while the app was away is there
whether or not it was ever tapped. The background handler writes to a separate
key that only it appends to, and the UI drains that key at launch and on every
resume — two keys rather than one, so neither isolate read-modify-writes the
other's data.

**A push is never notified twice.** Only messages arriving on the live foreground
stream produce a banner; anything restored from storage was already shown by FCM
while the app was away, so replaying it on launch is exactly what the code avoids.

Notification permission is requested at startup by `firebase_messaging`, which
covers Android 13+'s `POST_NOTIFICATIONS` grant. Denying it costs the banners
and nothing else — the inbox still fills.

## Verified on this machine

`melos run ci` passes clean — 20 `core` tests, 91 `fcm_gallery_shared` tests, 36
`fcm_api` tests and 282 `fcm_app` tests. `fvm flutter build apk --debug`
and `fvm flutter build web --release` both succeed (compile checks only: the web
build cannot receive FCM pushes without a VAPID key, and an apk build is not the
same as running on a device). The iOS build has **not** been verified here —
there is no Xcode on this machine.

The Android build needs one thing that is easy to miss:
`flutter_local_notifications` requires **core library desugaring**, and without
it `:app:checkDebugAarMetadata` fails with
`Dependency ':flutter_local_notifications' requires core library desugaring to be
enabled for :app`. `android/app/build.gradle.kts` therefore sets
`isCoreLibraryDesugaringEnabled = true` and adds
`coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")`. This is
needed even though the app only ever shows notifications immediately and never
schedules one.

Three things remain explicitly **not verified** on this machine:

- **The `validate_only` sweep through the form** — opening each gallery scenario
  in the Sandbox and sending it with validate-only on, expecting a 200. The typed
  model's own templates were swept earlier; this is the stronger and now more
  useful claim, that what the *form* builds is also accepted. It needs a service
  account key downloaded from the Firebase console and the API running against
  it, which this machine cannot do unattended.
- **The on-device payload checks** — that `big_picture_remote` renders its image,
  that `data_only` reaches the inbox with no notification drawn, that
  `custom_channel` pops as a heads-up banner, and that `direct_boot_ok` sends
  `false` when set to false and omits the key when left unset. That last one is
  the only real-world proof of the tristate design; a widget test can show the
  three states cycling but not what leaves the device.
- **The notification behaviour** — foreground banners, heads-up tray entries
  while backgrounded, tapping a notification into the detail page, and a
  background push reaching the inbox.

No service account key has been generated for this project and no Android device
has been attached on this machine, so none of the above has actually been run.
