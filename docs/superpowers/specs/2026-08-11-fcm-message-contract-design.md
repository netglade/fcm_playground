# FCM Message contract and Scenario rewrite — design

**Date:** 2026-08-11
**Status:** designed, not implemented
**Sub-project:** 1 of 3
**Supersedes parts of:** `2026-08-11-fcm-api-backend-design.md` (the typed draft and
the server-built message)

## Why this is one of three

The request bundled three features. They are being designed and built separately
so each produces something working on its own:

| Spec | Scope |
| --- | --- |
| **1 — this one** | The typed FCM v1 `Message` model, the `Scenario` rewrite, the raw-payload endpoint, and a JSON-editor Sandbox |
| 2 | Delayed sending: acting on `requiresKilledApp` and `defaultDelaySeconds` |
| 3 | The nested collapsible form over the whole `Message` model |

Spec 1 comes first because both of the others build on the payload shape it
defines. After it, every gallery scenario can be fired at a device as a real raw
FCM payload; Spec 3 makes those payloads editable field by field.

## Goal

Replace the app's own invented payload shape with **FCM's actual `Message`
model**, typed, and rewrite `Scenario` to the model from the FCM playground Notion
page — so a scenario is an FCM payload template rather than a title and a body.

## Decisions

| Decision | Choice | Why |
| --- | --- | --- |
| Model fidelity | Type the whole `Message` model now | Spec 3's form needs something to bind to, and a typed model means a malformed template fails locally naming the field instead of as an opaque FCM 400. |
| `Scenario.payloadTemplate` | Stays a raw `Map<String, dynamic>` | It is the *authoring* format: paste-able straight from Google's REST docs. The typed model is what it parses *into*. Raw → typed → raw round-tripping is the property the tests pin. |
| Unknown fields | **Rejected**, naming the field and its path | Catches typos immediately, which is what a playground is for. The cost is accepted: an FCM field we have not modelled is unusable until the model is updated. |
| Wire casing | **snake_case**, as the REST reference shows | A template lifted from the docs round-trips to the same text. FCM accepts both spellings, so this is a choice about which one we emit. |
| Free-form islands | `data`, `android.data`, `apns.headers`, `apns.payload`, `webpush.headers`, `webpush.data`, `webpush.notification` pass through untouched | Reject-unknown applies to objects with a fixed schema. These are maps whose keys are user-defined *by API definition* — rejecting unknown keys in them would be wrong. |
| Apple's `aps` | **Not typed in Spec 1** | `apns.payload` is free-form per the API, so any APNs payload is already writable. Typing `aps` under reject-loudly would hard-fail on any new Apple key with no escape hatch. Spec 3 decides whether to offer a structured sub-form. |
| Model location | Inside `packages/fcm_gallery_shared` | Chosen over a separate package; one fewer workspace member to wire up. |
| Content language | English throughout | Consistent with every other string in the repo, unlike the Notion page's Czech examples. |
| Unparseable arrivals | Relax `core`'s parser | `title` and `body` become optional so a data-only push appears in the inbox instead of being counted as malformed. |
| Sandbox in Spec 1 | Grouped gallery + raw JSON editor | The existing title/body/data form no longer describes what is sent. The JSON editor is not a stopgap — it stays as the escape hatch after Spec 3, and it is where a reject-loudly parse error becomes visible. |

## Precondition: a DCM configuration change

`analysis_options.yaml` sets `number-of-parameters: 5`, excluded only under
`test/**`. `AndroidNotification` has **27** fields and `Scenario` has **9**;
neither can be written under that limit.

These are data classes mirroring someone else's API — the parameter count is the
shape of the thing being mirrored, not a design smell. `metrics-exclude` therefore
gains the model directory and the scenario file:

```yaml
  metrics-exclude:
    - test/**
    - packages/fcm_gallery_shared/lib/src/message/**
    - packages/fcm_gallery_shared/lib/src/scenario.dart
```

