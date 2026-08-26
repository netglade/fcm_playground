import 'package:fcm_app/domains/telemetry/device_identity.dart';

/// An identity that answers with one id, or refuses to answer at all.
///
/// The real one reaches the platform store, which can fail — a `clear data` in
/// flight, an unavailable plugin — and [FixedDeviceIdentity.failing] is how a
/// test reaches the reporter's promise that a hook survives that.
class FixedDeviceIdentity implements DeviceIdentity {
  /// An install whose id is [_id].
  const FixedDeviceIdentity(this._id);

  /// An install whose id cannot be read.
  const FixedDeviceIdentity.failing() : _id = null;

  final String? _id;

  @override
  Future<String> id() async {
    final id = _id;
    if (id == null) {
      throw StateError('the platform store is unavailable');
    }

    return id;
  }

  @override
  Future<String> label() async => 'test handset';

  @override
  Future<void> setLabel(String label) async =>
      throw UnsupportedError('no test sets a label through the reporter');
}
