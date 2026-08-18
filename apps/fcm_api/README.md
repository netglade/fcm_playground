# fcm_api

A local HTTP server so the app in `fcm_app` has something to talk to: one route
that sends a push through FCM, four that schedule and manage a delayed run of
sends, and four that collect what became of any of them.

```
POST /send        {<target>, validate_only, message}   →  200 {messageId, sentAt}
POST /runs        {delay_seconds, spacing_seconds,
                    items: [{<target>, message}, …]}    →  201 {run_id, created_at, items}
GET  /runs                                              →  200 [{run_id, item_count, states, …}, …]
GET  /runs/<id>                                         →  200 {run_id, created_at, items}
DELETE /runs/<id>                                       →  200 {"cancelled": <n>}
POST /events      {"events": [<event>, …]}              →  200 {"recorded": <n>}
GET  /events      ?limit=<1..2000>                      →  200 [<event>, …]
GET  /latency                                           →  200 [<latency row>, …]
GET  /health                                            →  200 {"status": "ok"}
```

`message` is FCM's own v1 `Message` object, parsed by `FcmMessage.fromJson` and
forwarded verbatim. `<target>` is exactly one of `token`, `topic`, `condition` or
`all_devices` at the top level, mirroring FCM's own union — the *message* must not
set a target itself and is rejected if it does, so a template pasted out of
Google's reference cannot quietly broadcast. `all_devices` is answered with 501
until there is a token registry to fan out over.

The response carries FCM's `messageId` and the server's send time. It does **not**
carry a payload id: match a send to its arrival with an `id` you put in the
message's own `data` map.

## Telemetry

`POST /events` takes a **batch**, because the app flushes a local buffer and one
request per event would multiply the failure surface by the buffer size:

```json
{"events": [
  {"trace_id": "…", "type": "received_fg", "at": "2026-08-13T09:30:00.000Z",
   "device_id": "…", "scenario_id": "a1_notification_only"}
]}
```

`scenario_id` and `detail` are optional and omitted when absent rather than
written as null. `type` is one of `queued`, `sent`, `send_failed`,
`received_fg`, `received_bg`, `displayed`, `opened`, `dismissed`,
`not_received`; anything else is a 400 rather than a guess.

Every timestamp is UTC, on both sides. A device on local time and a server on
UTC produce a latency out by hours, which reads as a delivery fault rather than
as the clock bug it is.

The batch is **all-or-nothing**: one malformed member is a 400 and stores none of
it, because a client holding a buffer cannot tell which half of a partial success
to keep. `recorded` counts the events that were *newly* stored, so a client whose
acknowledgement was lost can tell a suppressed replay (`200` with `0`) from a
flush that never arrived.

**The idempotency key is `(trace_id, type, device_id)`**, and where a key repeats
the earliest `at` wins. A flush that succeeded server-side but failed to be
acknowledged is retried, and a duplicated `received_fg` would double-count the
one number this pipeline exists to produce. The key deliberately excludes `at`,
so a re-stamped retry can move an arrival earlier but never later. Two devices
receiving one broadcast differ in `device_id`, so they are two rows rather than a
duplicate.

`GET /latency` returns one row per trace and device, pairing `sent` with the
*first* `received_fg` or `received_bg`. A trace with no arrival is **absent**
rather than reported as zero: not-delivered and delivered-instantly are different
states. A negative `received_at - sent_at` means the device's clock disagrees with
the server's, and is reported rather than clamped.

Events are accepted for a trace this server never sent — a push made by hand has
no `queued` row, and refusing its arrival would hide a real delivery. Such an
arrival is stored but produces no latency row, since there is nothing to measure
from.

`GET /events` answers the recent events, newest first, in the same shape `POST /events`
accepts — the app's Telemetry page reads it to show what became of each trace. It is
bounded: `?limit=` defaults to 500 and is capped at 2000, and a value outside that is a
400 naming the parameter rather than a silent fallback to the default.

### `FCM_TELEMETRY_DB`

The events live in a SQLite file so they survive a restart; the delayed and
killed-app scenarios are interesting minutes after the send, and a matrix that
forgot everything on restart would be no matrix.

`FCM_TELEMETRY_DB` names that file. Unset, it defaults to
`fcm-telemetry.sqlite` **beside the service account key** — the two files that
must never be committed then live in one directory. Set but blank is refused
rather than treated as unset, because falling back would put the database
somewhere nobody asked for and the operator would look for their data in the
wrong place. A path that cannot be opened or written exits 64 with the reason,
exactly as a bad key path does: a server that starts and then silently records
nothing is worse than one that refuses to start.

The path is printed at startup, and the file is created if it is not there.

## This is a development tool

It has no authentication and binds `127.0.0.1`, so it is reachable only from the
machine it runs on. Binding it to `0.0.0.0` would expose an open relay to
whatever network it sits on — do not deploy it as is.

**`POST /events` makes that binding load-bearing.** An unauthenticated *write*
endpoint that accumulates a queryable store is a different proposition from a
stateless relay: anyone who can reach it can fabricate arrivals for any trace,
which corrupts the measurements rather than merely spending someone's FCM quota,
and can read every trace, device id and label back out of `GET /latency`. The
loopback bind is the only thing preventing that, and there is no second layer
behind it.

See the root `README.md` for how to run it.
