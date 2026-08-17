import 'package:flutter/material.dart';

import '../../../sandbox/forms/apns_config_form.dart';
import '../form_section.dart';
import '../path_rows_field.dart';
import '../string_map_rows.dart';
import 'apns_fcm_options_section.dart';

/// Edits `apns` — what FCM hands to Apple's push service.
///
/// Almost nothing here is a plain field. `payload` is free-form by FCM's own
/// definition, so it is edited as dotted-path rows: an `aps` key Apple ships
/// tomorrow is writable today, which no enumerated form could manage.
class ApnsSection extends StatelessWidget {
  /// Renders [form]'s inputs and its nested options block inside a section.
  const ApnsSection({required this.form, super.key});

  /// The block this section edits. Read, never listened to: something above
  /// listens to every model in the tree and rebuilds this.
  final ApnsConfigForm form;

  @override
  Widget build(BuildContext context) => FormSection(
    title: 'apns',
    subtitle: 'Delivery and rendering options for iOS and macOS',
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
