# Telemetry

*"Push feels slow on Xiaomi"* is an impression. *"Median 4m12s on Xiaomi,
1.1s on Pixel, same payload, same minute"* is a measurement. Telemetry is
what turns one into the other: every send gets a trace id, both the API and
the app record events against it as things happen to that message, and the
two together let a delay be attributed to a device instead of shrugged at.

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

## Ten events, recorded on both sides

`queued`, `sent`, and `send_failed` come from the API — the last carrying
FCM's own error code, which is what turns a hundred scattered failures into
three grouped causes. Everything else comes from the device: `received_fg`
and `received_bg` mark which of the app's states the push arrived in;
`displayed` fires only once a notification has actually been drawn, never
before; `opened` records a tap and which state it came from; `action` and
`dismissed` are Android-only, for reasons that mirror the ones in
[notifications.md](./notifications.md); and `not_received` is the one event
a human asserts, pressed from the Sandbox after sending, for the case where
silence is the only evidence there is.

Device-side events buffer locally and flush to the API, and are deleted only
once the API confirms it has them — never as a blanket clear, since that
would drop whatever arrived during a partial flush.

## The two tabs

The Telemetry page (drawer → Telemetry) is where all of this surfaces. The
Events tab lists every trace with its ten rows, arrived or not, so a blank
row is information rather than an absence. The Latency tab draws the
`scenario × device` matrix implied by the intro above, built from every pair
of a `sent` and a `received_*` event that share a trace. Neither tab polls —
a push's arrival is reported by the device, not discovered by this page — so
a refresh button is how either one grows.

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
