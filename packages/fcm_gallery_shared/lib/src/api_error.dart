import 'json_field.dart';

/// The body of every non-2xx answer from the send API.
///
/// Shared so the app parses failures with the same type the server produced them
/// with, rather than guessing at a shape at the moment things are already wrong.
class ApiError {
  const ApiError(this.message, {this.field});

  /// Parses an error response body, preserving the message even if the field is
  /// malformed — a parsing failure in the field must not prevent showing the
  /// error that the user needs to know.
  factory ApiError.fromJson(Map<String, dynamic> json) {
    final field = json['field'];

    return ApiError(
      requireText(json['error'], 'error'),
      field: field is String ? field : null,
    );
  }

  /// Human-readable, and safe to show as-is.
  final String message;

  /// The request field at fault, when there is one — the JSON path of the
  /// unknown or invalid field in the send request.
  final String? field;

  /// Serialises to the wire shape `{error, field?}`, omitting the field key
  /// when null.
  Map<String, dynamic> toJson() => {'error': message, 'field': ?field};
}
