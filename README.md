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
than its present surface. All 66 catalogue scenarios round-trip through the form
unchanged — a test asserts it, so a field missing from a form fails the build.

## The scenario catalogue

The Scenarios page (drawer → Scenarios, one of five destinations alongside
Inbox, Sandbox, Runs and Telemetry) holds **66 scenarios in eleven groups,
A–K**, mirroring the FCM playground test plan. Tapping one applies its payload
to the Sandbox form and switches you there; ticking several and scheduling
them instead sends you to Runs, as one run with a spacing between them. The
groups are the facets of FCM each scenario probes: basic delivery, app states,
priority and delivery window, channels and importance, appearance,
interaction, groups and badges, intrusive delivery, silent and data,
targeting, and edge cases.

**22 of the 66 work today.** The rest carry a marker naming what they still need —
notification channels, notification styles, notification actions, a launcher
badge, a device registry, a manual step, or approval from Apple or the OS that
this project cannot grant itself. That count is asserted by a test, so this
README cannot drift from the code: if a scenario is quietly unmarked to look
supported, the build fails.

A blocked scenario is **still sendable**. The push is genuine and valid; only the
behaviour it demonstrates is missing, and watching a client with no action support
receive an action payload is itself worth seeing. The banner above the form says
what is missing rather than disabling Send. Where a payload cannot produce the
scenario at all — a reboot, a Doze window, a revoked permission — the scenario
carries the exact command or procedure in a selectable block, because an adb line
that cannot be copied is one that will be mistyped.

Every one of the 66 templates round-trips `raw → FcmMessage → raw` unchanged, and
none may set its own delivery target at any depth. Both are asserted across the
whole catalogue, which is what makes 66 hand-written templates trustworthy.

## Choosing who receives a send

The delivery target lives in the **send envelope**, never in the payload:
`FcmMessage` rejects `token`, `topic` and `condition` outright, so a template
pasted out of Google's reference cannot quietly broadcast. The Sandbox offers one
selector above the form — this device, an explicit token, a topic, a condition, or
every device — and the button names the audience it will actually send to.

Only a send to *this device* needs this device's registration token; a topic or a
condition names its own audience. **Every device is refused with a 501** and a
stated reason: FCM has no such audience, so honouring it needs a registry of
tokens this API does not keep.

`curl` examples below are unchanged by this, because the target sits at the top
level of the request exactly where `token` always did.

## Telemetry

Every send gets a `trace_id`, and both sides record events against it, so
`sent → received` latency is a number rather than an impression. That is the point
of the whole thing: it turns *"push feels slow on Xiaomi"* into *"median 4m12s on
Xiaomi, 1.1s on Pixel, same payload, same minute"*.

**The API mints the trace id**, not the app, and injects it into `data.trace_id`.
Three reasons: none of the 66 catalogue templates carries one, so templates stay
untouched and their round-trip invariant is unaffected; the API is the only party
present for `queued`, `sent` and `send_failed`; and a send made by hand with `curl`
gets a trace id too, which is how half of this project's testing happens. It also
injects `data.scenario_id`, because **the payload a scenario produces does not
identify the scenario** — without the sender naming it, the scenario axis of the
matrix would be empty. Both are reserved keys in `PushMessageParser`, so neither
shows up as an "extra data" row in the inbox.

Nine events, eight of which are recorded today:

| Event | Where it comes from |
| --- | --- |
| `queued`, `sent`, `send_failed` | the API. `send_failed` carries FCM's error **code**, which is what groups a hundred failures into three causes |
| `received_fg` | the foreground stream |
| `received_bg` | the background handler — **data payloads only**, since a notification-only push never wakes it |
| `displayed` | after the local notification is actually drawn, never before |
| `opened` | a tap, carrying which of `foreground` / `background` / `killed` the app was in. On Android the tap is reported as the app resumes, *before* the payload carrying the trace id exists, so it is held and reported once that arrives |
| `dismissed` | a swipe, but **Android only** — the plugin's dismissal report lives on `AndroidNotificationDetails` alone, so iOS has no route to it — and only for notifications the app itself drew, and only while the process is still running |
| `not_received` | the one event a human asserts, and the only evidence available when the interesting answer is silence |

`opened` records its "from which state" qualifier as of this branch. `dismissed` is
the one event still short of what it should carry: it is produced now, but only on
Android and only for a foreground-drawn banner, so a device-drawn tray entry and
any iOS device both show a permanently blank row.

**Events buffer on the device and flush to `POST /events`.** They are deleted only
once the API acknowledges them, and only the ones acknowledged — a blanket clear
after a partial flush would lose whatever arrived during it, which is the common
case rather than an edge one. `record` never throws, because it is called from
inside push handlers and a throw there would take down delivery itself. The
background handler buffers without flushing: its isolate can be killed mid-request,
and the event would go with it.

**A negative latency means the clocks disagree, not that delivery beat the send.**
`GET /latency` reports both timestamps rather than clamping to zero, because
clamping turns a measurement error into a false result — and a "1 ms on Xiaomi"
would discredit every other number in the system.

