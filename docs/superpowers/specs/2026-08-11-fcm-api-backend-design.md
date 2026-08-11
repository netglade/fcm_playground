# Simple send API, shared contract, and Sandbox page — design

**Date:** 2026-08-11
**Status:** designed, not implemented
**Supersedes:** `2026-08-10-fcm-notification-sandbox-design.md` and its plan
`../plans/2026-08-10-fcm-notification-sandbox.md`

## Goal

A **standalone HTTP backend** with one endpoint that sends a push through FCM, a
**shared package** holding the contract both sides speak, and a **Sandbox page**
in `fcm_app` that composes a notification and sends it to the device it is
running on.

The point is the closed loop with one shared contract: what the app composes,
the server sends, and the existing inbox receives — with a compiler-enforced
agreement in the middle.

This replaces the Cloud Functions approach of the superseded design. A plain
Dart server needs no `build_runner` spike, no `dartfunctions` CLI experiment, no
Blaze plan and no deploy story to run end to end on this machine.

## Decisions

| Decision | Choice | Why |
| --- | --- | --- |
| Backend form | Standalone `shelf` server at `apps/fcm_api/` | `apps/` holds deployables. A process you can `dart run` and `curl` has far fewer moving parts than a Cloud Function, and every prerequisite is already installed. |
| Language | Dart | Same toolchain as the rest of the repo, and the only way the contract can be *shared* rather than transcribed. |
| FCM access | `googleapis_auth` + FCM HTTP v1 REST | Google-published package mints the OAuth2 token from a service-account JSON; we POST the message ourselves. Two dependencies, and the payload is visible in our own code instead of behind a wrapper. |
| Package boundary | `fcm_gallery_shared` **depends on** `core` | Additive — `core` keeps the wire contract, shared adds drafts, scenarios, DTOs and validation. No refactor of existing code. |
| Payload surface | `token`, `title`, `body`, `data` | Enough to exercise the whole loop. Silent pushes and priority control are out of scope. |
| `NotificationEvent` | **No enum.** An event is just a data key | With a free-form `data` map, `{'event': 'chat_message'}` is already expressible. An enum would add a type, a wire-name mapping and its tests for no behaviour the presets do not already give. |
| Server-stamped fields | `id` and `sentAt` generated on the server | The response and the delivered payload cannot drift, and the app has no clock authority over what it is about to receive. |
| Target | The token the caller supplies | The app sends its own registration token, so the loop closes on the calling device. No UI selector. |
| Auth and binding | None, `127.0.0.1` only | A local dev tool. See "Security posture". |

## Architecture

```
packages/core (pure Dart, unchanged)
  PushMessage, PushMessageParser, PushMessageFormatException
        ↑
packages/fcm_gallery_shared (pure Dart)
  NotificationDraft            the editable payload
  NotificationScenario         gallery preset + notificationGallery catalogue
  SendNotificationRequest      endpoint input DTO
  SendNotificationResponse     endpoint output DTO
  ApiError                     the server's error body
  NotificationDraftValidator   one validation, used by both sides
        ↑                              ↑
apps/fcm_app                   apps/fcm_api
  AppShell + Drawer              ApiRouter (POST /send, GET /health)
  ├── InboxView                  sendNotification (pure)
  └── SandboxView                NotificationMessage (pure)
  SandboxController              FcmSender (interface)
  NotificationSender (iface)     └── HttpV1FcmSender
  ├── HttpNotificationSender
  └── UnavailableNotificationSender
```

Data flow: `SandboxView` edits a `NotificationDraft` → `SandboxController`
validates it and wraps it with the device token into a
`SendNotificationRequest` → `POST /send` → the server revalidates, stamps `id`
and `sentAt`, `NotificationMessage` turns it into an FCM HTTP v1 message →
`HttpV1FcmSender` posts it → FCM delivers → the existing `FirebasePushSource` →
`PushMessageParser` → `PushInbox` → `InboxView`. The `payloadId` in the response
is the `id` the user then sees in the inbox, so the round trip is visible rather
than inferred.

## Repository layout

```
.
├── apps/fcm_api/                     NEW — Dart shelf server
│   ├── pubspec.yaml                  resolution: workspace
│   ├── analysis_options.yaml
│   ├── bin/server.dart
│   ├── lib/
│   └── test/
├── apps/fcm_app/                     drawer + Inbox + Sandbox
├── packages/core/                    unchanged
├── packages/fcm_gallery_shared/      NEW — pure Dart
└── pubspec.yaml                      workspace: gains two members
```

Both new packages are pub workspace members, so `melos analyze`, `melos dcm`
and `melos test:core` (filter `flutter: false` + `dirExists: test`) pick them up
with no change to the scripts.

## `packages/fcm_gallery_shared`

