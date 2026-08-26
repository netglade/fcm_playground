# Architecture

This repository is a Dart pub workspace, not a single Flutter project. The root
`pubspec.yaml` declares three members under `workspace:` — `apps/fcm_app`,
`apps/fcm_api`, `packages/fcm_gallery_shared` — and holds no application code
of its own; it exists only to give the three members one shared dependency
resolution and one place to configure `melos`, `fvm` and DCM once instead of
per package. That root is the fourth piece: every command in this repo, from
`fvm dart run melos run --no-select ci` down, runs against it rather than
against any one member.

`apps/fcm_app` is the Flutter app that receives the pushes. `apps/fcm_api` is a
plain `shelf` HTTP server — `dart run`, not a Cloud Function — that sends them,
and it is a separate process rather than a function inside the app because
sending a push needs a service-account credential, and that credential must
never ship inside something installed on a phone. `packages/fcm_gallery_shared`
is pure Dart with no Flutter dependency, holding what the app and the API have
to agree on — FCM's own typed `Message` model, the scenario catalogue's
payload templates, and the `/send` and `/events` wire types — so both sides
import one definition of each instead of keeping two in sync by hand.

## Domains and pages

Inside `apps/fcm_app/lib`, `domains/` and `pages/` are the two top-level
splits, and the question "where does a new file go" is answered by what the
file needs to exist. A domain — `notifications`, `push`, `runs`, `sandbox`,
`settings`, `telemetry` — holds the state and behaviour that outlives any one
screen: a model, a store, an interface, and the classes that implement it.
None of it imports a page, and none of it needs a `BuildContext`. A page is one
destination of the app's drawer — Inbox, Scenarios, Sandbox, Runs, Telemetry —
or a screen pushed over one, and holds the widgets and the cubit that turn a
domain's state into pixels for that one screen and feed taps back into it. A
file that would still make sense with no UI attached belongs in a domain; a
file that exists only because one screen needs it belongs in that screen's
page.

## Every data source has an interface, and a twin that does nothing

`apps/fcm_app/lib/di/service_locator.dart` builds every long-lived collaborator
exactly once, before the first frame, and registers each of them behind an
interface rather than a concrete class. `PushSource` is the clearest case:
`FirebasePushSource` wraps `firebase_messaging`, and a widget test hands the
same interface a fake instead — never the real plugin — which is why the
widget suite never touches Firebase. On a device, the locator tries to start
Firebase and catches what that throws; a fresh clone still holds placeholder
credentials in `firebase_options.dart`, so the first run always fails that
attempt and falls back to `DisabledPushSource`, whose streams never emit
anything at all. The app opens with a banner explaining what to run, instead of crashing
on an initialisation that cannot succeed.

The fallback repeats under two more names for two more reasons. A `silent_`
class, such as `SilentNotificationPresenter`, answers every call by doing
nothing, and is what a test gets by default when it registers no real
collaborator at all. An `unavailable_` class, such as
`UnavailableRunScheduler`, refuses every call with the same setup error that
made Firebase fail — scheduling or sending a push needs a registration token
only a working `PushSource` can produce, so there is nothing honest left for
it to do. Between them, the three prefixes are what let this app start up with
no Firebase project configured at all, rather than requiring one to reach the
first frame.

## Testing without a Firebase project

`push_message.dart`, `push_message_format_exception.dart`,
`push_message_parser.dart` and `notification_action.dart`, all in
`apps/fcm_app/lib/domains/push`, import nothing but `dart:core`, so the rules
for what makes a payload valid run under `melos run test:core` — plain
`dart test`, no widget, no Flutter binding, no device. `melos run test:app`
(`flutter test`) covers everything Flutter-shaped, and Firebase itself is
never started there either: `apps/fcm_app/test/fakes/fake_push_source.dart`
implements `PushSource` in memory and is what a test hands to the code under
test, the same way `DisabledPushSource` is what a real device falls back to.
`apps/fcm_app/test/di/service_locator_test.dart` drives
`configureDependencies` itself with placeholder credentials and checks that it
falls back exactly as a fresh clone does. `apps/fcm_api` tests the same way,
under `test:core`, so its FCM v1 payload construction and status mapping are
checked without a service-account credential either.
