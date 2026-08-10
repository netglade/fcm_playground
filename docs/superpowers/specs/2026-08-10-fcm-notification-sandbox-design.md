# FCM notification sandbox — design

**Date:** 2026-08-10
**Status:** designed, not implemented

> **Amendment, 2026-08-10 — measured during pre-flight.** This document names
> `firebase_functions` 0.7.0. That version **cannot resolve** against Flutter
> 3.44.8: it pulls `google_cloud_shelf`, which requires `meta ^1.18.2`, while the
> Flutter SDK pins `meta 1.18.0` and an SDK pin cannot be overridden. The only
> Flutter that pins `meta ≥ 1.18.2` is the current beta (3.47.0-0.4.pre); the
> newest stable, 3.44.9, does not. Staying on stable was the decision, so the
> implementation uses **`firebase_functions ^0.6.0`** — the version
> `firebase init functions` itself generates. Three consequences: rejections
> throw `InvalidArgumentError` rather than `HttpResponseException` (a *native*
> callable error, so the app sees
> `FirebaseFunctionsException(code: 'invalid-argument')`); `runFunctionsTest` is
> unavailable because 0.6.0 ships no `lib/testing.dart`, so the handler is tested
> directly as this document already permitted; and `--delete-conflicting-outputs`
> is gone from `build_runner`. The `onCallWithData`, `CallableOptions`,
> `Instances`, `TimeoutSeconds`, `adminApp` and builder APIs are unchanged.
>
> The pre-flight probe also **retired the risk this document flags below**:
> `build_runner` works inside the pub workspace and writes
> `apps/fcm_functions/functions.yaml` where the Firebase CLI reads it, and
> `dart compile exe --target-os=linux --target-arch=x64` produces a working
> binary. See "Pre-flight findings" in
> `docs/superpowers/plans/2026-08-10-fcm-notification-sandbox.md`.

## Goal

A **Sandbox** page in `fcm_app` where you compose a push notification and send it
to your own device: pick a scenario from a gallery, edit every field, send. The
send goes through a **Dart Cloud Function** in this repo, and the scenario models,
event enum, DTOs and validation live in a **`packages/fcm_gallery_shared`**
imported by both sides.

The point is the closed loop with one shared contract: what the app composes, the
function sends, and the existing inbox receives — with a compiler-enforced
agreement in the middle.

## Decisions

| Decision | Choice | Why |
| --- | --- | --- |
| Sandbox UX | Scenario gallery **plus** editor | Presets make the gallery name mean something; the editor keeps "build your own" true. Send-only presets would not. |
| `NotificationEvent` | Notification archetype (`chat_message`, …), not lifecycle | Goes on the wire as the `event` data key. Lifecycle tracking would need a return channel and Firestore. |
| Backend location | `apps/fcm_functions/` | Consistent with the repo: `apps/` holds deployables, `packages/` holds libraries. Costs a non-default `functions.source`. |
| Package boundary | `fcm_gallery_shared` **depends on** `core` | Additive — `core` keeps the wire contract, shared adds events, scenarios, DTOs, validation. No refactor of existing code. |
| Transport | Callable + `cloud_functions` plugin | `onCallWithData<Req, Res>` on the server, `httpsCallable` in the app. Least code, shared DTOs on both sides, emulator via one line. |
| Target | The calling device only | The app sends its own registration token. Closed loop, no UI selector, no way to spam a device you do not already own a token for. |
| Auth | None, capped with `maxInstances` | Documented, accepted sandbox risk. See "Security posture". |

## Architecture

```
packages/core (pure Dart, unchanged)
  PushMessage, PushMessageParser, PushMessageFormatException
        ↑
packages/fcm_gallery_shared (pure Dart)
  NotificationEvent          enum with stable wire names
  NotificationDraft          the editable payload
  NotificationScenario       gallery preset + notificationGallery catalogue
  SendNotificationRequest    callable input DTO
  SendNotificationResponse   callable output DTO
  NotificationDraftValidator one validation, used by both sides
        ↑                              ↑
apps/fcm_app                   apps/fcm_functions
  AppShell + Drawer              registerFunctions
  ├── InboxView                  handleSendNotification
  └── SandboxView                NotificationMessageBuilder
  SandboxController              NotificationSender (interface)
  NotificationSender (iface)     └── AdminNotificationSender
  ├── CallableNotificationSender
  └── UnavailableNotificationSender
```

Data flow: `SandboxView` edits a `NotificationDraft` → `SandboxController`
validates it and wraps it with the device token into a `SendNotificationRequest`
→ callable → `handleSendNotification` revalidates, stamps `id` and `sentAt`,
`NotificationMessageBuilder` turns it into a `TokenMessage` → Admin SDK sends →
FCM delivers → the existing `FirebasePushSource` → `PushMessageParser` →
`PushInbox` → `InboxView`. The `payloadId` in the response is the `id` the user
then sees in the inbox, so the round trip is visible rather than inferred.

