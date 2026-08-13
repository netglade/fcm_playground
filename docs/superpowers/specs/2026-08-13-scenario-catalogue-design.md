# The scenario catalogue

Replace the Sandbox's nine-scenario gallery with the full 66-scenario FCM test
catalogue, in eleven groups A–K, and record honestly which of them the app can
demonstrate today.

## Why this is its own spec

The catalogue names capability the app does not have: several notification
channels with a management screen, local notification styles, action buttons,
inline reply, launcher badges, topic and multicast targeting, delayed sending, and
a dozen procedures that are adb commands rather than payloads. Building all of
that is weeks of work across several plans.

But every scenario is *first* a catalogue entry, and the catalogue is the target
the rest is built against. So it comes first and alone. Nothing here depends on
the capability below; everything below is measured against what this defines.

## The roadmap this is step one of

| # | Sub-project | Scenarios | Unblocks |
| --- | --- | --- | --- |
| **1** | **The catalogue** (this spec) | all 66 | the 20 that already work |
| 2 | Channels and importance | D1–D8, H1, H2, I1 | 11 |
| 3 | Appearance styles | E1, E3, E6–E9 | 6 |
| 4 | Interaction | F1–F9, G1, G2 | 11 |
| 5 | Badge | G3 | 1 |
| 6 | Targeting | J1–J3, K2 | 4 |
| 7 | Delayed send | B3 | 1 |
| 8 | Procedures and burst | B2, B4–B6, C5–C7, I4, K3–K5 | 11 |

**The arithmetic closes at 66**, and it should be checkable rather than asserted:
20 work today, 45 are unblocked by sub-projects 2–8 (11+6+11+1+4+1+11), and 1 —
**H4**, iOS critical alerts — is permanently outside our control. 20 + 45 + 1 = 66.

The 20 that work today are A1–A4, B1, C1–C4, E2, E4, E5, E10, E11, G4, H3, H5, I2,
I3 and K1. E2 counts as working because it works on Android; iOS needs a
Notification Service Extension, which goes in `expectation` alongside every other
iOS caveat in this repo rather than blocking the entry.

Sub-project 2 is where the catalogue's own note lands — *"the app must have a
Channel management screen showing each channel's importance read **from the
system**, not from code"* — because without it nobody can explain why a push did
not make a sound.

Two scenarios stay permanently outside our control and are marked as such rather
than scheduled: **H4** needs an Apple-approved critical-alert entitlement, and
**E2 on iOS** needs a Notification Service Extension. **F8** additionally needs
`USE_FULL_SCREEN_INTENT`, which Android 14+ grants only to calling and alarm apps.

## The model

`Scenario` already carries `String group`, so A–K needs no new field — the gallery
groups dynamically on that string. Two additions:

```dart
/// What a scenario needs beyond a payload before it demonstrates anything.
enum ScenarioNeed {
  channels,              // sub-project 2
  styles,                // 3
  interaction,           // 4
  badge,                 // 5
  targeting,             // 6
  delayedSend,           // 7
  manualStep,            // 8
  externalApproval,      // never ours: Apple entitlements, NSE, DnD policy access
}
```

`List<ScenarioNeed> needs` (default `const []`) and `String? manualSteps`.

**An enum rather than free text**, for one reason worth stating: each value *is* a
sub-project. "How many scenarios does sub-project 4 unblock, and which?" becomes a
filter rather than a grep over prose, and a scenario cannot be marked as needing
something no plan will ever deliver.

The catalogue's three columns map onto fields that already exist: *Scénář* →
`title`, *Co sledovat* → `description`, and platform caveats → `expectation`.
`requiresKilledApp` and `defaultDelaySeconds` are already on the model, unused,
waiting for sub-project 7; B3 is what finally uses them.

## Files

Nine scenarios currently occupy 239 lines, so 66 in one file would be roughly
1,600 — a file doing eleven things. One file per group instead:

```
packages/fcm_gallery_shared/lib/src/scenarios/
  scenario.dart          the class, ScenarioNeed
  group_a.dart …
  group_k.dart           one const list each
  scenario_gallery.dart  concatenates them in order
```

Each group file is readable on its own and reviewable against one table of the
source document. `scenarioGallery` keeps its name and type, so every existing
consumer is untouched.

## The ids change, deliberately

The document's ids replace the current nine. `data_only` → `a2_data_only`,
`big_picture_remote` → `e2_image_remote`, `apns_alert` → `g4_badge_ios`,
`custom_channel` → `d1_importance_high`. Tests naming the old ids move to the new
ones; the ids are the document's, not ours, and two naming schemes would be worse
than one migration.

## The invariant

The existing gallery test asserts every template round-trips
`raw → FcmMessage.fromJson → toJson → raw` unchanged. It carries over to all 66 and
becomes the main safety net of this work: 66 hand-written templates is exactly the
situation where a `titel` typo or a camelCase key slips in, and the strict parser
plus this assertion is what turns that into a failed build rather than an opaque
400 from Google on a device.

A second assertion guards the catalogue's shape: every id is unique, every id
matches its group's letter (`^a\d`, `^b\d`, …), and the group count is 11. That is
what stops an entry being filed under the wrong letter as the file grows.

## The Sandbox and the gallery

**Any scenario can be opened and sent.** A scenario with unmet `needs` shows a
banner naming them — "needs notification actions" — above the form. The push is
genuine and valid; it simply will not demonstrate the feature yet. Sending F1's
payload and seeing what a client with no action support does with it is itself
worth seeing, which is why Send is not disabled.

`manualSteps`, where present, renders as a selectable block so an adb command can
be copied — for C6, C7 and the K3–K5 device procedures the payload is almost
incidental and the procedure is the scenario.

The gallery gains a small "needs" chip per row. It already builds one
`ExpansionTile` per group with only the first open, so eleven groups need no new
layout.

## Error handling

Nothing here talks to the network, so the failure modes are authoring mistakes,
and all three are compile-time or test-time:

| Mistake | Caught by |
| --- | --- |
| A template with a key FCM does not define | the strict parser, via the round-trip test |
| A duplicate or misfiled id | the catalogue-shape test |
| A `needs` value with no sub-project | the enum |

The one runtime concern is that the Sandbox must not imply a blocked scenario
works. The banner is the answer, and a widget test asserts it appears for a
scenario with unmet needs and is absent for one without.

## Testing

- Per group file: the entries parse, and the group's ids all carry its letter.
- Across the gallery: 66 entries, unique ids, 11 groups in A–K order, every
  template round-trips.
- `ScenarioNeed`: every value is used by at least one scenario, so the enum cannot
  drift from the catalogue. Also that exactly 20 scenarios have no needs — the
  number is asserted so that mis-marking one as blocked, or quietly unmarking one
  to make it look supported, fails the build.
- Widget: the needs banner appears and disappears correctly; `manualSteps` renders
  when present.
- Regression: the existing tests that named the old nine ids pass under the new
  ones.

## Out of scope

Everything in sub-projects 2–8. No notification channel beyond the existing
heads-up one, no styles, no actions, no badge, no topic or multicast targeting, no
delayed send, and no burst sender. This spec adds data, two model fields, and two
small pieces of UI.
