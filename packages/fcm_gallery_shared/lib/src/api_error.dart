import 'package:fcm_gallery_shared/src/json_field.dart';

/// The body of every non-2xx answer from the send API, shared so the app parses
/// failures with the same type the server produced them with.
class ApiError {
  const ApiError(this.message, {this.field});

  /// Preserves the message even if the field is malformed: a parse failure there
  /// must not stop the error the user needs from being shown.
  factory ApiError.fromJson(Map<String, dynamic> json) {
    final field = json['field'];

    return ApiError(
      requireText(json['error'], 'error'),
      field: field is String ? field : null,
    );
  }

  /// Human-readable, and safe to show as-is.
  final String message;

  /// The JSON path of the unknown or invalid field, when there is one.
  final String? field;

  Map<String, dynamic> toJson() => {'error': message, 'field': ?field};
}