## Repository layout

```
.
├── apps/fcm_app/                     Flutter app (drawer + Inbox + Sandbox)
├── apps/fcm_functions/               Dart Cloud Functions (name: fcm_functions)
│   ├── pubspec.yaml                  resolution: workspace
│   ├── analysis_options.yaml         include: shared DCM config + lints
│   ├── bin/server.dart               entry point the CLI requires
│   ├── lib/
│   └── test/
├── packages/core/                    unchanged
├── packages/fcm_gallery_shared/      new, pure Dart
├── firebase.json                     NEW at the root — the CLI's config
└── pubspec.yaml                      workspace: gains two members
```

Both new packages are pub workspace members, so `melos analyze`, `melos dcm` and
`melos test:core` (filter `flutter: false` + `dirExists: test`) pick them up with
no change to the scripts.

## `packages/fcm_gallery_shared`

### `NotificationEvent`

```dart
enum NotificationEvent {
  chatMessage('chat_message'),
  buildFinished('build_finished'),
  promo('promo'),
  silentSync('silent_sync');

  const NotificationEvent(this.wireName);
  final String wireName;
  static NotificationEvent? fromWireName(String value) => …;
}
```

Travels as the `event` data key. **`core` needs no change**:
`PushMessageParser` already passes unrecognised keys through to
`PushMessage.data`, so the app resolves the event with
`NotificationEvent.fromWireName(message.data['event'])`. An unknown value returns
`null` rather than throwing — a payload from an older or newer sender must not
break the inbox.

### `NotificationDraft`

The value the editor edits and the request carries:

| Field | Type | Meaning |
| --- | --- | --- |
| `event` | `NotificationEvent` | The archetype; becomes the `event` data key |
| `title` | `String` | Notification title and the `title` data key |
| `body` | `String` | Notification body and the `body` data key |
| `data` | `Map<String, String>` | Extra data keys, passed through untouched |
| `asNotification` | `bool` | `false` sends a data-only (silent) push |
| `priority` | `NotificationPriority` | `high` or `normal` |

Immutable, with `copyWith`, `toJson` and `fromJson`. `NotificationPriority` is a
two-value enum declared alongside it, with the same `wireName` treatment as
`NotificationEvent`.

### `NotificationScenario`

`id`, `label`, `description`, `draft`. A `const notificationGallery` list holds
the presets. Tapping one replaces the form contents with its draft; everything
stays editable afterwards.

The four scenarios cover the interesting axes rather than four flavours of the
same thing: `chatMessage` (high priority, notification, `deepLink` extra key),
`buildFinished` (normal priority, notification, matches the payload example in
the root README), `promo` (normal priority, notification, extra `campaign` key),
`silentSync` (`asNotification: false`, high priority — exercises the data-only
path).

### `SendNotificationRequest` / `SendNotificationResponse`

```dart
class SendNotificationRequest {
  final String token;             // the caller's own device
  final NotificationDraft draft;
}

class SendNotificationResponse {
  final String messageId;         // FCM message name from the Admin SDK
  final String payloadId;         // the `id` data key; matches PushMessage.id
  final DateTime sentAt;
}
```

Both with `toJson`/`fromJson`, so `onCallWithData` consumes the request and
returns the response with no hand-written envelope.

### `NotificationDraftValidator`

One validator, both sides. `validate(NotificationDraft) → List<DraftProblem>`,
where a `DraftProblem` names the offending field and says what is wrong. The app
renders them inline and disables Send; the function runs the same validator and
returns 400 if it finds anything, so the app is not the only line of defence.

> **Corrected after the final review.** The rule below originally exempted
> silent messages. That broke the payload contract:
> `NotificationMessageBuilder` writes `title` and `body` into the FCM `data` map
> unconditionally, because `PushMessageParser` requires all four keys, so a
> silent draft with blank text produced `title: ''` — which the parser rejects.
> Reachable in three taps, and the send reported success while the message went
> to `PushInbox.rejections`. `asNotification` governs whether a notification
> block is rendered, not whether the payload carries text, so **title and body
> are required unconditionally.**

Rules: `title` and `body` must not be blank when `asNotification` is true; extra
data keys must not be blank; and **extra data keys must not collide with
`PushMessageParser.reservedKeys`**. That last rule is the concrete reason the
dependency on `core` exists — the reserved names stay defined in exactly one
place and the compiler enforces the agreement.

## `apps/fcm_functions`

One callable, split by responsibility. The `firebase_functions` builder scans
**every** `.dart` file in the package, not just `bin/server.dart`, so registration
does not have to be crammed into the entry point.

