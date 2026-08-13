import 'push_source.dart';

/// A [PushSource] that never emits.
///
/// Substituted for `FirebasePushSource` when Firebase fails to start, so the
/// rest of the app can be built and navigated without special-casing a null
/// source.
class DisabledPushSource implements PushSource {
  const DisabledPushSource();

  @override
  Stream<Map<String, Object?>> get payloads => const Stream.empty();

  @override
  Stream<String> get taps => const Stream.empty();

  @override
  Future<String?> token() => Future<String?>.value();

  @override
  Future<bool> requestPermission() => Future<bool>.value(false);

  @override
  Future<void> dispose() => Future<void>.value();
}
