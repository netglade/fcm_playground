# fcm_gallery_shared

The contract shared by `apps/fcm_app` and `apps/fcm_api`: FCM's own v1 `Message`
model typed in Dart, the scenario catalogue, the `/send` and `/events` envelopes,
and the telemetry vocabulary both sides write.

Pure Dart, and it depends on **nothing but `collection`**. That matters: it is the
one package a Flutter app and a server process can both hold, so every rule in it
is exercised by plain `dart test` with no device, no binding and no credential.

## The typed message

| Type | Purpose |
| --- | --- |
| `FcmMessage` | FCM's `Message`, minus the delivery target and the output-only `name`. |
| `AndroidConfig`, `AndroidNotification` | The Android blocks. `AndroidNotification` has all 27 fields. |
| `ApnsConfig`, `WebpushConfig` | The two platform blocks. Their `payload` and `notification` stay free-form maps, because FCM defines them that way — Apple's `aps` is Apple's. |
| `FcmNotification`, `FcmOptions`, `ApnsFcmOptions`, `WebpushFcmOptions` | The cross-platform notification, and the three non-interchangeable options variants. |
| `LightSettings`, `LightColor` | The only non-nullable types here: FCM requires every field once the block is present. |
| `AndroidMessagePriority`, `AndroidNotificationPriority`, `NotificationVisibility`, `NotificationProxy` | The enums, each carrying FCM's own spelling as `wireName`. |
| `JsonObjectReader` | Reads a block and **rejects an unknown key with its JSON path**, so a typo surfaces as `message.android.notification: unknown field "titel"` rather than being silently dropped. |

The model reads and writes the same snake_case keys FCM's REST API does, so a
payload copied out of Google's reference round-trips through
`FcmMessage.fromJson`/`.toJson()` unchanged. A test asserts that for all 66
catalogue templates.

## The scenario catalogue

| Type | Purpose |
| --- | --- |
| `Scenario` | One catalogue entry: a payload template plus what to watch for. |
| `scenarioGallery` | All 66, in groups A–K. Assembled from `groupA` … `groupK`, one file per group. |
| `ScenarioNeed` | What a scenario still needs before it demonstrates anything. Most values are a planned piece of work, so "which scenarios does the channel work unblock?" is a filter rather than a search. Two are not: `externalApproval` is outside this project's control, and `nativeCode` names something it has decided never to build. |

32 of the 66 work today; the rest name what is missing. That count is
asserted by a test, so the documentation cannot drift from the code.

## The wire envelopes

| Type | Purpose |
| --- | --- |
| `SendMessageRequest` | `POST /send`'s body: a `SendTarget`, `validate_only`, the `message`, and the `scenario_id` telemetry groups by. |
| `SendMessageResponse` | Its 200 body: `{messageId, sentAt, traceId}`. |
| `SendTarget` | A sealed union — `TokenTarget`, `TopicTarget`, `ConditionTarget`, `AllDevicesTarget`. The target lives here rather than in the message, so a template pasted from Google's docs cannot quietly broadcast. |
| `ApiError` | Any non-2xx body: `{error, field?}`. |

## Telemetry

| Type | Purpose |
| --- | --- |
| `TelemetryEvent` | One thing that happened to one message, on either side. `at` is normalised to UTC in the constructor, because a latency computed across a device on local time and a server on UTC is out by hours and reads as a delivery fault. |
| `TelemetryEventType` | The ten events, each with a wire name pinned by test to its literal — a rename would otherwise surface only as telemetry that stops correlating. |
| `LatencyRow` | What `GET /latency` returns. A negative `latency` means the clocks disagree and is reported rather than clamped, because clamping turns a measurement error into a false result. |
