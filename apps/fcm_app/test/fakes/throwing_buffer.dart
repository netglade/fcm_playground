import 'package:fcm_app/domains/telemetry/entities/telemetry_buffer.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';

/// A buffer where every operation fails, as a corrupt or full database does.
///
/// It keeps what it was [attempted] with before throwing, so a test can tell "the
/// reporter swallowed a real failure" from "the reporter never tried".
class ThrowingBuffer implements TelemetryBuffer {
  /// Every event [add] was called with, failure included.
  final List<TelemetryEvent> attempted = [];

  @override
  Future<void> add(TelemetryEvent event) async {
    attempted.add(event);

    throw StateError('the buffer database is unavailable');
  }

  @override
  Future<List<PendingEvent>> pending({int limit = 200}) async =>
      throw StateError('the buffer database is unavailable');

  @override
  Future<void> forget(List<PendingEvent> events) async =>
      throw StateError('the buffer database is unavailable');
}
