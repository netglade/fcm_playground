# The telemetry pipeline

Give every send a `trace_id`, record nine events against it across the API and the
app, and make `sent → received` latency computable. That latency is the number the
whole design exists for: it is what turns *"push feels slow on Xiaomi"* into
*"median 4m12s on Xiaomi, 1.1s on Pixel, same payload, same minute"*.

## Scope

This spec covers the **capture pipeline** — the model, the backend store, and the
client's six hook points. It produces software you can verify end to end without a
screen: send a scenario, then `curl` the API and read the latency back.

**The report page is the next spec, not this one.** A `scenario × device` matrix
with CSV export is worth building on top of a pipeline that is known to work, and
worthless on top of one that is not.

## What this cannot capture yet, and why

Seven of the nine events hook into code that exists. Two do not, and they are
blocked on the *interaction* sub-project of the scenario-catalogue roadmap:

| Event | Blocked on |
| --- | --- |
| `dismissed` | a delete intent — `f6_delete_intent` |
| `opened`'s *"from which state"* qualifier | three-state routing — `f3`–`f5` |

Plain `opened` works now, because a notification tap already reaches the app. Only
the state qualifier is missing. Both are recorded in the enum from the start so the
schema does not change when they light up, and both are marked unsupported the same
way a blocked scenario is.

## Where `trace_id` comes from

**The API mints it and injects it into `data`, exactly as it already injects the
token.** Not the client, and not the templates.

That choice matters for three reasons. None of the 66 catalogue templates carries a
`trace_id`, so injecting server-side leaves every one of them untouched and the
gallery round-trip invariant unaffected. The API is also the only party present for
`queued`, `sent` and `send_failed`, so it must know the id anyway. And a
client-minted id would be absent from any send made by `curl`, which is how half of
this project's testing happens.

The id travels in `data.trace_id`, comes back to the app inside the received
message, and is returned in the send response so the Sandbox can show it.

**`trace_id` joins `PushMessageParser.reservedKeys`.** Without that it renders as an
"extra data" row in the inbox and the detail page, which is noise — it is
plumbing, not payload. It is *not* added to `requiredKeys`: a push sent by hand
carries no trace id and must still reach the inbox.

## The event model

Shared, in `fcm_gallery_shared`, because both sides write it:

```dart
enum TelemetryEventType {
  queued, sent, sendFailed,        // the API
  receivedFg, receivedBg,          // the app
  displayed, opened, dismissed,    // the app
  notReceived,                     // the app, by hand
}

class TelemetryEvent {
  final String traceId;
  final TelemetryEventType type;
  final DateTime at;               // always UTC
  final String deviceId;           // '' for API-side events
  final String? scenarioId;        // which catalogue entry, when known
  final String? detail;            // FCM error code, app state on open, …
}
```

`at` is UTC without exception. A latency computed across a device on local time and
a server on UTC is off by hours and looks like a delivery problem, which is the one
mistake that would discredit the whole measurement.

`detail` is deliberately one free-text field rather than a column per event type.
The nine types carry different extras — an FCM error code, the app state at open —
and a shared schema with seven mostly-null columns is worse than a string whose
meaning is documented per type.

## The backend: SQLite, and the API becomes stateful

The API has never had persistent state; `server_config.dart` only reads the
service-account key. This adds a single SQLite file, its path configurable and
defaulting beside the key.

```sql
CREATE TABLE events (
  id         INTEGER PRIMARY KEY AUTOINCREMENT,
  trace_id   TEXT    NOT NULL,
  type       TEXT    NOT NULL,
  at         TEXT    NOT NULL,   -- ISO-8601 UTC
  device_id  TEXT    NOT NULL DEFAULT '',
  scenario_id TEXT,
  detail     TEXT
);
CREATE INDEX events_trace ON events (trace_id);
```

`POST /events` takes `{"events": [ … ]}` — a batch, because the client flushes a
buffer rather than one event at a time — and is idempotent on
`(trace_id, type, device_id)`: a flush that succeeds server-side but fails to be
acknowledged will be retried, and a duplicated `received_fg` would corrupt the very
latency this exists to measure.

`GET /latency` returns, per `trace_id` and device, `sent → first received_*`. It is
one query rather than app-side arithmetic because the server holds both halves and
is the only party that holds *every* device's half.

