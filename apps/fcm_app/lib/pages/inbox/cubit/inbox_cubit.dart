import 'dart:async';

import 'package:fcm_app/domains/push/push.dart';
import 'package:fcm_app/pages/inbox/cubit/inbox_state.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The widget tree's projection of [PushRepository]. Its state *is* what the
/// repository publishes; everything worth testing stays app-scoped there.
///
/// Constructed by the widget that owns it, never registered in the locator: a
/// cubit there outlives its page and carries the previous page's state into the
/// next one.
class InboxCubit extends Cubit<InboxState> {
  /// The initial state is read rather than defaulted, because the repository has
  /// usually been running since before the first frame — `main()` drives
  /// `restore()` and `refreshToken()` before `runApp`, and a setup error is set
  /// in the constructor and never published at all.
  InboxCubit(this._repository) : super(_repository.state) {
    _subscription = _repository.changes.listen(emit);
  }

  final PushRepository _repository;
  late final StreamSubscription<InboxState> _subscription;

  void requestOpen(String id, OpenedFrom from) =>
      _repository.requestOpen(id, from);

  void clearPendingOpen() => _repository.clearPendingOpen();

  Future<void> drainPending() => _repository.drainPending();

  @override
  Future<void> close() {
    // This cubit is rebuilt with its page while the app-scoped repository is
    // not, so a leaked subscription adds one listener per page — each calling
    // `emit` on a closed cubit, which throws.
    unawaited(_subscription.cancel());

    return super.close();
  }
}
