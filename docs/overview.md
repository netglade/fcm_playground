# What this app does

A Flutter app that receives Firebase Cloud Messaging (FCM) pushes, plus a small
local server that sends them. Compose a push, send it to your own phone, and
watch what the device actually does with it.

A learning tool, not a product. Every question about push notifications — why no
banner appeared, why it was silent, why the sound never changed — becomes
something you can try in a minute.

Setup is in the [README](../README.md); this page is the tour.

## The six screens

| Screen | What it is for |
| --- | --- |
| **Inbox** | Every push the app accepted, and this device's registration token. |
| **Scenarios** | 66 ready-made payloads, grouped A–K. Load one into the Sandbox, or send several as a batch. |
| **Sandbox** | The payload editor: build any FCM message, choose who gets it, send now or on a delay. |
| **Channels** | What the app asked Android for, beside what Android reports back. |
| **Runs** | Scheduled sends, and what became of each. |
| **Telemetry** | A timeline per push, and how long each took to arrive. |

Of the 66 scenarios, 42 work as-is and 11 more need one step on the device (an
`adb` command or a settings toggle, spelled out on the card). The other 13 are
marked "needs work" — mostly notification styles the app cannot render yet.

## What notifications you can build

Every FCM message carries a `notification` block, a `data` map, or both, and
that choice decides who draws the banner:

- **Notification only** — FCM's SDK draws it. The app never sees it unless tapped.
- **Data only** — only the app can draw it, since FCM has no block to draw from.
  This is the shape that allows buttons.
- **Both** — what most production pushes look like.
- **Data with nothing to show** — a sync marker. Still posts an *empty* banner,
  not none.

The Sandbox exposes the whole FCM v1 message, a form section per block: `data`
and `fcm_options`; the cross-platform `notification`; the full Android block
(`collapse_key`, `priority`, `ttl`, `direct_boot_ok` and the ~25 fields of
`android.notification`); APNS for iOS; Webpush for browsers.

Scenarios can be edited before sending, but not saved back — the catalogue is
compile-time Dart in `packages/fcm_gallery_shared`.

### Extras this app adds

FCM has no field for these, so they ride in `data` as conventions of this app:

| `data` key | What it does |
| --- | --- |
| `actions` | Up to three buttons, as `id:Label\|id2:Label2`. |
| `actions` with `:input` | Inline reply: opens a text field in the shade and never opens the app. A background isolate saves the text and redraws the notification in place. |
| `deep_link` | Routes a tap straight to a screen. |
| `ongoing` | Resists being swiped away. |
| `group` | Groups notifications under a counting summary row. |
| `full_screen` | Asks to take over the screen; Android 14+ may refuse. |
| `category` | The Android category, e.g. `alarm`. |

**Notification channels** are real FCM, and the biggest trap: eleven are
registered, a payload picks one with `android.notification.channel_id`, and from
Android 8 the *channel* decides sound and importance — not the payload. Setting
`sound` in the payload changes nothing and reports no error. See
["Which channel it lands on"](./notifications.md#which-channel-it-lands-on).

## How it behaves in the app's three states

Who draws the banner depends on the payload shape *and* what the app is doing:

| Shape | Foreground | Backgrounded | Killed |
| --- | --- | --- | --- |
| Notification only | App | System | System |
| Data only | App | App | App |
| Both | App | System | System |
| Data, nothing to show | App | App | App |

- **Foreground is always the app.** Android draws nothing itself for a push
  arriving while the app is on screen, so the app draws every one.
- **A payload with no `data` never wakes the app** while backgrounded or killed.
  FCM does not start the app for a bare `notification` block, so such a push is
  seen only by the system tray until someone taps it.
- **Backgrounded and killed draw identically.** They differ in what a *tap* can
  deliver, not in who draws.
- **A tap arrives by a different route depending on who drew.** A banner the app
  drew reports through the notification plugin; one the system drew reports
  through FCM's own delivery.
- **Killed is where it stops being symmetric.** A tap that starts the process is
  the only kind a dead app can receive, and it can arrive before the message it
  names has finished being stored — so the app holds the tap and resolves it once
  the payload turns up.

Some behaviour only shows with the app dead, so the Sandbox can schedule a send
N seconds out and show a countdown: swipe the app away, then watch what arrives.

Full detail, including the iOS caveats, is in
[notifications.md](./notifications.md).

## How the Firebase connection has to work

**Two completely separate credentials, one for receiving and one for sending.**
This is the part people get wrong.

**Receiving** — the app identifies itself with
`apps/fcm_app/lib/firebase_options.dart` (API key, app id, sender id, project
id) plus `android/app/google-services.json`. Both come from
`flutterfire configure`.

This repo ships **placeholders**. Until you configure a project of your own the
app still starts and shows a banner saying what is missing — it never crashes.

**Sending** — a client app cannot send pushes; only a trusted server can.
`apps/fcm_api` reads a **service-account key** from
`GOOGLE_APPLICATION_CREDENTIALS` (Firebase console → Project settings → Service
accounts), exchanges it for an OAuth2 bearer with scope `firebase.messaging`,
and posts to `fcm.googleapis.com/v1/projects/<projectId>/messages:send`.

Both halves must point at the **same project**. An app on project A with a
service account from project B fails as `SENDER_ID_MISMATCH` — a confusing error
whose real cause is mismatched credentials.

The API is a dev tool: no auth, loopback only. From a physical device use
`adb reverse tcp:8080 tcp:8080`.

## How tokens work

A **registration token** is FCM's address for one install of one app on one
device. Sending means naming a token.

- The app reads it with `getToken()` and shows it on **Inbox** — copy it there.
- It is per install: reinstalling, clearing data or restoring to a new phone all
  produce a new one, and FCM can rotate it on its own.
- Sending to a dead token fails with **`UNREGISTERED`**. That is correct, not a
  bug — it is how a server learns to stop sending. See `k2_invalid_token` and
  `b6_token_refresh`.

"Send to" offers **this device** (the default), **token** (paste another
phone's), **topic**, **condition** (e.g. `'news' in topics && 'beta' in topics`)
and **all devices**, which is refused on purpose — FCM has no such audience, and
honouring it would need a token registry this API does not keep.

**Two limits worth knowing.** The app never calls `subscribeToTopic`, so a topic
send is accepted and arrives nowhere — that is why group J is blocked. And it
never subscribes to `onTokenRefresh`, reading the token once at startup, so a
rotated token stays stale on screen until the next launch. A production app
would listen and push the new token to its server.

## Where to read next

[notifications.md](./notifications.md) for delivery in depth ·
[scenarios.md](./scenarios.md) for the catalogue ·
[architecture.md](./architecture.md) for the code layout ·
[telemetry.md](./telemetry.md) for the measurements ·
[localization.md](./localization.md) for the CSV pipeline
