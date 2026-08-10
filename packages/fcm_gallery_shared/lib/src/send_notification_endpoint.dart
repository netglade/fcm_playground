/// The `sendNotification` callable's identity, in both forms it is known by.
///
/// `apps/fcm_functions` registers the function under [registeredName], and
/// `apps/fcm_app` calls the deployed service by [deployedId] — two different
/// strings related by a transformation neither package performs itself.
/// Holding both here, next to the doc comment that explains the relationship,
/// means there is exactly one place to look, and one place to fix, if they
/// are ever renamed.
///
/// `abstract final` rather than a plain top-level constant: it groups the pair
/// under one name at the call site (`SendNotificationEndpoint.deployedId`
/// rather than a bare, easily-shadowed `sendNotificationDeployedId`), and
/// gives the file a public type for `prefer-match-file-name` to anchor to.
abstract final class SendNotificationEndpoint {
  /// The name passed to `firebase.https.onCall` in `register_functions.dart`,
  /// and the identifier `apps/fcm_functions` declares the function under.
  static const registeredName = 'sendNotification';

  /// The id of the deployed Cloud Run service, and the name `apps/fcm_app`
  /// passes to `FirebaseFunctions.httpsCallable`.
  ///
  /// `firebase_functions` derives this from [registeredName] via its
  /// `toCloudRunId` sanitiser when it builds `functions.yaml`: a camelCase
  /// registered name becomes a kebab-case deployed id. That transformation
  /// happens at build time, not at run time, so the two constants below are
  /// equal by convention only — nothing in this package enforces the relation
  /// at compile time, which is what `send_notification_endpoint_test.dart`
  /// exists to check instead.
  static const deployedId = 'send-notification';
}
