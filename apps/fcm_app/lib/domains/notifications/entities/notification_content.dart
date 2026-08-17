/// The Android channel every notification from this app goes to.
///
/// Importance high is what makes a banner pop instead of landing silently in the
/// tray. The same id is given to FCM in `AndroidManifest.xml`, so the entries it
/// draws while the app is backgrounded are heads-up too.
const notificationChannelId = 'fcm_sample_high';

const notificationChannelName = 'Sample pushes';

const notificationChannelDescription = 'Pushes received by the FCM sample app.';

/// The integer id `flutter_local_notifications` requires, derived from the payload
/// id so re-showing the same message replaces its banner instead of stacking a
/// second one. Masked to 31 bits because Android's `notify` takes a Java `int`.
int notificationIdFor(String messageId) => messageId.hashCode & 0x7fffffff;
