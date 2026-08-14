import 'package:core/core.dart';

/// What the inbox holds, as one immutable snapshot.
///
/// One class for both halves of the split: `PushRepository` publishes it and
/// `InboxCubit`'s state *is* it. A second, parallel snapshot type would mean the
/// repository builds one that the cubit throws away to build an identical one.
///
/// Published rather than a bare "something changed" tick so a watcher cannot
/// read half of one update and half of the next. The tap is carried as an **id**
/// in [pendingOpenId], not as a resolved message: the message it names may not
/// have arrived yet, and resolving it against [messages] *in the same snapshot*
/// — which is what [pendingOpen] does — is what makes a tap that precedes its
/// payload work.
///
/// **Deliberately not value-equal**, for the reason `SandboxState` has none:
/// `Cubit.emit` drops a state equal to the current one, so an `==` here would
/// swallow updates the screen needs. And it could not be written honestly
/// anyway — [messages] and [rejections] are `List`s, whose `==` is identity, so
/// a value-equality attempt would compare two fresh lists as unequal while
/// looking as though it had compared their contents.
class InboxState {
  const InboxState({
    required this.messages,
    required this.rejections,
    required this.token,
    required this.setupError,
    required this.pendingOpenId,
  });

  /// Received messages, newest first.
  final List<PushMessage> messages;

  /// Payloads that failed validation, oldest first.
  final List<String> rejections;

  /// The device's registration token, once it has resolved.
  final String? token;

  /// Why push is unavailable, or null when it is.
  final String? setupError;

  /// The message id a notification tap is waiting on, if any.
  final String? pendingOpenId;

  /// Whether a notification tap is waiting to be acted on.
  ///
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
