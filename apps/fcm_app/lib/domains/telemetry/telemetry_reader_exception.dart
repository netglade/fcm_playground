import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';

/// Telemetry that could not be read, with a message written for the person holding the
/// phone.
///
/// Its own type rather than `RunSchedulerException`: a different domain, and having
/// `domains/telemetry` reach into `domains/runs` for an exception would couple them for
/// the sake of a dozen lines.
class TelemetryReaderException implements Exception {
  const TelemetryReaderException(this.message);

  factory TelemetryReaderException.fromApiError(ApiError error) =>
      TelemetryReaderException(error.message);

  /// Shown in the UI as-is.
  final String message;

  @override
  String toString() => message;
}
