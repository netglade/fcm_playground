/// Where one scheduled send has got to.
///
/// [dispatching] is not an implementation detail leaking out: it is the state a
/// claimed item sits in while the server awaits FCM, and it is what makes an
/// interrupted dispatch recoverable rather than guessed at.
enum RunItemState {
  /// Waiting for its due time. The only state a cancel may touch.
  pending('pending'),

  /// Claimed by the scheduler and on its way to FCM. Past the point of cancelling.
  dispatching('dispatching'),

  sent('sent'),

  /// FCM refused it, or the server stopped mid-dispatch and the telemetry says it
  /// never left. The reason is in `error`.
  failed('failed'),

  cancelled('cancelled'),

  /// Due while the server was down, and by more than the grace period. Shown as
  /// itself rather than as an absence: "the server did not get to it" and "nothing
  /// happened" are different answers.
  missed('missed');

  const RunItemState(this.wireName);

  /// The string the database, the API and the app agree on. Renaming one is a
  /// migration, not an edit.
  final String wireName;

  /// Refuses an unknown name rather than defaulting: a hand-edited row or a newer
  /// client saying `done` must fail loudly, not become `pending`.
  static RunItemState fromWireName(String wireName) {
    for (final state in values) {
      if (state.wireName == wireName) {
        return state;
      }
    }

    throw FormatException('"state" has unknown value "$wireName"');
  }

  /// Whether an item in this state is still waiting for something to happen to it.
  ///
  /// Lives here rather than beside any one caller: the server asks it to find the
  /// runs worth sweeping, the app asks it to decide whether a run is done, and a
  /// shared summary asks it to find the next due time — three packages, one of
  /// them the server, all needing the same answer. Written once so they cannot
  /// drift apart.
  bool get isOutstanding =>
      this == RunItemState.pending || this == RunItemState.dispatching;
}