### `NotificationDraft`

The value the form edits and the request carries:

| Field | Type | Meaning |
| --- | --- | --- |
| `title` | `String` | Notification title and the `title` data key |
| `body` | `String` | Notification body and the `body` data key |
| `data` | `Map<String, String>` | Extra data keys, passed through untouched |

Immutable, with `copyWith`, `toJson` and `fromJson`.

### `NotificationScenario`

`id`, `label`, `description`, `draft`. A `const notificationGallery` list holds
the presets. Tapping one replaces the form contents with its draft; everything
stays editable afterwards.

The four scenarios cover different axes rather than four flavours of the same
thing:

| id | Extra data | Point |
| --- | --- | --- |
| `chatMessage` | `event`, `deepLink` | The routing case — a key the app would act on |
| `buildFinished` | `event`, `buildNumber` | Matches the payload example in the root README |
| `promo` | `event`, `campaign` | Two unrelated extra keys |
| `plainText` | none | The `data`-less path, so an empty map is exercised |

### `SendNotificationRequest` / `SendNotificationResponse`

```dart
class SendNotificationRequest {
  final String token;             // the caller's own device
  final NotificationDraft draft;
}
```

It serialises **flat**, so the DTO is literally the endpoint's body rather than a
wrapper around it:

```json
{ "token": "e…", "title": "Build finished", "body": "main #128 passed",
  "data": { "event": "build_finished", "buildNumber": "128" } }
```

`data` is optional on the wire and absent means empty.

```dart
class SendNotificationResponse {
  final String messageId;         // FCM message name, e.g. projects/…/messages/0:17…
  final String payloadId;         // the `id` data key; matches PushMessage.id
  final DateTime sentAt;
}
```

```json
{ "messageId": "projects/fcm-sandbox-770fa/messages/0:1754812345678901%…",
  "id": "api-1754812345678901",
  "sentAt": "2026-08-11T09:12:03.123Z" }
```

The response key is `id` while the Dart field is `payloadId`: on the wire it is
the payload's `id`, in Dart the name has to say *which* id it is next to
`messageId`.

### `ApiError`

`message` plus an optional `field`. The server's error body for every non-2xx
answer, so the app parses failures with the same type the server produced them
with instead of guessing at a shape.

### `NotificationDraftValidator`

One validator, both sides. `validate(NotificationDraft) → List<DraftProblem>`,
where a `DraftProblem` names the offending field and says what is wrong. The app
renders them inline and disables Send; the server runs the same validator and
answers 400 if it finds anything, so the app is not the only line of defence.

Rules:

1. `title` must not be blank.
2. `body` must not be blank.
3. No data key may be blank.
4. No data key may repeat — the form holds a list of rows, so duplicates are
   reachable through the UI even though a `Map` cannot hold them. The validator
   therefore takes the rows' keys as given and reports the collision rather than
   silently keeping the last one.
5. **No data key may collide with `PushMessageParser.reservedKeys`.** This is
   the concrete reason the dependency on `core` exists — the reserved names stay
   defined in exactly one place and the compiler enforces the agreement.

Rule 4 needs the duplicate keys to still exist when `validate` runs, which a
`Map<String, String>` cannot represent. `SandboxController` therefore validates
its editor rows before collapsing them into the draft's map, and the validator
exposes a second entry point for that: `validateEntries(title, body,
List<MapEntry<String, String>>)`, with `validate(draft)` implemented on top of
it. The server only ever has a `Map` — a duplicate key cannot survive JSON
decoding — so it calls `validate` and rule 4 is vacuous there.

## `apps/fcm_api`

```
bin/server.dart                    env → dependencies → serve on 127.0.0.1
lib/fcm_api.dart                   barrel
lib/src/api_router.dart            shelf Router; JSON in, JSON out, status mapping
lib/src/send_notification.dart     pure: SendNotificationRequest → SendNotificationResponse
lib/src/notification_message.dart  pure: draft + token + id + sentAt → v1 message map
lib/src/fcm_sender.dart            interface over FCM
lib/src/http_v1_fcm_sender.dart    googleapis_auth + http implementation
```

### The FCM HTTP v1 message

`NotificationMessage` is a pure translation of a draft into the map that goes to
`https://fcm.googleapis.com/v1/projects/<projectId>/messages:send`:

```json
{ "message": {
    "token": "e…",
    "notification": { "title": "Build finished", "body": "main #128 passed" },
    "android": { "priority": "high" },
    "data": { "id": "api-1754812345678901",
              "title": "Build finished",
              "body": "main #128 passed",
              "sentAt": "2026-08-11T09:12:03.123Z",
              "event": "build_finished",
              "buildNumber": "128" } } }
```

