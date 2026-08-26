import 'package:core/core.dart';

/// The Android channel every notification from this app goes to.
///
/// Importance high is what makes a banner pop instead of landing silently in the
/// tray. The same id is given to FCM in `AndroidManifest.xml`, so the entries it
/// draws while the app is backgrounded are heads-up too.
const notificationChannelId = 'fcm_sample_high';

/// The `data` key that makes a notification undismissable.
///
/// Only the exact string `true` counts. The Sandbox accepts any text a user
/// types, and a typo must not produce a notification they cannot swipe away.
const notificationOngoingKey = 'ongoing';

/// The `data` key naming the group a notification collapses into.
const notificationGroupKey = 'group';

/// The `data` key asking a notification to take over the screen.
///
/// Only the exact string `true` counts, for the same reason
/// [notificationOngoingKey] does. Android 14 and later grant the permission
/// behind this only to calling and alarm apps, so for this gallery the request
/// is expected to be refused — that refusal is what `f8_full_screen_intent`
/// exists to show.
const notificationFullScreenKey = 'full_screen';

/// The integer id `flutter_local_notifications` requires, derived from the payload
/// id so re-showing the same message replaces its banner instead of stacking a
/// second one. Masked to 31 bits because Android's `notify` takes a Java `int`.
int notificationIdFor(String messageId) => messageId.hashCode & 0x7fffffff;

/// The notification id for [message]: its tag when it has one, its message id
/// otherwise.
///
/// The tag is what makes a second send replace the first rather than stacking
/// beside it. FCM already behaves this way for the notifications it draws
/// itself; this is how the app's own drawing agrees with it.
int notificationIdOf(PushMessage message) =>
    notificationIdFor(message.tag ?? message.id);
