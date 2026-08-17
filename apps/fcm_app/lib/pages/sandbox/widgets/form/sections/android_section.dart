import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter/material.dart';
import 'package:glade_forms/glade_forms.dart';

import '../../../sandbox/forms/android_config_form.dart';
import '../enum_field.dart';
import '../form_section.dart';
import '../string_map_rows.dart';
import '../tristate_field.dart';
import 'android_notification_section.dart';
import 'fcm_options_section.dart';

/// Edits `android` — how FCM delivers to an Android device and how that device
/// renders the result.
///
/// Nests its two child blocks as further sections, mirroring the payload: the
/// 27-field notification block and this platform's own copy of `fcm_options`.
class AndroidSection extends StatelessWidget {
  /// Renders [form]'s inputs and its two nested blocks inside a section.
  const AndroidSection({required this.form, super.key});

  /// The block this section edits. Read, never listened to: something above
  /// listens to every model in the tree and rebuilds this.
  final AndroidConfigForm form;

  @override
  Widget build(BuildContext context) => FormSection(
    title: 'android',
    subtitle: 'Delivery and rendering options for Android',
    isValid: form.isValid,
    children: [
      for (final (label, input) in _texts(form))
        TextFormField(
          controller: input.controller,
          validator: input.textFormFieldInputValidator,
          decoration: InputDecoration(labelText: label),
        ),
      EnumField<AndroidMessagePriority>(
        label: 'priority',
        input: form.priority,
        values: AndroidMessagePriority.values,
        labelOf: (value) => value.wireName,
      ),
      StringMapRows(
        label: 'data',
        value: form.data.value ?? const {},
        onChanged: form.data.updateValue,
      ),
      TristateField(label: 'direct_boot_ok', input: form.directBootOk),
      AndroidNotificationSection(form: form.notification),
      FcmOptionsSection(form: form.fcmOptions),
    ],
  );
}

/// This block's text inputs, labelled as FCM spells them.
///
/// Typed over `GladeInput<Object?>` because `controller` and
/// `textFormFieldInputValidator` are declared on `GladeInput` itself and take no
/// part in its type argument, so one list carries every input edited as text.
List<(String, GladeInput<Object?>)> _texts(AndroidConfigForm form) => [
  ('collapse_key', form.collapseKey),
  ('ttl', form.ttl),
  ('restricted_package_name', form.restrictedPackageName),
];
