import 'json_object_reader.dart';

/// An RGBA colour for an Android device's notification LED.
///
/// Android's `LightSettings.color`. All four components are required because
/// FCM rejects a light colour that does not fully specify them.
class LightColor {
  /// Creates a colour, requiring every component since FCM does the same.
  const LightColor({
    required this.red,
    required this.green,
    required this.blue,
    required this.alpha,
  });

  /// Reads FCM's `Color` object.
  factory LightColor.fromJson(Map<String, Object?> json) =>
      read(JsonObjectReader(json, path: 'color'));

  /// Reads from an existing reader, so a parent composes the path rather than
  /// each class inventing its own.
  static LightColor read(JsonObjectReader reader) {
    final red = reader.number('red');
    final green = reader.number('green');
    final blue = reader.number('blue');
    final alpha = reader.number('alpha');
    reader.requireNothingUnclaimed();
    if (red == null || green == null || blue == null || alpha == null) {
      throw FormatException(
        'color: red, green, blue and alpha are all required, '
        'and one or more was missing',
      );
    }

    return LightColor(red: red, green: green, blue: blue, alpha: alpha);
  }

  /// The red component, from 0 to 1.
  final double red;

  /// The green component, from 0 to 1.
  final double green;

  /// The blue component, from 0 to 1.
  final double blue;

  /// The alpha (opacity) component, from 0 to 1.
  final double alpha;

  /// Serialises to FCM's `Color` shape. Every field is required, so nothing
  /// is ever omitted.
  Map<String, Object?> toJson() => {
    'red': red,
    'green': green,
    'blue': blue,
    'alpha': alpha,
  };

  @override
  bool operator ==(Object other) =>
      other is LightColor &&
      red == other.red &&
      green == other.green &&
      blue == other.blue &&
      alpha == other.alpha;

  @override
  int get hashCode => Object.hash(red, green, blue, alpha);
}
