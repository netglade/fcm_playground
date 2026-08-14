/// The Android channel every notification from this app goes to.
///
/// Importance high is what makes a banner pop instead of landing silently in the
/// tray. The same id is given to FCM in `AndroidManifest.xml`, so the entries it
/// draws itself while the app is backgrounded use this channel too — without
/// that, only foreground banners would be heads-up.
const notificationChannelId = 'fcm_sample_high';

/// Shown to the user in Android's per-channel notification settings.
const notificationChannelName = 'Sample pushes';

/// Explains the channel in Android's notification settings.
const notificationChannelDescription = 'Pushes received by the FCM sample app.';

/// The integer id `flutter_local_notifications` requires, derived from the
/// payload id.
///
/// Deriving it means re-showing the same message replaces its banner instead of
/// stacking a second one. Masked to 31 bits because Android's `notify` takes a
/// Java `int`, and Dart's `hashCode` is neither bounded to that range nor
/// guaranteed non-negative.
int notificationIdFor(String messageId) => messageId.hashCode & 0x7fffffff;
