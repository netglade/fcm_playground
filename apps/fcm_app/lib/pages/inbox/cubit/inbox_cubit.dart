import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'inbox_state.dart';
import 'push_repository.dart';

/// The widget tree's projection of [PushRepository].
///
/// Thin on purpose, and thin in a specific way: its state *is* what the
/// repository publishes, so there is no snapshot built here that the repository
/// did not already build. Everything worth testing — the ordering, the
/// de-duplication, the cap, the persistence, the telemetry — is app-scoped and
/// stays in the repository, because a push arrives whichever tab is showing and
/// the token must outlive the page. This is only the part that would otherwise
/// duplicate it.
///
/// Constructed by the widget that owns it, never registered in the locator: a
/// cubit there outlives its page and carries the previous page's state into the
/// next one. The repository is the singleton; this is per page.
class InboxCubit extends Cubit<InboxState> {
  /// Projects [repository], starting from what it already holds.
  ///
  /// The initial state is read rather than defaulted, because the repository is
  /// app-scoped and has usually been running since before the first frame:
  /// `main()` drives `restore()` and `refreshToken()` before `runApp`, and a
  /// setup error is set in the constructor and never published at all. A blank
  /// initial state would blank the banner and the token until the next push.
  InboxCubit(this._repository) : super(_repository.state) {
    _subscription = _repository.changes.listen(emit);
  }

  final PushRepository _repository;
  late final StreamSubscription<InboxState> _subscription;

  /// Asks the shell to open the message with [id].
  void requestOpen(String id) => _repository.requestOpen(id);

  /// Called by the shell once it has navigated, so it does not navigate twice.
  void clearPendingOpen() => _repository.clearPendingOpen();

  /// Merges anything the background isolate appended since the last drain.
  Future<void> drainPending() => _repository.drainPending();

  @override
  Future<void> close() {
    // Cancelled rather than left running: this cubit is rebuilt with its page
    // while the app-scoped repository is not, so a leaked subscription adds one
    // listener per page — each one calling `emit` on a closed cubit, which
    // throws.
    unawaited(_subscription.cancel());

    return super.close();
  }
}