**The device is identified by a generated id plus a label you type.** Not the FCM
token: it rotates on reinstall and clear-data, which would split one handset into
several columns — and `b6_token_refresh` exists precisely to make that happen. No
automatic value is as useful as "Xiaomi 13" typed by someone who knows which phone
is on the desk.

**No telemetry on web.** `drift_flutter`'s web path needs a `sqlite3.wasm` and a
drift worker shipped as assets, and the app cannot receive a push on web at all
without a VAPID key — so there is nothing there for a buffer to hold.

**The Telemetry page (drawer → Telemetry)** is where this surfaces on the device
itself: an Events tab listing every trace with all nine rows, arrived or not, and a
Latency tab drawing the `scenario × device` matrix above from `GET /latency`.
Neither tab polls — the arrival of a push is reported by the device, not by this
page, so a refresh button reloads both.

### Independent confirmation

FCM can export delivery data to BigQuery, where Google reports how many messages it
dropped and why — `DROPPED_DEVICE_INACTIVE`, `DROPPED_TOO_MANY_MESSAGES`. Enabled in
the Firebase console under Cloud Messaging, not here.

It answers the one question our own telemetry cannot: when a message never arrived,
whether **Google** dropped it or the **handset** did. Our events end at the network;
Google's begin there. It is therefore the arbiter when our numbers and a tester
disagree, and worth turning on before trusting either.

## Sending a test push

The Sandbox page (drawer → Sandbox) composes a payload and sends it to the
device the app is running on, through `apps/fcm_api`. *Schedule…* holds the
same payload for later instead of sending it now, landing it on the Runs page
(drawer → Runs) rather than in the Inbox until it fires.

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

Holding a send until the app is gone, which is what `b3_killed` needs:

```bash
curl -X POST http://127.0.0.1:8080/runs \
  -H 'content-type: application/json' \
  -d '{"delay_seconds":30,"spacing_seconds":0,
       "items":[{"token":"<registration token>",
                 "scenario_id":"b3_killed",
                 "message":{"data":{"event":"killed_probe"},
                            "android":{"priority":"HIGH"}}}]}'
```

It answers `201` with a `run_id` and a `due_at` per item, and sends nothing yet.
Swipe the app away, then read the result back with
`curl -s http://127.0.0.1:8080/runs/<run_id>` — each item carries its own
telemetry, so `queued → sent → received_bg` is one response rather than a join you
do by hand. `DELETE /runs/<run_id>` cancels whatever has not gone out; an item
already on its way to FCM is past cancelling, and says so by staying `dispatching`
or landing on `sent`.

**`POST /runs` has no idempotency key.** A response lost on the way back to the
caller and retried creates a second run and a second set of pushes — the server has
no way to tell "the same schedule again" from "a new one that happens to match".
Every other write in this feature is safely repeatable; this is the one at-least-once
path in it, worth knowing before retrying a call that might already have landed.

**A schedule survives the server being restarted.** Runs are stored in the same
SQLite file as the telemetry, and the server sweeps them at startup: an item due
within the last two minutes is sent immediately, and anything older is marked
`missed` rather than delivered into a state nobody is watching.

**The API is a development tool.** It has no authentication and binds loopback,
so only the machine running it can reach it. Do not deploy it as is — bound to
`0.0.0.0` it is an open relay to any token an attacker already holds.

## Delayed sending

`b3_killed` is the hardest scenario in the catalogue and the reason this exists: the
send has to happen *after* the app is gone, so it cannot be a button the app presses.

**A run is a group of sends created by one action, and a single delayed send is a run
of one.** `POST /runs` stores it with an absolute due time per item; a one-second
ticker in the server dispatches whatever has fallen due, through the same
`sendMessage` an immediate send uses, so a scheduled push writes the same telemetry.
The Sandbox schedules one message from *Schedule…*; the Scenarios page ticks any set
of scenarios and schedules them as one run with a spacing between them.

**Not Cloud Tasks, deliberately.** That would be right for a Cloud Function, whose
container can be killed between accepting a request and firing a timer. This API is a
long-lived loopback process, and the property that actually matters — a schedule that
survives the process dying — comes from writing it to SQLite and sweeping it at
startup, not from who owns the timer. Cloud Tasks would additionally mean deploying
the API, which the warning above says not to do.

**A run that came due while the server was down** is sent if it is less than two
minutes late, and marked `missed` otherwise. Three hours late is worse than never: it
arrives in a state nobody was observing and pollutes the latency figures it lands in.

**Cancelling reaches only what has not gone out.** An item the scheduler has already
claimed is on its way to FCM, and reporting it cancelled would be contradicted by the
timeline a minute later. A crash mid-dispatch is resolved rather than guessed: the
trace id is written before the send, so at startup the item's own telemetry says
whether FCM ever answered.

**The countdown counts on the phone's clock**, not against the server's `due_at`.
Disagreeing clocks are a documented fact here — `GET /latency` reports both
timestamps rather than clamping — and a ten-second skew would show "40 s remaining"
with thirty seconds left. It holds a wakelock so the screen does not sleep before you
have swiped the app away. *"Dim the screen"* does not switch the display off: an
ordinary Android app cannot, without DeviceAdmin. It dims and releases the lock, and
the system's own timeout does the rest — which is what the button says.

