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

**`a4_no_display` and `i2_silent_data_sync` expect `displayed`.** The catalogue
describes both as drawing nothing. The app draws a banner for every foreground
arrival: `PushRepository._ingest` calls `_show` unconditionally, and
`LocalNotificationPresenter.show` has no title guard, so a data-only push posts a
notification with an empty title and records `displayed`.

The table matches the app, so these two tests pass. That is a deliberate choice not to
ship a red test — **not** a finding that the app is right. Someone has to decide
whether the app should suppress a titleless banner, and if it should, these two
entries gain `absentEvents: {displayed}` and the app gains a guard, in that order.

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
Patrol documents an API for. Whoever calibrates this entry on a device should press
each button by hand and confirm `action` reaches the Telemetry page with the right
id, in each of the three app states — foreground, background and killed.
