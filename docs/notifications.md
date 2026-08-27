# Notifications

Most confusion about whether a push "arrived" is not actually about arrival at
all — it is one payload shape and one app state mistaken for another, because
the two together decide who draws the banner and whether anything visible
happens at all. This document is the four shapes, the three states, and the
table the two make together. For where the code that implements any of this
actually lives, see [architecture.md](./architecture.md).

## The four shapes a message can take

FCM's `Message` object carries an optional `notification` block and an
optional `data` map, and what a device does with a push depends on which of
the two are present.

- **Notification only.** A `notification` block with no `data` at all. FCM's
  own SDK knows how to draw this without the app's help.
- **Data only.** A `data` map with no `notification` block, but with its own
  `title` and `body` among the data keys, so the app has real text to show —
  a sender can put those keys straight in `data` for exactly this reason.
  Nothing but the app itself can ever draw this shape, because FCM has no
  block to draw it from.
- **Both.** A `notification` block and a `data` map together, the shape most
  production pushes actually take.
- **Data present, nothing to show.** A `data` map with no `notification`
  block and no `title` or `body` among its keys either — a log line, a sync
  marker, a flag meant only for the app's own logic. Nothing in this shape
  suppresses a banner; it leaves nothing for one to say.

## The three states the app can be in

- **Foreground.** The app is on screen. Android draws nothing on its own here
  for any shape, `notification`-only included.
- **Backgrounded.** The process is alive but nothing of the app is on screen.
- **Killed.** The process does not exist until something — the push itself,
  or a later tap — starts it.

Backgrounded and killed behave identically for who draws a notification: the
same background code path handles both, and the difference between them only
shows up in what a tap can deliver, below.

## Which layer draws

| Shape                          | Foreground | Backgrounded | Killed |
| ------------------------------ | ---------- | ------------ | ------ |
| Notification only              | App        | System       | System |
| Data only                      | App        | App          | App    |
| Both                           | App        | System       | System |
| Data present, nothing to show  | App        | App          | App    |

**Foreground is always the app**, whatever the shape: Android draws nothing on
its own for a push that arrives while the app is on screen, so the app's own
notification-drawing code, `LocalNotificationPresenter`, draws every
foreground push itself — the row is uniform on purpose.

**On iOS this row may not be as clean as "App".** `FirebasePushSource` also
opts into `setForegroundNotificationPresentationOptions(alert: true, badge:
true, sound: true)` at startup, which asks iOS to present a foreground push
through its own system UI — on top of the `LocalNotificationPresenter` draw
above, which runs on every platform unconditionally. On Android that second
mechanism does not exist, so the app's own draw is the only one and the row
is exactly what it says. On iOS the same push may be drawn twice, once by
each mechanism. This has not been verified on a device — no iOS build has
ever run in this repo — so treat it as an open question rather than a
confirmed bug, and check it before copying this pattern into another app.

**A notification block, when present, is drawn by the system while the app
is not on screen**, straight from that block. For *notification only*, that
is the whole story: nothing else happens until the notification is tapped.
For *both*, the app still runs quietly alongside the system's own drawing
— it has to, in order to save the push and answer a later tap — but it
does not draw a second banner, because FCM's own tray entry already covers
it.

**A payload with no `data` map never wakes the app at all while it is
backgrounded or killed.** FCM does not start the app for a bare
`notification` block outside the foreground, so a notification-only push
that is never tapped is never seen by the app's own code, only by the
system tray. A `data` map is what starts the app's own drawing code
instead, which is why the *data only* and *nothing to show* rows read
"App" throughout: the app runs precisely because there is data to hand it,
whether or not that data has anything to draw.

**"Data present, nothing to show" still produces a banner.** Nothing in the
app reads a payload for an intent to stay silent; what varies is only
whether `title` and `body` come out non-empty. A `data` map with no `title`
or `body` key still reaches the app's drawing code the same way a `data` map
with them does, and still posts a banner — an empty one, icon and app name
with no text, rather than no banner at all. Mistaking a blank banner for a
missing one, or expecting a `data`-only push to stay invisible because it
carries nothing a person would read, is exactly the kind of confusion this
table exists to head off.

## Which channel it lands on

From Android 8 onwards a notification's *behaviour* is not its payload's to
decide. How loudly it announces itself, whether it makes a sound at all, what
it vibrates, whether it can cut through Do Not Disturb — all of that belongs to
the **channel** it is posted to, and the channel is created by the app before
any push arrives. This is the single most common surprise in Android
notifications: you put `sound` in the payload, nothing changes, and nothing
reports an error either.

