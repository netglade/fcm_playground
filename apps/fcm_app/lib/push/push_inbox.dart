import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter/foundation.dart';

import 'push_repository.dart';

/// The widget tree's view of [PushRepository].
///
/// All the state lives in the repository, which is app-scoped: this is only the
/// adapter that turns its [PushRepository.changes] stream into the
/// [ChangeNotifier] the current pages listen to, and forwards what they read.
/// Every getter delegates rather than caching a snapshot, so a tap outstanding
/// against a message that has not arrived is answered from what is held at the
/// moment of the read.
class PushInbox extends ChangeNotifier {
  PushInbox(this._repository) {
    _subscription = _repository.changes.listen((_) => notifyListeners());
  }

  final PushRepository _repository;
  late final StreamSubscription<PushInboxState> _subscription;

  /// Why push is unavailable, or `null` when everything started cleanly.
  String? get setupError => _repository.setupError;

  /// Received messages, newest first.
  List<PushMessage> get messages => _repository.messages;

  /// Payloads that failed validation, oldest first.
  List<String> get rejections => _repository.rejections;

  /// The device's registration token once it has resolved.
  String? get token => _repository.token;

  /// Whether a notification tap is waiting to be acted on.
  bool get hasPendingOpen => _repository.hasPendingOpen;

  /// The message a tap asked to open, or null when there is no tap outstanding
  /// or its message is not held.
  PushMessage? get pendingOpen => _repository.pendingOpen;

  /// Asks the shell to open the message with [id].
  void requestOpen(String id) => _repository.requestOpen(id);

  /// Called by the shell once it has navigated, so it does not navigate twice.
  void clearPendingOpen() => _repository.clearPendingOpen();

  /// Merges anything the background isolate appended since the last drain.
  Future<void> drainPending() => _repository.drainPending();

  @override
  void dispose() {
    // Cancelled rather than left running: this adapter is rebuilt with the page
    // while the repository is not, so a leaked subscription accumulates one
    // listener per page.
    unawaited(_subscription.cancel());
    super.dispose();
  }
}
