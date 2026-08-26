import 'push_source.dart';
import 'push_tap.dart';

/// A [PushSource] that never emits, substituted for `FirebasePushSource` when
/// Firebase fails to start.
class DisabledPushSource implements PushSource {
  const DisabledPushSource();

  @override
  Stream<Map<String, Object?>> get payloads => const Stream.empty();

  @override
  Stream<PushTap> get taps => const Stream.empty();

  @override
  Future<String?> token() => Future<String?>.value();

  @override
  Future<bool> requestPermission() => Future<bool>.value(false);

  @override
  Future<void> dispose() => Future<void>.value();
}
