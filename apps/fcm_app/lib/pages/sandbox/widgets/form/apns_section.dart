import 'package:flutter/material.dart';

import '../../../../../i18n/translations.g.dart';
import '../../forms/apns_config_form.dart';
import 'form_section.dart';
import 'path_rows_field.dart';
import 'string_map_rows.dart';
import 'apns_fcm_options_section.dart';

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
