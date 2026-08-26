import 'package:core/core.dart';

import '../../../domains/push/pressed_action.dart';

/// What the inbox holds, as one immutable snapshot. `PushRepository` publishes
/// it and `InboxCubit`'s state *is* it.
///
/// Deliberately not value-equal: `Cubit.emit` drops a state equal to the current
/// one, so an `==` here would swallow updates the screen needs — and it could
/// not be written honestly anyway, since `List`'s `==` is identity.
class InboxState {
  const InboxState({
    required this.messages,
    required this.rejections,
    required this.token,
    required this.setupError,
    required this.pendingOpenId,
    required this.pressedActions,
    required this.replies,
  });

  /// Received messages, newest first.
  final List<PushMessage> messages;

  /// Payloads that failed validation, oldest first.
  final List<String> rejections;

  final String? token;

  final String? setupError;

  /// The message id a notification tap is waiting on, if any.
  final String? pendingOpenId;

  /// The action pressed on each message's notification, keyed by message id.
  ///
  /// Not folded into [PushMessage]: it is not something the sender said, and a
  /// message the app never drew a notification for has no entry at all.
  final Map<String, PressedAction> pressedActions;

  /// The reply text the user typed into each message's notification, keyed by
  /// message id.
  ///
  /// Not folded into [PushMessage] for the same reason as [pressedActions]: it
  /// is not something the sender said, and a message nobody replied to has no
  /// entry at all.
  final Map<String, String> replies;

  /// True as soon as the tap arrives, whether or not [pendingOpen] can resolve
  /// it: the shell selects the inbox on this, which is the fallback for an id
  /// that never will resolve.
  bool get hasPendingOpen => pendingOpenId != null;

  /// The message a tap asked to open, or null when there is no tap outstanding
  /// or this snapshot does not hold its message.
  ///
  /// Scanned rather than stored, so the tap and the payload need not arrive in
  /// any particular order — the two come from different streams.
  PushMessage? get pendingOpen {
    final id = pendingOpenId;
    if (id == null) {
      return null;
    }

    for (final message in messages) {
      if (message.id == id) {
        return message;
      }
    }

    return null;
  }
}
