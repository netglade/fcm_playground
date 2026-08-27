import 'package:fcm_app/pages/sandbox/forms/fcm_notification_form.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:glade_forms/glade_forms.dart';

/// Edits `android.notification.light_settings` — the notification LED's colour
/// and blink timings.
///
/// The only form in this set whose fields FCM *requires*: if the block is present
/// at all, FCM demands a colour with all four components and both durations. So
/// [toModel] cannot compare against an empty instance the way the other forms do
/// — there is none. It returns a value only when every field is set.
class LightSettingsForm extends GladeModel {
  /// Red component, 0.0–1.0.
  late GladeInput<double?> red;

  late GladeInput<double?> green;

  late GladeInput<double?> blue;

  late GladeInput<double?> alpha;

  /// A proto duration such as `1s`.
  late GladeStringInput lightOnDuration;

  late GladeStringInput lightOffDuration;

  @override
  List<GladeInput<Object?>> get inputs => [
    red,
    green,
    blue,
    alpha,
    lightOnDuration,
    lightOffDuration,
  ];

  /// This form alone — see `FcmMessageForm.allModels`.
  List<GladeModelBase> get allModels => [this];

  @override
  void initialize() {
    red = _component('red');
    green = _component('green');
    blue = _component('blue');
    alpha = _component('alpha');
    lightOnDuration = GladeStringInput(
      inputKey: 'android.notification.light_settings.light_on_duration',
      isRequired: false,
    );
    lightOffDuration = GladeStringInput(
      inputKey: 'android.notification.light_settings.light_off_duration',
      isRequired: false,
    );
    super.initialize();
  }

  /// Fills the inputs from [source], clearing them when it is null.
  void readFrom(LightSettings? source) {
    red.updateValue(source?.color.red);
    green.updateValue(source?.color.green);
    blue.updateValue(source?.color.blue);
    alpha.updateValue(source?.color.alpha);
    lightOnDuration.updateValue(source?.lightOnDuration ?? '');
    lightOffDuration.updateValue(source?.lightOffDuration ?? '');
  }

  /// The block as FCM's own model, or null unless every field is set.
  LightSettings? toModel() {
    final redValue = red.value;
    final greenValue = green.value;
    final blueValue = blue.value;
    final alphaValue = alpha.value;
    final on = emptyMeansAbsent(lightOnDuration.value);
    final off = emptyMeansAbsent(lightOffDuration.value);

    if (redValue == null ||
        greenValue == null ||
        blueValue == null ||
        alphaValue == null ||
        on == null ||
        off == null) {
      return null;
    }

    return LightSettings(
      color: LightColor(
        red: redValue,
        green: greenValue,
        blue: blueValue,
        alpha: alphaValue,
      ),
      lightOnDuration: on,
      lightOffDuration: off,
    );
  }
}

/// One colour component, read from text and bounded to FCM's 0.0–1.0 range.
///
/// The converter maps empty or unparseable text to null rather than keeping the
/// previous value, which glade's own nullable converter does — a cleared
/// component would otherwise still reach the payload. `.create` rather than
/// `.optional`, because `.optional` accepts no validator.
GladeInput<double?> _component(String name) => GladeInput<double?>.create(
  inputKey: 'android.notification.light_settings.color.$name',
  value: null,
  useTextEditingController: true,
  stringToValueConverter: StringToTypeConverter<double?>(
    converter: (raw, _) =>
        (raw == null || raw.trim().isEmpty) ? null : double.tryParse(raw),
    converterBack: (value) => value?.toString() ?? '',
  ),
  validator: (validator) =>
      (validator..satisfy(
            // Null passes: an unset component is absent rather than invalid, and
            // toModel is what refuses a half-filled block.
            (value) => value == null || (value >= 0 && value <= 1),
            devMessage: (_) => 'must be between 0.0 and 1.0',
          ))
          .build(),
);
