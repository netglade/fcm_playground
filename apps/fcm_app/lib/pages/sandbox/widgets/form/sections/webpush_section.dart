import 'package:flutter/material.dart';

import '../../../sandbox/forms/webpush_config_form.dart';
import '../form_section.dart';
import '../path_rows_field.dart';
import '../string_map_rows.dart';
import 'webpush_fcm_options_section.dart';

/// Edits `webpush` — what FCM hands to a browser's push gateway.
///
/// Its `notification` is the Web Notification API's own options object, which
/// FCM forwards verbatim and never inspects, so it is edited as dotted-path rows
/// rather than as fields: an option a browser vendor ships tomorrow is writable
/// today.
class WebpushSection extends StatelessWidget {
  /// Renders [form]'s inputs and its nested options block inside a section.
  const WebpushSection({required this.form, super.key});

  /// The block this section edits. Read, never listened to: something above
  /// listens to every model in the tree and rebuilds this.
  final WebpushConfigForm form;

  @override
  Widget build(BuildContext context) => FormSection(
    title: 'webpush',
    subtitle: 'Delivery and rendering options for browsers',
    isValid: form.isValid,
    children: [
      StringMapRows(
        label: 'headers',
        value: form.headers.value ?? const {},
        onChanged: form.headers.updateValue,
      ),
      StringMapRows(
        label: 'data',
        value: form.data.value ?? const {},
        onChanged: form.data.updateValue,
      ),
      PathRowsField(
        label: 'notification',
        value: form.notification.value ?? const {},
        onChanged: form.notification.updateValue,
      ),
      WebpushFcmOptionsSection(form: form.fcmOptions),
    ],
  );
}
