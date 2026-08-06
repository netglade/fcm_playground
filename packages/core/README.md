# core

Platform-independent domain logic for the FCM sample app.

This package deliberately depends on nothing but `dart:core` — no Flutter, no
Firebase — so everything in it runs under plain `dart test`.

| Type | Purpose |
| --- | --- |
| `PushMessage` | Immutable, already-validated message. If one exists, it is well-formed. |
| `PushMessageParser` | Turns a flat FCM `data` map into a `PushMessage`. |
| `PushMessageFormatException` | Names the field that failed validation and why. |

Required payload keys are `id`, `title`, `body` and `sentAt` (ISO-8601, normalised
to UTC). Every other key is passed through in `PushMessage.data`.

```dart
final message = const PushMessageParser().parse({
  'id': 'msg-1',
  'title': 'Build finished',
  'body': 'Release 1.0.0 is ready.',
  'sentAt': '2026-08-06T09:30:00Z',
  'deepLink': '/builds/42',
});

message.data; // {'deepLink': '/builds/42'}
```

Run the tests from the repo root with `fvm dart run melos run test:core`.
