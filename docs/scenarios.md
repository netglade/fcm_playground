# Scenarios

The app does not wait for you to invent a push worth sending. The Scenarios
page (drawer → Scenarios) holds a catalogue of 66 payload templates in eleven
groups, A through K, mirroring FCM's own test surface: basic delivery, app
states, priority and delivery window, channels and importance, appearance,
interaction, groups and badges, intrusive delivery, silent and data,
targeting, and edge cases. Each one is a real FCM `Message`, built to show one
specific thing FCM can do. For what a device does once a payload like this
arrives, see [notifications.md](./notifications.md); for where the catalogue
lives in the code, see [architecture.md](./architecture.md).

This document does not list the 66 — the app already shows them, and a list
here would be wrong within a month of someone adding a scenario.

## Not every scenario works today

Every card shows a title, a description, and its bare id — the id is what the
catalogue, the server, and the tests all use to refer to it, so it is worth
reading even though it means nothing in prose. Some cards also carry a small
"needs work" chip. That chip is `ScenarioNeed`: a scenario can be catalogued
and still not demonstrable, because showing it needs something the app does
not have yet — a second notification channel, a launcher badge, a device
registry to fan a send out to, a manual step over `adb`, or approval from
Apple or the OS this project cannot grant itself. Rather than hide an
unfinished scenario, the app says on the card what it is waiting on.

A blocked scenario is still sendable — the payload is genuine, only the
behaviour it would demonstrate is missing, and watching a client with one
notification channel receive a payload aimed at a channel it does not have is
itself informative. Where no payload could produce the scenario at all — a
device reboot, a Doze window, a revoked permission — the card shows the exact
command to run by hand instead, in a block you can select and copy.

## Sending one

Tapping a card applies its payload to the Sandbox and switches you there. The
Sandbox edits the message through a form, not a JSON text box: ten
collapsible sections mirror FCM's own objects one for one — `message`,
`notification`, `android`, `apns`, `webpush`, and the rest — nested as deep as
the payload itself, each closed by default except the outermost, and each
header flags an error the moment anything inside it is invalid at any depth.
FCM distinguishes an omitted field from one explicitly set to `false`, and the
form does too: every optional boolean is a three-way choice — unset, true,
false — rather than a checkbox that would silently send `false` for a flag
you never touched, and an empty text, list or map field likewise omits the
key rather than sending it empty. `apns.payload` and `webpush.notification`
are Apple's and free-form respectively, so instead of nested controls they
are edited as dotted-path rows (`aps.alert.title`) that expand back into JSON
on send. The one deliberate gap: there is no JSON escape hatch, so only a
field the form already models can be sent — the trade for a form that cannot
produce a malformed payload.

**The field labels stay in FCM's own English**, in every language the app
supports, because they name fields from
[Google's own REST reference](https://firebase.google.com/docs/reference/fcm/rest/v1/projects.messages)
— translating `direct_boot_ok` would break the one thing that reference is
for, which is letting you look a field up.

## Choosing who receives a send

The delivery target lives outside the payload entirely, in an envelope
around it, so no template pasted from Google's docs can quietly send to more
than intended. The Sandbox offers one selector above the form — this device,
an explicit registration token, a topic, a condition, or every device — and
the Send button names whichever one is chosen. Only *this device* needs a
token from this device; a topic or a condition names its own audience.
Choosing every device gets refused outright, with a reason: FCM has no such
audience of its own, and honouring it would need a registry of every token
this project has ever seen, which nothing here keeps.

## Watching a scenario that needs the app gone

Some scenarios only mean anything if the app was not running when the push
arrived — `b3_killed` is the sharpest case, testing whether FCM starts the
app from nothing at all. A push like that cannot be a button the app itself
presses, since by the time it would fire, the app might already be dead.

Selecting *Schedule…* instead of *Send* holds the payload for later, on a
short set of delay presets (10s, 20s, 30s, 60s), and opens a countdown screen
that keeps the display awake so it does not sleep before you have had a
chance to swipe the app away. The schedule itself is held server-side rather
than on the device, so it survives you killing the app — that is the whole
reason a delay exists here rather than the app sending on its own timer: the
thing being tested requires the app to not be the one holding the clock. Once
it fires, the run appears on the Runs page (drawer → Runs) with its own
delivery timeline, the same as an immediate send.

Ticking several scenarios instead of one, from the Scenarios page's selection
mode, schedules all of them as a single run with a fixed spacing between each
send — useful for walking through a whole group unattended.

## The end-to-end suite

A device-driven Patrol suite exercises part of the catalogue for real, against
a connected Android handset, outside the ordinary test gate — a suite that
needs hardware has no business in one that has to pass on every machine. Of
the 66 scenarios, 26 run there; the other 40 are skipped, each with a stated
reason: 34 wait on a `ScenarioNeed` the app has not built yet, 4 need a
physical iPhone the suite cannot provide, and two — `b3_killed` and
`f5_deeplink_killed` — would each have to kill the very app the test is
running inside. The 26/40 split is pinned by a test in the app's own suite,
so a scenario becoming unblocked shows up as a failing count rather than as
silence.
