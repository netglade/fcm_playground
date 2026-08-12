# The FCM payload form — design

**Date:** 2026-08-11
**Status:** designed, not implemented
**Sub-project:** 3 of 3
**Builds on:** `2026-08-11-fcm-message-contract-design.md` (implemented)
**Replaces:** the raw JSON editor that spec shipped as an interim

## Goal

Replace the Sandbox's JSON text field with **nested, collapsible forms** covering
every property of an FCM v1 `Message`, built with
[`glade_forms`](https://pub.dev/packages/glade_forms).

The typed model already exists — this spec is about editing it, not defining it.

## Decisions

| Decision | Choice | Why |
| --- | --- | --- |
| Package | `glade_forms ^6.0.0` | Asked for by name. Published as `glade_forms`, not `netglade_forms`. |
| Composition | **One `GladeModel` per FCM object**, composed by hand — ten of them | `GladeModel`'s input list is flat, and `GladeComposedModel` handles *lists of one* sub-model type rather than a heterogeneous tree. Ten models mirroring the ten typed classes 1:1 keeps each one small and each mapping mechanical. |
| Optional bools | **Tristate**, via `GladeInput<bool?>.optional` | FCM distinguishes absent from `false`, and the typed model encodes that. A two-state checkbox cannot express "absent", so it would silently send fields the user never set. |
| Optional strings/ints | Empty text means absent | Same reason. `''` is never sent as a value. |
| Free-form islands | **Dotted-path key/value rows** | `apns.payload` and `webpush.notification` are free-form by API definition. Flat string rows could not express `aps.alert.title` or a numeric `badge`; a dotted path can, while staying rows rather than a JSON field. |
| JSON escape hatch | **Removed entirely** | Explicitly asked for. Consequence recorded below. |
| Scenario handoff | Populates the models | `applyScenario` stops writing text and starts filling inputs. |

## Architecture

```
ScenariosView  ──tap──▶  applyScenario  ──▶  populates the models
                                                     │
SandboxView                                          ▼
└── FcmMessageForm            data · notification · fcm_options      ▾
    ├── FcmNotificationForm   title · body · image                   ▾
    ├── AndroidConfigForm     collapse_key · priority · ttl · …       ▾
    │   ├── AndroidNotificationForm   27 fields                      ▾
    │   │   └── LightSettingsForm     colour + two durations         ▾
    │   └── FcmOptionsForm            analytics_label                ▾
    ├── ApnsConfigForm        headers rows · payload path-rows        ▾
    │   └── ApnsFcmOptionsForm        image · analytics_label         ▾
    └── WebpushConfigForm     headers · data · notification rows      ▾
        └── WebpushFcmOptionsForm     link · analytics_label          ▾
```

Each form is a `GladeModel` plus a widget wrapping it in an `ExpansionTile`, so
collapsing is per-object and nests to the depth FCM does. The page owns the set of
models; `isValid` is the conjunction of theirs.

Ten forms, because `LightColor`'s four components are edited inline in
`LightSettingsForm` rather than getting a form of their own — they are always
required together and never make sense apart.

Every model exposes the same pair, against the typed class it mirrors:

```dart
  void readFrom(AndroidNotification? source);   // null clears every input
  AndroidNotification? toModel();               // null when nothing is set
```

`toModel()` returning null when every input is empty is what keeps an untouched
`android` block out of the payload entirely, rather than sending `"android": {}`.

## `glade_forms` specifics that shape the code

Read from the published API rather than assumed, because three of its defaults are
the opposite of what this use case wants:

| Fact | Consequence |
| --- | --- |
| `GladeStringInput` defaults `isRequired: true` | **Every** optional FCM string must pass `isRequired: false`. Missing it on one field of ~50 makes the form permanently invalid until that field is filled. |
| `GladeStringInput` defaults `useTextEditingController: true` | Strings get a `.controller` for free. |
| `GladeIntInputNullable` defaults `useTextEditingController: false` | Int fields must pass `true` to bind a `TextFormField`. |
| `GladeBoolInput` is `GladeInput<bool>` | Cannot hold null, so it is unusable for FCM's optional bools. Use `GladeInput<bool?>.optional(value: null)` instead. |
| `GladeInput.updateValue(T value)` | How non-text controls (tristate checkbox, dropdown, rows) write back. |
| `input.controller`, `input.formFieldValidator` | How text fields bind. |

Each input gets an explicit `inputKey` equal to its FCM JSON path
(`android.notification.channel_id`), so a failing validation is traceable to a
field and the DevTools extension is readable.

## Field controls

| FCM shape | Count | Control |
| --- | --- | --- |
| `String?` | ~50 | `GladeStringInput(isRequired: false)` → `TextFormField` |
| `int?` | 1 | `GladeIntInputNullable(useTextEditingController: true)` |
| `bool?` | 7 | `GladeInput<bool?>.optional` → **tristate** `Checkbox` |
| enum | 4 | dropdown whose first entry is "not set" (null) |
| `List<String>?` | 3 | add/remove string rows |
| `Map<String,String>?` | 5 | flat key/value rows |
| free-form map | 2 | **dotted-path** key/value rows |
| `double` (required) | 4 | `GladeInput<double>.required` — `LightColor`'s components, the only non-nullable fields in the model |
| nested object | 10 | a collapsible subform, absent until opened and populated |

### The dotted-path rows

A row is a path and a scalar. `aps.alert.title` → `Build finished`,
`aps.badge` → `1`, `aps.content-available` → `1`.

- On the way **out**, paths expand into nested maps and values are parsed
  leniently: `true`/`false` become bools, an integer literal becomes an `int`,
  everything else stays a string. That is what makes `badge: 1` reachable.
- On the way **in**, a nested map flattens back into paths, so a scenario's
  `apns.payload` becomes editable rows and round-trips unchanged.
- A path segment containing a literal `.` is not expressible. FCM and Apple use no
  such keys, and the alternative — an escaping syntax — would be worse than the
  limitation. Documented, not solved.

### Validation

`glade_forms`' fluent validators, only where FCM has a real rule: duration strings
(`3600s`, `3.5s`) on `ttl` and the light/vibrate timings, `#rrggbb` on
`android.notification.color`, and URL shape on the image and link fields. Anything
FCM itself decides is left to FCM, so the form never refuses a payload the server
would accept.

## What is removed

`PayloadEditor` and its JSON text field, `SandboxController.payloadText`,
`editPayload` and `parseError`. Send becomes gated on the models' `isValid`
instead of a parse result.

**One consequence, recorded because it is a real loss.** With no escape hatch, a
payload can only contain fields the form models. All nine scenario templates are
fully modelled today — Spec 1's reject-loudly parsing guarantees it, and its
round-trip test proves it — so nothing breaks now. But a newly added FCM field
would need a form field before it could be sent, where previously it could be
typed. That is the accepted price of removing the JSON field.

## Error handling

| Cause | Behaviour |
| --- | --- |
| A field fails a validator | `TextFormField` shows the message; the containing sections stay expandable so the field is reachable |
| A section is invalid while collapsed | Its `ExpansionTile` shows an error badge, so an invalid field cannot hide behind a collapsed header |
| A dotted-path row has a blank path | That row is dropped on the way out rather than producing an empty key |
| Two rows share a path | The later wins, and the row shows a duplicate warning |
| Nothing is set in a block | `toModel()` returns null and the block is omitted from the payload |
| The scenario carries a field the form lacks | Cannot happen today; would surface as a dropped field, so a test asserts every gallery template survives a form round trip |

## Testing

The models are plain `ChangeNotifier`s, so most of this needs no widget pump.

| Unit | What |
| --- | --- |
| Each of the ten models | `readFrom` then `toModel` returns an equal object; an untouched model returns null; clearing one field omits exactly that key |
| Tristate bools | absent, `true` and `false` are three distinguishable outcomes, and absent stays out of the JSON |
| Enum dropdowns | "not set" maps to null; each wire name round-trips |
| Dotted-path rows | `aps.alert.title` expands to a nested map; `badge: 1` becomes an `int`; a nested payload flattens back to the same rows |
| String maps and list rows | add, remove, round-trip |
| Validators | a bad duration and a bad colour are rejected; a valid one is not |
| **The gallery invariant** | for all nine scenarios: `readFrom(template)` → `toModel()` equals the template. This is the test that proves the form covers every field actually shipped, and it is the direct successor to Spec 1's round-trip test |
| Widget | a section expands; an invalid collapsed section shows its badge; a tristate cycles through three states; Send is disabled while any model is invalid |

## Verification

- `melos run ci` green; `flutter build apk --debug` and `build web --release` succeed
- The gallery invariant passes for all nine scenarios
- With the API running: `validate_only` on a form-built payload for each scenario
  returns 200 — the same sweep Spec 1 defined, now proving the *form* produces
  payloads FCM accepts, not just the model
- On a device: build `big_picture_remote` from the form and confirm the image
  arrives; set `direct_boot_ok` to each of its three states and confirm the sent
  payload omits it only when unset

## Scope

~80 fields, ten models, four nesting levels, both mapping directions. Expect
15–18 plan tasks — the largest of the three sub-projects. Deliberately one spec:
half a form is not shippable.

## Deliberately out of scope

- Delayed sending (`requiresKilledApp`, `defaultDelaySeconds`) — still Spec 2
- Typing Apple's `aps` as a schema: it stays dotted-path rows, per the decision above
- Topic and condition targeting: the server owns the target
- Any change to `packages/core` or `apps/fcm_api`
