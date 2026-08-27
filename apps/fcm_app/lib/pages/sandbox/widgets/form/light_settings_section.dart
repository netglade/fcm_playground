import 'package:fcm_app/i18n/i18n.dart';
import 'package:fcm_app/pages/sandbox/forms/forms.dart';
import 'package:fcm_app/pages/sandbox/widgets/form/form_section.dart';
import 'package:flutter/material.dart';
import 'package:glade_forms/glade_forms.dart';

/// Edits `android.notification.light_settings` — the LED's colour and blink
/// timings.
///
/// The deepest section, and the one whose badge the whole per-level `isValid`
/// fold exists for: a component outside 0.0–1.0 has to show up on `android` and
/// on the message root, not only three levels down where nobody has expanded.
class LightSettingsSection extends StatelessWidget {
  const LightSettingsSection({required this.form, super.key});

  final LightSettingsForm form;

  @override
  Widget build(BuildContext context) {
    final t = context.t;

    return FormSection(
      title: 'light_settings',
      subtitle: t.form_section.light_settings,
      isValid: form.isValid,
      children: [
        for (final (label, input) in _numbers(form))
          TextFormField(
            controller: input.controller,
            validator: input.textFormFieldInputValidator,
            decoration: InputDecoration(labelText: label),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
        for (final (label, input) in _texts(form))
          TextFormField(
            controller: input.controller,
            validator: input.textFormFieldInputValidator,
            decoration: InputDecoration(labelText: label),
          ),
      ],
    );
  }
}

/// The colour components, each a decimal between 0.0 and 1.0.
List<(String, GladeInput<Object?>)> _numbers(LightSettingsForm form) => [
  ('color.red', form.red),
  ('color.green', form.green),
  ('color.blue', form.blue),
  ('color.alpha', form.alpha),
];

/// The blink timings, kept as text because they are proto durations such as
/// `0.5s` rather than plain numbers.
List<(String, GladeInput<Object?>)> _texts(LightSettingsForm form) => [
  ('light_on_duration', form.lightOnDuration),
  ('light_off_duration', form.lightOffDuration),
];
