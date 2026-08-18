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

**The four iOS scenarios have never been compiled for iOS.** They are in the table so
that unblocking iOS is a skip-policy change rather than a table rewrite. Expect the
Xcode side to need work that this plan did not do.
