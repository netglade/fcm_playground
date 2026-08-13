import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:glade_forms/glade_forms.dart';

import 'fcm_notification_form.dart';

/// Edits `android.notification.light_settings` — the notification LED's colour
/// and blink timings.
///
/// The only form in this set whose fields FCM **requires**. `LightSettings` and
/// `LightColor` are the sole non-nullable types in the typed model: if the block
/// is present at all, FCM demands a colour with all four components and both
/// durations.
///
/// So [toModel] cannot ask "is anything set?" by comparing against an empty
/// instance the way the other forms do — there is no empty instance. It returns
/// a value only when *every* field is set, and null otherwise. A half-filled
/// block is not a valid payload, and sending one would earn an opaque 400 from
/// FCM instead of a local error the user can see and fix.
class LightSettingsForm extends GladeModel {
  /// Red component, 0.0–1.0.
  late GladeInput<double?> red;

  /// Green component, 0.0–1.0.
  late GladeInput<double?> green;

  /// Blue component, 0.0–1.0.
  late GladeInput<double?> blue;

  /// Alpha component, 0.0–1.0.
  late GladeInput<double?> alpha;

  /// How long the LED stays lit, as a proto duration such as `1s`.
  late GladeStringInput lightOnDuration;

  /// How long it stays dark between blinks, as a proto duration such as `0.5s`.
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

  /// This form alone — it owns no subform.
  ///
  /// The deepest leaf of the traversal `FcmMessageForm.allModels` composes,
  /// three levels below the root. It exists because a nested model's
  /// notification never reaches its parent, so whoever renders the tree has to
  /// listen to every model in it — and this is the one a missed level would
  /// drop.
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
/// The converter maps empty or unparseable text to **null** rather than keeping
/// the previous value. `glade_forms`' own nullable-int converter does the
/// opposite — it treats `''` as unparseable and silently retains the last good
/// number — which would mean a cleared component still reached the payload.
/// `.create` rather than `.optional`, because `.optional` accepts no validator —
/// it is documented as being for inputs that allow null *without* additional
/// validation, and the 0.0–1.0 bound is exactly such a validation.
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
