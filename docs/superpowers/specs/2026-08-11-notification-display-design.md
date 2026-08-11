# Notifications on top of the inbox — design

**Date:** 2026-08-11
**Status:** designed, not implemented
**Branch:** `feature/notification-display`
**Builds on:** `2026-08-11-fcm-api-backend-design.md` (implemented on `main`)

## Goal

Make a received push behave like a notification, not only an inbox row: a banner
while the app is in use, a heads-up tray entry while it is away, an inbox that
survives a restart, and a tap that lands on a **message detail page**.

## What already worked before this

Worth recording, because one of the four gaps turned out not to be a gap.

`apps/fcm_api` already sends a `notification` block alongside the `data` keys, so
while the app is **backgrounded or terminated on Android, FCM's own SDK draws the
tray entry with no app code involved**. That needed nothing. What was missing:

| Gap | Behaviour before this change |
| --- | --- |
| Foreground | `onMessage` fires, the row appears in the inbox, no banner is shown |
| Notification tap | `onMessageOpenedApp` unhandled — tapping while backgrounded raised the app and dropped the payload. A cold-start tap did work, via `getInitialMessage` |
| Background → inbox | `_onBackgroundMessage` only `debugPrint`s, and the inbox is in-memory, so an untapped background push left no trace |
| Heads-up | No channel declared, so a tray entry could land silently |

## Decisions

| Decision | Choice | Why |
| --- | --- | --- |
| Inbox durability | Persist everything, capped at 100 newest | Catching background arrivals needs disk anyway. A queue-only hand-off would keep background messages across a restart but lose foreground ones — an asymmetry with no defensible explanation. |
| Store shape | **Two keys**, one per writer | The UI isolate owns the inbox key; the background isolate only appends to the pending key. Neither read-modify-writes the other's, so a push arriving mid-write cannot be lost. |
| On-disk format | **Raw flat payload maps**, not parsed `PushMessage`s | One format on disk and one parse path: `PushMessageParser` stays the only validator, and its `rejections` counter keeps working for restored payloads. It also means `packages/core` needs **no change**. |
| Re-notifying | Only live-stream messages notify | Restored and drained payloads were already shown by FCM while the app was away. Re-notifying on launch would replay every old notification at once. |
| Background isolate | Persists, shows nothing | FCM already drew the tray entry; posting again would double it. |
| Tap destination | A message detail page | Gives the tap somewhere meaningful to land, and doubles as the inbox row's detail view. |
| iOS | Included, unverified | `setForegroundNotificationPresentationOptions` is one line. This machine has no Xcode, so it is committed and labelled unverified rather than omitted. |
| Payload flattening | Extracted to a shared top-level function | Both isolates need it; duplicating it would let the two paths drift. |

## Architecture

```
packages/core (unchanged)
  PushMessage, PushMessageParser, PushMessageFormatException
        ↑
apps/fcm_app
  main()
   ├── remoteMessageToPayload()          shared by both isolates
   ├── PushPayloadStore (interface)
   │    ├── SharedPreferencesPushPayloadStore
   │    └── FakePushPayloadStore (tests)
   ├── NotificationPresenter (interface)
   │    ├── LocalNotificationPresenter   flutter_local_notifications
   │    └── SilentNotificationPresenter  tests, and the failure path
   ├── PushSource (interface, gains `taps`)
   │    ├── FirebasePushSource           onMessage + onMessageOpenedApp
   │    └── DisabledPushSource
   └── PushInbox                         restore / drainPending / requestOpen
        ↑
   AppShell ──push──▶ MessageDetailPage
   └── InboxView ──tap──▶ MessageDetailPage
```

`packages/fcm_gallery_shared` and `apps/fcm_api` are untouched.

## The store

```dart
abstract interface class PushPayloadStore {
  /// Payloads kept from earlier sessions, newest first.
  Future<List<Map<String, Object?>>> loadInbox();

  /// Replaces the kept payloads. The caller has already applied the cap.
  Future<void> saveInbox(List<Map<String, Object?>> payloads);

  /// Appends one payload. Called **only** from the background isolate.
  Future<void> appendPending(Map<String, Object?> payload);

  /// Returns the pending payloads and clears them in one step.
  Future<List<Map<String, Object?>>> takePending();
}
```

`SharedPreferencesPushPayloadStore` stores each list as a `List<String>` of JSON
objects under two keys, `push_inbox` and `push_pending`. `takePending` reads then
removes, so a payload cannot be drained twice.

