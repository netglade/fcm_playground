import 'json_field.dart';
import 'message/fcm_message.dart';

/// A request to send a message through the local FCM API.
///
/// The caller provides the delivery target ([token]) and the message content
/// ([message]); [validateOnly] controls whether to actually deliver it.
class SendMessageRequest {
  /// Creates a request to send a message.
  const SendMessageRequest({
    required this.token,
    required this.message,
    this.validateOnly = false,
  });

  /// Parses a request body, reading `message` by delegating to [FcmMessage.fromJson]
  /// so that a malformed message reports its path rather than failing opaquely,
  /// and so that a message setting its own target is rejected.
  factory SendMessageRequest.fromJson(Map<String, Object?> json) {
    final token = requireText(json['token'], 'token');
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
      token: token,
      message: message,
      validateOnly: validateOnly,
    );
  }

  /// The device token to deliver the message to.
  final String token;

  /// The message content to send.
  final FcmMessage message;

  /// Whether to validate the request without actually delivering the message.
  ///
  /// Always written to the wire, even when false, to preserve the caller's
  /// explicit intent — a reader seeing it absent should not have to guess.
  final bool validateOnly;

  /// Serialises the request, always writing `validate_only` even when false
  /// to capture the caller's explicit intent.
  Map<String, Object?> toJson() => {
    'token': token,
    'validate_only': validateOnly,
    'message': message.toJson(),
  };
}
