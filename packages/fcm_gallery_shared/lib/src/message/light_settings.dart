import 'json_object_reader.dart';
import 'light_color.dart';

/// How Android should flash a device's notification LED. All three fields are
/// required, because FCM rejects light settings that do not fully specify them.
class LightSettings {
  const LightSettings({
    required this.color,
    required this.lightOnDuration,
    required this.lightOffDuration,
  });

  factory LightSettings.fromJson(Map<String, Object?> json) =>
      read(JsonObjectReader(json, path: 'light_settings'));

  static LightSettings read(JsonObjectReader reader) {
    final color = reader.object('color', LightColor.read);
    final lightOnDuration = reader.text('light_on_duration');
    final lightOffDuration = reader.text('light_off_duration');
    reader.requireNothingUnclaimed();
    if (color == null || lightOnDuration == null || lightOffDuration == null) {
      throw FormatException(
        'light_settings: color, light_on_duration and light_off_duration are '
        'all required, and one or more was missing',
      );
    }

    return LightSettings(
      color: color,
      lightOnDuration: lightOnDuration,
      lightOffDuration: lightOffDuration,
    );
  }

  final LightColor color;

  /// A proto duration like `"1s"`, kept as text rather than parsed to [Duration]:
  /// `"3.5s"` and `"3.500s"` are the same duration but not the same text, and this
  /// model's contract is round-trip fidelity.
  final String lightOnDuration;

  /// Text, for the same reason as [lightOnDuration].
  final String lightOffDuration;

  Map<String, Object?> toJson() => {
    'color': color.toJson(),
    'light_on_duration': lightOnDuration,
    'light_off_duration': lightOffDuration,
  };

  @override
  bool operator ==(Object other) =>
      other is LightSettings &&
      color == other.color &&
      lightOnDuration == other.lightOnDuration &&
      lightOffDuration == other.lightOffDuration;

  @override
  int get hashCode => Object.hash(color, lightOnDuration, lightOffDuration);
}