`FakePushPayloadStore` is an in-memory implementation used by every test, so no
test touches platform channels.

**The cap is 100, newest first, applied by `PushInbox` before `saveInbox`.** It
exists so a long-lived install cannot grow the stored list without bound; 100 is
far more than the sample needs and small enough to decode instantly.

## `PushInbox` changes

Today `PushInbox` owns parsing, ordering and de-duplication of a live stream. It
gains persistence and one navigation hook, and keeps everything else.

| Member | Behaviour |
| --- | --- |
| `restore()` | `loadInbox()`, then `takePending()`, parse both through the existing `_onPayload` path, de-duplicate by id, cap, `saveInbox()`. Called once from `main()` before `runApp`. |
| `drainPending()` | `takePending()` and merge. Called again whenever the app resumes, because a push arriving while merely backgrounded would otherwise sit unseen until a restart. |
| `requestOpen(String id)` | Resolves the id against `messages` and exposes the match as `pendingOpen`, then notifies. |
| `pendingOpen` | The `PushMessage?` the shell should navigate to, or null. |
| `clearPendingOpen()` | Called by the shell once it has navigated. |

De-duplication already exists — `_seenIds` — so a payload that is both stored and
re-delivered appears once. Restoring re-runs validation, which is deterministic:
a payload accepted last session is accepted again.

**Live messages notify; restored and drained ones do not.** `_onPayload` gains a
`required bool notify` parameter — `true` only from the `payloads` subscription,
`false` from `restore` and `drainPending` — and it is the single rule keeping the
banner path honest.

Two delivery subtleties the de-duplication has to absorb, both by design rather
than by luck:

- The background handler runs **only** while the app is backgrounded or
  terminated; that is FCM's contract. A foreground message therefore reaches the
  live stream and never the pending key, so it cannot be stored twice.
- A push that arrives while backgrounded and is **then tapped** is delivered
  twice: once by the background handler into the pending key, and again by
  `onMessageOpenedApp`. `_seenIds` collapses them to one row, and the tap still
  navigates.

Resume detection uses an `AppLifecycleListener` owned by `AppShell`, disposed with
the widget, rather than a `WidgetsBindingObserver` on a longer-lived object — the
shell is the widget whose lifetime matches "the UI is on screen".

## Notifications

```dart
abstract interface class NotificationPresenter {
  /// Creates the Android channel and registers the tap callback.
  Future<void> initialize();

  /// Posts a banner for a message that has just arrived in the foreground.
  Future<void> show(PushMessage message);

  /// Ids of messages whose banner the user tapped.
  Stream<String> get taps;
}
```

`LocalNotificationPresenter` wraps `flutter_local_notifications ^22.3.0`. It
creates one channel — id `fcm_sample_high`, importance high — and posts with the
message id as the notification payload, so a tap resolves back to a message. The
notification id is the message id's `hashCode`, since the plugin requires an int.

`SilentNotificationPresenter` does nothing and emits no taps. It is used in widget
tests and when initialisation fails, so a broken notification plugin degrades to
"the inbox still works" rather than a crash at launch.

### Android configuration

`android/app/src/main/AndroidManifest.xml` gains, inside `<application>`:

```xml
<meta-data
    android:name="com.google.firebase.messaging.default_notification_channel_id"
    android:value="fcm_sample_high" />
```

Pointing FCM at the same high-importance channel is what makes the tray entries
it draws while the app is away pop as heads-up banners instead of landing
silently. Without it, FCM uses its own default channel and the channel created in
`initialize()` would only affect foreground banners.

`POST_NOTIFICATIONS` on Android 13+ is already requested: `main()` calls
`FirebasePushSource.requestPermission()`, which is `firebase_messaging`'s
`requestPermission()` and covers the runtime grant. No second request is added.

### iOS

`FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(alert: true, badge: true, sound: true)`
in `FirebasePushSource.start()`. Without it iOS suppresses the banner while the
app is foregrounded, so `flutter_local_notifications` is not needed there at all.
**Unverified** — this machine has no Xcode.

## Taps and the detail page

`MessageDetailPage` is pushed over the shell with its own `Scaffold` and back
button, and shows the title, the body, `sentAt`, the `id`, and one row per data
key. It is the same page from both entry points, so there is one place to read a
message.

Three things open it:

| Source | Route in |
| --- | --- |
| An inbox row | `MessageTile` gains an `onTap`; `InboxView` pushes the page directly |
| An FCM tray notification | `PushSource` gains `Stream<String> taps`, fed by `onMessageOpenedApp` and, on a cold start, by the `getInitialMessage` that `start()` already handles |
| A foreground banner | `NotificationPresenter.taps` |

