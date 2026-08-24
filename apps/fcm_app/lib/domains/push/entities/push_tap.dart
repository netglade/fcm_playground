import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';

/// A notification tap: which message, and which app state it was tapped from.
///
/// The state is knowable only at the source — `getInitialMessage` means the tap started
/// the process, `onMessageOpenedApp` means the app was already running, and a tap the
/// plugin reports is a banner drawn while the app was on screen. Carrying it as far as
/// `PushRepository` is the whole reason this type exists; a bare id cannot say which.
class PushTap {
  const PushTap(this.id, this.from, {this.actionId});

  /// The message id the notification carried.
  final String id;

  final OpenedFrom from;

  /// The action button that was pressed, or null for a tap on the body.
  ///
  /// Only notifications this app drew can carry buttons, so this is always null
  /// for a tap FCM reported.
  final String? actionId;

  @override
  bool operator ==(Object other) =>
      other is PushTap &&
      id == other.id &&
      from == other.from &&
      actionId == other.actionId;

  @override
  int get hashCode => Object.hash(id, from, actionId);

  @override
  String toString() =>
      'PushTap($id, ${from.wireName}${actionId == null ? '' : ', $actionId'})';
}
