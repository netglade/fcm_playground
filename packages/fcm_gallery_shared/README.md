# fcm_gallery_shared

The notification contract shared by `apps/fcm_app` and `apps/fcm_api`.

Pure Dart. It depends on `core` for exactly one thing —
`PushMessageParser.reservedKeys` — so the payload keys the app requires stay
defined in one place and the compiler enforces the agreement.

| Type | Purpose |
| --- | --- |
| `NotificationDraft` | The editable payload: title, body, extra data keys. |
| `NotificationScenario` | A gallery preset. `notificationGallery` holds them all. |
| `SendNotificationRequest` | `POST /send`'s body. Serialises flat: `{token, title, body, data}`. |
| `SendNotificationResponse` | Its 200 body: `{messageId, id, sentAt}`. |
| `ApiError` | Its non-2xx body: `{error, field?}`. |
| `NotificationDraftValidator` | The one validation, run by both sides. |