**This makes the loopback binding load-bearing rather than merely prudent.** An
unauthenticated write endpoint that accumulates a queryable store is a different
proposition from a stateless relay. The README's existing warning is upgraded to say
so, and the bind address stays `127.0.0.1`.

## The client: Drift, and codegen enters the repo

Events buffer locally and flush to `/events`, so a push received with the API down
is not lost — which is most of them, since the interesting cases involve killing the
app or cutting the network.

Drift brings `build_runner`, and this repo has no codegen step today. Two
consequences must be handled or the gate breaks:

- **Generated `*.g.dart` files are committed**, so `melos run ci` needs no codegen
  step and a fresh clone builds. A `melos run generate` script exists for
  regenerating them.
- **They are excluded from `format:check`, `analyze` and DCM.** Generated code will
  not satisfy this repo's fatal lints, and a `// ignore_for_file` header is
  forbidden here. Exclusion is by path in `analysis_options.yaml`, the same
  mechanism `metrics-exclude` already uses.

The store sits behind an interface, as `PushPayloadStore` does, so the widget tests
never open a database.

**Flush policy:** on app resume, after each event, and on a timer while events
remain — whichever comes first. Events are deleted only once the API acknowledges
them. A failed flush is a no-op that leaves the buffer intact, because losing
telemetry silently is worse than sending it late.

## Device identity

The matrix needs a device axis, and the FCM token cannot be it: it rotates on
reinstall and clear-data, which would split one phone into several columns — and
`b6_token_refresh` exists specifically to make that happen.

So: a **UUID generated once and persisted locally**, plus an **editable label**
("Pixel 8", "Xiaomi 13"). The UUID keeps rows joinable; the label is what makes a
matrix readable, and no automatic value is as useful as the one a human types when
they know which handset is which.

## The six client hook points

| Event | Hook |
| --- | --- |
| `receivedFg` | `FirebasePushSource`'s foreground stream |
| `receivedBg` | the background handler — **data payloads only**, since a notification-only push never wakes it |
| `displayed` | after `LocalNotificationPresenter.show()` |
| `opened` | the existing notification-tap path |
| `dismissed` | not yet — needs a delete intent |
| `notReceived` | a button on the message the user expected |

The background handler runs in its own isolate, so it writes to the buffer and never
tries to flush: it may be killed at any moment, and a half-completed HTTP request
there loses the event it was trying to save.

## Error handling

| Failure | Behaviour |
| --- | --- |
| API unreachable on flush | Buffer kept, retried later. Never dropped. |
| Duplicate event in a retried batch | Ignored by the idempotency key, not stored twice |
| Event with an unknown `trace_id` | Stored anyway. A hand-made `curl` send has no `queued` row, and refusing its `received_fg` would hide a real delivery. |
| Clock skew between device and server | Not corrected, but `GET /latency` reports both timestamps so a negative latency is visible as skew rather than read as instant delivery |
| SQLite file missing or unwritable | Exit 64 at startup with the reason, matching how a bad key is already handled |

That fourth row is the one worth stating plainly: **a negative latency means the
clocks disagree, not that delivery beat the send.** Silently clamping it to zero
would turn a measurement error into a false result.

## Testing

- The event model round-trips through JSON, and every `TelemetryEventType` has a
  wire name asserted against its literal — a renamed enum value must not silently
  change the wire format both sides agree on.
- The store: an event is recorded, a duplicate is not, and latency is computed from
  a `sent` and a `received_fg` across two devices independently.
- `trace_id` injection: the API adds it, no template contains one beforehand, and
  all 66 still round-trip afterwards.
- The parser treats `trace_id` as reserved, so it does not appear as extra data.
- The client buffer keeps events when a flush fails and deletes them only on
  acknowledgement — driven by a fake sender that fails, then succeeds.
- Negative latency surfaces as skew rather than as zero.

## Out of scope

The report page and CSV export (next spec). BigQuery delivery-data export, which is
console configuration plus a README section rather than code. `dismissed` and the
`opened` state qualifier, both blocked on the interaction sub-project. Any
authentication on `/events` — the endpoint stays loopback-only, and that constraint
is now documented as load-bearing.
