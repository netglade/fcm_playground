import 'package:fcm_api/fcm_api.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';

/// An [FcmSender] that reads a [TelemetryStore] at the moment it is called.
///
/// The only way to show that `queued` was recorded *before* FCM was asked to
/// deliver: afterwards, a store written to twice at the end looks exactly like
/// one written to before and after the call, because the events are stamped from
/// one clock reading and read back in the order they were written.
///
/// A file of its own because `prefer-match-file-name` is fatal here and applies
/// to tests as well — `metrics-exclude` covers the metrics, not the rules.
class StoreReadingFcmSender implements FcmSender {
  StoreReadingFcmSender(this._store);

  final TelemetryStore _store;

  /// Everything the store held when [send] ran.
  List<TelemetryEvent> eventsWhenCalled = const [];

  @override
  Future<String> send(Map<String, Object?> message) async {
    eventsWhenCalled = await _store.all();

    return 'projects/p/messages/0:17';
  }
}
