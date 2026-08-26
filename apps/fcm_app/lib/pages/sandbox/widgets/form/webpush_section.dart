import 'package:flutter/material.dart';

import '../../../../../i18n/translations.g.dart';
import '../../forms/webpush_config_form.dart';
import 'form_section.dart';
import 'path_rows_field.dart';
import 'string_map_rows.dart';
import 'webpush_fcm_options_section.dart';

/// Edits `webpush` — what FCM hands to a browser's push gateway.
///
/// Its `notification` is the Web Notification API's own options object, forwarded
/// verbatim, so it is edited as dotted-path rows: an option a browser vendor ships
/// tomorrow is writable today.
class WebpushSection extends StatelessWidget {
  const WebpushSection({required this.form, super.key});

  final WebpushConfigForm form;

  @override
  Widget build(BuildContext context) {
    final t = context.t;

    return FormSection(
      title: 'webpush',
      subtitle: t.form_section.webpush,
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
}
