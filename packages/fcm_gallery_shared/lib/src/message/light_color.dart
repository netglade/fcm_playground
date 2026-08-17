import 'json_object_reader.dart';

/// An RGBA colour for an Android device's notification LED. All four components are
/// required, because FCM rejects a colour that does not fully specify them.
class LightColor {
  const LightColor({
    required this.red,
    required this.green,
    required this.blue,
    required this.alpha,
  });

  factory LightColor.fromJson(Map<String, Object?> json) =>
      read(JsonObjectReader(json, path: 'color'));

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

  /// From 0 to 1, as are [green], [blue] and [alpha].
  final double red;

  final double green;

  final double blue;

  final double alpha;

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