The limit stays in force everywhere logic lives. Raising it globally was
considered and rejected.

## Architecture

```
packages/core
  PushMessage, PushMessageParser (title/body relaxed), PushMessageFormatException
        ↑
packages/fcm_gallery_shared
  src/message/          the typed FCM v1 Message model, 16 files
  src/scenario.dart     Scenario + scenarioGallery
  src/send_message_request.dart   {token, validate_only, message}
  src/send_message_response.dart  {messageId, sentAt}
  src/api_error.dart              unchanged
        ↑                                    ↑
apps/fcm_app                          apps/fcm_api
  SandboxController                     sendMessage handler
  └── grouped gallery + JSON editor     injects the target, forwards the rest
```

**Deleted by this spec:** `NotificationDraft`, `NotificationDraftValidator`,
`DraftProblem`, `NotificationScenario`, `apps/fcm_api`'s `NotificationMessage`,
and the app's `SandboxForm`, `DataEntryRow` and `ScenarioPicker`.

`DraftProblem` goes too. Nothing in Spec 1 produces one — parse failures are
`FormatException`s carrying a path — so keeping it would be dead code held for a
spec that may not want it in that shape. Spec 3 can introduce whatever
field-problem type its form actually needs.

## The typed model

`packages/fcm_gallery_shared/lib/src/message/`, one public type per file to
satisfy `prefer-match-file-name`.

### Classes

| File | Type | Fields |
| --- | --- | --- |
| `fcm_message.dart` | `FcmMessage` | `data`, `notification`, `android`, `webpush`, `apns`, `fcmOptions` |
| `fcm_notification.dart` | `FcmNotification` | `title`, `body`, `image` |
| `android_config.dart` | `AndroidConfig` | `collapseKey`, `priority`, `ttl`, `restrictedPackageName`, `data`, `notification`, `fcmOptions`, `directBootOk` |
| `android_notification.dart` | `AndroidNotification` | the 27 below |
| `light_settings.dart` | `LightSettings` | `color`, `lightOnDuration`, `lightOffDuration` |
| `light_color.dart` | `LightColor` | `red`, `green`, `blue`, `alpha` |
| `apns_config.dart` | `ApnsConfig` | `headers`, `payload`, `fcmOptions` |
| `webpush_config.dart` | `WebpushConfig` | `headers`, `data`, `notification`, `fcmOptions` |
| `fcm_options.dart` | `FcmOptions` | `analyticsLabel` |
| `apns_fcm_options.dart` | `ApnsFcmOptions` | `image`, `analyticsLabel` |
| `webpush_fcm_options.dart` | `WebpushFcmOptions` | `link`, `analyticsLabel` |
| `android_message_priority.dart` | enum | `NORMAL`, `HIGH` |
| `android_notification_priority.dart` | enum | `PRIORITY_UNSPECIFIED`, `PRIORITY_MIN`, `PRIORITY_LOW`, `PRIORITY_DEFAULT`, `PRIORITY_HIGH`, `PRIORITY_MAX` |
| `notification_visibility.dart` | enum | `VISIBILITY_UNSPECIFIED`, `PRIVATE`, `PUBLIC`, `SECRET` |
| `notification_proxy.dart` | enum | `PROXY_UNSPECIFIED`, `ALLOW`, `DENY`, `IF_PRIORITY_LOWERED` |
| `json_object_reader.dart` | `JsonObjectReader` | the strict reader |

**Three `fcm_options` types, not one.** The generic one carries only
`analytics_label`; APNs adds `image`; WebPush adds `link`. Collapsing them into
one class would let a field through on a platform that does not accept it.

`AndroidNotification`'s 27 fields: `title`, `body`, `icon`, `color`, `sound`,
`tag`, `clickAction`, `bodyLocKey`, `bodyLocArgs`, `titleLocKey`, `titleLocArgs`,
`channelId`, `ticker`, `sticky`, `eventTime`, `localOnly`, `notificationPriority`,
`defaultSound`, `defaultVibrateTimings`, `defaultLightSettings`,
`vibrateTimings`, `visibility`, `notificationCount`, `lightSettings`, `image`,
`bypassProxyNotification`, `proxy`.