`PushSource` gaining `taps` means `DisabledPushSource` returns `const Stream.empty()`
and `FakePushSource` gains an `emitTap` — which is what makes the whole tap path
widget-testable without Firebase.

`main()` subscribes both tap streams to `inbox.requestOpen`. `AppShell` adds a
listener in `initState` and removes it in `dispose` (DCM's `always-remove-listener`
is fatal), and when `pendingOpen` is non-null it pushes the page and calls
`clearPendingOpen()`.

**If the id resolves to nothing** — evicted by the cap, or the payload was
malformed and rejected — the shell selects the Inbox destination and pushes
nothing. A tap must never open a blank page.

## Error handling

| Cause | Behaviour |
| --- | --- |
| A stored entry is not decodable JSON | Skipped with a `debugPrint`; the rest of the inbox still loads. Corruption of one entry must not lose the others. |
| A stored payload decodes but fails validation | The existing `PushInbox.rejections` path, unchanged |
| `shared_preferences` is unavailable | Launch continues with an empty in-memory inbox, and the reason goes to the existing setup banner. Persistence failing must not stop the app opening — the same principle `main()` already applies to Firebase. |
| `flutter_local_notifications` fails to initialise | Falls back to `SilentNotificationPresenter`; the inbox still works |
| Notification permission denied | Banners do not appear. Nothing to handle — it is the OS's decision, and it is already requested at startup. |
| A tapped id is not in the inbox | Inbox destination selected, no navigation |
| A background push arrives while the app is dead | Persisted by the background isolate, surfaced by `restore()` at next launch |

## Testing

Every test runs under `fvm flutter test` with the fake store and the silent
presenter, so none touches a platform channel.

| Unit | What |
| --- | --- |
| `remoteMessageToPayload` | notification block supplies defaults, `data` wins, missing `sentTime` falls back to now, ids and timestamps are strings |
| `PushInbox.restore` | loads stored payloads newest-first, drains pending, de-duplicates against both, applies the cap, saves the capped result |
| `PushInbox.drainPending` | merges a payload that arrived while backgrounded; draining twice does not duplicate it |
| `PushInbox` notification rule | `show()` is called for a live payload and **not** for a restored or drained one — asserted with a recording fake presenter |
| `PushInbox.requestOpen` | resolves a known id; leaves `pendingOpen` null for an unknown one |
| `PushInbox` double delivery | a payload arriving both in the pending key and on the live stream produces exactly one row |
| `SharedPreferencesPushPayloadStore` | round-trips through `SharedPreferences.setMockInitialValues`; `takePending` clears; a corrupt entry is skipped |
| `MessageDetailPage` | renders title, body, `sentAt`, id and every data key |
| `InboxView` | tapping a row pushes the detail page for that message |
| `AppShell` | a `pendingOpen` message pushes the detail page and clears the request; an unknown id selects Inbox instead |

**Not automatable, and stated as such rather than claimed:** the real background
isolate, actual OS notification rendering, heads-up behaviour, tapping a real tray
notification, and everything iOS.

## Verification

- `fvm dart run melos run ci` green
- `fvm flutter build web --release` still compiles
- On a real Android device, with `apps/fcm_api` running:
  1. App foregrounded → send from the Sandbox → a **banner** appears and the row lands in the inbox
  2. Tap the banner → the **detail page** opens on that message
  3. Background the app → send → a **heads-up tray entry** appears
  4. Tap it → the app opens on the detail page for that message
  5. Background the app → send → do **not** tap → reopen the app → the message is in the inbox
  6. Force-stop the app → send → relaunch → the message is in the inbox
  7. Restart the app twice → no banners are replayed for old messages
  8. Tap an inbox row → the detail page opens

Items 1–8 need a device, which this machine has not had attached. They will be
reported as verified or unverified honestly, never assumed. The two manual items
still outstanding from the previous plan — generating a service-account key and
the `curl` check that proves the OAuth path — are prerequisites for all of them.

## Deliberately out of scope

- Routing on data keys: the `deepLink` a gallery preset carries stays inert
- Notification actions, buttons and replies
- Grouping or summary notifications
- Badge counts
- Scheduled or repeating local notifications
- Encryption of the stored payloads at rest
- Changes to `packages/core`, `packages/fcm_gallery_shared` or `apps/fcm_api`
