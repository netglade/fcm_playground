# What this app does

A Flutter app that receives Firebase Cloud Messaging (FCM) pushes, plus a small
local server that sends them. You compose a push, send it to your own phone, and
watch exactly what the device does with it.

It is a learning tool, not a product. The point is that every question about
push notifications — "why didn't it show a banner?", "why is it silent?", "why
did the sound not change?" — becomes something you can try in under a minute.

Start with the [setup in the README](../README.md); this page is the tour.

## The six screens

| Screen | What it is for |
| --- | --- |
| **Inbox** | Every push the app has accepted, and this device's registration token. Tapping a message shows its raw payload. |
| **Scenarios** | A catalogue of 66 ready-made payloads, grouped A–K. Pick one and it loads into the Sandbox, or select several and send them as a batch. |
| **Sandbox** | The payload editor. Build any FCM message by hand, choose who receives it, send now or on a delay. |
| **Channels** | What the app asked Android for, next to what Android actually reports back. |
| **Runs** | Sends that were scheduled rather than sent immediately, and what became of each. |
| **Telemetry** | A timeline per push and a latency matrix — how long each one took to arrive. |

## What notifications you can build

### The four shapes of a payload

Every FCM message can carry a `notification` block, a `data` map, or both, and
that choice decides who draws the banner:

- **Notification only** — FCM's own SDK draws it. The app never sees it unless
  it is tapped.
- **Data only** — nothing but the app can draw it, because FCM has no block to
  draw from. This is the shape that lets the app add buttons.
- **Both** — what most production pushes look like.
- **Data with nothing to show** — a sync marker or a flag. Note that this still
  posts an *empty* banner rather than none.

Which of these arrives, and in which of the three app states (foreground,
backgrounded, killed), is the whole subject of
[notifications.md](./notifications.md).

### What you can put on a notification

The Sandbox exposes the full FCM v1 message, one form section per block:

- **Message** — the `data` map, and top-level `fcm_options`.
- **Notification** — the cross-platform `title`, `body`, `image`.
- **Android** — `collapse_key`, `priority`, `ttl`, `restricted_package_name`,
  `direct_boot_ok`, plus the whole `android.notification` block: `channel_id`,
  icon, colour, sound, tag, click action, the title and body localisation keys
  and their args, ticker, sticky, event time, local-only, notification priority,
  the three `default_*` flags, vibrate timings, visibility, notification count
  (the badge), light settings, image, and the two proxy fields.
- **APNS** — headers and the `aps` payload, for iOS.
- **Webpush** — headers, data and notification, for browsers.

Anything in the catalogue can be edited before you send it. There is no way to
save a hand-built payload back as a scenario — the catalogue is compile-time
Dart in `packages/fcm_gallery_shared`, so adding one means adding code.

Of the 66 scenarios, **42 work with nothing extra** and **11 more work but need
one step on the device** (an `adb` command or a settings toggle, spelled out on
the card). The remaining 13 are marked "needs work" in the app: six wait on
notification styles the app cannot render yet, three on a token registry, one on
badge support, two on an Apple entitlement or an OS permission outside this
project, and one on native code this project deliberately will not add.

### The extras this app adds on top of FCM

Some things FCM has no field for, so this project puts them in `data` and the
client builds them. These are conventions of this app, not part of FCM:

| `data` key | What it does |
| --- | --- |
| `actions` | Up to three buttons, as `id:Label\|id2:Label2`. Android shows a fourth only by overflowing. |
| `actions` with `:input` | Marks one action as inline reply — see below. |
| `deep_link` | Names a screen, so a tap routes straight there instead of to the message's detail page. |
| `ongoing` | `true` makes the notification resist being swiped away. |
| `group` | Groups notifications under a summary row that counts its members. |
| `full_screen` | `true` asks to take over the screen, which Android 14+ may refuse. |
| `category` | The Android notification category, e.g. `alarm` or `message`. |

**Inline reply** is the most interesting of these: pressing a `:input` action
opens a text field in the notification shade and never opens the app. A
background isolate saves the typed text and redraws the notification in place,
and the app only sees the reply the next time it is opened.

The rest of what you can control is real FCM, not a convention:

