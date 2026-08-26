# Calibrating the expectations

`support/expected_events.dart` was written from reading the code, not from watching a
device. It will be wrong somewhere. This is how to find out where.

## What you need

- An Android handset or emulator with Google Play services, showing in `adb devices`
- The API running with a real service account key:
  `GOOGLE_APPLICATION_CREDENTIALS=/path/to/key.json fvm dart run melos run api:serve`
- On a physical handset: `adb reverse tcp:8080 tcp:8080`
- On the emulator: `export FCM_API_BASE_URL=http://10.0.2.2:8080`

## The pass

Run one group at a time rather than `test:e2e`, so a failure is easy to read:

```bash
cd apps/fcm_app
fvm exec patrol test --target integration_test/group_a_test.dart \
  --dart-define=FCM_API_BASE_URL="${FCM_API_BASE_URL:-http://localhost:8080}"
```

That `--dart-define` is what actually reads the `FCM_API_BASE_URL` the previous
section exports — it is a build-time value, not something the app can pick up from
the shell at run time — and matches how `melos run test:e2e` invokes the same binary.

A mismatch reports as a set difference naming the scenario, for example:

```
a1_notification_only: expected but never arrived. Arrived: queued, sent, received_fg
```

That line is the datum: `displayed` did not arrive, so either the presenter threw or
the flush had not landed by the deadline.

## What to change, and what not to

Correct the **table**, not the assertion helper. When a scenario records something the
table did not expect, decide which side is wrong:

- the app behaves correctly and the table guessed badly → fix the table
- the app behaves wrongly → leave the table, open a bug. A failing e2e test that
  describes real misbehaviour is the suite working.

Write down which entries you have confirmed against a device, so the next reader knows
which are still guesses.

## Known disagreements, decided in advance

**`a4_no_display` and `i2_silent_data_sync` expect `displayed`.** Both are data-only
and carry no title or body, and nothing guards against that: `PushRepository._ingest`
calls `_show` unconditionally for a foreground arrival, and the background isolate
draws through the same builder for every payload with no `notification` block, so
either isolate posts a blank tray entry — icon and app name, no text — and records
`displayed`. The catalogue used to describe these two as drawing nothing at all; that
was wrong and has been corrected in the catalogue copy itself, not here.

The table matches the app, so these two tests pass. That is not a finding that the app
is right, only that the table describes it accurately. Someone still has to decide
whether the app should suppress a titleless banner instead of drawing an empty shell,
and if it should, these two entries gain `absentEvents: {displayed}` and the app gains
a guard, in that order.

**`c2_priority_normal` can fail for a correct reason.** NORMAL priority entitles FCM to
hold the message until the next maintenance window. Its two-minute timeout is generous,
not sufficient. A timeout there may be FCM behaving exactly as documented — re-run
before believing it.

**`c3_ttl_zero` shares that property, and a longer timeout cannot fix it.** `ttl: '0s'`
tells FCM to make exactly one delivery attempt and discard the message rather than
queue it. A device that is momentarily unreachable at the instant FCM tries — briefly
off the network, mid Doze maintenance window itself — fails this test for a correct
reason, and re-running is the only remedy: there is no later delivery window for a
longer timeout to wait for, unlike `c2`.

**A passing `displayed` does not prove a notification was drawn.** It is recorded
when `LocalNotificationPresenter.show` *returns without throwing* — not when the OS
actually paints something. On Android 13+ with `POST_NOTIFICATIONS` denied, `show`
still returns normally; nothing appears in the tray. So if permission granting were
ever to silently fail — the harness's own grant call swallowing an error, a device
that never shows the dialog at all — every `displayed` assertion here would still
pass, against an empty tray. `displayed` is evidence the app *tried* to draw a
banner, not that a person would have seen one.

**The four iOS scenarios have never been compiled for iOS.** They are in the table so
that unblocking iOS is a skip-policy change rather than a table rewrite. Expect the
Xcode side to need work that this plan did not do.

**`f1_actions`'s automated assertions cover delivery and drawing only.** Pressing an
action button is a manual step: Patrol's `tapOnNotificationBySelector` matches
notifications, not the buttons inside them, and pressing an action is not something
Patrol documents an API for. That is not the same as "cannot be automated", though:
`$.native.tap(Selector(text: 'Retry'))` against an already-open shade is the obvious
untried route — `NativeAutomator.tap` takes any `Selector`, not only ones the
notification helpers construct — and whoever calibrates this entry should try it
before assuming the manual step is permanent. Until then, press each button by hand
and confirm `action` reaches the Telemetry page with the right id, in each of the
three app states — foreground, background and killed.

**`f2_inline_reply`'s automated assertions cover delivery and drawing only, the same
limit `f1_actions` already documents.** Patrol cannot type into the notification
shade any more than it can press an action button, so typing the reply — and
everything the reply sets in motion — is a manual pass. Three things need a device
to settle, and none of them is provable by any test:

1. **Run this one first.** Send the scenario with the app backgrounded, so the
   background isolate draws it, then press Reply and type. The notification
   should update in place — `Sending…`, then `Sent`. It reliably will: the
   background isolate, the response isolate, and the main isolate all
   register the same callback, so the registration is correct whichever of
   the three happens to run its `initialize` last, and the pinned
   `flutter_local_notifications` does not clear one registration when another
   initialize call omits it. A failure here does not show in the shade at
   all — open the message from the Inbox afterwards and confirm the detail
   page reads `Replied: <what you typed>`. A reply that reaches storage but
   never makes it into the app's merged map looks identical to success in the
   tray, right through to the final `Sent`; the missing `Replied:` line on the
   detail page is the only place that failure is visible.