`title` and `body` appear twice on purpose. The `notification` block is what the
OS renders when the app is backgrounded; the `data` copies are what
`PushMessageParser` reads, and it requires all four of `id`, `title`, `body` and
`sentAt` to be present in `data`. Every `data` value is a `String`, which FCM
requires.

`android.priority: high` is fixed rather than configurable — the point of the
sandbox is prompt delivery while you watch.

### Server-stamped fields

`id` is `api-<microsecondsSinceEpoch>` and `sentAt` is
`DateTime.now().toUtc()`. Both are generated on the server. `sendNotification`
takes them as injected generators (`String Function()` and `DateTime
Function()`) so its tests assert exact values instead of matching patterns.

### Seams

`sendNotification` is an ordinary function taking an `FcmSender`, the two
generators, and the request. It depends on no `Request`, no credentials and no
socket, so it is unit-testable directly. `FcmSender` is the same seam as
`PushSource` in the app: an interface, one implementation over HTTP v1, a fake in
the tests.

```dart
abstract interface class FcmSender {
  /// Returns the FCM message name, or throws [FcmSendException].
  Future<String> send(Map<String, Object?> message);
}
```

DCM's `prefer-match-file-name` wants a file named after its first public type, so
every exception gets its own file: `lib/src/fcm_send_exception.dart` here,
`DraftProblem` in `packages/fcm_gallery_shared/lib/src/draft_problem.dart`, and
`NotificationSendException` in
`apps/fcm_app/lib/sandbox/notification_send_exception.dart`.
`send_notification.dart` declares a function rather than a type and so has no
name to match.

`HttpV1FcmSender` holds an `AutoRefreshingAuthClient` from
`clientViaServiceAccount`, scoped to
`https://www.googleapis.com/auth/firebase.messaging`, so token refresh is the
package's problem and not ours. A non-2xx answer becomes an `FcmSendException`
carrying FCM's own `status` string and message.

### Configuration

Read from the environment once at startup, and the server refuses to start if
anything is missing or unreadable — a missing credential must not become a
runtime 500 on the first send.

| Variable | Required | Meaning |
| --- | --- | --- |
| `GOOGLE_APPLICATION_CREDENTIALS` | yes | Path to the service-account JSON |
| `FCM_PROJECT_ID` | no | Defaults to `project_id` from that JSON |
| `PORT` | no | Defaults to `8080` |

The service-account JSON is gitignored. A new `melos api:serve` script records
the `fvm dart run` incantation, consistent with the existing `fvm exec dcm`.

## `apps/fcm_app`

Today `FcmSampleApp` renders `InboxScreen`, which owns its own `Scaffold`. The
drawer needs a shell:

```
FcmSampleApp
└── AppShell (StatefulWidget)       owns the selected destination
    ├── Drawer → NavigationDrawer    [Inbox] [Sandbox]
    └── body: InboxView | SandboxView
```

`InboxScreen` becomes `InboxView` and loses its `Scaffold` and `AppBar`, which
the shell takes over. The single `AppBar` title follows the selected destination
("Push inbox" / "Sandbox"), so each destination is one body widget with no
chrome of its own. `inbox_screen_test.dart` moves with it — a small edit, not a
rewrite. Inbox is the destination selected on launch, so the app opens exactly
where it does today.

`SandboxView`, top to bottom:

```
AppBar: Sandbox                                    ☰
────────────────────────────────────────────────────
Presets   [Chat message] [Build finished] [Promo] [Plain text]
────────────────────────────────────────────────────
Title      ┌──────────────────────────────────┐
Body       ┌──────────────────────────────────┐
────────────────────────────────────────────────────
Extra data     key ┌────────┐  value ┌────────┐   ✕
               key ┌────────┐  value ┌────────┐   ✕
           + add key/value
────────────────────────────────────────────────────
           [ Send to this device ]
────────────────────────────────────────────────────
✓ Sent · id api-1754812… · appears in Inbox shortly
```

`SandboxController extends ChangeNotifier` holds the title, the body, the list of
data rows, the validator's problems, and the send state (idle / sending / sent /
failed). It takes two things: a `NotificationSender` and a `String? Function()`
for the token, which `main()` supplies as `() => inbox.token`. The sandbox
therefore does not know about `PushInbox` — it only asks for a token.

`main()` constructs the controller alongside the inbox and passes both into
`FcmSampleApp`, which hands each to its view. That mirrors how `inbox` is
threaded today, and it is what lets a widget test build the whole app around a
fake sender.

The rows are a `List<MapEntry<String, String>>` rather than a `Map`, because a
map cannot hold the half-finished state of a form: two blank keys, or a
duplicate the user is mid-way through fixing. They collapse into the draft's map
only once validation has passed.

The app-side seam mirrors the push side:

