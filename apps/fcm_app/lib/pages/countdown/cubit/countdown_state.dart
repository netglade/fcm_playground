/// What the countdown is showing.
class CountdownState {
  const CountdownState({
    required this.remainingSeconds,
    this.isFinished = false,
    this.isCancelled = false,
    this.error,
  });

  /// Counted on this device's clock rather than against the server's `due_at`.
  ///
  /// The two clocks disagree in this project as a matter of record — `GET /latency`
  /// reports both timestamps rather than clamping — and a countdown run against a
  /// clock ten seconds ahead would show "40 s remaining" with thirty seconds left.
  /// Measuring latency and counting seconds at a person are different jobs, and only
  /// the first can tolerate a foreign clock.
  final int remainingSeconds;

  /// The delay has elapsed. The send is the server's business from here.
  final bool isFinished;

  final bool isCancelled;

  /// Why the cancel did not happen, or null.
  final String? error;

  CountdownState copyWith({
    int? remainingSeconds,
    bool? isFinished,
    bool? isCancelled,
    String? error,
  }) => CountdownState(
    remainingSeconds: remainingSeconds ?? this.remainingSeconds,
    isFinished: isFinished ?? this.isFinished,
    isCancelled: isCancelled ?? this.isCancelled,
    error: error ?? this.error,
  );

  @override
  bool operator ==(Object other) =>
      other is CountdownState &&
      remainingSeconds == other.remainingSeconds &&
      isFinished == other.isFinished &&
      isCancelled == other.isCancelled &&
      error == other.error;

  @override
  int get hashCode =>
      Object.hash(remainingSeconds, isFinished, isCancelled, error);
}