`Message.name` is omitted: it is output-only and never sent.

Every class is immutable with `==`, `hashCode` and `toJson`. Fields are nullable
and a null field is **absent** from the output, never `null` — FCM treats an
explicit null as a value in some positions.

Two exceptions, both because the API requires them: `LightSettings`' `color`,
`lightOnDuration` and `lightOffDuration` are non-null, as are all four of
`LightColor`'s components. A `light_settings` object missing any of them is a parse
error like any other.

**Durations and timestamps stay `String`.** `ttl`, `lightOnDuration`,
`lightOffDuration`, `vibrateTimings` and `eventTime` are proto duration and
timestamp strings (`"3.5s"`, `"2026-08-11T09:30:00Z"`). Parsing them into
`Duration` and `DateTime` would break round-trip fidelity — `"3.5s"` and `"3.500s"`
are the same duration but not the same text, and this model's contract is that a
template comes back out as it went in. Validating their format is Spec 3's problem,
where a form field can offer a picker.

### Enums

Each carries a `wireName` and a `fromWireName` returning null for an unrecognised
value, the same shape the project already uses. An unrecognised enum value in a
template is a parse error, consistent with reject-loudly — it is
indistinguishable from a typo.

### `JsonObjectReader`

Rejecting unknown fields is only useful if the error says *where*, so parsing goes
through one reader that tracks a path and reports what nobody claimed:

```dart
final reader = JsonObjectReader(json, path: 'message.android.notification');
final title = reader.text('title');
final sticky = reader.flag('sticky');
final count = reader.integer('notification_count');
final args = reader.textList('body_loc_args');
final extras = reader.stringMap('data');
final payload = reader.freeForm('payload');
final light = reader.object('light_settings', LightSettings.read);
final proxy = reader.enumValue('proxy', NotificationProxy.values);
reader.requireNothingUnclaimed();
```

`requireNothingUnclaimed()` throws `FormatException` naming every key not read:

```
message.android.notification: unknown field "titel"
```

A wrong-typed value is the same kind of failure, with the same path:

```
message.android.priority: expected a string, got int
```

Each class exposes `static T read(JsonObjectReader)` alongside
`factory T.fromJson(Map<String, dynamic>)`, so nested objects compose without
each one re-deriving its path.

## `Scenario`

Replaces `NotificationScenario`, matching the Notion model field for field:

```dart
class Scenario {
  const Scenario({
    required this.id,
    required this.group,
    required this.title,
    required this.description,
    required this.payloadTemplate,
    this.expectation,
    this.requiresKilledApp = false,
    this.defaultDelaySeconds = 0,
    this.tags = const [],
  });

  final String id;                            // 'big_picture_remote'
  final String group;                         // 'Appearance'
  final String title;
  final String description;                   // what should happen, what to watch
  final String? expectation;                  // 'On Xiaomi the image may not appear'
  final Map<String, dynamic> payloadTemplate; // FCM v1 message, without a target
  final bool requiresKilledApp;               // Spec 2 forces a delayed send
  final int defaultDelaySeconds;              // Spec 2
  final List<String> tags;                    // ['android', 'ios', 'image']
}
```

`requiresKilledApp` and `defaultDelaySeconds` are **carried but inert** in Spec 1.
They are in the model now so Spec 2 adds behaviour rather than re-opening the
contract, and the Sandbox displays `requiresKilledApp` as a hint so the field is
not silently meaningless.

### The gallery

`const scenarioGallery` holds nine scenarios across four groups, chosen to cover
different axes rather than nine variations of one:

| Group | id | Exercises |
| --- | --- | --- |
| Appearance | `big_picture_remote` | `notification.image` |
| Appearance | `coloured_icon` | `android.notification.icon`, `color` |
| Appearance | `custom_channel` | `android.notification.channel_id` = `fcm_sample_high` |
| Delivery | `high_priority` | `android.priority: HIGH` |
| Delivery | `normal_priority_long_ttl` | `android.priority: NORMAL`, `android.ttl` |
| Delivery | `collapsible` | `android.collapse_key` |
| Data | `data_only` | `data` with no `notification` — the silent path, `requiresKilledApp: true` |
| Data | `notification_and_data` | both blocks together |
| iOS | `apns_alert` | `apns.payload.aps`, `apns.headers` |

Every template is authored in snake_case so it reads as the FCM docs do.

## The endpoint

```
POST /send
{ "token": "e…",
  "validate_only": false,
  "message": { "notification": {"title": "…"}, "android": {"priority": "HIGH"} } }

200 { "messageId": "projects/p/messages/0:17…", "sentAt": "2026-08-11T09:12:03.000Z" }
```

`SendMessageRequest` carries `token`, `validateOnly` and an `FcmMessage`.
`SendMessageResponse` carries `messageId` and `sentAt` — the moment the server
sent it.

**Validation reduces to two local rules**, both cheaper to catch here than as an
FCM 400: the message must parse, and it must not already set `token`, `topic` or
`condition`, because the server owns the target.

`validate_only` is forwarded to FCM as the `validateOnly` field of its request
envelope, so nothing is delivered and the payload is still checked by Google.

### What this costs

The old response carried a `payloadId` that matched the arriving inbox row, which
made the round trip visible. That property **goes away**: the payload is now
yours, so the server no longer invents `id`, `title`, `body` and `sentAt` data
keys. A scenario that wants the correlation can put an `id` of its own in `data`.
This is a real loss in observability and is accepted as the price of sending real
FCM payloads.

## Relaxing `core`'s parser

`PushMessageParser` currently requires four non-blank data keys. `title` and
`body` become optional, defaulting to `''`; `id` and `sentAt` stay required, and
`remoteMessageToPayload` always supplies both from FCM metadata.

So a data-only push now appears in the inbox as a row with empty text and its data
keys visible, instead of incrementing the malformed counter.

**Consequence to document:** `PushInbox.rejections` becomes nearly unreachable —
only a corrupt stored payload can trigger it. The counter stays, because a corrupt
store is exactly when you want to know, but the README must stop describing it as
an expected outcome.

`PushMessage.title` and `.body` therefore stop being guaranteed non-empty. Their
doc comments say so, and `MessageTile` shows a muted placeholder rather than a
blank row.

## Branch relationship

This is implemented on `feature/fcm-message-contract`, branched from **`main`** at
`03dad2f` — deliberately *not* from `feature/notification-display`, whose work is
complete but unmerged. So `MessageDetailPage`, `PushPayloadStore`,
`NotificationPresenter` and `remoteMessageToPayload` do not exist here, and this
spec must not assume them. The app baseline is 49 tests, not 108.

Three files are edited by both branches and will conflict on merge. All three are
textual rather than structural:

| File | This branch | `feature/notification-display` |
| --- | --- | --- |
| `apps/fcm_app/lib/main.dart` | new sender and controller wiring | store, presenter and tap-stream wiring |
| `apps/fcm_app/lib/ui/message_tile.dart` | placeholder for a blank title | an `onTap` callback |
| `README.md` | payload and scenario sections | a Notifications section |

Whichever merges second resolves them. Worth knowing now so neither branch is
surprised, and worth re-checking before merging rather than assuming this list is
still complete.

## The Sandbox