2. That the notification **updates in place** — `Sending…` replaced by `Sent` —
   rather than a second banner stacking beside the first.
3. That the **typed text arrives intact** through the platform channel: open the
   message from the Inbox and confirm it reads `Replied: <what you typed>`, not
   a truncated or re-encoded copy of it.

Also confirm the Telemetry page records an `action` event for the reply, with no
`opened` — nothing opened the app.

**`f6_delete_intent` needs a swipe by hand, for the same reason.** Patrol has no
notification-specific dismiss gesture, only the generic `$.native.swipe`, and
nobody has aimed it at a tray entry yet. Send the scenario with the app on screen
and swipe it away; confirm `dismissed` is recorded. Then send it again, background
the app, and swipe the FCM-drawn entry: confirm nothing is recorded, which is the
limit `f6_delete_intent`'s catalogue entry now documents, not a gap in the harness.

**The three deep links need a tap by hand too, same as `f1_actions`.** The suite's
automated assertions only cover that the push arrives and is drawn; the tap itself,
and where it lands, is a manual step. Send `f3_deeplink_foreground` and
`f4_deeplink_background` and confirm the named screen opens — Telemetry and Sandbox
respectively — rather than the message detail page. `f5_deeplink_killed` needs the
delayed send and a real app kill to exercise at all, and is the one most worth doing
by hand: `getInitialMessage` is the route nobody exercises by accident, so it is the
one most likely to have quietly broken.

**Group D, h2 and i1 assert delivery, not behaviour.** Telemetry can see that a
notification was delivered and drawn. It cannot hear a sound, feel a vibration, or
read an importance. All ten therefore carry the same `_deliveredAndDrawn` every
other delivered scenario carries, and the channel's actual properties are read off
the Channels page by a human — the same split f1 and f6 already have for a button
press and a swipe.

`d3_importance_low`, `d4_importance_min` and `i1_silent_no_sound` are the ones to
watch here: they draw through channels where no banner pops at all, and still
record `displayed`, because `PushRepository._show` reports it once `plugin.show()`
returns rather than according to what the user saw.

**`f7_ongoing`'s automated assertions cover delivery and drawing only; the ongoing
behaviour itself is a manual pass.** It is data-only, so the app draws it itself and
the ongoing flag applies whichever state you send it in — app state does not matter
here, unlike `g2` below. Nothing in the telemetry stream distinguishes an ongoing
notification from any other — `displayed` fires the same way either way — so send it
and try to swipe it away by hand. On Android 13 and earlier it should refuse; on
Android 14 and later the platform lets the user dismiss it anyway (the exemptions are
`CallStyle`, device-policy and media notifications, and a plain ongoing flag is not
among them), so a swipe succeeding there is the OS working as documented, not a bug.
Either way, open the Inbox and press **Clear notifications**, and confirm the
notification is gone from the tray while the Inbox's messages are untouched.

**`f8_full_screen_intent`'s automated assertions cover delivery and drawing only;
what the intent degrades to is a manual pass.** Nothing about a full-screen intent
reaches telemetry — the app asks for one, Android decides, and `displayed` fires
either way — so send it with the app **backgrounded and the screen locked or off**.
That second condition decides the test: a full-screen intent launches its activity
only when the user is not already using the device, so on an unlocked handset
Android shows a heads-up **even where it has granted the permission** — and a
heads-up is exactly what a refusal looks like. Run this unlocked and you record
"refused" whatever really happened, destroying the one observation this scenario
exists to produce. On Android 14 and later expect a heads-up rather than a
lock-screen takeover: the platform grants `USE_FULL_SCREEN_INTENT` only to calling
and alarm apps, and that refusal is the demonstration. On Android 13 and earlier the
permission is granted at install, so expect the takeover instead — a correct grant,
not a broken expectation. A user can also grant it by hand under Settings → Apps →
Special app access → Full screen intents, so check there before recording a surprise
on your own handset. Record what you see either way — a device that does grant the
takeover is a valid observation about that device, not a failure of the scenario.
Confirm separately that the notification is drawn at all: it is data-only now, so
nothing appearing means the app's own drawing did not run, which is a different
failure from a refused permission and must not be read as one.

**`f9_trampoline` has no device step at all.** It is not built — demonstrating the
Android 12 ban means starting an activity from a broadcast receiver or service,
which needs the platform code this Dart-only gallery deliberately does not carry —
so it carries `ScenarioNeed.nativeCode`, never reaches the table, and there is
nothing to watch. Its catalogue entry says so on the card.

**`g1_group_summary`'s automated assertions cover delivery and drawing only; the
collapse under a summary, and the climbing count, are both manual passes.** It is
data-only, so the app draws it and posts the summary itself whichever state you send
it in — app state does not matter here, unlike `g2` below. Nothing about the summary
reaches telemetry — a send of the fifth looks the same on the wire as the first. Send
it five times by hand and confirm all five collapse under one summary row, and that
the row's count reads 5 by the time the fifth arrives. If this device already has a
"builds" summary standing from an earlier pass, clear it first: the store only forgets
a group when Clear notifications is pressed, never when a member notification is
merely swiped or tapped away, so a count that starts above 5 or climbs past it is that
leftover state, not a miscount.

**`g2_update_same_id`'s automated assertions cover delivery and drawing only; that
the second send replaces rather than stacks is a manual pass.** Telemetry records
two separate deliveries either way, so send it twice by hand — with the app
backgrounded, then again with it on screen — and confirm the tray shows one
notification, not two, after each pair.