**Coming back**, the app reopens the run it was waiting on, from an id in
`shared_preferences` — the only thing that survives being swiped away. That timing is
what makes the killed case readable: `received_bg` is buffered by the background
isolate and flushed at the next launch, which is the moment you are looking at the
timeline.

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

`melos run ci` passes clean — 24 `core` tests, 231 `fcm_gallery_shared` tests, 204
`fcm_api` tests and 487 `fcm_app` tests. `fvm flutter build web --release` succeeds
(a compile check only: the web build cannot receive FCM pushes without a VAPID
key). `fvm flutter build apk --debug` currently **fails** — see below. The iOS
build has **not** been verified here either; there is no Xcode on this machine.

The Android build needs one thing that is easy to miss:
`flutter_local_notifications` requires **core library desugaring**, and without
it `:app:checkDebugAarMetadata` fails with
`Dependency ':flutter_local_notifications' requires core library desugaring to be
enabled for :app`. `android/app/build.gradle.kts` therefore sets
`isCoreLibraryDesugaringEnabled = true` and adds
`coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")`. This is
needed even though the app only ever shows notifications immediately and never
schedules one.

**The debug APK build is broken today by a second plugin, in the same family of
failure.** `app_settings` — added for the "Battery settings" link on the
countdown screen — pulls in `androidx.fragment:fragment:1.7.1`,
`androidx.window:window:1.2.0`, `androidx.lifecycle:lifecycle-runtime:2.7.0` and
twelve more transitive dependencies that all require compiling against API 34 or
later. This project's `compileSdk` is 33, so `fvm flutter build apk --debug`
fails at `:app_settings:checkDebugAarMetadata` with fifteen AAR-metadata errors,
each recommending the same fix: raise `compileSdk` to at least 34. That change
was deliberately **not** made here — it affects what every plugin in the app
compiles against, not only this one, and deciding that is a separate piece of
work from the review that found it. Until `compileSdk` is raised,
`fvm flutter build apk --debug` cannot be used to verify this branch on Android;
`fvm flutter build web --release` is unaffected and remains a valid check.

Seven things remain explicitly **not verified** on this machine:

- **The `validate_only` sweep over the catalogue** — opening each of the 66
  scenarios in the Sandbox and sending it with validate-only on, expecting a 200
  for every one whose needs do not include a device registry or a manual step.
  The round-trip test proves the templates agree with the *typed model*; only this
  proves they agree with *Google*, which is a different claim and the one that
  would catch a field FCM rejects for a reason no local parser can know. It needs
  a service account key downloaded from the Firebase console and the API running
  against it, which this machine cannot do unattended.
- **The on-device payload checks** — that `e2_image_remote` renders its image,
  that `a2_data_only` reaches the inbox with no notification drawn, that
  `k2_invalid_token` reports UNREGISTERED rather than a generic 404, and that
  `direct_boot_ok` sends `false` when set to false and omits the key when left
  unset. That last one is the only real-world proof of the tristate design; a
  widget test can show the three states cycling but not what leaves the device.
- **The telemetry round trip on a real device.** Send a scenario, then read
  `GET /latency` and confirm the figure is plausible; repeat with the app
  backgrounded and killed. The killed case is the one that matters and the one that
  needs `b3_killed`'s delayed send to arrange properly. *Partly verified here:* the
  pipeline was driven end to end against the real router and the real SQLite file
  with a stubbed FCM sender — a send, an arrival, `{"recorded":1}` then
  `{"recorded":0}` on replay, and one latency row carrying the right device and
  scenario. What is **not** verified is the FCM leg, a real handset, or the entry
  point's own socket, none of which can run without a service-account key.
- **The delayed send on a real handset.** Schedule `b3_killed`, swipe the app out of
  recents, and confirm on relaunch that the timeline holds `queued → sent →
  received_bg`. *Verified here:* a run is scheduled, claimed, dispatched through a
  stubbed sender, cancelled, missed past the grace period, and recovered across a
  restart from its own telemetry. What is **not** verified is the FCM leg, a real
  handset, the three display plugins, or that a killed app's background isolate wakes
  at all — which is the very question the scenario asks.
- **Two devices, one send** — the point of the whole pipeline, and the only way to
  see the matrix do its job. Send to a topic both have subscribed to (which needs
  the targeting work) or twice by token, and confirm two rows with different
  latencies and different labels.
- **The needs banner and the manual-steps block on a device** — that a blocked
  scenario names what it needs, that a working one shows no banner at all, and
  that an adb command can actually be selected and copied out of
  `ManualStepsBlock`. Selection behaviour is the one thing a widget test cannot
  stand in for.
- **The notification behaviour** — foreground banners, heads-up tray entries
  while backgrounded, tapping a notification into the detail page, and a
  background push reaching the inbox.

No service account key has been generated for this project and no Android device
has been attached on this machine, so none of the above has actually been run.