```
AppBar: Sandbox                                          ☰
──────────────────────────────────────────────────────────
▾ Appearance
    Big picture (server-side)          android · ios · image
    Sends an image in the notification block.
    ⚠ On Xiaomi the image may not appear
    ─────────────────────────────────────────────
▸ Delivery
▸ Data
▸ iOS
──────────────────────────────────────────────────────────
Payload                                    ☐ validate only
┌────────────────────────────────────────────────────────┐
│ {                                                       │
│   "notification": {                                     │
│     "title": "Build finished",                          │
│     "image": "https://…/build.png"                      │
│   },                                                    │
│   "android": { "priority": "HIGH" }                     │
│ }                                                       │
└────────────────────────────────────────────────────────┘
message.android.notification: unknown field "titel"
──────────────────────────────────────────────────────────
                 [ Send to this device ]
✓ Sent · projects/p/messages/0:17…
```

Groups are collapsible (`ExpansionTile`), which is also the first step toward
Spec 3's nested collapsing. Selecting a scenario writes its template into the
editor as formatted JSON.

`SandboxController` holds: the selected scenario id, the editor's text, the parse
result (an `FcmMessage` or a `FormatException` message), the `validateOnly` flag,
and the send state. Send is disabled while the text does not parse, and the parse
error renders under the editor. The editor's `TextEditingController` stays in the
view, keyed on the selected-scenario revision — the same mechanism already used
for the current form.

## Error handling

| Cause | Behaviour |
| --- | --- |
| Editor text is not JSON | Parse error under the editor, Send disabled |
| An unknown or wrong-typed field | Same, with the field's full path |
| The message sets `token`/`topic`/`condition` | Same, naming the field and saying the server owns the target |
| Server receives an unparseable message | 400 with the same message the app would have shown |
| FCM rejects the send | Unchanged: `UNREGISTERED` → 404 with its own wording, `INVALID_ARGUMENT` → 400, otherwise 502 |
| `validate_only` succeeds | 200 with FCM's fake message name; the result card says validated, not sent |
| Data-only push arrives | Inbox row with a placeholder title and its data keys |

## Testing

| Unit | What |
| --- | --- |
| `JsonObjectReader` | unknown key rejected with its path; wrong type rejected with its path; free-form and string-map reads; nested path composition |
| Each message class | snake_case round-trip; absent fields stay absent rather than becoming null; unknown field rejected |
| Enums | every wire name maps both ways; an unrecognised value is a parse error |
| Free-form islands | `apns.payload`, `webpush.notification` and every `data` map survive round-trip unchanged, including keys the model knows nothing about |
| Target rule | a template setting any of the three targets is rejected |
| `scenarioGallery` | unique ids; every template parses, round-trips, and sets no target; every group non-blank; `data_only` really has no `notification` |
| `SendMessageRequest`/`Response` | round-trips including `validate_only` |
| `apps/fcm_api` | the token is injected into the outgoing message; `validate_only` is forwarded; an unparseable message answers 400 with the path |
| `core` parser | blank `title`/`body` now accepted; blank `id` still rejected; unparseable `sentAt` still rejected; every existing test still passes |
| `apps/fcm_app` | a scenario loads into the editor; a parse error renders and disables Send; Send posts the parsed message; the result card distinguishes validated from sent; groups collapse |

## Verification

- `fvm dart run melos run ci` green
- `fvm flutter build apk --debug` and `fvm flutter build web --release` succeed
- With the API running: `validate_only: true` on every gallery scenario returns
  200, which proves all nine templates are payloads FCM actually accepts — this is
  the cheapest real check available and needs no device
- On a device: `big_picture_remote` shows an image, `data_only` arrives silently
  and appears in the inbox with empty text and its data keys

The `validate_only` sweep is the item worth most here: it turns "the model
round-trips" into "Google accepts what we emit", and no unit test can do that.

## Deliberately out of scope

- Delayed sending, `requiresKilledApp`, `defaultDelaySeconds` behaviour — Spec 2
- The nested collapsible form, and whether `aps` gets typed — Spec 3
- Topic and condition targeting: the server owns the target
- `Message.name`, which is output-only
- Any change to the notification display work on `feature/notification-display`
