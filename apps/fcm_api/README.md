# fcm_api

One endpoint that sends a push through FCM, so the Sandbox page in `fcm_app` has
something to talk to.

```
POST /send   {token, title, body, data?}  →  200 {messageId, id, sentAt}
GET  /health                              →  200 {"status": "ok"}
```

`id` and `sentAt` are stamped by the server, so the response and the delivered
payload cannot drift, and the message is guaranteed to satisfy
`PushMessageParser` in `packages/core`.

**This is a development tool.** It has no authentication and binds `127.0.0.1`,
so it is reachable only from the machine it runs on. Binding it to `0.0.0.0`
would expose an open relay to whatever network it sits on — do not deploy it as
is.

See the root `README.md` for how to run it.
