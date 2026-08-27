import 'package:fcm_gallery_shared/src/message/message.dart';
import 'package:fcm_gallery_shared/src/send_target.dart';

/// A request to send a message through the local FCM API.
class SendMessageRequest {
  const SendMessageRequest({
    required this.target,
    required this.message,
    this.validateOnly = false,
    this.scenarioId,
  });

  /// `message` is delegated to [FcmMessage.fromJson], so a malformed message reports
  /// its path and one setting its own target is rejected. The target is read from the
  /// body's *top level*, where FCM's own `oneof` sits, so "no target", "two targets"
  /// and a blank one all report from one place.
  factory SendMessageRequest.fromJson(Map<String, Object?> json) {
    final target = SendTarget.readFrom(json);
    final messageJson = json['message'];
    if (messageJson == null) {
      throw FormatException('"message" is missing');
    }
    if (messageJson is! Map<String, Object?>) {
      throw FormatException(
        '"message" must be an object, got ${messageJson.runtimeType}',
      );
    }
    final message = FcmMessage.fromJson(messageJson);
    final validateOnly = json['validate_only'] as bool? ?? false;

    return SendMessageRequest(
      scenarioId: json['scenario_id'] as String?,
      target: target,
      message: message,
      validateOnly: validateOnly,
    );
  }

  final SendTarget target;

  final FcmMessage message;

  /// Sent so telemetry can group by scenario, and unrecoverable otherwise: the
  /// payload a scenario produces does not identify the scenario. Null for a payload
  /// composed by hand, which is a real case and not an error.
  final String? scenarioId;

  /// Whether to validate the request without actually delivering the message.
  final bool validateOnly;

  /// Always writes `validate_only`, even when false, to capture the caller's explicit
  /// intent. The target is spread at the top level rather than nested, so the body
  /// keeps the shape documented as `POST /send`'s contract in docs/telemetry.md.
  Map<String, Object?> toJson() => {
    ...target.toJson(),
    'scenario_id': ?scenarioId,
    'validate_only': validateOnly,
    'message': message.toJson(),
  };
}
