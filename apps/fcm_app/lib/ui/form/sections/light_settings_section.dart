import 'package:flutter/material.dart';
import 'package:glade_forms/glade_forms.dart';

import '../../../sandbox/forms/light_settings_form.dart';
import '../form_section.dart';

/// Edits `android.notification.light_settings` — the LED's colour and blink
/// timings.
///
/// The deepest section, and the one whose badge the whole per-level `isValid`
/// fold exists for: a component outside 0.0–1.0 has to show up on `android` and
/// on the message root, not only three levels down where nobody has expanded.
class LightSettingsSection extends StatelessWidget {
  /// Renders [form]'s inputs inside a collapsible section.
  const LightSettingsSection({required this.form, super.key});

  /// The block this section edits. Read, never listened to: something above
  /// listens to every model in the tree and rebuilds this.
  final LightSettingsForm form;

  @override
  Widget build(BuildContext context) => FormSection(
    title: 'light_settings',
    subtitle: 'FCM requires every field once this block is present',
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

/// The colour components, each a fraction of full intensity.
///
/// A numeric keyboard, because every one of them is a decimal between 0.0 and
/// 1.0 and a phone offering letters here would only be in the way.
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
