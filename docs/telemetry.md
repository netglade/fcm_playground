# Telemetry

*"Push feels slow on Xiaomi"* is an impression. *"Median 4m12s on Xiaomi,
1.1s on Pixel, same payload, same minute"* is a measurement. Telemetry is
what turns one into the other: every send gets a trace id, both the API and
the app record events against it as things happen to that message, and the
two together let a delay be attributed to a device instead of shrugged at.

## What the API answers

`apps/fcm_api` exposes nine routes: `POST /send` for one push; `POST /runs`,
`GET /runs`, `GET /runs/<id>` and `DELETE /runs/<id>` for a delayed batch;
`POST /events` and `GET /events` for telemetry; `GET /latency` for the
matrix below; `GET /health`. A send names exactly one delivery target —
`token`, `topic`, `condition`, or `all_devices`, refused with a 501 until a
device registry exists to fan a send out over — and its `message` is parsed
strictly: an unknown key is rejected naming its own JSON path, so a typo in a
hand-edited payload fails loudly instead of being silently dropped.

`POST /events` takes a batch, all-or-nothing: one malformed event is a 400
that stores none of it, since a buffering client cannot tell which half of a
partial success to keep. `recorded` counts only events newly stored, so a
lost acknowledgement (`200` with `0`) reads differently from a lost flush
(nothing recorded). The idempotency key is `(trace_id, type, device_id)`,
excluding `at` on purpose, so a retry can move a duplicate's recorded time
earlier but never pass as a second event. `?limit=` on `GET /events` is
bounded to 1–2000; outside that is a 400 naming the parameter, not a silent
fallback. Both sides normalise every timestamp to UTC, and an arrival for a
trace the server never sent — a push made by hand — is stored but produces
no latency row, since there is nothing to measure it against.

## Where the trace id comes from

The API mints the trace id, not the app, and writes it into the payload's own
`data.trace_id` before forwarding it to FCM — `trace_id` and a companion
`scenario_id` are reserved keys the app's parser strips back out rather than
showing as ordinary payload data. That has to happen server-side for a
concrete reason: the API is the only party present for the three events that
happen before the push exists on any device at all — accepting the request,
handing it to FCM, and finding out whether FCM accepted it back. A send made
by hand with `curl`, bypassing the Sandbox entirely, gets a trace id the same
way a scenario's own send does, which is also why none of the catalogue's
templates carry one baked in — a template with its own `trace_id` would
collide with the one the API assigns on every send.

## The loopback bind is load-bearing

Being the sole party present for those events also makes `POST /events` an
unauthenticated *write* into a queryable store — a different risk from a
stateless relay that just forwards a send. Binding to loopback rather than
`0.0.0.0` is the only thing standing between anyone on the network and two
things: forging arrivals for any trace, which corrupts the measurements
this pipeline exists to produce rather than merely spending someone's FCM
quota, and reading every trace, device id and label back out through
`GET /latency`. There is no second layer behind that bind — widening it for
convenience removes the only protection this data has.

## Ten events, recorded on both sides

`queued`, `sent`, and `send_failed` come from the API — the last carrying
FCM's own error code, which is what turns a hundred scattered failures into
three grouped causes. Everything else comes from the device: `received_fg`
and `received_bg` mark which of the app's states the push arrived in;
`displayed` fires only once a notification has actually been drawn, never
before; `opened` records a tap and which state it came from; `action` and
`dismissed` are Android-only, for the reason action buttons in general are —
see [notifications.md](./notifications.md#what-a-person-can-do-to-a-notification);
and `not_received` is the one event a human asserts, pressed from the
Sandbox after sending, for the case where silence is the only evidence there
is.

Device-side events buffer locally and flush to the API, and are deleted only
once the API confirms it has them — never as a blanket clear, since that
would drop whatever arrived during a partial flush.

## The two tabs

The Telemetry page (drawer → Telemetry) is where all of this surfaces. The
Events tab lists every trace with its ten rows, arrived or not, so a blank
row is drawn neutrally rather than as a failure — most absences are correct,
not a sign that anything went wrong. The most common blank pair is also the
easiest to misread: an ordinary notification-only push arriving while the app
is backgrounded produces neither `received_bg` nor `displayed`, because
nothing wakes the app's own code for a bare notification block outside the
foreground (see [notifications.md](./notifications.md)). Two blank device
rows there are the push behaving exactly as it should, not a reason to press
`not_received`.

The Latency tab draws the `scenario × device` matrix implied by the intro
above, built from every pair of a `sent` and a `received_*` event that share
a trace. Neither tab polls — a push's arrival is reported by the device, not
discovered by this page — so a refresh button is how either one grows.

**The load-bearing caveat sits under the Latency tab itself:** `sent` is when
the API received the send request, not when FCM answered it, so every figure
in the matrix includes however long the FCM call itself took. A number that
looks slow may be measuring FCM's own latency rather than the device's.

A negative figure shows up as itself rather than as zero — clamping it would
turn a clock disagreement between two machines into a false result, and one
implausible "1ms" would be reason to doubt every other number in the matrix
too.

## What this can't tell you

Nothing here can say whether a message that never arrived was dropped by
Google or never left the handset — the device's own telemetry ends at the
network, and FCM's begins there. FCM's own delivery data, exported to
BigQuery from the Firebase console, is the independent source for that
question, and worth turning on before trusting either side's numbers over
the other's when they disagree.