```
bin/server.dart                        main() → runFunctions(registerFunctions)
lib/register_functions.dart            onCallWithData + HttpsOptions
lib/send_notification_handler.dart     pure: Request → Response
lib/notification_message_builder.dart  Draft + token + id + sentAt → TokenMessage
lib/notification_sender.dart           interface over Messaging + admin impl
```

```dart
firebase.https.onCallWithData<SendNotificationRequest, SendNotificationResponse>(
  name: 'sendNotification',
  fromJson: SendNotificationRequest.fromJson,
  options: const HttpsOptions(maxInstances: Instances(3), timeoutSeconds: 30),
  (request, _) => handleSendNotification(
    request.data,
    sender: AdminNotificationSender(firebase.adminApp.messaging()),
  ),
);
```

The stamped `id` is `sandbox-<microsecondsSinceEpoch>` and `sentAt` is
`DateTime.now().toUtc()`. Both are generated **on the server**, so the value the
response reports and the value in the delivered payload cannot drift, and the
app has no clock authority over what it is about to receive.

`handleSendNotification` is an ordinary function taking a `NotificationSender`
and the `id`/`sentAt` generators as parameters. It depends on no `Firebase`
object, no `Request`, and no network, so it is unit-testable directly — no
emulator and no admin app. `NotificationSender` is the same seam as `PushSource`
in the app: an interface, a production implementation over `Messaging`, a fake in
the tests.

`NotificationMessageBuilder` is a pure translation of a draft into a
`TokenMessage`: `Notification(title, body)` only when `asNotification`, otherwise
data-only; the `data` map gets the four keys `PushMessageParser` requires (`id`,
`title`, `body`, `sentAt`) plus `event` and the user's extra keys;
`AndroidConfig(priority:)` from the draft, and `ApnsConfig` with
`Aps(contentAvailable: true)` when the message is silent so iOS wakes the app
instead of dropping it.

## `apps/fcm_app`

Today `FcmSampleApp` renders `InboxScreen`, which owns its own `Scaffold`. The
drawer needs a shell:

```
FcmSampleApp
└── AppShell (StatefulWidget)      owns the selected destination
    ├── Drawer → NavigationDrawer   [Inbox] [Sandbox]
    └── body: InboxView | SandboxView
```

`InboxScreen` becomes `InboxView` and loses its `Scaffold` and `AppBar`, which
the shell takes over. The single `AppBar` title follows the selected destination
("Push inbox" / "Sandbox"), so each destination is one body widget with no chrome
of its own. `inbox_screen_test.dart` moves with it — a small edit, not a rewrite.

`SandboxView`, top to bottom:

```
AppBar: Sandbox                                    ☰
────────────────────────────────────────────────────
Gallery   [Chat message] [Build finished] [Promo] [Silent sync]
────────────────────────────────────────────────────
Event      chat_message                           ▾
Title      ┌──────────────────────────────────┐
Body       ┌──────────────────────────────────┐
           ☑ Show as notification    (off = silent data-only)
Priority   ○ normal   ● high
Extra data key ┌────────┐ value ┌────────┐   ✕
           + add key/value
────────────────────────────────────────────────────
           [ Send to this device ]
────────────────────────────────────────────────────
✓ Sent · id sandbox-1754812… · appears in Inbox shortly
```

`SandboxController extends ChangeNotifier` holds the current draft, the
validator's problems, and the send state (idle / sending / sent / failed). It
takes two things: a `NotificationSender` and a `String? Function()` for the
token, which `main()` supplies as `() => inbox.token`. The sandbox therefore does
not know about `PushInbox` — it only asks for a token.

The app-side seam mirrors the push side:

```dart
abstract interface class NotificationSender {
  Future<SendNotificationResponse> send(SendNotificationRequest request);
}
```

`CallableNotificationSender` wraps
`FirebaseFunctions.instance.httpsCallable('sendNotification')`.
`UnavailableNotificationSender` always throws with the reason, and is used when
Firebase failed to start — exactly as `DisabledPushSource` is today. Widget tests
consequently never construct `cloud_functions`.

Dart functions deploy to Cloud Run. If the `cloudfunctions.net` alias does not
resolve for the deployed service, the fallback is
`FirebaseFunctions.instance.httpsCallableFromUrl(<run url>)` — same DTOs, one
line different. This is only relevant once a real deploy happens.

## Error handling

Five paths, each visible rather than swallowed:

1. **Firebase did not start** — `UnavailableNotificationSender`, Send disabled,
   reason shown in the existing setup banner.
2. **No registration token yet** — Send disabled with an explicit reason.
3. **Invalid draft** — shared validator, problems inline against their fields,
   Send disabled. The function revalidates and answers 400.
4. **The callable fails** (network, quota, unregistered token) — an error card
   with the code and message; the form keeps its contents so the send can be
   retried.