- **Notification channels** — eleven of them, covering the four importance
  levels, a custom sound, a vibration pattern, a Do Not Disturb bypass, the
  alarm audio stream, and two chat channels in a shared group. A payload picks
  one with `android.notification.channel_id`. On Android 8+ the *channel*
  decides sound and importance, not the payload — the single most common
  surprise in Android notifications. See
  ["Which channel it lands on"](./notifications.md#which-channel-it-lands-on).

### Sending later, so you can watch the app die first

Some behaviour only appears when the app is not running. The Sandbox can
schedule a send for N seconds from now and show a countdown, so you can swipe
the app away and still see what arrives. Those sends appear on the Runs screen
with their outcome.

## How the Firebase connection has to work

**This is the part people get wrong, so it is worth being explicit: there are
two completely separate credentials, one for receiving and one for sending.**

### Receiving — the app's client config

The app needs to identify itself to FCM so it can be given a token.

- `apps/fcm_app/lib/firebase_options.dart` holds the API key, app id, sender id
  and project id. It is generated by `flutterfire configure`.
- On Android, `android/app/google-services.json` is also generated, and the
  Gradle plugin reads it at build time.

This repo ships **placeholders**, not a real project. Until you run
`flutterfire configure` with a project of your own, the app still starts and
shows a banner explaining what is missing — it never crashes. That fallback is
deliberate and is the pattern [architecture.md](./architecture.md) is built
around.

### Sending — the server's service account

A client app cannot send pushes. Only a trusted server can, and it authenticates
completely differently:

- `apps/fcm_api` reads a **service-account key** from
  `GOOGLE_APPLICATION_CREDENTIALS` (Firebase console → Project settings →
  Service accounts → Generate new private key).
- It exchanges that for an OAuth2 bearer token, scope
  `https://www.googleapis.com/auth/firebase.messaging`, and posts to
  `https://fcm.googleapis.com/v1/projects/<projectId>/messages:send`.

So a working setup means **both halves point at the same Firebase project**. If
the app is configured for project A and the service account belongs to project
B, sends fail with `SENDER_ID_MISMATCH` — a genuinely confusing error whose real
cause is two mismatched credentials.

The API is a development tool: no authentication, bound to loopback only. To
reach it from a physical Android device rather than an emulator, use
`adb reverse tcp:8080 tcp:8080`.

## How tokens work

A **registration token** is FCM's address for one install of one app on one
device. Sending a push means naming a token.

- The app asks for one with `getToken()` after notification permission is
  granted, and shows it on the **Inbox** screen. That is where you copy it from.
- The token is per install, not per user and not per device. Reinstalling the
  app, clearing its data, or restoring to a new phone all produce a new one.
- FCM can also rotate a token on its own.
- Sending to a token that is no longer valid fails with **`UNREGISTERED`**. That
  is the correct answer, not a bug — it is how a server learns to stop sending
  and delete its copy. Scenarios `k2_invalid_token` and `b6_token_refresh` are
  exactly this.

### Choosing who receives a send

The Sandbox's "Send to" picker offers:

- **This device** — uses the token the app just read. The default, and the only
  option that needs no extra setup.
- **Token** — any token you paste in, so you can send from one phone to another.
- **Topic** — every device subscribed to a named topic.
- **Condition** — a boolean expression over topics, e.g.
  `'news' in topics && 'beta' in topics`.
- **All devices** — refused on purpose. FCM has no such audience, and honouring
  it would need a registry of every token, which this API does not keep.

### Two honest limits

- **The app never subscribes to a topic.** You can send to a topic and the API
  will accept it, but nothing will arrive here, because nothing calls
  `subscribeToTopic`. This is why the catalogue's group J is marked blocked.
- **The app does not listen for token rotation.** It reads the token once at
  startup; it has no `onTokenRefresh` subscription. If a token rotates while the
  app is running, the value on the Inbox screen is stale until the next launch. A
  production app would listen and send the new token to its server.

## Where to read next

- [notifications.md](./notifications.md) — what a push actually does: the four
  shapes against the three app states
- [scenarios.md](./scenarios.md) — the catalogue and how to drive it
- [architecture.md](./architecture.md) — how the code is laid out, and why
- [telemetry.md](./telemetry.md) — what gets measured, and how latency is worked
  out
- [localization.md](./localization.md) — how a string gets from the CSV into the
  app
