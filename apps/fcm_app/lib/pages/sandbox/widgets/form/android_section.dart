import 'package:fcm_app/i18n/i18n.dart';
import 'package:fcm_app/pages/sandbox/forms/forms.dart';
import 'package:fcm_app/pages/sandbox/widgets/form/android_notification_section.dart';
import 'package:fcm_app/pages/sandbox/widgets/form/enum_field.dart';
import 'package:fcm_app/pages/sandbox/widgets/form/fcm_options_section.dart';
import 'package:fcm_app/pages/sandbox/widgets/form/form_section.dart';
import 'package:fcm_app/pages/sandbox/widgets/form/string_map_rows.dart';
import 'package:fcm_app/pages/sandbox/widgets/form/tristate_field.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter/material.dart';
import 'package:glade_forms/glade_forms.dart';

/// Edits `android` — how FCM delivers to an Android device and how that device
/// renders the result.
class AndroidSection extends StatelessWidget {
  const AndroidSection({required this.form, super.key});

  final AndroidConfigForm form;

  @override
  Widget build(BuildContext context) {
    final t = context.t;

    return FormSection(
      title: 'android',
      subtitle: t.form_section.android,
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
}

/// See `AndroidNotificationSection` for why these are typed over
/// `GladeInput<Object?>`.
List<(String, GladeInput<Object?>)> _texts(AndroidConfigForm form) => [
  ('collapse_key', form.collapseKey),
  ('ttl', form.ttl),
  ('restricted_package_name', form.restrictedPackageName),
];