A payload picks a channel by id, in `android.notification.channel_id`. This app
registers eleven of them and the catalogue's `d` and `h` groups exist to walk
through what they control — four that differ only in importance, one with a
custom sound, one with a vibration pattern, one asking to bypass Do Not
Disturb, one using the alarm audio stream, and two chat channels filed under a
shared group so they appear together in system settings.

**An id the app never registered draws nothing at all.** Not a fallback, not a
default — on Android O+ a notification posted to a channel that does not exist
is dropped silently. So an unrecognised id is replaced with the app's default
channel rather than passed through to Android, because honouring the payload
literally would lose the notification. The default is the first channel in the
table, the same one `AndroidManifest.xml` names as FCM's
`default_notification_channel_id`.

**A channel's properties are fixed the first time it is created**, and the two
ways an app might try to change one fail differently. Registering it again does
not update it: the plugin refuses the call outright once the channel exists,
which is why this app registering all eleven from each of its three drawing
isolates is a real no-op past the first. Asking Android directly to change an
existing channel's importance fails the other way — the request is accepted and
the value simply does not move. Only the user can change these, in system
settings.

One consequence catches people out: a channel keeps the name it was created
with. Install the app in Czech and the channels are named in Czech; switch the
app to English afterwards and they stay Czech, because renaming them is exactly
the call Android refuses. The single fix available to an app that got a channel
wrong is to create a new one under a new id and abandon the old — which is why
the catalogue ships `chat_v1` alongside `chat_v2`: the mistake and the only
repair Android permits.

The **Channels** page is where this stops being theory. It lists every channel
the app asked for beside what Android actually reports holding, so a
divergence is visible rather than inferred, and it has a button that asks
Android to lower `chat_v1`'s importance and then re-reads the system's answer.
The re-read is the point: the request succeeds and the value does not move.
The same page is where `bypassDnd` shows its own asymmetry — the app requests
it, and Android grants it only if the user has given the app
notification-policy access, so requested and granted are two different columns.

Channel names and descriptions are shown to the user by Android itself, which
is why they are translated rather than const, and read by id at registration
time — see [localization.md](./localization.md).

## What a tap delivers

A tap always delivers two things: which message it was for, and where the
tap should navigate to. Which message resolves to the actual push content —
its title, body and full `data` map — pulled back out of what the app has
already stored. Where to navigate is read from one `data` key the message
itself carries: if it names a screen or a specific run the app already
knows, the tap goes straight there; if it names nothing the app recognises,
or the payload carries no such key at all, the tap opens that message's own
detail page instead, showing the raw payload rather than guessing at an
intent nobody stated.

**How the tap reaches the app differs by which layer drew the banner.** A
banner the app drew itself — every foreground case, and every backgrounded
or killed case with no notification block — reports the tap through the
notification plugin the app used to draw it. A banner the system drew —
backgrounded or killed, with a notification block present — reports the tap
through FCM's own delivery instead, because the app was never involved in
drawing it and has no plugin callback to hear from.

**Killed is the state where this stops being symmetric.** A tap that starts
the process from nothing is the only kind of tap a killed app can receive —
there is no other way for it to learn a tap happened at all — and which
route reports it still depends on which layer drew the banner: the system's
own route for a notification block, the notification plugin's own launch
details for one the app would have drawn once it was running. The two do not
always arrive in the same order — a tap can be reported before the message
it names has finished being stored — so the app holds an unresolved tap
rather than dropping it, and resolves it the moment the message it was
waiting for turns up.

## What a person can do to a notification

A notification the app drew itself can also carry up to three action
buttons, named in the payload's own `data.actions` key rather than in any
FCM field — FCM has no way to express a button, so the convention lives on
this project's side, and the client builds the buttons from it
(`notification_action.dart`). Pressing a plain button behaves like a tap: it
opens the app, and the press is reported alongside which button it was. One
button can instead be marked to take typed input — inline reply — which does
not open the app at all: a background isolate saves the typed text and
redraws the notification in place to show it went through, and the app only
sees the reply once it is next opened.

This is Android-only in this app, for the same reason `dismissed` is: iOS
takes its actions from a fixed `UNNotificationCategory` registered once at
startup, and a per-message payload has nowhere to hand it a different set.
See [telemetry.md](./telemetry.md) for how a press and a reply are recorded.