5. **The Admin SDK send fails** — `FirebaseMessagingAdminException` is mapped to
   a readable message. An unregistered token is the common case and gets its own
   wording rather than surfacing
   `messaging/registration-token-not-registered` raw.

Once the push is delivered, it follows the existing path, including the existing
handling for a malformed payload (`PushInbox.rejections`).

## Security posture

The callable is unauthenticated, because the app has no Firebase Auth. This is a
deliberate, bounded risk:

- The function only sends to the token supplied by the caller, so an attacker
  must already hold someone's registration token to bother them with it.
- `maxInstances: 3` and `timeoutSeconds: 30` cap the cost of abuse.

The production answer is **Firebase App Check** —
`firebase_functions` supports it (`lib/src/https/auth.dart`) — which is out of
scope here because it needs Play Integrity / DeviceCheck registration plus debug
providers for the emulator and tests. Anonymous Firebase Auth was rejected as
security theatre: anyone can mint an anonymous account.

## Tooling and Firebase configuration

- One-time, per machine: `firebase experiments:enable dartfunctions`. Recorded in
  the README.
- Root `firebase.json` gains
  `functions: { source: "apps/fcm_functions", runtime: "dart3", ignore: [".dart_tool", "build", "test"] }`
  and an `emulators` block.
- `apps/fcm_app/firebase.json`, written by `flutterfire configure`, **stays** —
  it is that tool's own record. The README must say that `firebase` is always run
  **from the repo root**, otherwise the CLI finds the app-level file, which has no
  `functions` block.
- **`dart` is not on `PATH`** on this machine — only fvm — and the CLI invokes it
  as `dart`. Every firebase command therefore goes through `fvm exec firebase …`.
  New melos scripts `functions:build`, `functions:serve` and `functions:deploy`
  record those incantations in one place, consistent with the existing
  `fvm exec dcm`.
- The generated `functions.yaml` is a build artifact at the package root and is
  gitignored.

## Risks

1. **`build_runner` inside a pub workspace.** The `firebase_functions` generator
   is a build_runner builder with `auto_apply: root_package`, and a workspace has
   a single `.dart_tool/package_config.json` at the root. This is verified as the
   **first implementation step**, as a throwaway spike on a copy of the repo,
   before anything is built on top of it. If it does not work, the design needs
   revisiting — a path dependency from outside the workspace into a
   `resolution: workspace` package is not a viable fallback.
   A related, harmless consequence: the CLI looks for
   `<source>/.dart_tool/package_config.json`, which never exists for a workspace
   member, so it re-runs `dart pub get` on every deploy.
2. **End-to-end through the emulator needs a service account key.** The emulator
   has no metadata server, so the Admin SDK has nothing to authenticate with. A
   JSON key must be downloaded and `GOOGLE_APPLICATION_CREDENTIALS` set; the file
   is gitignored.

## Testing

| Where | Runner | What |
| --- | --- | --- |
| `fcm_gallery_shared` | `dart test` | DTO JSON round-trips, `wireName` mapping including unknown values, every validator rule, gallery invariants (unique ids, every scenario's draft validates clean) |
| `fcm_functions` | `dart test` | `NotificationMessageBuilder` — payload keys, notification vs. silent, priority, APNs `contentAvailable`; `handleSendNotification` with a fake sender — happy path, 400 on an invalid draft, Admin SDK error mapping |
| `fcm_app` | `flutter test` | the drawer switches destination, a scenario prefills the form, validation blocks Send, Send hands the fake sender the expected `SendNotificationRequest`, the failure path renders |

`runFunctionsTest` from `firebase_functions/testing.dart` will be attempted as
well, but it requires an initialised admin `FirebaseApp`. If one cannot be
assembled in a test without credentials, it is dropped and the handler is tested
directly. It will not be claimed as working if it is not.

## Verification

To be verified before the work is called done:

- `melos run ci` green, now covering two more packages
- `build_runner` produces a `functions.yaml` containing the `sendNotification`
  endpoint
- `dart compile exe bin/server.dart --target-os=linux --target-arch=x64`
  succeeds — this is exactly what deploy does, so it is the evidence of
  deployability
- end-to-end against the Functions emulator on a real Android device: send from
  the Sandbox, the push arrives, and it appears in the Inbox with the same `id`
  the response returned

**`firebase deploy` will not be verified.** The Cloud Functions API is disabled
on `fcm-sandbox-770fa` (measured, not assumed), and Dart functions target Cloud
Run, which needs the Blaze plan. Deploy is documented as a step and labelled
unverified.

## Deliberately out of scope

- A Firestore history of sent notifications
- Scheduled or delayed sends
- Firebase App Check
- Topic targeting and arbitrary-token targeting
- `flutter_local_notifications` for foreground display
- iOS and Android release builds — this machine has neither Xcode nor the Android
  SDK
