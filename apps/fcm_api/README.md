# fcm_api

One endpoint that sends a push through FCM, so the Sandbox page in `fcm_app` has
something to talk to.

```
POST /send   {<target>, validate_only, message}  →  200 {messageId, sentAt}
GET  /health                                     →  200 {"status": "ok"}
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

**This is a development tool.** It has no authentication and binds `127.0.0.1`,
so it is reachable only from the machine it runs on. Binding it to `0.0.0.0`
would expose an open relay to whatever network it sits on — do not deploy it as
is.

See the root `README.md` for how to run it.