```dart
abstract interface class NotificationSender {
  Future<SendNotificationResponse> send(SendNotificationRequest request);
}
```

`HttpNotificationSender` POSTs to `<baseUrl>/send` with `package:http` and turns
a non-2xx answer into a `NotificationSendException` carrying the parsed
`ApiError`. `UnavailableNotificationSender` always throws with the reason, and is
used when Firebase failed to start — exactly as `DisabledPushSource` is today.
Widget tests consequently never construct an HTTP client.

The base URL comes from `--dart-define=FCM_API_BASE_URL`, read with
`String.fromEnvironment`, defaulting to `http://localhost:8080`. The README
records the two things that make that default work: `adb reverse tcp:8080
tcp:8080` for a physical device, and `10.0.2.2` in place of `localhost` for the
Android emulator.

Widgets are split per file to satisfy DCM's `prefer-single-widget-per-file` and
`avoid-returning-widgets`: `sandbox_view.dart`, `scenario_picker.dart`,
`data_entry_row.dart`, `send_result_card.dart`.

## Error handling

Six paths, each visible rather than swallowed:

1. **Firebase did not start** — `UnavailableNotificationSender`, Send disabled,
   reason shown in the existing setup banner.
2. **No registration token yet** — Send disabled with an explicit reason.
3. **Invalid draft** — shared validator, problems inline against their fields,
   Send disabled. The server revalidates and answers 400 with the first
   problem's field and message.
4. **Malformed request body** — a body that is not a JSON object, or a `data`
   value that is not a string, answers 400. This is not reachable from the app,
   only from `curl`.
5. **FCM rejects the send** — `UNREGISTERED` becomes 404 with wording of its own
   rather than the raw `UNREGISTERED`, since a stale token is the common case;
   `INVALID_ARGUMENT` becomes 400; anything else becomes 502 carrying FCM's
   status. The app shows the message in an error card and **keeps the form
   contents**, so the send can be retried.
6. **The app cannot reach the server at all** — a `SocketException` renders as an
   error card naming the base URL, because the usual cause is a forgotten `adb
   reverse` rather than a broken server.

Once the push is delivered it follows the existing path, including the existing
handling for a malformed payload (`PushInbox.rejections`).

## Security posture

The endpoint is unauthenticated and binds `127.0.0.1`, so it is reachable only
from the machine it runs on. It is a development tool, and the README says so
in those words. Two consequences worth stating plainly:

- Anyone who can run code on that machine can send a push to any device token
  they already hold. They must already hold one — the server has no token
  registry to enumerate.
- **It must not be deployed as-is.** Binding `0.0.0.0` would expose an open
  relay to whatever network it sits on. Exposing it beyond localhost requires
  authentication first; a shared-secret header is the smallest sufficient
  answer, and is deliberately not built now.

The service-account key grants send rights on the whole Firebase project, so it
stays out of git.

## Testing

| Where | Runner | What |
| --- | --- | --- |
| `fcm_gallery_shared` | `dart test` | DTO JSON round-trips including absent `data`; every validator rule, with the reserved-key collision and the duplicate key called out individually; gallery invariants (unique ids, every preset validates clean) |
| `fcm_api` | `dart test` | `NotificationMessage` — the v1 map key by key, both `data` copies present, empty `data` case; `sendNotification` with a fake sender and fixed generators — happy path, 400 on an invalid draft, each `FcmSendException` mapping; `ApiRouter` — status codes and error bodies for every row of the table above, driven by `shelf.Request` objects with no socket |
| `fcm_app` | `flutter test` | the drawer switches destination; a preset prefills the form; validation blocks Send and renders problems; Send hands the fake sender the expected `SendNotificationRequest`; the failure path renders and the form keeps its contents |

## Verification

To be verified before the work is called done:

- `melos run ci` green, now covering two more packages
- `GET /health` answers 200 with the server running
- `POST /send` with a **bogus** token answers the mapped 404. This is the
  evidence that OAuth against FCM actually worked: an invalid token cannot
  produce `UNREGISTERED` unless the request carried a valid access token, so one
  `curl` proves the credential path end to end without needing a device.
- end-to-end on a real Android device: send from the Sandbox, the push arrives,
  and it appears in the Inbox with the same `id` the response returned

If no device is available for the last item, it will be reported as unverified
rather than claimed.

## Deliberately out of scope

- Silent (data-only) pushes and configurable priority
- Authentication on the endpoint, and any non-localhost binding
- Deploying the server anywhere
- Topic targeting and arbitrary-token targeting from the UI
- A history of sent notifications
- Scheduled or delayed sends
- `flutter_local_notifications` for foreground display
- iOS and Android release builds — this machine has neither Xcode nor the
  Android SDK
