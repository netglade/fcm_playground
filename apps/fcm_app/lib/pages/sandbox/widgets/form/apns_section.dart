import 'package:fcm_app/i18n/i18n.dart';
import 'package:fcm_app/pages/sandbox/forms/forms.dart';
import 'package:fcm_app/pages/sandbox/widgets/form/apns_fcm_options_section.dart';
import 'package:fcm_app/pages/sandbox/widgets/form/form_section.dart';
import 'package:fcm_app/pages/sandbox/widgets/form/path_rows_field.dart';
import 'package:fcm_app/pages/sandbox/widgets/form/string_map_rows.dart';
import 'package:flutter/material.dart';

/// Edits `apns` — what FCM hands to Apple's push service.
///
/// `payload` is free-form, so it is edited as dotted-path rows: an `aps` key Apple
/// ships tomorrow is writable today.
class ApnsSection extends StatelessWidget {
  const ApnsSection({required this.form, super.key});

  final ApnsConfigForm form;

  @override
  Widget build(BuildContext context) {
    final t = context.t;

    return FormSection(
      title: 'apns',
      subtitle: t.form_section.apns,
      isValid: form.isValid,
      children: [
        StringMapRows(
          label: 'headers',
          value: form.headers.value ?? const {},
          onChanged: form.headers.updateValue,
        ),
        PathRowsField(
          label: 'payload',
          value: form.payload.value ?? const {},
          onChanged: form.payload.updateValue,
        ),
        ApnsFcmOptionsSection(form: form.fcmOptions),
      ],
    );
  }
}
