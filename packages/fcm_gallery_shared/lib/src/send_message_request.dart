import 'message/fcm_message.dart';
import 'send_target.dart';

/// A request to send a message through the local FCM API.
///
/// The caller provides the delivery target ([target]) and the message content
/// ([message]); [validateOnly] controls whether to actually deliver it.
class SendMessageRequest {
  /// Creates a request to send a message.
  const SendMessageRequest({
    required this.target,
    required this.message,
    this.validateOnly = false,
  });

  /// Parses a request body, reading `message` by delegating to [FcmMessage.fromJson]
  /// so that a malformed message reports its path rather than failing opaquely,
  /// and so that a message setting its own target is rejected.
  ///
  /// The target is read by [SendTarget.readFrom] from the body's *top level*,
  /// which is where FCM's own `oneof` sits, so "no target", "two targets" and a
  /// blank one all report from one place.
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
      target: target,
      message: message,
      validateOnly: validateOnly,
    );
  }

  /// Where the message should be delivered.
  final SendTarget target;

  /// The message content to send.
  final FcmMessage message;

  /// Whether to validate the request without actually delivering the message.
  ///
  /// Always written to the wire, even when false, to preserve the caller's
  /// explicit intent — a reader seeing it absent should not have to guess.
  final bool validateOnly;

  /// Serialises the request, always writing `validate_only` even when false
  /// to capture the caller's explicit intent.
  ///
  /// The target is spread at the top level rather than nested, so the body keeps
  /// the shape FCM uses and every `curl` example in the README still applies.
  Map<String, Object?> toJson() => {
    ...target.toJson(),
    'validate_only': validateOnly,
    'message': message.toJson(),
  };
}
